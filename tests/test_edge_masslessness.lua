package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local corpse = require("runtime.corpse")
local digest = require("core.digest")
local edge_life_projection = require("runtime.edge_life_projection")
local flow_domain = require("runtime.flow_domain")
local packet_memory = require("runtime.packet_memory")
local qa_fixture = require("tests.support.qa_hand")
local repository_capability = require("runtime.repository_capability")
local repository_fixture = require("tests.support.repository_hands")
local plan_fixture = require("tests.support.plan_life")
local tension_runner = require("runtime.tension_runner")

local suite = H.new("edge-masslessness-i08")
local selected_case = os.getenv("PROC17_I08_CASE")

local function check(id, callback)
    if selected_case == nil or id:sub(1, #selected_case) == selected_case then
        suite:check(id, callback)
    end
end

local frozen_time = 1785542400

local function with_frozen_time(callback)
    local original = os.time
    os.time = function() return frozen_time end
    local values = table.pack(pcall(callback))
    os.time = original
    if not values[1] then error(values[2], 0) end
    return table.unpack(values, 2, values.n)
end

local function instrument_options(mode, case_id)
    if mode == "off" then
        return {
            authority_instrument = "off",
            authority_instrument_test_override = true,
        }
    end
    return {
        authority_instrument = "v3",
        edge_evidence = {
            case_id = case_id,
            corpus_layer = "unit",
            evidence_run_id = "run:i08:" .. case_id,
        },
    }
end

local function merge(target, source)
    for key, value in pairs(source or {}) do target[key] = value end
    return target
end

local function record_digest(value)
    return "sha256:" .. assert(digest.record(value))
end

local function first_difference(left, right, path, seen)
    path = path or "root"
    if type(left) ~= type(right) then
        return path .. " (" .. type(left) .. " != " .. type(right) .. ")"
    end
    if type(left) ~= "table" then
        if left ~= right then
            return path .. " (" .. tostring(left) .. " != " .. tostring(right) .. ")"
        end
        return nil
    end
    seen = seen or {}
    seen[left] = seen[left] or {}
    if seen[left][right] then return nil end
    seen[left][right] = true
    local keys = {}
    local present = {}
    for key in pairs(left) do
        keys[#keys + 1] = key
        present[key] = true
    end
    for key in pairs(right) do
        if not present[key] then keys[#keys + 1] = key end
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do
        if left[key] == nil and right[key] ~= nil then
            return path .. "." .. tostring(key) .. " (missing left)"
        end
        if left[key] ~= nil and right[key] == nil then
            return path .. "." .. tostring(key) .. " (missing right)"
        end
        local difference = first_difference(
            left[key],
            right[key],
            path .. "." .. tostring(key),
            seen
        )
        if difference then return difference end
    end
    return nil
end

local function assert_same_record(left, right, message)
    H.assert_eq(record_digest(left), record_digest(right),
        message .. ": " .. tostring(first_difference(left, right)))
end

local function capture_projection(life, life_id)
    return assert(edge_life_projection.capture(
        life.instance,
        life.result,
        life.corpse,
        {life_id = life_id}
    ))
end

local function assert_exact_life(left, right, label)
    assert_same_record(left.instance, right.instance, label .. " Packet")
    assert_same_record(left.corpse, right.corpse, label .. " corpse")
    local left_projection = capture_projection(left, "life:" .. label .. ":off")
    local right_projection = capture_projection(right, "life:" .. label .. ":v3")
    local same, differences = edge_life_projection.same_exact(
        left_projection,
        right_projection
    )
    H.assert_true(same, label .. " projection differs: "
        .. table.concat(differences or {}, ","))
    return left_projection, right_projection
end

local function run_plan(mode, observer, label, budget_steps, expected_cause)
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = label,
        source_ref = "fixture:" .. label,
    }))
    local birth_digest
    local options = {
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        ablate_relation_consumer = true,
        legacy_shadow = observer == true,
        work_mode = "plan",
        max_ticks = 20,
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = domain,
            projection_adapter = "vertical_single.v0",
        },
        packet_options = {
            id = "packet:" .. label,
            session_id = "session:" .. label,
            lineage_id = "lineage:" .. label,
            budget = {
                steps = budget_steps or 64,
                substrate_calls = 16,
                tool_calls = 8,
                encode_items = 16,
                loss = 10,
            },
        },
        on_packet_birth = function(instance)
            birth_digest = record_digest(instance)
            return true
        end,
    }
    merge(options, instrument_options(mode, "MI01_MI02"))
    local instance, result = assert(tension_runner.run(
        "prepare an exact instrument-ablation plan",
        plan_fixture.substrate(plan_fixture.proposal(
            "work_sequence",
            {"inspect", "change", "verify"}
        )),
        options
    ))
    H.assert_eq(instance.status, "dead", "Plan fixture must be terminal")
    H.assert_eq(instance.death.cause, expected_cause or "complete",
        "Plan fixture terminal cause")
    local dead = assert(corpse.capture(instance, {
        corpse_id = "corpse:" .. label,
        trace_tail_count = 32,
    }))
    return {
        instance = instance,
        result = result,
        corpse = dead,
        birth_digest = birth_digest,
    }
