package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local owned = require("tests.support.owned_temp_root")
local suite = H.new("qa-residue-observer-lua")

local module_path = "./native/tests/proc17_qa_residue_observer.so"
local module_symbol = "luaopen_proc17_qa_residue_observer"
local expected_api = {
    protocol_version = "string",
    open = "function",
    bind_owned_root = "function",
    capture = "function",
    compare = "function",
}
local projection_fields = {
    protocol_version = true,
    snapshot_id = true,
    scope = true,
    parent_fd_set_id = true,
    parent_fd_count = true,
    parent_namespace_set_id = true,
    direct_live_child_count = true,
    direct_zombie_count = true,
    matching_supervisor_process_count = true,
    unresolved_supervisor_zombie_count = true,
    qa_host_mount_count = true,
    owned_source_identity_id = true,
    owned_source_host_mount_count = true,
    owned_root_set_id = true,
    owned_root_count = true,
    event_truth_status = true,
}
local delta_fields = {
    protocol_version = true,
    baseline_snapshot_id = true,
    observed_snapshot_id = true,
    fd_opened = true,
    fd_missing = true,
    fd_identity_changed = true,
    fd_flags_changed = true,
    parent_namespace_changed = true,
    direct_live_children = true,
    direct_zombies = true,
    matching_supervisor_processes = true,
    unresolved_supervisor_zombies = true,
    qa_host_mounts = true,
    owned_source_host_mounts = true,
    owned_roots_added = true,
    owned_roots_missing = true,
    exact = true,
    event_truth_status = true,
}

local function load_observer()
    local loader, load_err = package.loadlib(module_path, module_symbol)
    if not loader then
        return nil, "observer module absent: " .. tostring(load_err)
    end
    local ok, value = pcall(loader)
    if not ok then
        return nil, "observer module load failed: " .. tostring(value)
    end
    if type(value) ~= "table" then
        return nil, "observer module did not return its closed API"
    end
    return value
end

local observer, observer_err = load_observer()

local function require_observer()
    return suite:require_module(
        observer, observer_err, "qa.residue_observer.lua54.v0")
end

local function assert_locked_userdata(value, label)
    H.assert_eq(type(value), "userdata", label .. " must be opaque userdata")
    local public_metatable = getmetatable(value)
    H.assert_true(public_metatable == false or type(public_metatable) == "string",
        label .. " metatable must be locked")
end

local function assert_typed_error(value, err, label)
    H.assert_nil(value, label .. " must reject")
    H.assert_eq(type(err), "table", label .. " must return a typed error")
    H.assert_true(type(err.code) == "string" and err.code ~= "",
        label .. " error code")
    H.assert_true(type(err.stage) == "string" and err.stage ~= "",
        label .. " error stage")
end

local function assert_closed_projection(record, allowed, label)
    H.assert_eq(type(record), "table", label .. " must be a projection")
    for key in pairs(record) do
        H.assert_true(allowed[key] == true,
            label .. " exposes undeclared field " .. tostring(key))
    end
end

local function open_session()
    local api = require_observer()
    local session, err = api.open()
    H.assert_true(session ~= nil,
        "observer session must open: " .. tostring(err and err.code or err))
    assert_locked_userdata(session, "observer session")
    return api, session
end

suite:check("RL01 closed API and fixed protocol", function()
    local api = require_observer()
    for key, expected_type in pairs(expected_api) do
        H.assert_eq(type(api[key]), expected_type, "observer API field " .. key)
    end
    H.assert_eq(api.protocol_version, "qa.residue_observer.lua54.v0",
        "observer Lua protocol")
    for key in pairs(api) do
        H.assert_true(expected_api[key] ~= nil,
            "observer API exposes undeclared field " .. tostring(key))
    end
end)

suite:check("RL02 session and baseline snapshot are opaque", function()
    local api, session = open_session()
    local snapshot, projection, err = api.capture(session, "baseline", nil)
    H.assert_true(snapshot ~= nil,
        "baseline capture must succeed: " .. tostring(err and err.code or err))
    assert_locked_userdata(snapshot, "baseline snapshot")
    assert_closed_projection(projection, projection_fields, "baseline projection")
    H.assert_eq(projection.protocol_version, "qa.residue_host_projection.v0",
        "baseline projection protocol")
    H.assert_eq(projection.scope, "baseline", "baseline scope")
    H.assert_eq(projection.event_truth_status, "runtime_confirmed",
        "baseline truth status")
end)

