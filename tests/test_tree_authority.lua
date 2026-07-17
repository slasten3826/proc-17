package.path = "./?.lua;./?/init.lua;" .. package.path

-- Gate A contract: explicit tree authority must remain runnable and auditable.

local packet = require("core.packet")
local tension_runner = require("runtime.tension_runner")
local edge_catalog = require("runtime.edge_catalog")
local fake = require("substrates.fake")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": " .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function base_packet_options()
    return {
        budget = {
            steps = 64,
            substrate_calls = 16,
            tool_calls = 8,
            encode_items = 16,
            loss = 10,
        },
    }
end

local function assert_body_result(instance, result, label)
    assert_true(type(instance) == "table",
        label .. " escaped as harness failure: " .. tostring(result))
    assert_true(type(result) == "table", label .. " result must be structured")
end

local function has_trace_event(instance, event_type)
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.type == event_type then
            return true, event
        end
    end
    return false, nil
end

local fixture_path = "sandbox/tree_authority_gate_ok.py"
local fixture = assert(io.open(fixture_path, "w"))
fixture:write("print('tree authority gate')\n")
fixture:close()

local cases = {}

local function case(name, run)
    cases[#cases + 1] = {name = name, run = run}
end

case("explicit_tree_authority_runs", function()
    local instance, result = tension_runner.run("inspect tree authority", fake, {
        router_mode = "tree",
        work_mode = "plan",
        max_ticks = 8,
        packet_options = base_packet_options(),
    })
    assert_body_result(instance, result, "tree authority")
    assert_true(result.stop_reason ~= nil, "tree life has a bounded outcome")
end)

case("normal_build_manifests_under_tree", function()
    local instance, result = tension_runner.run("build checked artifact", fake, {
        router_mode = "tree",
        work_mode = "build",
        max_ticks = 64,
        packet_options = base_packet_options(),
        logic = {
            spells = {
                {
                    kind = "check_file_exists",
                    name = "tree authority fixture exists",
                    intention = "grow accepted build evidence",
                    path = fixture_path,
                },
            },
        },
    })
    assert_body_result(instance, result, "tree build")
    assert_eq(result.stop_reason, "manifested", "tree build reaches manifest")
    assert_true(instance.terminal and instance.terminal.kind == "manifest",
        "tree build has manifest terminal")
    assert_eq(instance.manifest.output.status, "complete",
        "accepted tree build is outwardly complete")
    assert_eq(instance.terminal.cause, "complete",
        "accepted tree build has complete terminal cause")
    assert_eq(instance.manifest.assembly.input_provenance, "packet_trace",
        "tree manifest material belongs to Packet trace")
end)

case("rejected_validation_stays_inside_body", function()
    local instance, result = tension_runner.run("build missing artifact", fake, {
        router_mode = "tree",
        work_mode = "build",
        max_ticks = 64,
        packet_options = base_packet_options(),
        logic = {
            spells = {
                {
                    kind = "check_file_exists",
                    name = "missing tree authority fixture",
                    intention = "grow honest rejected validation",
                    path = "sandbox/tree_authority_gate_missing.py",
                },
            },
        },
    })
    assert_body_result(instance, result, "rejected validation")
    local validation = instance.boundary and instance.boundary.validations
        and instance.boundary.validations[#instance.boundary.validations]
    assert_true(validation and validation.status == "rejected",
        "test life grows a real rejected validation")
    assert_true(instance.terminal ~= nil, "rejected validation reaches typed terminal")
    for _, route in ipairs(result.routes or {}) do
        local selected = route.selected_candidate
        assert_true(selected and selected.readiness and selected.readiness.ready == true,
            "every committed tree route carries a ready selected candidate")
    end
end)

case("typed_substrate_failure_becomes_body_terminal", function()
    local failing_substrate = {
        ask = function()
            return nil, {
                kind = "effect_failure",
                source = "substrate",
                code = "connection_lost",
                message = "injected expected substrate failure",
                source_refs = {},
                retryability = "retryable",
                cost = {substrate_calls = 1},
                event_truth_status = "runtime_confirmed",
            }
        end,
    }

    local instance, result = tension_runner.run("observe until substrate failure", failing_substrate, {
        router_mode = "tree",
        work_mode = "plan",
        max_ticks = 20,
        packet_options = base_packet_options(),
    })
    assert_body_result(instance, result, "typed substrate failure")
    assert_true(instance.death and instance.death.cause == "effect_failure",
        "typed substrate failure kills inside Packet physics")
    assert_true(instance.terminal ~= nil, "effect failure creates terminal record")
    assert_true(has_trace_event(instance, "operator_failure"),
        "effect failure remains in Packet trace")
    local entry = result.entry_route
    local edge = assert(edge_catalog.get(entry.from, entry.to))
    local evidence = result.edge_stats.edges[edge.edge]
    assert_eq(evidence.failed_count, 1, "failed arrival is counted once")
    assert_eq(evidence.executed_count, 0, "failed arrival is not executed evidence")
    assert_eq(instance.runtime.budget.spent.substrate_calls, 1,
        "confirmed failed substrate attempt pays exactly one call")
end)

case("tree_missing_capability_stalls_inside_body", function()
    local instance, result = tension_runner.run("tree birth without substrate", nil, {
        router_mode = "tree",
        work_mode = "plan",
        max_ticks = 8,
        packet_options = base_packet_options(),
    })
    assert_body_result(instance, result, "missing tree capability")
    assert_eq(result.stop_reason, "stalled", "no viable birth edge is a body stall")
    assert_true(instance.death and instance.death.cause == "stalled",
        "stalled tree birth dies inside Packet physics")
    assert_eq(instance.residue.stall_kind, "missing_capability",
        "stall preserves the exact missing-capability cause")
    assert_true(type(instance.residue.candidate_audit_ref) == "string",
        "stall residue retains candidate audit evidence")
end)

case("committed_route_preserves_derivation_evidence", function()
    local instance = packet.new("route evidence gate")
    local selected = {
        to = "☴",
        total = 1,
        affordable = true,
        exclusions = {},
        excluded = false,
        readiness = {
            operator = "☴",
            ready = true,
            reason = "semantic_scope_available",
            source_refs = {"field:ingress"},
        },
    }
    local snapshot = assert(packet.append_trace(instance, {
        type = "tension_measure",
        operator = "▽",
        truth_status = "runtime_confirmed",
        payload = {kind = "edge_pressure_snapshot"},
        cost = {},
    }))
    local derivation = assert(packet.append_trace(instance, {
        type = "route_derivation",
        operator = "▽",
        truth_status = "runtime_confirmed",
        payload = {
            kind = "route_derivation",
            current_operator = "▽",
            pressure_snapshot_ref = snapshot.id,
            candidates = {selected},
            outcome = "selected",
            selected_to = "☴",
            policy = "pressure.binary.v0",
            threshold = 0,
        },
        cost = {},
    }))
    local route_event = assert(packet.commit_transition(instance, {
        kind = "tree_route_decision",
        from = "▽",
        to = "☴",
        reason = "highest_positive_pressure",
        derivation_ref = derivation.id,
        pressure_snapshot_ref = snapshot.id,
        selected_candidate = selected,
        policy = "pressure.binary.v0",
        threshold = 0,
    }))
    assert_eq(route_event.payload.derivation_ref, derivation.id,
        "route trace retains derivation ref")
    assert_eq(route_event.payload.pressure_snapshot_ref, snapshot.id,
        "route trace retains pressure snapshot ref")
    assert_true(route_event.payload.selected_candidate.readiness.ready,
        "route trace retains selected readiness")
end)

case("forged_tree_evidence_is_invariant_failure", function()
    local instance = packet.new("forged route evidence gate")
    local committed, commit_err = packet.commit_transition(instance, {
        kind = "tree_route_decision",
        from = "▽",
        to = "☴",
        reason = "forged",
        derivation_ref = "event-does-not-exist",
        pressure_snapshot_ref = "event-also-missing",
        selected_candidate = {
            to = "☴",
            readiness = {ready = true},
        },
    })
    assert_true(not committed, "forged tree evidence cannot move Packet")
    assert_true(tostring(commit_err):find("route_derivation", 1, true) ~= nil,
        "forged evidence reports an invariant failure")
end)

case("tree_flow_entry_is_body_derived", function()
    local instance, result = tension_runner.run("derive first tree road", fake, {
        router_mode = "tree",
        work_mode = "plan",
        max_ticks = 2,
        packet_options = base_packet_options(),
    })
    assert_body_result(instance, result, "tree entry")
    assert_true(result.entry_route.reason ~= "runner_entry",
        "normal tree entry is not assigned by harness")
    assert_true(type(result.entry_route.derivation_ref) == "string",
        "tree entry references its derivation")
    assert_true(result.entry_route.selected_candidate
        and result.entry_route.selected_candidate.readiness.ready == true,
        "tree entry commits a ready candidate")
end)

case("lua_invariant_failure_remains_loud", function()
    local exploding_substrate = {
        ask = function()
            error("injected_lua_invariant_failure")
        end,
    }
    local ok, err = pcall(function()
        tension_runner.run("explode trusted adapter", exploding_substrate, {
            router_mode = "tree",
            work_mode = "plan",
            max_ticks = 4,
            packet_options = base_packet_options(),
        })
    end)
    assert_eq(ok, false, "Lua invariant failure must escape the body")
    assert_true(tostring(err):find("injected_lua_invariant_failure", 1, true) ~= nil,
        "harness failure preserves diagnostic reason")
end)


case("malformed_effect_failure_remains_loud", function()
    local malformed_substrate = {
        ask = function()
            return nil, {
                kind = "effect_failure",
                source = "substrate",
            }
        end,
    }
    local ok, instance, err = pcall(function()
        return tension_runner.run("malformed external failure", malformed_substrate, {
            router_mode = "tree",
            work_mode = "plan",
            max_ticks = 20,
            packet_options = base_packet_options(),
        })
    end)
    assert_true(ok, "ordinary contract rejection need not throw Lua exception")
    assert_true(instance == nil, "malformed effect failure must escape body physics")
    assert_true(tostring(err):find("invalid effect failure contract", 1, true) ~= nil,
        "malformed failure preserves its invariant diagnostic")
end)

local red = 0
local green = 0
for _, value in ipairs(cases) do
    local ok, err = xpcall(value.run, debug.traceback)
    if ok then
        green = green + 1
        print("tree-authority gate GREEN " .. value.name)
    else
        red = red + 1
        local first_line = tostring(err):match("^[^\n]+") or tostring(err)
        print("tree-authority gate RED   " .. value.name .. " :: " .. first_line)
    end
end

os.remove(fixture_path)

print(string.format("tree-authority gate summary: green=%d red=%d", green, red))
if red > 0 then
    error("tree authority promotion gate remains red: " .. tostring(red) .. " case(s)")
end

print("test_tree_authority ok")