end

local function run_repository(mode)
    local label = "i08-mi03-repository"
    local registry, _, _, provider_state = repository_fixture.new_registry(
        repository_capability,
        {session_id = "session-repository-hands"}
    )
    local runner_options = {
        repository_hands = {
            protocol_version = "repository.hands.config.v0",
            enabled = true,
            repository_id = "repo-a",
        },
        host_services = {repository_capabilities = registry},
    }
    merge(runner_options, instrument_options(mode, "MI03"))
    local instance, result = repository_fixture.packet({{
        path = "src/main.lua",
        content = "return 'massless'\n",
    }}, {
        label = label,
        max_ticks = 20,
        packet_options = {
            id = "packet:" .. label,
            budget = {
                steps = 64,
                substrate_calls = 16,
                tool_calls = 16,
                file_writes = 8,
                encode_items = 16,
                loss = 10,
            },
        },
        runner_options = runner_options,
    })
    H.assert_eq(instance.death.cause, "complete", "repository life completes")
    local dead = assert(corpse.capture(instance, {
        corpse_id = "corpse:" .. label,
        trace_tail_count = 32,
    }))
    return {
        instance = instance,
        result = result,
        corpse = dead,
        provider_state = provider_state,
    }
end

local function run_effect_failure(mode)
    local label = "i08-mi04-effect-failure"
    local failing_substrate = {
        ask = function()
            return nil, {
                kind = "effect_failure",
                source = "substrate",
                code = "connection_lost",
                message = "i08 injected typed failure",
                source_refs = {},
                retryability = "retryable",
                cost = {substrate_calls = 1},
                event_truth_status = "runtime_confirmed",
            }
        end,
    }
    local options = {
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        legacy_shadow = false,
        work_mode = "plan",
        max_ticks = 8,
        packet_options = {
            id = "packet:" .. label,
            session_id = "session:" .. label,
            lineage_id = "lineage:" .. label,
            budget = {
                steps = 64,
                substrate_calls = 16,
                tool_calls = 8,
                encode_items = 16,
                loss = 10,
            },
        },
    }
    merge(options, instrument_options(mode, "MI04"))
    local instance, result = assert(tension_runner.run(
        "observe an injected typed failure",
        failing_substrate,
        options
    ))
    H.assert_eq(instance.death.cause, "effect_failure", "typed failure dies")
    local dead = assert(corpse.capture(instance, {
        corpse_id = "corpse:" .. label,
        trace_tail_count = 32,
    }))
    return {instance = instance, result = result, corpse = dead}
end

local function run_qa_terminal(mode)
    local runner_options = instrument_options(mode, "MI05")
    local life = assert(qa_fixture.grow_terminal_qa_life({
        label = "i08-mi05-qa-terminal",
        runner_options = runner_options,
        packet_options = {
            id = "packet:i08-mi05-qa-terminal",
        },
        capture_runner_packet_digest = true,
    }))
    return {
        instance = life.instance,
        result = life.runner_result,
        corpse = life.corpse_record,
        terminal = life.terminal,
        verdict = life.verdict,
        check = life.check,
        seal = life.grown.seal,
        runner_packet_digest = life.runner_packet_digest,
    }
end

