local packet_core = require("core.packet")
local body = require("runtime.body")
local field = require("runtime.field")
local system_prompt = require("runtime.system_prompt")
local substrate_contract = require("substrates.contract")

local observe = {}

local function ingress_refs(instance)
    local view = field.view(instance, {
        created_by = "▽",
        activation = {live = true, selected = true},
        limit = 16,
    })
    local refs = {}
    if view then
        for _, unit in ipairs(view.units) do
            refs[#refs + 1] = unit.id
        end
    end
    if #refs == 0 then
        refs[1] = "chaos:raw_prompt"
    end
    return refs
end

local function prompt_payload(instance, options)
    options = options or {}
    if options.prompt_payload ~= nil then
        return options.prompt_payload
    end
    return instance.chaos and instance.chaos.raw_prompt or ""
end

local function build_call(instance, options)
    options = options or {}
    local call = {
        mode = options.mode or "mixed",
        operator = "☴",
        prompt_payload = prompt_payload(instance, options),
        expected_shape = "semantic_proposal",
        work_mode = options.work_mode or "build",
        system_prompt = options.system_prompt or system_prompt.format({
            work_mode = options.work_mode or "build",
        }),
    }
    return call
end

function observe.run(instance, substrate, options)
    options = options or {}
    local mutable, mutable_err = packet_core.assert_mutable(instance, "observe")
    if not mutable then
        return nil, mutable_err
    end
    if type(substrate) ~= "table" or type(substrate.ask) ~= "function" then
        return nil, "missing_substrate"
    end

    local scope_refs = ingress_refs(instance)
    local read_revisions, revision_err = body.revision_snapshot(instance, "upper")
    if not read_revisions then
        return nil, revision_err
    end
    local planned_ids, planned_err = field.plan_unit_ids(instance, 1)
    if not planned_ids then
        return nil, planned_err
    end

    local call = build_call(instance, options)
    local ok, err = substrate_contract.validate_call(call)
    if not ok then
        return nil, err
    end

    local response, ask_err = substrate.ask(call, options.substrate_options or {})
    if not response then
        return nil, ask_err or "substrate_failed"
    end

    local normalized = substrate_contract.normalize_response(response)
    local _, chaos_event = packet_core.append_chaos(instance, {
        operator = "☴",
        kind = "substrate_response",
        text = normalized.text,
        reasoning_text = normalized.reasoning_text,
        tool_intents = normalized.tool_intents,
        usage = normalized.usage,
        latency = normalized.latency,
        provider_metadata = normalized.provider_metadata,
        raw = normalized.raw,
        call = call,
        truth_status = "semantic_proposal",
    })

    local observation, observation_err = body.record_observation(instance, "upper", {
        scope_refs = scope_refs,
        read_revisions = read_revisions,
        payload = {
            kind = "upper_eye_payload",
            call = call,
            response = normalized,
        },
        metrics = {
            scope_count = #scope_refs,
            proposal_count = 1,
        },
        source_refs = {chaos_event.id},
        sensor_output_refs = {planned_ids[1]},
        content_truth_status = "semantic_proposal",
        fidelity = "substrate_mediated",
    })
    if not observation then
        return nil, observation_err
    end

    local unit, unit_err = field.add_unit(instance, "☴", {
        id = planned_ids[1],
        kind = "substrate_response",
        carrier = normalized,
        source_refs = scope_refs,
        event_truth_status = "runtime_confirmed",
        content_truth_status = "semantic_proposal",
        created_event_id = observation.trace_event_id,
        migration = {
            status = "shadow_only",
            legacy_ref = "chaos:fragment:" .. tostring(#instance.chaos.fragments),
        },
    })
    if not unit then
        return nil, unit_err
    end

    return instance, {
        kind = "observe_organ_payload",
        response = normalized,
        call = call,
        trace_event_id = observation.trace_event_id,
        chaos_trace_event_id = chaos_event.id,
        observation_id = observation.id,
        field_unit_id = unit.id,
        field_shadow = true,
        truth_status = "semantic_proposal",
    }
end

return observe
