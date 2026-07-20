local json = require("core.json")
local topology = require("core.topology")
local field = require("runtime.field")
local registry = require("runtime.operator_registry")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local pressure_action = require("runtime.pressure_action")

local composition = {
    policy = "pressure.class_order.v0",
    policy_status = "shadow_treatment",
}

local class_rank = {
    causal_affordance = 1,
    blocking_demand = 2,
    terminal_boundary = 3,
}

local canonical_index = {}
for index, glyph in ipairs(topology.order) do
    canonical_index[glyph] = index
end

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

local function same_value(left, right)
    return json.encode(left) == json.encode(right)
end

local function edge(left, right)
    if canonical_index[left] <= canonical_index[right] then
        return left .. "-" .. right
    end
    return right .. "-" .. left
end

local function add_exclusion(candidate, kind, reason, refs)
    candidate.exclusions[#candidate.exclusions + 1] = {
        kind = kind,
        reason = reason or kind,
        source_refs = copy_value(refs or {}),
        event_truth_status = "runtime_confirmed",
    }
end

local function recursive_contains(value, needle, seen)
    if value == needle then
        return true
    end
    if type(value) ~= "table" then
        return false
    end
    seen = seen or {}
    if seen[value] then
        return false
    end
    seen[value] = true
    for key, child in pairs(value) do
        if recursive_contains(key, needle, seen)
            or recursive_contains(child, needle, seen) then
            return true
        end
    end
    return false
end

local function provenance_resolves(instance, ref)
    if ref == "consumer:encode.relation_formation.v0"
        or ref == "consumer:calm.work_structure.v0"
        or ref == "consumer:calm.singular_focus.v0"
        or ref == "consumer:runtime.plan_completion.v0"
        or ref == "consumer:manifest.plan_delivery.v0"
        or ref == "consumer:runtime.repository_action_review.v0"
        or ref == "consumer:logic.repository_effect.v0"
        or ref == "consumer:runtime.repository_reconcile.v0"
        or ref == "consumer:manifest.repository_result.v0" then
        return true
    end
    for _, event in ipairs(instance.trace or {}) do
        if event.id == ref then
            return true
        end
    end
    if field.get_unit(instance, ref) ~= nil then
        return true
    end
    local covered_id, covered_version = ref:match(
        "^coverage:field_unit:(.+):(%d+)$"
    )
    if covered_id then
        local unit = field.get_unit(instance, covered_id)
        if unit and unit.version == tonumber(covered_version) then
            return true
        end
    end
    local relations = instance.field and instance.field.relations or {}
    for _, scope in ipairs({relations.raw, relations.active}) do
        for _, relation in ipairs(scope and scope.items or {}) do
            if relation.id == ref then
                return true
            end
        end
    end
    return recursive_contains(instance.ingress, ref)
end

local function validate_witness(instance, snapshot, witness)
    if type(witness) ~= "table" or witness.protocol_version ~= "pressure.witness.v1"
        or type(witness.witness_id) ~= "string" or witness.witness_id == ""
        or not class_rank[witness.causal_class]
        or type(witness.source_domain) ~= "string" or witness.source_domain == ""
        or #witness.source_domain > 128
        or witness.calculation_status ~= "runtime_confirmed"
        or type(witness.source_truth_status) ~= "string"
        or witness.source_truth_status == "" then
        return nil, "invalid qualified pressure witness"
    end
    local current = topology.resolve(witness.current_operator)
    local target = topology.resolve(witness.target_operator)
    if current ~= snapshot.current_operator or not target
        or not topology.is_adjacent(current, target)
        or witness.target_edge ~= edge(current, target)
        or type(witness.scope_refs) ~= "table" or #witness.scope_refs == 0
        or type(witness.provenance_refs) ~= "table" then
        return nil, "qualified pressure witness topology/scope mismatch"
    end
    local plan_ok, plan_err = pressure_action.validate(witness.action_plan)
    if not plan_ok then
        return nil, plan_err
    end
    if witness.action_plan.witness_id ~= witness.witness_id
        or witness.action_plan.target_operator ~= target
        or not same_value(witness.action_plan.scope_refs, witness.scope_refs) then
        return nil, "qualified pressure witness/action mismatch"
    end
    local fresh, fresh_err = pressure_action.verify_preconditions(
        witness.action_plan,
        instance
    )
    if not fresh then
        return nil, fresh_err
    end
    for _, ref in ipairs(witness.provenance_refs) do
        if not provenance_resolves(instance, ref) then
            return nil, "unresolved qualified provenance ref: " .. tostring(ref)
        end
    end
    return true
end

