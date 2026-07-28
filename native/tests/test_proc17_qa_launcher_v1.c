#define _GNU_SOURCE

#include "../proc17_qa_launcher_v1.h"

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <sys/syscall.h>
#include <sys/wait.h>
#include <unistd.h>

static const unsigned char empty_sha256[PROC17_SHA256_BYTES] = {
    0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14,
    0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f, 0xb9, 0x24,
    0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c,
    0xa4, 0x95, 0x99, 0x1b, 0x78, 0x52, 0xb8, 0x55,
};

struct public_sequence {
    unsigned char bytes[2U * PROC17_QA_WIRE_MAX_FRAME_BYTES + 1U];
    size_t length;
    size_t first_write;
    int child_exit;
};

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

static int append_frame(
    struct public_sequence *sequence,
    uint16_t kind,
    const unsigned char *payload,
    uint32_t payload_bytes)
{
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t frame_bytes = 0U;
    if (proc17_qa_wire_encode_run_v1(kind, payload, payload,
            payload_bytes, frame, &frame_bytes) != 0
        || frame_bytes > sizeof(sequence->bytes) - sequence->length) {
        return -1;
    }
    memcpy(sequence->bytes + sequence->length, frame, frame_bytes);
    sequence->length += frame_bytes;
    return 0;
}

static int append_started(
    struct public_sequence *sequence,
    const struct proc17_qa_launcher_v1_expectation *expectation,
    int wrong_source)
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
    if (wrong_source) {
        proc17_qa_wire_put_u64(
            payload + PROC17_QA_V1_STARTED_STAGE_OFFSET + 8U, 99U);
    }
    return append_frame(sequence, PROC17_QA_WIRE_RUN_STARTED_V1,
        payload, sizeof(payload));
}

static int append_result(
    struct public_sequence *sequence,
    const struct proc17_qa_launcher_v1_expectation *expectation)
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
    return append_frame(sequence, PROC17_QA_WIRE_RUN_RESULT_V1,
        payload, sizeof(payload));
}

static int append_error(
    struct public_sequence *sequence,
    const struct proc17_qa_launcher_v1_expectation *expectation,
    int post_start)
{
    unsigned char payload[PROC17_QA_RUN_ERROR_V1_BYTES];
    memset(payload, 0, sizeof(payload));
    memcpy(payload, expectation->identity, sizeof(expectation->identity));
    proc17_qa_wire_put_u16(payload + PROC17_QA_V1_PHASE_OFFSET,
        post_start ? PROC17_QA_RUN_V1_PHASE_TERMINAL
                   : PROC17_QA_RUN_V1_PHASE_STARTED);
    proc17_qa_wire_put_u16(payload + 130U,
        PROC17_QA_RUN_V1_ERROR_UNAVAILABLE);
    proc17_qa_wire_put_u16(payload + 132U,
        PROC17_QA_RUN_V1_SUPERVISOR_UNAVAILABLE);
    proc17_qa_wire_put_u16(payload + 134U,
        post_start ? PROC17_QA_RUN_V1_ERROR_SUPERVISION
                   : PROC17_QA_RUN_V1_ERROR_PREFLIGHT);
    payload[136U] = post_start
        ? PROC17_QA_RUN_V1_TRUE : PROC17_QA_RUN_V1_FALSE;
    payload[137U] = PROC17_QA_RUN_V1_TRUE;
    if (post_start) {
        payload[139U] = 1U;
        fill_stage(payload + PROC17_QA_V1_ERROR_STAGE_OFFSET, expectation);
    }
    return append_frame(sequence, PROC17_QA_WIRE_RUN_ERROR_V1,
        payload, sizeof(payload));
}

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

static int collect_sequence(
    const struct public_sequence *sequence,
    const struct proc17_qa_launcher_v1_expectation *expectation,
    struct proc17_qa_launcher_v1_terminal *terminal)
{
    int descriptors[2] = {-1, -1};
    int pidfd = -1;
    pid_t child;
    int result;

