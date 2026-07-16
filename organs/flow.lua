local field = require("runtime.field")

local flow = {}

local function birth_event(instance)
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "birth" then
            return event
        end
    end
    return nil
end

function flow.run(instance, input)
    input = input or {}
    local event = birth_event(instance)
    if not event then
        return nil, "FLOW requires birth event"
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

    return instance, {
        kind = "flow_organ_payload",
        unit_id = unit.id,
        birth_event_id = event.id,
        shadow_only = true,
        truth_status = "runtime_confirmed",
    }
end

return flow
