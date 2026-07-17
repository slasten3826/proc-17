local catalog = require("runtime.edge_catalog")

local edge_stats = {}

local rail_definitions = {
    {
        id = "rail.encode_observe",
        from = "☵",
        eye = "☴",
        debt_kind = "upper_observation_debt",
    },
    {
        id = "rail.choose_observe",
        from = "☳",
        eye = "☴",
        debt_kind = "upper_observation_debt",
    },
    {
        id = "rail.cycle_runtime",
        from = "☲",
        eye = "☱",
        debt_kind = "runtime_reconciliation_debt",
    },
    {
        id = "rail.logic_runtime",
        from = "☶",
        eye = "☱",
        debt_kind = "runtime_reconciliation_debt",
    },
}

local function new_direction(key, legal)
    return {
        direction = key,
        legal = legal == true,
        candidate_count = 0,
        prediction_count = 0,
        committed_count = 0,
        executed_count = 0,
        failed_count = 0,
        positive_sum = 0,
        resistance_sum = 0,
        total_sum = 0,
        exclusion_reasons = {},
        arrival_kinds = {},
        failure_kinds = {},
    }
end

local function new_edge(definition)
    local legal = {}
    local directions = {}
    for _, direction in ipairs(definition.directions) do
        legal[direction] = true
        directions[direction] = new_direction(direction, true)
    end
    return {
        id = definition.id,
        edge = definition.edge,
        left = definition.left,
        right = definition.right,
        witness = definition.witness,
        legal_directions = legal,
        directions = directions,
        candidate_count = 0,
        selection_count = 0,
        committed_count = 0,
        executed_count = 0,
        failed_count = 0,
        positive_sum = 0,
        resistance_sum = 0,
        total_sum = 0,
        exclusion_reasons = {},
        status = "untested",
        coverage = "untested",
        executed_direction_count = 0,
        required_direction_count = #definition.directions,
    }
end

local function new_rail(definition)
    return {
        id = definition.id,
        from = definition.from,
        eye = definition.eye,
        debt_kind = definition.debt_kind,
        cases = 0,
        live_eye_count = 0,
        eye_debt_cases = 0,
        required_eye_recall = 0,
        eye_without_debt = 0,
        debt_bypass_proposals = 0,
        fresh_direct_proposals = 0,
        no_prediction_count = 0,
        promotion_status = "insufficient_evidence",
    }
end

local function refresh_edge(record)
    local executed_directions = 0
    for direction in pairs(record.legal_directions) do
        local directional = record.directions[direction]
        if directional and directional.executed_count > 0 then
            executed_directions = executed_directions + 1
        end
    end
    record.executed_direction_count = executed_directions
    if record.executed_count > 0 then
        record.status = "observed_live"
    elseif record.committed_count > 0 then
        record.status = "committed_only"
    elseif record.selection_count > 0 then
        record.status = "shadow_selected"
    elseif record.candidate_count > 0 then
        record.status = "candidate_only"
    else
        record.status = "untested"
    end

    if executed_directions == record.required_direction_count then
        record.coverage = "complete"
    elseif executed_directions > 0 then
        record.coverage = "partial"
    else
        record.coverage = "untested"
    end
end

local function ensure_edge(stats, from, to)
    local definition = catalog.get(from, to)
    if not definition then
        return nil, "transition is outside canonical edge catalog"
    end
    return stats.edges[definition.edge], definition
end

local function ensure_direction(record, from, to)
    local key = tostring(from) .. "->" .. tostring(to)
    if not record.directions[key] then
        record.directions[key] = new_direction(key, false)
    end
    return record.directions[key]
end

local function increment_reason(target, reason)
    reason = reason or "unknown"
    target[reason] = (target[reason] or 0) + 1
end

local function merge_counts(target, source)
    for key, value in pairs(source or {}) do
        target[key] = (target[key] or 0) + value
    end
end

local function contribution_present(shadow, target, kind)
    for _, candidate in ipairs(shadow.candidates or {}) do
        if candidate.to == target then
            for _, value in ipairs(candidate.contributions or {}) do
                if value.kind == kind and value.direction == "help" then
                    return true
                end
            end
        end
    end
    return false
end

