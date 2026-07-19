local topology = require("core.topology")
local field = require("runtime.field")
local substrate_contract = require("substrates.contract")

local flow = require("organs.flow")
local connect = require("organs.connect")
local dissolve = require("organs.dissolve")
local encode = require("organs.encode")
local choose = require("organs.choose")
local observe = require("organs.observe")
local cycle = require("organs.cycle")
local logic = require("organs.logic")
local runtime_organ = require("organs.runtime")
local manifest = require("organs.manifest")

local registry = {
    protocol_version = "operator-registry.v0",
}

local function witness(glyph, ready, reason, source_refs, extra)
    local result = {
        operator = glyph,
        ready = ready == true,
        reason = reason,
        source_refs = source_refs or {},
        required_capabilities = {},
        missing_capabilities = {},
        event_truth_status = "runtime_confirmed",
    }
    for key, value in pairs(extra or {}) do
        result[key] = value
    end
    return result
end

local function option(context, key)
    context = context or {}
    if context[key] ~= nil then
        return context[key]
    end
    local options = context.options or {}
    return options[key] or {}
end

local function main_options(context)
    return context and context.options or {}
end

local function merged_options(context, key)
    local result = {}
    for option_key, value in pairs(main_options(context)) do
        result[option_key] = value
    end
    for option_key, value in pairs(option(context, key)) do
        result[option_key] = value
    end
    if context and context.result ~= nil then
        result.result = context.result
    end
    return result
end

local function unwrap(ok, payload_or_err)
    if not ok then
        return nil, payload_or_err
    end
    return payload_or_err
end

