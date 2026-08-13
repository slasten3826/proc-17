local packet_core = require("core.packet")
local field = require("runtime.field")
local body = require("runtime.body")
local dissolve_schema = require("core.dissolve_schema")
local network_projection_schema = require("core.network_projection_schema")
local json = require("core.json")

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

local function copy_value(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

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

local function same(left, right)
    return json.encode(left) == json.encode(right)
end

local function sorted_unique(values)
    local result, seen = {}, {}
    for _, value in ipairs(values or {}) do
        if type(value) ~= "string" or value == "" or seen[value] then
            return nil
        end
        seen[value] = true
        result[#result + 1] = value
    end
    table.sort(result)
    return result
end

local function unit_release_event(instance, target_id, projection_id)
    local found
    for _, event in ipairs(instance.trace or {}) do
        local payload = event.payload or {}
        if event.type == "unit_dissolution"
            and payload.target and payload.target.id == target_id
            and payload.reason
            and payload.reason.network_projection_id == projection_id then
            if found then return nil, "multiple inherited-form release events" end
            found = event
        end
    end
    return found
end

local function unit_readiness(instance, options)
    if instance.status == "dead" or instance.status == "dying"
        or instance.status == "manifested" then
        return {
            operator = "☷",
            ready = false,
            reason = "packet_terminal",
            source_refs = {},
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    local target = options.target
    local qualified_action = options.qualified_action
    if options.scope ~= "unit" or options.preserve_residue ~= true
        or type(target) ~= "table" or target.kind ~= "unit"
        or type(target.id) ~= "string"
        or type(target.version) ~= "number" or target.version < 1
        or target.version ~= math.floor(target.version)
        or type(qualified_action) ~= "table"
        or type(qualified_action.plan_id) ~= "string"
        or type(qualified_action.scope_refs) ~= "table"
        or type(qualified_action.planned_residue_unit_id) ~= "string"
        or type(qualified_action.potential_revision) ~= "number" then
        return {
            operator = "☷",
            ready = false,
            reason = "nothing_dissolvable",
            source_refs = {},
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    local reason, reason_err = dissolve_schema.normalize_inherited_reason(
        options.reason
    )
    if not reason or not dissolve_schema.same(reason, options.reason) then
        return nil, reason_err or "DISSOLVE reason is not normalized"
    end
    local projection = instance.ingress and instance.ingress.network_projection
    local projection_ok, projection_err =
        network_projection_schema.verify_projection(projection)
    if not projection_ok then return nil, projection_err end
    local form = projection.rejected_form
    local expected_reason = {
        kind = "rejected",
        subtype = "ancestor_candidate",
        network_projection_id = projection.projection_id,
        carrier_id = projection.carrier_id,
        source_corpse_id = projection.source_corpse_id,
        historical_qa_id = projection.historical_qa_id,
        candidate_seal_id = form.candidate_seal_id,
        verdict_id = form.verdict_id,
    }
    if not dissolve_schema.same(reason, expected_reason) then
        return nil, "DISSOLVE reason contradicts NETWORK projection"
    end
    local expected_scope = {
        table.concat({
            "coverage", "field_unit", target.id, tostring(target.version),
        }, ":"),
        reason.network_projection_id,
        reason.carrier_id,
        reason.source_corpse_id,
        reason.historical_qa_id,
        reason.candidate_seal_id,
        reason.verdict_id,
    }
    table.sort(expected_scope)
    local scope = sorted_unique(qualified_action.scope_refs)
    if not scope or not same(scope, expected_scope)
        or not same(scope, qualified_action.scope_refs) then
        return nil, "DISSOLVE readiness scope contradicts action"
    end
    local existing, existing_err = unit_release_event(
        instance,
        target.id,
        projection.projection_id
    )
    if existing_err then return nil, existing_err end
    local unit = field.get_unit(instance, target.id)
    if existing then
        local release_ok, release_err = dissolve_schema.verify_release(
            existing.payload
        )
        if not release_ok then return nil, release_err end
        local residue = field.get_unit(instance, existing.payload.residue_unit_id)
        if not unit or unit.activation ~= "dissolved"
            or unit.version ~= existing.payload.target.after_version
            or not residue or residue.kind ~= "rejected_form_residue"
            or residue.created_event_id ~= existing.id
            or not dissolve_schema.verify_residue_carrier(residue.carrier)
            or residue.carrier.release_id ~= existing.payload.release_id then
            return nil, "release event contradicts current field state"
        end
        return {
            operator = "☷",
            ready = false,
            reason = "already_released",
            target = copy_value(existing.payload.target),
            source_refs = scope,
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }, unit
    end
    local migration = unit and unit.migration or {}
    local created = unit and trace_event(instance, unit.created_event_id)
    if not unit or unit.kind ~= "inherited_rejected_form"
        or unit.id ~= target.id or unit.version ~= target.version
        or unit.generation ~= instance.generation
        or (unit.activation ~= "live" and unit.activation ~= "selected")
        or unit.created_by ~= "▽"
        or unit.event_truth_status ~= "runtime_confirmed"
        or unit.content_truth_status ~= "inherited_proposal"
        or not network_projection_schema.same(unit.carrier, form)
        or not network_projection_schema.same(unit.source_refs, form.source_refs)
        or migration.status ~= "network_reentry_v1"
        or migration.projection_id ~= projection.projection_id
        or migration.rejected_form_id ~= form.projection_id
        or type(created) ~= "table" or created.type ~= "birth"
        or created.payload.network_projection_id ~= projection.projection_id then
        return nil, "DISSOLVE inherited target contradicts ingress"
    end
    local planned, planned_err = field.plan_unit_ids(instance, 1)
    if not planned then return nil, planned_err end
    if planned[1] ~= qualified_action.planned_residue_unit_id
        or instance.revisions.potential
            ~= qualified_action.potential_revision then
        return nil, "DISSOLVE readiness preconditions are stale"
    end
    return {
        operator = "☷",
        ready = true,
        reason = "inherited_rejected_form_releasable",
        target = copy_value(target),
        source_refs = scope,
        required_capabilities = {},
        missing_capabilities = {},
        event_truth_status = "runtime_confirmed",
    }, unit
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
    if options.scope == "unit" then
        return unit_readiness(instance, options)
    end
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
    if options.scope == "unit" then
        local qualified_action = options.qualified_action
        local release, residue, event, released_target =
            body.release_inherited_rejected_form(instance, {
                target = options.target,
                reason = options.reason,
                preserve_residue = options.preserve_residue,
                source_refs = qualified_action.scope_refs,
                planned_residue_unit_id =
                    qualified_action.planned_residue_unit_id,
                potential_revision = qualified_action.potential_revision,
            })
        if not release then return nil, residue end
        return instance, {
            kind = "dissolve_organ_payload",
            mode = "inherited_rejected_form_release",
            status = "applied",
            readiness = witness,
            reads = {
                target_unit_id = options.target.id,
                target_before_version = options.target.version,
                network_projection_id =
                    options.reason.network_projection_id,
            },
            writes = {
                target_after_version = released_target.version,
                target_activation = released_target.activation,
                residue_unit_id = residue.id,
            },
            dissolution = release,
            residue = residue,
            released_mass = {forms = 1, relations = 0},
            loss = {
                kind = "dissolution_loss",
                amount = 0,
                irreversible = false,
                truth_status = "runtime_confirmed",
            },
            trace_event_id = event.id,
            effect_scope_refs = copy_value(qualified_action.scope_refs),
            event_truth_status = "runtime_confirmed",
            content_truth_status = "mixed",
        }
    end
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
