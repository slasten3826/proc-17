package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local packet = require("core.packet")
local field = require("runtime.field")
local flow_domain = require("runtime.flow_domain")
local packet_birth = require("runtime.packet_birth")
local choice_inspection = require("runtime.choice_inspection")
local pressure_action = require("runtime.pressure_action")
local qualified_pressure = require("runtime.qualified_pressure")
local registry = require("runtime.operator_registry")
local tension_runner = require("runtime.tension_runner")
local flow = require("organs.flow")
local observe = require("organs.observe")
local choose = require("organs.choose")

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

local function contains_key(value, needle, seen)
    if type(value) ~= "table" then
        return false
    end
    seen = seen or {}
    if seen[value] then
        return false
    end
    seen[value] = true
    for key, child in pairs(value) do
        if key == needle or contains_key(child, needle, seen) then
            return true
        end
    end
    return false
end

local function proposal(shape, values)
    local items = {}
    for index, value in ipairs(values) do
        items[index] = {
            key = "alternative-" .. tostring(index),
            kind = "work_item",
            value = value,
            source_keys = {},
        }
    end
    local result = {
        protocol_version = "packet.structure.proposal.v0",
        receiver_contract_id = "calm.work_structure.v0",
        shape = shape,
        items = items,
        edges = {},
    }
    if shape == "alternative_set" then
        result.choice = {kind = "mutually_exclusive"}
    end
    return result
end

local function substrate_for(envelope)
    return {
        ask = function()
            return {text = json.encode(envelope)}
        end,
    }
end

local fixture_counter = 0
local function formed_packet(shape, values, configure)
    fixture_counter = fixture_counter + 1
    local domain = assert(flow_domain.new({1, 2, 3, 5, 8}, {
        stream_id = "choice-need-" .. tostring(fixture_counter),
        source_ref = "fixture:choice-need:" .. tostring(fixture_counter),
    }))
    local instance = assert(packet_birth.create(domain, "form exact alternatives", {
        projection_adapter = "vertical_single.v0",
    }))
    if configure then
        configure(instance)
    end
    assert(flow.run(instance))
    assert(packet.commit_transition(instance, {
        from = "▽", to = "☴", reason = "choice_source_observe",
        authority = "harness_override",
    }))
    assert(packet.begin_tick(instance, "☴", {}))
    local _, observed = assert(observe.run(
        instance,
        substrate_for(proposal(shape, values)),
        {work_mode = "plan"}
    ))
    local encoding = assert(qualified_pressure.structure_witnesses(instance, {
        current_operator = "☴",
    }))
    local encoding_witness = assert(encoding[1], "structure witness required")
    local context = assert(pressure_action.registry_context(
        encoding_witness.action_plan,
        {instance = instance, options = {work_mode = "plan"}}
    ))
    assert(packet.commit_transition(instance, {
        from = "☴", to = "☵", reason = "choice_structure_form",
        authority = "harness_override",
    }))
    assert(packet.begin_tick(instance, "☵", {}))
    local execution = assert(registry.execute("☵", instance, context))
    assert_eq(execution.status, "applied", "structure formation applies")
    return instance, execution.payload, observed
end

local function observe_formed(instance, payload)
    assert(packet.commit_transition(instance, {
        from = "☵", to = "☴", reason = "choice_field_observe",
        authority = "harness_override",
    }))
    assert(packet.begin_tick(instance, "☴", {}))
    assert(observe.run(instance, nil, {
        sensor = "field_native",
        unit_ids = payload.structure_formation.formed_unit_ids,
    }))
end

local function find_diagnostic(result, kind)
    for _, item in ipairs(result.diagnostics or {}) do
        if item.kind == kind then
            return item
        end
    end
    return nil
end

local function find_witness(result, kind)
    for _, item in ipairs(result.witnesses or result or {}) do
        if item.kind == kind then
            return item
        end
    end
    return nil
end

