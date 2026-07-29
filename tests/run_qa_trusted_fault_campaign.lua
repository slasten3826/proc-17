package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local digest = require("core.digest")
local fixtures = require("tests.support.qa_hostile_fixtures")
local owned = require("tests.support.owned_temp_root")
local support = require("tests.support.qa_provider_witness")
local witness = require("runtime.qa_provider_witness")

local expected = {
    ["trusted-wrong-launcher-abi"] = {
        boundary = "loader_abi_rejected", start = "not_started",
        terminal = "no_terminal", variants = 1, owner = "lua",
    },
    ["trusted-wrong-supervisor-identity"] = {
        boundary = "launcher_identity_rejected", start = "not_started",
        terminal = "no_terminal", variants = 1, owner = "native",
    },
    ["trusted-malformed-request-frames"] = {
        boundary = "supervisor_request_rejected", start = "not_started",
        terminal = "no_started", variants = 7, owner = "native",
    },
    ["trusted-malformed-result-frames"] = {
        boundary = "trusted_invariant", start = "started",
        terminal = "loud", variants = 7, owner = "native",
    },
    ["trusted-crash-before-start"] = {
        boundary = "supervisor_crashed", start = "not_started",
        terminal = "infrastructure", variants = 1, owner = "native",
    },
    ["trusted-crash-after-start"] = {
        boundary = "supervisor_crashed", start = "started",
        terminal = "infrastructure", variants = 1, owner = "native",
    },
    ["trusted-lost-result-pipe"] = {
        boundary = "result_pipe_lost", start = "not_started",
        terminal = "infrastructure", variants = 1, owner = "native",
    },
    ["trusted-wait-reap-ambiguity"] = {
        boundary = "reap_ambiguous", start = "started",
        terminal = "infrastructure", variants = 1, owner = "native",
    },
    ["trusted-postflight-source-drift"] = {
        boundary = "source_drift", start = "started",
        terminal = "quarantined", variants = 1, owner = "lua",
    },
}

local function read(path)
    local file = assert(io.open(path, "rb"))
    local bytes = assert(file:read("*a"))
    assert(file:close())
    return bytes
end

local function copy_file(source, target)
    local output = assert(io.open(target, "wb"))
    assert(output:write(read(source)))
    assert(output:close())
end

local function quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function command_ok(command)
    local ok, why, code = os.execute(command)
    return ok == true and (code == nil or code == 0), why, code
end