local function record_rail(stats, shadow)
    local rail = stats.rails_by_source[shadow.current_operator]
    if not rail then
        return
    end
    rail.cases = rail.cases + 1
    if shadow.live_to == rail.eye then
        rail.live_eye_count = rail.live_eye_count + 1
    end
    local debt = contribution_present(shadow, rail.eye, rail.debt_kind)
    if debt then
        rail.eye_debt_cases = rail.eye_debt_cases + 1
    end
    if shadow.predicted_to == nil then
        rail.no_prediction_count = rail.no_prediction_count + 1
    elseif shadow.predicted_to == rail.eye then
        if debt then
            rail.required_eye_recall = rail.required_eye_recall + 1
        else
            rail.eye_without_debt = rail.eye_without_debt + 1
        end
    elseif debt then
        rail.debt_bypass_proposals = rail.debt_bypass_proposals + 1
    else
        rail.fresh_direct_proposals = rail.fresh_direct_proposals + 1
    end
end

function edge_stats.new(labels)
    local stats = {
        kind = "edge_statistics",
        protocol_version = "edge-stats.v1",
        labels = labels or {},
        shadow_ticks = 0,
        agreement_count = 0,
        divergence_count = 0,
        no_viable_edge_count = 0,
        edges = {},
        edge_order = {},
        rails = {},
        rails_by_source = {},
        truth_status = "runtime_confirmed",
    }
    for _, definition in ipairs(catalog.list()) do
        stats.edges[definition.edge] = new_edge(definition)
        stats.edge_order[#stats.edge_order + 1] = definition.edge
    end
    for _, definition in ipairs(rail_definitions) do
        local rail = new_rail(definition)
        stats.rails[definition.id] = rail
        stats.rails_by_source[definition.from] = rail
    end
    return stats
end

function edge_stats.record(stats, shadow)
    if type(stats) ~= "table" or stats.kind ~= "edge_statistics" then
        return nil, "edge statistics state required"
    end
    if type(shadow) ~= "table" or shadow.kind ~= "shadow_route_decision" then
        return nil, "shadow route decision required"
    end

    stats.shadow_ticks = stats.shadow_ticks + 1
    if shadow.agreement == true then
        stats.agreement_count = stats.agreement_count + 1
    else
        stats.divergence_count = stats.divergence_count + 1
    end
    if shadow.predicted_to == nil then
        stats.no_viable_edge_count = stats.no_viable_edge_count + 1
    end

    for _, candidate in ipairs(shadow.candidates or {}) do
        local record, record_err = ensure_edge(stats, shadow.current_operator, candidate.to)
        if not record then
            return nil, record_err
        end
        local directional = ensure_direction(record, shadow.current_operator, candidate.to)
        record.candidate_count = record.candidate_count + 1
        directional.candidate_count = directional.candidate_count + 1
        record.positive_sum = record.positive_sum + (candidate.positive or 0)
        record.resistance_sum = record.resistance_sum + (candidate.resistance or 0)
        record.total_sum = record.total_sum + (candidate.total or 0)
        directional.positive_sum = directional.positive_sum + (candidate.positive or 0)
        directional.resistance_sum = directional.resistance_sum + (candidate.resistance or 0)
        directional.total_sum = directional.total_sum + (candidate.total or 0)
        if candidate.to == shadow.predicted_to then
            record.selection_count = record.selection_count + 1
            directional.prediction_count = directional.prediction_count + 1
        end
        for _, exclusion in ipairs(candidate.exclusions or {}) do
            local reason = exclusion.reason or exclusion.kind or "unknown"
            increment_reason(record.exclusion_reasons, reason)
            increment_reason(directional.exclusion_reasons, reason)
        end
        refresh_edge(record)
    end
    record_rail(stats, shadow)
    return stats
end

function edge_stats.record_transition(stats, route)
    if type(stats) ~= "table" or stats.kind ~= "edge_statistics" then
        return nil, "edge statistics state required"
    end
    if type(route) ~= "table" or route.from == nil or route.to == nil then
        return nil, "route transition required"
    end
    local record, record_err = ensure_edge(stats, route.from, route.to)
    if not record then
        return nil, record_err
    end
    local directional = ensure_direction(record, route.from, route.to)
    record.committed_count = record.committed_count + 1
    directional.committed_count = directional.committed_count + 1
    refresh_edge(record)
    return record
end

function edge_stats.record_arrival(stats, route, payload)
    if type(stats) ~= "table" or stats.kind ~= "edge_statistics" then
        return nil, "edge statistics state required"
    end
    if type(route) ~= "table" or route.from == nil or route.to == nil then
        return nil, "arrival route required"
    end
    local record, record_err = ensure_edge(stats, route.from, route.to)
    if not record then
        return nil, record_err
    end
    local directional = ensure_direction(record, route.from, route.to)
    record.executed_count = record.executed_count + 1
    directional.executed_count = directional.executed_count + 1
    local kind = type(payload) == "table" and payload.kind or "unknown"
    increment_reason(directional.arrival_kinds, kind)
    refresh_edge(record)
    return record
end

function edge_stats.record_failure(stats, route, failure)
    if type(stats) ~= "table" or stats.kind ~= "edge_statistics" then
        return nil, "edge statistics state required"
    end
    if type(route) ~= "table" or route.from == nil or route.to == nil then
        return nil, "failed arrival route required"
    end
    local record, record_err = ensure_edge(stats, route.from, route.to)
    if not record then
        return nil, record_err
    end
    local directional = ensure_direction(record, route.from, route.to)
    record.failed_count = (record.failed_count or 0) + 1
    directional.failed_count = (directional.failed_count or 0) + 1
    local kind = type(failure) == "table" and (failure.code or failure.kind) or "unknown"
    increment_reason(directional.failure_kinds, kind)
    refresh_edge(record)
    return record
end

function edge_stats.summary(stats)
    if type(stats) ~= "table" or stats.kind ~= "edge_statistics" then
        return nil, "edge statistics state required"
    end
    local status_counts = {}
    local coverage_counts = {}
    local untested_ids = {}
    for _, edge in ipairs(stats.edge_order) do
        local record = stats.edges[edge]
        status_counts[record.status] = (status_counts[record.status] or 0) + 1
        coverage_counts[record.coverage] = (coverage_counts[record.coverage] or 0) + 1
        if record.coverage == "untested" then
            untested_ids[#untested_ids + 1] = record.id
        end
    end
    return {
        kind = "edge_evidence_summary",
        edge_count = #stats.edge_order,
        status_counts = status_counts,
        coverage_counts = coverage_counts,
        untested_ids = untested_ids,
        rail_count = #rail_definitions,
        shadow_ticks = stats.shadow_ticks,
        agreement_count = stats.agreement_count,
        divergence_count = stats.divergence_count,
        truth_status = "runtime_confirmed",
    }
end

function edge_stats.merge(target, source)
    if type(target) ~= "table" or target.kind ~= "edge_statistics" then
        return nil, "target edge statistics state required"
    end
    if type(source) ~= "table" or source.kind ~= "edge_statistics" then
        return nil, "source edge statistics state required"
    end

    for _, key in ipairs({
        "shadow_ticks",
        "agreement_count",
        "divergence_count",
        "no_viable_edge_count",
    }) do
        target[key] = (target[key] or 0) + (source[key] or 0)
    end

    for _, edge in ipairs(target.edge_order) do
        local into = target.edges[edge]
        local from = source.edges[edge]
        if from then
            for _, key in ipairs({
                "candidate_count",
                "selection_count",
                "committed_count",
                "executed_count",
                "failed_count",
                "positive_sum",
                "resistance_sum",
                "total_sum",
            }) do
                into[key] = (into[key] or 0) + (from[key] or 0)
            end
            merge_counts(into.exclusion_reasons, from.exclusion_reasons)
            for direction, source_direction in pairs(from.directions or {}) do
                local target_direction = into.directions[direction]
                    or new_direction(direction, source_direction.legal)
                into.directions[direction] = target_direction
                for _, key in ipairs({
                    "candidate_count",
                    "prediction_count",
                    "committed_count",
                    "executed_count",
                    "failed_count",
                    "positive_sum",
                    "resistance_sum",
                    "total_sum",
                }) do
                    target_direction[key] = (target_direction[key] or 0) + (source_direction[key] or 0)
                end
                merge_counts(target_direction.exclusion_reasons, source_direction.exclusion_reasons)
                merge_counts(target_direction.arrival_kinds, source_direction.arrival_kinds)
                merge_counts(target_direction.failure_kinds, source_direction.failure_kinds)
            end
            refresh_edge(into)
        end
    end

    for id, source_rail in pairs(source.rails or {}) do
        local target_rail = target.rails[id]
        if target_rail then
            for _, key in ipairs({
                "cases",
                "live_eye_count",
                "eye_debt_cases",
                "required_eye_recall",
                "eye_without_debt",
                "debt_bypass_proposals",
                "fresh_direct_proposals",
                "no_prediction_count",
            }) do
                target_rail[key] = (target_rail[key] or 0) + (source_rail[key] or 0)
            end
        end
    end
    return target
end

return edge_stats