    if (pipe2(descriptors, O_CLOEXEC) != 0) return -99;
    child = fork();
    if (child < 0) {
        close(descriptors[0]);
        close(descriptors[1]);
        return -99;
    }
    if (child == 0) {
        size_t first = sequence->first_write;
        close(descriptors[0]);
        if (first > sequence->length) first = sequence->length;
        if ((first != 0U
                && write_all(descriptors[1], sequence->bytes, first) != 0)
            || (sequence->length > first
                && write_all(descriptors[1], sequence->bytes + first,
                    sequence->length - first) != 0)
            || close(descriptors[1]) != 0) {
            _exit(126);
        }
        _exit(sequence->child_exit);
    }
    close(descriptors[1]);
    descriptors[1] = -1;
    pidfd = (int)syscall(SYS_pidfd_open, child, 0U);
    if (pidfd < 0) {
        kill(child, SIGKILL);
        waitpid(child, NULL, 0);
        close(descriptors[0]);
        return -99;
    }
    result = proc17_qa_launcher_collect_v1(child, pidfd, descriptors[0],
        5U, expectation, terminal);
    close(pidfd);
    close(descriptors[0]);
    return result;
}

static int contains_token(
    const unsigned char *bytes,
    size_t length)
{
    unsigned char token[PROC17_QA_WIRE_DIGEST_BYTES];
    size_t index;
    memset(token, 0x55, sizeof(token));
    if (length < sizeof(token)) return 0;
    for (index = 0U; index <= length - sizeof(token); index++) {
        if (memcmp(bytes + index, token, sizeof(token)) == 0) return 1;
    }
    return 0;
}

static int test_legal_sequences(void)
{
    struct proc17_qa_launcher_v1_expectation expectation;
    struct proc17_qa_launcher_v1_terminal terminal;
    struct public_sequence sequence;
    int status;

    fill_expectation(&expectation);
    memset(&sequence, 0, sizeof(sequence));
    if (append_started(&sequence, &expectation, 0) != 0
        || append_result(&sequence, &expectation) != 0) return -1;
    sequence.first_write = 17U;
    status = collect_sequence(&sequence, &expectation, &terminal);
    if (status != PROC17_QA_LAUNCHER_V1_OK
        || terminal.kind != PROC17_QA_LAUNCHER_V1_TERMINAL_RESULT
        || terminal.started_attested != 1U
        || terminal.launcher_reap_state != PROC17_QA_RUN_V1_TRUE
        || terminal.result_eof_state != PROC17_QA_RUN_V1_TRUE
        || contains_token(terminal.frame, terminal.frame_bytes)) return -1;

    memset(&sequence, 0, sizeof(sequence));
    if (append_error(&sequence, &expectation, 0) != 0) return -1;
    status = collect_sequence(&sequence, &expectation, &terminal);
    if (status != PROC17_QA_LAUNCHER_V1_OK
        || terminal.kind != PROC17_QA_LAUNCHER_V1_TERMINAL_ERROR
        || terminal.started_attested != 0U
        || terminal.phase != PROC17_QA_RUN_V1_PHASE_STARTED
        || terminal.candidate_start_state != PROC17_QA_RUN_V1_FALSE) return -1;

    memset(&sequence, 0, sizeof(sequence));
    if (append_started(&sequence, &expectation, 0) != 0
        || append_error(&sequence, &expectation, 1) != 0) return -1;
    status = collect_sequence(&sequence, &expectation, &terminal);
    return status == PROC17_QA_LAUNCHER_V1_OK
        && terminal.kind == PROC17_QA_LAUNCHER_V1_TERMINAL_ERROR
        && terminal.started_attested == 1U
        && terminal.phase == PROC17_QA_RUN_V1_PHASE_TERMINAL
        && terminal.candidate_start_state == PROC17_QA_RUN_V1_TRUE ? 0 : -1;
}

static int test_derived_errors(void)
{
    struct proc17_qa_launcher_v1_expectation expectation;
    struct proc17_qa_launcher_v1_terminal terminal;
    struct public_sequence sequence;
    int status;

    fill_expectation(&expectation);
    memset(&sequence, 0, sizeof(sequence));
    sequence.child_exit = 7;
    status = collect_sequence(&sequence, &expectation, &terminal);
    if (status != PROC17_QA_LAUNCHER_V1_OK
        || terminal.kind
            != PROC17_QA_LAUNCHER_V1_TERMINAL_DERIVED_ERROR
        || terminal.error_code != PROC17_QA_RUN_V1_SUPERVISOR_CRASHED
        || terminal.candidate_start_state != PROC17_QA_RUN_V1_FALSE) return -1;

    memset(&sequence, 0, sizeof(sequence));
    if (append_started(&sequence, &expectation, 0) != 0) return -1;
    status = collect_sequence(&sequence, &expectation, &terminal);
    return status == PROC17_QA_LAUNCHER_V1_OK
        && terminal.kind == PROC17_QA_LAUNCHER_V1_TERMINAL_DERIVED_ERROR
        && terminal.error_code == PROC17_QA_RUN_V1_TERMINAL_FRAME_MISSING
        && terminal.phase == PROC17_QA_RUN_V1_PHASE_TERMINAL
        && terminal.candidate_start_state == PROC17_QA_RUN_V1_TRUE ? 0 : -1;
}