local descriptors = {
    ["▽"] = {
        glyph = "▽",
        name = "FLOW",
        module = flow,
        required_capabilities = {},
        loss_profile = "zero",
        reads = {"birth", "chaos.raw_prompt", "lineage.carrier"},
        writes = {"field.potential"},
        readiness = function(instance)
            local view = field.view(instance, {created_by = "▽", limit = 1})
            local ready = view ~= nil and view.total_count == 0
            return witness("▽", ready, ready and "ready" or "flow_already_materialized", {
                "chaos:raw_prompt",
            })
        end,
        run = function(instance, context)
            return unwrap(flow.run(instance, option(context, "flow")))
        end,
    },
    ["☰"] = {
        glyph = "☰",
        name = "CONNECT",
        module = connect,
        required_capabilities = {},
        loss_profile = "zero",
        reads = {"field.potential", "field.relations.raw", "boundary.observations.upper"},
        writes = {"field.relations.raw"},
        readiness = function(instance, context)
            return connect.readiness(instance, option(context, "connect"))
        end,
        run = function(instance, context)
            return unwrap(connect.run(instance, option(context, "connect")))
        end,
    },
    ["☷"] = {
        glyph = "☷",
        name = "DISSOLVE",
        module = dissolve,
        required_capabilities = {},
        loss_profile = "conditional",
        reads = {"field.relations.active", "boundary.validations", "trace"},
        writes = {"field.relations.active", "field.potential", "loss"},
        readiness = function(instance, context)
            return dissolve.readiness(instance, option(context, "dissolve"))
        end,
        run = function(instance, context)
            return unwrap(dissolve.run(instance, option(context, "dissolve")))
        end,
    },
    ["☵"] = {
        glyph = "☵",
        name = "ENCODE",
        module = encode,
        required_capabilities = {},
        loss_profile = "mandatory",
        reads = {"chaos.fragments", "field.potential", "regime.encoding"},
        writes = {"calm", "field.potential", "field.identity_maps", "loss"},
        readiness = function(instance, context)
            return encode.readiness(instance, option(context, "encode"))
        end,
        run = function(instance, context)
            return unwrap(encode.run(instance, option(context, "encode")))
        end,
    },
    ["☳"] = {
        glyph = "☳",
        name = "CHOOSE",
        module = choose,
        required_capabilities = {},
        loss_profile = "mandatory",
        reads = {"calm", "field.potential", "constraints", "tension"},
        writes = {"boundary.choices", "field.potential.activation", "loss"},
        readiness = function(instance, context)
            return choose.readiness(instance, option(context, "choose"))
        end,
        run = function(instance, context)
            return unwrap(choose.run(instance, option(context, "choose")))
        end,
    },
    ["☴"] = {
        glyph = "☴",
        name = "OBSERVE",
        module = observe,
        required_capabilities = {"substrate.ask"},
        capabilities = function(context)
            local observe_options = option(context, "observe")
            if observe_options.sensor == "relation_native"
                or observe_options.sensor == "field_native" then
                return {}
            end
            return {"substrate.ask"}
        end,
        loss_profile = "zero",
        reads = {"chaos", "field.potential", "field.relations", "substrate.current"},
        writes = {"boundary.observations.upper", "chaos.fragments", "field.potential"},
        readiness = function(instance, context)
            return observe.readiness(instance, option(context, "observe"))
        end,
        run = function(instance, context)
            local options = main_options(context)
            local configured = option(context, "observe")
            configured = setmetatable(configured, {__index = {
                work_mode = options.work_mode or "build",
                mode = options.observe_mode or options.mode or "mixed",
                prompt_payload = options.prompt_payload,
                system_prompt = options.system_prompt,
                substrate_options = options.substrate_options,
            }})
            return unwrap(observe.run(instance, context and context.substrate, configured))
        end,
    },
    ["☲"] = {
        glyph = "☲",
        name = "CYCLE",
        module = cycle,
        required_capabilities = {},
        loss_profile = "zero",
        reads = {"calm.work_units", "runtime.progress", "budget", "regime.cycle"},
        writes = {"boundary.cycles", "regime.cycle"},
        readiness = function(instance, context)
            local options = main_options(context)
            return cycle.readiness(instance, {
                goal = options.goal,
                logic_status = options.logic_status,
                manifest_ready = options.manifest_ready,
            })
        end,
        run = function(instance, context)
            local options = main_options(context)
            local result = context and context.result or {ticks = {}}
            return unwrap(cycle.run(instance, {
                cycle_key = options.cycle_key or instance.id,
                turn_count = options.turn_count or #(result.ticks or {}),
                max_turns = options.max_turns or options.max_ticks or 12,
                required_budget = options.required_budget or {steps = 1},
                logic_status = options.logic_status,
                state_fingerprint = options.state_fingerprint,
            }))
        end,
    },
    ["☶"] = {
        glyph = "☶",
        name = "LOGIC",
        module = logic,
        required_capabilities = {},
        loss_profile = "conditional",
        reads = {"calm", "constraints", "runtime.evidence", "sandbox.capabilities"},
        writes = {"boundary.validations", "constraints", "runtime.evidence", "runtime.foundation"},
        readiness = function(instance)
            return logic.readiness(instance)
        end,
        run = function(instance, context)
            return unwrap(logic.run(instance, main_options(context)))
        end,
    },
    ["☱"] = {
        glyph = "☱",
        name = "RUNTIME",
        module = runtime_organ,
        required_capabilities = {},
        loss_profile = "conditional",
        reads = {"calm", "field.relations", "runtime.camera.frames", "budget", "loss", "history", "regime.work"},
        writes = {"runtime.camera.reconciliations", "runtime.camera.watermark", "boundary.observations.lower", "tension", "field.relations.active", "field.momentum", "plan.completion_assessment"},
        readiness = function(instance, context)
            return runtime_organ.readiness(instance, option(context, "runtime"))
        end,
        run = function(instance, context)
            return unwrap(runtime_organ.run(instance, option(context, "runtime")))
        end,
    },
    ["△"] = {
        glyph = "△",
        name = "MANIFEST",
        module = manifest,
        required_capabilities = {},
        loss_profile = "terminal",
        reads = {"calm", "boundary.validations", "runtime.camera.reconciliations", "runtime.evidence", "budget", "loss", "regime.work", "plan.completion_assessment"},
        writes = {"manifest", "terminal", "residue"},
        readiness = function(instance, context)
            return manifest.readiness(instance, merged_options(context, "manifest"))
        end,
        run = function(instance, context)
            return unwrap(manifest.run(instance, merged_options(context, "manifest")))
        end,
    },
}

