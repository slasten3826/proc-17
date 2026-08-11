package.path = "./?.lua;./?/init.lua;" .. package.path

local authority_epoch = require("runtime.authority_epoch")
local edge_catalog = require("runtime.edge_catalog")
local edge_credit = require("runtime.edge_credit")
local edge_stats = require("runtime.edge_stats")
local json = require("core.json")
local packet = require("core.packet")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function assert_same(left, right, message)
    assert_eq(json.encode(left), json.encode(right), message)
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

local function resolve_epoch(bounds)
    local record, err = authority_epoch.resolve({
        router_mode = "tree",
        legacy_shadow = false,
        pressure_policy = "qualified_need_v0",
        authority_instrument_bounds = bounds,
    })
    assert_true(record ~= nil, err and err.code or err)
    return record
end

local default_epoch = resolve_epoch()

local function new_life(label, epoch_record)
    local life, life_err = edge_stats.make_life_source({
        packet_id = "packet:" .. label,
        lineage_id = "lineage:" .. label,
        generation = 1,
        session_id = "session:" .. label,
        work_mode = "build",
        case_id = "case:" .. label,
        corpus_layer = "unit",
        evidence_run_id = "run:" .. label,
        model = "fixture",
        prompt_hash = "sha256:"
            .. string.rep(string.format("%x", (#label % 15) + 1), 64),
    })
    assert_true(life ~= nil, life_err and life_err.code or life_err)
    local ledger, ledger_err = edge_stats.new(epoch_record, life)
    assert_true(ledger ~= nil, ledger_err and ledger_err.code or ledger_err)
    local credit, credit_err = edge_credit.new(epoch_record, {
        life_id = life.life_id,
        packet_id = life.packet_id,
        lineage_id = life.lineage_id,
        generation = life.generation,
    })
    assert_true(credit ~= nil, credit_err and credit_err.code or credit_err)
    return life, ledger, credit
end

local function eligibility()
    return {
        promotion_eligible = true,
        promotion_ineligibility_reasons = {},
        promotion_eligibility_basis = {
            witness_ids = {"witness:qualified"},
            unqualified_snapshot = false,
            fixture_witness_ids = {},
        },
    }
end

local function install_eligibility(target, value)
    target.promotion_eligible = value.promotion_eligible
    target.promotion_ineligibility_reasons = copy_value(
        value.promotion_ineligibility_reasons
    )
    target.promotion_eligibility_basis = copy_value(
        value.promotion_eligibility_basis
    )
    return target
end

local function route(label, ordinal, from, to)
    from = from or "☵"
    to = to or "☴"
    local triple = eligibility()
    local pressure_ref = "pressure:" .. label
    local derivation_ref = "derivation:" .. label
    local action_plan_id = "action:" .. label
    local candidate = install_eligibility({
        to = to,
        readiness = {ready = true},
        action_plan = {plan_id = action_plan_id},
        contributions = {
            {
                kind = "upper_observation_debt",
                direction = "help",
            },
        },
    }, triple)
    local decision = install_eligibility({
        kind = "tree_route_decision",
        from = from,
        to = to,
        reason = "qualified_test_route",
        authority = "tree",
        derivation_ref = derivation_ref,
        pressure_snapshot_ref = pressure_ref,
        selected_action_plan_id = action_plan_id,
        selected_candidate = copy_value(candidate),
        candidates = {copy_value(candidate)},
        truth_status = "runtime_confirmed",
    }, triple)
    local derivation_event = {
        id = derivation_ref,
        type = "route_derivation",
        operator = from,
        truth_status = "runtime_confirmed",
        payload = install_eligibility({
            kind = "route_derivation",
            current_operator = from,
            selected_to = to,
            outcome = "selected",
            pressure_snapshot_ref = pressure_ref,
            selected_action_plan_id = action_plan_id,
            selected_candidate = copy_value(candidate),
            candidates = {copy_value(candidate)},
        }, triple),
    }
    local route_event = {
        id = "route:" .. label,
        type = "route",
        operator = to,
        truth_status = "runtime_confirmed",
        payload = install_eligibility({
            kind = "tree_route_decision",
            from = from,
            to = to,
            authority = "tree",
            derivation_ref = derivation_ref,
            pressure_snapshot_ref = pressure_ref,
            selected_action_plan_id = action_plan_id,
        }, triple),
    }
    return {
        ordinal = ordinal,
        decision = decision,
        derivation_event = derivation_event,
        route_event = route_event,
        pressure_event = {
            id = pressure_ref,
            type = "pressure_snapshot",
            truth_status = "runtime_confirmed",
            payload = {current_operator = from},
        },
    }
end

local function grow_selection(credit_state, route_value)
    local selection, selection_err = edge_credit.prepare(
        credit_state,
        route_value.decision,
        {
            route_ordinal = route_value.ordinal,
            derivation_event = route_value.derivation_event,
        }
    )
    assert_true(selection ~= nil, selection_err and selection_err.code)
    return selection
end

local function grow_commit(credit_state, selection, route_value)
    local commit, taint, commit_err = edge_credit.record_commit(
        credit_state,
        selection,
        route_value.route_event
    )
    assert_true(commit ~= nil, commit_err and commit_err.code)
    assert_eq(taint, nil, "qualified Tree commit remains untainted")
    return commit
end

local function source(kind, original_id, record)
    return {
        source_kind = kind,
        original_source_id = original_id,
        source_record = record,
    }
end

local function bundle(life, records)
    return {
        life_id = life.life_id,
        records = records or {},
    }
end

local function direction(ledger, from, to)
    local definition = assert(edge_catalog.get(from, to))
    return assert(ledger.edges[definition.edge].directions[from .. "->" .. to])
end

local function source_count(ledger)
    return ledger.source_usage.record_count
end

local function error_code_present(ledger, code)
    for _, err in ipairs(ledger.errors or {}) do
        if err.code == code then
            return true
        end
    end
    return false
end

-- Physical happy path: candidate, selection, commit and arrival are four
-- independent facts. After I05, promotion reads the same immutable chain but
-- remains a separate channel.
local life, ledger, credit_state = new_life("physical", default_epoch)
local physical_route = route("physical", 1)
local derivation_ok, derivation_err = edge_stats.record_tree_derivation(
    ledger,
    physical_route.decision,
    bundle(life, {
    source("packet_trace", physical_route.derivation_event.id,
        physical_route.derivation_event),
    source("policy_evidence", physical_route.pressure_event.id,
        physical_route.pressure_event),
    })
)
assert_true(derivation_ok, derivation_err and derivation_err.code)
local physical_direction = direction(ledger, "☵", "☴")
assert_eq(physical_direction.physical.candidate_count, 1,
    "derivation owns candidate count")
assert_eq(physical_direction.physical.selected_count, 0,
    "derivation cannot invent selection")
assert_eq(ledger.rails["rail.encode_observe"].channels.tree_authority.cases, 1,
    "authoritative derivation retains rail role")

local selection = grow_selection(credit_state, physical_route)
local repeated_pressure = source(
    "policy_evidence",
    physical_route.pressure_event.id,
    physical_route.pressure_event
)
assert(edge_stats.record_selection(ledger, selection, bundle(life, {
    repeated_pressure,
})))
physical_direction = direction(ledger, "☵", "☴")
assert_eq(physical_direction.physical.selected_count, 1,
    "selection owns selected count")
local count_after_selection = source_count(ledger)

local commit = grow_commit(credit_state, selection, physical_route)
assert(edge_stats.record_transition(ledger, commit, bundle(life, {
    repeated_pressure,
    source("packet_trace", physical_route.route_event.id,
        physical_route.route_event),
})))
assert_eq(source_count(ledger), count_after_selection + 2,
    "SE02 exact source replay reuses one record while new commit and route enter")
physical_direction = direction(ledger, "☵", "☴")
assert_eq(physical_direction.physical.committed_count, 1,
    "commit owns committed count")

local arrival, credit_decision = assert(edge_credit.record_arrival(
    credit_state,
    commit,
    {
        destination_tick_ref = "tick:physical",
        effect_refs = {"effect:physical"},
        payload_kind = "repository_effect",
    }
))
local tick_source = {
    id = "tick:physical",
    kind = "runner_tick",
    event_truth_status = "runtime_confirmed",
}
local effect_source = {
    id = "effect:physical",
    kind = "repository_effect",
    event_truth_status = "runtime_confirmed",
}
assert(edge_stats.record_arrival(ledger, arrival, credit_decision, bundle(life, {
    source("runner_tick", tick_source.id, tick_source),
    source("runner_effect", effect_source.id, effect_source),
})))
physical_direction = direction(ledger, "☵", "☴")
assert_eq(physical_direction.physical.executed_count, 1,
    "arrival owns executed count")
assert_eq(physical_direction.promotion.eligible_executed_count, 1,
    "I05 promotion consumes only the final credited arrival")
assert_eq(ledger.routes[selection.route_evidence_id].phase_status, "executed",
    "route index reaches executed")
assert_true(edge_stats.verify(ledger), "physical ledger verifies")

-- Detached credit records keep their original minting contract. A caller may
-- not alter eligibility metadata and obtain a fresh source wrapper around it.
local forged_life, forged_ledger, forged_credit = new_life(
    "forged-credit", default_epoch
)
local forged_route = route("forged-credit", 1)
local forged_selection = grow_selection(forged_credit, forged_route)
forged_selection.classification_error_codes = {"invented_reason"}
local forged_before = assert(edge_stats.summary(forged_ledger))
local forged_ok, forged_err = edge_stats.record_selection(
    forged_ledger,
    forged_selection,
    bundle(forged_life)
)
assert_eq(forged_ok, nil, "forged edge-credit record is rejected")
assert_eq(forged_err.code, "edge_credit_source_invalid",
    "minting module owns detached record verification")
assert_same(assert(edge_stats.summary(forged_ledger)), forged_before,
    "forged credit source is transactionally inert")

-- SE01/SE05: source owners can disappear or mutate after capture; the ledger
-- retains one detached, digest-bound record.
local stored_effect_ref = ledger.source_index[life.life_id]
    .runner_effect[effect_source.id]
effect_source.kind = "caller_mutated"
tick_source = nil
collectgarbage("collect")
assert_eq(ledger.evidence_records[stored_effect_ref].source_record.kind,
    "repository_effect", "SE05 caller mutation cannot rewrite source")
assert_true(edge_stats.verify(ledger),
    "SE01 ledger remains self-contained after source discard")

-- Failure and host-ceiling pending never enter executed.
local failure_life, failure_ledger, failure_credit = new_life(
    "failure", default_epoch
)
local failure_route = route("failure", 1)
local failure_selection = grow_selection(failure_credit, failure_route)
assert(edge_stats.record_selection(failure_ledger, failure_selection,
    bundle(failure_life)))
local failure_commit = grow_commit(failure_credit, failure_selection, failure_route)
assert(edge_stats.record_transition(failure_ledger, failure_commit,
    bundle(failure_life)))
local failure_record = assert(edge_credit.record_failure(
    failure_credit,
    failure_commit,
    {
        destination_tick_ref = "tick:failure",
        failure_ref = "failure:typed",
        failure_kind = "typed_effect_failure",
    }
))
assert(edge_stats.record_failure(failure_ledger, failure_record,
    bundle(failure_life, {
        source("runner_tick", "tick:failure", {
            id = "tick:failure",
            kind = "runner_tick",
            event_truth_status = "runtime_confirmed",
        }),
        source("runner_effect", "failure:typed", {
            id = "failure:typed",
            kind = "typed_effect_failure",
            event_truth_status = "runtime_confirmed",
        }),
    })))
local failed_direction = direction(failure_ledger, "☵", "☴")
assert_eq(failed_direction.physical.failed_count, 1, "failure is physical")
assert_eq(failed_direction.physical.executed_count, 0,
    "failure is not execution")

local pending_life, pending_ledger, pending_credit = new_life(
    "pending", default_epoch
)
local pending_route = route("pending", 1)
local pending_selection = grow_selection(pending_credit, pending_route)
assert(edge_stats.record_selection(pending_ledger, pending_selection,
    bundle(pending_life)))
local pending_commit = grow_commit(pending_credit, pending_selection, pending_route)
assert(edge_stats.record_transition(pending_ledger, pending_commit,
    bundle(pending_life)))
local pending_record = assert(edge_credit.record_pending(
    pending_credit,
    pending_commit,
    {stop_reason = "tick_limit"}
))
assert(edge_stats.record_pending(pending_ledger, pending_record))
local pending_direction = direction(pending_ledger, "☵", "☴")
assert_eq(pending_direction.physical.pending_at_host_ceiling_count, 1,
    "host ceiling is preserved")
assert_eq(pending_direction.physical.executed_count, 0,
    "pending is not execution")

-- Existing observer/rail roles remain counterfactual and massless: observer
-- candidates never enter the physical candidate channel.
local observer_life, observer_ledger = new_life("observer", default_epoch)
local shadow = {
    kind = "shadow_route_decision",
    observer = "tree",
    live_authority = "legacy_control",
    current_operator = "☵",
    candidates = physical_route.decision.candidates,
    predicted_to = "☴",
    live_to = "☳",
    agreement = false,
    prediction_outcome = "selected",
    instrumentation_status = "available",
}
local observer_source = {
    id = "observer:physical",
    kind = "shadow_route_decision",
    event_truth_status = "runtime_confirmed",
    payload = copy_value(shadow),
}
assert(edge_stats.record_observer(observer_ledger, shadow,
    bundle(observer_life, {
        source("observer", observer_source.id, observer_source),
    })))
assert_eq(observer_ledger.observers.tree.comparison_count, 1,
    "observer role retained")
assert_eq(observer_ledger.rails["rail.encode_observe"]
    .channels.tree_shadow.cases, 1, "shadow rail role retained")
assert_eq(direction(observer_ledger, "☵", "☴").physical.candidate_count, 0,
    "observer prediction has no physical mass")

-- SE03: one original id cannot acquire a changed payload. The whole observer
-- transaction, including its counters, must remain unchanged.
local observer_before = assert(edge_stats.summary(observer_ledger))
observer_source.payload.live_to = "☱"
local conflict_ok, conflict_err = edge_stats.record_observer(
    observer_ledger,
    shadow,
    bundle(observer_life, {
        source("observer", observer_source.id, observer_source),
    })
)
assert_eq(conflict_ok, nil, "SE03 conflicting source rejected")
assert_eq(conflict_err.code, "source_evidence_conflict",
    "SE03 names source conflict")
assert_same(assert(edge_stats.summary(observer_ledger)), observer_before,
    "SE03 rejected transaction is inert")

-- SE04: the transport accepts only finite plain data, never live authority.
local hostile_records = {
    {label = "function", value = {value = function() end}},
    {label = "userdata", value = {value = io.stdout}},
    {label = "thread", value = {value = coroutine.create(function() end)}},
    {label = "metatable", value = setmetatable({value = 1}, {})},
    {label = "packet", value = packet.new("live source object")},
}
for index, hostile in ipairs(hostile_records) do
    local hostile_before = assert(edge_stats.summary(observer_ledger))
    local hostile_ok, hostile_err = edge_stats.record_observer(
        observer_ledger,
        shadow,
        bundle(observer_life, {
            source("observer", "hostile:" .. tostring(index), hostile.value),
        })
    )
    assert_eq(hostile_ok, nil, "SE04 rejects " .. hostile.label)
    assert_eq(hostile_err.code, "source_evidence_not_plain",
        "SE04 types " .. hostile.label)
    assert_same(assert(edge_stats.summary(observer_ledger)), hostile_before,
        "SE04 leaves ledger unchanged for " .. hostile.label)
end

local function bounded_selection(label, bounds)
    local bounded_epoch = resolve_epoch(bounds)
    local bounded_life, bounded_ledger, bounded_credit = new_life(
        label,
        bounded_epoch
    )
    local bounded_route = route(label, 1)
    local bounded_record = grow_selection(bounded_credit, bounded_route)
    assert(edge_stats.record_selection(
        bounded_ledger,
        bounded_record,
        bundle(bounded_life)
    ))
    local bounded_direction = direction(bounded_ledger, "☵", "☴")
    assert_eq(bounded_direction.physical.selected_count, 1,
        "SE09 physical selection survives " .. label)
    assert_eq(bounded_ledger.ledger_status, "invalid",
        "SE09 bound invalidates ledger " .. label)
    assert_true(bounded_ledger.source_usage.omitted_record_count > 0,
        "SE09 records omitted source " .. label)
    assert_true(error_code_present(
        bounded_ledger,
        "instrument_source_bound_exceeded"
    ) or bounded_ledger.error_overflow ~= nil,
        "SE09 records bounded error " .. label)
    local bounded_commit = grow_commit(
        bounded_credit,
        bounded_record,
        bounded_route
    )
    assert(edge_stats.record_transition(
        bounded_ledger,
        bounded_commit,
        bundle(bounded_life)
    ))
    bounded_direction = direction(bounded_ledger, "☵", "☴")
    assert_eq(bounded_direction.physical.committed_count, 1,
        "SE09 omitted selection source cannot erase later commit " .. label)
    assert_true(edge_stats.verify(bounded_ledger),
        "SE09 invalid physical ledger still verifies " .. label)
end

-- SE09: every independent source bound keeps the phase visible and blocks
-- promotion by invalidating only the instrument ledger.
bounded_selection("count-bound", {
    max_source_records = 1,
    max_single_source_bytes = 1024 * 1024,
    max_source_bytes_per_life = 1024 * 1024,
    max_projection_bytes = 1024 * 1024,
    max_error_records = 8,
})
bounded_selection("single-bound", {
    max_source_records = 32,
    max_single_source_bytes = 32,
    max_source_bytes_per_life = 1024 * 1024,
    max_projection_bytes = 1024 * 1024,
    max_error_records = 8,
})
bounded_selection("aggregate-bound", {
    max_source_records = 32,
    max_single_source_bytes = 1024 * 1024,
    max_source_bytes_per_life = 64,
    max_projection_bytes = 1024 * 1024,
    max_error_records = 8,
})

print("test_edge_stats_v3 ok")
