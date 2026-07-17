package.path = "./?.lua;./?/init.lua;" .. package.path

-- Gate B contract: tree moves; legacy may only observe.

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

local function assert_numeric_map_eq(left, right, message)
    local keys = {}
    for key in pairs(left or {}) do
        keys[key] = true
    end
    for key in pairs(right or {}) do
        keys[key] = true
    end
    for key in pairs(keys) do
        assert_eq(left and left[key], right and right[key], message .. "." .. tostring(key))
    end
end

local function run_tree(legacy_shadow)
    return tension_runner.run("build checked tree instrumentation", fake, {
        router_mode = "tree",
        legacy_shadow = legacy_shadow,
        work_mode = "build",
        max_ticks = 64,
        packet_options = {
            budget = {
                steps = 64,
                substrate_calls = 16,
                tool_calls = 8,
                encode_items = 16,
                loss = 10,
            },
        },
        logic = {
            spells = {
                {
                    kind = "check_file_exists",
                    name = "README exists",
                    intention = "grow accepted Gate B evidence",
                    path = "README.md",
                },
            },
        },
    })
end

local function full_route(result)
    local values = {}
    local entry = result.entry_route
    if entry then
        values[#values + 1] = tostring(entry.from) .. "->" .. tostring(entry.to)
    end
    for _, route in ipairs(result.routes or {}) do
        values[#values + 1] = tostring(route.from) .. "->" .. tostring(route.to)
    end
    return table.concat(values, "|")
end

local function trace_counts(instance)
    local result = {
        routes = 0,
        derivations = 0,
        legacy_shadows = 0,
    }
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "route" then
            result.routes = result.routes + 1
        elseif event.type == "route_derivation" then
            result.derivations = result.derivations + 1
        elseif event.payload and event.payload.kind == "shadow_route_decision"
            and event.payload.observer == "legacy" then
            result.legacy_shadows = result.legacy_shadows + 1
        end
    end
    return result
end

local without, without_result = assert(run_tree(false))
local with, with_result = assert(run_tree(true))

local cases = {}
local function case(name, run)
    cases[#cases + 1] = {name = name, run = run}
end

case("legacy_observer_cannot_change_tree_physics", function()
    assert_eq(full_route(with_result),
        "▽->☴|☴->☰|☰->☵|☵->☲|☲->☶|☶->☱|☱->△",
        "complete tree walk includes FLOW entry")
    assert_eq(full_route(with_result), full_route(without_result), "live route")
    assert_eq(#with_result.ticks, #without_result.ticks, "tick count")
    assert_numeric_map_eq(with.runtime.budget.spent, without.runtime.budget.spent, "budget spent")
    assert_numeric_map_eq(with.runtime.budget.remaining, without.runtime.budget.remaining,
        "budget remaining")
    assert_eq(with.tension.loss, without.tension.loss, "identity loss")
    assert_numeric_map_eq(with.revisions, without.revisions, "Packet revisions")
    assert_eq(with_result.stop_reason, without_result.stop_reason, "stop reason")
    assert_eq(with.status, without.status, "final status")
    assert_eq(with.death and with.death.cause, without.death and without.death.cause,
        "death cause")
    assert_eq(with.terminal and with.terminal.kind, without.terminal and without.terminal.kind,
        "terminal kind")
    assert_eq(#(with.boundary.validations or {}), #(without.boundary.validations or {}),
        "validation count")
    assert_eq(#(with.runtime.evidence or {}), #(without.runtime.evidence or {}),
        "runtime evidence count")
    local with_validation = with.boundary.validations[#with.boundary.validations]
    local without_validation = without.boundary.validations[#without.boundary.validations]
    assert_eq(with_validation and with_validation.status,
        without_validation and without_validation.status,
        "validation status")
    assert_eq(with.manifest and with.manifest.output and with.manifest.output.type,
        without.manifest and without.manifest.output and without.manifest.output.type,
        "manifest type")
    assert_eq(with_result.edge_stats_errors, nil, "enabled observer has no ledger errors")
    assert_eq(without_result.edge_stats_errors, nil, "disabled observer has no ledger errors")
end)

case("tree_life_records_one_legacy_observer_per_derivation", function()
    local counts = trace_counts(with)
    assert_eq(counts.routes, counts.derivations, "every committed tree route has derivation")
    assert_eq(counts.legacy_shadows, counts.derivations,
        "every tree derivation has one legacy observation")
    assert_eq(#with_result.shadow_routes, counts.derivations,
        "run report exposes every legacy observation")
    assert_eq(#with.trace - #without.trace, counts.legacy_shadows,
        "observer adds only its own append-only trace events")
    assert_true(with_result.legacy_shadow, "run report marks enabled legacy observer")
    for _, shadow in ipairs(with_result.shadow_routes) do
        assert_eq(shadow.observer, "legacy", "observer identity")
        assert_eq(shadow.live_authority, "tree", "live authority remains tree")
    end
    for _, event in ipairs(with.trace or {}) do
        if event.type == "route" then
            assert_eq(event.payload.shadow, nil,
                "observer data stays outside committed route evidence")
        end
    end
end)

case("legacy_observer_can_be_disabled", function()
    local counts = trace_counts(without)
    assert_eq(counts.legacy_shadows, 0, "disabled observer writes no shadow event")
    assert_eq(#without_result.shadow_routes, 0, "disabled observer writes no report item")
    assert_eq(without_result.legacy_shadow, false, "run report marks disabled observer")
end)

case("unsupported_legacy_source_is_typed_instrumentation_absence", function()
    local unavailable
    for _, shadow in ipairs(with_result.shadow_routes) do
        if shadow.current_operator == "☰" then
            unavailable = shadow
            break
        end
    end
    assert_true(unavailable ~= nil, "tree CONNECT tick has a legacy observation")
    assert_eq(unavailable.predicted_to, nil, "legacy invents no CONNECT successor")
    assert_eq(unavailable.instrumentation_status, "unavailable", "absence is typed")
    assert_eq(unavailable.predicted_reason, "unsupported_route_source", "reason is preserved")
end)

case("tree_derivations_feed_edge_statistics", function()
    local counts = trace_counts(with)
    assert_eq(with_result.edge_stats.tree_derivation_count, counts.derivations,
        "ledger reads every live tree derivation")
    local entry_edge = with_result.edge_stats.edges[assert(edge_catalog.get("▽", "☴")).edge]
    assert_true(entry_edge.candidate_count > 0, "entry candidate is counted")
    assert_true(entry_edge.selection_count > 0, "entry tree selection is counted")
    assert_true(entry_edge.committed_count > 0, "entry tree route is committed")
    assert_true(entry_edge.executed_count > 0, "entry destination executes")
    assert_true((entry_edge.authority_counts or {}).tree > 0,
        "committed edge names tree authority")
    assert_true(#(entry_edge.derivation_refs or {}) > 0,
        "committed edge retains derivation refs")
    local observers = with_result.edge_stats.observers or {}
    assert_eq(observers.legacy and observers.legacy.comparison_count, counts.derivations,
        "observer statistics are separated by identity")
    assert_eq(observers.legacy and observers.legacy.unavailable_count, 1,
        "typed CONNECT absence is counted once")
end)

case("legacy_observer_does_not_pollute_tree_evidence", function()
    assert_eq(with_result.edge_stats.tree_derivation_count,
        without_result.edge_stats.tree_derivation_count,
        "observer cannot create tree derivations")
    for edge_id, with_edge in pairs(with_result.edge_stats.edges or {}) do
        local without_edge = without_result.edge_stats.edges[edge_id]
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
            assert_eq(with_edge[key], without_edge[key],
                "observer polluted edge " .. tostring(edge_id) .. "." .. key)
        end
    end
    for rail_id, with_rail in pairs(with_result.edge_stats.rails or {}) do
        local without_rail = without_result.edge_stats.rails[rail_id]
        for channel_id, with_channel in pairs(with_rail.channels or {}) do
            local without_channel = without_rail.channels[channel_id]
            for _, key in ipairs({
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
            }) do
                assert_eq(with_channel[key], without_channel[key],
                    "observer polluted rail " .. tostring(rail_id)
                        .. "." .. tostring(channel_id) .. "." .. key)
            end
        end
    end
end)

case("legacy_observer_never_commits", function()
    for _, event in ipairs(with.trace or {}) do
        if event.type == "route" then
            assert_eq(event.payload.authority, "tree", "only tree commits in tree mode")
        end
    end
end)

local red = 0
local green = 0
for _, value in ipairs(cases) do
    local ok, err = xpcall(value.run, debug.traceback)
    if ok then
        green = green + 1
        print("tree-instrumentation gate GREEN " .. value.name)
    else
        red = red + 1
        local first_line = tostring(err):match("^[^\n]+") or tostring(err)
        print("tree-instrumentation gate RED   " .. value.name .. " :: " .. first_line)
    end
end

print(string.format("tree-instrumentation gate summary: green=%d red=%d", green, red))
if red > 0 then
    error("tree instrumentation gate remains red: " .. tostring(red) .. " case(s)")
end

print("test_tree_instrumentation ok")
