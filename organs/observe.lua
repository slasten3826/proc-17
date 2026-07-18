local packet_core = require("core.packet")
local body = require("runtime.body")
local field = require("runtime.field")
local object_coverage = require("runtime.object_coverage")
local system_prompt = require("runtime.system_prompt")
local substrate_contract = require("substrates.contract")

local observe = {}
local ingress_refs

local function relation_input(options)
    local input = options and options.relation_input
    if type(input) ~= "table" or type(input.raw_epoch) ~= "number"
        or type(input.relation_ids) ~= "table" or #input.relation_ids == 0
        or type(input.endpoint_versions) ~= "table" then
        return nil, "relation-native OBSERVE requires exact relation_input"
    end
    return input
end

local function relation_native_scope(instance, input)
    local relations = {}
    local endpoint_ids = {}
    local endpoint_seen = {}
    local source_refs = {}
    for _, relation_id in ipairs(input.relation_ids) do
        local relation, relation_err = field.raw_relation_exact(
            instance,
            input.raw_epoch,
            relation_id,
            input.endpoint_versions
        )
        if not relation then
            return nil, relation_err
        end
        local phase, phase_err = field.raw_relation_phase(
            instance,
            input.raw_epoch,
            relation_id
        )
        if not phase then
            return nil, phase_err
        end
        relations[#relations + 1] = {
            relation = relation,
            phase = phase,
        }
        source_refs[#source_refs + 1] = relation.id
        if relation.origin_event_id then
            source_refs[#source_refs + 1] = relation.origin_event_id
        end
        for _, endpoint in ipairs({relation.from, relation.to}) do
            if not endpoint_seen[endpoint] then
                endpoint_seen[endpoint] = true
                endpoint_ids[#endpoint_ids + 1] = endpoint
            end
        end
    end
    return {
        relations = relations,
        endpoint_ids = endpoint_ids,
        source_refs = source_refs,
    }
end

local function latest_unit_coverage(instance, policy_id)
    local observations = instance.boundary and instance.boundary.observations
        and instance.boundary.observations.upper or {}
    for index = #observations, 1, -1 do
        local candidate = observations[index].read_units
        if candidate and candidate.policy_id == policy_id then
            return candidate
        end
    end
    return nil
end

local function field_native_scope(instance, options)
    if type(options.unit_ids) ~= "table" or #options.unit_ids == 0 then
        return nil, "field-native OBSERVE requires unit_ids"
    end
    local entries = {}
    local refs = {}
    local content_status
    local seen = {}
    for _, unit_id in ipairs(options.unit_ids) do
        if type(unit_id) ~= "string" or unit_id == "" or seen[unit_id] then
            return nil, "field-native OBSERVE requires unique unit ids"
        end
        seen[unit_id] = true
        local unit = field.get_unit(instance, unit_id)
        if not unit then
            return nil, "field-native unit not found"
        end
        entries[#entries + 1] = {
            object_kind = "field_unit",
            object_id = unit.id,
            version = unit.version,
            activation_at_coverage = unit.activation,
            source_ref = unit.id,
            content_truth_status = unit.content_truth_status,
        }
        refs[#refs + 1] = unit.id
        local current = unit.content_truth_status or "unknown"
        if content_status == nil then
            content_status = current
        elseif content_status ~= current then
            content_status = "mixed"
        end
    end
    return {
        entries = entries,
        source_refs = refs,
        content_truth_status = content_status or "unknown",
    }
end

function observe.readiness(instance, options)
    options = options or {}
    if options.sensor == "field_native" then
        if not (instance.ingress
            and instance.ingress.integration_protocol == "vertical_packet_life.v0") then
            return {
                operator = "☴",
                ready = false,
                reason = "field_native_requires_vertical_packet_life",
                source_refs = {},
                required_capabilities = {},
                missing_capabilities = {},
                event_truth_status = "runtime_confirmed",
            }
        end
        local scope, scope_err = field_native_scope(instance, options)
        if not scope then
            return {
                operator = "☴",
                ready = false,
                reason = scope_err,
                source_refs = {},
                required_capabilities = {},
                missing_capabilities = {},
                event_truth_status = "runtime_confirmed",
            }
        end
        local delta, delta_err = object_coverage.diff(
            latest_unit_coverage(instance, "observe.field_native.v0"),
            scope.entries,
            {
                domain = "upper_observation",
                policy_id = "observe.field_native.v0",
            }
        )
        if not delta then
            return nil, delta_err
        end
        return {
            operator = "☴",
            ready = delta.changed_count > 0,
            reason = delta.changed_count > 0
                and "field_native_version_delta" or "field_native_current",
            source_refs = object_coverage.source_refs(delta),
            coverage_delta = delta,
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }, scope
    end
    if options.sensor ~= "relation_native" then
        return {
            operator = "☴",
            ready = true,
            reason = "ready",
            source_refs = ingress_refs(instance),
            required_capabilities = {"substrate.ask"},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    if not (instance.ingress
        and instance.ingress.integration_protocol == "vertical_packet_life.v0") then
        return {
            operator = "☴",
            ready = false,
            reason = "relation_native_requires_vertical_packet_life",
            source_refs = {},
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    local input, input_err = relation_input(options)
    if not input then
        return nil, input_err
    end
    local scope, scope_err = relation_native_scope(instance, input)
    if not scope then
        return {
            operator = "☴",
            ready = false,
            reason = scope_err,
            source_refs = {},
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    local prior_coverage = latest_unit_coverage(instance, "observe.relation_native.v0")
    local current_entries = {}
    for _, endpoint in ipairs(scope.endpoint_ids) do
        local unit = field.get_unit(instance, endpoint)
        if not unit then
            return {
                operator = "☴",
                ready = false,
                reason = "relation-native endpoint disappeared",
                source_refs = {},
                required_capabilities = {},
                missing_capabilities = {},
                event_truth_status = "runtime_confirmed",
            }
        end
        current_entries[#current_entries + 1] = {
            object_kind = "field_unit",
            object_id = unit.id,
            version = unit.version,
            activation_at_coverage = unit.activation,
            source_ref = unit.id,
            content_truth_status = unit.content_truth_status,
        }
    end
    local delta, delta_err = object_coverage.diff(prior_coverage, current_entries, {
        domain = "upper_observation",
        policy_id = "observe.relation_native.v0",
    })
    if not delta then
        return nil, delta_err
    end
    local terminal = false
    for _, item in ipairs(scope.relations) do
        if item.phase.phase == "encoded" or item.phase.phase == "released"
            or item.phase.phase == "expired" or item.phase.phase == "replaced" then
            terminal = true
        end
    end
    local ready = not terminal and delta.changed_count > 0
    return {
        operator = "☴",
        ready = ready,
        reason = ready and "relation_native_unobserved" or "relation_native_current",
        source_refs = object_coverage.source_refs(delta),
        required_capabilities = {},
        missing_capabilities = {},
        raw_epoch = input.raw_epoch,
        relation_ids = input.relation_ids,
        coverage_delta = delta,
        event_truth_status = "runtime_confirmed",
    }, scope
end

ingress_refs = function(instance)
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
    if options.sensor == "field_native" then
        local witness, scope_or_err = observe.readiness(instance, options)
        if not witness then
            return nil, scope_or_err
        end
        if not witness.ready then
            return nil, witness.reason
        end
        local scope = scope_or_err
        local read_revisions, revision_err = body.revision_snapshot(instance, "upper")
        if not read_revisions then
            return nil, revision_err
        end
        local read_units, coverage_err = object_coverage.capture(scope.entries, {
            domain = "upper_observation",
            policy_id = "observe.field_native.v0",
            global_revision = instance.revisions.potential,
        })
        if not read_units then
            return nil, coverage_err
        end
        local observation, observation_err = body.record_observation(instance, "upper", {
            scope_refs = scope.source_refs,
            read_revisions = read_revisions,
            read_units = read_units,
            payload = {
                kind = "field_native_observation",
                sensor = "field_native",
                unit_ids = options.unit_ids,
            },
            metrics = {
                unit_count = #scope.entries,
                substrate_call_count = 0,
            },
            source_refs = scope.source_refs,
            sensor_output_refs = {},
            content_truth_status = scope.content_truth_status,
            fidelity = "body_native",
        })
        if not observation then
            return nil, observation_err
        end
        return instance, {
            kind = "observe_organ_payload",
            sensor = "field_native",
            substrate_called = false,
            unit_ids = options.unit_ids,
            trace_event_id = observation.trace_event_id,
            observation_id = observation.id,
            field_unit_id = nil,
            truth_status = "runtime_confirmed",
            content_truth_status = scope.content_truth_status,
        }
    end
    if options.sensor == "relation_native" then
        local witness, scope_or_err = observe.readiness(instance, options)
        if not witness then
            return nil, scope_or_err
        end
        if not witness.ready then
            return nil, witness.reason
        end
        local scope = scope_or_err
        local input = assert(relation_input(options))
        local read_revisions, revision_err = body.revision_snapshot(instance, "upper")
        if not read_revisions then
            return nil, revision_err
        end
        local coverage_entries = {}
        for _, endpoint in ipairs(scope.endpoint_ids) do
            local unit = field.get_unit(instance, endpoint)
            if not unit then
                return nil, "relation-native endpoint disappeared"
            end
            coverage_entries[#coverage_entries + 1] = {
                object_kind = "field_unit",
                object_id = unit.id,
                version = unit.version,
                activation_at_coverage = unit.activation,
                source_ref = unit.id,
                content_truth_status = unit.content_truth_status,
            }
        end
        local read_units, coverage_err = object_coverage.capture(coverage_entries, {
            domain = "upper_observation",
            policy_id = "observe.relation_native.v0",
            global_revision = instance.revisions.potential,
        })
        if not read_units then
            return nil, coverage_err
        end
        local content_status = "unknown"
        for index, item in ipairs(scope.relations) do
            local current = item.relation.content_truth_status or "unknown"
            if index == 1 then
                content_status = current
            elseif content_status ~= current then
                content_status = "mixed"
            end
        end
        local observation, observation_err = body.record_observation(instance, "upper", {
            scope_refs = witness.source_refs,
            read_revisions = read_revisions,
            read_units = read_units,
            payload = {
                kind = "relation_native_observation",
                sensor = "relation_native",
                relation_input = {
                    raw_epoch = input.raw_epoch,
                    relation_ids = input.relation_ids,
                    endpoint_versions = input.endpoint_versions,
                    source_event_refs = input.source_event_refs or scope.source_refs,
                },
            },
            metrics = {
                relation_count = #scope.relations,
                endpoint_count = #scope.endpoint_ids,
                substrate_call_count = 0,
            },
            source_refs = input.source_event_refs or scope.source_refs,
            sensor_output_refs = {},
            content_truth_status = content_status,
            fidelity = "body_native",
        })
        if not observation then
            return nil, observation_err
        end
        return instance, {
            kind = "observe_organ_payload",
            sensor = "relation_native",
            substrate_called = false,
            raw_epoch = input.raw_epoch,
            relation_ids = input.relation_ids,
            endpoint_versions = input.endpoint_versions,
            trace_event_id = observation.trace_event_id,
            observation_id = observation.id,
            field_unit_id = nil,
            truth_status = "runtime_confirmed",
            content_truth_status = content_status,
        }
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
        sensor = "semantic",
        substrate_called = true,
        truth_status = "semantic_proposal",
    }
end

return observe
