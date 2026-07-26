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
end)

suite:finish()
print("test_qa_fixture_guard ok")
