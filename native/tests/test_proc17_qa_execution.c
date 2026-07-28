#define _GNU_SOURCE

#define main proc17_qa_supervisor_embedded_main
#include "../proc17_qa_supervisor.c"
#undef main

#include "../proc17_qa_launcher_v1.h"

static int test_high_duplicate(int descriptor)
{
    return fcntl(descriptor, F_DUPFD_CLOEXEC, 10);
}

static void test_supervisor_exec_child(
    int source,
    int request,
    int result,
    int supervisor,
    const char *mode)
{
    char *const arguments[] = {
        (char *)"proc17_qa_supervisor", (char *)mode, NULL};
    char *const environment[] = {NULL};
    if (dup3(source, 3, 0) < 0 || dup3(request, 4, 0) < 0
        || dup3(result, 5, 0) < 0 || dup3(supervisor, 6, 0) < 0
        || syscall(SYS_close_range, 7U, UINT_MAX, 0U) != 0) {
        _exit(126);
    }
    execveat(6, "", arguments, environment, AT_EMPTY_PATH);
    _exit(127);
}

static int write_file_at(int directory, const char *name, const char *bytes)
{
    int descriptor = openat(directory, name,
        O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0600);
    size_t length = strlen(bytes);
    int result = -1;
    if (descriptor >= 0 && write_exact(descriptor, bytes, length) == 0
        && close(descriptor) == 0) {
        result = 0;
        descriptor = -1;
    }
    if (descriptor >= 0) close(descriptor);
    return result;
}

static void fill_v1_identity(
    struct proc17_qa_phase_identity *identity,
    struct proc17_qa_run_request *request)
{
    memset(identity, 0, sizeof(*identity));
    memset(request, 0, sizeof(*request));
    memset(identity->transaction, 0x11, sizeof(identity->transaction));
    memset(identity->witness, 0x22, sizeof(identity->witness));
    memset(identity->profile, 0x33, sizeof(identity->profile));
    memset(identity->environment, 0x44, sizeof(identity->environment));
    memcpy(request->transaction, identity->transaction,
        sizeof(request->transaction));
    memcpy(request->witness, identity->witness, sizeof(request->witness));
    memcpy(request->profile, identity->profile, sizeof(request->profile));
    memcpy(request->environment, identity->environment,
        sizeof(request->environment));
    request->expected_exit = 0U;
    strcpy(request->entrypoint, "tests/run.lua");
}

static int read_public_started(
    int descriptor,
    const struct proc17_qa_phase_identity *identity,
    const unsigned char token[PROC17_QA_WIRE_DIGEST_BYTES])
{
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    struct proc17_qa_wire_view view;
    size_t used = 0U;
    for (;;) {
        ssize_t observed = read(descriptor, frame + used, sizeof(frame) - used);
        if (observed > 0) {
            used += (size_t)observed;
            if (used == sizeof(frame)) return -1;
            continue;
        }
        if (observed < 0 && errno == EINTR) continue;
        if (observed != 0) return -1;
        break;
    }
    return proc17_qa_wire_decode_run_v1(frame, used, &view) == 0
        && view.kind == PROC17_QA_WIRE_RUN_STARTED_V1
        && memcmp(view.payload, identity, sizeof(*identity)) == 0
        && memcmp(view.payload + 136U, token,
            PROC17_QA_WIRE_DIGEST_BYTES) == 0 ? 0 : -1;
}

