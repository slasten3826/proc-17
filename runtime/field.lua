local packet_core = require("core.packet")
local topology = require("core.topology")

local field = {}

local FIELD_PROTOCOL = "field.v0"

local add_unit_rights = {
    ["▽"] = true,
    ["☴"] = true,
    ["☷"] = true,
    ["☵"] = true,
}

local activations = {
    live = true,
    selected = true,
    suppressed = true,
    dissolved = true,
}

local relation_states = {
    raw = true,
    active = true,
    weakened = true,
    locked = true,
    dissolved = true,
}

local dissolve_reasons = {
    stale = true,
    rigid = true,
    rejected = true,
    contradictory = true,
    unsupported = true,
    explicitly_released = true,
}

local logic_reasons = {
    rejected = true,
    invalid = true,
    unsupported = true,
    violated_constraint = true,
}

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

local function copy_array(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = copy_value(value)
    end
    return result
end

local function new_root()
    return {
        protocol_version = FIELD_PROTOCOL,
        next_unit_id = 1,
        next_relation_id = 1,
        unit_order = {},
        units = {},
        relations = {
            raw = {
                epoch = 0,
                source_revision = 0,
                items = {},
            },
            active = {},
            momentum = {},
        },
        identity_maps = {},
    }
end

local function root(instance)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    if type(instance.field) ~= "table" or instance.field.protocol_version ~= FIELD_PROTOCOL then
        return nil, "canonical field is not initialized"
    end
    return instance.field
end

local function actor_glyph(actor)
    local glyph = topology.resolve(actor)
    if not glyph then
        return nil, "invalid field actor"
    end
    return glyph
end

local function find_event(instance, event_id)
    for _, event in ipairs(instance.trace or {}) do
        if event.id == event_id then
            return event
        end
    end
    return nil
end

local function validate_source_refs(source_refs, allow_empty)
    if type(source_refs) ~= "table" then
        return nil, "field unit source_refs must be table"
    end
    if #source_refs == 0 and not allow_empty then
        return nil, "field unit source_refs must be non-empty"
    end
    for _, ref in ipairs(source_refs) do
        if type(ref) ~= "string" or ref == "" then
            return nil, "field unit source ref must be non-empty string"
        end
    end
    return true
end

local function next_unit_id(root_value, offset)
    return "unit:" .. tostring(root_value.next_unit_id + (offset or 0))
end

local function next_relation_id(root_value, offset)
    return "relation:" .. tostring(root_value.next_relation_id + (offset or 0))
end

local function valid_content_status(value)
    return type(value) == "string" and value ~= ""
end

local function normalize_filter(value)
    if value == nil then
        return nil
    end
    if type(value) == "string" then
        return {[value] = true}
    end
    if type(value) ~= "table" then
        return nil, "field view filter must be string or table"
    end

    local result = {}
    for key, child in pairs(value) do
        if type(key) == "number" then
            result[child] = true
        elseif child then
            result[key] = true
        end
    end
    return result
end

local function unit_matches(unit, filters)
    if filters.unit_ids and not filters.unit_ids[unit.id] then
        return false
    end
    if filters.created_by and not filters.created_by[unit.created_by] then
        return false
    end
    if filters.activation and not filters.activation[unit.activation] then
        return false
    end
    if filters.kinds and not filters.kinds[unit.kind] then
        return false
    end
    if filters.generation and unit.generation ~= filters.generation then
        return false
    end
    return true
end

function field.init(instance)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    if instance.field ~= nil then
        return root(instance)
    end

    -- Compatibility initializer for packets created before packet.next.v1.
    local mutable, mutable_err = packet_core.assert_mutable(instance, "initialize field")
    if not mutable then
        return nil, mutable_err
    end
    instance.field = new_root()
    return instance.field
end

function field.plan_unit_ids(instance, count)
    local root_value, root_err = root(instance)
    if not root_value then
        return nil, root_err
    end
    if type(count) ~= "number" or count < 0 or count ~= math.floor(count) then
        return nil, "field unit plan count must be a non-negative integer"
    end

    local ids = {}
    for offset = 0, count - 1 do
        ids[#ids + 1] = next_unit_id(root_value, offset)
    end
    return ids
end

function field.add_unit(instance, actor, input)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "add field unit")
    if not mutable then
        return nil, mutable_err
    end
    local root_value, root_err = root(instance)
    if not root_value then
        return nil, root_err
    end
    local glyph, glyph_err = actor_glyph(actor)
    if not glyph then
        return nil, glyph_err
    end
    if not add_unit_rights[glyph] then
        return nil, "field actor cannot add units"
    end

    input = input or {}
    if type(input.kind) ~= "string" or input.kind == "" then
        return nil, "field unit kind is required"
    end
    if input.carrier == nil and (type(input.carrier_ref) ~= "string" or input.carrier_ref == "") then
        return nil, "field unit requires carrier or carrier_ref"
    end
    local refs_ok, refs_err = validate_source_refs(
        input.source_refs,
        glyph == "▽" and instance.birth_kind == "user"
    )
    if not refs_ok then
        return nil, refs_err
    end
    if not packet_core.truth_statuses[input.event_truth_status or "runtime_confirmed"] then
        return nil, "invalid field unit event truth status"
    end
    if not valid_content_status(input.content_truth_status or "unknown") then
        return nil, "invalid field unit content truth status"
    end
    if input.density ~= nil and type(input.density) ~= "number" then
        return nil, "field unit density must be number when present"
    end
    local activation = input.activation or "live"
    if not activations[activation] then
        return nil, "invalid field unit activation"
    end
    if type(input.created_event_id) ~= "string" or input.created_event_id == "" then
        return nil, "field unit created_event_id is required"
    end
    local creation_event = find_event(instance, input.created_event_id)
    if not creation_event then
        return nil, "field unit creation event not found"
    end
    if creation_event.operator ~= glyph then
        return nil, "field unit creation event actor mismatch"
    end

    local expected_id = next_unit_id(root_value)
    if input.id ~= nil and input.id ~= expected_id then
        return nil, "field unit id does not match next deterministic id"
    end

    local unit = {
        id = expected_id,
        kind = input.kind,
        carrier = copy_value(input.carrier),
        carrier_ref = input.carrier_ref,
        source_refs = copy_array(input.source_refs),
        event_truth_status = input.event_truth_status or "runtime_confirmed",
        content_truth_status = input.content_truth_status or "unknown",
        activation = activation,
        created_by = glyph,
        created_event_id = input.created_event_id,
        generation = instance.generation,
        version = 1,
    }
    if input.density ~= nil then
        unit.density = input.density
    end
    if input.migration ~= nil then
        unit.migration = copy_value(input.migration)
    end

    root_value.units[unit.id] = unit
    root_value.unit_order[#root_value.unit_order + 1] = unit.id
    root_value.next_unit_id = root_value.next_unit_id + 1
    instance.revisions.potential = instance.revisions.potential + 1
    return copy_value(unit)
end

function field.get_unit(instance, id)
    local root_value = root(instance)
    if not root_value then
        return nil
    end
    return copy_value(root_value.units[id])
end

function field.set_activation(instance, actor, id, activation, source)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "set field activation")
    if not mutable then
        return nil, mutable_err
    end
    local root_value, root_err = root(instance)
    if not root_value then
        return nil, root_err
    end
    local glyph, glyph_err = actor_glyph(actor)
    if not glyph then
        return nil, glyph_err
    end
    if glyph ~= "☳" and glyph ~= "☷" then
        return nil, "field actor cannot set activation"
    end
    if glyph == "☳" and activation ~= "selected" and activation ~= "suppressed" then
        return nil, "CHOOSE may only select or suppress field units"
    end
    if glyph == "☷" and activation ~= "dissolved" then
        return nil, "DISSOLVE may only dissolve field units"
    end

    local unit = root_value.units[id]
    if not unit then
        return nil, "field unit not found"
    end
    if unit.activation == "dissolved" and activation ~= "dissolved" then
        return nil, "dissolved field unit cannot be reactivated"
    end
    source = source or {}
    if type(source.event_id) ~= "string" or source.event_id == "" then
        return nil, "field activation source event is required"
    end
    local source_event = find_event(instance, source.event_id)
    if not source_event then
        return nil, "field activation source event not found"
    end
    if source_event.operator ~= glyph then
        return nil, "field activation source actor mismatch"
    end
    if unit.activation == activation then
        return copy_value(unit)
    end

    unit.activation = activation
    unit.activation_source = {
        event_id = source.event_id,
        actor = glyph,
        reason = source.reason,
    }
    unit.version = unit.version + 1
    instance.revisions.potential = instance.revisions.potential + 1
    return copy_value(unit)
end

local function validate_relation_candidate(root_value, candidate, planned_id)
    if type(candidate) ~= "table" then
        return nil, "relation candidate must be table"
    end
    if type(candidate.from) ~= "string" or type(candidate.to) ~= "string" then
        return nil, "relation endpoints are required"
    end
    local from_unit = root_value.units[candidate.from]
    local to_unit = root_value.units[candidate.to]
    if not from_unit or not to_unit then
        return nil, "relation endpoint not found"
    end
    if from_unit.generation ~= to_unit.generation then
        return nil, "relation endpoints must share generation"
    end
    if candidate.from == candidate.to and candidate.allow_self ~= true then
        return nil, "self relation requires explicit permission"
    end
    if type(candidate.kind) ~= "string" or candidate.kind == "" then
        return nil, "relation kind is required"
    end
    local refs_ok, refs_err = validate_source_refs(candidate.source_refs, false)
    if not refs_ok then
        return nil, refs_err
    end
    if candidate.weight ~= nil and type(candidate.weight) ~= "number" then
        return nil, "relation weight must be number when present"
    end
    if candidate.confidence ~= nil
        and (type(candidate.confidence) ~= "number" or candidate.confidence < 0 or candidate.confidence > 1) then
        return nil, "relation confidence must be between zero and one"
    end
    if candidate.event_truth_status ~= nil and candidate.event_truth_status ~= "runtime_confirmed" then
        return nil, "relation detection event must be runtime-confirmed"
    end
    if not valid_content_status(candidate.content_truth_status or "unknown") then
        return nil, "invalid relation content truth status"
    end

    return {
        id = planned_id,
        from = candidate.from,
        to = candidate.to,
        kind = candidate.kind,
        weight = candidate.weight,
        confidence = candidate.confidence,
        state = "raw",
        source_refs = copy_array(candidate.source_refs),
        event_truth_status = candidate.event_truth_status or "runtime_confirmed",
        content_truth_status = candidate.content_truth_status or "unknown",
        observed_tick = candidate.observed_tick,
        endpoint_versions = {
            [candidate.from] = from_unit.version,
            [candidate.to] = to_unit.version,
        },
        self_relation = candidate.from == candidate.to or nil,
        version = 1,
    }
end

function field.snapshot_raw_relations(instance, actor, input)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "snapshot raw field relations")
    if not mutable then
        return nil, mutable_err
    end
    local root_value, root_err = root(instance)
    if not root_value then
        return nil, root_err
    end
    local glyph, glyph_err = actor_glyph(actor)
    if not glyph then
        return nil, glyph_err
    end
    if glyph ~= "☰" then
        return nil, "only CONNECT may snapshot raw relations"
    end

    input = input or {}
    if type(input.items) ~= "table" then
        return nil, "raw relation snapshot items must be table"
    end
    local refs_ok, refs_err = validate_source_refs(input.source_refs, false)
    if not refs_ok then
        return nil, refs_err
    end
    if input.coverage ~= nil and type(input.coverage) ~= "table" then
        return nil, "raw relation snapshot coverage must be table"
    end
    if not valid_content_status(input.content_truth_status or "unknown") then
        return nil, "invalid raw relation snapshot content truth status"
    end
    local source_revision = input.source_revision
    if type(source_revision) ~= "number" or source_revision ~= instance.revisions.potential then
        return nil, "raw relation snapshot source revision is stale"
    end

    local relations = {}
    local seen = {}
    for index, candidate in ipairs(input.items) do
        local relation, relation_err = validate_relation_candidate(
            root_value,
            candidate,
            next_relation_id(root_value, index - 1)
        )
        if not relation then
            return nil, relation_err
        end
        relation.observed_tick = relation.observed_tick
            or (instance.physis and instance.physis.clock and instance.physis.clock.ticks)
        local key = relation.from .. "\0" .. relation.to .. "\0" .. relation.kind
        if seen[key] then
            return nil, "duplicate relation candidate"
        end
        seen[key] = true
        relations[#relations + 1] = relation
    end

    local previous_raw = root_value.relations.raw
    local previous_next_id = root_value.next_relation_id
    local previous_revision = instance.revisions.relations_raw
    local snapshot = {
        kind = "raw_relation_snapshot",
        epoch = (previous_raw.epoch or 0) + 1,
        source_revision = source_revision,
        items = relations,
        source_refs = copy_array(input.source_refs),
        coverage = copy_value(input.coverage or {}),
        event_truth_status = "runtime_confirmed",
        content_truth_status = input.content_truth_status or "unknown",
    }

    root_value.relations.raw = snapshot
    root_value.next_relation_id = root_value.next_relation_id + #relations
    instance.revisions.relations_raw = instance.revisions.relations_raw + 1
    local event, event_err = packet_core.append_event(instance, {
        type = "relation_snapshot",
        operator = "☰",
        truth_status = "runtime_confirmed",
        payload = snapshot,
        cost = {},
    })
    if not event then
        root_value.relations.raw = previous_raw
        root_value.next_relation_id = previous_next_id
        instance.revisions.relations_raw = previous_revision
        return nil, event_err
    end
    snapshot.trace_event_id = event.id
    for _, relation in ipairs(relations) do
        relation.origin_event_id = event.id
    end
    return copy_value(snapshot)
end

local function raw_relation_by_id(root_value, relation_id)
    for _, relation in ipairs(root_value.relations.raw.items or {}) do
        if relation.id == relation_id then
            return relation
        end
    end
    return nil
end

function field.activate_relations(instance, actor, relation_ids, source)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "activate field relations")
    if not mutable then
        return nil, mutable_err
    end
    local root_value, root_err = root(instance)
    if not root_value then
        return nil, root_err
    end
    local glyph, glyph_err = actor_glyph(actor)
    if not glyph then
        return nil, glyph_err
    end
    if glyph ~= "☱" then
        return nil, "only RUNTIME may activate raw relations"
    end
    if type(relation_ids) ~= "table" then
        return nil, "relation_ids must be table"
    end
    if root_value.relations.raw.source_revision ~= instance.revisions.potential then
        return nil, "raw relation snapshot is stale"
    end

    local planned = {}
    local seen = {}
    for _, relation_id in ipairs(relation_ids) do
        if type(relation_id) ~= "string" or seen[relation_id] then
            return nil, "invalid relation activation id"
        end
        seen[relation_id] = true
        local raw_relation = raw_relation_by_id(root_value, relation_id)
        if not raw_relation then
            return nil, "raw relation not found"
        end
        local current = root_value.relations.active[relation_id]
        if current and current.state ~= "active" then
            return nil, "non-active relation requires a fresh raw identity before activation"
        end
        if not current then
            local active = copy_value(raw_relation)
            active.state = "active"
            active.version = raw_relation.version + 1
            active.activated_from_epoch = root_value.relations.raw.epoch
            planned[#planned + 1] = active
        end
    end

    if #planned == 0 then
        return {
            kind = "relation_activation_payload",
            status = "no_op",
            relation_ids = {},
            truth_status = "runtime_confirmed",
        }
    end

    source = source or {}
    if source.event_id ~= nil then
        local source_event = find_event(instance, source.event_id)
        if not source_event then
            return nil, "relation activation source event not found"
        end
        if source_event.truth_status ~= "runtime_confirmed" then
            return nil, "relation activation source must be runtime-confirmed"
        end
    end
    local previous = {}
    for _, relation in ipairs(planned) do
        previous[relation.id] = root_value.relations.active[relation.id]
        root_value.relations.active[relation.id] = relation
    end
    local previous_revision = instance.revisions.relations_active
    instance.revisions.relations_active = instance.revisions.relations_active + 1
    local payload = {
        kind = "relation_activation_payload",
        status = "applied",
        relation_ids = {},
        raw_epoch = root_value.relations.raw.epoch,
        source_event_id = source.event_id,
        reason = source.reason,
        truth_status = "runtime_confirmed",
    }
    for _, relation in ipairs(planned) do
        payload.relation_ids[#payload.relation_ids + 1] = relation.id
    end
    local event, event_err = packet_core.append_event(instance, {
        type = "relation_mutation",
        operator = "☱",
        truth_status = "runtime_confirmed",
        payload = payload,
        cost = {},
    })
    if not event then
        for relation_id, prior in pairs(previous) do
            root_value.relations.active[relation_id] = prior
        end
        instance.revisions.relations_active = previous_revision
        return nil, event_err
    end
    payload.trace_event_id = event.id
    for _, relation in ipairs(planned) do
        relation.activation_event_id = event.id
    end
    return copy_value(payload)
end

local function reason_rights(glyph, reason_kind, target_state)
    if glyph == "☷" then
        return dissolve_reasons[reason_kind]
            and (target_state == "weakened" or target_state == "dissolved")
    end
    if glyph == "☶" then
        return logic_reasons[reason_kind]
            and (target_state == "weakened" or target_state == "locked")
    end
    return false
end

function field.weaken_relation(instance, actor, relation_id, source)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "weaken field relation")
    if not mutable then
        return nil, mutable_err
    end
    local root_value, root_err = root(instance)
    if not root_value then
        return nil, root_err
    end
    local glyph, glyph_err = actor_glyph(actor)
    if not glyph then
        return nil, glyph_err
    end
    source = source or {}
    local target_state = source.target_state
    local reason_kind = source.reason_kind
    if not reason_rights(glyph, reason_kind, target_state) then
        return nil, "field actor cannot apply requested relation weakening"
    end

    local relation = root_value.relations.active[relation_id]
    if not relation then
        return nil, "active relation not found"
    end
    if relation.state == "dissolved" and target_state ~= "dissolved" then
        return nil, "dissolved relation cannot be restored"
    end
    if type(source.event_id) ~= "string" or source.event_id == "" then
        return nil, "relation weakening reason event is required"
    end
    local reason_event = find_event(instance, source.event_id)
    if not reason_event or reason_event.truth_status ~= "runtime_confirmed" then
        return nil, "relation weakening reason must be runtime-confirmed"
    end
    local reason_payload = reason_event.payload or {}
    if reason_payload.relation_id ~= relation_id and reason_payload.target_ref ~= relation_id then
        return nil, "relation weakening reason does not reference relation"
    end
    if reason_payload.reason_kind ~= nil and reason_payload.reason_kind ~= reason_kind then
        return nil, "relation weakening reason kind mismatch"
    end
    if relation.state == target_state then
        return {
            kind = "relation_weakening_payload",
            status = "no_op",
            relation = copy_value(relation),
            truth_status = "runtime_confirmed",
        }
    end

    local before = copy_value(relation)
    local previous_revision = instance.revisions.relations_active
    relation.state = target_state
    relation.version = relation.version + 1
    relation.last_mutation_reason = reason_kind
    relation.last_reason_event_id = source.event_id
    instance.revisions.relations_active = instance.revisions.relations_active + 1
    local payload = {
        kind = "relation_weakening_payload",
        status = "applied",
        relation_id = relation_id,
        before = before,
        after = copy_value(relation),
        reason_kind = reason_kind,
        reason_event_id = source.event_id,
        truth_status = "runtime_confirmed",
    }
    local event, event_err = packet_core.append_event(instance, {
        type = "relation_mutation",
        operator = glyph,
        truth_status = "runtime_confirmed",
        payload = payload,
        cost = {},
    })
    if not event then
        root_value.relations.active[relation_id] = before
        instance.revisions.relations_active = previous_revision
        return nil, event_err
    end
    relation.last_mutation_event_id = event.id
    payload.after.last_mutation_event_id = event.id
    payload.trace_event_id = event.id
    return copy_value(payload)
end

function field.relation_view(instance, refs)
    local root_value, root_err = root(instance)
    if not root_value then
        return nil, root_err
    end
    refs = refs or {}
    local scope = refs.scope or "active"
    if scope ~= "raw" and scope ~= "active" then
        return nil, "relation view scope must be raw or active"
    end
    local states, states_err = normalize_filter(refs.states)
    if states_err then
        return nil, states_err
    end
    local ids, ids_err = normalize_filter(refs.relation_ids)
    if ids_err then
        return nil, ids_err
    end
    local limit = refs.limit or 128
    if type(limit) ~= "number" or limit < 1 or limit ~= math.floor(limit) then
        return nil, "relation view limit must be a positive integer"
    end

    local source = {}
    if scope == "raw" then
        for _, relation in ipairs(root_value.relations.raw.items or {}) do
            source[#source + 1] = relation
        end
    else
        local ordered_ids = {}
        for relation_id in pairs(root_value.relations.active or {}) do
            ordered_ids[#ordered_ids + 1] = relation_id
        end
        table.sort(ordered_ids)
        for _, relation_id in ipairs(ordered_ids) do
            source[#source + 1] = root_value.relations.active[relation_id]
        end
    end

    local relations = {}
    local total_count = 0
    for _, relation in ipairs(source) do
        if (not states or states[relation.state]) and (not ids or ids[relation.id]) then
            total_count = total_count + 1
            if #relations < limit then
                relations[#relations + 1] = copy_value(relation)
            end
        end
    end
    return {
        kind = "bounded_relation_view",
        scope = scope,
        relations = relations,
        total_count = total_count,
        omitted_count = math.max(0, total_count - #relations),
        truncated = total_count > #relations,
        source_revision = scope == "raw"
            and instance.revisions.relations_raw or instance.revisions.relations_active,
        potential_revision = instance.revisions.potential,
        truth_status = "runtime_confirmed",
    }
end

function field.record_identity_map(instance, actor, input)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "record field identity map")
    if not mutable then
        return nil, mutable_err
    end
    local root_value, root_err = root(instance)
    if not root_value then
        return nil, root_err
    end
    local glyph, glyph_err = actor_glyph(actor)
    if not glyph then
        return nil, glyph_err
    end
    if glyph ~= "☵" then
        return nil, "only ENCODE may record field identity maps"
    end

    input = input or {}
    local encode_event = find_event(instance, input.encode_event_id)
    if not encode_event or encode_event.operator ~= "☵" then
        return nil, "field identity map requires ENCODE event"
    end
    if type(input.old_ids) ~= "table" or type(input.new_ids) ~= "table" or #input.new_ids == 0 then
        return nil, "field identity map requires old_ids and non-empty new_ids"
    end
    if type(input.mapping) ~= "table" then
        return nil, "field identity map mapping must be table"
    end
    for _, existing in ipairs(root_value.identity_maps) do
        if existing.encode_event_id == input.encode_event_id then
            return nil, "field identity map already recorded for ENCODE event"
        end
    end

    local remapped = {}
    for _, id in ipairs(input.old_ids) do
        if not root_value.units[id] then
            return nil, "field identity map old unit not found"
        end
        remapped[id] = true
    end
    for _, id in ipairs(input.new_ids) do
        if not root_value.units[id] then
            return nil, "field identity map new unit not found"
        end
    end
    for old_id, targets in pairs(input.mapping) do
        if not remapped[old_id] or type(targets) ~= "table" then
            return nil, "invalid field identity mapping"
        end
        for _, new_id in ipairs(targets) do
            if not root_value.units[new_id] then
                return nil, "field identity mapping target not found"
            end
        end
    end

    local invalidated_relations = {}
    local seen_relations = {}
    local function consider_relation(relation)
        if type(relation) == "table" and (remapped[relation.from] or remapped[relation.to])
            and not seen_relations[relation.id] then
            seen_relations[relation.id] = true
            invalidated_relations[#invalidated_relations + 1] = relation.id
        end
    end
    for _, relation in ipairs(root_value.relations.raw.items or {}) do
        consider_relation(relation)
    end
    for _, relation in pairs(root_value.relations.active or {}) do
        consider_relation(relation)
    end

    local record = {
        kind = "field_identity_map",
        encode_event_id = input.encode_event_id,
        old_ids = copy_array(input.old_ids),
        new_ids = copy_array(input.new_ids),
        mapping = copy_value(input.mapping),
        mapping_kind = input.mapping_kind or "explicit",
        source_event_refs = copy_array(input.source_event_refs),
        invalidated_relation_ids = invalidated_relations,
        invalidated_observation_ids = copy_array(input.invalidated_observation_ids),
        shadow_only = input.shadow_only == true,
        truth_status = "runtime_confirmed",
    }

    root_value.identity_maps[#root_value.identity_maps + 1] = record
    local event, event_err = packet_core.append_event(instance, {
        type = "identity_map",
        operator = "☵",
        truth_status = "runtime_confirmed",
        payload = record,
        cost = {},
    })
    if not event then
        root_value.identity_maps[#root_value.identity_maps] = nil
        return nil, event_err
    end
    record.trace_event_id = event.id
    return copy_value(record)
end

function field.view(instance, refs)
    local root_value, root_err = root(instance)
    if not root_value then
        return nil, root_err
    end
    refs = refs or {}
    if type(refs) ~= "table" then
        return nil, "field view refs must be table"
    end

    local unit_ids, unit_ids_err = normalize_filter(refs.unit_ids)
    if unit_ids_err then
        return nil, unit_ids_err
    end
    local created_by, created_by_err = normalize_filter(refs.created_by)
    if created_by_err then
        return nil, created_by_err
    end
    local activation, activation_err = normalize_filter(refs.activation)
    if activation_err then
        return nil, activation_err
    end
    local kinds, kinds_err = normalize_filter(refs.kinds)
    if kinds_err then
        return nil, kinds_err
    end

    local limit = refs.limit or 128
    if type(limit) ~= "number" or limit < 1 or limit ~= math.floor(limit) then
        return nil, "field view limit must be a positive integer"
    end
    local filters = {
        unit_ids = unit_ids,
        created_by = created_by,
        activation = activation,
        kinds = kinds,
        generation = refs.generation,
    }

    local units = {}
    local total_count = 0
    for _, id in ipairs(root_value.unit_order) do
        local unit = root_value.units[id]
        if unit and unit_matches(unit, filters) then
            total_count = total_count + 1
            if #units < limit then
                units[#units + 1] = copy_value(unit)
            end
        end
    end

    return {
        kind = "bounded_field_view",
        units = units,
        total_count = total_count,
        omitted_count = math.max(0, total_count - #units),
        truncated = total_count > #units,
        source_revision = instance.revisions.potential,
        generation = instance.generation,
        truth_status = "runtime_confirmed",
    }
end

return field
