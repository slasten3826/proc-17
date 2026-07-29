#define _GNU_SOURCE

#include "../proc17_qa_launcher_v1.h"
#include "../proc17_qa_policy.h"
#include "../proc17_qa_report.h"
#include "../proc17_qa_status.h"

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <stdint.h>
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

static int collect_bytes(
    const unsigned char *bytes,
    size_t length,
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
        _exit(0);
    }
    close_if_open(&descriptors[1]);
    pidfd = (int)syscall(SYS_pidfd_open, child, 0U);
    if (pidfd < 0) goto cleanup_child;
    if (pre_reap != 0) {
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
    }
cleanup:
    close_if_open(&pidfd);
    close_if_open(&descriptors[0]);
    close_if_open(&descriptors[1]);
    return result;
}

static int empty_stream(
    uint64_t limit,
    struct proc17_qa_stream_measurement *measurement)
{
    memset(measurement, 0, sizeof(*measurement));
    measurement->limit_bytes = limit;
    memcpy(measurement->prefix_digest, empty_sha256,
        sizeof(measurement->prefix_digest));
    measurement->eof_observed = 1U;
    return 0;
}

static int make_local_phase(
    struct proc17_qa_phase_state *phase,
    const struct proc17_qa_phase_identity *identity,
    const unsigned char token[PROC17_QA_WIRE_DIGEST_BYTES],
    const unsigned char stage[PROC17_QA_SOURCE_STAGE_V1_BYTES])
{
    int result_pipe[2];
    int descriptor;
    struct proc17_qa_started_writer_state writer;
    struct proc17_qa_status_message ready = {
        .kind = PROC17_QA_STATUS_READY,
        .sequence = 1U,
    };
    unsigned char discard[512];
    ssize_t observed;
    int member;

    proc17_qa_phase_init(phase);
    proc17_qa_started_writer_init(&writer);
    if (pipe2(result_pipe, O_CLOEXEC) != 0) return -1;
    descriptor = result_pipe[1];
    if (proc17_qa_phase_emit_started_and_close(
            &writer, &descriptor, identity, token, stage) != 0
        || descriptor != -1) {
        close(result_pipe[0]);
        return -1;
    }
    do {
        observed = read(result_pipe[0], discard, sizeof(discard));
    } while (observed < 0 && errno == EINTR);
    if (observed <= 0 || close(result_pipe[0]) != 0
        || proc17_qa_status_accept_ready(&ready, phase) != 0
        || proc17_qa_phase_authorize_candidate(phase) != 0
        || proc17_qa_phase_claim_first_cause(phase,
            PROC17_QA_RUN_EXPECTED_EXIT, 0U) != PROC17_QA_CAUSE_SET) {
        return -1;
    }
    for (member = PROC17_QA_FINAL_CANDIDATE_TERMINAL;
            member <= PROC17_QA_FINAL_SCRATCH_OBSERVED; member++) {
        if (proc17_qa_phase_mark_finality(phase,
                (enum proc17_qa_phase_finality)member) != 0) {
            return -1;
        }
    }
    return proc17_qa_phase_controller_report_ready(phase) ? 0 : -1;
}

static int build_result_report(
    const struct proc17_qa_launcher_v1_expectation *expectation,
    const unsigned char token[PROC17_QA_WIRE_DIGEST_BYTES],
    unsigned char report[PROC17_QA_CONTROLLER_REPORT_BYTES])
{
    struct proc17_qa_phase_identity identity;
    struct proc17_qa_phase_state phase;
    struct proc17_qa_stream_measurement stdout_measurement;
    struct proc17_qa_stream_measurement stderr_measurement;
    struct proc17_qa_candidate_metrics metrics;
    struct proc17_qa_allocator_snapshot allocator;
    struct proc17_qa_scratch_measurement scratch;
    struct proc17_qa_controller_report_input input;
    unsigned char stage[PROC17_QA_SOURCE_STAGE_V1_BYTES];

    memcpy(&identity, expectation->identity, sizeof(identity));
    fill_stage(stage, expectation);
    if (make_local_phase(&phase, &identity, token, stage) != 0
        || empty_stream(PROC17_QA_STDOUT_BYTES, &stdout_measurement) != 0
        || empty_stream(PROC17_QA_STDERR_BYTES, &stderr_measurement) != 0) {
        return -1;
    }
    memset(&metrics, 0, sizeof(metrics));
    metrics.wall_time_ms = 1U;
    memset(&allocator, 0, sizeof(allocator));
    allocator.ceiling_bytes = PROC17_QA_RUNTIME_HEAP_BYTES;
    memset(&scratch, 0, sizeof(scratch));
    scratch.limit_bytes = PROC17_QA_SCRATCH_BYTES;
    scratch.limit_entries = PROC17_QA_SCRATCH_ENTRIES;
    scratch.inventory_complete = 1U;
    memset(&input, 0, sizeof(input));
    input.identity = &identity;
    input.process_token = token;
    input.phase = &phase;
    input.termination.kind = PROC17_QA_TERMINATION_EXIT;
    input.termination.exit_code = 0U;
    input.termination.signal_number = UINT32_MAX;
    input.stdout_measurement = &stdout_measurement;
    input.stderr_measurement = &stderr_measurement;
    input.candidate_metrics = &metrics;
    input.allocator = &allocator;
    input.scratch = &scratch;
    input.source_stage = stage;
    input.status_eof_observed = 1U;
    input.allocator_observation_stable = 1U;
    return proc17_qa_controller_report_build(&input, report);
}