-- CN-0: unrelated units and non-alternative structures do not create choice.
local unrelated = packet.new("unrelated units")
assert(flow.run(unrelated))
local unrelated_choice = assert(choice_inspection.derive(unrelated))
assert_eq(#unrelated_choice.missing, 0, "unrelated field has no choice set")

local sequence, sequence_payload = formed_packet(
    "work_sequence",
    {"inspect", "implement"}
)
observe_formed(sequence, sequence_payload)
local sequence_choice = assert(choice_inspection.derive(sequence))
assert_eq(#sequence_choice.sets, 0, "work sequence is not an alternative set")

-- CN-1: formation alone is insufficient; exact consequence sight comes first.
local instance, formation = formed_packet(
    "alternative_set",
    {"use cache", "recompute"}
)
local unseen = assert(choice_inspection.derive(instance))
assert_eq(#unseen.missing, 0, "unobserved alternatives create no choice need")
assert_true(find_diagnostic(unseen, "choice_set_observation_missing") ~= nil,
    "missing field-native coverage is typed")
local unseen_witnesses = assert(qualified_pressure.choice_witnesses(instance, {
    current_operator = "☴",
}))
assert_eq(find_witness(unseen_witnesses, "choice_need"), nil,
    "unobserved set emits no action")

-- CN-2: observed alternatives yield one stable exact action with no winner.
observe_formed(instance, formation)
local trace_before = #instance.trace
local revision_before = instance.revisions.potential
local choice_state = assert(choice_inspection.derive(instance))
assert_eq(#choice_state.missing, 1, "two observed alternatives block singular focus")
local set = choice_state.missing[1]
assert_eq(set.choice_set_ref, formation.formation_event_id,
    "choice set is the immutable formation event")
assert_eq(set.alternative_ids[1], formation.structure_formation.formed_unit_ids[1],
    "frozen formation order is retained")
assert_eq(set.alternative_ids[2], formation.structure_formation.formed_unit_ids[2],
    "second alternative remains ordered")

local first = assert(qualified_pressure.choice_witnesses(instance, {
    current_operator = "☴",
}))
local second = assert(qualified_pressure.choice_witnesses(instance, {
    current_operator = "☴",
}))
local witness = assert(find_witness(first, "choice_need"),
    "observed set creates choice need")
local repeated = assert(find_witness(second, "choice_need"))
assert_eq(witness.witness_id, repeated.witness_id, "choice derivation is stable")
assert_eq(witness.action_plan.plan_id, repeated.action_plan.plan_id,
    "choice action identity is stable")
assert_eq(#instance.trace, trace_before, "choice inspection is trace-pure")
assert_eq(instance.revisions.potential, revision_before,
    "choice inspection is field-pure")
assert_eq(witness.causal_class, "blocking_demand", "choice is a blocked consumer")
assert_eq(witness.action_plan.mode, "alternative_collapse", "exact collapse mode")
assert_true(not contains_key(witness.action_plan, "selected_ids"),
    "pressure cannot preselect the winner")
assert_true(not contains_key(witness.action_plan, "chosen"),
    "pressure cannot smuggle a chosen alias")

local action_input = witness.action_plan.options.choose.choice_input
assert_eq(action_input.choice_set_ref, formation.formation_event_id,
    "action owns exact formation set")
assert_eq(action_input.max_selected, 1, "body owns collapse cardinality")
assert_eq(action_input.selection_policy_id, "formation_order.v0",
    "body owns selection policy")
assert_eq(#witness.scope_refs, 2, "action scope contains both exact operands")
assert(choice_inspection.resolve(instance, action_input))

local forged = copy_value(witness.action_plan)
forged.options.choose.choice_input.selected_ids = {set.alternative_ids[2]}
assert_true(not pressure_action.validate(forged),
    "winner injection invalidates the action")
local _, override_err = pressure_action.registry_context(witness.action_plan, {
    instance = instance,
    options = {choose = {semantic_ranking = {items = {}}}},
})
assert_eq(override_err, "caller options override action-owned scope",
    "caller cannot replace exact choice scope")

local second_plan = assert(pressure_action.build("alternative_collapse", {
    witness_id = "choice-witness:independent",
    target_operator = "☳",
    scope_refs = witness.scope_refs,
    provenance_refs = witness.provenance_refs,
    preconditions = witness.action_plan.preconditions,
    options = witness.action_plan.options,
    expected_effect = witness.action_plan.expected_effect,
    content_truth_status = witness.action_plan.content_truth_status,
}))
local merged, merge_err = pressure_action.merge(witness.action_plan, second_plan)
assert_true(not merged and merge_err == "ambiguous_action",
    "independent choice actions never merge in v0")

-- CN-3: unrelated material cannot alter the exact set or action identity.
local _, unrelated_event = assert(packet.append_chaos(instance, {
    operator = "☴", kind = "unrelated_choice_fixture",
    truth_status = "runtime_confirmed",
}))
assert(field.add_unit(instance, "☴", {
    kind = "unrelated_material",
    carrier = {value = "outside choice set"},
    source_refs = {formation.formation_event_id},
    created_event_id = unrelated_event.id,
    content_truth_status = "runtime_confirmed",
}))
local after_unrelated = assert(qualified_pressure.choice_witnesses(instance, {
    current_operator = "☴",
}))
assert_eq(assert(find_witness(after_unrelated, "choice_need")).action_plan.plan_id,
    witness.action_plan.plan_id, "unrelated unit does not re-arm or rewrite choice")

-- CN-4: exact version changes remove the old action until consequence sight.
assert(packet.commit_transition(instance, {
    from = "☴", to = "☳", reason = "choice_version_fixture",
    authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☳", {}))
local mutation_event = assert(packet.append_event(instance, {
    type = "choice",
    operator = "☳",
    truth_status = "runtime_confirmed",
    payload = {kind = "choice_version_fixture"},
    cost = {},
}))
local changed = assert(field.set_activation(
    instance,
    "☳",
    set.alternative_ids[1],
    "selected",
    {event_id = mutation_event.id, reason = "choice_version_fixture"}
))
assert_eq(changed.version, 2, "activation mutation advances exact version")
assert_true(not pressure_action.verify_preconditions(witness.action_plan, instance),
    "old action becomes stale immediately")
local stale = assert(choice_inspection.derive(instance))
assert_eq(#stale.missing, 0, "stale observed versions create no action")
assert_true(find_diagnostic(stale, "choice_set_observation_missing") ~= nil,
    "version delta requests fresh consequence sight")

assert(packet.commit_transition(instance, {
    from = "☳", to = "☴", reason = "choice_version_reobserve",
    authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☴", {}))
assert(observe.run(instance, nil, {
    sensor = "field_native",
    unit_ids = set.alternative_ids,
}))
local renewed = assert(qualified_pressure.choice_witnesses(instance, {
    current_operator = "☴",
}))
local renewed_witness = assert(find_witness(renewed, "choice_need"),
    "freshly observed version creates a new action")
assert_true(renewed_witness.action_plan.plan_id ~= witness.action_plan.plan_id,
    "new operand version changes action identity")
assert_eq(renewed_witness.action_plan.options.choose.choice_input
    .alternative_versions[set.alternative_ids[1]], 2,
    "renewed action names current selected version")
local renewed_context = assert(pressure_action.registry_context(
    renewed_witness.action_plan,
    {instance = instance, options = {}}
))
assert(packet.commit_transition(instance, {
    from = "☴", to = "☳", reason = "restamp_existing_selection",
    authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☳", {}))
local renewed_execution = assert(registry.execute("☳", instance, renewed_context))
assert_true(pressure_action.verify_effect(
    renewed_witness.action_plan,
    renewed_execution.payload,
    instance
), "already-selected operand is restamped by the exact choice event")
assert_eq(field.get_unit(instance, set.alternative_ids[1]).version, 3,
    "reselection advances the selected operand version")

-- CN-5: one alternative is confirmation and a disabled consumer is no pressure.
local single, single_payload = formed_packet("alternative_set", {"only option"})
observe_formed(single, single_payload)
local single_state = assert(choice_inspection.derive(single))
assert_eq(#single_state.missing, 0, "one alternative requires no collapse")
assert_eq(single_state.current[1].collapse_status, "confirmation",
    "single member is typed confirmation")
local single_witness = assert(qualified_pressure.choice_witnesses(single, {
    current_operator = "☴",
}))
assert_eq(find_witness(single_witness, "choice_need"), nil,
    "confirmation is not choice pressure")

local disabled, disabled_payload = formed_packet(
    "alternative_set",
    {"first", "second"}
)
observe_formed(disabled, disabled_payload)
disabled.regime.choice.consumer_contract_id = nil
local disabled_state = assert(choice_inspection.derive(disabled))
assert_eq(#disabled_state.missing, 0, "disabled consumer emits no action")
assert_true(find_diagnostic(disabled_state, "choice_consumer_not_enabled") ~= nil,
    "disabled consumer remains a typed diagnostic")

-- CN-6: a stale exact action is rejected before CHOOSE records a choice.
local stale_instance, stale_formation = formed_packet(
    "alternative_set",
    {"keep cache", "drop cache"}
)
observe_formed(stale_instance, stale_formation)
local stale_snapshot = assert(qualified_pressure.choice_witnesses(stale_instance, {
    current_operator = "☴",
}))
local stale_witness = assert(find_witness(stale_snapshot, "choice_need"))
assert(packet.commit_transition(stale_instance, {
    from = "☴", to = "☳", reason = "stale_choice_fixture",
    authority = "harness_override",
}))
assert(packet.begin_tick(stale_instance, "☳", {}))
local stale_event = assert(packet.append_event(stale_instance, {
    type = "choice",
    operator = "☳",
    truth_status = "runtime_confirmed",
    payload = {kind = "fixture_activation"},
    cost = {},
}))
assert(field.set_activation(
    stale_instance,
    "☳",
    stale_formation.structure_formation.formed_unit_ids[1],
    "selected",
    {event_id = stale_event.id, reason = "stale_choice_fixture"}
))
local stale_readiness = assert(choose.readiness(
    stale_instance,
    stale_witness.action_plan.options.choose
))
assert_true(stale_readiness.ready == false, "stale operand is not executable")
assert_eq(#(stale_instance.boundary.choices or {}), 0,
    "stale readiness cannot record a boundary choice")

-- CN-7/CN-10/CN-11: exact execution partitions the set and discharges it.
local collapsed, collapse_formation = formed_packet(
    "alternative_set",
    {"retain source", "replace source"}
)
observe_formed(collapsed, collapse_formation)
local collapse_snapshot = assert(qualified_pressure.choice_witnesses(collapsed, {
    current_operator = "☴",
}))
local collapse_witness = assert(find_witness(collapse_snapshot, "choice_need"))
local collapse_context = assert(pressure_action.registry_context(
    collapse_witness.action_plan,
    {instance = collapsed, options = {work_mode = "plan"}}
))
assert(packet.commit_transition(collapsed, {
    from = "☴", to = "☳", reason = "qualified_alternative_collapse",
    authority = "harness_override",
}))
assert(packet.begin_tick(collapsed, "☳", {}))
local collapse_execution = assert(registry.execute("☳", collapsed, collapse_context))
assert_eq(collapse_execution.status, "applied", "qualified CHOOSE applies")
assert_eq(collapse_execution.readiness.reason, "alternative_collapse_ready",
    "readiness resolves the exact declared set")
local collapse_payload = collapse_execution.payload
assert_eq(collapse_payload.mode, "alternative_collapse", "production mode is exact")
assert_eq(collapse_payload.selected_ids[1],
    collapse_formation.structure_formation.formed_unit_ids[1],
    "the organ selects first frozen formation member")
assert_eq(collapse_payload.suppressed_ids[1],
    collapse_formation.structure_formation.formed_unit_ids[2],
    "the organ suppresses the remaining member")
assert_eq(collapse_payload.before_count, 2, "collapse records full operand count")
assert_eq(collapse_payload.after_count, 1, "collapse leaves singular focus")
assert_eq(collapse_payload.loss.calculation_status, "provisional_count_proxy",
    "choice loss remains an explicit provisional proxy")
assert_eq(collapse_payload.loss.amount, 0.5, "two-way collapse pays one half")
assert_true(pressure_action.verify_effect(
    collapse_witness.action_plan,
    collapse_payload,
    collapsed
), "exact collapse effect resolves")

for index, id in ipairs(collapse_formation.structure_formation.formed_unit_ids) do
    local unit = assert(field.get_unit(collapsed, id))
    assert_eq(unit.activation, index == 1 and "selected" or "suppressed",
        "each exact operand receives its collapse activation")
    assert_eq(unit.version, 2, "each exact operand advances exactly one version")
    assert_eq(unit.activation_source.event_id, collapse_payload.trace_event_id,
        "all activation effects name the same choice event")
end

local forged_effect = copy_value(collapse_payload)
forged_effect.suppressed_ids = {}
assert_true(not pressure_action.verify_effect(
    collapse_witness.action_plan,
    forged_effect,
    collapsed
), "missing suppression effect is rejected")
local missing_post_version = copy_value(collapse_payload)
missing_post_version.post_versions[
    collapse_formation.structure_formation.formed_unit_ids[2]
] = nil
assert_true(not pressure_action.verify_effect(
    collapse_witness.action_plan,
    missing_post_version,
    collapsed
), "missing post version is rejected")

local just_collapsed = assert(choice_inspection.derive(collapsed))
assert_eq(#just_collapsed.missing, 0, "collapse immediately removes choice pressure")
assert_true(find_diagnostic(just_collapsed, "choice_set_observation_missing") ~= nil,
    "changed selected version still requests consequence sight")
assert(packet.commit_transition(collapsed, {
    from = "☳", to = "☴", reason = "observe_choice_effect",
    authority = "harness_override",
}))
assert(packet.begin_tick(collapsed, "☴", {}))
assert(observe.run(collapsed, nil, {
    sensor = "field_native",
    unit_ids = {collapse_payload.selected_ids[1]},
}))
local confirmed = assert(choice_inspection.derive(collapsed))
assert_eq(#confirmed.missing, 0, "observed collapse stays discharged")
assert_eq(confirmed.current[1].collapse_status, "confirmation",
    "one surviving eligible member is confirmation")

local _, unrelated_after_event = assert(packet.append_chaos(collapsed, {
    operator = "☴",
    kind = "unrelated_after_choice",
    truth_status = "runtime_confirmed",
}))
assert(field.add_unit(collapsed, "☴", {
    kind = "unrelated_after_choice",
    carrier = {value = "not a member"},
    source_refs = {collapse_payload.trace_event_id},
    created_event_id = unrelated_after_event.id,
    content_truth_status = "runtime_confirmed",
}))
local after_noise = assert(choice_inspection.derive(collapsed))
assert_eq(#after_noise.missing, 0, "unrelated material cannot re-arm choice")
assert_eq(after_noise.current[1].collapse_status, "confirmation",
    "unrelated material cannot join the declared set")

-- CN-12: a new exact formation creates a new set without reviving the old one.
assert(observe.run(
    collapsed,
    substrate_for(proposal("alternative_set", {"new left", "new right"})),
    {work_mode = "plan"}
))
local new_structure = assert(qualified_pressure.structure_witnesses(collapsed, {
    current_operator = "☴",
}))
local new_structure_witness = assert(find_witness(new_structure, "encoding_need"),
    "new strict source creates a new structure action")
local new_structure_context = assert(pressure_action.registry_context(
    new_structure_witness.action_plan,
    {instance = collapsed, options = {work_mode = "plan"}}
))
assert(packet.commit_transition(collapsed, {
    from = "☴", to = "☵", reason = "new_choice_formation",
    authority = "harness_override",
}))
assert(packet.begin_tick(collapsed, "☵", {}))
local new_formation_execution = assert(registry.execute(
    "☵",
    collapsed,
    new_structure_context
))
assert(packet.commit_transition(collapsed, {
    from = "☵", to = "☴", reason = "observe_new_choice_formation",
    authority = "harness_override",
}))
assert(packet.begin_tick(collapsed, "☴", {}))
assert(observe.run(collapsed, nil, {
    sensor = "field_native",
    unit_ids = new_formation_execution.payload.structure_formation.formed_unit_ids,
}))
local rearmed = assert(qualified_pressure.choice_witnesses(collapsed, {
    current_operator = "☴",
}))
local rearmed_witness = assert(find_witness(rearmed, "choice_need"),
    "new observed formation creates fresh choice pressure")
assert_eq(rearmed_witness.choice_set_ref,
    new_formation_execution.payload.formation_event_id,
    "fresh pressure names only the new formation")
assert_true(rearmed_witness.choice_set_ref ~= collapse_payload.choice_set_ref,
    "old collapsed set remains historical")

-- CN-8: detail sampling is bounded without hiding the complete suppression.
local sampled, sampled_formation = formed_packet(
    "alternative_set",
    {"one", "two", "three", "four"},
    function(packet_instance)
        packet_instance.regime.choice.bounds.max_killed_sample = 1
    end
)
observe_formed(sampled, sampled_formation)
local sampled_snapshot = assert(qualified_pressure.choice_witnesses(sampled, {
    current_operator = "☴",
}))
local sampled_witness = assert(find_witness(sampled_snapshot, "choice_need"))
local sampled_context = assert(pressure_action.registry_context(
    sampled_witness.action_plan,
    {instance = sampled, options = {}}
))
assert(packet.commit_transition(sampled, {
    from = "☴", to = "☳", reason = "sampled_alternative_collapse",
    authority = "harness_override",
}))
assert(packet.begin_tick(sampled, "☳", {}))
local sampled_execution = assert(registry.execute("☳", sampled, sampled_context))
local sampled_payload = sampled_execution.payload
assert_eq(#sampled_payload.suppressed_ids, 3, "full suppressed identity survives")
assert_eq(sampled_payload.not_chosen_count, 3, "full suppression count survives")
assert_eq(#sampled_payload.killed_alternatives, 1, "killed detail obeys bound")
assert_true(sampled_payload.loss.truncated, "sample truncation is explicit")
assert_eq(sampled_payload.loss.amount, 0.75, "loss uses the full suppression count")
assert_true(pressure_action.verify_effect(
    sampled_witness.action_plan,
    sampled_payload,
    sampled
), "sampled effect remains exact")

-- Treatment trace: tree authority carries exact ☳ action and observes its effects.
local tree_domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
    stream_id = "choice-collapse-tree",
    source_ref = "fixture:choice-collapse-tree",
}))
local tree_packet, tree_result = assert(tension_runner.run(
    "choose one exact alternative",
    substrate_for(proposal("alternative_set", {"left", "right"})),
    {
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        ablate_relation_consumer = true,
        work_mode = "plan",
        max_ticks = 5,
        legacy_shadow = false,
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = tree_domain,
            projection_adapter = "vertical_single.v0",
        },
    }
))
local expected_tree = {"☴", "☵", "☴", "☳", "☴"}
for index, operator in ipairs(expected_tree) do
    assert_eq(tree_result.ticks[index].operator, operator,
        "tree treatment follows qualified pair at tick " .. tostring(index))
end
assert_eq(tree_result.ticks[4].payload.mode, "alternative_collapse",
    "tree carries exact action into CHOOSE")
assert_eq(tree_result.ticks[5].payload.sensor, "field_native",
    "choice consequences require body-native sight")
assert_true(tree_packet.tension.loss >= 0.9,
    "tree physics charges both structure and choice identity loss")

print("test_choice_need ok")
