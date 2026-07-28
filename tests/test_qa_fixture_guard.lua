package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local digest = require("core.digest")
local fixtures = require("tests.support.qa_hostile_fixtures")
local suite = H.new("qa-fixture-guard")

local required_pressures = {
    "clean exit 0",
    "nonzero exit",
    "Lua error",
    "infinite CPU loop",
    "infinite wall loop",
    "allocator exhaustion",
    "stdout flood",
    "stderr flood",
    "scratch byte and inode exhaustion",
    "source create overwrite rename unlink",
    "host and sibling path probes",
    "socket and network attempt",
    "fork and clone attempt",
    "exec attempt",
    "native module load attempt",
    "descriptor enumeration and escape",
    "policy violation and SIGSYS classification",
    "wrong launcher ABI",
    "wrong supervisor digest or ABI",
    "short oversized corrupt request frames",
    "short oversized corrupt result frames",
    "supervisor crash before candidate start",
    "supervisor crash after candidate start",
    "lost result pipe",
    "forced wait and reap ambiguity",
    "trusted postflight source drift",
}

suite:check("QF01 manifest is closed and covers every crystall pressure", function()
    local ids = {}
    local pressures = {}
    for _, item in ipairs(fixtures.items) do
        H.assert_false(ids[item.id] == true, "duplicate fixture id: " .. item.id)
        ids[item.id] = true
        pressures[item.pressure] = true
        H.assert_true(item.class == "candidate" or item.class == "trusted_fault",
            "closed fixture class")
        fixtures.path(item)
    end
    H.assert_eq(#fixtures.items, #required_pressures, "exact fixture count")
    for _, pressure in ipairs(required_pressures) do
        H.assert_true(pressures[pressure] == true, "missing pressure: " .. pressure)
    end
end)

suite:check("QF02 every hostile fixture is bounded inert data", function()
    local hashes = {}
    for _, item in ipairs(fixtures.items) do
        local bytes = assert(fixtures.read(item))
        H.assert_true(#bytes > #fixtures.marker, "fixture contains a body")
        H.assert_eq(bytes:sub(1, #fixtures.marker), fixtures.marker,
            "fixture marker: " .. item.id)
        H.assert_contains(bytes, "-- fixture-id: " .. item.id,
            "fixture identity: " .. item.id)
        local hash = assert(digest.sha256(bytes))
        H.assert_false(hashes[hash] == true, "duplicate fixture bytes: " .. item.id)
        hashes[hash] = true
    end
end)

suite:check("QF03 ordinary runner reaches fixture bytes only through the guard", function()
    local file = assert(io.open("tests/run.lua", "rb"))
    local source = assert(file:read("*a"))
    assert(file:close())
    H.assert_false(source:find(fixtures.root, 1, true) ~= nil,
        "ordinary runner must not name hostile fixture root")
    H.assert_false(source:find("qa_hostile_fixtures", 1, true) ~= nil,
        "ordinary runner must not import hostile fixture manifest")
end)

suite:check("QF05 expected-red QA suites stay outside the ordinary runner", function()
    local file = assert(io.open("tests/run.lua", "rb"))
    local source = assert(file:read("*a"))
    assert(file:close())
    for _, forbidden in ipairs({
        "tests.test_qa_contract",
        "tests.test_qa_execution",
        "tests.test_qa_native_supervisor",
        "tests.test_qa_check_verdict",
        "tests.red_qa_hand",
    }) do
        H.assert_false(source:find(forbidden, 1, true) ~= nil,
            "expected-red suite leaked into ordinary runner: " .. forbidden)
    end
    H.assert_contains(source, "tests.test_qa_fixture_guard",
        "ordinary runner retains the inert fixture guard")
end)

suite:check("QF04 fixture reader has no execution primitive", function()
    local file = assert(io.open("tests/support/qa_hostile_fixtures.lua", "rb"))
    local source = assert(file:read("*a"))
    assert(file:close())
    for _, forbidden in ipairs({
        "dofile(",
        "loadfile(",
        "load(",
        "os.execute",
        "io.popen",
        "package.loadlib",
    }) do
        H.assert_false(source:find(forbidden, 1, true) ~= nil,
            "fixture reader execution primitive: " .. forbidden)
    end

    local candidate_count = 0
    local trusted_fault_count = 0
    for _, item in ipairs(fixtures.items) do
        if item.class == "candidate" then
            candidate_count = candidate_count + 1
        elseif item.class == "trusted_fault" then
            trusted_fault_count = trusted_fault_count + 1
        end
    end
    H.assert_eq(candidate_count, 17, "closed QN17 candidate count")
    H.assert_eq(trusted_fault_count, 9, "closed later trusted-fault count")

    local campaign = assert(io.open(
        "tests/run_qa_hostile_candidate_campaign.lua", "rb"))
    local campaign_source = assert(campaign:read("*a"))
    assert(campaign:close())
    H.assert_contains(campaign_source,
        'require("tests.support.qa_hostile_fixtures")',
        "dedicated campaign is the executable fixture reader")
    H.assert_contains(campaign_source,
        'require("tests.support.qa_provider_witness")',
        "campaign crosses the real first-hand witness boundary")
    for _, forbidden in ipairs({
        "arg[", "dofile(", "loadfile(", "load(", "os.execute",
        "io.popen", "package.loadlib",
    }) do
        H.assert_false(campaign_source:find(forbidden, 1, true) ~= nil,
            "campaign selector or direct execution primitive: " .. forbidden)
    end

    local makefile = assert(io.open("native/Makefile", "rb"))
    local make_source = assert(makefile:read("*a"))
    assert(makefile:close())
    H.assert_contains(make_source,
        "qa-supervisor-hostile-fixtures-test:",
        "QN17 owns one named Make target")
    H.assert_contains(make_source,
        "lua tests/run_qa_hostile_candidate_campaign.lua",
        "QN17 target invokes only the dedicated campaign")

    local trusted_campaign = assert(io.open(
        "tests/run_qa_trusted_fault_campaign.lua", "rb"))
    local trusted_source = assert(trusted_campaign:read("*a"))
    assert(trusted_campaign:close())
    H.assert_contains(trusted_source,
        'require("tests.support.qa_hostile_fixtures")',
        "QN18 campaign reads the same inert manifest")
    H.assert_contains(trusted_source,
        'require("runtime.qa_provider_witness")',
        "QN18 campaign crosses real source finality")
    H.assert_contains(trusted_source,
        "./tests/test_proc17_qa_trusted_faults",
        "QN18 campaign invokes one parameterless native driver")
    for _, forbidden in ipairs({"arg[", "item.pressure", "fault_kind="}) do
        H.assert_false(trusted_source:find(forbidden, 1, true) ~= nil,
            "QN18 selector or label authority: " .. forbidden)
    end
    H.assert_contains(make_source,
        "qa-supervisor-trusted-fault-test:",
        "QN18 owns one named Make target")
    H.assert_contains(make_source,
        "lua tests/run_qa_trusted_fault_campaign.lua",
        "QN18 target invokes only the dedicated campaign")

    local fault_header = assert(io.open(
        "native/tests/proc17_qa_fault_testing.h", "rb"))
    local fault_header_source = assert(fault_header:read("*a"))
    assert(fault_header:close())
    H.assert_contains(fault_header_source,
        "#ifndef PROC17_QA_FAULT_TESTING",
        "fault declarations fail closed outside the test build")
    H.assert_contains(fault_header_source,
        "proc17.qa.launcher.lua54.fault-test.v0",
        "fault launcher has a distinct ABI")
end)

suite:finish()
print("test_qa_fixture_guard ok")
