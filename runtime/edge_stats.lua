local catalog = require("runtime.edge_catalog")

local edge_stats = {}

edge_stats.protocol_version = "edge-stats.v2"

local observer_authorities = {
    tree = "legacy_control",
    legacy = "tree",
}

local observer_counter_keys = {
    "comparison_count",
    "agreement_count",
    "divergence_count",
    "no_prediction_count",
    "unavailable_count",
}

local rail_channel_definitions = {
    tree_shadow = {
        id = "tree_shadow",
        evidence_role = "counterfactual_prediction",
        observer = "tree",
        observed_authority = "legacy_control",
        authority = "none",
        target_kind = "predicted_to",
    },
    tree_authority = {
        id = "tree_authority",
        evidence_role = "authoritative_derivation",
        authority = "tree",
        target_kind = "selected_to",
    },
}

local rail_counter_keys = {
    "cases",
    "target_count",
    "reference_eye_count",
    "eye_debt_cases",
    "eye_target_count",
    "debt_eye_target_count",
    "fresh_eye_target_count",
    "debt_bypass_count",
    "fresh_direct_count",
    "no_target_count",
}

local function validate_stats(stats)
    if type(stats) ~= "table" or stats.kind ~= "edge_statistics" then
        return nil, "edge statistics state required"
    end
    if stats.protocol_version ~= edge_stats.protocol_version then
        return nil, "edge statistics protocol mismatch"
    end
    return true
end

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
        authority_counts = {},
        derivation_refs = {},
        failure_refs = {},
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
        authority_counts = {},
        derivation_refs = {},
        failure_refs = {},
        status = "untested",
        coverage = "untested",
        executed_direction_count = 0,
        required_direction_count = #definition.directions,
    }
end

local function new_observer(observer_id, observed_authority)
    return {
        observer = observer_id,
        observed_authority = observed_authority or observer_authorities[observer_id],
        evidence_role = "route_comparison",
        comparison_count = 0,
        agreement_count = 0,
        divergence_count = 0,
        no_prediction_count = 0,
        unavailable_count = 0,
        outcome_counts = {},
    }
end

local function new_rail_channel(definition)
    return {
        id = definition.id,
        evidence_role = definition.evidence_role,
        observer = definition.observer,
        observed_authority = definition.observed_authority,
        authority = definition.authority,
        target_kind = definition.target_kind,
        cases = 0,
        target_count = 0,
        reference_eye_count = 0,
        eye_debt_cases = 0,
        eye_target_count = 0,
        debt_eye_target_count = 0,
        fresh_eye_target_count = 0,
        debt_bypass_count = 0,
        fresh_direct_count = 0,
        no_target_count = 0,
    }
end

