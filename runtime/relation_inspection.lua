local json = require("core.json")
local field = require("runtime.field")
local object_coverage = require("runtime.object_coverage")

local inspection = {
    protocol_version = "connect.inspection.v0",
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

local function sorted_unique(values)
    local seen = {}
    local result = {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function same_array(left, right)
    left = left or {}
    right = right or {}
    if #left ~= #right then
        return false
    end
    for index, value in ipairs(left) do
        if right[index] ~= value then
            return false
        end
    end
    return true
end

local function exact_ref(unit)
    return table.concat({
        "coverage",
        "field_unit",
        unit.id,
        tostring(unit.version),
    }, ":")
end

local function content_truth(left, right)
    if left == right then
        return left or "unknown"
    end
    return "mixed"
end

local function resolved_bounds(options)
    local configured = options and options.bounds or {}
    local max_units = configured.max_units or 64
    local max_relations = configured.max_relations or 128
    if type(max_units) ~= "number" or max_units < 1
        or max_units ~= math.floor(max_units) then
        return nil, "relation inspection max_units must be a positive integer"
    end
    if type(max_relations) ~= "number" or max_relations < 1
        or max_relations ~= math.floor(max_relations) then
        return nil, "relation inspection max_relations must be a positive integer"
    end
    return {
        max_units = max_units,
        max_relations = max_relations,
    }
end

local function unit_view(instance, options, bounds)
    local kinds = options.kinds
    if kinds == nil and instance.ingress
        and instance.ingress.integration_protocol == "vertical_packet_life.v0" then
        kinds = {
            l1_physical_sample = true,
            formed_relation = true,
            raw_relation_residue = true,
            grave_warning = true,
            grave_bequest = true,
        }
    end
    return field.view(instance, {
        unit_ids = options.unit_ids,
        activation = options.activation or {live = true, selected = true},
        kinds = kinds,
        generation = instance.generation,
        limit = bounds.max_units,
    })
end

local function candidate_identity(candidate)
    return "relation-candidate:" .. json.encode({
        protocol_version = inspection.protocol_version,
        predicate_id = candidate.predicate_id,
        kind = candidate.kind,
        from = candidate.from,
        to = candidate.to,
        endpoint_versions = candidate.endpoint_versions,
        provenance_refs = candidate.provenance_refs,
    })
end

local function finalize_candidate(candidate, by_id)
    local from = by_id[candidate.from]
    local to = by_id[candidate.to]
    if not from or not to or from.id == to.id then
        return nil
    end
    candidate.endpoint_versions = {
        [from.id] = from.version,
        [to.id] = to.version,
    }
    candidate.scope_refs = sorted_unique({exact_ref(from), exact_ref(to)})
    candidate.provenance_refs = sorted_unique(candidate.provenance_refs)
    candidate.source_refs = sorted_unique(candidate.source_refs)
    candidate.event_truth_status = "runtime_confirmed"
    candidate.candidate_key = candidate_identity(candidate)
    return candidate
end

local function projection_candidates(instance, units, by_id)
    local by_key = {}
    for _, unit in ipairs(units) do
        local migration = unit.migration or {}
        if migration.status == "vertical_fixture_only"
            and type(migration.projection_key) == "string" then
            by_key[migration.projection_key] = unit
        end
    end

    local candidates = {}
    local projection = instance.ingress and instance.ingress.l1_projection
    for _, declared in ipairs(projection and projection.relation_candidates or {}) do
        local from = by_key[declared.from_key]
        local to = by_key[declared.to_key]
        if from and to and from.id ~= to.id then
            local provenance = {}
            for _, ref in ipairs(declared.source_refs or {}) do
                provenance[#provenance + 1] = ref
            end
            if from.created_event_id then
                provenance[#provenance + 1] = from.created_event_id
            end
            if to.created_event_id then
                provenance[#provenance + 1] = to.created_event_id
            end
            candidates[#candidates + 1] = finalize_candidate({
                from = from.id,
                to = to.id,
                kind = declared.kind,
                predicate_id = "connect.l1_registered_projection.v0",
                confidence = 1.0,
                source_refs = {from.id, to.id, from.created_event_id},
                provenance_refs = provenance,
                content_truth_status = "non_semantic_measurement",
                promotion_source = "fixture",
            }, by_id)
        end
    end
    return candidates
end

local function structural_candidates(instance, units)
    local by_id = {}
    local by_legacy_id = {}
    for _, unit in ipairs(units) do
        by_id[unit.id] = unit
        local migration = unit.migration or {}
        if migration.legacy_id ~= nil then
            by_legacy_id[tostring(migration.legacy_id)] = unit
        end
    end

    local candidates = {}
    for _, unit in ipairs(units) do
        local carrier = unit.carrier
        local parent_legacy_id = type(carrier) == "table" and carrier.parent_id or nil
        local parent = parent_legacy_id and by_legacy_id[tostring(parent_legacy_id)] or nil
        if parent and parent.id ~= unit.id then
            candidates[#candidates + 1] = finalize_candidate({
                from = parent.id,
                to = unit.id,
                kind = "contains",
                predicate_id = "connect.parent_carrier.v0",
                confidence = 1.0,
                source_refs = {parent.id, unit.id, unit.created_event_id},
                provenance_refs = {parent.created_event_id, unit.created_event_id},
                content_truth_status = content_truth(
                    parent.content_truth_status,
                    unit.content_truth_status
                ),
                promotion_source = "body",
            }, by_id)
        end
    end
    for _, candidate in ipairs(projection_candidates(instance, units, by_id)) do
        candidates[#candidates + 1] = candidate
    end
    table.sort(candidates, function(left, right)
        return left.candidate_key < right.candidate_key
    end)
    return candidates
end

local function exact_versions(left, right)
    for endpoint, version in pairs(left or {}) do
        if right == nil or right[endpoint] ~= version then
            return false
        end
    end
    for endpoint, version in pairs(right or {}) do
        if left == nil or left[endpoint] ~= version then
            return false
        end
    end
    return true
end

local function logical_match(candidate, relation, raw_policy_id, policy_id)
    return raw_policy_id == policy_id
        and relation.from == candidate.from
        and relation.to == candidate.to
        and relation.kind == candidate.kind
        and relation.predicate_id == candidate.predicate_id
        and same_array(
            sorted_unique(relation.provenance_refs),
            candidate.provenance_refs
        )
end

local function candidate_delta(candidates, raw, policy_id)
    local delta = {
        missing = {},
        stale = {},
        current = {},
        unsupported = {},
    }
    local raw_policy_id = raw.probe_policy and raw.probe_policy.policy_id
    local matched_relations = {}

    for _, candidate in ipairs(candidates) do
        local logical
        for _, relation in ipairs(raw.items or {}) do
            if logical_match(candidate, relation, raw_policy_id, policy_id) then
                logical = relation
                break
            end
        end
        if not logical then
            delta.missing[#delta.missing + 1] = copy_value(candidate)
        elseif exact_versions(candidate.endpoint_versions, logical.endpoint_versions) then
            matched_relations[logical.id] = true
            delta.current[#delta.current + 1] = copy_value(candidate)
        else
            matched_relations[logical.id] = true
            local stale = copy_value(candidate)
            stale.covered_endpoint_versions = copy_value(logical.endpoint_versions)
            stale.raw_relation_id = logical.id
            delta.stale[#delta.stale + 1] = stale
        end
    end

    for _, relation in ipairs(raw.items or {}) do
        if not matched_relations[relation.id] then
            delta.unsupported[#delta.unsupported + 1] = {
                raw_relation_id = relation.id,
                kind = relation.kind,
                from = relation.from,
                to = relation.to,
                predicate_id = relation.predicate_id,
                endpoint_versions = copy_value(relation.endpoint_versions),
                provenance_refs = sorted_unique(relation.provenance_refs),
                event_truth_status = "runtime_confirmed",
            }
        end
    end
    return delta
end

function inspection.derive(instance, options)
    options = options or {}
    local policy_id = options.policy_id or "connect.structural.v1"
    if type(policy_id) ~= "string" or policy_id == "" then
        return nil, "relation inspection policy_id required"
    end
    local bounds, bounds_err = resolved_bounds(options)
    if not bounds then
        return nil, bounds_err
    end
    local view, view_err = unit_view(instance, options, bounds)
    if not view then
        return nil, view_err
    end

    local unit_ids = {}
    for _, unit in ipairs(view.units) do
        unit_ids[#unit_ids + 1] = unit.id
    end
    local coverage_entries, coverage_meta = field.coverage_domain(instance, "relation", {
        limit = bounds.max_units,
        unit_ids = unit_ids,
    })
    if not coverage_entries then
        return nil, coverage_meta
    end
    local raw = instance.field and instance.field.relations
        and instance.field.relations.raw or {}
    local coverage_delta, delta_err = object_coverage.diff(
        raw.object_coverage,
        coverage_entries,
        {
            domain = "relation",
            policy_id = policy_id,
            current_omitted_count = coverage_meta.omitted_count,
            departed_is_change = false,
        }
    )
    if not coverage_delta then
        return nil, delta_err
    end

    local detected = structural_candidates(instance, view.units)
    local total_candidates = #detected
    local candidates = {}
    for index, candidate in ipairs(detected) do
        if index > bounds.max_relations then
            break
        end
        candidates[#candidates + 1] = candidate
    end
    local relation_delta = candidate_delta(candidates, raw, policy_id)
    local result = {
        protocol_version = inspection.protocol_version,
        policy_id = policy_id,
        generation = instance.generation,
        source_potential_revision = instance.revisions.potential,
        unit_ids = copy_value(unit_ids),
        coverage_entries = copy_value(coverage_entries),
        coverage_delta = coverage_delta,
        coverage_meta = {
            total_count = coverage_meta.total_count,
            stored_count = coverage_meta.stored_count,
            omitted_count = coverage_meta.omitted_count,
            truncated = coverage_meta.truncated,
            global_revision = coverage_meta.global_revision,
        },
        candidates = copy_value(candidates),
        candidate_delta = relation_delta,
        candidate_count = total_candidates,
        omitted_candidate_count = math.max(0, total_candidates - #candidates),
        qualification_status = (coverage_meta.truncated or total_candidates > #candidates)
            and "incomplete_scope" or "complete_scope",
        event_truth_status = "runtime_confirmed",
    }
    result.inspection_id = "connect-inspection:" .. json.encode({
        protocol_version = result.protocol_version,
        policy_id = result.policy_id,
        generation = result.generation,
        source_potential_revision = result.source_potential_revision,
        coverage_refs = coverage_delta.source_refs,
        candidate_keys = (function()
            local keys = {}
            for _, candidate in ipairs(candidates) do
                keys[#keys + 1] = candidate.candidate_key
            end
            return keys
        end)(),
        missing_keys = (function()
            local keys = {}
            for _, candidate in ipairs(relation_delta.missing) do
                keys[#keys + 1] = candidate.candidate_key
            end
            return keys
        end)(),
        stale_keys = (function()
            local keys = {}
            for _, candidate in ipairs(relation_delta.stale) do
                keys[#keys + 1] = candidate.candidate_key
            end
            return keys
        end)(),
        current_keys = (function()
            local keys = {}
            for _, candidate in ipairs(relation_delta.current) do
                keys[#keys + 1] = candidate.candidate_key
            end
            return keys
        end)(),
        qualification_status = result.qualification_status,
    })
    return copy_value(result)
end

function inspection.same(left, right)
    return type(left) == "table" and type(right) == "table"
        and type(left.inspection_id) == "string"
        and left.inspection_id == right.inspection_id
end

function inspection.scope_refs(value)
    local refs = {}
    for _, ref in ipairs(value and value.coverage_delta
        and value.coverage_delta.source_refs or {}) do
        refs[#refs + 1] = ref
    end
    for _, candidate in ipairs(value and value.candidates or {}) do
        for _, ref in ipairs(candidate.scope_refs or {}) do
            refs[#refs + 1] = ref
        end
    end
    return sorted_unique(refs)
end

return inspection