check("MI01 instrument is absent from birth and raw corpse", function()
    with_frozen_time(function()
        local off = run_plan("off", false, "i08-mi01")
        local on = run_plan("v3", false, "i08-mi01")
        H.assert_eq(off.birth_digest, on.birth_digest,
            "instrument changed Packet before FLOW")
        assert_same_record(off.instance, on.instance, "MI01 terminal Packet")
        assert_same_record(off.corpse, on.corpse, "MI01 raw corpse")
    end)
end)

check("MI02 complete Plan life is exactly massless", function()
    with_frozen_time(function()
        local off = run_plan("off", false, "i08-mi02")
        local on = run_plan("v3", false, "i08-mi02")
        assert_exact_life(off, on, "mi02-plan")
    end)
end)

check("MI03 repository effect and read-back are exactly massless", function()
    with_frozen_time(function()
        local off = run_repository("off")
        local on = run_repository("v3")
        assert_exact_life(off, on, "mi03-repository")
        assert_same_record(off.provider_state.files, on.provider_state.files,
            "MI03 provider files")
        assert_same_record(off.provider_state.calls, on.provider_state.calls,
            "MI03 provider calls")
    end)
end)

check("MI04 typed effect failure is exactly massless", function()
    with_frozen_time(function()
        local off = run_effect_failure("off")
        local on = run_effect_failure("v3")
        assert_exact_life(off, on, "mi04-effect-failure")
        H.assert_eq(off.instance.death.cause, on.instance.death.cause)
        assert_same_record(off.instance.residue, on.instance.residue,
            "MI04 residue")
    end)
end)

check("MI05 QA M4 terminal life is exactly massless", function()
    with_frozen_time(function()
        local off = run_qa_terminal("off")
        local on = run_qa_terminal("v3")
        H.assert_eq(off.runner_packet_digest, on.runner_packet_digest,
            "MI05 instrument changed pre-seal Packet")
        assert_same_record(off.seal, on.seal, "MI05 candidate seal")
        assert_exact_life(off, on, "mi05-qa-m4")
        assert_same_record(off.check, on.check, "MI05 check")
        assert_same_record(off.verdict, on.verdict, "MI05 verdict")
        assert_same_record(off.terminal, on.terminal, "MI05 terminal")
    end)
end)

check("MI06 observer pair differs only through named observer refs", function()
    with_frozen_time(function()
        local off = run_plan("v3", false, "i08-mi06")
        local on = run_plan("v3", true, "i08-mi06")
        local off_projection = capture_projection(off, "life:mi06:observer-off")
        local on_projection = capture_projection(on, "life:mi06:observer-on")
        local raw_same = edge_life_projection.same_exact(
            off_projection,
            on_projection
        )
        H.assert_false(raw_same, "MI06 raw observer pair must expose evidence")
        local neutral, differences = edge_life_projection.same_observer_neutral(
            off_projection,
            on_projection
        )
        H.assert_true(neutral, "MI06 unexplained body delta: "
            .. table.concat(differences or {}, ",") .. ": "
            .. tostring(first_difference(
                off_projection.observer_neutral_components.corpse,
                on_projection.observer_neutral_components.corpse,
                "corpse"
            )))
        H.assert_true(#on_projection.removed_observer_refs > 0,
            "MI06 enabled observer must name its refs")
        assert_same_record(off.corpse.trace_tail, on.corpse.trace_tail,
            "MI06 observer consumed corpse body-tail capacity")

        local budget_off = run_plan(
            "v3", false, "i08-mi06-budget", 1, "budget_exhausted"
        )
        local budget_on = run_plan(
            "v3", true, "i08-mi06-budget", 1, "budget_exhausted"
        )
        assert_same_record(
            budget_off.instance.residue.trace_tail,
            budget_on.instance.residue.trace_tail,
            "MI06 observer consumed residue body-tail capacity"
        )
        local memory_off = assert(packet_memory.capsule(
            budget_off.instance,
            {trace_tail_count = 8}
        ))
        local memory_on = assert(packet_memory.capsule(
            budget_on.instance,
            {trace_tail_count = 8}
        ))
        assert_same_record(memory_off, memory_on,
            "MI06 observer consumed packet-memory body-tail capacity")
    end)
end)

suite:finish()
print("test_edge_masslessness ok")
