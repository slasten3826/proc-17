package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local qa_process = require("runtime.qa_process")
local support = require("tests.support.qa_provider_witness")
local witness = require("runtime.qa_provider_witness")

local expected = {
    ["terminal-missing"] = {
        class = "ambiguous", code = "terminal_frame_missing",
        stage = "postflight", start = "started", cleanup = "unknown",
        reap = "complete", eof = "complete", variants = 1, owner = "native",
    },
    ["reap-ambiguity"] = {
        class = "ambiguous", code = "reap_ambiguous",
        stage = "cleanup", start = "started", cleanup = "unknown",
        reap = "unknown", eof = "complete", variants = 1, owner = "native",
    },
    ["stream-observation"] = {
        class = "ambiguous", code = "output_observation_incomplete",
        stage = "postflight", start = "started", cleanup = "incomplete",
        reap = "complete", eof = "complete", variants = 2, owner = "native",
    },
    ["scratch-observation"] = {
        class = "ambiguous", code = "scratch_observation_incomplete",
        stage = "postflight", start = "started", cleanup = "incomplete",
        reap = "complete", eof = "complete", variants = 1, owner = "native",
    },
    ["namespace-cleanup"] = {
        class = "ambiguous", code = "namespace_cleanup_incomplete",
        stage = "cleanup", start = "started", cleanup = "incomplete",
        reap = "complete", eof = "complete", variants = 1, owner = "native",
    },
    ["postflight-source-drift"] = {
        class = "ambiguous", code = "source_drift",
        stage = "postflight", start = "started", cleanup = "complete",
        reap = "complete", eof = "complete", variants = 1, owner = "lua",
    },
}

