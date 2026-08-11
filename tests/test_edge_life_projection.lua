package.path = "./?.lua;./?/init.lua;" .. package.path

local corpse = require("runtime.corpse")
local digest = require("core.digest")
local flow_domain = require("runtime.flow_domain")
local json = require("core.json")
local projection = require("runtime.edge_life_projection")
local tension_runner = require("runtime.tension_runner")
local fixture = require("tests.support.plan_life")

local function assert_true(value, message)
    if not value then error(message or "assertion failed", 2) end
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

local function first_difference(left, right, path, seen)
    path = path or "root"
    if type(left) ~= type(right) then return path .. ":type" end
    if type(left) ~= "table" then
        return left ~= right and (path .. ":" .. tostring(left)
            .. "!=" .. tostring(right)) or nil
    end
    seen = seen or {}
    seen[left] = seen[left] or {}
    if seen[left][right] then return nil end
    seen[left][right] = true
    local keys, present = {}, {}
    for key in pairs(left) do keys[#keys + 1] = key; present[key] = true end
    for key in pairs(right) do if not present[key] then keys[#keys + 1] = key end end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do
        if left[key] == nil or right[key] == nil then
            return path .. "." .. tostring(key) .. ":missing"
        end
        local difference = first_difference(
            left[key], right[key], path .. "." .. tostring(key), seen)
        if difference then return difference end
    end
    return nil
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

local function with_host_time(value, callback)
    local original = os.time
    os.time = function() return value end
    local values = table.pack(pcall(callback))
    os.time = original
    if not values[1] then error(values[2], 0) end
    return table.unpack(values, 2, values.n)
end

local function grown(label)
    local instance, result = assert(fixture.run(
        label,
        "work_sequence",
        {"inspect"},
        5,
        {
            packet_options = {
                budget = {
                    steps = 1,
                    substrate_calls = 4,
                    tool_calls = 4,
                    encode_items = 4,
                    loss = 4,
                },
            },
        }
    ))
    assert_eq(instance.status, "dead", "fixture must finish")
    local dead = assert(corpse.capture(instance, {
        corpse_id = "corpse:" .. label,
        trace_tail_count = 4,
    }))
    return instance, result, dead
end

local function capture(instance, result, dead, life_id, bounds)
    local record, err = projection.capture(instance, result, dead, {
        life_id = life_id,
        instrument_bounds = bounds,
    })
    assert_true(record ~= nil, err and err.code or err)
    return record
end

local instance, result, dead = grown("edge-life-projection")

-- LP01: post-life observation is detached and has no body mass.
local before = assert(digest.record(instance))
local exact = capture(instance, result, dead, "life:projection:base")
local after = assert(digest.record(instance))
assert_eq(before, after, "LP01 projector mutated Packet")
assert_true(projection.verify(exact), "LP01 projection verifies")
assert_eq(exact.corpse_status, "present", "LP01 corpse is present")
assert_true(exact.exact_digest ~= exact.observer_neutral_digest,
    "LP01 exact view retains raw host time and corpse identity")

-- LP02: an external instrument toggle cannot change exact body components.
local exact_again = capture(instance, result, dead, "life:projection:instrument-on")
local same_exact, exact_differences = projection.same_exact(exact, exact_again)
assert_true(same_exact, "LP02 exact instrument ablation: "
    .. table.concat(exact_differences or {}, ","))

local function observer_event(packet, id, predicted_to)
    return {
        id = id,
        packet_id = packet.id,
        lineage_id = packet.lineage_id,
        generation = packet.generation,
        tick = packet.physis.clock.ticks,
        type = "tension_measure",
        operator = "☱",
        payload = {
            kind = "shadow_route_decision",
            observer = "legacy",
            live_authority = "tree",
            current_operator = "☱",
            predicted_to = predicted_to or "△",
            instrumentation_status = "observed",
            truth_status = "runtime_confirmed",
        },
        truth_status = "runtime_confirmed",
        cost = {},
        time = 1,
    }
end

-- LP03/LP05: remove only the observer event named by the runner decision.
local neutral_base_packet = copy_value(instance)
local neutral_base_result = copy_value(result)
local unnamed = observer_event(neutral_base_packet, "observer-event-900", "☵")
neutral_base_packet.trace[#neutral_base_packet.trace + 1] = unnamed

local observed_packet = copy_value(neutral_base_packet)
local observed_result = copy_value(neutral_base_result)
local named = observer_event(observed_packet, "observer-event-901", "△")
observed_packet.trace[#observed_packet.trace + 1] = named
observed_result.shadow_routes = {
    {
        kind = "shadow_route_decision",
        observer = "legacy",
        live_authority = "tree",
        current_operator = "☱",
        predicted_to = "△",
        instrumentation_status = "observed",
        truth_status = "runtime_confirmed",
        trace_event_id = named.id,
    },
}

local neutral_base = capture(
    neutral_base_packet,
    neutral_base_result,
    nil,
    "life:projection:observer-off"
)
local observed = capture(
    observed_packet,
    observed_result,
    nil,
    "life:projection:observer-on"
)
local raw_same = projection.same_exact(neutral_base, observed)
assert_true(raw_same == false, "LP03 raw observer traces must differ")
local neutral_same, neutral_differences = projection.same_observer_neutral(
    neutral_base,
    observed
)
assert_true(neutral_same, "LP03 neutral observer pair: "
    .. table.concat(neutral_differences or {}, ","))
assert_same(observed.removed_observer_refs, {named.id},
    "LP03 exact observer ref is named")
assert_eq(#observed.observer_neutral_components.packet_trace,
    #neutral_base.observer_neutral_components.packet_trace,
    "LP03 one named event removed")

local changed_unnamed_packet = copy_value(observed_packet)
changed_unnamed_packet.trace[#changed_unnamed_packet.trace - 1]
    .payload.predicted_to = "☷"
local changed_unnamed = capture(
    changed_unnamed_packet,
    observed_result,
    nil,
    "life:projection:unnamed-changed"
)
local unnamed_same, unnamed_differences = projection.same_observer_neutral(
    neutral_base,
    changed_unnamed
)
assert_true(unnamed_same == false, "LP05 unnamed same-kind event must remain")
assert_true(#(unnamed_differences or {}) > 0, "LP05 reports differing component")

-- LP04: absent and wrongly typed observer refs reject capture.
local absent_result = copy_value(observed_result)
absent_result.shadow_routes[1].trace_event_id = "observer-event-999"
local absent, absent_err = projection.capture(observed_packet, absent_result, nil, {
    life_id = "life:projection:absent-ref",
})
assert_eq(absent, nil, "LP04 absent observer ref rejects")
assert_eq(absent_err.code, "observer_trace_ref_invalid", "LP04 absent ref code")

local wrong_packet = copy_value(observed_packet)
wrong_packet.trace[#wrong_packet.trace].payload.observer = "tree"
local wrong, wrong_err = projection.capture(wrong_packet, observed_result, nil, {
    life_id = "life:projection:wrong-ref",
})
assert_eq(wrong, nil, "LP04 wrong observer identity rejects")
assert_eq(wrong_err.code, "observer_trace_ref_invalid", "LP04 wrong ref code")

-- LP10/LP11: the real legacy observer has its own id lane and no body-ref mass.
local function grown_observer_pair(observer)
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = "edge-life-observer-pair",
        source_ref = "fixture:edge-life-observer-pair",
    }))
    local pair_packet, pair_result = assert(tension_runner.run(
        "edge life observer pair",
        fixture.substrate(fixture.proposal("work_sequence", {"inspect"})),
        {
            router_mode = "tree",
            pressure_policy = "qualified_need_v0",
            ablate_relation_consumer = true,
            legacy_shadow = observer,
            work_mode = "plan",
            max_ticks = 5,
            packet_life = {
                protocol_version = "vertical_packet_life.v0",
                flow_domain = domain,
                projection_adapter = "vertical_single.v0",
            },
            packet_options = {
                id = "packet:edge-life-observer-pair",
                lineage_id = "lineage:edge-life-observer-pair",
                metadata = {time = "semantic-time-must-remain"},
                budget = {
                    steps = 1,
                    substrate_calls = 4,
                    tool_calls = 4,
                    encode_items = 4,
                    loss = 4,
                },
            },
        }
    ))
    local pair_corpse = assert(corpse.capture(pair_packet, {
        corpse_id = "corpse:edge-life-observer-pair",
        trace_tail_count = 32,
    }))
    return pair_packet, pair_result, pair_corpse
end

local pair_off_packet, pair_off_result, pair_off_corpse = with_host_time(
    1785542400,
    function() return grown_observer_pair(false) end
)
local pair_on_packet, pair_on_result, pair_on_corpse = with_host_time(
    1785542401,
    function() return grown_observer_pair(true) end
)
local off_body_ids = {}
local on_body_ids = {}
for _, event in ipairs(pair_off_packet.trace) do
    if event.id:match("^event%-%d+$") then off_body_ids[#off_body_ids + 1] = event.id end
end
for _, event in ipairs(pair_on_packet.trace) do
    if event.id:match("^event%-%d+$") then on_body_ids[#on_body_ids + 1] = event.id end
end
assert_same(off_body_ids, on_body_ids, "LP11 observer cannot shift body event ids")
assert_true(#pair_on_result.shadow_routes > 0, "LP10 real observer produced evidence")
assert_true(
    pair_off_corpse.residue.trace_tail[1].time
        ~= pair_on_corpse.residue.trace_tail[1].time,
    "LP10 fixture must exercise embedded residue host-time normalization"
)
for _, shadow in ipairs(pair_on_result.shadow_routes) do
    assert_true(shadow.trace_event_id:match("^observer%-event%-%d+$") ~= nil,
        "LP11 observer uses its own trace lane")
end

local pair_off = capture(
    pair_off_packet,
    pair_off_result,
    pair_off_corpse,
    "life:projection:real-observer-off"
)
local pair_on = capture(
    pair_on_packet,
    pair_on_result,
    pair_on_corpse,
    "life:projection:real-observer-on"
)
local grown_raw_same = projection.same_exact(pair_off, pair_on)
assert_true(grown_raw_same == false, "LP10 real raw pair must expose observer")
local grown_neutral_same, grown_neutral_differences =
    projection.same_observer_neutral(pair_off, pair_on)
assert_true(grown_neutral_same, "LP10 real observer-neutral pair: "
    .. table.concat(grown_neutral_differences or {}, ",") .. ":"
    .. tostring(first_difference(
        pair_off.observer_neutral_components,
        pair_on.observer_neutral_components
    )))

-- LP10b: legacy and shadow share legacy_control physics; Tree pressure is observer-only.
local function grown_tree_shadow_pair(mode)
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = "edge-life-tree-shadow-pair",
        source_ref = "fixture:edge-life-tree-shadow-pair",
    }))
    local pair_packet, pair_result = assert(tension_runner.run(
        "edge life tree shadow pair",
        fixture.substrate(fixture.proposal("work_sequence", {"inspect"})),
        {
            router_mode = mode,
            pressure_policy = "qualified_need_v0",
            ablate_relation_consumer = true,
            work_mode = "plan",
            max_ticks = 5,
            packet_life = {
                protocol_version = "vertical_packet_life.v0",
                flow_domain = domain,
                projection_adapter = "vertical_single.v0",
            },
            packet_options = {
                id = "packet:edge-life-tree-shadow-pair",
                lineage_id = "lineage:edge-life-tree-shadow-pair",
                budget = {
                    steps = 2,
                    substrate_calls = 4,
                    tool_calls = 4,
                    encode_items = 4,
                    loss = 4,
                },
            },
        }
    ))
    local pair_corpse = assert(corpse.capture(pair_packet, {
        corpse_id = "corpse:edge-life-tree-shadow-pair",
        trace_tail_count = 32,
    }))
    return pair_packet, pair_result, pair_corpse
end

local legacy_packet, legacy_result, legacy_corpse = with_host_time(
    1785542400,
    function() return grown_tree_shadow_pair("legacy") end
)
local shadow_packet, shadow_result, shadow_corpse = with_host_time(
    1785542401,
    function() return grown_tree_shadow_pair("shadow") end
)
assert_true(#shadow_result.shadow_routes > 0, "LP10b Tree observer produced evidence")
assert_true(shadow_result.shadow_routes[1].pressure_snapshot_ref ~= nil,
    "LP10b Tree observer names pressure evidence")
local legacy_projection = capture(
    legacy_packet,
    legacy_result,
    legacy_corpse,
    "life:projection:legacy-control"
)
local shadow_projection = capture(
    shadow_packet,
    shadow_result,
    shadow_corpse,
    "life:projection:tree-shadow"
)
assert_true(#shadow_projection.removed_observer_refs >= 2,
    "LP10b decision and pressure refs are both removed")
local shadow_pair_same, shadow_pair_differences =
    projection.same_observer_neutral(legacy_projection, shadow_projection)
assert_true(shadow_pair_same, "LP10b legacy/shadow neutral pair: "
    .. table.concat(shadow_pair_differences or {}, ",") .. ":"
    .. tostring(first_difference(
        legacy_projection.observer_neutral_components,
        shadow_projection.observer_neutral_components
    )))

-- LP12: the closed wall-time rule cannot erase semantic metadata named time.
local semantic_time_packet = copy_value(pair_on_packet)
semantic_time_packet.metadata.time = "different-semantic-time"
local semantic_time = capture(
    semantic_time_packet,
    pair_on_result,
    pair_on_corpse,
    "life:projection:semantic-time"
)
local semantic_same = projection.same_observer_neutral(pair_off, semantic_time)
assert_true(semantic_same == false, "LP12 metadata.time remains significant")

-- LP06/LP08: the record survives mutation and loss of every caller object.
local detached_packet = copy_value(instance)
local detached_result = copy_value(result)
local detached_corpse = copy_value(dead)
local detached = capture(
    detached_packet,
    detached_result,
    detached_corpse,
    "life:projection:detached"
)
local detached_snapshot = assert(projection.snapshot(detached))
detached_packet.metadata.changed = true
detached_result.ticks[1].payload.changed = true
detached_corpse.residue.changed = true
assert_true(projection.verify(detached), "LP06 caller mutation cannot alter record")
assert_same(detached, detached_snapshot, "LP06 detached bytes stable")
detached_packet, detached_result, detached_corpse = nil, nil, nil
collectgarbage("collect")
local detached_copy = assert(projection.snapshot(detached))
local detached_same = projection.same_exact(detached, detached_copy)
assert_true(detached_same, "LP08 discarded sources still compare")

-- LP07: selected state accepts only acyclic, metatable-free plain data.
local cyclic_packet = copy_value(instance)
cyclic_packet.metadata.cycle = cyclic_packet.metadata
local cyclic, cyclic_err = projection.capture(cyclic_packet, result, nil, {
    life_id = "life:projection:cycle",
})
assert_eq(cyclic, nil, "LP07 cycle rejects")
assert_eq(cyclic_err.code, "projection_cycle_rejected", "LP07 cycle code")

local meta_packet = copy_value(instance)
meta_packet.metadata.decorated = setmetatable({}, {})
local decorated, decorated_err = projection.capture(meta_packet, result, nil, {
    life_id = "life:projection:metatable",
})
assert_eq(decorated, nil, "LP07 metatable rejects")
assert_eq(decorated_err.code, "projection_metatable_rejected", "LP07 metatable code")

local function_packet = copy_value(instance)
function_packet.metadata.callback = function() end
local callback, callback_err = projection.capture(function_packet, result, nil, {
    life_id = "life:projection:function",
})
assert_eq(callback, nil, "LP07 function rejects")
assert_eq(callback_err.code, "projection_non_plain_value", "LP07 function code")

local userdata_packet = copy_value(instance)
userdata_packet.metadata.handle = io.stdout
local handle, handle_err = projection.capture(userdata_packet, result, nil, {
    life_id = "life:projection:userdata",
})
assert_eq(handle, nil, "LP07 userdata rejects")
assert_eq(handle_err.code, "projection_non_plain_value", "LP07 userdata code")

local thread_packet = copy_value(instance)
thread_packet.metadata.thread = coroutine.create(function() end)
local thread, thread_err = projection.capture(thread_packet, result, nil, {
    life_id = "life:projection:thread",
})
assert_eq(thread, nil, "LP07 thread rejects")
assert_eq(thread_err.code, "projection_non_plain_value", "LP07 thread code")

local nested_packet = copy_value(instance)
nested_packet.metadata.packet = instance
local live, live_err = projection.capture(nested_packet, result, nil, {
    life_id = "life:projection:live-packet",
})
assert_eq(live, nil, "LP07 nested live Packet rejects")
assert_eq(live_err.code, "projection_live_packet_rejected", "LP07 live Packet code")

-- LP09: archival bounds reject without touching the body.
local bounded_before = assert(digest.record(instance))
local bounded, bounded_err = projection.capture(instance, result, dead, {
    life_id = "life:projection:bounded",
    instrument_bounds = {max_projection_bytes = 1},
})
assert_eq(bounded, nil, "LP09 byte bound rejects")
assert_eq(bounded_err.code, "projection_bound_exceeded", "LP09 bound code")
assert_eq(assert(digest.record(instance)), bounded_before,
    "LP09 bound rejection has no body mass")

print("test_edge_life_projection ok")
