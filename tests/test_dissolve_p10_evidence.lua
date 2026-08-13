package.path = "./?.lua;./?/init.lua;" .. package.path

local digest = require("core.digest")
local edge_case_manifest = require("runtime.edge_case_manifest")
local edge_corpus = require("runtime.edge_corpus")
local edge_current_report = require("runtime.edge_current_report")
local edge_life_projection = require("runtime.edge_life_projection")
local flow_domain = require("runtime.flow_domain")
local tension_runner = require("runtime.tension_runner")
local fixture = require("tests.support.qa_hand")

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function copy_value(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function tagged(value)
    return "sha256:" .. assert(digest.record(value))
end

local function one_life_id(ledger)
    local found
    for life_id in pairs(ledger.source_lives or {}) do
        assert(found == nil, "P10 ledger contains multiple lives")
        found = life_id
    end
    return assert(found, "P10 ledger contains no life")
end

local function event_count(instance, event_type)
    local count = 0
    for _, event in ipairs(instance.trace or {}) do
        if event.type == event_type then count = count + 1 end
    end
    return count
end

local function field_unit(instance, kind)
    local found
    for _, id in ipairs(instance.field and instance.field.unit_order or {}) do
        local unit = instance.field.units[id]
        if unit and unit.kind == kind then
            assert(found == nil, "duplicate field unit: " .. kind)
            found = unit
        end
    end
    return found
end

local function instrumented_life(prompt, substrate, options)
    local instance, result = assert(tension_runner.run(
        prompt,
        substrate,
        options
    ))
    local life_id = one_life_id(assert(result.edge_stats))
    local projection = assert(edge_life_projection.capture(
        instance,
        result,
        nil,
        {life_id = life_id}
    ))
    return {
        instance = instance,
        result = result,
        life_id = life_id,
        projection = projection,
    }
end

local substrate = {
    ask = function()
        return {
            text = "bounded post-release observation",
            usage = {
                prompt_tokens = 1,
                completion_tokens = 1,
                total_tokens = 2,
            },
        }
    end,
}

local function rejected_life(grown, observer_enabled, run_id)
    local packet_options = copy_value(grown.ingress.packet_options)
    packet_options.id = "packet:qa-p10-child"
    packet_options.repository_id = grown.fresh_repository_id
    packet_options.budget = {
        steps = 32,
        substrate_calls = 8,
        tool_calls = 8,
        encode_items = 16,
        loss = 10,
    }
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = "stream:qa-p10-child",
        source_ref = grown.network_projection.projection_id,
    }))
    local life = instrumented_life(grown.ingress.prompt, substrate, {
        authority_instrument = "v3",
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        legacy_shadow = observer_enabled,
        work_mode = "build",
        max_ticks = 2,
        packet_options = packet_options,
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = domain,
            projection_adapter = "vertical_single.v0",
            network_projection = grown.ingress.network_projection,
        },
        edge_evidence = {
            case_id = "P10",
            corpus_layer = "L0",
            evidence_run_id = run_id,
        },
    })
    life.prompt = grown.ingress.prompt
    assert_eq(event_count(life.instance, "unit_dissolution"), 1,
        "P10 positive life must release exactly once")
    assert_eq(assert(field_unit(
        life.instance,
        "inherited_rejected_form"
    )).activation, "dissolved")
    return life
end

local function no_rigidity_life(prompt)
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = "stream:qa-p10-no-rigidity",
        source_ref = "control:qa-p10:no-rigidity",
    }))
    local life = instrumented_life(prompt, substrate, {
        authority_instrument = "v3",
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        legacy_shadow = true,
        work_mode = "build",
        max_ticks = 2,
        packet_options = {
            id = "packet:qa-p10-no-rigidity",
            lineage_id = "lineage:qa-p10-no-rigidity",
            session_id = "session:qa-p10",
            budget = {
                steps = 32,
                substrate_calls = 8,
                tool_calls = 8,
                encode_items = 16,
                loss = 10,
            },
        },
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = domain,
            projection_adapter = "vertical_single.v0",
        },
        edge_evidence = {
            case_id = "P10",
            corpus_layer = "L0",
            evidence_run_id = "run:qa-p10:no-rigidity",
        },
    })
    assert_eq(event_count(life.instance, "unit_dissolution"), 0,
        "P10 no-rigidity life must not release")
    assert(field_unit(life.instance, "inherited_rejected_form") == nil,
        "P10 no-rigidity life materialized inherited form")
    return life
