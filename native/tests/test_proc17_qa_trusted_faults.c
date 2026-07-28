#define _GNU_SOURCE

#include "proc17_qa_fault_testing.h"

#include "../proc17_qa_launcher_v1.h"
#include "../proc17_qa_policy.h"

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/wait.h>
#include <unistd.h>

static const unsigned char empty_sha256[PROC17_SHA256_BYTES] = {
    0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14,
    0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f, 0xb9, 0x24,
    0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c,
    0xa4, 0x95, 0x99, 0x1b, 0x78, 0x52, 0xb8, 0x55,
};

enum malformed_variant {
    VARIANT_SHORT = 0,
    VARIANT_OVERSIZED,
    VARIANT_WRONG_MAGIC,
    VARIANT_WRONG_VERSION,
    VARIANT_UNKNOWN_KIND,
    VARIANT_DIGEST_MISMATCH,
    VARIANT_TRAILING,
    VARIANT_COUNT,
};

struct root_identity {
    uint64_t device;
    uint64_t inode;
    uint64_t mount_id;
};

static int write_all(int descriptor, const unsigned char *bytes, size_t length)
{
    while (length > 0U) {
        ssize_t written = write(descriptor, bytes, length);
        if (written < 0 && errno == EINTR) continue;
        if (written <= 0) return -1;
        bytes += (size_t)written;
        length -= (size_t)written;
    }
    return 0;
}

static void close_if_open(int *descriptor)
{
    if (*descriptor >= 0) {
        (void)close(*descriptor);
        *descriptor = -1;
    }
}

static int high_duplicate(int descriptor)
{
    return fcntl(descriptor, F_DUPFD_CLOEXEC, 10);
}

static int observe_root(int descriptor, struct root_identity *identity)
{
    struct stat status;
    struct statx extended;

    memset(&extended, 0, sizeof(extended));
    if (fstat(descriptor, &status) != 0 || !S_ISDIR(status.st_mode)
        || statx(descriptor, "", AT_EMPTY_PATH | AT_STATX_SYNC_AS_STAT,
            STATX_TYPE | STATX_MNT_ID, &extended) != 0
        || (extended.stx_mask & STATX_MNT_ID) == 0) {
        return -1;
    }
    identity->device = (uint64_t)(uintmax_t)status.st_dev;
    identity->inode = (uint64_t)(uintmax_t)status.st_ino;
    identity->mount_id = extended.stx_mnt_id;
    return 0;
}

static void fill_expectation(
    struct proc17_qa_launcher_v1_expectation *expectation)
{
    memset(expectation, 0, sizeof(*expectation));
    memset(expectation->identity, 0x11, 32U);
    memset(expectation->identity + 32U, 0x22, 32U);
    memset(expectation->identity + 64U, 0x33, 32U);
    memset(expectation->identity + 96U, 0x44, 32U);
    expectation->source_device = 11U;
    expectation->source_inode = 22U;
    expectation->source_mount_id = 33U;
    expectation->source_mount_policy_flags = 15U;
}

static void fill_stage(
    unsigned char stage[PROC17_QA_SOURCE_STAGE_V1_BYTES],
    const struct proc17_qa_launcher_v1_expectation *expectation)
{
    memset(stage, 0, PROC17_QA_SOURCE_STAGE_V1_BYTES);
    proc17_qa_wire_put_u16(stage, 1U);
    proc17_qa_wire_put_u32(stage + 4U,
        expectation->source_mount_policy_flags);
    proc17_qa_wire_put_u64(stage + 8U, expectation->source_device);
    proc17_qa_wire_put_u64(stage + 16U, expectation->source_inode);
    proc17_qa_wire_put_u64(stage + 24U, expectation->source_mount_id);
    proc17_qa_wire_put_u64(stage + 32U, expectation->source_device);
    proc17_qa_wire_put_u64(stage + 40U, expectation->source_inode);
    proc17_qa_wire_put_u64(stage + 48U, 44U);
    proc17_qa_wire_put_u64(stage + 56U, expectation->source_device);
    proc17_qa_wire_put_u64(stage + 64U, expectation->source_inode);
    proc17_qa_wire_put_u64(stage + 72U, 44U);
    stage[80U] = 1U;
    stage[81U] = 1U;
}

static void fill_stream(unsigned char *stream)
{
    memset(stream, 0, PROC17_QA_STREAM_MEASUREMENT_V1_BYTES);
    proc17_qa_wire_put_u64(stream + 16U, 1024U);
    memcpy(stream + 24U, empty_sha256, sizeof(empty_sha256));
    stream[57U] = 1U;
}