local function affordability(instance, descriptor, plan)
    local budget_state = budget.snapshot(instance)
    local loss_state = loss.snapshot(instance)
    local reasons = {}
    if type(budget_state.remaining.steps) == "number"
        and budget_state.remaining.steps <= 0 then
        reasons[#reasons + 1] = "step_budget_exhausted"
    end
    if plan and plan.mode == "semantic_observe"
        and type(budget_state.remaining.substrate_calls) == "number"
        and budget_state.remaining.substrate_calls <= 0 then
        reasons[#reasons + 1] = "substrate_call_budget_exhausted"
    end
    if descriptor.loss_profile == "mandatory" and loss_state.loss_remaining <= 0 then
        reasons[#reasons + 1] = "identity_loss_exhausted"
    end
    return #reasons == 0, reasons
end

local function highest_class(witnesses)
    local selected
    for _, witness in ipairs(witnesses or {}) do
        if selected == nil
            or class_rank[witness.causal_class] > class_rank[selected] then
            selected = witness.causal_class
        end
    end
    return selected
end

local function witnesses_for(snapshot, target)
    local result = {}
    for _, witness in ipairs(snapshot.witnesses or {}) do
        if witness.target_operator == target then
            result[#result + 1] = witness
        end
    end
    table.sort(result, function(left, right)
        return left.witness_id < right.witness_id
    end)
    return result
end

local function merge_plans(witnesses)
    local merged
    for _, witness in ipairs(witnesses) do
        if merged == nil then
            merged = copy_value(witness.action_plan)
        else
            local next_plan, merge_err = pressure_action.merge(
                merged,
                witness.action_plan
            )
            if not next_plan then
                return nil, merge_err
            end
            merged = next_plan
        end
    end
    return merged
end

local function registry_base_context(instance, context)
    context = context or {}
    return {
        instance = instance,
        substrate = context.substrate,
        capabilities = context.capabilities,
        options = context.options or {},
        result = context.result,
        host_services = context.host_services
            or (context.options and context.options.host_services),
    }
end

function composition.candidates(instance, snapshot, context)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    if type(snapshot) ~= "table"
        or snapshot.kind ~= "qualified_pressure_snapshot"
        or snapshot.derivation_version ~= "pressure.qualified_need.v0" then
        return nil, "qualified pressure snapshot required"
    end
    local current = topology.resolve(snapshot.current_operator)
    if not current then
        return nil, "qualified pressure snapshot has invalid operator"
    end

    for _, witness in ipairs(snapshot.witnesses or {}) do
        local valid, valid_err = validate_witness(instance, snapshot, witness)
        if not valid then
            return nil, "invariant_failure: " .. tostring(valid_err)
        end
    end

    local candidates = {}
    for _, target in ipairs(topology.order) do
        if topology.is_adjacent(current, target) then
            local witnesses = witnesses_for(snapshot, target)
            local candidate = {
                to = target,
                edge = edge(current, target),
                witnesses = copy_value(witnesses),
                witness_count = #witnesses,
                highest_class = highest_class(witnesses),
                action_plan = nil,
                action_status = #witnesses > 0 and "pending" or "absent",
                readiness = nil,
                affordable = false,
                executable_witnesses = {},
                witness_exclusions = {},
                exclusions = {},
                excluded = false,
                promotion_eligible = #snapshot.unqualified == 0,
            }
            for _, witness in ipairs(witnesses) do
                if witness.promotion_source == "fixture" then
                    candidate.promotion_eligible = false
                end
            end

            if #witnesses == 0 then
                add_exclusion(candidate, "pressure", "no_qualified_need")
            elseif current == "△" then
                add_exclusion(candidate, "lifecycle", "manifest_has_no_same_life_successor")
            elseif target == "▽" then
                add_exclusion(candidate, "lifecycle", "living_packet_cannot_return_to_flow")
            else
                local descriptor = registry.get(target)
                if not descriptor then
                    add_exclusion(candidate, "registry", "operator_not_registered")
                else
                    for _, witness in ipairs(witnesses) do
                        local witness_context, context_err = pressure_action.registry_context(
                            witness.action_plan,
                            registry_base_context(instance, context)
                        )
                        if not witness_context then
                            return nil, "invariant_failure: " .. tostring(context_err)
                        end
                        local available, available_reason, missing = registry.available(
                            target,
                            instance,
                            witness_context
                        )
                        local affordable, reasons = affordability(
                            instance,
                            descriptor,
                            witness.action_plan
                        )
                        if available and affordable then
                            candidate.executable_witnesses[
                                #candidate.executable_witnesses + 1
                            ] = witness
                        else
                            candidate.witness_exclusions[#candidate.witness_exclusions + 1] = {
                                witness_id = witness.witness_id,
                                availability_reason = available and nil or available_reason,
                                missing_capabilities = copy_value(missing or {}),
                                affordability_reasons = copy_value(reasons or {}),
                                event_truth_status = "runtime_confirmed",
                            }
                        end
                    end
                end

                candidate.executable_witness_count = #candidate.executable_witnesses
                candidate.highest_class = highest_class(candidate.executable_witnesses)
                    or candidate.highest_class
                if descriptor and #candidate.executable_witnesses == 0 then
                    add_exclusion(
                        candidate,
                        "availability",
                        "no_executable_qualified_witness"
                    )
                end

                local merged, merge_err
                if descriptor and #candidate.executable_witnesses > 0 then
                    merged, merge_err = merge_plans(candidate.executable_witnesses)
                end
                if not merged then
                    if merge_err and tostring(merge_err):find("ambiguous_action", 1, true) then
                        candidate.action_status = "ambiguous_action"
                        candidate.action_error = merge_err
                    elseif merge_err then
                        return nil, "invariant_failure: " .. tostring(merge_err)
                    end
                else
                    candidate.action_plan = merged
                    candidate.action_status = "validated"
                    local registry_context, context_err = pressure_action.registry_context(
                        merged,
                        registry_base_context(instance, context)
                    )
                    if not registry_context then
                        return nil, "invariant_failure: " .. tostring(context_err)
                    end
                    local readiness, readiness_err = registry.readiness(
                        target,
                        instance,
                        registry_context
                    )
                    if not readiness then
                        return nil, "invariant_failure: " .. tostring(readiness_err)
                    end
                    candidate.readiness = readiness
                    if not readiness.ready then
                        add_exclusion(
                            candidate,
                            "readiness",
                            readiness.reason,
                            readiness.source_refs
                        )
                    else
                        local scope_ok, scope_err = pressure_action.verify_readiness(
                            merged,
                            readiness
                        )
                        if not scope_ok then
                            return nil, "invariant_failure: " .. tostring(scope_err)
                        end
                    end
                    local affordable = affordability(
                        instance,
                        descriptor,
                        merged
                    )
                    candidate.affordable = affordable == true
                    if not candidate.affordable then
                        add_exclusion(
                            candidate,
                            "affordability",
                            "merged_action_not_affordable"
                        )
                    end
                end
            end
            candidate.excluded = #candidate.exclusions > 0
            candidates[#candidates + 1] = candidate
        end
    end
    return candidates
end

local function outcome(kind, candidates, extra)
    local result = {
        kind = kind,
        cause = kind,
        candidates = candidates,
        policy = composition.policy,
        policy_status = composition.policy_status,
        event_truth_status = "runtime_confirmed",
        promotion_eligible = false,
    }
    for key, value in pairs(extra or {}) do
        result[key] = value
    end
    return result
end

function composition.select(instance, candidates, options)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    if type(candidates) ~= "table" then
        return nil, "candidate list required"
    end
    options = options or {}
    if options.policy ~= nil and options.policy ~= composition.policy then
        return nil, "invalid pressure composition policy"
    end

    local with_witnesses = {}
    for _, candidate in ipairs(candidates) do
        if (candidate.witness_count or #(candidate.witnesses or {})) > 0 then
            with_witnesses[#with_witnesses + 1] = candidate
        end
    end
    if #with_witnesses == 0 then
        return outcome("no_qualified_need", candidates)
    end

    local relevant = {}
    local highest_rank = 0
    for _, candidate in ipairs(with_witnesses) do
        if candidate.action_status == "ambiguous_action" or not candidate.excluded then
            local rank = class_rank[candidate.highest_class] or 0
            if rank > highest_rank then
                highest_rank = rank
                relevant = {candidate}
            elseif rank == highest_rank then
                relevant[#relevant + 1] = candidate
            end
        end
    end
    if #relevant == 0 then
        return outcome("no_viable_edge", candidates)
    end

    for _, candidate in ipairs(relevant) do
        if candidate.action_status == "ambiguous_action" then
            return outcome("ambiguous_action", candidates, {
                causal_class = candidate.highest_class,
                ambiguous_target = candidate.to,
                ambiguity = candidate.action_error,
            })
        end
    end

    if #relevant > 1 then
        local ambiguity = outcome("ambiguous_pressure", candidates, {
            causal_class = relevant[1].highest_class,
            ambiguous_targets = (function()
                local targets = {}
                for _, candidate in ipairs(relevant) do
                    targets[#targets + 1] = candidate.to
                end
                return targets
            end)(),
        })
        if options.allow_control_fallback ~= true then
            return ambiguity
        end
        table.sort(relevant, function(left, right)
            return canonical_index[left.to] < canonical_index[right.to]
        end)
        local selected = relevant[1]
        return outcome("control_selected", candidates, {
            from = instance.operator,
            to = selected.to,
            selected_candidate = selected,
            original_outcome = ambiguity,
            selection_reason = "canonical_control_fallback",
        })
    end

    local selected = relevant[1]
    return {
        kind = "tree_route_decision",
        composition_outcome = "selected",
        policy = composition.policy,
        policy_status = composition.policy_status,
        from = instance.operator,
        to = selected.to,
        candidates = candidates,
        selected_candidate = selected,
        reason = "highest_causal_class_unique_executable_need",
        causal_class = selected.highest_class,
        promotion_eligible = selected.promotion_eligible == true,
        event_truth_status = "runtime_confirmed",
    }
end

function composition.predict(instance, snapshot, context)
    local candidates, candidate_err = composition.candidates(instance, snapshot, context)
    if not candidates then
        return nil, candidate_err
    end
    local options = context and context.composition or {}
    local result, result_err = composition.select(instance, candidates, options)
    if not result then
        return nil, result_err
    end
    result.from = snapshot.current_operator
    result.source_snapshot_ref = snapshot.trace_event_id or snapshot.id
    return result
end

composition.class_rank = copy_value(class_rank)

return composition
