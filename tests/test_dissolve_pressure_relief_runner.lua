package.path = "./?.lua;./?/init.lua;" .. package.path

local digest = require("core.digest")
local flow_domain = require("runtime.flow_domain")
local pressure_relief = require("runtime.dissolve_pressure_relief")
local tension_runner = require("runtime.tension_runner")
local qa_fixture = require("tests.support.qa_hand")

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

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function differences(left, right, path, output, seen)
    output = output or {}
    if #output >= 20 then return output end
    path = path or "$"
    if type(left) ~= type(right) then
        output[#output + 1] = path .. " type " .. type(left) .. " ~= " .. type(right)
        return output
    end
    if type(left) ~= "table" then
        if left ~= right then
            output[#output + 1] = path .. " " .. tostring(left)
                .. " ~= " .. tostring(right)
        end
        return output
    end
    seen = seen or {}
    if seen[left] == right then return output end
    seen[left] = right
    local keys = {}
    for key in pairs(left) do keys[key] = true end
    for key in pairs(right) do keys[key] = true end
    local ordered = {}
    for key in pairs(keys) do ordered[#ordered + 1] = key end
    table.sort(ordered, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(ordered) do
        differences(left[key], right[key], path .. "." .. tostring(key), output, seen)
        if #output >= 20 then break end
    end
    return output
end

local grown = assert(qa_fixture.grow_qa_descendant({
    label = "pressure-relief-runner",
    session_id = "session-pressure-relief-runner",
    packet_options = {id = "packet:pressure-relief-runner-ancestor"},
    child_packet_id = "packet:pressure-relief-runner-fixture-child",
    child_stream_id = "stream:pressure-relief-runner-child",
    fresh_repository_id = "repo-pressure-relief-runner-child",
}))

local function with_frozen_time(callback)
    local original = os.time
    os.time = function() return 1787184000 end
    local result = table.pack(pcall(callback))
    os.time = original
    if not result[1] then error(result[2], 0) end
    return table.unpack(result, 2, result.n)
end

local function run(reader_mode)
    local packet_options = copy_value(grown.ingress.packet_options)
    packet_options.id = "packet:pressure-relief-runner-child"
    packet_options.repository_id = grown.fresh_repository_id
    packet_options.budget = {
        steps = 32,
        substrate_calls = 8,
        tool_calls = 8,
        encode_items = 16,
        loss = 10,
    }
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = "stream:pressure-relief-runner-child",
        source_ref = grown.network_projection.projection_id,
    }))
    return with_frozen_time(function()
        return tension_runner.run(grown.ingress.prompt, nil, {
            authority_instrument = "v3",
            router_mode = "tree",
            pressure_policy = "qualified_need_v0",
            legacy_shadow = false,
            work_mode = "build",
            max_ticks = 1,
            ablate_relation_consumer = true,
            dissolve_pressure_relief_reader = reader_mode,
            packet_options = packet_options,
            packet_life = {
                protocol_version = "vertical_packet_life.v0",
                flow_domain = domain,
                projection_adapter = "vertical_single.v0",
                network_projection = grown.ingress.network_projection,
            },
            edge_evidence = {
                case_id = "PR-T15",
                corpus_layer = "unit",
                evidence_run_id = "run:pressure-relief-reader-ablation",
            },
        })
    end)
end

local disabled_instance, disabled = assert(run("off"))
local enabled_instance, enabled = assert(run("v0"))

-- PR-T15: enabling the reader changes diagnostics and nothing else.
assert_eq(disabled.dissolve_pressure_relief_reader, "off")
assert_eq(#disabled.dissolve_pressure_relief_measurements, 0)
assert_eq(enabled.dissolve_pressure_relief_reader, "v0")
assert_eq(#enabled.dissolve_pressure_relief_measurements, 1)

local measurement = enabled.dissolve_pressure_relief_measurements[1]
assert_eq(measurement.measurement_status, "discharged")
assert_eq(measurement.pressure_relief.classification,
    "discharged_with_successor_obligation")
assert(measurement.actual_post.expected_successor)
-- PR-T16: discharge remains valid without a successor substrate call.
assert_eq(measurement.actual_post.expected_successor.executable, false,
    "substrate-free successor was falsely executable")

local packet_differences = differences(
    enabled_instance,
    disabled_instance
)
assert_eq(#packet_differences, 0,
    "reader option changed Packet body state: " .. table.concat(packet_differences, " | "))

local disabled_result = copy_value(disabled)
local enabled_result = copy_value(enabled)
disabled_result.dissolve_pressure_relief_reader = nil
disabled_result.dissolve_pressure_relief_measurements = nil
enabled_result.dissolve_pressure_relief_reader = nil
enabled_result.dissolve_pressure_relief_measurements = nil
local result_differences = differences(
    enabled_result,
    disabled_result
)
assert_eq(#result_differences, 0,
    "reader option changed runner behavior outside diagnostic result: "
        .. table.concat(result_differences, " | "))
assert_eq(assert(digest.record(enabled_result)),
    assert(digest.record(disabled_result)),
    "reader option changed runner digest")

-- PR-T12: without inherited rigidity, the body never selects the treatment
-- and therefore cannot manufacture relief credit.
local no_rigidity_domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
    stream_id = "stream:pressure-relief-no-rigidity",
    source_ref = "control:pressure-relief:no-rigidity",
}))
local substrate = {
    ask = function()
        return {
            text = "bounded no-rigidity observation",
            usage = {
                prompt_tokens = 1,
                completion_tokens = 1,
                total_tokens = 2,
            },
        }
    end,
}
local no_rigidity_instance, no_rigidity_result = assert(with_frozen_time(function()
    return tension_runner.run("pressure relief control", substrate, {
        authority_instrument = "v3",
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        legacy_shadow = false,
        work_mode = "build",
        max_ticks = 2,
        dissolve_pressure_relief_reader = "v0",
        packet_options = {
            id = "packet:pressure-relief-no-rigidity",
            lineage_id = "lineage:pressure-relief-no-rigidity",
            session_id = "session:pressure-relief-no-rigidity",
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
            flow_domain = no_rigidity_domain,
            projection_adapter = "vertical_single.v0",
        },
        edge_evidence = {
            case_id = "PR-T12",
            corpus_layer = "unit",
            evidence_run_id = "run:pressure-relief-no-rigidity",
        },
    })
end))
assert_eq(#no_rigidity_result.dissolve_pressure_relief_measurements, 0)
for _, event in ipairs(no_rigidity_instance.trace) do
    assert(event.type ~= "unit_dissolution",
        "no-rigidity control performed a DISSOLVE release")
end
for _, unit_id in ipairs(no_rigidity_instance.field.unit_order) do
    assert(no_rigidity_instance.field.units[unit_id].kind
        ~= "inherited_rejected_form",
        "no-rigidity control materialized an inherited form")
end

-- A diagnostic failure is a loud harness error, never a Packet death.
local original_measure = pressure_relief.measure
local observed_instance
pressure_relief.measure = function(instance)
    observed_instance = instance
    error("injected pressure-relief failure")
end
local failed_instance, failed_err = run("v0")
pressure_relief.measure = original_measure
assert(failed_instance == nil)
assert(failed_err:find("dissolve_pressure_relief:reader_failure:", 1, true))
assert(observed_instance, "injected reader did not reach the runner hook")
assert_eq(observed_instance.status, "running")
assert(observed_instance.death == nil and observed_instance.terminal == nil,
    "reader failure fabricated Packet death")

local invalid, invalid_err = tension_runner.run("invalid reader option", nil, {
    dissolve_pressure_relief_reader = "yes",
})
assert(invalid == nil)
assert(invalid_err:find(
    "dissolve_pressure_relief_reader must be off or v0",
    1,
    true
))

print("test_dissolve_pressure_relief_runner ok")
