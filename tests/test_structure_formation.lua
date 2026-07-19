package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local packet = require("core.packet")
local field = require("runtime.field")
local flow_domain = require("runtime.flow_domain")
local pressure_action = require("runtime.pressure_action")
local qualified_pressure = require("runtime.qualified_pressure")
local structure_inspection = require("runtime.structure_inspection")
local tension_runner = require("runtime.tension_runner")
local registry = require("runtime.operator_registry")
local encode = require("organs.encode")
local flow = require("organs.flow")
local observe = require("organs.observe")

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

local function proposal(shape, values)
    local items = {}
    for index, value in ipairs(values or {"inspect", "implement"}) do
        items[index] = {
            key = "item-" .. tostring(index),
            kind = "work_item",
            value = value,
            source_keys = {},
        }
    end
    local result = {
        protocol_version = structure_inspection.proposal_protocol,
        receiver_contract_id = structure_inspection.receiver_contract_id,
        shape = shape or "work_sequence",
        items = items,
        edges = {},
    }
    if result.shape == "alternative_set" then
        result.choice = {kind = "mutually_exclusive"}
    end
    return result
end

local function substrate_with_text(text)
    return {
        ask = function()
            return {text = text}
        end,
    }
end

local function observed_packet(text)
    local instance = packet.new("structure formation fixture")
    assert(flow.run(instance))
    assert(packet.commit_transition(instance, {
        from = "▽",
        to = "☴",
        reason = "structure_fixture_observe",
        authority = "harness_override",
    }))
    assert(packet.begin_tick(instance, "☴", {}))
    local _, payload = assert(observe.run(
        instance,
        substrate_with_text(text),
        {work_mode = "plan"}
    ))
    return instance, payload
end

local function find_witness(values, kind)
    for _, witness in ipairs(values.witnesses or values or {}) do
        if witness.kind == kind then
            return witness
        end
    end
    return nil
end

local function has_diagnostic(values, kind)
    for _, diagnostic in ipairs(values.diagnostics or values.unqualified or {}) do
        if diagnostic.kind == kind then
            return true
        end
    end
    return false
end

-- SF-0: the strict adapter does not reinterpret prose or unknown envelope keys.
local normalized = assert(structure_inspection.normalize(proposal("work_sequence")))
assert_eq(normalized.shape, "work_sequence", "strict proposal normalizes")
local prose, prose_err = structure_inspection.from_unit({
    kind = "substrate_response",
    carrier = {text = "ordinary prose"},
})
assert_true(not prose and prose_err == "structure proposal text is not strict JSON",
    "ordinary prose is not silently structured")
local unknown_envelope = proposal("work_sequence")
unknown_envelope.suggestion = "invented body authority"
assert_true(not structure_inspection.normalize(unknown_envelope),
    "unknown envelope keys are rejected")

-- SF-1: semantically observed prose is diagnostic, never encoding pressure.
local prose_packet = observed_packet("ordinary prose")
local prose_inspection = assert(structure_inspection.derive(prose_packet))
assert_true(has_diagnostic(prose_inspection, "unsupported_structure_proposal"),
    "prose leaves a typed unsupported diagnostic")