end

local frozen_time = 1786665600
local function frozen(callback)
    local original = os.time
    os.time = function() return frozen_time end
    local values = table.pack(pcall(callback))
    os.time = original
    if not values[1] then error(values[2], 0) end
    return table.unpack(values, 2, values.n)
end

local primary, mirror, no_rigidity = frozen(function()
    local grown = assert(fixture.grow_qa_descendant({
        label = "qa-p10-ancestor",
        session_id = "session:qa-p10",
        packet_options = {id = "packet:qa-p10-ancestor"},
        child_packet_id = "packet:qa-p10-fixture-child",
        child_stream_id = "stream:qa-p10-fixture-child",
        fresh_repository_id = "repo-qa-p10-child",
    }))
    local enabled = rejected_life(
        grown,
        true,
        "run:qa-p10:observer-enabled"
    )
    local disabled = rejected_life(
        grown,
        false,
        "run:qa-p10:observer-disabled"
    )
    local control = no_rigidity_life(enabled.prompt)
    return enabled, disabled, control
end)

local revision = "revision:dissolve-p10-evidence.v1"
local function provenance(label)
    return {
        source_revision = revision,
        worktree_state = "clean",
        artifact_digest = tagged({test = "dissolve-p10", life = label}),
        event_truth_status = "runtime_confirmed",
        content_truth_status = "runtime_confirmed",
        verifier_ref = "tests.test_dissolve_p10_evidence:" .. label,
    }
end

local corpus = assert(edge_corpus.new({
    corpus_id = "corpus:dissolve-p10-evidence:v1",
    authority_claim = "diagnostic",
}))
for label, life in pairs({
    primary = primary,
    mirror = mirror,
    no_rigidity = no_rigidity,
}) do
    assert(edge_corpus.add_life(
        corpus,
        life.result,
        life.projection,
        provenance(label)
    ))
end
local pair = assert(edge_corpus.add_observer_pair(
    corpus,
    primary.life_id,
    mirror.life_id
))
assert_eq(pair.status, "green", "P10 observer pair must be massless")

local case_record = assert(edge_corpus.evaluate_l0_case(corpus, "P10", {
    life_ids = {primary.life_id},
    observer_pair_refs = {pair.pair_id},
    controls = {
        no_rigidity = {life_ids = {no_rigidity.life_id}},
    },
}))
assert_eq(case_record.status, "green",
    "P10 exact release evidence must be green")

local current_manifest = edge_case_manifest.current()
local p10_definition
for _, definition in ipairs(current_manifest.required_l0) do
    if definition.case_id == "P10" then p10_definition = definition break end
end
assert_eq(assert(p10_definition).evaluator_id,
    "tree-authority.case.P10.unit_dissolution.v1")
assert_eq(p10_definition.evaluator_version,
    "edge-case-evaluator.p10.release.v1")

local report = assert(edge_current_report.build(corpus, {
    implementation_revision = revision,
}))
assert_eq(report.promotion_authorized, false,
    "green direct P10 cannot promote Tree")
assert(#report.promotion_blockers > 0,
    "green direct P10 must leave promotion blockers")

local epoch_id = tagged({epoch = "p10-hostile"})
local physics_id = tagged({physics = "p10-hostile"})
local pair_id = tagged({pair = "p10-hostile"})

