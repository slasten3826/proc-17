local topology = require("core.topology")
local field = require("runtime.field")
local body = require("runtime.body")
local freshness = require("runtime.freshness")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local reconciliation = require("runtime.reconciliation")
local qualified_pressure = require("runtime.qualified_pressure")

local pressure = {
    derivation_version = "pressure.binary.v0",
    calibration_status = "vibed_control",
}

local canonical_index = {}
for index, glyph in ipairs(topology.order) do
    canonical_index[glyph] = index
end

local reader_order = {
    "relation_debt",
    "rigidity",
    "upper_observation_debt",
    "encoding_debt",
    "choice_pressure",
    "runtime_reconciliation_debt",
    "runtime_mismatch",
    "validation_debt",
    "continuation",
    "manifest",
    "karma_help",
    "karma_resistance",
}

local sampled_reader_order = {
    "relation_debt",
    "rigidity",
    "sampled_upper_observation_debt",
    "encoding_debt",
    "choice_pressure",
    "sampled_runtime_mismatch",
    "lower_observation_debt",
    "validation_debt",
    "continuation",
    "manifest",
    "karma_help",
    "karma_resistance",
}

local readers = {}

local function copy_array(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = value
    end
    return result
end

local function copy_map(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

local function current_operator(instance, context)
    context = context or {}
    local tick = context.tick_result or context.tick or {}
    return topology.resolve(context.current_operator or tick.operator or instance.operator)
end

function pressure.edge(left, right)
    left = topology.resolve(left)
    right = topology.resolve(right)
    if not left or not right then
        return nil
    end
    if canonical_index[left] <= canonical_index[right] then
        return left .. "-" .. right
    end
    return right .. "-" .. left
end

local function source_status(value)
    if type(value) ~= "string" or value == "" then
        return "runtime_confirmed"
    end
    return value
end

local function contribution(kind, instance, context, target, direction, reason, source_refs, extra)
    local current = current_operator(instance, context)
    target = topology.resolve(target)
    if not current or not target or not topology.is_adjacent(current, target) then
        return nil
    end
    source_refs = copy_array(source_refs)
    if #source_refs == 0 then
        return nil
    end

    local value = {
        kind = kind,
        source_ref = source_refs[1],
        source_refs = source_refs,
        current_operator = current,
        target_operator = target,
        target_edge = pressure.edge(current, target),
        direction = direction or "help",
        amount = 1,
        reason = reason,
        calculation_status = "runtime_confirmed",
        source_truth_status = "runtime_confirmed",
        freshness = "current",
        derivation_version = pressure.derivation_version,
    }
    for key, child in pairs(extra or {}) do
        value[key] = child
    end
    value.source_truth_status = source_status(value.source_truth_status)
    return value
end

local function one(value)
    if value == nil then
        return {}
    end
    return {value}
end

local function latest(list)
    if type(list) ~= "table" then
        return nil
    end
    return list[#list]
end

readers.relation_debt = function(instance, context)
    local view = field.view(instance, {
        created_by = {"▽", "☷", "☴"},
        activation = {live = true, selected = true},
        generation = instance.generation,
        limit = 256,
    }) or {units = {}, total_count = 0}
    if view.total_count < 2 then
        return {}
    end
    local relations = instance.field and instance.field.relations or {}
    local raw = relations.raw or {}
    local covered = {}
    for _, ref in ipairs(raw.source_refs or {}) do
        covered[ref] = true
    end
    local refs = {}
    for _, unit in ipairs(view.units) do
        if not covered[unit.id] then
            refs[#refs + 1] = unit.id
        end
    end
    if #refs == 0 then
        return {}
    end
    return one(contribution(
        "relation_debt",
        instance,
        context,
        "☰",
        "help",
        "addressable_units_lack_fresh_relation_epoch",
        refs,
        {
            freshness = type(raw.epoch) == "number" and raw.epoch > 0
                and "partial" or "missing",
            uncovered_unit_count = #refs,
        }
    ))
end

local function relation_rigidity(instance)
    local view = field.relation_view(instance, {
        scope = "active",
        limit = 128,
    }) or {relations = {}}
    for _, relation in ipairs(view.relations or {}) do
        local reason_kind
        if relation.state == "locked" then
            reason_kind = "rigid"
        elseif relation.state == "rejected" then
            reason_kind = "rejected"
        elseif relation.state == "contradictory" then
            reason_kind = "contradictory"
        elseif relation.state == "unsupported" then
            reason_kind = "unsupported"
        else
            for endpoint, version in pairs(relation.endpoint_versions or {}) do
                local unit = field.get_unit(instance, endpoint)
                if not unit or unit.version ~= version then
                    reason_kind = "stale"
                    break
                end
            end
        end
        if reason_kind then
            return relation, reason_kind
        end
    end
    return nil
end

readers.rigidity = function(instance, context)
    local relation, reason_kind = relation_rigidity(instance)
    if not relation then
        return {}
    end
    return one(contribution(
        "rigidity",
        instance,
        context,
        "☷",
        "help",
        "active_relation_requires_subtractive_release",
        {relation.id, relation.last_mutation_event_id or relation.id},
        {
            relation_id = relation.id,
            dissolve_reason = reason_kind,
            source_truth_status = relation.event_truth_status,
        }
    ))
end

local function eye_debt(instance, context, eye, target, kind)
    local state, err = freshness.latest_eye(instance, eye)
    if not state then
        return nil, err
    end
    if state.fresh then
        return {}
    end
    local refs = {}
    if state.observation_id then
        refs[#refs + 1] = state.observation_id
    end
    for _, changed in ipairs(state.changed_components or {}) do
        refs[#refs + 1] = "revision:" .. tostring(changed.component) .. ":" .. tostring(changed.current)
    end
    if #refs == 0 then
        local components = eye == "upper"
            and {"potential", "relations_raw", "relations_active", "calm"}
            or {"relations_active", "momentum", "calm", "constraints", "evidence", "history", "budget", "loss", "scalars"}
        for _, component in ipairs(components) do
            refs[#refs + 1] = "revision:" .. component .. ":" .. tostring(instance.revisions[component])
        end
    end
    return one(contribution(kind, instance, context, target, "help", state.reason, refs, {
        freshness = state.zone,
        changed_components = copy_array(state.changed_components),
        observation_id = state.observation_id,
    }))
end

readers.sampled_upper_observation_debt = function(instance, context)
    return eye_debt(instance, context, "upper", "☴", "upper_observation_debt")
end

readers.upper_observation_debt = function(instance, context)
    local view = field.view(instance, {
        created_by = {"▽", "☷", "☴"},
        activation = {live = true, selected = true},
        generation = instance.generation,
        limit = 256,
    }) or {units = {}}
    local observation, observation_err = body.latest_observation(instance, "upper")
    if observation_err then
        return nil, observation_err
    end
    local covered = {}
    for _, ref in ipairs(observation and observation.scope_refs or {}) do
        covered[ref] = true
    end
    for _, ref in ipairs(observation and observation.sensor_output_refs or {}) do
        covered[ref] = true
    end

    local refs = {}
    for _, unit in ipairs(view.units or {}) do
        if not covered[unit.id] then
            refs[#refs + 1] = unit.id
        end
    end
    if #refs == 0 then
        return {}
    end
    return one(contribution(
        "upper_observation_debt",
        instance,
        context,
        "☴",
        "help",
        observation and "semantic_units_outside_upper_observation"
            or "upper_observation_missing",
        refs,
        {
            freshness = observation and "uncovered" or "missing",
            observation_id = observation and observation.id,
            uncovered_unit_count = #refs,
        }
    ))
end

readers.lower_observation_debt = function(instance, context)
    return eye_debt(instance, context, "lower", "☱", "lower_observation_debt")
end

local function mapped_source_ids(instance)
    local mapped = {}
    for _, identity_map in ipairs(instance.field and instance.field.identity_maps or {}) do
        for _, old_id in ipairs(identity_map.old_ids or {}) do
            mapped[old_id] = true
        end
    end
    return mapped
end

readers.encoding_debt = function(instance, context)
    local mapped = mapped_source_ids(instance)
    local source_view = field.view(instance, {
        created_by = {"▽", "☴"},
        activation = {live = true, selected = true},
        generation = instance.generation,
        limit = 256,
    }) or {units = {}}
    local refs = {}
    for _, unit in ipairs(source_view.units or {}) do
        if not mapped[unit.id] then
            refs[#refs + 1] = unit.id
        end
    end
    for index in ipairs(instance.chaos and instance.chaos.unresolved_pressure or {}) do
        refs[#refs + 1] = "chaos:unresolved_pressure:" .. tostring(index)
    end
    if #refs == 0 then
        return {}
    end
    return one(contribution(
        "encoding_debt",
        instance,
        context,
        "☵",
        "help",
        "live_potential_has_no_receiver_suitable_form",
        refs,
        {freshness = "unencoded"}
    ))
end

local function live_choice_refs(instance)
    local calm = instance.calm or {}
    local current = calm.current or {}
    local shadow = current.field_shadow or {}
    local refs = {}
    if type(shadow.member_unit_ids) == "table" and #shadow.member_unit_ids > 0 then
        for _, id in ipairs(shadow.member_unit_ids) do
            local unit = field.get_unit(instance, id)
            if unit and (unit.activation == "live" or unit.activation == "selected") then
                refs[#refs + 1] = id
            end
        end
        return refs
    end
    for index, item in ipairs(current.field and current.field.items or {}) do
        refs[#refs + 1] = tostring(item.id or ("calm:item:" .. index))
    end
    return refs
end

readers.choice_pressure = function(instance, context)
    local refs = live_choice_refs(instance)
    if #refs < 2 then
        return {}
    end
    return one(contribution(
        "choice_pressure",
        instance,
        context,
        "☳",
        "help",
        "multiple_live_alternatives_require_suppression",
        refs,
        {alternative_count = #refs}
    ))
end

readers.runtime_reconciliation_debt = function(instance, context)
    local state, state_err = reconciliation.inspect(instance)
    if not state then
        return nil, state_err
    end
    if not state.has_debt then
        return {}
    end
    return one(contribution(
        "runtime_reconciliation_debt",
        instance,
        context,
        "☱",
        "help",
        "significant_runtime_frames_not_reconciled",
        state.source_refs,
        {
            freshness = "unreconciled",
            from_seq = state.from_seq,
            through_seq = state.through_seq,
            pending_frame_count = state.pending_frame_count,
            significant_frame_count = state.significant_frame_count,
            significant_frames = copy_array(state.significant_frames),
        }
    ))
end

readers.runtime_mismatch = function()
    -- No independent CALM/runtime comparator exists in v0. A missing witness
    -- must remain absent instead of aliasing lower-eye freshness.
    return {}
end

readers.sampled_runtime_mismatch = function(instance, context)
    if not (instance.calm and instance.calm.current) then
        return {}
    end
    local lower = freshness.latest_eye(instance, "lower")
    if not lower or lower.fresh then
        return {}
    end
    local refs = {"revision:calm:" .. tostring(instance.revisions.calm)}
    if lower.observation_id then
        refs[#refs + 1] = lower.observation_id
    end
    return one(contribution(
        "runtime_mismatch",
        instance,
        context,
        "☱",
        "help",
        "calm_state_not_reconciled_with_current_runtime_view",
        refs,
        {freshness = lower.zone}
    ))
end

local function work_mode(instance, context)
    context = context or {}
    local options = context.options or {}
    local tick = context.tick_result or context.tick or {}
    return options.work_mode or tick.work_mode
        or (instance.metadata and instance.metadata.work_mode) or "build"
end

readers.validation_debt = function(instance, context)
    if work_mode(instance, context) ~= "build" or not (instance.calm and instance.calm.current) then
        return {}
    end
    local stamp = instance.runtime and instance.runtime.logic_stamp
    local fingerprint = freshness.evidence_fingerprint(instance)
    if stamp and stamp.evidence_fingerprint == fingerprint then
        return {}
    end
    local refs = {"calm:current", "evidence:fingerprint:" .. tostring(fingerprint)}
    return one(contribution(
        "validation_debt",
        instance,
        context,
        "☶",
        "help",
        "build_form_lacks_fresh_effect_verdict",
        refs,
        {freshness = stamp and "stale" or "missing"}
    ))
end

local function current_logic_stamp(instance)
    local stamp = instance.runtime and instance.runtime.logic_stamp
    if type(stamp) ~= "table" then
        return nil
    end
    local fingerprint = freshness.evidence_fingerprint(instance)
    if stamp.evidence_fingerprint ~= fingerprint then
        return nil
    end
    return stamp, fingerprint
end

readers.continuation = function(instance, context)
    local progress = body.progress(instance)
    local budget_state = budget.snapshot(instance)
    if progress.remaining_count <= 0 or budget_state.exhausted then
        return {}
    end
    if work_mode(instance, context) == "build" and current_logic_stamp(instance) ~= nil then
        return {}
    end
    local refs = {}
    for _, id in ipairs(progress.remaining or {}) do
        refs[#refs + 1] = "work:" .. tostring(id)
    end
    refs[#refs + 1] = "revision:budget:" .. tostring(instance.revisions.budget)
    return one(contribution(
        "continuation",
        instance,
        context,
        "☲",
        "help",
        "runtime_confirmed_repeatable_work_remains",
        refs,
        {remaining_count = progress.remaining_count}
    ))
end

readers.manifest = function(instance, context)
    local progress = body.progress(instance)
    local budget_state = budget.snapshot(instance)
    local loss_state = loss.snapshot(instance)
    local calm_exists = instance.calm and instance.calm.current ~= nil
    local stamp, evidence_fingerprint = current_logic_stamp(instance)
    local no_new_evidence = work_mode(instance, context) == "build"
        and calm_exists
        and progress.remaining_count > 0
        and stamp ~= nil
    local ready = loss_state.near_death or budget_state.exhausted
        or (calm_exists and progress.remaining_count == 0)
        or no_new_evidence
    if not ready then
        return {}
    end
    local refs = {}
    local reason = "no_remaining_work"
    if loss_state.near_death then
        refs[#refs + 1] = "revision:loss:" .. tostring(instance.revisions.loss)
        reason = "identity_near_death"
    elseif budget_state.exhausted then
        refs[#refs + 1] = "revision:budget:" .. tostring(instance.revisions.budget)
        reason = "budget_exhausted"
    elseif no_new_evidence then
        refs[#refs + 1] = stamp.trace_event_id or "runtime:logic_stamp"
        refs[#refs + 1] = "evidence:fingerprint:" .. tostring(evidence_fingerprint)
        reason = "logic_stamp_no_new_evidence"
    else
        refs[#refs + 1] = "calm:current"
    end
    return one(contribution("manifest", instance, context, "△", "help", reason, refs, {
        remaining_count = progress.remaining_count,
    }))
end

readers.karma_help = function(instance, context)
    local history = instance.runtime and (instance.runtime.history or instance.runtime.karma) or {}
    local bequests = history.bequests or {}
    local unresolved = instance.chaos and instance.chaos.unresolved_pressure or {}
    if #bequests == 0 or #unresolved == 0 then
        return {}
    end
    local refs = {"revision:history:" .. tostring(instance.revisions.history)}
    for index = 1, math.min(#bequests, 8) do
        local grave = bequests[index]
        refs[#refs + 1] = tostring(grave.id or grave.packet_id or ("bequest:" .. index))
    end
    return one(contribution(
        "karma_help",
        instance,
        context,
        "☵",
        "help",
        "attached_bequest_matches_unresolved_newborn_pressure",
        refs,
        {calculation_status = "estimated", source_truth_status = "grave_pressure"}
    ))
end

readers.karma_resistance = function(instance, context)
    local history = instance.runtime and (instance.runtime.history or instance.runtime.karma) or {}
    local warnings = history.warnings or {}
    local last_cycle = latest(instance.boundary and instance.boundary.cycles)
    if #warnings == 0 or not last_cycle
        or (last_cycle.decision ~= "again" and last_cycle.reason ~= "remaining_work") then
        return {}
    end
    local refs = {last_cycle.trace_event_id or "cycle:last"}
    for index = 1, math.min(#warnings, 8) do
        local grave = warnings[index]
        refs[#refs + 1] = tostring(grave.id or grave.packet_id or ("warning:" .. index))
    end
    return one(contribution(
        "karma_resistance",
        instance,
        context,
        "☲",
        "resist",
        "known_lineage_warning_matches_repeated_cycle",
        refs,
        {calculation_status = "estimated", source_truth_status = "grave_pressure"}
    ))
end

function pressure.read(kind, instance, context)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    local reader = readers[kind]
    if not reader then
        return nil, "unknown pressure kind"
    end
    local result, err = reader(instance, context or {})
    if not result then
        return nil, err
    end
    return result
end

function pressure.derive(instance, tick_result, options)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    options = options or {}
    local context = {
        current_operator = options.current_operator,
        tick_result = tick_result or {},
        options = options.options or options,
    }
    local current = current_operator(instance, context)
    if not current then
        return nil, "invalid current operator"
    end

    local policy = context.options.pressure_policy or "camera_reconciliation"
    if policy == "qualified_need_v0" then
        local qualified_options = copy_map(context.options)
        qualified_options.current_operator = current
        return qualified_pressure.derive(instance, tick_result, qualified_options)
    end
    if policy ~= "camera_reconciliation" and policy ~= "sampled" then
        return nil, "invalid pressure policy"
    end
    local active_reader_order = policy == "sampled" and sampled_reader_order or reader_order
    local contributions = {}
    local seen = {}
    for _, kind in ipairs(active_reader_order) do
        local values, err = pressure.read(kind, instance, context)
        if not values then
            return nil, err
        end
        for _, value in ipairs(values) do
            local key = value.kind .. "|" .. value.target_edge .. "|" .. value.direction
            if not seen[key] then
                seen[key] = true
                contributions[#contributions + 1] = value
            end
        end
    end

    local clock = instance.physis and instance.physis.clock or {}
    return {
        kind = "edge_pressure_snapshot",
        packet_id = instance.id,
        generation = instance.generation,
        tick = clock.ticks or 0,
        current_operator = current,
        derivation_version = pressure.derivation_version,
        calibration_status = pressure.calibration_status,
        runtime_policy = policy,
        source_revisions = copy_map(instance.revisions),
        contributions = contributions,
        event_truth_status = "runtime_confirmed",
    }
end

pressure.reader_order = copy_array(reader_order)
pressure.sampled_reader_order = copy_array(sampled_reader_order)

return pressure