local function capture(command)
    local stream = assert(io.popen(command, "r"))
    local output = assert(stream:read("*a"))
    local closed, why, code = stream:close()
    H.assert_true(closed == true and (code == nil or code == 0),
        "trusted command failed: " .. tostring(why) .. ":" .. tostring(code))
    H.assert_true(#output <= 65536, "trusted command output is bounded")
    return output
end

local function corrupt_inventory(raw)
    local changed = H.copy(raw)
    for _, entry in ipairs(changed.entries or {}) do
        if entry.kind == "regular_file" and type(entry.content) == "string" then
            entry.content = string.rep("x", #entry.content)
            return changed
        end
    end
    error("trusted drift fixture has no regular file", 0)
end

local declared = 0
for _ in pairs(expected) do declared = declared + 1 end
H.assert_eq(declared, 9, "closed QN18 expectation count")

local ids = {}
for _, item in ipairs(fixtures.items) do
    if item.class == "trusted_fault" then
        local bytes = assert(fixtures.read(item))
        H.assert_true(expected[item.id] ~= nil,
            "unexpected QN18 fixture id: " .. tostring(item.id))
        H.assert_false(ids[item.id] == true,
            "duplicate QN18 fixture id: " .. item.id)
        H.assert_eq(bytes:sub(1, #fixtures.marker), fixtures.marker,
            "QN18 inert marker")
        H.assert_contains(bytes, "-- fixture-id: " .. item.id,
            "QN18 embedded fixture identity")
        ids[item.id] = true
    end
end
for id in pairs(expected) do
    H.assert_true(ids[id] == true, "missing QN18 fixture: " .. id)
end

local executed = 0
local matched = 0
local candidate_outcomes = 0
local source_quarantines = 0

local native_output = capture(
    "cd native && ./tests/test_proc17_qa_trusted_faults"
)
local native_count = 0
for line in native_output:gmatch("[^\n]+") do
    local id, boundary, start, terminal, variants = line:match(
        "^QN18_NATIVE_V0|([^|]+)|([^|]+)|([^|]+)|([^|]+)|(%d+)$"
    )
    H.assert_true(id ~= nil, "malformed QN18 native record: " .. line)
    local row = expected[id]
    H.assert_true(row ~= nil and row.owner == "native",
        "unexpected QN18 native row: " .. tostring(id))
    H.assert_false(row.observed == true, "duplicate QN18 native row: " .. id)
    row.observed = true
    H.assert_eq(boundary, row.boundary, id .. " boundary")
    H.assert_eq(start, row.start, id .. " start state")
    H.assert_eq(terminal, row.terminal, id .. " terminal state")
    H.assert_eq(tonumber(variants), row.variants, id .. " variant count")
    native_count = native_count + 1
    executed = executed + 1
    matched = matched + 1
end
H.assert_eq(native_count, 7, "exact QN18 native row count")

assert(owned.with_root(function(root)
    local runtime_dir = assert(owned.assert_owned_path(
        root, root.path .. "/runtime"))
    local native_dir = assert(owned.assert_owned_path(
        root, root.path .. "/native"))
    local ok, why, code = command_ok(
        "mkdir -p " .. quote(runtime_dir) .. " " .. quote(native_dir))
    H.assert_true(ok, "owned loader fixture mkdir: "
        .. tostring(why) .. ":" .. tostring(code))
    local loader_path = runtime_dir .. "/qa_provider.lua"
    copy_file("runtime/qa_provider.lua", loader_path)
    copy_file("native/tests/proc17_qa_launcher_fault_test.so",
        native_dir .. "/proc17_qa_launcher.so")
    local chunk = assert(loadfile(loader_path))
    local loaded, load_err = pcall(chunk)
    H.assert_false(loaded, "production loader accepted fault launcher")
    H.assert_contains(load_err, "native ABI mismatch",
        "fault launcher rejection names ABI")
    executed = executed + 1
    matched = matched + 1
    return true
end))

assert(support.with_candidate("return true\n", function(grown)
    local inventories = 0
    local runs = 0
    local exact_inventory = grown.repository_provider.inventory_tree
    local function hostile_inventory(handle, bounds)
        inventories = inventories + 1
        local raw, err = exact_inventory(handle, bounds)
        if not raw then return nil, err end
        if inventories == 2 then raw = corrupt_inventory(raw) end
        return raw
    end
    local qa_provider = {
        run = function(handle, request)
            runs = runs + 1
            return grown.qa_provider.run(handle, request)
        end,
    }
    local services = {
        repository_capabilities = grown.registry,
        repository_provider = grown.repository_provider,
        qa_provider = qa_provider,
        qa_environment = grown.environment,
    }
    local plan = assert(witness.prepare(grown.instance, services))
    local report, err = support.with_root_bound_inventory(
        grown,
        hostile_inventory,
        function()
            return witness.execute(grown.instance, services, plan)
        end
    )
    H.assert_nil(report, "source drift cannot produce candidate witness")
    H.assert_eq(err.protocol_version, "qa.provider_witness_error.v1")
    H.assert_eq(err.class, "ambiguous")
    H.assert_eq(err.code, "source_drift")
    H.assert_eq(err.stage, "postflight")
    H.assert_eq(err.candidate_start_state, "started")
    H.assert_eq(err.source_disposition, "quarantined")
    H.assert_false(err.source_stable)
    H.assert_eq(err.cleanup_state, "complete")
    H.assert_eq(err.launcher_reaped, "complete")
    H.assert_eq(err.result_eof, "complete")
    H.assert_eq(runs, 1)
    H.assert_eq(inventories, 2)
    source_quarantines = source_quarantines + 1
    executed = executed + 1
    matched = matched + 1
    return true
end))

assert(support.with_candidate("return true\n", function(grown)
    local runs = 0
    local qa_provider = {
        run = function()
            runs = runs + 1
            error("test-only malformed trusted terminal", 0)
        end,
    }
    local services = {
        repository_capabilities = grown.registry,
        repository_provider = grown.repository_provider,
        qa_provider = qa_provider,
        qa_environment = grown.environment,
    }
    local plan = assert(witness.prepare(grown.instance, services))
    local ok, err = pcall(witness.execute, grown.instance, services, plan)
    H.assert_false(ok, "trusted contradiction returned normally")
    H.assert_contains(err, "callback failed",
        "trusted contradiction is loud after finality")
    local replay, replay_err = witness.execute(grown.instance, services, plan)
    H.assert_nil(replay, "quarantined malformed-result source replayed")
    H.assert_true(replay_err ~= nil, "quarantine replay denial is explicit")
    H.assert_eq(runs, 1, "quarantine prevents second trusted callback")
    source_quarantines = source_quarantines + 1
    return true
end))

local production_exclusions = 0
do
    local production_module = read("native/proc17_qa_launcher.so")
    local fault_module = read("native/tests/proc17_qa_launcher_fault_test.so")
    local production_supervisor = read("native/proc17_qa_supervisor")
    local fault_supervisor = read("native/tests/proc17_qa_supervisor_fault_test")
    H.assert_false(digest.sha256(production_module) == digest.sha256(fault_module),
        "fault launcher identity aliases production")
    H.assert_false(digest.sha256(production_supervisor)
            == digest.sha256(fault_supervisor),
        "fault supervisor identity aliases production")
    production_exclusions = production_exclusions + 1

    local production_symbols = capture("nm -D native/proc17_qa_launcher.so")
    H.assert_false(production_symbols:find(
        "proc17_qa_fault_test_", 1, true) ~= nil,
        "fault symbol entered production launcher")
    local fault_symbols = capture(
        "nm -D native/tests/proc17_qa_launcher_fault_test.so")
    H.assert_contains(fault_symbols,
        "proc17_qa_fault_test_supervisor_identity_accepts",
        "fault build lacks its distinct test-only seam")
    production_exclusions = production_exclusions + 1

    local production_strings = production_module .. production_supervisor
    for _, forbidden in ipairs({
        "proc17.qa.launcher.lua54.fault-test.v0",
        "proc17.qa.supervisor.fault-test.v0",
        "fault-build-identity",
        "trusted-wrong-launcher-abi",
        "trusted-malformed-result-frames",
    }) do
        H.assert_false(production_strings:find(forbidden, 1, true) ~= nil,
            "test identity entered production artifact: " .. forbidden)
    end
    production_exclusions = production_exclusions + 1

    local fault_strings = fault_module .. fault_supervisor
    H.assert_contains(fault_strings,
        "proc17.qa.launcher.lua54.fault-test.v0")
    H.assert_contains(fault_strings,
        "proc17.qa.supervisor.fault-test.v0")
    production_exclusions = production_exclusions + 1

    local provider = require("runtime.qa_provider")
    H.assert_nil(provider.inject_fault, "production provider exports fault API")
    H.assert_nil(provider.fault_mode, "production provider exports fault mode")
    production_exclusions = production_exclusions + 1

    local production_lua = read("runtime/qa_provider.lua")
        .. read("runtime/qa_process.lua")
    for _, forbidden in ipairs({"fault_mode", "fault_kind", "inject_fault"}) do
        H.assert_false(production_lua:find(forbidden, 1, true) ~= nil,
            "fault selector entered production Lua: " .. forbidden)
    end
    production_exclusions = production_exclusions + 1
end

H.assert_eq(executed, 9, "QN18 executed count")
H.assert_eq(matched, 9, "QN18 matched count")
H.assert_eq(candidate_outcomes, 0, "QN18 candidate outcome count")
H.assert_eq(source_quarantines, 2, "QN18 source quarantine witnesses")
H.assert_eq(production_exclusions, 6, "QN18 production exclusions")

print(string.format(
    "proc17 QN18 trusted fault campaign ok: declared=%d executed=%d matched=%d candidate_outcomes=%d source_quarantines=%d production_exclusions=%d",
    declared, executed, matched, candidate_outcomes, source_quarantines,
    production_exclusions))