local function has_capability(name, context)
    context = context or {}
    if name == "substrate.ask" then
        return type(context.substrate) == "table" and type(context.substrate.ask) == "function"
    end
    return type(context.capabilities) == "table" and context.capabilities[name] == true
end

local function normalize_witness(descriptor, value)
    value = value or {}
    value.operator = descriptor.glyph
    value.ready = value.ready == true
    value.reason = value.reason or (value.ready and "ready" or "not_ready")
    value.source_refs = value.source_refs or {}
    value.required_capabilities = value.required_capabilities or descriptor.required_capabilities
    value.missing_capabilities = value.missing_capabilities or {}
    value.event_truth_status = "runtime_confirmed"
    return value
end

function registry.get(value)
    local glyph = topology.resolve(value)
    return glyph and descriptors[glyph] or nil
end

function registry.list()
    local result = {}
    for _, glyph in ipairs(topology.order) do
        result[#result + 1] = descriptors[glyph]
    end
    return result
end

function registry.available(value, instance, context)
    local descriptor = registry.get(value)
    if not descriptor then
        return false, "operator_not_registered", {}
    end
    if type(instance) ~= "table" then
        return false, "packet_instance_required", {}
    end
    if instance.status == "dead" or instance.status == "dying" or instance.terminal ~= nil then
        return false, "terminal_packet", {}
    end

    local required = descriptor.capabilities and descriptor.capabilities(context or {})
        or descriptor.required_capabilities
    local missing = {}
    for _, capability in ipairs(required) do
        if not has_capability(capability, context) then
            missing[#missing + 1] = capability
        end
    end
    if #missing > 0 then
        return false, "missing_capability", missing, required
    end
    return true, "available", {}, required
end

function registry.readiness(value, instance, context)
    local descriptor = registry.get(value)
    if not descriptor then
        return nil, "operator_not_registered"
    end
    local available, reason, missing, required = registry.available(value, instance, context)
    if not available then
        return normalize_witness(descriptor, {
            ready = false,
            reason = reason,
            missing_capabilities = missing,
            required_capabilities = required,
        })
    end

    local value_or_nil, err = descriptor.readiness(instance, context or {})
    if not value_or_nil then
        return nil, err
    end
    value_or_nil.required_capabilities = required
    return normalize_witness(descriptor, value_or_nil)
end

function registry.run(value, instance, context)
    local outcome, outcome_err = registry.execute(value, instance, context)
    if not outcome then
        return nil, outcome_err
    end
    if outcome.status == "not_ready" then
        return nil, outcome.readiness.reason, outcome.readiness
    end
    if outcome.status == "effect_failure" then
        return nil, outcome.failure, outcome.readiness
    end
    return outcome.payload, nil, outcome.readiness
end

function registry.execute(value, instance, context)
    local descriptor = registry.get(value)
    if not descriptor then
        return nil, "operator_not_registered"
    end
    if instance.operator ~= descriptor.glyph then
        return nil, "operator position mismatch"
    end
    local ready, ready_err = registry.readiness(descriptor.glyph, instance, context)
    if not ready then
        return nil, ready_err
    end
    if not ready.ready then
        return {
            kind = "operator_execution_outcome",
            status = "not_ready",
            operator = descriptor.glyph,
            readiness = ready,
            event_truth_status = "runtime_confirmed",
        }
    end

    local payload, run_err = descriptor.run(instance, context or {})
    if not payload then
        if substrate_contract.is_effect_failure(run_err) then
            return {
                kind = "operator_execution_outcome",
                status = "effect_failure",
                operator = descriptor.glyph,
                failure = run_err,
                readiness = ready,
                event_truth_status = "runtime_confirmed",
            }
        end
        if type(run_err) == "table" and run_err.kind == "effect_failure" then
            return nil, "invalid effect failure contract"
        end
        return nil, run_err
    end
    return {
        kind = "operator_execution_outcome",
        status = "applied",
        operator = descriptor.glyph,
        payload = payload,
        readiness = ready,
        event_truth_status = "runtime_confirmed",
    }
end

return registry
