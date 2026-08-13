local field = require("runtime.field")
local network_projection_schema = require("core.network_projection_schema")
local json = require("core.json")

local flow = {}

local function copy_value(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function birth_event(instance)
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "birth" then
            return event
        end
    end
    return nil
end

local function materialize_network_reentry(instance, event, projection)
    local valid, valid_err = network_projection_schema.verify_projection(projection)
    if not valid then return nil, valid_err end
    if projection.terminal_recovery_basis ~= "qa_rejected"
        or projection.lineage_id ~= instance.lineage_id
        or projection.target_generation ~= instance.generation
        or projection.source_generation ~= instance.generation - 1
        or projection.source_packet_id ~= instance.parent_id
        or projection.source_corpse_id ~= instance.parent_corpse_id
        or projection.carrier_id ~= instance.carrier_id
        or projection.process_contract_id ~= instance.process_contract_id
        or projection.context ~= instance.work_context
        or projection.stage_id ~= instance.stage_id
        or instance.chaos.raw_prompt ~= json.encode(projection.current_work) then
        return nil, "FLOW NETWORK projection diverged from Packet birth"
    end

    local current, current_err = field.add_unit(instance, "▽", {
        kind = "network_current_work",
        carrier = copy_value(projection.current_work),
        source_refs = {
            projection.projection_id,
            projection.carrier_id,
            projection.source_corpse_id,
        },
        event_truth_status = "runtime_confirmed",
        content_truth_status = projection.current_work.content_truth_status,
        activation = "live",
        created_event_id = event.id,
        migration = {
            status = "network_reentry_v1",
            projection_id = projection.projection_id,
            projection_role = "current_work",
        },
    })
    if not current then return nil, current_err end

    local rejected, rejected_err = field.add_unit(instance, "▽", {
        kind = "inherited_rejected_form",
        carrier = copy_value(projection.rejected_form),
        source_refs = copy_value(projection.rejected_form.source_refs),
        event_truth_status = "runtime_confirmed",
        content_truth_status = "inherited_proposal",
        activation = "live",
        created_event_id = event.id,
        migration = {
            status = "network_reentry_v1",
            projection_id = projection.projection_id,
            rejected_form_id = projection.rejected_form.projection_id,
            projection_role = "rejected_form",
        },
    })
    if not rejected then return nil, rejected_err end

    return instance, {
        kind = "flow_organ_payload",
        unit_id = current.id,
        unit_ids = {current.id, rejected.id},
        materialized = {
            {
                unit_id = current.id,
                provenance_class = "network_current_work",
                content_truth_status = current.content_truth_status,
            },
            {
                unit_id = rejected.id,
                provenance_class = "inherited_rejected_form",
                content_truth_status = rejected.content_truth_status,
            },
        },
        birth_event_id = event.id,
        shadow_only = false,
        integration_protocol = instance.ingress.integration_protocol,
        network_projection_id = projection.projection_id,
        flow_ref = instance.ingress.flow_mark and {
            stream_id = instance.ingress.flow_mark.stream_id,
            stream_epoch = instance.ingress.flow_mark.stream_epoch,
            birth_seq = instance.ingress.flow_mark.birth_seq,
        } or nil,
        truth_status = "runtime_confirmed",
    }
end

function flow.run(instance, input)
    input = input or {}
    local event = birth_event(instance)
    if not event then
        return nil, "FLOW requires birth event"
    end
    local existing = field.view(instance, {created_by = "▽", limit = 1})
    if existing and existing.total_count > 0 then
        return nil, "FLOW already materialized"
    end

    local ingress = instance.ingress or {}
    if ingress.network_projection ~= nil then
        return materialize_network_reentry(
            instance,
            event,
            ingress.network_projection
        )
    end

    local carrier = input.carrier
    if carrier == nil then
        carrier = instance.chaos and instance.chaos.raw_prompt or nil
    end
    local source_refs = input.source_refs
    if source_refs == nil then
        source_refs = instance.birth_kind == "user" and {} or {instance.carrier_id}
    end
    local unit, unit_err = field.add_unit(instance, "▽", {
        kind = input.kind or (instance.birth_kind == "user" and "user_prompt" or "network_carrier"),
        carrier = carrier,
        carrier_ref = input.carrier_ref,
        source_refs = source_refs,
        event_truth_status = "runtime_confirmed",
        content_truth_status = input.content_truth_status or "semantic_proposal",
        created_event_id = event.id,
        migration = {
            status = "shadow_only",
            legacy_ref = "chaos:raw_prompt",
        },
    })
    if not unit then
        return nil, unit_err
    end

    local unit_ids = {unit.id}
    local materialized = {{
        unit_id = unit.id,
        provenance_class = instance.birth_kind == "user" and "prompt" or "carrier",
        content_truth_status = unit.content_truth_status,
    }}

    local projection = ingress.l1_projection
    for _, projected in ipairs(projection and projection.units or {}) do
        local projected_unit, projected_err = field.add_unit(instance, "▽", {
            kind = projected.kind,
            carrier = copy_value(projected.carrier),
            source_refs = copy_value(projected.source_refs),
            event_truth_status = projected.event_truth_status,
            content_truth_status = projected.content_truth_status,
            created_event_id = event.id,
            migration = {
                status = "vertical_fixture_only",
                protocol_version = projection.protocol_version,
                adapter_id = projection.adapter_id,
                projection_key = projected.projection_key,
                flow_ref = copy_value(projection.flow_ref),
            },
        })
        if not projected_unit then
            return nil, projected_err
        end
        unit_ids[#unit_ids + 1] = projected_unit.id
        materialized[#materialized + 1] = {
            unit_id = projected_unit.id,
            projection_key = projected.projection_key,
            provenance_class = "l1_projection",
            content_truth_status = projected_unit.content_truth_status,
        }
    end

    local karma = instance.runtime and instance.runtime.karma or {}
    for _, grave_kind in ipairs({"warnings", "bequests"}) do
        for _, record in ipairs(karma[grave_kind] or {}) do
            local grave_unit, grave_err = field.add_unit(instance, "▽", {
                kind = grave_kind == "warnings" and "grave_warning" or "grave_bequest",
                carrier = copy_value(record),
                source_refs = {record.source_packet_id},
                event_truth_status = "runtime_confirmed",
                content_truth_status = record.applicability_truth_status or "grave_pressure",
                created_event_id = event.id,
                migration = {
                    status = "inherited_pressure",
                    source_packet_id = record.source_packet_id,
                    grave_kind = record.grave_kind,
                },
            })
            if not grave_unit then
                return nil, grave_err
            end
            unit_ids[#unit_ids + 1] = grave_unit.id
            materialized[#materialized + 1] = {
                unit_id = grave_unit.id,
                provenance_class = "grave_" .. record.grave_kind,
                content_truth_status = grave_unit.content_truth_status,
            }
        end
    end

    return instance, {
        kind = "flow_organ_payload",
        unit_id = unit.id,
        unit_ids = unit_ids,
        materialized = materialized,
        birth_event_id = event.id,
        shadow_only = true,
        integration_protocol = ingress.integration_protocol,
        flow_ref = ingress.flow_mark and {
            stream_id = ingress.flow_mark.stream_id,
            stream_epoch = ingress.flow_mark.stream_epoch,
            birth_seq = ingress.flow_mark.birth_seq,
        } or nil,
        truth_status = "runtime_confirmed",
    }
end

return flow
