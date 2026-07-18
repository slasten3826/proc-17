local packet_core = require("core.packet")
local field = require("runtime.field")
local object_coverage = require("runtime.object_coverage")

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

local function projection_candidates(instance, units)
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
            local domain_event_ref = from.source_refs and from.source_refs[1]
                or to.source_refs and to.source_refs[1]
            candidates[#candidates + 1] = {
                from = from.id,
                to = to.id,
                kind = declared.kind,
                confidence = 1.0,
                source_refs = {from.id, to.id, domain_event_ref},
                event_truth_status = "runtime_confirmed",
                content_truth_status = "non_semantic_measurement",
            }
        end
    end
    return candidates
end

local function structural_candidates(instance, units)
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
    for _, candidate in ipairs(projection_candidates(instance, units)) do
        candidates[#candidates + 1] = candidate
    end
    return candidates
end

local function unit_view(instance, options, resolved_bounds)
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
    local exact_probe = instance.ingress
        and instance.ingress.integration_protocol == "vertical_packet_life.v0"
    if exact_probe then
        local policy_id = options.policy_id or "connect.structural.v1"
        local entries, meta = field.coverage_domain(instance, "relation", {
            limit = resolved_bounds.max_units,
            unit_ids = source_refs,
        })
        if not entries then
            return nil, meta
        end
        local raw = instance.field and instance.field.relations
            and instance.field.relations.raw or {}
        local delta, delta_err = object_coverage.diff(raw.object_coverage, entries, {
            domain = "relation",
            policy_id = policy_id,
            current_omitted_count = meta.omitted_count,
            departed_is_change = false,
        })
        if not delta then
            return nil, delta_err
        end
        local ready = meta.total_count > 0 and delta.changed_count > 0
        return {
            operator = "☰",
            ready = ready,
            reason = ready and "relation_probe_delta" or (meta.total_count == 0
                and "no_addressable_units" or "relation_probe_current"),
            source_refs = object_coverage.source_refs(delta),
            required_capabilities = {},
            missing_capabilities = {},
            field_revision = view.source_revision,
            coverage_delta = delta,
            probe_policy_id = policy_id,
            event_truth_status = "runtime_confirmed",
        }, view, resolved_bounds, entries, meta
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
    if options.candidates ~= nil and instance.ingress
        and instance.ingress.integration_protocol == "vertical_packet_life.v0" then
        return nil, "vertical CONNECT rejects caller-injected relation candidates"
    end
    local witness, view_or_err, resolved_bounds, coverage_entries, coverage_meta = connect.readiness(instance, options)
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
        detected = structural_candidates(instance, view.units)
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
    local probe_policy
    local captured_coverage
    if coverage_entries then
        probe_policy = {
            policy_id = witness.probe_policy_id,
            policy_version = 1,
            bounds = {
                max_units = resolved_bounds.max_units,
                max_relations = resolved_bounds.max_relations,
            },
        }
        local capture_err
        captured_coverage, capture_err = object_coverage.capture(coverage_entries, {
            domain = "relation",
            policy_id = probe_policy.policy_id,
            total_count = coverage_meta.total_count,
            global_revision = coverage_meta.global_revision,
        })
        if not captured_coverage then
            return nil, capture_err
        end
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
        probe_policy = probe_policy,
        object_coverage = captured_coverage,
        outcome = #recorded > 0 and "relations_recorded" or "empty",
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