assert_eq(#prose_inspection.missing, 0, "prose creates no structure candidate")
local prose_pressure = assert(qualified_pressure.structure_witnesses(prose_packet, {
    current_operator = "☴",
}))
assert_eq(find_witness(prose_pressure, "encoding_need"), nil,
    "prose creates no encoding witness")

-- SF-2: a strict but unobserved source remains upper observation debt.
local unobserved = packet.new("unobserved structure")
assert(flow.run(unobserved))
assert(packet.commit_transition(unobserved, {
    from = "▽", to = "☴", reason = "unobserved_fixture",
    authority = "harness_override",
}))
assert(packet.begin_tick(unobserved, "☴", {}))
local _, source_event = assert(packet.append_chaos(unobserved, {
    operator = "☴",
    kind = "unobserved_structure_fixture",
    truth_status = "semantic_proposal",
}))
local unobserved_unit = assert(field.add_unit(unobserved, "☴", {
    kind = "substrate_response",
    carrier = {text = json.encode(proposal("work_sequence"))},
    source_refs = {"unit:1"},
    created_event_id = source_event.id,
    content_truth_status = "semantic_proposal",
}))
local unobserved_snapshot = assert(qualified_pressure.derive(unobserved, nil, {
    current_operator = "☵",
}))
assert_eq(find_witness(unobserved_snapshot, "encoding_need"), nil,
    "unobserved proposal cannot create encoding pressure")
assert_true(find_witness(unobserved_snapshot, "upper_observation_need") ~= nil,
    "unobserved proposal remains an upper observation need")
assert_true(has_diagnostic(unobserved_snapshot, "source_semantic_observation_missing"),
    "missing semantic coverage remains explicit")
assert_eq(unobserved_unit.version, 1, "unobserved fixture names an exact source")

-- SF-3: one observed envelope creates a stable exact, action-owned witness.
local envelope = proposal("alternative_set", {"use cache", "recompute"})
local instance, observed = observed_packet(json.encode(envelope))
local trace_before = #instance.trace
local revision_before = instance.revisions.potential
local first = assert(qualified_pressure.structure_witnesses(instance, {
    current_operator = "☴",
}))
local second = assert(qualified_pressure.structure_witnesses(instance, {
    current_operator = "☴",
}))
local witness = assert(find_witness(first, "encoding_need"),
    "observed strict proposal creates encoding need")
local repeated = assert(find_witness(second, "encoding_need"))
assert_eq(witness.witness_id, repeated.witness_id, "pure derivation is stable")
assert_eq(witness.action_plan.plan_id, repeated.action_plan.plan_id,
    "exact action identity is stable")
assert_eq(#instance.trace, trace_before, "inspection does not append trace")
assert_eq(instance.revisions.potential, revision_before,
    "inspection does not mutate field")
assert_eq(witness.scope_refs[1], "coverage:field_unit:"
    .. observed.field_unit_id .. ":1", "witness pins exact observed version")
assert_eq(witness.action_plan.mode, "structure_formation", "exact action mode")
assert_eq(witness.action_plan.options.encode.structure_input.requested_shape,
    "alternative_set", "action owns requested shape")

local mismatched_plan = copy_value(witness.action_plan)
mismatched_plan.scope_refs = {"coverage:field_unit:" .. observed.field_unit_id .. ":2"}
assert_true(not pressure_action.validate(mismatched_plan),
    "source/scope mismatch is rejected")
local _, override_err = pressure_action.registry_context(witness.action_plan, {
    instance = instance,
    options = {encode = {limits = {max_items = 2}}},
})
assert_eq(override_err, "caller options override action-owned scope",
    "caller cannot replace qualified structure scope")

-- SF-4: receiver policy may disable consumption without changing the proposal.
local disabled = observed_packet(json.encode(proposal("work_sequence")))
disabled.regime.encoding.receiver_contract_id = nil
local disabled_result = assert(structure_inspection.derive(disabled))
assert_true(has_diagnostic(disabled_result, "receiver_not_enabled"),
    "disabled receiver remains visible")
assert_eq(#disabled_result.missing, 0, "disabled receiver creates no action")

-- SF-5: a compatibility shadow map is not an exact formation proof.
local shadow = observed_packet(json.encode(proposal("work_sequence")))
local shadow_source = assert(structure_inspection.derive(shadow)).missing[1].source_unit_id
assert(packet.commit_transition(shadow, {
    from = "☴", to = "☵", reason = "compatibility_shadow_map",
    authority = "harness_override",
}))
assert(packet.begin_tick(shadow, "☵", {}))
local _, shadow_payload = assert(encode.run(shadow, {}))
assert_true(shadow_payload.field_shadow.shadow_only,
    "compatibility ENCODE remains shadow-only")
local shadow_names_source = false
for _, old_id in ipairs(shadow.field.identity_maps[1].old_ids) do
    shadow_names_source = shadow_names_source or old_id == shadow_source
end
assert_true(shadow_names_source, "control shadow map names the proposal source")
local shadow_need = assert(qualified_pressure.structure_witnesses(shadow, {
    current_operator = "☴",
}))
assert_true(find_witness(shadow_need, "encoding_need") ~= nil,
    "shadow map cannot discharge exact structure need")

-- SF-6: the action reaches ☵ without caller scope and writes one composite proof.
local context = assert(pressure_action.registry_context(witness.action_plan, {
    instance = instance,
    options = {work_mode = "build"},
}))
assert(packet.commit_transition(instance, {
    from = "☴", to = "☵", reason = "qualified_structure_formation",
    authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☵", {}))
local execution = assert(registry.execute("☵", instance, context))
assert_eq(execution.status, "applied", "qualified ENCODE applies")
local payload = execution.payload
assert_eq(payload.mode, "structure_formation", "production mode is explicit")
assert_eq(payload.formation_basis, "packet_structure", "production basis is explicit")
assert_true(payload.identity_map.shadow_only == false, "production map is non-shadow")
assert_eq(payload.identity_map.old_ids[1], observed.field_unit_id,
    "identity map names exact source")
assert_eq(#payload.structure_formation.formed_unit_ids, 2,
    "both bounded alternatives are formed")
assert_eq(payload.loss.kind, "structure_projection_loss", "loss is visible")
assert_eq(payload.loss.calculation_status, "estimated_policy",
    "provisional loss does not pretend to be measured")
assert_eq(payload.structure_formation.choice_contract.consumer_contract_id,
    structure_inspection.choice_consumer_id, "choice contract is frozen at formation")
assert_true(pressure_action.verify_effect(witness.action_plan, payload, instance),
    "composite effect resolves")

local forged_map = copy_value(payload)
forged_map.identity_map.id = "identity_map:forged"
assert_true(not pressure_action.verify_effect(witness.action_plan, forged_map, instance),
    "forged identity map is rejected")
local missing_loss = copy_value(payload)
missing_loss.loss = nil
assert_true(not pressure_action.verify_effect(witness.action_plan, missing_loss, instance),
    "missing linked loss is rejected")

local formed = assert(structure_inspection.derive(instance))
assert_eq(#formed.missing, 0, "exact formation discharges missing state")
assert_eq(#formed.current, 1, "exact formation remains current")
local discharged = assert(qualified_pressure.structure_witnesses(instance, {
    current_operator = "☴",
}))
assert_eq(find_witness(discharged, "encoding_need"), nil,
    "same source version does not re-arm")

-- An unrelated object mutation cannot invalidate exact source/formation proof.
assert(packet.commit_transition(instance, {
    from = "☵", to = "☴", reason = "unrelated_structure_mutation",
    authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☴", {}))
local _, unrelated_event = assert(packet.append_chaos(instance, {
    operator = "☴", kind = "unrelated_fixture", truth_status = "runtime_confirmed",
}))
assert(field.add_unit(instance, "☴", {
    kind = "unrelated_material",
    carrier = {value = "unrelated"},
    source_refs = {payload.formation_event_id},
    created_event_id = unrelated_event.id,
    content_truth_status = "runtime_confirmed",
}))
local unchanged = assert(qualified_pressure.structure_witnesses(instance, {
    current_operator = "☴",
}))
assert_eq(find_witness(unchanged, "encoding_need"), nil,
    "unrelated mutation does not re-arm exact source")

-- A new observed strict source is a new exact need; the old proof stays historical.
assert(packet.commit_transition(instance, {
    from = "☴", to = "☰", reason = "new_source_spacing",
    authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☰", {}))
assert(packet.commit_transition(instance, {
    from = "☰", to = "☴", reason = "new_structure_source",
    authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☴", {}))
local _, new_observed = assert(observe.run(
    instance,
    substrate_with_text(json.encode(proposal("artifact_set", {"artifact"}))),
    {work_mode = "plan"}
))
local renewed = assert(qualified_pressure.structure_witnesses(instance, {
    current_operator = "☴",
}))
local renewed_witness = assert(find_witness(renewed, "encoding_need"),
    "new source creates a fresh need")
assert_eq(renewed_witness.action_plan.options.encode.structure_input.source_unit_id,
    new_observed.field_unit_id, "new need names only the new source")

-- SF-7: tree authority derives ▽ -> ☴ -> ☵ -> ☴ with no harness ENCODE scope.
local tree_substrate = substrate_with_text(json.encode(proposal("work_sequence")))
local tree_domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
    stream_id = "structure-formation-tree",
    source_ref = "fixture:structure-formation-tree",
}))
local tree_packet, tree_result = assert(tension_runner.run(
    "derive and form a work sequence",
    tree_substrate,
    {
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        ablate_relation_consumer = true,
        work_mode = "plan",
        max_ticks = 4,
        legacy_shadow = false,
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = tree_domain,
            projection_adapter = "vertical_single.v0",
        },
    }
))
assert_eq(tree_result.entry_route.to, "☴", "FLOW derives semantic observation")
assert_eq(tree_result.ticks[1].operator, "☴", "tree tick one observes")
assert_eq(tree_result.ticks[2].operator, "☵", "tree tick two forms structure")
assert_eq(tree_result.ticks[2].payload.mode, "structure_formation",
    "tree carries exact action into ENCODE")
assert_eq(tree_result.ticks[3].operator, "☴", "formed units request body-native sight")
assert_eq(tree_result.ticks[3].payload.sensor, "field_native",
    "second sight does not call the substrate")
assert_true(tree_packet.status == "dead" or tree_result.stop_reason == "tick_limit",
    "bounded treatment ends inside body physics")

-- SF-8: under shadow authority the qualified producer has no live mass.
local function shadow_life(ablate)
    local p, result = assert(tension_runner.run(
        "shadow structure ablation",
        tree_substrate,
        {
            router_mode = "shadow",
            pressure_policy = "qualified_need_v0",
            ablate_structure_consumer = ablate,
            work_mode = "plan",
            max_ticks = 3,
        }
    ))
    local operators = {}
    for _, tick in ipairs(result.ticks) do
        operators[#operators + 1] = tick.operator
    end
    return p, result, table.concat(operators, "")
end

local shadow_on, shadow_on_result, shadow_on_route = shadow_life(false)
local shadow_off, shadow_off_result, shadow_off_route = shadow_life(true)
assert_eq(shadow_on_route, shadow_off_route, "shadow producer cannot alter live route")
assert_eq(shadow_on.runtime.budget.spent.steps, shadow_off.runtime.budget.spent.steps,
    "shadow producer cannot alter step economics")
assert_eq(shadow_on.runtime.budget.spent.substrate_calls,
    shadow_off.runtime.budget.spent.substrate_calls,
    "shadow producer cannot alter substrate economics")
assert_eq(shadow_on.tension.loss, shadow_off.tension.loss,
    "shadow producer cannot alter identity loss")
assert_eq(shadow_on_result.stop_reason, shadow_off_result.stop_reason,
    "shadow producer cannot alter terminal reason")

print("test_structure_formation ok")
