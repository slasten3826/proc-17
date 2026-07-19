local topology = require("core.topology")
local registry = require("runtime.operator_registry")
local pressure = require("runtime.pressure")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local pressure_composition = require("runtime.pressure_composition")

local tree_router = {
    policy = "pressure.binary.v0",
    policy_status = "vibed_control",
}

local canonical_index = {}
for index, glyph in ipairs(topology.order) do
    canonical_index[glyph] = index
end

local function copy_array(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = value
    end
    return result
end

local function add_exclusion(candidate, kind, reason, refs)
    candidate.exclusions[#candidate.exclusions + 1] = {
        kind = kind,
        reason = reason or kind,
        source_refs = copy_array(refs),
        event_truth_status = "runtime_confirmed",
    }
end

local function context_for_registry(context)
    context = context or {}
    return {
        substrate = context.substrate,
        capabilities = context.capabilities,
        options = context.options or {},
        result = context.result,
    }
end

local function affordability(instance, descriptor)
    local budget_state = budget.snapshot(instance)
    local loss_state = loss.snapshot(instance)
    local reasons = {}
    local steps = budget_state.remaining.steps
    if type(steps) == "number" and steps <= 0 then
        reasons[#reasons + 1] = "step_budget_exhausted"
    end
    if descriptor.glyph == "☴" then
        local calls = budget_state.remaining.substrate_calls
        if type(calls) == "number" and calls <= 0 then
            reasons[#reasons + 1] = "substrate_call_budget_exhausted"
        end
    end
    if descriptor.loss_profile == "mandatory" and loss_state.loss_remaining <= 0 then
        reasons[#reasons + 1] = "identity_loss_exhausted"
    end
    return #reasons == 0, reasons
end

local function contributions_for(snapshot, target)
    local result = {}
    for _, value in ipairs(snapshot.contributions or {}) do
        if value.target_operator == target
            and value.target_edge == pressure.edge(snapshot.current_operator, target) then
            result[#result + 1] = value
        end
    end
    return result
end

local function totals(contributions)
    local positive = 0
    local resistance = 0
    for _, value in ipairs(contributions or {}) do
        if value.direction == "resist" then
            resistance = resistance + (tonumber(value.amount) or 0)
        elseif value.direction == "help" then
            positive = positive + (tonumber(value.amount) or 0)
        end
    end
    return positive, resistance, positive - resistance
end

function tree_router.candidates(instance, snapshot, context)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    if type(snapshot) == "table" and snapshot.kind == "qualified_pressure_snapshot" then
        return pressure_composition.candidates(instance, snapshot, context)
    end
    if type(snapshot) ~= "table" or snapshot.kind ~= "edge_pressure_snapshot" then
        return nil, "pressure snapshot required"
    end
    local current = topology.resolve(snapshot.current_operator)
    if not current then
        return nil, "pressure snapshot has invalid operator"
    end

    local candidates = {}
    local registry_context = context_for_registry(context)
    for _, target in ipairs(topology.order) do
        if topology.is_adjacent(current, target) then
            local values = contributions_for(snapshot, target)
            local positive, resistance, total = totals(values)
            local descriptor = registry.get(target)
            local candidate = {
                to = target,
                edge = pressure.edge(current, target),
                contributions = values,
                positive = positive,
                resistance = resistance,
                total = total,
                readiness = nil,
                affordable = false,
                exclusions = {},
                excluded = false,
            }

            if current == "△" then
                add_exclusion(candidate, "lifecycle", "manifest_has_no_same_life_successor")
            elseif target == "▽" then
                add_exclusion(candidate, "lifecycle", "living_packet_cannot_return_to_flow")
            elseif not descriptor then
                add_exclusion(candidate, "registry", "operator_not_registered")
            else
                local available, available_reason, missing = registry.available(
                    target,
                    instance,
                    registry_context
                )
                if not available then
                    add_exclusion(candidate, "availability", available_reason, missing)
                else
                    local readiness, readiness_err = registry.readiness(
                        target,
                        instance,
                        registry_context
                    )
                    if not readiness then
                        add_exclusion(candidate, "readiness_error", readiness_err)
                    else
                        candidate.readiness = readiness
                        if not readiness.ready then
                            add_exclusion(candidate, "readiness", readiness.reason, readiness.source_refs)
                        elseif target == "☳" and readiness.collapse_possible == false then
                            add_exclusion(candidate, "readiness", "confirmation_not_choice", readiness.source_refs)
                        end
                    end
                end

                local affordable, affordability_reasons = affordability(instance, descriptor)
                candidate.affordable = affordable
                if not affordable then
                    for _, reason in ipairs(affordability_reasons) do
                        add_exclusion(candidate, "affordability", reason)
                    end
                end
            end

            candidate.excluded = #candidate.exclusions > 0
            candidates[#candidates + 1] = candidate
        end
    end
    return candidates
end

local function no_viable_cause(candidates)
    local saw_missing_capability = false
    local saw_ready = false
    local saw_unsafe = false
    for _, candidate in ipairs(candidates or {}) do
        if candidate.readiness and candidate.readiness.ready then
            saw_ready = true
        end
        for _, exclusion in ipairs(candidate.exclusions or {}) do
            if exclusion.reason == "missing_capability" then
                saw_missing_capability = true
            elseif exclusion.kind == "safety" then
                saw_unsafe = true
            end
        end
    end
    if saw_unsafe then
        return "unsafe"
    end
    if saw_missing_capability and not saw_ready then
        return "missing_capability"
    end
    if saw_ready then
        return "below_threshold"
    end
    return "stalled"
end

function tree_router.select(instance, candidates, options)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    if type(candidates) ~= "table" then
        return nil, "candidate list required"
    end
    options = options or {}
    local threshold = options.threshold
    if threshold == nil then
        threshold = 0
    end
    if type(threshold) ~= "number" then
        return nil, "movement threshold must be number"
    end

    local winner
    local tied = false
    for _, candidate in ipairs(candidates) do
        if not candidate.excluded and candidate.total > threshold then
            if not winner or candidate.total > winner.total then
                winner = candidate
                tied = false
            elseif candidate.total == winner.total then
                tied = true
                if (canonical_index[candidate.to] or math.huge)
                    < (canonical_index[winner.to] or math.huge) then
                    winner = candidate
                end
            end
        end
    end

    if not winner then
        return {
            kind = "no_viable_edge",
            cause = no_viable_cause(candidates),
            candidates = candidates,
            threshold = threshold,
            policy = tree_router.policy,
            policy_status = tree_router.policy_status,
            event_truth_status = "runtime_confirmed",
        }
    end

    return {
        kind = "tree_route_decision",
        policy = tree_router.policy,
        policy_status = tree_router.policy_status,
        from = instance.operator,
        to = winner.to,
        candidates = candidates,
        reason = tied and "highest_pressure_canonical_tie_break" or "highest_positive_pressure",
        winning_total = winner.total,
        threshold = threshold,
        event_truth_status = "runtime_confirmed",
    }
end

function tree_router.predict(instance, snapshot, context)
    if type(snapshot) == "table" and snapshot.kind == "qualified_pressure_snapshot" then
        local qualified_context = {}
        for key, value in pairs(context or {}) do
            qualified_context[key] = value
        end
        qualified_context.composition = context and context.tree or {}
        return pressure_composition.predict(instance, snapshot, qualified_context)
    end
    local candidates, candidate_err = tree_router.candidates(instance, snapshot, context)
    if not candidates then
        return nil, candidate_err
    end
    local options = context and context.tree or {}
    local decision, decision_err = tree_router.select(instance, candidates, options)
    if not decision then
        return nil, decision_err
    end
    decision.from = snapshot.current_operator
    decision.source_snapshot_ref = snapshot.trace_event_id or snapshot.id
    return decision
end

return tree_router
