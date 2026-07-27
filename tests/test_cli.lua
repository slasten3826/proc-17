package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local cli = require("cli.proc17")
local session_memory = require("runtime.session_memory")
local fixture = require("tests.support.repository_hands")
local native_build = require("tests.support.repository_native_build")
local roots = require("tests.support.owned_temp_root")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": " .. tostring(left)
            .. " ~= " .. tostring(right), 2)
    end
end

local session_root = "sandbox/test_cli_sessions"
local session_serial = 0
local lineage_nonce = 100

local session_api = {}
for key, value in pairs(session_memory) do
    session_api[key] = value
end
function session_api.create(id, options)
    if id == nil then
        session_serial = session_serial + 1
        id = "cli-test-session-" .. tostring(session_serial)
    end
    return session_memory.create(id, options)
end

local function deps(substrate, provider, runner)
    return {
        substrate = substrate,
        repository_provider = provider,
        tension_runner = runner,
        session_memory = session_api,
        session_options = {root = session_root},
        now = function() return 1785100000 end,
        random = function()
            lineage_nonce = lineage_nonce + 1
            return lineage_nonce
        end,
    }
end

local function capture(stdin)
    local state = {stdout = {}, stderr = {}}
    local io_context = {
        read_stdin = function() return stdin or "" end,
        read_file = function(path)
            local file, err = io.open(path, "rb")
            if not file then return nil, err end
            local content = file:read("*a")
            file:close()
            return content
        end,
        write_stdout = function(text) state.stdout[#state.stdout + 1] = text end,
        write_stderr = function(text) state.stderr[#state.stderr + 1] = text end,
    }
    function state:decoded()
        return json.decode(table.concat(self.stdout))
    end
    return io_context, state
end

local function run(argv, stdin, dependencies)
    local io_context, output = capture(stdin)
    local code = cli.main(argv, io_context, dependencies)
    return code, output:decoded(), table.concat(output.stdout), table.concat(output.stderr)
end

for index = 1, 12 do
    os.remove(session_root .. "/cli-test-session-" .. tostring(index) .. ".json")
end
os.remove(session_root .. "/cli-loud-session.json")

local plan_substrate = fixture.substrate(fixture.proposal({
    {key = "inspect", kind = "work_item", value = "inspect requirements"},
    {key = "design", kind = "work_item", value = "design one artifact"},
}, "work_sequence"))

local plan_code, plan_result, plan_json, plan_stderr = run(
    {"plan", "design a tiny program"},
    nil,
    deps(plan_substrate)
)
assert_eq(plan_code, 0, "CL06 fake plan exit")
assert_true(plan_result.ok, "CL06 fake plan completes")
assert_eq(plan_result.error, nil, "CL06 completed Packet has no error")
assert_eq(plan_result.mode, "plan", "CL06 plan mode")
assert_eq(plan_result.manifest.mode, "plan_delivery", "CL06 plan delivery")
assert_true(type(plan_result.trace) == "table" and #plan_result.trace > 0,
    "CL06 public trace")
assert_eq(plan_stderr, "", "CL06 stderr remains empty")
assert_true(plan_json:sub(1, 1) == "{" and plan_json:sub(-1) == "\n",
    "CL06 stdout is one JSON line")

local first_session_id = plan_result.session_id
local resumed_code, resumed = run(
    {"plan", "design another tiny program", "--session", first_session_id,
        "--label", "resumed"},
    nil,
    deps(plan_substrate)
)
assert_eq(resumed_code, 0, "CL02 resumed session exit")
assert_eq(resumed.session_id, first_session_id, "CL02 explicit session identity")
local resumed_session = assert(session_memory.load(first_session_id, {root = session_root}))
assert_eq(resumed_session.label, "resumed", "CL02 session label")
assert_eq(#resumed_session.packet_ids, 2, "CL12 terminal packets saved")
assert_eq(#resumed_session.lineage_ids, 2, "CL12 invocation lineages saved")

local fresh_code, fresh = run(
    {"plan", "design an isolated program"},
    nil,
    deps(plan_substrate)
)
assert_eq(fresh_code, 0, "CL01 second fresh session exit")
assert_true(fresh.session_id ~= first_session_id, "CL01 fresh sessions are isolated")

local stdin_code, stdin_result = run(
    {"plan"},
    "design a program from stdin",
    deps(plan_substrate)
)
assert_eq(stdin_code, 0, "CL13 stdin task exit")
assert_true(stdin_result.ok, "CL13 stdin task completes")

local file_code, file_result = run(
    {"plan", "--task-file", "README.md"},
    nil,
    deps(plan_substrate)
)
assert_eq(file_code, 0, "CL13 task-file exit")
assert_true(file_result.ok, "CL13 task-file completes")

local fake_provider, provider_state = fixture.fake_provider()
local build_substrate = fixture.substrate(fixture.proposal({
    {
        key = "hello",
        kind = "repository.create_text_file.v0",
        value = {path = "hello.lua", content = "return 'hello'\n"},
    },
}, "artifact_set"))
local build_code, build_result, build_json = run({
    "build",
    "create one hello module",
    "--project-base", "/trusted/proc17-cli-tests",
    "--repository", "fresh-project",
}, nil, deps(build_substrate, fake_provider))
assert_eq(build_code, 0, "CL07 fake build exit")
assert_true(build_result.ok, "CL07 fake build completes")
assert_eq(build_result.manifest.mode, "repository_delivery", "CL07 repository delivery")
assert_eq(provider_state.files["hello.lua"], "return 'hello'\n", "CL07 exact create effect")
for _, forbidden in ipairs({"grant_id", "repository_handle", "host_path", "userdata"}) do
    assert_true(not build_json:find(forbidden, 1, true),
        "CL10 output excludes " .. forbidden)
end

assert(native_build.ensure_loader_fixtures())
package.loaded["runtime.repository_provider"] = nil
local real_provider = require("runtime.repository_provider")
assert(roots.with_root(function(root)
    local real_code, real_result = run({
        "build",
        "create one hello module through the native provider",
        "--project-base", root.project_base,
        "--repository", "repo",
    }, nil, deps(build_substrate, real_provider))
    assert_eq(real_code, 0, "CL07 real-provider build exit")
    assert_eq(real_result.manifest.mode, "repository_delivery",
        "CL07 real-provider repository delivery")
    local file = assert(io.open(root.repository .. "/hello.lua", "rb"))
    local content = file:read("*a")
    file:close()
    assert_eq(content, "return 'hello'\n", "CL07 real-provider bytes")
    return true
end))

local exhausted_code, exhausted = run({
    "plan", "die after one paid step", "--max-steps", "1",
}, nil, deps(plan_substrate))
assert_eq(exhausted_code, 3, "CL08 non-complete Packet exit")
assert_true(not exhausted.ok, "CL08 non-complete Packet JSON")
assert_eq(exhausted.error.class, "packet_terminal", "CL08 terminal error class")
assert_eq(exhausted.death.cause, "budget_exhausted", "CL08 honest mortality")

local bad_code, bad = run({"plan", "task", "--router", "tree"}, nil, deps(plan_substrate))
assert_eq(bad_code, 2, "CL11 unknown flag exit")
assert_eq(bad.error.class, "input", "CL11 unknown flag classification")

local ambiguous_code = run({
    "plan", "task", "--task-file", "missing-task.txt",
}, nil, deps(plan_substrate))
assert_eq(ambiguous_code, 2, "CL03 task source ambiguity")

local missing_build_code = run({"build", "task"}, nil, deps(build_substrate, fake_provider))
assert_eq(missing_build_code, 2, "CL05 build coordinates required")

local plan_repo_code = run({
    "plan", "task", "--project-base", "/tmp", "--repository", "x",
}, nil, deps(plan_substrate))
assert_eq(plan_repo_code, 2, "CL04 plan rejects repository authority")

local loud_session = assert(session_memory.create("cli-loud-session"))
assert(session_memory.save(loud_session, {root = session_root}))
local loud_runner = {
    run = function()
        error("trusted runner exploded")
    end,
}
local loud_code, loud = run({
    "plan", "trigger loud failure", "--session", "cli-loud-session",
}, nil, deps(plan_substrate, nil, loud_runner))
assert_eq(loud_code, 4, "CL09 loud failure exit")
assert_eq(loud.error.stage, "runner", "CL09 loud failure stage")
local loud_after = assert(session_memory.load("cli-loud-session", {root = session_root}))
assert_eq(#loud_after.packet_ids, 0, "CL09 no invented Packet history")
assert_eq(#loud_after.grave.warnings + #loud_after.grave.bequests
    + #loud_after.grave.neutral, 0, "CL09 no invented grave")

print("test_cli ok")