static int encode_started(
    const struct proc17_qa_launcher_v1_expectation *expectation,
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES],
    size_t *frame_bytes)
{
    unsigned char payload[PROC17_QA_RUN_STARTED_V1_BYTES];

    memset(payload, 0, sizeof(payload));
    memcpy(payload, expectation->identity, sizeof(expectation->identity));
    proc17_qa_wire_put_u16(payload + PROC17_QA_V1_PHASE_OFFSET,
        PROC17_QA_RUN_V1_PHASE_STARTED);
    proc17_qa_wire_put_u16(payload + 130U, 1U);
    payload[132U] = 1U;
    payload[133U] = PROC17_QA_RUN_V1_PREPARED_UNDER_POLICY;
    memset(payload + 136U, 0x55, PROC17_QA_WIRE_DIGEST_BYTES);
    fill_stage(payload + PROC17_QA_V1_STARTED_STAGE_OFFSET, expectation);
    return proc17_qa_wire_encode_run_v1(PROC17_QA_WIRE_RUN_STARTED_V1,
        payload, payload, sizeof(payload), frame, frame_bytes);
}

static int encode_result(
    const struct proc17_qa_launcher_v1_expectation *expectation,
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES],
    size_t *frame_bytes)
{
    unsigned char payload[PROC17_QA_RUN_RESULT_V1_BYTES];
    unsigned char *resource;
    unsigned char *scratch;

    memset(payload, 0, sizeof(payload));
    memcpy(payload, expectation->identity, sizeof(expectation->identity));
    proc17_qa_wire_put_u16(payload + PROC17_QA_V1_PHASE_OFFSET,
        PROC17_QA_RUN_V1_PHASE_TERMINAL);
    proc17_qa_wire_put_u16(payload + 130U, PROC17_QA_RUN_CONTAINED);
    proc17_qa_wire_put_u16(payload + 132U, PROC17_QA_RUN_EXPECTED_EXIT);
    proc17_qa_wire_put_u16(payload + 134U, PROC17_QA_TERMINATION_EXIT);
    proc17_qa_wire_put_u32(payload + 136U, 0U);
    proc17_qa_wire_put_u32(payload + 140U, UINT32_MAX);
    proc17_qa_wire_put_u16(payload + 144U, PROC17_QA_RUN_EXPECTED_EXIT);
    proc17_qa_wire_put_u64(payload + 148U, 1U);
    memset(payload + PROC17_QA_V1_RESULT_FINALITY_OFFSET, 1, 8U);
    fill_stream(payload + PROC17_QA_V1_RESULT_STDOUT_OFFSET);
    fill_stream(payload + PROC17_QA_V1_RESULT_STDERR_OFFSET);
    resource = payload + PROC17_QA_V1_RESULT_RESOURCE_OFFSET;
    proc17_qa_wire_put_u64(resource + 32U, 268435456U);
    proc17_qa_wire_put_u64(resource + 48U, 67108864U);
    proc17_qa_wire_put_u64(resource + 56U, 1U);
    proc17_qa_wire_put_u64(resource + 64U, 64U);
    proc17_qa_wire_put_u64(resource + 72U, 16777216U);
    scratch = payload + PROC17_QA_V1_RESULT_SCRATCH_OFFSET;
    proc17_qa_wire_put_u64(scratch + 16U, 67108864U);
    proc17_qa_wire_put_u64(scratch + 24U, 4096U);
    scratch[34U] = 1U;
    fill_stage(payload + PROC17_QA_V1_RESULT_STAGE_OFFSET, expectation);
    return proc17_qa_wire_encode_run_v1(PROC17_QA_WIRE_RUN_RESULT_V1,
        payload, payload, sizeof(payload), frame, frame_bytes);
}

static void refresh_digest(unsigned char *frame, size_t frame_bytes)
{
    uint32_t payload_bytes;
    size_t before_digest;
    unsigned char digest[PROC17_QA_WIRE_DIGEST_BYTES];

    if (frame_bytes < PROC17_QA_WIRE_ENVELOPE_BYTES) return;
    payload_bytes = proc17_qa_wire_get_u32(frame + 12U);
    before_digest = 48U + (size_t)payload_bytes;
    if (before_digest + sizeof(digest) != frame_bytes) return;
    proc17_sha256_bytes(frame, before_digest, digest);
    memcpy(frame + before_digest, digest, sizeof(digest));
}

