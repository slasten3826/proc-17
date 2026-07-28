#define _GNU_SOURCE

#include "../proc17_qa_report.h"
#include "../proc17_qa_policy.h"
#include "../proc17_qa_status.h"

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static void fill_identity(struct proc17_qa_phase_identity *identity)
{
    memset(identity->transaction, 0x11, sizeof(identity->transaction));
    memset(identity->witness, 0x22, sizeof(identity->witness));
    memset(identity->profile, 0x33, sizeof(identity->profile));
    memset(identity->environment, 0x44, sizeof(identity->environment));
}

static void fill_stage(unsigned char stage[PROC17_QA_SOURCE_STAGE_V1_BYTES])
{
    size_t index;
    memset(stage, 0, PROC17_QA_SOURCE_STAGE_V1_BYTES);
    proc17_qa_wire_put_u16(stage, 1U);
    proc17_qa_wire_put_u32(stage + 4U, 15U);
    for (index = 0U; index < 9U; index++) {
        proc17_qa_wire_put_u64(stage + 8U + index * 8U, index + 1U);
    }
    stage[80U] = 1U;
    stage[81U] = 1U;
}

static int empty_stream(
    uint64_t limit,
    struct proc17_qa_stream_measurement *measurement)
{
    struct proc17_qa_stream_observer observer;
    int descriptors[2];
    if (pipe2(descriptors, O_CLOEXEC | O_NONBLOCK) != 0
        || proc17_qa_stream_init(&observer, limit) != 0
        || close(descriptors[1]) != 0
        || proc17_qa_stream_drain_nonblocking(&observer, descriptors[0])
            != PROC17_QA_STREAM_DRAIN_EOF
        || close(descriptors[0]) != 0
        || proc17_qa_stream_snapshot(&observer, measurement) != 0) {
        return -1;
    }
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
    return proc17_qa_phase_controller_report_ready(phase)
        && !proc17_qa_phase_candidate_result_ready(phase) ? 0 : -1;
}

static int test_join_and_suppression(void)
{
    struct proc17_qa_phase_identity identity;
    struct proc17_qa_phase_state phase;
    struct proc17_qa_phase_state changed_phase;
    struct proc17_qa_stream_measurement stdout_measurement;
    struct proc17_qa_stream_measurement stderr_measurement;
    struct proc17_qa_candidate_metrics metrics;
    struct proc17_qa_allocator_telemetry telemetry;
    struct proc17_qa_allocator_snapshot allocator;
    struct proc17_qa_scratch_measurement scratch;
    struct proc17_qa_controller_report_input input;
    struct proc17_qa_wire_view view;
    unsigned char token[PROC17_QA_WIRE_DIGEST_BYTES];
    unsigned char wrong_token[PROC17_QA_WIRE_DIGEST_BYTES];
    unsigned char stage[PROC17_QA_SOURCE_STAGE_V1_BYTES];
    unsigned char report[PROC17_QA_CONTROLLER_REPORT_BYTES];
    unsigned char changed_report[PROC17_QA_CONTROLLER_REPORT_BYTES];
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t frame_bytes = 0U;

    fill_identity(&identity);
    memset(token, 0x55, sizeof(token));
    memset(wrong_token, 0x56, sizeof(wrong_token));
    fill_stage(stage);
    if (make_local_phase(&phase, &identity, token, stage) != 0
        || empty_stream(PROC17_QA_STDOUT_BYTES, &stdout_measurement) != 0
        || empty_stream(PROC17_QA_STDERR_BYTES, &stderr_measurement) != 0
        || proc17_qa_allocator_telemetry_init(&telemetry,
            PROC17_QA_RUNTIME_HEAP_BYTES) != 0
        || proc17_qa_allocator_snapshot(&telemetry, &allocator) != 0) {
        return -1;
    }
    memset(&metrics, 0, sizeof(metrics));
    metrics.wall_time_ms = 2U;
    metrics.cpu_user_ms = 1U;
    metrics.cpu_system_ms = 1U;
    metrics.max_rss_bytes = 4096U;
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
    if (proc17_qa_controller_report_build(&input, report) != 0
        || proc17_qa_controller_report_finalize(report, &identity, token,
            0, 1U, frame, &frame_bytes) != 0
        || proc17_qa_wire_decode_run_v1(frame, frame_bytes, &view) != 0
        || view.kind != PROC17_QA_WIRE_RUN_RESULT_V1
        || !proc17_qa_wire_v1_result_valid(
            view.payload, view.payload_bytes)
        || proc17_qa_wire_get_u16(view.payload + 132U)
            != PROC17_QA_RUN_EXPECTED_EXIT
        || view.payload[PROC17_QA_V1_RESULT_FINALITY_OFFSET + 7U] != 1U
        || proc17_qa_phase_candidate_result_ready(&phase)) {
        return -1;
    }

    if (proc17_qa_controller_report_finalize(report, &identity, wrong_token,
            0, 1U, frame, &frame_bytes) == 0
        || proc17_qa_controller_report_finalize(report, &identity, token,
            SIGKILL, 1U, frame, &frame_bytes) == 0
        || proc17_qa_controller_report_finalize(report, &identity, token,
            0, 0U, frame, &frame_bytes) == 0) {
        return -1;
    }
    memcpy(changed_report, report, sizeof(changed_report));
    changed_report[220U] = 1U;
    if (proc17_qa_controller_report_finalize(changed_report,
            &identity, token, 0, 1U, frame, &frame_bytes) == 0) {
        return -1;
    }
    input.status_eof_observed = 0U;
    if (proc17_qa_controller_report_build(&input, changed_report) == 0) {
        return -1;
    }
    input.status_eof_observed = 1U;
    input.heap_denied_notifications = 1U;
    if (proc17_qa_controller_report_build(&input, changed_report) == 0) {
        return -1;
    }
    input.heap_denied_notifications = 0U;
    changed_phase = phase;
    if (proc17_qa_phase_mark_finality(&changed_phase,
            PROC17_QA_FINAL_NAMESPACE_CLEAN) != 0) {
        return -1;
    }
    input.phase = &changed_phase;
    if (proc17_qa_controller_report_build(&input, changed_report) == 0) {
        return -1;
    }
    return 0;
}