static int expect_invariant(
    struct public_sequence *sequence,
    const struct proc17_qa_launcher_v1_expectation *expectation)
{
    struct proc17_qa_launcher_v1_terminal terminal;
    return collect_sequence(sequence, expectation, &terminal)
        == PROC17_QA_LAUNCHER_V1_TRUSTED_INVARIANT ? 0 : -1;
}

static int test_invariants(void)
{
    struct proc17_qa_launcher_v1_expectation expectation;
    struct public_sequence sequence;
    size_t first_frame;

    fill_expectation(&expectation);
    memset(&sequence, 0, sizeof(sequence));
    if (append_result(&sequence, &expectation) != 0
        || expect_invariant(&sequence, &expectation) != 0) return -1;

    memset(&sequence, 0, sizeof(sequence));
    if (append_started(&sequence, &expectation, 0) != 0) return -1;
    first_frame = sequence.length;
    if (append_started(&sequence, &expectation, 0) != 0
        || expect_invariant(&sequence, &expectation) != 0) return -1;

    memset(&sequence, 0, sizeof(sequence));
    if (append_started(&sequence, &expectation, 1) != 0
        || expect_invariant(&sequence, &expectation) != 0) return -1;

    memset(&sequence, 0, sizeof(sequence));
    if (append_started(&sequence, &expectation, 0) != 0
        || append_result(&sequence, &expectation) != 0) return -1;
    sequence.bytes[sequence.length++] = 0xa5U;
    if (expect_invariant(&sequence, &expectation) != 0) return -1;

    memset(&sequence, 0, sizeof(sequence));
    if (append_started(&sequence, &expectation, 0) != 0
        || append_result(&sequence, &expectation) != 0) return -1;
    sequence.length = first_frame + 20U;
    if (expect_invariant(&sequence, &expectation) != 0) return -1;

    memset(&sequence, 0, sizeof(sequence));
    if (append_started(&sequence, &expectation, 0) != 0
        || append_result(&sequence, &expectation) != 0) return -1;
    sequence.child_exit = 9;
    return expect_invariant(&sequence, &expectation);
}

static int test_setup_failure_still_reaps(void)
{
    struct proc17_qa_launcher_v1_expectation expectation;
    struct proc17_qa_launcher_v1_terminal terminal;
    int descriptors[2];
    int stale_descriptor;
    int pidfd;
    pid_t child;
    int status;

    fill_expectation(&expectation);
    if (pipe2(descriptors, O_CLOEXEC) != 0) return -1;
    child = fork();
    if (child < 0) {
        close(descriptors[0]);
        close(descriptors[1]);
        return -1;
    }
    if (child == 0) {
        close(descriptors[0]);
        close(descriptors[1]);
        for (;;) pause();
    }
    pidfd = (int)syscall(SYS_pidfd_open, child, 0U);
    stale_descriptor = descriptors[0];
    close(descriptors[0]);
    close(descriptors[1]);
    if (pidfd < 0) {
        kill(child, SIGKILL);
        waitpid(child, NULL, 0);
        return -1;
    }
    status = proc17_qa_launcher_collect_v1(child, pidfd,
        stale_descriptor, 5U, &expectation, &terminal);
    close(pidfd);
    errno = 0;
    return status == PROC17_QA_LAUNCHER_V1_SYSTEM_FAILURE
        && waitpid(child, NULL, WNOHANG) < 0 && errno == ECHILD ? 0 : -1;
}

int main(void)
{
    if (test_legal_sequences() != 0
        || test_derived_errors() != 0
        || test_invariants() != 0
        || test_setup_failure_still_reaps() != 0) {
        return 1;
    }
    puts("proc17 QA launcher v1 phase machine ok");
    return 0;
}