local function direct_case(primary_projection, primary_directions,
    control_projection, control_directions)
    local primary_id = "life:p10:hostile-primary"
    local mirror_id = "life:p10:hostile-mirror"
    local control_id = "life:p10:hostile-control"
    local function life(id, projection, directions)
        return {
            life_id = id,
            case_id = "P10",
            corpus_layer = "L0",
            evidence_epoch_id = epoch_id,
            physics_epoch_id = physics_id,
            implementation_revision = revision,
            projection = projection,
            eligible_directions = directions,
        }
    end
    local view = {
        kind = "edge_case_corpus_view",
        protocol_version = edge_case_manifest.view_protocol_version,
        target_evidence_epoch_id = epoch_id,
        target_physics_epoch_id = physics_id,
        implementation_revision = revision,
        lives = {
            [primary_id] = life(
                primary_id,
                primary_projection,
                primary_directions
            ),
            [mirror_id] = life(
                mirror_id,
                primary_projection,
                primary_directions
            ),
            [control_id] = life(
                control_id,
                control_projection,
                control_directions or {}
            ),
        },
        observer_pairs = {
            [pair_id] = {
                pair_id = pair_id,
                status = "green",
                enabled_life_id = primary_id,
                disabled_life_id = mirror_id,
                physics_epoch_id = physics_id,
            },
        },
        evidence_records = {},
        harness_evidence = {},
    }
    return assert(edge_case_manifest.evaluate_l0("P10", view, {
        life_ids = {primary_id},
        observer_pair_refs = {pair_id},
        controls = {no_rigidity = {life_ids = {control_id}}},
    }))
end

-- The obsolete reader called this green solely because an unrelated loss and
-- a claimed direction existed. The v1 reader requires the release join.
local old_false_green_instance = copy_value(no_rigidity.instance)
old_false_green_instance.boundary.loss_records = {
    {kind = "unrelated_crystallization_loss", amount = 1},
}
local old_false_green = assert(edge_life_projection.capture(
    old_false_green_instance,
    no_rigidity.result,
    nil,
    {life_id = "projection:p10:old-false-green"}
))
assert_eq(direct_case(
    old_false_green,
    {"▽->☷"},
    no_rigidity.projection,
    {}
).status, "red", "P10 old loss channel must not satisfy release")

assert_eq(direct_case(
    primary.projection,
    {},
    no_rigidity.projection,
    {}
).status, "red", "P10 event without credited arrival must be red")

local stale_target_instance = copy_value(primary.instance)
local stale_target = assert(field_unit(
    stale_target_instance,
    "inherited_rejected_form"
))
stale_target.activation = "live"
stale_target.activation_source = nil
local stale_target_projection = assert(edge_life_projection.capture(
    stale_target_instance,
    primary.result,
    nil,
    {life_id = "projection:p10:stale-target"}
))
assert_eq(direct_case(
    stale_target_projection,
    {"▽->☷"},
    no_rigidity.projection,
    {}
).status, "red", "P10 contradictory target state must be red")

local missing_residue_instance = copy_value(primary.instance)
local missing_residue = assert(field_unit(
    missing_residue_instance,
    "rejected_form_residue"
))
missing_residue_instance.field.units[missing_residue.id] = nil
local missing_residue_projection = assert(edge_life_projection.capture(
    missing_residue_instance,
    primary.result,
    nil,
    {life_id = "projection:p10:missing-residue"}
))
assert_eq(direct_case(
    missing_residue_projection,
    {"▽->☷"},
    no_rigidity.projection,
    {}
).status, "red", "P10 missing residue must be red")

local foreign_residue_instance = copy_value(primary.instance)
local foreign_residue = assert(field_unit(
    foreign_residue_instance,
    "rejected_form_residue"
))
foreign_residue.carrier.source_corpse_id = "corpse:foreign-p10-source"
local foreign_residue_projection = assert(edge_life_projection.capture(
    foreign_residue_instance,
    primary.result,
    nil,
    {life_id = "projection:p10:foreign-residue"}
))
assert_eq(direct_case(
    foreign_residue_projection,
    {"▽->☷"},
    no_rigidity.projection,
    {}
).status, "red", "P10 foreign residue must be red")

assert_eq(direct_case(
    primary.projection,
    {"▽->☷"},
    primary.projection,
    {"▽->☷"}
).status, "red", "P10 active release life cannot pose as no-rigidity control")

print("test_dissolve_p10_evidence ok")