local function capture(command)
    local stream = assert(io.popen(command, "r"))
    local output = assert(stream:read("*a"))
    local closed, why, code = stream:close()
    H.assert_true(closed == true and (code == nil or code == 0),
        "QN19 native driver failed: " .. tostring(why) .. ":" .. tostring(code))
    H.assert_true(#output <= 32768, "QN19 native output is bounded")
    return output
end

local function read(path)
    local file = assert(io.open(path, "rb"))
    local bytes = assert(file:read("*a"))
    assert(file:close())
    return bytes
end

local function command_ok(command)
    local ok, _, code = os.execute(command)
    return ok == true and (code == nil or code == 0)
end

local function corrupt_inventory(raw)
    local changed = H.copy(raw)
    for _, entry in ipairs(changed.entries or {}) do
        if entry.kind == "regular_file" and type(entry.content) == "string" then
            entry.content = string.rep("x", #entry.content)
            return changed
        end
    end
    error("QN19 drift source has no regular file", 0)
end

local declared = 0
for _ in pairs(expected) do declared = declared + 1 end
H.assert_eq(declared, 6, "closed QN19 case count")

local native_rows = {}
for line in capture("native/tests/test_proc17_qa_cleanup_ambiguity")
        :gmatch("[^\n]+") do
    local id, class, code, stage, start, cleanup, reap, eof, variants =
        line:match(
            "^QN19_NATIVE_V0|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|(%d+)$")
    H.assert_true(id ~= nil, "malformed QN19 native record: " .. line)
    local row = expected[id]
    H.assert_true(row ~= nil and row.owner == "native",
        "unexpected QN19 native row: " .. tostring(id))
    H.assert_true(native_rows[id] == nil, "duplicate QN19 native row: " .. id)
    H.assert_eq(class, row.class, id .. " class")
    H.assert_eq(code, row.code, id .. " code")
    H.assert_eq(stage, row.stage, id .. " stage")
    H.assert_eq(start, row.start, id .. " start")
    H.assert_eq(cleanup, row.cleanup, id .. " cleanup")
    H.assert_eq(reap, row.reap, id .. " reap")
    H.assert_eq(eof, row.eof, id .. " EOF")
    H.assert_eq(tonumber(variants), row.variants, id .. " variants")
    native_rows[id] = row
end

local native_count = 0
for id, row in pairs(expected) do
    if row.owner == "native" then
        H.assert_true(native_rows[id] ~= nil, "missing QN19 native row: " .. id)
        native_count = native_count + 1
    end
end
H.assert_eq(native_count, 5, "exact QN19 native row count")

local executed = 0
local matched = 0
local stream_variants = 0
local candidate_outcomes = 0
local source_quarantines = 0
local replayed_provider_calls = 0
local owned_paths = {}

for id, row in pairs(native_rows) do
    assert(support.with_candidate("return true\n", function(grown)
        owned_paths[#owned_paths + 1] = grown.root.path
        local runs = 0
        local qa_provider = {
            run = function(_, request)
                runs = runs + 1
                local raw = {
                    protocol_version = "qa.native_run_error.v1",
                    transaction_id = request.transaction_id,
                    witness_id = request.witness_id,
                    profile_id = request.profile_id,
                    environment_id = request.environment_id,
                    phase_ordinal = row.start == "started" and 2 or 1,
                    class = row.class,
                    code = row.code,
                    stage = row.stage,
                    candidate_start_state = row.start,
                    cleanup_state = row.cleanup,
                    launcher_reaped = row.reap,
                    result_eof = row.eof,
                    event_truth_status = "runtime_confirmed",
                }
                return nil, qa_process.normalize_error_v1(raw, request)
            end,
        }
        local services = {
            repository_capabilities = grown.registry,
            repository_provider = grown.repository_provider,
            qa_provider = qa_provider,
            qa_environment = grown.environment,
        }
        local plan = assert(witness.prepare(grown.instance, services))
        local report, err = witness.execute(grown.instance, services, plan)
        if report ~= nil then candidate_outcomes = candidate_outcomes + 1 end
        H.assert_nil(report, id .. " produced a candidate witness")
        H.assert_eq(err.protocol_version, "qa.provider_witness_error.v1")
        H.assert_eq(err.class, row.class, id .. " witness class")
        H.assert_eq(err.code, row.code, id .. " witness code")
        H.assert_eq(err.stage, row.stage, id .. " witness stage")
        H.assert_eq(err.candidate_start_state, row.start, id .. " witness start")
        H.assert_eq(err.cleanup_state, row.cleanup, id .. " witness cleanup")
        H.assert_eq(err.launcher_reaped, row.reap, id .. " witness reap")
        H.assert_eq(err.result_eof, row.eof, id .. " witness EOF")
        H.assert_eq(err.source_disposition, "quarantined")
        local replay, replay_err = witness.execute(grown.instance, services, plan)
        H.assert_nil(replay, id .. " quarantined source replayed")
        H.assert_true(replay_err ~= nil, id .. " replay denial is explicit")
        replayed_provider_calls = replayed_provider_calls + math.max(0, runs - 1)
        H.assert_eq(runs, 1, id .. " launched more than once")
        source_quarantines = source_quarantines + 1
        executed = executed + 1
        matched = matched + 1
        if id == "stream-observation" then
            stream_variants = row.variants
        end
        return true
    end))
end

do
    local row = expected["postflight-source-drift"]
    assert(support.with_candidate("return true\n", function(grown)
        owned_paths[#owned_paths + 1] = grown.root.path
        local inventories = 0
        local runs = 0
        local repository_provider = {
            provider_id = grown.repository_provider.provider_id,
            inventory_tree = function(handle, bounds)
                inventories = inventories + 1
                local raw, err = grown.repository_provider.inventory_tree(
                    handle, bounds)
                if not raw then return nil, err end
                if inventories == 2 then raw = corrupt_inventory(raw) end
                return raw
            end,
        }
        local qa_provider = {
            run = function(handle, request)
                runs = runs + 1
                return grown.qa_provider.run(handle, request)
            end,
        }
        local services = {
            repository_capabilities = grown.registry,
            repository_provider = repository_provider,
            qa_provider = qa_provider,
            qa_environment = grown.environment,
        }
        local plan = assert(witness.prepare(grown.instance, services))
        local report, err = witness.execute(grown.instance, services, plan)
        if report ~= nil then candidate_outcomes = candidate_outcomes + 1 end
        H.assert_nil(report, "postflight drift produced a candidate witness")
        H.assert_eq(err.class, row.class)
        H.assert_eq(err.code, row.code)
        H.assert_eq(err.stage, row.stage)
        H.assert_eq(err.candidate_start_state, row.start)
        H.assert_eq(err.cleanup_state, row.cleanup)
        H.assert_eq(err.launcher_reaped, row.reap)
        H.assert_eq(err.result_eof, row.eof)
        H.assert_eq(err.source_disposition, "quarantined")
        local replay, replay_err = witness.execute(grown.instance, services, plan)
        H.assert_nil(replay, "postflight drift source replayed")
        H.assert_true(replay_err ~= nil, "postflight drift replay denial")
        replayed_provider_calls = replayed_provider_calls + math.max(0, runs - 1)
        H.assert_eq(runs, 1, "postflight drift launched more than once")
        H.assert_eq(inventories, 2, "postflight drift inventory count")
        source_quarantines = source_quarantines + 1
        executed = executed + 1
        matched = matched + 1
        return true
    end))
end

H.assert_eq(executed, 6, "QN19 executed count")
H.assert_eq(matched, 6, "QN19 matched count")
H.assert_eq(stream_variants, 2, "QN19 stream variant count")
H.assert_eq(candidate_outcomes, 0, "QN19 candidate outcome count")
H.assert_eq(source_quarantines, 6, "QN19 source quarantine count")
H.assert_eq(replayed_provider_calls, 0, "QN19 replayed provider calls")

local production_exclusions = 0
do
    local production = read("native/proc17_qa_supervisor")
        .. read("native/proc17_qa_launcher.so")
    for _, forbidden in ipairs({
        "QN19_NATIVE_V0",
        "terminal-missing",
        "reap-ambiguity",
        "stream-observation",
        "scratch-observation",
        "namespace-cleanup",
        "postflight-source-drift",
    }) do
        H.assert_false(production:find(forbidden, 1, true) ~= nil,
            "QN19 selector entered production artifact: " .. forbidden)
    end
    production_exclusions = production_exclusions + 1

    local production_lua = read("runtime/qa_provider.lua")
        .. read("runtime/qa_process.lua")
        .. read("runtime/qa_provider_witness.lua")
    H.assert_false(production_lua:find("QN19_NATIVE_V0", 1, true) ~= nil,
        "QN19 record entered production Lua")
    production_exclusions = production_exclusions + 1

    local provider = require("runtime.qa_provider")
    H.assert_nil(provider.inject_cleanup_ambiguity,
        "production provider exports QN19 injection")
    H.assert_nil(provider.qn19_case,
        "production provider exports QN19 selector")
    production_exclusions = production_exclusions + 1

    local driver_source = read(
        "native/tests/test_proc17_qa_cleanup_ambiguity.c")
    H.assert_false(driver_source:find("getenv(", 1, true) ~= nil,
        "QN19 driver reads an environment selector")
    H.assert_false(command_ok(
        "native/tests/test_proc17_qa_cleanup_ambiguity unexpected"),
        "QN19 driver accepted an argument")
    production_exclusions = production_exclusions + 1
end

local residue_checks = 0
for _, path in ipairs(owned_paths) do
    H.assert_true(command_ok("test ! -e " .. path),
        "QN19 owned root survived cleanup: " .. path)
    residue_checks = residue_checks + 1
end
do
    local processes = capture("ps -eo comm=")
    for line in processes:gmatch("[^\n]+") do
        local name = line:match("^%s*(.-)%s*$")
        H.assert_false(name == "proc17_qa_supervisor",
            "QN19 supervisor process survived campaign")
    end
    residue_checks = residue_checks + 1
end

print(string.format(
    "proc17 QN19 cleanup ambiguity campaign ok: declared=%d executed=%d matched=%d stream_variants=%d candidate_outcomes=%d source_quarantines=%d replays=%d",
    declared, executed, matched, stream_variants, candidate_outcomes,
    source_quarantines, replayed_provider_calls))
print(string.format(
    "proc17 QN19 exclusion audit ok: production_exclusions=%d residue_checks=%d",
    production_exclusions, residue_checks))
