local packet_core = require("core.packet")
local field = require("runtime.field")
local object_coverage = require("runtime.object_coverage")
local relation_inspection = require("runtime.relation_inspection")

local connect = {}

local function exact_versions(instance, configured)
    if configured == nil then
        return true
    end
    if type(configured) ~= "table" then
        return nil, "CONNECT unit_versions must be table"
    end
    for id, version in pairs(configured) do
        local unit = field.get_unit(instance, id)
        if not unit or unit.version ~= version then
            return nil, "CONNECT qualified unit version is stale"
        end
    end
    return true
end

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
    local versions_ok, versions_err = exact_versions(instance, options.unit_versions)
    if not versions_ok then
        return {
            operator = "☰",
            ready = false,
            reason = versions_err,
            source_refs = {},
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
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
        local derived, derive_err = relation_inspection.derive(instance, {
            policy_id = options.policy_id or "connect.structural.v1",
            bounds = resolved_bounds,
            unit_ids = options.unit_ids,
            activation = options.activation,
            kinds = options.kinds,
        })
        if not derived then
            return nil, derive_err
        end
        local meta = derived.coverage_meta
        local delta = derived.coverage_delta
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
            probe_policy_id = derived.policy_id,
            inspection_id = derived.inspection_id,
            candidate_count = #derived.candidates,
            candidate_delta = derived.candidate_delta,
            qualification_status = derived.qualification_status,
            event_truth_status = "runtime_confirmed",
        }, derived, resolved_bounds
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
        if witness.inspection_id then
            local execution_inspection, inspection_err = relation_inspection.derive(instance, {
                policy_id = witness.probe_policy_id,
                bounds = resolved_bounds,
                unit_ids = options.unit_ids,
                activation = options.activation,
                kinds = options.kinds,
            })
            if not execution_inspection then
                return nil, inspection_err
            end
            if not relation_inspection.same(view, execution_inspection) then
                return nil, "relation inspection changed before CONNECT execution"
            end
            view = execution_inspection
            for _, candidate in ipairs(execution_inspection.candidates) do
                detected[#detected + 1] = copy_candidate(candidate)
                detected[#detected].predicate_id = candidate.predicate_id
                detected[#detected].provenance_refs = candidate.provenance_refs
                detected[#detected].promotion_source = candidate.promotion_source
            end
        else
            local legacy_inspection, inspection_err = relation_inspection.derive(instance, {
                policy_id = options.policy_id or "connect.structural.v1",
                bounds = resolved_bounds,
                unit_ids = options.unit_ids,
                activation = options.activation,
                kinds = options.kinds,
            })
            if not legacy_inspection then
                return nil, inspection_err
            end
            for _, candidate in ipairs(legacy_inspection.candidates) do
                detected[#detected + 1] = copy_candidate(candidate)
                detected[#detected].predicate_id = candidate.predicate_id
                detected[#detected].provenance_refs = candidate.provenance_refs
                detected[#detected].promotion_source = candidate.promotion_source
            end
        end
    end

    local recorded = {}
    for index, candidate in ipairs(detected) do
        if index > resolved_bounds.max_relations then
            break
        end
        recorded[#recorded + 1] = candidate
    end
    local source_refs = {}
    if view.unit_ids then
        for _, ref in ipairs(view.unit_ids) do
            source_refs[#source_refs + 1] = ref
        end
    else
        for _, unit in ipairs(view.units or {}) do
            source_refs[#source_refs + 1] = unit.id
        end
    end
    local probe_policy
    local captured_coverage
    if witness.inspection_id then
        probe_policy = {
            policy_id = witness.probe_policy_id,
            policy_version = 1,
            bounds = {
                max_units = resolved_bounds.max_units,
                max_relations = resolved_bounds.max_relations,
            },
        }
        local capture_err
        captured_coverage, capture_err = object_coverage.capture(view.coverage_entries, {
            domain = "relation",
            policy_id = probe_policy.policy_id,
            total_count = view.coverage_meta.total_count,
            global_revision = view.coverage_meta.global_revision,
        })
        if not captured_coverage then
            return nil, capture_err
        end
    end
    local snapshot, snapshot_err = field.snapshot_raw_relations(instance, "☰", {
        items = recorded,
        source_revision = witness.inspection_id
            and view.source_potential_revision or view.source_revision,
        source_refs = source_refs,
        coverage = {
            units_available = witness.inspection_id
                and view.coverage_meta.total_count or view.total_count,
            units_considered = witness.inspection_id
                and #view.coverage_entries or #view.units,
            candidates_detected = #detected,
            relations_recorded = #recorded,
            omitted_relations = math.max(0, #detected - #recorded),
            truncated_units = witness.inspection_id
                and view.coverage_meta.truncated or view.truncated,
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
        inspection_id = witness.inspection_id,
        reads = {
            unit_ids = source_refs,
            potential_revision = witness.inspection_id
                and view.source_potential_revision or view.source_revision,
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
        effect_scope_refs = witness.source_refs,
        event_truth_status = "runtime_confirmed",
        content_truth_status = snapshot.content_truth_status,
    }
end

return connect