static size_t malformed_frame(
    const unsigned char *base,
    size_t base_bytes,
    enum malformed_variant variant,
    unsigned char output[PROC17_QA_WIRE_MAX_FRAME_BYTES + 1U])
{
    size_t length = base_bytes;

    memset(output, 0, PROC17_QA_WIRE_MAX_FRAME_BYTES + 1U);
    memcpy(output, base, base_bytes);
    switch (variant) {
    case VARIANT_SHORT:
        return 16U;
    case VARIANT_OVERSIZED:
        memset(output, 0, PROC17_QA_WIRE_ENVELOPE_BYTES);
        memcpy(output, base, 48U);
        proc17_qa_wire_put_u32(output + 12U,
            PROC17_QA_WIRE_MAX_FRAME_BYTES);
        return PROC17_QA_WIRE_ENVELOPE_BYTES;
    case VARIANT_WRONG_MAGIC:
        output[0] ^= 0xffU;
        refresh_digest(output, length);
        break;
    case VARIANT_WRONG_VERSION:
        proc17_qa_wire_put_u16(output + 8U, PROC17_QA_WIRE_VERSION + 1U);
        refresh_digest(output, length);
        break;
    case VARIANT_UNKNOWN_KIND:
        proc17_qa_wire_put_u16(output + 10U, 0xffffU);
        refresh_digest(output, length);
        break;
    case VARIANT_DIGEST_MISMATCH:
        output[length - 1U] ^= 0xffU;
        break;
    case VARIANT_TRAILING:
        output[length++] = 0xa5U;
        break;
    case VARIANT_COUNT:
        return 0U;
    }
    return length;
}

static int collect_bytes(
    const unsigned char *bytes,
    size_t length,
    int child_exit,
    int pre_reap,
    const struct proc17_qa_launcher_v1_expectation *expectation,
    struct proc17_qa_launcher_v1_terminal *terminal)
{
    int descriptors[2] = {-1, -1};
    int pidfd = -1;
    pid_t child = -1;
    int wait_status = 0;
    int result = PROC17_QA_LAUNCHER_V1_SYSTEM_FAILURE;

    if (pipe2(descriptors, O_CLOEXEC) != 0) return result;
    child = fork();
    if (child < 0) goto cleanup;
    if (child == 0) {
        close(descriptors[0]);
        if (length != 0U && write_all(descriptors[1], bytes, length) != 0) {
            _exit(126);
        }
        (void)close(descriptors[1]);
        _exit(child_exit);
    }
    close_if_open(&descriptors[1]);
    pidfd = (int)syscall(SYS_pidfd_open, child, 0U);
    if (pidfd < 0) goto cleanup_child;
    if (pre_reap) {
        pid_t observed;
        do {
            observed = waitpid(child, &wait_status, 0);
        } while (observed < 0 && errno == EINTR);
        if (observed != child) goto cleanup_child;
    }
    result = proc17_qa_launcher_collect_v1(child, pidfd, descriptors[0],
        3U, expectation, terminal);
    child = -1;
    goto cleanup;

cleanup_child:
    if (child > 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
        child = -1;
    }
cleanup:
    if (child > 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
    }
    close_if_open(&pidfd);
    close_if_open(&descriptors[0]);
    close_if_open(&descriptors[1]);
    return result;
}

static int build_request(
    int source,
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
    struct root_identity root;
    unsigned char payload[PROC17_QA_RUN_REQUEST_V1_FIXED_BYTES
        + sizeof(entrypoint) - 1U];
    size_t index;

    if (observe_root(source, &root) != 0) return -1;
    memset(payload, 0, sizeof(payload));
    memset(payload, 0x11, 32U);
    memset(payload + 32U, 0x22, 32U);
    memset(payload + 64U, 0x33, 32U);
    memset(payload + 96U, 0x44, 32U);
    proc17_qa_wire_put_u64(payload + 128U, root.device);
    proc17_qa_wire_put_u64(payload + 136U, root.inode);
    proc17_qa_wire_put_u64(payload + 144U, root.mount_id);
    for (index = 0U; index < PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS; index++) {
        proc17_qa_wire_put_u64(payload + 152U + index * 8U, limits[index]);
    }
    proc17_qa_wire_put_u32(payload + 232U, 0U);
    proc17_qa_wire_put_u16(payload + 236U, sizeof(entrypoint) - 1U);
    memcpy(payload + PROC17_QA_RUN_REQUEST_V1_FIXED_BYTES,
        entrypoint, sizeof(entrypoint) - 1U);
    return proc17_qa_wire_encode_run_v1(PROC17_QA_WIRE_RUN_REQUEST_V1,
        payload, payload, sizeof(payload), frame, frame_bytes);
}