local function new_rail(definition)
    return {
        id = definition.id,
        from = definition.from,
        eye = definition.eye,
        debt_kind = definition.debt_kind,
        channels = {
            tree_shadow = new_rail_channel(rail_channel_definitions.tree_shadow),
            tree_authority = new_rail_channel(rail_channel_definitions.tree_authority),
        },
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

local function append_unique(target, value)
    if type(value) ~= "string" or value == "" then
        return
    end
    for _, existing in ipairs(target) do
        if existing == value then
            return
        end
    end
    target[#target + 1] = value
end

local function merge_unique(target, source)
    for _, value in ipairs(source or {}) do
        append_unique(target, value)
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

local function record_rail(stats, evidence, channel_id)
    local rail = stats.rails_by_source[evidence.current_operator]
    if not rail then
        return stats
    end
    local channel = rail.channels[channel_id]
    if not channel then
        return nil, "unknown rail evidence channel: " .. tostring(channel_id)
    end

    channel.cases = channel.cases + 1
    if evidence.reference_to == rail.eye then
        channel.reference_eye_count = channel.reference_eye_count + 1
    end
    local debt = contribution_present(evidence, rail.eye, rail.debt_kind)
    if debt then
        channel.eye_debt_cases = channel.eye_debt_cases + 1
    end

    if evidence.target_to == nil then
        channel.no_target_count = channel.no_target_count + 1
        return channel
    end

    channel.target_count = channel.target_count + 1
    if evidence.target_to == rail.eye then
        channel.eye_target_count = channel.eye_target_count + 1
        if debt then
            channel.debt_eye_target_count = channel.debt_eye_target_count + 1
        else
            channel.fresh_eye_target_count = channel.fresh_eye_target_count + 1
        end
    elseif debt then
        channel.debt_bypass_count = channel.debt_bypass_count + 1
    else
        channel.fresh_direct_count = channel.fresh_direct_count + 1
    end
    return channel
end

local function record_candidates(stats, current_operator, candidates, selected_to, derivation_ref)
    for _, candidate in ipairs(candidates or {}) do
        local record, record_err = ensure_edge(stats, current_operator, candidate.to)
        if not record then
            return nil, record_err
        end
        local directional = ensure_direction(record, current_operator, candidate.to)
        record.candidate_count = record.candidate_count + 1
        directional.candidate_count = directional.candidate_count + 1
        record.positive_sum = record.positive_sum + (candidate.positive or 0)
        record.resistance_sum = record.resistance_sum + (candidate.resistance or 0)
        record.total_sum = record.total_sum + (candidate.total or 0)
        directional.positive_sum = directional.positive_sum + (candidate.positive or 0)
        directional.resistance_sum = directional.resistance_sum + (candidate.resistance or 0)
        directional.total_sum = directional.total_sum + (candidate.total or 0)
        append_unique(record.derivation_refs, derivation_ref)
        append_unique(directional.derivation_refs, derivation_ref)
        if candidate.to == selected_to then
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
    return stats
end

function edge_stats.new(labels)
    local stats = {
        kind = "edge_statistics",
        protocol_version = edge_stats.protocol_version,
        labels = labels or {},
        comparison_count = 0,
        tree_derivation_count = 0,
        tree_no_viable_count = 0,
        tree_outcome_counts = {},
        observers = {
            tree = new_observer("tree", "legacy_control"),
            legacy = new_observer("legacy", "tree"),
        },
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
    local valid, valid_err = validate_stats(stats)
    if not valid then
        return nil, valid_err
    end
    if type(shadow) ~= "table" or shadow.kind ~= "shadow_route_decision" then
        return nil, "shadow route decision required"
    end

    local observer_id = shadow.observer
    local observed_authority = shadow.live_authority
    if type(observer_id) ~= "string" or observer_id == "" then
        return nil, "shadow observer identity required"
    end
    if type(observed_authority) ~= "string" or observed_authority == "" then
        return nil, "shadow observed authority required"
    end
    local expected_authority = observer_authorities[observer_id]
    if expected_authority and observed_authority ~= expected_authority then
        return nil, "observer authority mismatch: " .. observer_id
    end

    local observer = stats.observers[observer_id]
    if not observer then
        observer = new_observer(observer_id, observed_authority)
        stats.observers[observer_id] = observer
    elseif observer.observed_authority ~= observed_authority then
        return nil, "observer authority changed: " .. observer_id
    end

    stats.comparison_count = stats.comparison_count + 1
    observer.comparison_count = observer.comparison_count + 1
    if shadow.agreement == true then
        observer.agreement_count = observer.agreement_count + 1
    else
        observer.divergence_count = observer.divergence_count + 1
    end
    if shadow.predicted_to == nil then
        observer.no_prediction_count = observer.no_prediction_count + 1
    end
    if shadow.instrumentation_status == "unavailable" then
        observer.unavailable_count = observer.unavailable_count + 1
    end
    local prediction_outcome = shadow.prediction_outcome
        or (shadow.predicted_to ~= nil and "selected" or "no_prediction")
    increment_reason(observer.outcome_counts, prediction_outcome)

    if observer_id == "tree" then
        local recorded, record_err = record_candidates(
            stats,
            shadow.current_operator,
            shadow.candidates,
            shadow.predicted_to,
            shadow.derivation_ref
        )
        if not recorded then
            return nil, record_err
        end
        local rail_recorded, rail_err = record_rail(stats, {
            current_operator = shadow.current_operator,
            candidates = shadow.candidates,
            target_to = shadow.predicted_to,
            reference_to = shadow.live_to,
        }, "tree_shadow")
        if not rail_recorded then
            return nil, rail_err
        end
    end
    return stats
end

function edge_stats.record_tree_derivation(stats, decision)
    local valid, valid_err = validate_stats(stats)
    if not valid then
        return nil, valid_err
    end
    if type(decision) ~= "table" or decision.authority ~= "tree"
        or decision.from == nil or type(decision.candidates) ~= "table" then
        return nil, "tree route derivation required"
    end

    stats.tree_derivation_count = stats.tree_derivation_count + 1
    if decision.kind == "no_viable_edge" then
        stats.tree_no_viable_count = stats.tree_no_viable_count + 1
    end
    increment_reason(
        stats.tree_outcome_counts,
        decision.kind == "tree_route_decision" and "selected" or decision.kind
    )
    local recorded, record_err = record_candidates(
        stats,
        decision.from,
        decision.candidates,
        decision.to,
        decision.derivation_ref
    )
    if not recorded then
        return nil, record_err
    end
    local rail_recorded, rail_err = record_rail(stats, {
        current_operator = decision.from,
        candidates = decision.candidates,
        target_to = decision.to,
    }, "tree_authority")
    if not rail_recorded then
        return nil, rail_err
    end
    return stats
end

function edge_stats.record_transition(stats, route)
    local valid, valid_err = validate_stats(stats)
    if not valid then
        return nil, valid_err
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
    local authority = route.authority or "legacy_control"
    increment_reason(record.authority_counts, authority)
    increment_reason(directional.authority_counts, authority)
    append_unique(record.derivation_refs, route.derivation_ref)
    append_unique(directional.derivation_refs, route.derivation_ref)
    refresh_edge(record)
    return record
end

function edge_stats.record_arrival(stats, route, payload)
    local valid, valid_err = validate_stats(stats)
    if not valid then
        return nil, valid_err
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

function edge_stats.record_failure(stats, route, failure, failure_ref)
    local valid, valid_err = validate_stats(stats)
    if not valid then
        return nil, valid_err
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
    append_unique(record.failure_refs, failure_ref)
    append_unique(directional.failure_refs, failure_ref)
    refresh_edge(record)
    return record
end

function edge_stats.summary(stats)
    local valid, valid_err = validate_stats(stats)
    if not valid then
        return nil, valid_err
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
        protocol_version = edge_stats.protocol_version,
        edge_count = #stats.edge_order,
        status_counts = status_counts,
        coverage_counts = coverage_counts,
        untested_ids = untested_ids,
        rail_count = #rail_definitions,
        comparison_count = stats.comparison_count,
        tree_derivation_count = stats.tree_derivation_count,
        tree_no_viable_count = stats.tree_no_viable_count,
        tree_outcome_counts = stats.tree_outcome_counts,
        observers = stats.observers,
        truth_status = "runtime_confirmed",
    }
end

local observer_metadata_keys = {
    "observer",
    "observed_authority",
    "evidence_role",
}

local rail_metadata_keys = {
    "id",
    "evidence_role",
    "observer",
    "observed_authority",
    "authority",
    "target_kind",
}

local function same_metadata(left, right, keys)
    for _, key in ipairs(keys) do
        if left[key] ~= right[key] then
            return nil, key
        end
    end
    return true
end

local function validate_merge_contract(target, source)
    if target.protocol_version ~= edge_stats.protocol_version
        or source.protocol_version ~= edge_stats.protocol_version then
        return nil, "edge statistics protocol mismatch"
    end

    for observer_id, source_observer in pairs(source.observers or {}) do
        if source_observer.observer ~= observer_id
            or type(source_observer.observed_authority) ~= "string"
            or source_observer.evidence_role ~= "route_comparison" then
            return nil, "invalid observer metadata: " .. tostring(observer_id)
        end
        local expected_authority = observer_authorities[observer_id]
        if expected_authority
            and source_observer.observed_authority ~= expected_authority then
            return nil, "observer authority mismatch: " .. observer_id
        end
        local target_observer = target.observers[observer_id]
        if target_observer then
            local same, key = same_metadata(
                target_observer,
                source_observer,
                observer_metadata_keys
            )
            if not same then
                return nil, "observer metadata mismatch: "
                    .. observer_id .. "." .. tostring(key)
            end
        end
    end

    for rail_id, source_rail in pairs(source.rails or {}) do
        local target_rail = target.rails[rail_id]
        if not target_rail then
            return nil, "unknown rail: " .. tostring(rail_id)
        end
        for channel_id, source_channel in pairs(source_rail.channels or {}) do
            if source_channel.id ~= channel_id
                or type(source_channel.evidence_role) ~= "string"
                or type(source_channel.authority) ~= "string"
                or type(source_channel.target_kind) ~= "string" then
                return nil, "invalid rail channel metadata: "
                    .. tostring(rail_id) .. "." .. tostring(channel_id)
            end
            local target_channel = target_rail.channels[channel_id]
            if target_channel then
                local same, key = same_metadata(
                    target_channel,
                    source_channel,
                    rail_metadata_keys
                )
                if not same then
                    return nil, "rail channel metadata mismatch: "
                        .. tostring(rail_id) .. "." .. tostring(channel_id)
                        .. "." .. tostring(key)
                end
            end
        end
    end
    return true
end

function edge_stats.merge(target, source)
    if type(target) ~= "table" or target.kind ~= "edge_statistics" then
        return nil, "target edge statistics state required"
    end
    if type(source) ~= "table" or source.kind ~= "edge_statistics" then
        return nil, "source edge statistics state required"
    end
    local valid, valid_err = validate_merge_contract(target, source)
    if not valid then
        return nil, valid_err
    end

    for _, key in ipairs({
        "comparison_count",
        "tree_derivation_count",
        "tree_no_viable_count",
    }) do
        target[key] = (target[key] or 0) + (source[key] or 0)
    end

    for observer_id, source_observer in pairs(source.observers or {}) do
        local target_observer = target.observers[observer_id]
        if not target_observer then
            target_observer = new_observer(
                observer_id,
                source_observer.observed_authority
            )
            target.observers[observer_id] = target_observer
        end
        for _, key in ipairs(observer_counter_keys) do
            target_observer[key] = (target_observer[key] or 0)
                + (source_observer[key] or 0)
        end
        merge_counts(target_observer.outcome_counts, source_observer.outcome_counts)
    end

    merge_counts(target.tree_outcome_counts, source.tree_outcome_counts)

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
            merge_counts(into.authority_counts, from.authority_counts)
            merge_unique(into.derivation_refs, from.derivation_refs)
            merge_unique(into.failure_refs, from.failure_refs)
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
                merge_counts(target_direction.authority_counts, source_direction.authority_counts)
                merge_unique(target_direction.derivation_refs, source_direction.derivation_refs)
                merge_unique(target_direction.failure_refs, source_direction.failure_refs)
            end
            refresh_edge(into)
        end
    end

    for id, source_rail in pairs(source.rails or {}) do
        local target_rail = target.rails[id]
        if target_rail then
            for channel_id, source_channel in pairs(source_rail.channels or {}) do
                local target_channel = target_rail.channels[channel_id]
                if not target_channel then
                    target_channel = new_rail_channel(source_channel)
                    target_rail.channels[channel_id] = target_channel
                end
                for _, key in ipairs(rail_counter_keys) do
                    target_channel[key] = (target_channel[key] or 0)
                        + (source_channel[key] or 0)
                end
            end
        end
    end
    return target
end

return edge_stats