static int build_error_frame(
    const struct proc17_qa_launcher_v1_expectation *expectation,
    uint16_t code,
    uint16_t subject,
    int namespace_complete,
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES],
    size_t *frame_bytes)
{
    struct proc17_qa_phase_identity identity;
    struct proc17_qa_controller_error_input input;
    struct proc17_qa_namespace_observation observation = {
        .controller_pidfd_identity_retained = 1U,
        .terminal_record_complete = 1U,
        .terminal_record_eof_observed = 1U,
        .controller_reaped = 1U,
        .controller_authority_closed = 1U,
    };
    unsigned char token[PROC17_QA_WIRE_DIGEST_BYTES];
    unsigned char stage[PROC17_QA_SOURCE_STAGE_V1_BYTES];
    unsigned char report[PROC17_QA_CONTROLLER_REPORT_BYTES];

    memcpy(&identity, expectation->identity, sizeof(identity));
    memset(token, 0x55, sizeof(token));
    fill_stage(stage, expectation);
    if (code == PROC17_QA_RUN_V1_NAMESPACE_CLEANUP_INCOMPLETE) {
        if (build_result_report(expectation, token, report) != 0) return -1;
        observation.controller_authority_closed
            = namespace_complete != 0 ? 1U : 0U;
    } else {
        memset(&input, 0, sizeof(input));
        input.identity = &identity;
        input.process_token = token;
        input.source_stage = stage;
        input.error_code = code;
        input.subject = subject;
        input.candidate_terminal_observed = 1U;
        input.process_tree_reaped = 1U;
        input.stdout_eof_observed
            = subject == PROC17_QA_CONTROLLER_ERROR_STDOUT ? 0U : 1U;
        input.stderr_eof_observed
            = subject == PROC17_QA_CONTROLLER_ERROR_STDERR ? 0U : 1U;
        input.scratch_observation_complete
            = subject == PROC17_QA_CONTROLLER_ERROR_SCRATCH ? 0U : 1U;
        input.status_eof_observed = 1U;
        if (proc17_qa_controller_error_build(&input, report) != 0) return -1;
    }
    return proc17_qa_controller_report_finalize(report, &identity, token,
        0, &observation, frame, frame_bytes);
}

