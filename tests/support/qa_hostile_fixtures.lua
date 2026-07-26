local fixtures = {}

fixtures.root = "native/tests/qa_fixtures"
fixtures.marker = "-- PROC17_QA_HOSTILE_FIXTURE_V0: INERT DATA; DO NOT EXECUTE DIRECTLY"
fixtures.max_bytes = 16384

fixtures.items = {
    {id = "candidate-clean-exit", class = "candidate", file = "candidate_clean_exit.fixture", pressure = "clean exit 0"},
    {id = "candidate-nonzero-exit", class = "candidate", file = "candidate_nonzero_exit.fixture", pressure = "nonzero exit"},
    {id = "candidate-lua-error", class = "candidate", file = "candidate_lua_error.fixture", pressure = "Lua error"},
    {id = "candidate-cpu-loop", class = "candidate", file = "candidate_cpu_loop.fixture", pressure = "infinite CPU loop"},
    {id = "candidate-wall-loop", class = "candidate", file = "candidate_wall_loop.fixture", pressure = "infinite wall loop"},
    {id = "candidate-allocator-exhaustion", class = "candidate", file = "candidate_allocator_exhaustion.fixture", pressure = "allocator exhaustion"},
    {id = "candidate-stdout-flood", class = "candidate", file = "candidate_stdout_flood.fixture", pressure = "stdout flood"},
    {id = "candidate-stderr-flood", class = "candidate", file = "candidate_stderr_flood.fixture", pressure = "stderr flood"},
    {id = "candidate-scratch-exhaustion", class = "candidate", file = "candidate_scratch_exhaustion.fixture", pressure = "scratch byte and inode exhaustion"},
    {id = "candidate-source-mutation", class = "candidate", file = "candidate_source_mutation.fixture", pressure = "source create overwrite rename unlink"},
    {id = "candidate-host-path-probe", class = "candidate", file = "candidate_host_path_probe.fixture", pressure = "host and sibling path probes"},
    {id = "candidate-socket-attempt", class = "candidate", file = "candidate_socket_attempt.fixture", pressure = "socket and network attempt"},
    {id = "candidate-fork-attempt", class = "candidate", file = "candidate_fork_attempt.fixture", pressure = "fork and clone attempt"},
    {id = "candidate-exec-attempt", class = "candidate", file = "candidate_exec_attempt.fixture", pressure = "exec attempt"},
    {id = "candidate-native-module-attempt", class = "candidate", file = "candidate_native_module_attempt.fixture", pressure = "native module load attempt"},
    {id = "candidate-fd-escape", class = "candidate", file = "candidate_fd_escape.fixture", pressure = "descriptor enumeration and escape"},
    {id = "candidate-sigsys", class = "candidate", file = "candidate_sigsys.fixture", pressure = "policy violation and SIGSYS classification"},

    {id = "trusted-wrong-launcher-abi", class = "trusted_fault", file = "trusted_wrong_launcher_abi.fixture", pressure = "wrong launcher ABI"},
    {id = "trusted-wrong-supervisor-identity", class = "trusted_fault", file = "trusted_wrong_supervisor_identity.fixture", pressure = "wrong supervisor digest or ABI"},
    {id = "trusted-malformed-request-frames", class = "trusted_fault", file = "trusted_malformed_request_frames.fixture", pressure = "short oversized corrupt request frames"},
    {id = "trusted-malformed-result-frames", class = "trusted_fault", file = "trusted_malformed_result_frames.fixture", pressure = "short oversized corrupt result frames"},
    {id = "trusted-crash-before-start", class = "trusted_fault", file = "trusted_crash_before_start.fixture", pressure = "supervisor crash before candidate start"},
    {id = "trusted-crash-after-start", class = "trusted_fault", file = "trusted_crash_after_start.fixture", pressure = "supervisor crash after candidate start"},
    {id = "trusted-lost-result-pipe", class = "trusted_fault", file = "trusted_lost_result_pipe.fixture", pressure = "lost result pipe"},
    {id = "trusted-wait-reap-ambiguity", class = "trusted_fault", file = "trusted_wait_reap_ambiguity.fixture", pressure = "forced wait and reap ambiguity"},
    {id = "trusted-postflight-source-drift", class = "trusted_fault", file = "trusted_postflight_source_drift.fixture", pressure = "trusted postflight source drift"},
}

function fixtures.path(item)
    assert(type(item) == "table" and type(item.file) == "string", "fixture item required")
    assert(not item.file:find("/", 1, true), "fixture filename must be local")
    assert(item.file:match("^[a-z0-9_]+%.fixture$"), "inert .fixture filename required")
    return fixtures.root .. "/" .. item.file
end

function fixtures.read(item)
    local path = fixtures.path(item)
    local file, open_err = io.open(path, "rb")
    if not file then
        return nil, open_err
    end
    local bytes = file:read(fixtures.max_bytes + 1)
    file:close()
    if not bytes then
        return nil, "fixture read failed"
    end
    if #bytes > fixtures.max_bytes then
        return nil, "fixture exceeds inert byte ceiling"
    end
    return bytes
end

return fixtures