static int test_fault_free_controller(void)
{
    static const char candidate[] =
        "assert(_VERSION == 'Lua 5.4')\n"
        "io.stdout:write('e5-controller-ok\\n')\n";
    char root[] = "/tmp/proc17-qa-e5-XXXXXX";
    char tests_path[PATH_MAX];
    struct proc17_qa_phase_identity identity;
    struct proc17_qa_run_request request;
    struct proc17_qa_wire_view result_view;
    unsigned char token[PROC17_QA_WIRE_DIGEST_BYTES];
    unsigned char report[PROC17_QA_CONTROLLER_REPORT_BYTES];
    unsigned char result_frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t result_bytes = 0U;
    int public_descriptors[2] = {-1, -1};
    int root_descriptor = -1;
    int tests_descriptor = -1;
    int controller_wait_status = 0;
    int result = -1;

    fill_v1_identity(&identity, &request);
    memset(token, 0x55, sizeof(token));
    if (mkdtemp(root) == NULL
        || snprintf(tests_path, sizeof(tests_path), "%s/tests", root)
            >= (int)sizeof(tests_path)
        || mkdir(tests_path, 0700) != 0) {
        return -1;
    }
    root_descriptor = open(root,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    tests_descriptor = openat(root_descriptor, "tests",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (root_descriptor < 0 || tests_descriptor < 0
        || write_file_at(tests_descriptor, "run.lua", candidate) != 0
        || close(tests_descriptor) != 0
        || pipe2(public_descriptors, O_CLOEXEC) != 0) {
        tests_descriptor = -1;
        goto cleanup;
    }
    tests_descriptor = -1;
    if (proc17_qa_run_namespace_v1_unrouted(root_descriptor,
            public_descriptors[1], &request, &identity, token,
            report, &controller_wait_status) != 0) {
        root_descriptor = -1;
        goto cleanup;
    }
    root_descriptor = -1;
    if (close(public_descriptors[1]) != 0) goto cleanup;
    public_descriptors[1] = -1;
    if (read_public_started(public_descriptors[0], &identity, token) != 0
        || close(public_descriptors[0]) != 0) {
        public_descriptors[0] = -1;
        goto cleanup;
    }
    public_descriptors[0] = -1;
    if (proc17_qa_controller_report_finalize(report, &identity, token,
            controller_wait_status, 1U, result_frame, &result_bytes) != 0
        || proc17_qa_wire_decode_run_v1(
            result_frame, result_bytes, &result_view) != 0
        || result_view.kind != PROC17_QA_WIRE_RUN_RESULT_V1
        || proc17_qa_wire_get_u16(result_view.payload + 132U)
            != PROC17_QA_RUN_EXPECTED_EXIT
        || proc17_qa_wire_get_u64(
            result_view.payload + PROC17_QA_V1_RESULT_STDOUT_OFFSET) == 0U) {
        goto cleanup;
    }
    result = 0;

cleanup:
    close_if_open(&public_descriptors[0]);
    close_if_open(&public_descriptors[1]);
    close_if_open(&tests_descriptor);
    close_if_open(&root_descriptor);
    (void)unlinkat(AT_FDCWD, tests_path, AT_REMOVEDIR);
    {
        char candidate_path[PATH_MAX];
        if (snprintf(candidate_path, sizeof(candidate_path),
                "%s/tests/run.lua", root) < (int)sizeof(candidate_path)) {
            (void)unlink(candidate_path);
        }
    }
    (void)rmdir(tests_path);
    (void)rmdir(root);
    return result;
}

static int build_run_v1_request(
    int source_descriptor,
    const struct proc17_qa_phase_identity *identity,
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES],
    size_t *frame_bytes)
{
    static const uint64_t limits[PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS] = {
        PROC17_QA_WALL_TIME_MS, PROC17_QA_CPU_TIME_MS,
        PROC17_QA_ADDRESS_SPACE_BYTES, PROC17_QA_MAX_PROCESSES,
        PROC17_QA_MAX_OPEN_FILES, PROC17_QA_MAX_FILE_BYTES,
        PROC17_QA_SCRATCH_BYTES, PROC17_QA_SCRATCH_ENTRIES,
        PROC17_QA_STDOUT_BYTES, PROC17_QA_STDERR_BYTES,
    };
    static const char entrypoint[] = "tests/run.lua";
    struct proc17_qa_root_identity root_identity;
    unsigned char payload[PROC17_QA_RUN_REQUEST_V1_FIXED_BYTES
        + sizeof(entrypoint) - 1U];
    size_t index;

    if (observe_root(source_descriptor, &root_identity) != 0) return -1;
    memset(payload, 0, sizeof(payload));
    memcpy(payload, identity, sizeof(*identity));
    proc17_qa_wire_put_u64(payload + 128U, root_identity.device);
    proc17_qa_wire_put_u64(payload + 136U, root_identity.inode);
    proc17_qa_wire_put_u64(payload + 144U, root_identity.mount_id);
    for (index = 0U; index < PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS; index++) {
        proc17_qa_wire_put_u64(payload + 152U + index * 8U, limits[index]);
    }
    proc17_qa_wire_put_u32(payload + 232U, 0U);
    proc17_qa_wire_put_u16(payload + 236U, sizeof(entrypoint) - 1U);
    memcpy(payload + PROC17_QA_RUN_REQUEST_V1_FIXED_BYTES,
        entrypoint, sizeof(entrypoint) - 1U);
    return proc17_qa_wire_encode_run_v1(PROC17_QA_WIRE_RUN_REQUEST_V1,
        identity->transaction, payload, sizeof(payload), frame, frame_bytes);
}

static int test_top_level_public_sequence(void)
{
    static const char candidate[] = "assert(true)\n";
    char root[] = "/tmp/proc17-qa-e5-top-XXXXXX";
    char tests_path[PATH_MAX];
    char candidate_path[PATH_MAX];
    struct proc17_qa_phase_identity identity;
    struct proc17_qa_run_request request;
    struct proc17_qa_root_identity root_identity;
    struct proc17_qa_launcher_v1_expectation expectation;
    struct proc17_qa_launcher_v1_terminal public_terminal;
    struct proc17_qa_wire_view terminal;
    unsigned char request_frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t request_bytes = 0U;
    int request_descriptors[2] = {-1, -1};
    int result_descriptors[2] = {-1, -1};
    int source_descriptor = -1;
    int tests_descriptor = -1;
    int supervisor_descriptor = -1;
    int child_source = -1;
    int child_request = -1;
    int child_result = -1;
    int child_supervisor = -1;
    int pidfd = -1;
    pid_t child = -1;
    int result = -1;

    fill_v1_identity(&identity, &request);
    if (mkdtemp(root) == NULL
        || snprintf(tests_path, sizeof(tests_path), "%s/tests", root)
            >= (int)sizeof(tests_path)
        || snprintf(candidate_path, sizeof(candidate_path),
            "%s/tests/run.lua", root) >= (int)sizeof(candidate_path)
        || mkdir(tests_path, 0700) != 0) {
        return -1;
    }
    source_descriptor = open(root,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    tests_descriptor = openat(source_descriptor, "tests",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    supervisor_descriptor = open("./proc17_qa_supervisor",
        O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
    if (source_descriptor < 0 || tests_descriptor < 0
        || supervisor_descriptor < 0
        || observe_root(source_descriptor, &root_identity) != 0
        || write_file_at(tests_descriptor, "run.lua", candidate) != 0
        || close(tests_descriptor) != 0
        || build_run_v1_request(source_descriptor, &identity,
            request_frame, &request_bytes) != 0
        || pipe2(request_descriptors, O_CLOEXEC) != 0
        || pipe2(result_descriptors, O_CLOEXEC) != 0
        || (child_source = test_high_duplicate(source_descriptor)) < 0
        || (child_request = test_high_duplicate(request_descriptors[0])) < 0
        || (child_result = test_high_duplicate(result_descriptors[1])) < 0
        || (child_supervisor = test_high_duplicate(supervisor_descriptor)) < 0
        || write_exact(request_descriptors[1],
            request_frame, request_bytes) != 0
        || close(request_descriptors[1]) != 0) {
        tests_descriptor = -1;
        request_descriptors[1] = -1;
        goto cleanup;
    }
    memset(&expectation, 0, sizeof(expectation));
    memcpy(expectation.identity, &identity, sizeof(identity));
    expectation.source_device = root_identity.device;
    expectation.source_inode = root_identity.inode;
    expectation.source_mount_id = root_identity.mount_id;
    expectation.source_mount_policy_flags = PROC17_QA_SOURCE_MOUNT_REQUIRED;
    tests_descriptor = -1;
    request_descriptors[1] = -1;
    child = fork();
    if (child < 0) goto cleanup;
    if (child == 0) {
        test_supervisor_exec_child(child_source, child_request, child_result,
            child_supervisor, "run");
    }
    close_if_open(&child_source);
    close_if_open(&child_request);
    close_if_open(&child_result);
    close_if_open(&child_supervisor);
    close_if_open(&source_descriptor);
    close_if_open(&supervisor_descriptor);
    close_if_open(&request_descriptors[0]);
    close_if_open(&result_descriptors[1]);
    pidfd = (int)syscall(SYS_pidfd_open, child, 0U);
    if (pidfd < 0
        || proc17_qa_launcher_collect_v1(child, pidfd,
            result_descriptors[0], 40U, &expectation,
            &public_terminal) != PROC17_QA_LAUNCHER_V1_OK) {
        if (pidfd >= 0) child = -1;
        goto cleanup;
    }
    child = -1;
    if (public_terminal.kind != PROC17_QA_LAUNCHER_V1_TERMINAL_RESULT
        || public_terminal.started_attested != 1U
        || public_terminal.launcher_reap_state != PROC17_QA_RUN_V1_TRUE
        || public_terminal.result_eof_state != PROC17_QA_RUN_V1_TRUE
        || proc17_qa_wire_decode_run_v1(public_terminal.frame,
            public_terminal.frame_bytes, &terminal) != 0
        || terminal.kind != PROC17_QA_WIRE_RUN_RESULT_V1
        || memcmp(terminal.payload, &identity, sizeof(identity)) != 0
        || proc17_qa_wire_get_u16(terminal.payload + 132U)
            != PROC17_QA_RUN_EXPECTED_EXIT) {
        goto cleanup;
    }
    result = 0;

cleanup:
    if (child > 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
    }
    close_if_open(&request_descriptors[0]);
    close_if_open(&request_descriptors[1]);
    close_if_open(&result_descriptors[0]);
    close_if_open(&result_descriptors[1]);
    close_if_open(&source_descriptor);
    close_if_open(&tests_descriptor);
    close_if_open(&supervisor_descriptor);
    close_if_open(&child_source);
    close_if_open(&child_request);
    close_if_open(&child_result);
    close_if_open(&child_supervisor);
    close_if_open(&pidfd);
    (void)unlink(candidate_path);
    (void)rmdir(tests_path);
    (void)rmdir(root);
    return result;
}

static int test_known_prestart_error(void)
{
    struct proc17_qa_phase_identity identity;
    struct proc17_qa_run_request request;
    struct proc17_qa_wire_view view;
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    int descriptors[2];
    ssize_t observed;

    fill_v1_identity(&identity, &request);
    if (pipe2(descriptors, O_CLOEXEC) != 0
        || emit_run_error_v1(descriptors[1], &identity,
            PROC17_QA_RUN_V1_PHASE_STARTED,
            PROC17_QA_RUN_V1_ERROR_UNAVAILABLE,
            PROC17_QA_RUN_V1_SUPERVISOR_UNAVAILABLE,
            PROC17_QA_RUN_V1_ERROR_PREFLIGHT,
            PROC17_QA_RUN_V1_FALSE, PROC17_QA_RUN_V1_TRUE, NULL) != 0
        || close(descriptors[1]) != 0) {
        close(descriptors[0]);
        return -1;
    }
    do {
        observed = read(descriptors[0], frame, sizeof(frame));
    } while (observed < 0 && errno == EINTR);
    close(descriptors[0]);
    return observed > 0
        && proc17_qa_wire_decode_run_v1(
            frame, (size_t)observed, &view) == 0
        && view.kind == PROC17_QA_WIRE_RUN_ERROR_V1
        && view.payload[136U] == PROC17_QA_RUN_V1_FALSE
        && view.payload[137U] == PROC17_QA_RUN_V1_TRUE ? 0 : -1;
}

int main(void)
{
    if (test_fault_free_controller() != 0
        || test_top_level_public_sequence() != 0
        || test_known_prestart_error() != 0) {
        return 1;
    }
    puts("proc17 QA fault-free controller and public v1 sequence ok");
    return 0;
}