static int collect_terminal_frame(
    const struct proc17_qa_launcher_v1_expectation *expectation,
    const unsigned char *terminal_frame,
    size_t terminal_bytes,
    struct proc17_qa_launcher_v1_terminal *terminal)
{
    unsigned char started[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char sequence[2U * PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t started_bytes = 0U;

    if (encode_started(expectation, started, &started_bytes) != 0
        || started_bytes + terminal_bytes > sizeof(sequence)) {
        return -1;
    }
    memcpy(sequence, started, started_bytes);
    memcpy(sequence + started_bytes, terminal_frame, terminal_bytes);
    return collect_bytes(sequence, started_bytes + terminal_bytes, 0,
        expectation, terminal);
}

static const char *class_name(uint16_t value)
{
    if (value == PROC17_QA_RUN_V1_ERROR_UNAVAILABLE) return "unavailable";
    if (value == PROC17_QA_RUN_V1_ERROR_AMBIGUOUS) return "ambiguous";
    if (value == PROC17_QA_RUN_V1_ERROR_WORLD) return "world";
    return NULL;
}

static const char *code_name(uint16_t value)
{
    switch (value) {
    case PROC17_QA_RUN_V1_TERMINAL_FRAME_MISSING:
        return "terminal_frame_missing";
    case PROC17_QA_RUN_V1_REAP_AMBIGUOUS:
        return "reap_ambiguous";
    case PROC17_QA_RUN_V1_OUTPUT_OBSERVATION_INCOMPLETE:
        return "output_observation_incomplete";
    case PROC17_QA_RUN_V1_SCRATCH_OBSERVATION_INCOMPLETE:
        return "scratch_observation_incomplete";
    case PROC17_QA_RUN_V1_NAMESPACE_CLEANUP_INCOMPLETE:
        return "namespace_cleanup_incomplete";
    default:
        return NULL;
    }
}

static const char *stage_name(uint16_t value)
{
    if (value == PROC17_QA_RUN_V1_ERROR_POSTFLIGHT) return "postflight";
    if (value == PROC17_QA_RUN_V1_ERROR_CLEANUP) return "cleanup";
    return NULL;
}

static const char *start_name(uint8_t value)
{
    if (value == PROC17_QA_RUN_V1_TRUE) return "started";
    if (value == PROC17_QA_RUN_V1_FALSE) return "not_started";
    if (value == PROC17_QA_RUN_V1_UNKNOWN) return "unknown";
    return NULL;
}

static const char *completion_name(uint8_t value)
{
    if (value == PROC17_QA_RUN_V1_TRUE) return "complete";
    if (value == PROC17_QA_RUN_V1_FALSE) return "incomplete";
    if (value == PROC17_QA_RUN_V1_UNKNOWN) return "unknown";
    return NULL;
}

static int record(
    const char *id,
    const struct proc17_qa_launcher_v1_terminal *terminal,
    unsigned int variants)
{
    const char *error_class = class_name(terminal->error_class);
    const char *code = code_name(terminal->error_code);
    const char *stage = stage_name(terminal->error_stage);
    const char *start = start_name(terminal->candidate_start_state);
    const char *cleanup = completion_name(terminal->cleanup_state);
    const char *reap = completion_name(terminal->launcher_reap_state);
    const char *eof = completion_name(terminal->result_eof_state);

    if (terminal->kind != PROC17_QA_LAUNCHER_V1_TERMINAL_ERROR
            && terminal->kind
                != PROC17_QA_LAUNCHER_V1_TERMINAL_DERIVED_ERROR) {
        return -1;
    }
    if (error_class == NULL || code == NULL || stage == NULL || start == NULL
        || cleanup == NULL || reap == NULL || eof == NULL) {
        return -1;
    }
    printf("QN19_NATIVE_V0|%s|%s|%s|%s|%s|%s|%s|%s|%u\n",
        id, error_class, code, stage, start, cleanup, reap, eof, variants);
    return 0;
}

static int same_terminal_shape(
    const struct proc17_qa_launcher_v1_terminal *left,
    const struct proc17_qa_launcher_v1_terminal *right)
{
    return left->kind == right->kind
        && left->error_class == right->error_class
        && left->error_code == right->error_code
        && left->error_stage == right->error_stage
        && left->candidate_start_state == right->candidate_start_state
        && left->cleanup_state == right->cleanup_state
        && left->launcher_reap_state == right->launcher_reap_state
        && left->result_eof_state == right->result_eof_state;
}

int main(int argument_count, char **arguments)
{
    struct proc17_qa_launcher_v1_expectation expectation;
    struct proc17_qa_launcher_v1_terminal terminal;
    struct proc17_qa_launcher_v1_terminal second;
    unsigned char started[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t started_bytes = 0U;
    size_t frame_bytes = 0U;

    (void)arguments;
    if (argument_count != 1) return 2;
    fill_expectation(&expectation);
    if (encode_started(&expectation, started, &started_bytes) != 0
        || collect_bytes(started, started_bytes, 0, &expectation, &terminal)
            != PROC17_QA_LAUNCHER_V1_OK
        || record("terminal-missing", &terminal, 1U) != 0) {
        return 1;
    }
    if (collect_bytes(started, started_bytes, 1, &expectation, &terminal)
            != PROC17_QA_LAUNCHER_V1_OK
        || record("reap-ambiguity", &terminal, 1U) != 0) {
        return 1;
    }
    if (build_error_frame(&expectation,
            PROC17_QA_RUN_V1_OUTPUT_OBSERVATION_INCOMPLETE,
            PROC17_QA_CONTROLLER_ERROR_STDOUT, 1, frame, &frame_bytes) != 0
        || collect_terminal_frame(&expectation, frame, frame_bytes, &terminal)
            != PROC17_QA_LAUNCHER_V1_OK
        || build_error_frame(&expectation,
            PROC17_QA_RUN_V1_OUTPUT_OBSERVATION_INCOMPLETE,
            PROC17_QA_CONTROLLER_ERROR_STDERR, 1, frame, &frame_bytes) != 0
        || collect_terminal_frame(&expectation, frame, frame_bytes, &second)
            != PROC17_QA_LAUNCHER_V1_OK
        || !same_terminal_shape(&terminal, &second)
        || record("stream-observation", &terminal, 2U) != 0) {
        return 1;
    }
    if (build_error_frame(&expectation,
            PROC17_QA_RUN_V1_SCRATCH_OBSERVATION_INCOMPLETE,
            PROC17_QA_CONTROLLER_ERROR_SCRATCH, 1, frame, &frame_bytes) != 0
        || collect_terminal_frame(&expectation, frame, frame_bytes, &terminal)
            != PROC17_QA_LAUNCHER_V1_OK
        || record("scratch-observation", &terminal, 1U) != 0) {
        return 1;
    }
    if (build_error_frame(&expectation,
            PROC17_QA_RUN_V1_NAMESPACE_CLEANUP_INCOMPLETE, 0U, 0,
            frame, &frame_bytes) != 0
        || collect_terminal_frame(&expectation, frame, frame_bytes, &terminal)
            != PROC17_QA_LAUNCHER_V1_OK
        || record("namespace-cleanup", &terminal, 1U) != 0) {
        return 1;
    }
    return 0;
}
