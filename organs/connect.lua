local packet_core = require("core.packet")
local field = require("runtime.field")

local connect = {}

local function bounds(options)
    local configured = options and options.bounds or {}
    local max_units = configured.max_units or 64
    local max_relations = configured.max_relations or 128
    if type(max_units) ~= "number" or max_units < 2 or max_units ~= math.floor(max_units) then
        return nil, "CONNECT max_units must be an integer >= 2"
    end
    if type(max_relations) ~= "number" or max_relations < 1 or max_relations ~= math.floor(max_relations) then
        return nil, "CONNECT max_relations must be a positive integer"
    end
    return {
        max_units = max_units,
        max_relations = max_relations,
    }
end

local function content_truth(left, right)
    if left == right then
        return left or "unknown"
    end
    return "mixed"
end

local function relations_truth(relations)
    if #relations == 0 then
        return "unknown"
    end
    local status = relations[1].content_truth_status or "unknown"
    for _, relation in ipairs(relations) do
        if (relation.content_truth_status or "unknown") ~= status then
            return "mixed"
        end
    end
    return status
end

local function copy_candidate(candidate)
    local refs = {}
    for _, ref in ipairs(candidate.source_refs or {candidate.from, candidate.to}) do
        refs[#refs + 1] = ref
    end
    return {
        from = candidate.from,
        to = candidate.to,
        kind = candidate.kind,
        weight = candidate.weight,
        confidence = candidate.confidence,
        source_refs = refs,
        event_truth_status = candidate.event_truth_status or "runtime_confirmed",
        content_truth_status = candidate.content_truth_status or "unknown",
        allow_self = candidate.allow_self,
    }
end

local function structural_candidates(units)
    local candidates = {}
    local by_legacy_id = {}
    for _, unit in ipairs(units) do
        local migration = unit.migration or {}
        if migration.legacy_id ~= nil then
            by_legacy_id[tostring(migration.legacy_id)] = unit
        end
    end

    for _, unit in ipairs(units) do
        local carrier = unit.carrier
        local parent_legacy_id = type(carrier) == "table" and carrier.parent_id or nil
        local parent = parent_legacy_id and by_legacy_id[tostring(parent_legacy_id)] or nil
        if parent and parent.id ~= unit.id then
            candidates[#candidates + 1] = {
                from = parent.id,
                to = unit.id,
                kind = "contains",
                confidence = 1.0,
                source_refs = {parent.id, unit.id, unit.created_event_id},
                event_truth_status = "runtime_confirmed",
                content_truth_status = content_truth(
                    parent.content_truth_status,
                    unit.content_truth_status
                ),
            }
        end
    end
    return candidates
end

local function unit_view(instance, options, resolved_bounds)
    return field.view(instance, {
        unit_ids = options.unit_ids,
        activation = options.activation or {live = true, selected = true},
        generation = instance.generation,
        limit = resolved_bounds.max_units,
    })
end

function connect.readiness(instance, options)
    options = options or {}
    local resolved_bounds, bounds_err = bounds(options)
    if not resolved_bounds then
        return nil, bounds_err
    end
    local view, view_err = unit_view(instance, options, resolved_bounds)
    if not view then
        return nil, view_err
    end
    local source_refs = {}
    for _, unit in ipairs(view.units) do
        source_refs[#source_refs + 1] = unit.id
    end
    return {
        operator = "☰",
        ready = #view.units >= 2,
        reason = #view.units >= 2 and "ready" or "no_relation_candidates",
        source_refs = source_refs,
        required_capabilities = {},
        missing_capabilities = {},
        field_revision = view.source_revision,
        event_truth_status = "runtime_confirmed",
    }, view, resolved_bounds
end

function connect.run(instance, options)
    options = options or {}
    local mutable, mutable_err = packet_core.assert_mutable(instance, "connect field units")
    if not mutable then
        return nil, mutable_err
    end
    local witness, view_or_err, resolved_bounds = connect.readiness(instance, options)
    if not witness then
        return nil, view_or_err
    end
    if not witness.ready then
        return nil, witness.reason
    end
    local view = view_or_err

    local detected = {}
    if options.candidates ~= nil then
        if type(options.candidates) ~= "table" then
            return nil, "CONNECT candidates must be table"
        end
        for _, candidate in ipairs(options.candidates) do
            if type(candidate) ~= "table" then
                return nil, "CONNECT candidate must be table"
            end
            detected[#detected + 1] = copy_candidate(candidate)
        end
    else
        detected = structural_candidates(view.units)
    end

    local recorded = {}
    for index, candidate in ipairs(detected) do
        if index > resolved_bounds.max_relations then
            break
        end
        recorded[#recorded + 1] = candidate
    end
    local source_refs = {}
    for _, unit in ipairs(view.units) do
        source_refs[#source_refs + 1] = unit.id
    end
    local snapshot, snapshot_err = field.snapshot_raw_relations(instance, "☰", {
        items = recorded,
        source_revision = view.source_revision,
        source_refs = source_refs,
        coverage = {
            units_available = view.total_count,
            units_considered = #view.units,
            candidates_detected = #detected,
            relations_recorded = #recorded,
            omitted_relations = math.max(0, #detected - #recorded),
            truncated_units = view.truncated,
        },
        content_truth_status = relations_truth(recorded),
    })
    if not snapshot then
        return nil, snapshot_err
    end

    return instance, {
        kind = "connect_organ_payload",
        status = "applied",
        reason = #recorded > 0 and "relations_recognized" or "no_relation_candidates",
        outcome = #recorded > 0 and "relations_recorded" or "empty_snapshot",
        readiness = witness,
        reads = {
            unit_ids = source_refs,
            potential_revision = view.source_revision,
        },
        writes = {
            raw_epoch = snapshot.epoch,
            relation_ids = (function()
                local ids = {}
                for _, relation in ipairs(snapshot.items) do
                    ids[#ids + 1] = relation.id
                end
                return ids
            end)(),
        },
        coverage = snapshot.coverage,
        projection_loss = {
            kind = "bounded_relation_projection",
            omitted_count = math.max(0, #detected - #recorded),
            truth_status = "runtime_confirmed",
        },
        loss = {
            kind = "none",
            amount = 0,
        },
        trace_event_id = snapshot.trace_event_id,
        event_truth_status = "runtime_confirmed",
        content_truth_status = snapshot.content_truth_status,
    }
end

return connect