static void supervisor_child(
    int source,
    int request,
    int result,
    int supervisor)
{
    char *const arguments[] = {
        (char *)"proc17_qa_supervisor", (char *)"run", NULL};
    char *const environment[] = {NULL};

    if (dup3(source, 3, 0) < 0 || dup3(request, 4, 0) < 0
        || dup3(result, 5, 0) < 0 || dup3(supervisor, 6, 0) < 0
        || syscall(SYS_close_range, 7U, UINT_MAX, 0U) != 0) {
        _exit(125);
    }
    execveat(6, "", arguments, environment, AT_EMPTY_PATH);
    _exit(126);
}

static int supervisor_rejects_request(
    int source,
    const unsigned char *request,
    size_t request_bytes)
{
    int request_pipe[2] = {-1, -1};
    int result_pipe[2] = {-1, -1};
    int supervisor = -1;
    int child_source = -1;
    int child_request = -1;
    int child_result = -1;
    int child_supervisor = -1;
    unsigned char observed[1];
    ssize_t result_bytes;
    int wait_status = 0;
    pid_t child = -1;
    int accepted = -1;

    supervisor = open("./proc17_qa_supervisor",
        O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
    if (supervisor < 0 || pipe2(request_pipe, O_CLOEXEC) != 0
        || pipe2(result_pipe, O_CLOEXEC) != 0
        || (child_source = high_duplicate(source)) < 0
        || (child_request = high_duplicate(request_pipe[0])) < 0
        || (child_result = high_duplicate(result_pipe[1])) < 0
        || (child_supervisor = high_duplicate(supervisor)) < 0
        || write_all(request_pipe[1], request, request_bytes) != 0
        || close(request_pipe[1]) != 0) {
        request_pipe[1] = -1;
        goto cleanup;
    }
    request_pipe[1] = -1;
    child = fork();
    if (child < 0) goto cleanup;
    if (child == 0) {
        supervisor_child(child_source, child_request, child_result,
            child_supervisor);
    }
    close_if_open(&child_source);
    close_if_open(&child_request);
    close_if_open(&child_result);
    close_if_open(&child_supervisor);
    close_if_open(&request_pipe[0]);
    close_if_open(&result_pipe[1]);
    do {
        result_bytes = read(result_pipe[0], observed, sizeof(observed));
    } while (result_bytes < 0 && errno == EINTR);
    do {
        accepted = waitpid(child, &wait_status, 0);
    } while (accepted < 0 && errno == EINTR);
    if (accepted == child) child = -1;
    accepted = accepted >= 0 && result_bytes == 0
        && WIFEXITED(wait_status) && WEXITSTATUS(wait_status) == 127 ? 0 : -1;

cleanup:
    if (child > 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
    }
    close_if_open(&request_pipe[0]);
    close_if_open(&request_pipe[1]);
    close_if_open(&result_pipe[0]);
    close_if_open(&result_pipe[1]);
    close_if_open(&supervisor);
    close_if_open(&child_source);
    close_if_open(&child_request);
    close_if_open(&child_result);
    close_if_open(&child_supervisor);
    return accepted;
}

static int test_wrong_supervisor_identity(void)
{
    return proc17_qa_fault_test_supervisor_identity_accepts(
            "./proc17_qa_supervisor") == 1
        && proc17_qa_fault_test_supervisor_identity_accepts(
            "./tests/proc17_qa_supervisor_fault_test") == 0 ? 0 : -1;
}

static int test_malformed_requests(void)
{
    char root[] = "/tmp/proc17-qa-qn18-request-XXXXXX";
    unsigned char valid[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char malformed[PROC17_QA_WIRE_MAX_FRAME_BYTES + 1U];
    size_t valid_bytes = 0U;
    int source = -1;
    int result = -1;
    enum malformed_variant variant;

    if (mkdtemp(root) == NULL) return -1;
    source = open(root, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (source < 0 || build_request(source, valid, &valid_bytes) != 0) {
        goto cleanup;
    }
    for (variant = VARIANT_SHORT; variant < VARIANT_COUNT; variant++) {
        size_t bytes = malformed_frame(
            valid, valid_bytes, variant, malformed);
        if (bytes == 0U
            || supervisor_rejects_request(source, malformed, bytes) != 0) {
            goto cleanup;
        }
    }
    result = 0;

cleanup:
    close_if_open(&source);
    (void)rmdir(root);
    return result;
}

static int test_malformed_results(void)
{
    struct proc17_qa_launcher_v1_expectation expectation;
    struct proc17_qa_launcher_v1_terminal terminal;
    unsigned char started[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char result[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char malformed[PROC17_QA_WIRE_MAX_FRAME_BYTES + 1U];
    unsigned char sequence[2U * PROC17_QA_WIRE_MAX_FRAME_BYTES + 1U];
    size_t started_bytes = 0U;
    size_t result_bytes = 0U;
    enum malformed_variant variant;

    fill_expectation(&expectation);
    if (encode_started(&expectation, started, &started_bytes) != 0
        || encode_result(&expectation, result, &result_bytes) != 0) {
        return -1;
    }
    for (variant = VARIANT_SHORT; variant < VARIANT_COUNT; variant++) {
        size_t malformed_bytes = malformed_frame(
            result, result_bytes, variant, malformed);
        memcpy(sequence, started, started_bytes);
        memcpy(sequence + started_bytes, malformed, malformed_bytes);
        if (malformed_bytes == 0U
            || collect_bytes(sequence, started_bytes + malformed_bytes,
                0, 0, &expectation, &terminal)
                != PROC17_QA_LAUNCHER_V1_TRUSTED_INVARIANT) {
            return -1;
        }
    }
    return 0;
}

static int test_crash(int after_start)
{
    struct proc17_qa_launcher_v1_expectation expectation;
    struct proc17_qa_launcher_v1_terminal terminal;
    unsigned char started[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t started_bytes = 0U;
    int status;

    fill_expectation(&expectation);
    if (after_start
        && encode_started(&expectation, started, &started_bytes) != 0) {
        return -1;
    }
    status = collect_bytes(started, after_start ? started_bytes : 0U,
        7, 0, &expectation, &terminal);
    return status == PROC17_QA_LAUNCHER_V1_OK
        && terminal.kind == PROC17_QA_LAUNCHER_V1_TERMINAL_DERIVED_ERROR
        && terminal.error_class == PROC17_QA_RUN_V1_ERROR_UNAVAILABLE
        && terminal.error_code == PROC17_QA_RUN_V1_SUPERVISOR_CRASHED
        && terminal.error_stage == PROC17_QA_RUN_V1_ERROR_SUPERVISION
        && terminal.candidate_start_state == (after_start
            ? PROC17_QA_RUN_V1_TRUE : PROC17_QA_RUN_V1_FALSE)
        && terminal.launcher_reap_state == PROC17_QA_RUN_V1_TRUE
        && terminal.result_eof_state == PROC17_QA_RUN_V1_TRUE ? 0 : -1;
}

static int test_lost_result_pipe(void)
{
    struct proc17_qa_launcher_v1_expectation expectation;
    struct proc17_qa_launcher_v1_terminal terminal;
    int result_descriptor = -1;
    int pidfd = -1;
    pid_t child = -1;
    int status;

    fill_expectation(&expectation);
    result_descriptor = open("/tmp",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (result_descriptor < 0) return -1;
    child = fork();
    if (child < 0) goto fail;
    if (child == 0) {
        for (;;) pause();
    }
    pidfd = (int)syscall(SYS_pidfd_open, child, 0U);
    if (pidfd < 0) goto fail;
    status = proc17_qa_launcher_collect_v1(child, pidfd, result_descriptor,
        3U, &expectation, &terminal);
    child = -1;
    close_if_open(&pidfd);
    close_if_open(&result_descriptor);
    return status == PROC17_QA_LAUNCHER_V1_OK
        && terminal.kind == PROC17_QA_LAUNCHER_V1_TERMINAL_DERIVED_ERROR
        && terminal.error_class == PROC17_QA_RUN_V1_ERROR_AMBIGUOUS
        && terminal.error_code == PROC17_QA_RUN_V1_RESULT_PIPE_LOST
        && terminal.error_stage == PROC17_QA_RUN_V1_ERROR_SUPERVISION
        && terminal.candidate_start_state == PROC17_QA_RUN_V1_FALSE
        && terminal.launcher_reap_state == PROC17_QA_RUN_V1_TRUE
        && terminal.result_eof_state == PROC17_QA_RUN_V1_UNKNOWN ? 0 : -1;

fail:
    if (child > 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
    }
    close_if_open(&pidfd);
    close_if_open(&result_descriptor);
    return -1;
}

static int test_reap_ambiguity(void)
{
    struct proc17_qa_launcher_v1_expectation expectation;
    struct proc17_qa_launcher_v1_terminal terminal;
    unsigned char started[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t started_bytes = 0U;
    int status;

    fill_expectation(&expectation);
    if (encode_started(&expectation, started, &started_bytes) != 0) return -1;
    status = collect_bytes(
        started, started_bytes, 0, 1, &expectation, &terminal);
    return status == PROC17_QA_LAUNCHER_V1_OK
        && terminal.kind == PROC17_QA_LAUNCHER_V1_TERMINAL_DERIVED_ERROR
        && terminal.error_class == PROC17_QA_RUN_V1_ERROR_AMBIGUOUS
        && terminal.error_code == PROC17_QA_RUN_V1_REAP_AMBIGUOUS
        && terminal.error_stage == PROC17_QA_RUN_V1_ERROR_CLEANUP
        && terminal.candidate_start_state == PROC17_QA_RUN_V1_TRUE
        && terminal.launcher_reap_state == PROC17_QA_RUN_V1_UNKNOWN
        && terminal.result_eof_state == PROC17_QA_RUN_V1_TRUE ? 0 : -1;
}

static void record(
    const char *id,
    const char *boundary,
    const char *start,
    const char *terminal,
    unsigned int variants)
{
    printf("QN18_NATIVE_V0|%s|%s|%s|%s|%u\n",
        id, boundary, start, terminal, variants);
}

int main(int argument_count, char **arguments)
{
    static const enum proc17_qa_trusted_fault_case cases[] = {
        PROC17_QA_FAULT_WRONG_SUPERVISOR_IDENTITY,
        PROC17_QA_FAULT_MALFORMED_REQUEST_FRAMES,
        PROC17_QA_FAULT_MALFORMED_RESULT_FRAMES,
        PROC17_QA_FAULT_CRASH_BEFORE_START,
        PROC17_QA_FAULT_CRASH_AFTER_START,
        PROC17_QA_FAULT_LOST_RESULT_PIPE,
        PROC17_QA_FAULT_WAIT_REAP_AMBIGUITY,
    };
    size_t index;

    (void)arguments;
    if (argument_count != 1) return 2;
    for (index = 0U; index < sizeof(cases) / sizeof(cases[0]); index++) {
        switch (cases[index]) {
        case PROC17_QA_FAULT_WRONG_SUPERVISOR_IDENTITY:
            if (test_wrong_supervisor_identity() != 0) return 1;
            record("trusted-wrong-supervisor-identity",
                "launcher_identity_rejected", "not_started", "no_terminal", 1U);
            break;
        case PROC17_QA_FAULT_MALFORMED_REQUEST_FRAMES:
            if (test_malformed_requests() != 0) return 1;
            record("trusted-malformed-request-frames",
                "supervisor_request_rejected", "not_started", "no_started",
                VARIANT_COUNT);
            break;
        case PROC17_QA_FAULT_MALFORMED_RESULT_FRAMES:
            if (test_malformed_results() != 0) return 1;
            record("trusted-malformed-result-frames", "trusted_invariant",
                "started", "loud", VARIANT_COUNT);
            break;
        case PROC17_QA_FAULT_CRASH_BEFORE_START:
            if (test_crash(0) != 0) return 1;
            record("trusted-crash-before-start", "supervisor_crashed",
                "not_started", "infrastructure", 1U);
            break;
        case PROC17_QA_FAULT_CRASH_AFTER_START:
            if (test_crash(1) != 0) return 1;
            record("trusted-crash-after-start", "supervisor_crashed",
                "started", "infrastructure", 1U);
            break;
        case PROC17_QA_FAULT_LOST_RESULT_PIPE:
            if (test_lost_result_pipe() != 0) return 1;
            record("trusted-lost-result-pipe", "result_pipe_lost",
                "not_started", "infrastructure", 1U);
            break;
        case PROC17_QA_FAULT_WAIT_REAP_AMBIGUITY:
            if (test_reap_ambiguity() != 0) return 1;
            record("trusted-wait-reap-ambiguity", "reap_ambiguous",
                "started", "infrastructure", 1U);
            break;
        }
    }
    return 0;
}
