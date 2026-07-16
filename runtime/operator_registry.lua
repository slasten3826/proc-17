local topology = require("core.topology")
local field = require("runtime.field")

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
        readiness = function(instance)
            local chaos = instance and instance.chaos or {}
            local refs = {}
            for index, fragment in ipairs(chaos.fragments or {}) do
                if fragment.text ~= nil or fragment.value ~= nil or fragment.content ~= nil then
                    refs[#refs + 1] = "chaos:fragment:" .. tostring(index)
                end
            end
            if #refs == 0 and type(chaos.raw_prompt) == "string" and chaos.raw_prompt ~= "" then
                refs[1] = "chaos:raw_prompt"
            end
            return witness("☵", #refs > 0, #refs > 0 and "ready" or "no_compressible_structure", refs)
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
        readiness = function(instance)
            local calm = instance and instance.calm or {}
            local current = calm.current
            local items = type(current) == "table" and type(current.field) == "table"
                and current.field.items or calm.work_units or {}
            local refs = {}
            for index, item in ipairs(items or {}) do
                refs[#refs + 1] = tostring(type(item) == "table" and (item.id or item.value) or index)
            end
            if #refs == 0 then
                return witness("☳", false, "scope_empty", {})
            end
            return witness("☳", true, #refs == 1 and "confirmation_not_choice" or "ready", refs, {
                alternative_count = #refs,
                collapse_possible = #refs > 1,
            })
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
        loss_profile = "zero",
        reads = {"chaos", "field.potential", "field.relations", "substrate.current"},
        writes = {"boundary.observations.upper", "chaos.fragments", "field.potential"},
        readiness = function(instance)
            local view = field.view(instance, {limit = 16})
            local refs = {}
            for _, unit in ipairs(view and view.units or {}) do
                refs[#refs + 1] = unit.id
            end
            if #refs == 0 then
                refs[1] = "chaos:raw_prompt"
            end
            return witness("☴", true, "ready", refs)
        end,
        run = function(instance, context)
            local options = main_options(context)
            return unwrap(observe.run(instance, context and context.substrate, {
                work_mode = options.work_mode or "build",
                mode = options.observe_mode or options.mode or "mixed",
                prompt_payload = options.prompt_payload,
                system_prompt = options.system_prompt,
                substrate_options = options.substrate_options,
            }))
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
        reads = {"calm", "field.relations", "runtime", "budget", "loss", "history"},
        writes = {"boundary.observations.lower", "tension", "field.relations.active", "field.momentum"},
        readiness = function(instance)
            return runtime_organ.readiness(instance)
        end,
        run = function(instance)
            return unwrap(runtime_organ.run(instance))
        end,
    },
    ["△"] = {
        glyph = "△",
        name = "MANIFEST",
        module = manifest,
        required_capabilities = {},
        loss_profile = "terminal",
        reads = {"calm", "boundary.validations", "runtime.evidence", "budget", "loss"},
        writes = {"manifest", "terminal", "residue"},
        readiness = function(instance, context)
            local options = main_options(context)
            options = setmetatable({result = context and context.result}, {__index = options})
            return manifest.readiness(instance, options)
        end,
        run = function(instance, context)
            local options = main_options(context)
            options = setmetatable({result = context and context.result}, {__index = options})
            return unwrap(manifest.run(instance, options))
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
    value.required_capabilities = descriptor.required_capabilities
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

    local missing = {}
    for _, capability in ipairs(descriptor.required_capabilities) do
        if not has_capability(capability, context) then
            missing[#missing + 1] = capability
        end
    end
    if #missing > 0 then
        return false, "missing_capability", missing
    end
    return true, "available", {}
end

function registry.readiness(value, instance, context)
    local descriptor = registry.get(value)
    if not descriptor then
        return nil, "operator_not_registered"
    end
    local available, reason, missing = registry.available(value, instance, context)
    if not available then
        return normalize_witness(descriptor, {
            ready = false,
            reason = reason,
            missing_capabilities = missing,
        })
    end

    local value_or_nil, err = descriptor.readiness(instance, context or {})
    if not value_or_nil then
        return nil, err
    end
    return normalize_witness(descriptor, value_or_nil)
end

function registry.run(value, instance, context)
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
        return nil, ready.reason, ready
    end

    local payload, run_err = descriptor.run(instance, context or {})
    if not payload then
        return nil, run_err, ready
    end
    return payload, nil, ready
end

return registry
