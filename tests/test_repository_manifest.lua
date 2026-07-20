package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local fixture = require("tests.support.repository_hands")
local packet_core = require("core.packet")
local pressure_action = require("runtime.pressure_action")
local qualified_pressure = require("runtime.qualified_pressure")
local operator_registry = require("runtime.operator_registry")
local capabilities = require("runtime.repository_capability")
local repository_result, repository_result_err = H.optional_require(
    "runtime.repository_result"
)

local suite = H.new("repository-manifest")

local function result_contract()
    return suite:require_module(
        repository_result,
        repository_result_err,
        "runtime.repository_result"
    )
end

local function hand_config()
    return {
        protocol_version = "repository.hands.config.v0",
        enabled = true,
        repository_id = "repo-a",
    }
end

local function run_with_hand(options)
    options = options or {}
    local registry, _, _, state = fixture.new_registry(capabilities, {
        provider_options = options.provider_options,
    })
    local runner_options = {
        repository_hands = hand_config(),
        host_services = {repository_capabilities = registry},
    }
    for key, value in pairs(options.runner_options or {}) do
        runner_options[key] = value
    end
    local instance, result = fixture.packet(options.items or {{
        path = "src/main.lua",
        content = "return 'manifest'\n",
    }}, {
        shape = options.shape,
        max_ticks = options.max_ticks or 16,
        packet_options = options.packet_options,
        runner_options = runner_options,
    })
    return instance, result, state, registry
end

local function event_count(instance, event_type)
    local count = 0
    for _, event in ipairs(instance.trace or {}) do
        if event.type == event_type then
            count = count + 1
        end
    end
    return count
end

local function last_route_to(result, target)
    for index = #(result and result.routes or {}), 1, -1 do
        local route = result.routes[index]
        if route.to == target then
            return route
        end
    end
    return nil
end

local function manifest_tick(result)
    for index = #(result and result.ticks or {}), 1, -1 do
        local tick = result.ticks[index]
        if tick.operator == "△" then
            return tick
        end
    end
    return nil
end

local function has_repository_manifest(instance)
    return type(instance.manifest) == "table"
        and instance.manifest.mode == "repository_delivery"
end

local function forbidden_projection(value, registry, seen)
    if value == registry then
        return "private_registry"
    end
    if type(value) ~= "table" then
        return nil
    end
    seen = seen or {}
    if seen[value] then
        return nil
    end
    seen[value] = true
    local forbidden = {
        content = true,
        observed_content = true,
        host_path = true,
        project_base = true,
        repository_handle = true,
        root_handle = true,
        provider = true,
        registry = true,
        lease = true,
        command = true,
        shell = true,
    }
    for key, child in pairs(value) do
        if forbidden[key] then
            return tostring(key)
        end
        local nested = forbidden_projection(child, registry, seen)
        if nested then
            return nested
        end
    end
    return nil
end

suite:check("M0 exact complete life manifests and dies complete", function()
    result_contract()
    local instance, result = run_with_hand()
    H.assert_true(fixture.contains_subsequence(fixture.route_pairs(instance), {
        "☶->☱", "☱->△",
    }), "verified work reaches terminal delivery")
    H.assert_eq(result.stop_reason, "manifested", "runner stops at manifest")
    H.assert_eq(instance.status, "dead", "manifested Packet is dead")
    H.assert_eq(instance.death.cause, "complete", "death is complete")
    H.assert_true(has_repository_manifest(instance), "repository manifest exists")

    local alternative, alternative_result = run_with_hand({
        shape = "alternative_set",
        items = {
            {path = "src/a.lua", content = "return 'a'\n"},
            {path = "src/b.lua", content = "return 'b'\n"},
        },
        max_ticks = 18,
    })
    H.assert_eq(alternative_result.stop_reason, "manifested",
        "selected alternative also manifests")
    H.assert_eq(#(alternative.boundary.choices or {}), 1,
        "alternative life performs one real choice")
    H.assert_eq(#alternative.manifest.output.structured.artifacts, 1,
        "only selected alternative becomes an artifact")
end)

suite:check("M1 pre-completion state has no delivery witness", function()
    result_contract()
    local instance, _, _, registry = run_with_hand({max_ticks = 4})
    local witnesses = assert(qualified_pressure.repository_witnesses(instance, {
        current_operator = instance.operator,
    }, {
        work_mode = "build",
        repository_hands = hand_config(),
        host_services = {repository_capabilities = registry},
    }))
    for _, witness in ipairs(witnesses) do
        H.assert_false(witness.kind == "repository_delivery_need",
            "delivery cannot precede completion")
    end
    H.assert_eq(event_count(instance, "work_completion"), 0,
        "fixture truly stops before completion")
end)

suite:check("M2 delivery ablation leaves completion internal", function()
    result_contract()
    local instance = run_with_hand({
        runner_options = {ablate_repository_delivery = true},
    })
    H.assert_eq(event_count(instance, "work_completion"), 1,
        "work still completes")
    H.assert_false(has_repository_manifest(instance),
        "ablated terminal reader cannot project repository result")
end)

