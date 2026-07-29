package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local catalog = require("tests.support.qa_control_catalog").native
local fixtures = require("tests.support.qa_hostile_fixtures")
local qa_process = require("runtime.qa_process")
local qa_schema = require("core.qa_schema")
local provider_ready, _, provider_build_code = os.execute(
    "make -C native qa-provider-shell"
)
local provider, provider_err
if provider_ready == true
    and (provider_build_code == nil or provider_build_code == 0) then
    provider, provider_err = H.optional_require("runtime.qa_provider")
else
    provider_err = "exact QA provider cold-build failed"
end
local suite = H.new("qa-native-supervisor")

local function read(path)
    local file, err = io.open(path, "rb")
    if not file then
        return nil, err
    end
    local bytes = file:read("*a")
    file:close()
    return bytes
end

local function command_ok(command)
    local ok, _, code = os.execute(command)
    return ok == true and (code == nil or code == 0)
end

local function require_source(path)
    local source, err = read(path)
    H.assert_true(source ~= nil, path .. " required: " .. tostring(err))
    return source
end

local function require_provider()
    provider = suite:require_module(provider, provider_err, "runtime.qa_provider")
    H.assert_true(type(provider.availability) == "function", "provider availability")
    H.assert_true(type(provider.probe) == "function", "provider probe")
    H.assert_true(type(provider.run) == "function", "provider run")
    return provider
end

local function native_witness(id, paths, target)
    for _, path in ipairs(paths or {}) do
        require_source(path)
    end
    H.assert_true(type(target) == "string" and target ~= "",
        id .. " native test target required")
    H.assert_true(command_ok("make -C native " .. target),
        id .. " exact native hostile witness remains red")
end

local probes = {}

