local packet_core = require("core.packet")
local field = require("runtime.field")

local dissolve = {}

local allowed_reasons = {
    stale = true,
    rigid = true,
    rejected = true,
    contradictory = true,
    unsupported = true,
    explicitly_released = true,
}

local function trace_event(instance, event_id)
    for _, event in ipairs(instance.trace or {}) do
        if event.id == event_id then
            return event
        end
    end
    return nil
end

local function choose_relation(view, relation_id)
    for _, relation in ipairs(view.relations or {}) do
        if relation_id == nil or relation.id == relation_id then
            return relation
        end
    end
    return nil
end

local function reason_is_visible(instance, relation, reason)
    if type(reason) ~= "table" or not allowed_reasons[reason.kind] then
        return false
    end
    local event = trace_event(instance, reason.event_id)
    if not event or event.truth_status ~= "runtime_confirmed" then
        return false
    end
    local payload = event.payload or {}
    if payload.relation_id ~= relation.id and payload.target_ref ~= relation.id then
        return false
    end
    return payload.reason_kind == nil or payload.reason_kind == reason.kind
end

function dissolve.readiness(instance, options)
    options = options or {}
    local view, view_err = field.relation_view(instance, {
        scope = "active",
        relation_ids = options.relation_id and {options.relation_id} or nil,
        states = {active = true, weakened = true, locked = true},
        limit = options.limit or 64,
    })
    if not view then
        return nil, view_err
    end
    local relation = choose_relation(view, options.relation_id)
    local visible = relation and reason_is_visible(instance, relation, options.reason)
    local source_refs = {}
    if relation then
        source_refs[#source_refs + 1] = relation.id
    end
    if type(options.reason) == "table" and type(options.reason.event_id) == "string" then
        source_refs[#source_refs + 1] = options.reason.event_id
    end
    return {
        operator = "☷",
        ready = relation ~= nil and visible,
        reason = relation and visible and "ready" or "nothing_dissolvable",
        source_refs = source_refs,
        required_capabilities = {},
        missing_capabilities = {},
        relation_revision = view.source_revision,
        event_truth_status = "runtime_confirmed",
    }, relation
end

local function target_state(options)
    if options.target_state ~= nil then
        return options.target_state
    end
    local reason_kind = options.reason and options.reason.kind
    if reason_kind == "stale" or reason_kind == "rigid" then
        return "weakened"
    end
    return "dissolved"
end

local function loss_contract(options, target, preserve_residue)
    if target ~= "dissolved" or preserve_residue then
        return {
            kind = "dissolution_loss",
            amount = 0,
            irreversible = false,
            truth_status = "runtime_confirmed",
        }
    end
    local amount = options.irreversible_fraction
    if type(amount) ~= "number" or amount <= 0 or amount > 1 then
        return nil, "irreversible dissolution requires fraction in (0, 1]"
    end
    return {
        kind = "dissolution_loss",
        amount = amount,
        irreversible = true,
        truth_status = "runtime_confirmed",
    }
end

local function residue_carrier(relation, reason)
    return {
        kind = "relation_residue",
        relation_id = relation.id,
        from = relation.from,
        to = relation.to,
        relation_kind = relation.kind,
        prior_state = relation.state,
        release_reason = reason.kind,
    }
end

function dissolve.run(instance, options)
    options = options or {}
    local mutable, mutable_err = packet_core.assert_mutable(instance, "dissolve field relation")
    if not mutable then
        return nil, mutable_err
    end
    local witness, relation_or_err = dissolve.readiness(instance, options)
    if not witness then
        return nil, relation_or_err
    end
    if not witness.ready then
        return nil, witness.reason
    end
    local relation = relation_or_err
    local target = target_state(options)
    if target ~= "weakened" and target ~= "dissolved" then
        return nil, "DISSOLVE target_state must be weakened or dissolved"
    end
    local preserve_residue = options.preserve_residue
    if preserve_residue == nil then
        preserve_residue = target == "dissolved"
    end
    local loss, loss_err = loss_contract(options, target, preserve_residue)
    if not loss then
        return nil, loss_err
    end

    local mutation, mutation_err = field.weaken_relation(instance, "☷", relation.id, {
        target_state = target,
        reason_kind = options.reason.kind,
        event_id = options.reason.event_id,
    })
    if not mutation then
        return nil, mutation_err
    end

    local residue_unit
    if mutation.status == "applied" and target == "dissolved" and preserve_residue then
        local carrier = residue_carrier(relation, options.reason)
        local unit, unit_err = field.add_unit(instance, "☷", {
            kind = "dissolved_residue",
            carrier = carrier,
            source_refs = {relation.id, options.reason.event_id, mutation.trace_event_id},
            event_truth_status = "runtime_confirmed",
            content_truth_status = relation.content_truth_status or "unknown",
            created_event_id = mutation.trace_event_id,
        })
        if not unit then
            return nil, unit_err
        end
        residue_unit = unit
    end

    return instance, {
        kind = "dissolve_organ_payload",
        status = mutation.status,
        reason = options.reason,
        readiness = witness,
        reads = {
            relation_id = relation.id,
            relation_revision = witness.relation_revision,
        },
        writes = {
            relation_id = relation.id,
            relation_state = target,
            residue_unit_id = residue_unit and residue_unit.id or nil,
        },
        dissolution = mutation,
        residue = residue_unit,
        invalidations = {
            relations_active_revision = instance.revisions.relations_active,
            dependent_relation_ids = {relation.id},
        },
        loss = loss,
        trace_event_id = mutation.trace_event_id,
        event_truth_status = "runtime_confirmed",
        content_truth_status = relation.content_truth_status,
    }
end

return dissolve