suite:check("M3 rejected read-back cannot become complete result", function()
    result_contract()
    local instance = run_with_hand({
        provider_options = {
            read_override = function(_, _, state)
                return {
                    protocol_version = "repository.provider_result.v0",
                    operation = "read_text_file",
                    outcome = "observed",
                    target_kind = "missing",
                    root = H.copy(state.root_identity),
                    mutation_primitive_entered = false,
                    published = false,
                    cost = {tool_calls = 1, file_writes = 0, time_ms = 0},
                }
            end,
        },
    })
    H.assert_eq(event_count(instance, "work_completion"), 0,
        "rejected evidence creates no completion")
    H.assert_false(has_repository_manifest(instance),
        "rejected evidence creates no complete repository result")
end)

suite:check("M4 committed delivery rejects stale work version", function()
    result_contract()
    local instance, result = run_with_hand({max_ticks = 5})
    local route = assert(last_route_to(result, "△"), "delivery route required")
    local plan = route.selected_candidate.action_plan
    local context = assert(pressure_action.registry_context(plan, {
        instance = instance,
        options = {work_mode = "build"},
        result = {ticks = {}},
    }))
    local unit = instance.field.units[plan.options.manifest.repository_result.work_unit_id]
    unit.version = unit.version + 1
    assert(packet_core.begin_tick(instance, "△", {}))
    local execution = assert(operator_registry.execute("△", instance, context))
    H.assert_eq(execution.status, "not_ready",
        "stale committed projection is not executable")
end)

suite:check("M5 runner text cannot change Packet-local projection", function()
    result_contract()
    local instance, result = run_with_hand({max_ticks = 5})
    local route = assert(last_route_to(result, "△"), "delivery route required")
    local plan = route.selected_candidate.action_plan
    local context_a = assert(pressure_action.registry_context(plan, {
        instance = instance,
        options = {work_mode = "build"},
        result = {ticks = {{operator = "☴", payload = {response = {text = "A"}}}}},
    }))
    local context_b = assert(pressure_action.registry_context(plan, {
        instance = instance,
        options = {work_mode = "build"},
        result = {ticks = {{operator = "☴", payload = {response = {text = "B"}}}}},
    }))
    assert(packet_core.begin_tick(instance, "△", {}))
    local left = assert(operator_registry.execute("△", instance, context_a))
    local right = assert(operator_registry.execute("△", instance, context_b))
    H.assert_eq(left.status, "applied", "first projection applies")
    H.assert_eq(right.status, "applied", "second projection applies")
    H.assert_eq(require("core.json").encode(left.payload),
        require("core.json").encode(right.payload),
        "runner text has no effect")
end)

suite:check("M6 projection contains no authority or raw content", function()
    result_contract()
    local instance, _, _, registry = run_with_hand()
    H.assert_nil(forbidden_projection(instance.manifest, registry),
        "manifest projection is bounded")
end)

suite:check("M7 delivery adds no second external charge or loss", function()
    result_contract()
    local pending = run_with_hand({max_ticks = 5})
    local delivered = run_with_hand({max_ticks = 6})
    H.assert_eq(delivered.runtime.budget.spent.steps,
        pending.runtime.budget.spent.steps + 1, "△ pays one ordinary step")
    H.assert_eq(delivered.runtime.budget.spent.tool_calls, 2,
        "tool calls are charged only by prior effect")
    H.assert_eq(delivered.runtime.budget.spent.file_writes, 1,
        "file write is charged only once")
    local effect_charges = 0
    for _, event in ipairs(delivered.runtime.budget.events or {}) do
        if event.source == "repository_effect" then
            effect_charges = effect_charges + 1
        end
    end
    H.assert_eq(effect_charges, 1, "one repository effect charge")
    for _, event in ipairs(delivered.tension.loss_events or {}) do
        H.assert_false(event.operator == "△", "delivery creates no identity loss")
    end
end)

suite:check("M8 result metadata matches verified artifact exactly", function()
    result_contract()
    local instance = run_with_hand()
    local manifest = instance.manifest
    local structured = manifest.output.structured
    local artifact = structured.artifacts[1]
    H.assert_eq(structured.protocol_version, "repository.result.v0",
        "result protocol")
    H.assert_eq(structured.status, "complete", "result status")
    H.assert_eq(#structured.artifacts, 1, "one bounded artifact")
    H.assert_eq(artifact.relative_path, "src/main.lua", "relative path")
    H.assert_eq(artifact.bytes, #"return 'manifest'\n", "verified bytes")
    H.assert_eq(#artifact.sha256, 64, "verified SHA-256")
    H.assert_eq(manifest.output.text, require("core.json").encode(structured),
        "text is canonical structured result")
    H.assert_eq(manifest.truth_status, "runtime_confirmed", "assembly truth")
    H.assert_eq(manifest.content_truth_status, "semantic_proposal",
        "semantic origin remains typed")
end)

suite:check("M9 returned tick payload cannot mutate sealed manifest", function()
    result_contract()
    local instance, result = run_with_hand()
    local tick = assert(manifest_tick(result), "manifest tick required")
    tick.payload.output.structured.artifacts[1].relative_path = "forged.lua"
    H.assert_eq(instance.manifest.output.structured.artifacts[1].relative_path,
        "src/main.lua", "Packet manifest is detached from runner payload")
end)

suite:check("M10 default shadow authority gains no repository delivery", function()
    result_contract()
    local instance = run_with_hand({
        max_ticks = 10,
        runner_options = {router_mode = "shadow"},
    })
    H.assert_false(has_repository_manifest(instance),
        "opt-in hand cannot promote default authority")
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "route" then
            H.assert_false(event.payload.authority == "tree",
                "shadow life commits no Tree route")
        end
    end
end)

suite:finish()
print("test_repository_manifest ok")