suite:check("RL03 caller configuration and arbitrary roots are rejected", function()
    local api, session = open_session()
    local configured, configured_err = api.open({test_root_parent = "/"})
    assert_typed_error(configured, configured_err, "configured open")
    local subject, subject_err = api.bind_owned_root(session, {
        protocol_version = "repository.test_owned_root_identity.v0",
        path = "/tmp/not-a-proc17-owned-root",
        device = "1",
        inode = "1",
        mount_id = "1",
    })
    assert_typed_error(subject, subject_err, "arbitrary root binding")
end)

suite:check("RL04 scope order rejects caller-created phase claims", function()
    local api, session = open_session()
    local snapshot, err = api.capture(session, "iteration", nil)
    assert_typed_error(snapshot, err, "iteration without verified subject")
    local unknown, unknown_err = api.capture(session, "unknown", nil)
    assert_typed_error(unknown, unknown_err, "unknown scope")
end)

suite:check("RL05 verified root crosses iteration and cleanup phases", function()
    local api, session = open_session()
    H.assert_eq(type(owned.identity), "function", "owned-root identity support")
    H.assert_eq(type(owned.absent), "function", "owned-root absence support")
    H.assert_eq(type(owned.with_root_phases), "function",
        "owned-root phase support")
    assert(owned.use_prebuilt_helper())
    local subject
    local iteration_snapshot
    local ok, phase_err = owned.with_root_phases(function(root)
        local identity = assert(owned.identity(root))
        subject = assert(api.bind_owned_root(session, identity))
        assert_locked_userdata(subject, "owned-root subject")
        local projection
        iteration_snapshot, projection = assert(api.capture(
            session, "iteration", subject))
        assert_locked_userdata(iteration_snapshot, "iteration snapshot")
        assert_closed_projection(projection, projection_fields,
            "iteration projection")
        H.assert_eq(projection.scope, "iteration", "iteration scope")
        local premature, premature_err = api.capture(
            session, "post_cleanup", subject)
        assert_typed_error(premature, premature_err,
            "post-cleanup capture while root is live")
        return true
    end, function(prior_identity)
        assert(owned.absent(prior_identity))
        local post_snapshot, projection = assert(api.capture(
            session, "post_cleanup", subject))
        assert_locked_userdata(post_snapshot, "post-cleanup snapshot")
        assert_closed_projection(projection, projection_fields,
            "post-cleanup projection")
        H.assert_eq(projection.scope, "post_cleanup", "post-cleanup scope")
        return true
    end)
    H.assert_true(ok ~= nil, "owned-root phases: " .. tostring(phase_err))
end)

suite:check("RL06 comparison is session-bound and direction-bound", function()
    local api, first_session = open_session()
    local _, second_session = open_session()
    local first_baseline = assert(api.capture(first_session, "baseline", nil))
    local second_baseline = assert(api.capture(second_session, "baseline", nil))
    local same_scope, same_scope_err = api.compare(first_baseline, first_baseline)
    assert_typed_error(same_scope, same_scope_err, "baseline-to-baseline compare")
    local cross_session, cross_session_err = api.compare(
        first_baseline, second_baseline)
    assert_typed_error(cross_session, cross_session_err,
        "cross-session compare")
end)

suite:check("RL07 final delta is detached scalar evidence", function()
    local api, session = open_session()
    local baseline = assert(api.capture(session, "baseline", nil))
    local final_snapshot, projection = assert(api.capture(
        session, "final", nil))
    local delta = assert(api.compare(baseline, final_snapshot))
    assert_closed_projection(projection, projection_fields, "final projection")
    assert_closed_projection(delta, delta_fields, "final delta")
    H.assert_eq(delta.protocol_version, "qa.residue_host_delta.v0",
        "delta protocol")
    H.assert_eq(delta.event_truth_status, "runtime_confirmed",
        "delta truth status")
    H.assert_eq(type(delta.exact), "boolean", "derived exact bit")
end)

suite:finish()
print("test_qa_repeated_residue_observer ok")