static int test_memory_join(void)
{
    struct proc17_qa_phase_identity identity;
    struct proc17_qa_phase_state phase;
    struct proc17_qa_stream_measurement stdout_measurement;
    struct proc17_qa_stream_measurement stderr_measurement;
    struct proc17_qa_candidate_metrics metrics;
    struct proc17_qa_allocator_snapshot allocator;
    struct proc17_qa_scratch_measurement scratch;
    struct proc17_qa_controller_report_input input;
    unsigned char token[PROC17_QA_WIRE_DIGEST_BYTES];
    unsigned char stage[PROC17_QA_SOURCE_STAGE_V1_BYTES];
    unsigned char report[PROC17_QA_CONTROLLER_REPORT_BYTES];

    fill_identity(&identity);
    memset(token, 0x66, sizeof(token));
    fill_stage(stage);
    if (make_local_phase(&phase, &identity, token, stage) != 0
        || empty_stream(PROC17_QA_STDOUT_BYTES, &stdout_measurement) != 0
        || empty_stream(PROC17_QA_STDERR_BYTES, &stderr_measurement) != 0) {
        return -1;
    }
    phase.first_cause.kind = PROC17_QA_RUN_MEMORY_LIMIT;
    phase.first_cause.observed_value = 1024U;
    memset(&metrics, 0, sizeof(metrics));
    metrics.wall_time_ms = 2U;
    memset(&allocator, 0, sizeof(allocator));
    allocator.ceiling_bytes = PROC17_QA_RUNTIME_HEAP_BYTES;
    allocator.peak_bytes = 1024U;
    allocator.ceiling_denied = 1U;
    memset(&scratch, 0, sizeof(scratch));
    scratch.limit_bytes = PROC17_QA_SCRATCH_BYTES;
    scratch.limit_entries = PROC17_QA_SCRATCH_ENTRIES;
    scratch.inventory_complete = 1U;
    memset(&input, 0, sizeof(input));
    input.identity = &identity;
    input.process_token = token;
    input.phase = &phase;
    input.termination.kind = PROC17_QA_TERMINATION_SUPERVISOR_KILL;
    input.termination.exit_code = UINT32_MAX;
    input.termination.signal_number = SIGKILL;
    input.stdout_measurement = &stdout_measurement;
    input.stderr_measurement = &stderr_measurement;
    input.candidate_metrics = &metrics;
    input.allocator = &allocator;
    input.scratch = &scratch;
    input.source_stage = stage;
    input.status_eof_observed = 1U;
    input.allocator_observation_stable = 1U;
    input.heap_denied_notifications = 1U;
    if (proc17_qa_controller_report_build(&input, report) != 0) return -1;
    allocator.system_allocation_failed = 1U;
    if (proc17_qa_controller_report_build(&input, report) == 0) return -1;
    return 0;
}

int main(void)
{
    if (test_join_and_suppression() != 0 || test_memory_join() != 0) {
        return 1;
    }
    puts("proc17 QA private controller report and finality join ok");
    return 0;
}