probes.QN01 = function()
    H.assert_eq(#fixtures.items, 26, "closed hostile fixture count")
    for _, item in ipairs(fixtures.items) do
        local bytes = assert(fixtures.read(item))
        H.assert_eq(bytes:sub(1, #fixtures.marker), fixtures.marker,
            "inert marker: " .. item.id)
    end
end

probes.QN02 = function()
    H.assert_true(command_ok("make -C native qa-wire-contract-syntax"),
        "exact wire header constants must satisfy the compile-only contract")
end

probes.QN03 = function()
    native_witness("QN03", {
        "native/proc17_qa_wire.h",
        "native/tests/test_proc17_qa_wire.c",
    }, "qa-wire-test")
    native_witness("QN03-phase", {
        "native/proc17_qa_phase.h",
        "native/proc17_qa_phase.c",
        "native/tests/test_proc17_qa_phase.c",
    }, "qa-phase-test")
    native_witness("QN03-stream", {
        "native/proc17_qa_stream.h",
        "native/proc17_qa_stream.c",
        "native/tests/test_proc17_qa_stream.c",
    }, "qa-stream-test")
    native_witness("QN03-allocator", {
        "native/proc17_qa_status.h",
        "native/proc17_qa_status.c",
        "native/proc17_qa_allocator.h",
        "native/proc17_qa_allocator.c",
        "native/tests/test_proc17_qa_allocator.c",
    }, "qa-allocator-test")
    native_witness("QN03-controller", {
        "native/proc17_qa_controller.h",
        "native/proc17_qa_controller.c",
        "native/tests/test_proc17_qa_controller.c",
    }, "qa-controller-test")
    native_witness("QN03-scratch", {
        "native/proc17_qa_scratch.h",
        "native/proc17_qa_scratch.c",
        "native/tests/test_proc17_qa_scratch.c",
    }, "qa-scratch-test")
    native_witness("QN03-report", {
        "native/proc17_qa_report.h",
        "native/proc17_qa_report.c",
        "native/tests/test_proc17_qa_report.c",
    }, "qa-report-test")
    native_witness("QN03-launcher-v1", {
        "native/proc17_qa_launcher_v1.h",
        "native/proc17_qa_launcher_v1.c",
        "native/tests/test_proc17_qa_launcher_v1.c",
    }, "qa-launcher-v1-test")
    native_witness("QN03-execution", {
        "native/proc17_qa_supervisor.c",
        "native/proc17_qa_launcher_v1.c",
        "native/tests/test_proc17_qa_execution.c",
    }, "qa-execution-test")
end

probes.QN04 = function()
    local header = require_source("native/proc17_repository_handle_abi.h")
    H.assert_contains(header, "PROC17_REPOSITORY_HANDLE_MAGIC", "handle magic")
    H.assert_contains(header, "PROC17_REPOSITORY_HANDLE_ABI", "handle ABI")
    H.assert_contains(require_source("native/proc17_repository_fs.c"),
        "proc17_repository_handle_abi.h", "first hand owns shared prefix")
    H.assert_contains(require_source("native/proc17_qa_launcher.c"),
        "proc17_repository_handle_abi.h", "launcher borrows shared prefix")
    native_witness("QN04", {"native/tests/test_proc17_qa_launcher.c"},
        "qa-shared-abi-test")
end

probes.QN05 = function()
    local source = require_source("native/proc17_qa_launcher.c")
    for _, exact in ipairs({
        "luaopen_proc17_qa_launcher",
        "qa.native_launcher.v0",
        "proc17.qa.launcher.lua54.v0",
        "linux.qa_supervisor.lua54.v0",
        "run_lua54_test_suite",
    }) do
        H.assert_contains(source, exact, "closed launcher ABI field")
    end
    native_witness("QN05", {"native/tests/test_proc17_qa_launcher.c"},
        "qa-launcher-contract-test")
end

probes.QN06 = function()
    H.assert_true(command_ok("make -C native qa-static-closure-test"),
        "supervisor must be an exact static PIE with no dynamic closure")
end

probes.QN07 = function()
    native_witness("QN07", {"native/proc17_qa_launcher.c"},
        "qa-launcher-identity-test")
end

probes.QN08 = function()
    local source = require_source("native/proc17_qa_launcher.c")
    H.assert_contains(source, "execveat", "memory erasure boundary")
    native_witness("QN08", {"native/tests/test_proc17_qa_launcher.c"},
        "qa-launcher-exec-test")
end

probes.QN09 = function()
    native_witness("QN09", {
        "native/proc17_qa_launcher.c",
        "native/tests/test_proc17_qa_launcher.c",
    }, "qa-launcher-fd-test")
end

probes.QN10 = function()
    local source = require_source("native/proc17_qa_supervisor.c")
    for _, flag in ipairs({
        "CLONE_NEWUSER", "CLONE_NEWNS", "CLONE_NEWPID",
        "CLONE_NEWNET", "CLONE_NEWIPC", "CLONE_NEWUTS",
    }) do
        H.assert_contains(source, flag, "namespace flag")
    end
    native_witness("QN10", {"native/tests/test_proc17_qa_supervisor.c"},
        "qa-supervisor-namespace-test")
end

probes.QN11 = function()
    local source = require_source("native/proc17_qa_supervisor.c")
    H.assert_contains(source, "MOUNT_ATTR_RDONLY", "read-only source")
    H.assert_contains(source, "MOUNT_ATTR_NOEXEC", "non-executable source")
    native_witness("QN11", {"native/tests/test_proc17_qa_supervisor.c"},
        "qa-supervisor-mount-test")
end

probes.QN12 = function()
    local source = require_source("native/proc17_qa_supervisor.c")
    for _, exact in ipairs({"clearenv", "luaL_newstate", "package.cpath"}) do
        H.assert_contains(source, exact, "fresh Lua closure")
    end
    native_witness("QN12", {"native/tests/test_proc17_qa_supervisor.c"},
        "qa-supervisor-lua-test")
end

probes.QN13 = function()
    require_source("native/proc17_qa_policy.h")
    native_witness("QN13", {"native/tests/test_proc17_qa_supervisor.c"},
        "qa-supervisor-seccomp-test")
end

probes.QN14 = function()
    native_witness("QN14", {
        "native/proc17_qa_policy.h",
        "native/tests/test_proc17_qa_supervisor.c",
    }, "qa-supervisor-limits-test")
end

probes.QN15 = function()
    H.assert_true(command_ok("make -C native qa-host-contract-syntax"),
        "host ABI compile probe")
    local module = require_provider()
    local environment, err = module.probe()
    H.assert_true(environment ~= nil,
        "exercised production environment probe required: " .. tostring(err))
end

local hostile_targets = {
    QN16 = "qa-supervisor-basic-fixtures-test",
    QN17 = "qa-supervisor-hostile-fixtures-test",
    QN18 = "qa-supervisor-trusted-fault-test",
    QN20 = "qa-supervisor-leak-loop-test",
}

for id, target in pairs(hostile_targets) do
    probes[id] = function()
        require_provider()
        native_witness(id, {
            "native/tests/test_proc17_qa_supervisor.c",
            "native/tests/test_proc17_qa_launcher.c",
        }, target)
    end
end

probes.QN19 = function()
    local request = {
        protocol_version = "qa.native_run_request.v1",
        operation = "run_lua54_test_suite",
        transaction_id = "qa-provider-transaction:" .. string.rep("a", 64),
        witness_id = "qa-provider-witness:" .. string.rep("b", 64),
        profile_id = "qa.profile.lua54_test_suite.v0",
        environment_id = "qa-environment:" .. string.rep("c", 64),
        entrypoint_relative_path = "tests/run.lua",
        expected_exit_code = 0,
        resource_limits = qa_schema.hard_limits(),
    }
    local impossible = {
        protocol_version = "qa.native_run_error.v1",
        transaction_id = request.transaction_id,
        witness_id = request.witness_id,
        profile_id = request.profile_id,
        environment_id = request.environment_id,
        phase_ordinal = 1,
        class = "ambiguous",
        code = "reap_ambiguous",
        stage = "preflight",
        candidate_start_state = "not_started",
        cleanup_state = "complete",
        launcher_reaped = "complete",
        result_eof = "complete",
        event_truth_status = "runtime_confirmed",
    }
    local accepted, normalize_err = pcall(
        qa_process.normalize_error_v1, impossible, request)
    H.assert_false(accepted,
        "QN19 impossible causal error topology remains accepted")
    H.assert_contains(normalize_err, "causal topology",
        "QN19 topology rejection must name the violated boundary")

    require_provider()
    native_witness("QN19", {
        "native/tests/test_proc17_qa_cleanup_ambiguity.c",
        "tests/run_qa_cleanup_ambiguity_campaign.lua",
    }, "qa-supervisor-cleanup-ambiguity-test")
end

for _, control in ipairs(catalog) do
    local id, description = control[1], control[2]
    assert(type(probes[id]) == "function", "missing QA native probe " .. id)
    if not _G.PROC17_QA_RED_BATTERY and id == "QN20" then
        suite:skip(id .. " " .. description,
            "explicitly deferred after QN19 promotion")
    else
        suite:check(id .. " " .. description, probes[id])
    end
end

suite:finish()
print("test_qa_native_supervisor ok")
