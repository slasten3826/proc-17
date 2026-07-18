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
    snapshot_replaced = true,
}

local fixture_release_policies = {
    ["vertical.fixture.explicit_release.v0"] = {
        explicitly_released = true,
    },
    ["vertical.fixture.unsupported_release.v0"] = {
        unsupported = true,
    },
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

local function raw_reason_is_visible(instance, phase, relation, reason)
    if type(reason) ~= "table" or not allowed_reasons[reason.kind] then
        return false
    end
    if reason.kind == "stale" and phase.phase == "stale" then
        return true
    end
    if reason.kind == "snapshot_replaced" and phase.phase == "replaced" then
        return true
    end
    local policy = fixture_release_policies[reason.policy_id]
    if policy and policy[reason.kind]
        and instance.ingress
        and instance.ingress.integration_protocol == "vertical_packet_life.v0" then
        return true
    end
    local event = trace_event(instance, reason.event_id)
    if not event or event.truth_status ~= "runtime_confirmed" then
        return false
    end
    local payload = event.payload or {}
    local nested = payload.payload or {}
    local target = payload.relation_id or payload.target_ref
        or nested.relation_id or nested.target_ref
    local kind = payload.reason_kind or nested.reason_kind
    return target == relation.id and (kind == nil or kind == reason.kind)
end

local function raw_readiness(instance, options)
    if not (instance.ingress
        and instance.ingress.integration_protocol == "vertical_packet_life.v0") then
        return {
            operator = "☷",
            ready = false,
            reason = "raw_release_requires_vertical_packet_life",
            source_refs = {},
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    local relation, relation_err = field.raw_relation_exact(
        instance,
        options.raw_epoch,
        options.relation_id,
        options.endpoint_versions
    )
    if not relation then
        return {
            operator = "☷",
            ready = false,
            reason = relation_err,
            source_refs = {},
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    local phase, phase_err = field.raw_relation_phase(
        instance,
        options.raw_epoch,
        options.relation_id
    )
    if not phase then
        return nil, phase_err
    end
    local visible = raw_reason_is_visible(instance, phase, relation, options.reason)
    local phase_allows = phase.phase == "available" or phase.phase == "observed"
        or phase.phase == "stale" or phase.phase == "replaced"
    local refs = {relation.id}
    for endpoint, version in pairs(relation.endpoint_versions or {}) do
        refs[#refs + 1] = table.concat({
            "coverage", "field_unit", endpoint, tostring(version),
        }, ":")
    end
    if options.reason and options.reason.event_id then
        refs[#refs + 1] = options.reason.event_id
    elseif options.reason and options.reason.policy_id then
        refs[#refs + 1] = "policy:" .. options.reason.policy_id
    end
    return {
        operator = "☷",
        ready = phase_allows and visible,
        reason = phase_allows and visible and "raw_relation_releasable"
            or (not phase_allows and ("raw_relation_" .. phase.phase)
                or "raw_release_reason_not_visible"),
        source_refs = refs,
        required_capabilities = {},
        missing_capabilities = {},
        raw_phase = phase.phase,
        event_truth_status = "runtime_confirmed",
    }, relation, phase
end

function dissolve.readiness(instance, options)
    options = options or {}
    if options.scope == "raw" then
        return raw_readiness(instance, options)
    end
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
    if options.scope == "raw" then
        local release, release_relation = field.release_raw_relation(instance, "☷", {
            raw_epoch = options.raw_epoch,
            relation_id = options.relation_id,
            endpoint_versions = options.endpoint_versions,
            reason = options.reason,
            source_event_refs = options.source_event_refs,
        })
        if not release then
            return nil, release_relation
        end
        local residue_unit
        if options.preserve_residue == true then
            local carrier = residue_carrier(release_relation, options.reason)
            local unit, unit_err = field.add_unit(instance, "☷", {
                kind = "raw_relation_residue",
                carrier = carrier,
                source_refs = {
                    release_relation.id,
                    release_relation.origin_event_id,
                    release.trace_event_id,
                },
                event_truth_status = "runtime_confirmed",
                content_truth_status = release_relation.content_truth_status or "unknown",
                created_event_id = release.trace_event_id,
                migration = {
                    status = "released_raw_residue",
                    raw_epoch = options.raw_epoch,
                    relation_id = release_relation.id,
                },
            })
            if not unit then
                return nil, unit_err
            end
            residue_unit = unit
        end
        return instance, {
            kind = "dissolve_organ_payload",
            mode = "raw_release",
            status = "applied",
            reason = options.reason,
            readiness = witness,
            reads = {
                raw_epoch = options.raw_epoch,
                relation_id = release_relation.id,
                endpoint_versions = release_relation.endpoint_versions,
            },
            writes = {
                disposition = "released",
                residue_unit_id = residue_unit and residue_unit.id,
            },
            dissolution = release,
            residue = residue_unit,
            loss = {
                kind = "none",
                amount = 0,
                truth_status = "runtime_confirmed",
            },
            trace_event_id = release.trace_event_id,
            event_truth_status = "runtime_confirmed",
            content_truth_status = release_relation.content_truth_status,
        }
    end
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
