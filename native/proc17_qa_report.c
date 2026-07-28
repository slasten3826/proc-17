#define _GNU_SOURCE

#include "proc17_qa_report.h"

#include <limits.h>
#include <signal.h>
#include <string.h>
#include <sys/wait.h>

#include "proc17_qa_policy.h"

#define PROC17_QA_REPORT_IDENTITY_OFFSET 16U
#define PROC17_QA_REPORT_TOKEN_OFFSET 144U
#define PROC17_QA_REPORT_REASON_OFFSET 176U
#define PROC17_QA_REPORT_CAUSE_OFFSET 188U
#define PROC17_QA_REPORT_FINALITY_OFFSET 208U
#define PROC17_QA_REPORT_STATUS_EOF_OFFSET 215U
#define PROC17_QA_REPORT_ALLOCATOR_STABLE_OFFSET 216U
#define PROC17_QA_REPORT_HEAP_NOTIFICATION_OFFSET 217U
#define PROC17_QA_REPORT_SYSTEM_FAILURE_OFFSET 218U
#define PROC17_QA_REPORT_NOTIFICATION_FAILURE_OFFSET 219U
#define PROC17_QA_REPORT_ALLOCATOR_CURRENT_OFFSET 224U
#define PROC17_QA_REPORT_STDOUT_OFFSET 232U
#define PROC17_QA_REPORT_STDERR_OFFSET 296U
#define PROC17_QA_REPORT_RESOURCE_OFFSET 360U
#define PROC17_QA_REPORT_SCRATCH_OFFSET 448U
#define PROC17_QA_REPORT_STAGE_OFFSET 488U

static const unsigned char report_magic[8] = {
    'P', '1', '7', 'Q', 'A', 'C', 'R', 0,
};

_Static_assert(PROC17_QA_CONTROLLER_REPORT_BYTES == 572U,
    "private controller report layout changed");
_Static_assert(PROC17_QA_WIRE_ENVELOPE_BYTES
        + PROC17_QA_RUN_RESULT_V1_BYTES <= PIPE_BUF,
    "terminal RUN v1 frame must fit one atomic pipe write");

static int termination_shape_valid(
    const struct proc17_qa_candidate_termination *termination)
{
    if (termination == NULL) return 0;
    if (termination->kind == PROC17_QA_TERMINATION_EXIT) {
        return termination->exit_code <= 255U
            && termination->signal_number == UINT32_MAX;
    }
    if (termination->kind == PROC17_QA_TERMINATION_SIGNAL) {
        return termination->exit_code == UINT32_MAX
            && termination->signal_number > 0U
            && termination->signal_number < (uint32_t)NSIG;
    }
    return termination->kind == PROC17_QA_TERMINATION_SUPERVISOR_KILL
        && termination->exit_code == UINT32_MAX
        && termination->signal_number == (uint32_t)SIGKILL;
}

static int stream_shape_valid(
    const struct proc17_qa_stream_measurement *measurement,
    uint64_t exact_limit)
{
    unsigned char wire[PROC17_QA_STREAM_MEASUREMENT_V1_BYTES];
    return measurement != NULL && measurement->limit_bytes == exact_limit
        && proc17_qa_stream_encode_v1(measurement, wire) == 0;
}

static int scratch_shape_valid(
    const struct proc17_qa_scratch_measurement *measurement)
{
    unsigned char wire[PROC17_QA_SCRATCH_MEASUREMENT_V1_BYTES];
    return measurement != NULL
        && measurement->limit_bytes == PROC17_QA_SCRATCH_BYTES
        && measurement->limit_entries == PROC17_QA_SCRATCH_ENTRIES
        && proc17_qa_scratch_encode_v1(measurement, wire) == 0;
}

static int allocator_shape_valid(
    const struct proc17_qa_allocator_snapshot *allocator,
    uint8_t notifications,
    uint16_t reason)
{
    if (allocator == NULL
        || allocator->ceiling_bytes != PROC17_QA_RUNTIME_HEAP_BYTES
        || allocator->current_bytes > allocator->peak_bytes
        || allocator->peak_bytes > allocator->ceiling_bytes
        || allocator->ceiling_denied > 1U
        || allocator->system_allocation_failed != 0U
        || allocator->status_notification_failed != 0U
        || notifications > 1U
        || notifications != allocator->ceiling_denied
        || (allocator->ceiling_denied != 0U
            && allocator->system_allocation_failed != 0U)
        || ((reason == PROC17_QA_RUN_MEMORY_LIMIT)
            != (allocator->ceiling_denied != 0U))) {
        return 0;
    }
    return 1;
}

static int reason_evidence_valid(
    uint16_t reason,
    const struct proc17_qa_first_cause *cause,
    const struct proc17_qa_candidate_termination *termination,
    const struct proc17_qa_stream_measurement *stdout_measurement,
    const struct proc17_qa_stream_measurement *stderr_measurement,
    const struct proc17_qa_candidate_metrics *metrics,
    const struct proc17_qa_allocator_snapshot *allocator)
{
    int output_crossed;
    uint64_t maximum_output = 0U;

    if (cause == NULL || metrics == NULL || cause->kind != reason
        || cause->monotonic_sequence == 0U
        || reason < PROC17_QA_RUN_EXPECTED_EXIT
        || reason > PROC17_QA_RUN_SANDBOX_POLICY_VIOLATION
        || reason == PROC17_QA_RUN_SCRATCH_LIMIT
        || !termination_shape_valid(termination)) {
        return 0;
    }
    output_crossed = stdout_measurement->limit_crossed != 0U
        || stderr_measurement->limit_crossed != 0U;
    if (stdout_measurement->limit_crossed != 0U) {
        maximum_output = stdout_measurement->observed_bytes;
    }
    if (stderr_measurement->limit_crossed != 0U
        && stderr_measurement->observed_bytes > maximum_output) {
        maximum_output = stderr_measurement->observed_bytes;
    }
    if ((reason == PROC17_QA_RUN_OUTPUT_LIMIT) != output_crossed) return 0;
    switch (reason) {
    case PROC17_QA_RUN_EXPECTED_EXIT:
        return termination->kind == PROC17_QA_TERMINATION_EXIT
            && termination->exit_code == 0U && cause->observed_value == 0U;
    case PROC17_QA_RUN_UNEXPECTED_EXIT:
        return termination->kind == PROC17_QA_TERMINATION_EXIT
            && termination->exit_code != 0U
            && cause->observed_value == termination->exit_code;
    case PROC17_QA_RUN_SIGNAL:
        return termination->kind == PROC17_QA_TERMINATION_SIGNAL
            && termination->signal_number != (uint32_t)SIGXCPU
            && termination->signal_number != (uint32_t)SIGSYS
            && cause->observed_value == termination->signal_number;
    case PROC17_QA_RUN_WALL_TIMEOUT:
        return termination->kind == PROC17_QA_TERMINATION_SUPERVISOR_KILL
            && cause->observed_value == PROC17_QA_WALL_TIME_MS
            && metrics->wall_time_ms >= PROC17_QA_WALL_TIME_MS;
    case PROC17_QA_RUN_CPU_LIMIT:
        return termination->kind == PROC17_QA_TERMINATION_SIGNAL
            && termination->signal_number == (uint32_t)SIGXCPU
            && cause->observed_value == (uint64_t)SIGXCPU;
    case PROC17_QA_RUN_MEMORY_LIMIT:
        return (termination->kind == PROC17_QA_TERMINATION_SUPERVISOR_KILL
                || (termination->kind == PROC17_QA_TERMINATION_EXIT
                    && termination->exit_code != 0U))
            && cause->observed_value != 0U
            && cause->observed_value <= allocator->peak_bytes;
    case PROC17_QA_RUN_OUTPUT_LIMIT:
        return termination->kind == PROC17_QA_TERMINATION_SUPERVISOR_KILL
            && cause->observed_value != 0U
            && cause->observed_value <= maximum_output;
    case PROC17_QA_RUN_SANDBOX_POLICY_VIOLATION:
        return termination->kind == PROC17_QA_TERMINATION_SIGNAL
            && termination->signal_number == (uint32_t)SIGSYS
            && cause->observed_value == (uint64_t)SIGSYS;
    default:
        return 0;
    }
}

static int encode_resource(
    const struct proc17_qa_candidate_metrics *metrics,
    const struct proc17_qa_allocator_snapshot *allocator,
    unsigned char output[PROC17_QA_RESOURCE_MEASUREMENT_V1_BYTES])
{
    if (metrics == NULL || allocator == NULL || output == NULL) return -1;
    memset(output, 0, PROC17_QA_RESOURCE_MEASUREMENT_V1_BYTES);
    proc17_qa_wire_put_u64(output, metrics->wall_time_ms);
    proc17_qa_wire_put_u64(output + 8U, metrics->cpu_user_ms);
    proc17_qa_wire_put_u64(output + 16U, metrics->cpu_system_ms);
    proc17_qa_wire_put_u64(output + 24U, metrics->max_rss_bytes);
    proc17_qa_wire_put_u64(output + 32U, PROC17_QA_ADDRESS_SPACE_BYTES);
    proc17_qa_wire_put_u64(output + 40U, allocator->peak_bytes);
    proc17_qa_wire_put_u64(output + 48U, allocator->ceiling_bytes);
    proc17_qa_wire_put_u64(output + 56U, PROC17_QA_MAX_PROCESSES);
    proc17_qa_wire_put_u64(output + 64U, PROC17_QA_MAX_OPEN_FILES);
    proc17_qa_wire_put_u64(output + 72U, PROC17_QA_MAX_FILE_BYTES);
    output[80U] = allocator->ceiling_denied;
    return proc17_qa_wire_v1_resource_valid(output) ? 0 : -1;
}

static void encode_termination(
    unsigned char *output,
    const struct proc17_qa_candidate_termination *termination)
{
    proc17_qa_wire_put_u16(output, termination->kind);
    proc17_qa_wire_put_u32(output + 2U, termination->exit_code);
    proc17_qa_wire_put_u32(output + 6U, termination->signal_number);
}

int proc17_qa_controller_report_build(
    const struct proc17_qa_controller_report_input *input,
    unsigned char output[PROC17_QA_CONTROLLER_REPORT_BYTES])
{
    uint16_t reason;
    size_t index;

    if (input == NULL || output == NULL || input->identity == NULL
        || input->process_token == NULL || input->phase == NULL
        || input->stdout_measurement == NULL
        || input->stderr_measurement == NULL
        || input->candidate_metrics == NULL || input->allocator == NULL
        || input->scratch == NULL || input->source_stage == NULL
        || input->status_eof_observed != 1U
        || input->allocator_observation_stable != 1U
        || !proc17_qa_phase_identity_valid(input->identity)
        || !proc17_qa_wire_digest_nonzero(input->process_token)
        || !proc17_qa_phase_controller_report_ready(input->phase)
        || !stream_shape_valid(input->stdout_measurement,
            PROC17_QA_STDOUT_BYTES)
        || !stream_shape_valid(input->stderr_measurement,
            PROC17_QA_STDERR_BYTES)
        || !scratch_shape_valid(input->scratch)
        || !proc17_qa_wire_v1_source_stage_valid(input->source_stage)
        || input->source_stage[80U] != 1U
        || input->source_stage[81U] != 1U) {
        return -1;
    }
    reason = input->phase->first_cause.kind;
    if (!allocator_shape_valid(input->allocator,
            input->heap_denied_notifications, reason)
        || !reason_evidence_valid(reason, &input->phase->first_cause,
            &input->termination, input->stdout_measurement,
            input->stderr_measurement, input->candidate_metrics,
            input->allocator)) {
        return -1;
    }
    memset(output, 0, PROC17_QA_CONTROLLER_REPORT_BYTES);
    memcpy(output, report_magic, sizeof(report_magic));
    proc17_qa_wire_put_u16(output + 8U,
        PROC17_QA_CONTROLLER_REPORT_VERSION);
    proc17_qa_wire_put_u16(output + 10U,
        PROC17_QA_CONTROLLER_REPORT_BYTES);
    memcpy(output + PROC17_QA_REPORT_IDENTITY_OFFSET, input->identity,
        PROC17_QA_V1_IDENTITY_BYTES);
    memcpy(output + PROC17_QA_REPORT_TOKEN_OFFSET, input->process_token,
        PROC17_QA_WIRE_DIGEST_BYTES);
    proc17_qa_wire_put_u16(output + PROC17_QA_REPORT_REASON_OFFSET, reason);
    encode_termination(output + PROC17_QA_REPORT_REASON_OFFSET + 2U,
        &input->termination);
    proc17_qa_wire_put_u16(output + PROC17_QA_REPORT_CAUSE_OFFSET, reason);
    proc17_qa_wire_put_u64(output + PROC17_QA_REPORT_CAUSE_OFFSET + 4U,
        input->phase->first_cause.monotonic_sequence);
    proc17_qa_wire_put_u64(output + PROC17_QA_REPORT_CAUSE_OFFSET + 12U,
        input->phase->first_cause.observed_value);
    for (index = 0U; index < 7U; index++) {
        output[PROC17_QA_REPORT_FINALITY_OFFSET + index] = 1U;
    }
    output[PROC17_QA_REPORT_STATUS_EOF_OFFSET] = 1U;
    output[PROC17_QA_REPORT_ALLOCATOR_STABLE_OFFSET] = 1U;
    output[PROC17_QA_REPORT_HEAP_NOTIFICATION_OFFSET]
        = input->heap_denied_notifications;
    output[PROC17_QA_REPORT_SYSTEM_FAILURE_OFFSET]
        = input->allocator->system_allocation_failed;
    output[PROC17_QA_REPORT_NOTIFICATION_FAILURE_OFFSET]
        = input->allocator->status_notification_failed;
    proc17_qa_wire_put_u64(output + PROC17_QA_REPORT_ALLOCATOR_CURRENT_OFFSET,
        input->allocator->current_bytes);
    if (proc17_qa_stream_encode_v1(input->stdout_measurement,
            output + PROC17_QA_REPORT_STDOUT_OFFSET) != 0
        || proc17_qa_stream_encode_v1(input->stderr_measurement,
            output + PROC17_QA_REPORT_STDERR_OFFSET) != 0
        || encode_resource(input->candidate_metrics, input->allocator,
            output + PROC17_QA_REPORT_RESOURCE_OFFSET) != 0
        || proc17_qa_scratch_encode_v1(input->scratch,
            output + PROC17_QA_REPORT_SCRATCH_OFFSET) != 0) {
        memset(output, 0, PROC17_QA_CONTROLLER_REPORT_BYTES);
        return -1;
    }
    memcpy(output + PROC17_QA_REPORT_STAGE_OFFSET, input->source_stage,
        PROC17_QA_SOURCE_STAGE_V1_BYTES);
    return 0;
}

static int private_report_valid(
    const unsigned char report[PROC17_QA_CONTROLLER_REPORT_BYTES])
{
    struct proc17_qa_candidate_termination termination;
    struct proc17_qa_first_cause cause;
    struct proc17_qa_stream_measurement stdout_measurement;
    struct proc17_qa_stream_measurement stderr_measurement;
    struct proc17_qa_candidate_metrics metrics;
    struct proc17_qa_allocator_snapshot allocator;
    uint16_t reason;
    uint64_t current;
    const unsigned char *resource;
    size_t index;

    if (report == NULL || memcmp(report, report_magic, sizeof(report_magic)) != 0
        || proc17_qa_wire_get_u16(report + 8U)
            != PROC17_QA_CONTROLLER_REPORT_VERSION
        || proc17_qa_wire_get_u16(report + 10U)
            != PROC17_QA_CONTROLLER_REPORT_BYTES
        || !proc17_qa_wire_bytes_zero(report + 12U, 4U)
        || !proc17_qa_wire_v1_identity_valid(
            report + PROC17_QA_REPORT_IDENTITY_OFFSET)
        || !proc17_qa_wire_digest_nonzero(
            report + PROC17_QA_REPORT_TOKEN_OFFSET)
        || !proc17_qa_wire_bytes_zero(report + 190U, 2U)
        || report[PROC17_QA_REPORT_STATUS_EOF_OFFSET] != 1U
        || report[PROC17_QA_REPORT_ALLOCATOR_STABLE_OFFSET] != 1U
        || report[PROC17_QA_REPORT_HEAP_NOTIFICATION_OFFSET] > 1U
        || !proc17_qa_wire_boolean(
            report[PROC17_QA_REPORT_SYSTEM_FAILURE_OFFSET])
        || report[PROC17_QA_REPORT_NOTIFICATION_FAILURE_OFFSET] != 0U
        || !proc17_qa_wire_bytes_zero(report + 220U, 4U)) {
        return 0;
    }
    for (index = 0U; index < 7U; index++) {
        if (report[PROC17_QA_REPORT_FINALITY_OFFSET + index] != 1U) return 0;
    }
    if (!proc17_qa_wire_v1_stream_valid(
            report + PROC17_QA_REPORT_STDOUT_OFFSET)
        || !proc17_qa_wire_v1_stream_valid(
            report + PROC17_QA_REPORT_STDERR_OFFSET)
        || !proc17_qa_wire_v1_resource_valid(
            report + PROC17_QA_REPORT_RESOURCE_OFFSET)
        || !proc17_qa_wire_v1_scratch_valid(
            report + PROC17_QA_REPORT_SCRATCH_OFFSET)
        || !proc17_qa_wire_v1_source_stage_valid(
            report + PROC17_QA_REPORT_STAGE_OFFSET)
        || report[PROC17_QA_REPORT_STAGE_OFFSET + 80U] != 1U
        || report[PROC17_QA_REPORT_STAGE_OFFSET + 81U] != 1U) {
        return 0;
    }
    resource = report + PROC17_QA_REPORT_RESOURCE_OFFSET;
    if (proc17_qa_wire_get_u64(resource + 32U)
            != PROC17_QA_ADDRESS_SPACE_BYTES
        || proc17_qa_wire_get_u64(resource + 48U)
            != PROC17_QA_RUNTIME_HEAP_BYTES
        || proc17_qa_wire_get_u64(resource + 56U)
            != PROC17_QA_MAX_PROCESSES
        || proc17_qa_wire_get_u64(resource + 64U)
            != PROC17_QA_MAX_OPEN_FILES
        || proc17_qa_wire_get_u64(resource + 72U)
            != PROC17_QA_MAX_FILE_BYTES
        || proc17_qa_wire_get_u64(
            report + PROC17_QA_REPORT_SCRATCH_OFFSET + 16U)
            != PROC17_QA_SCRATCH_BYTES
        || proc17_qa_wire_get_u64(
            report + PROC17_QA_REPORT_SCRATCH_OFFSET + 24U)
            != PROC17_QA_SCRATCH_ENTRIES) {
        return 0;
    }
    reason = proc17_qa_wire_get_u16(report + PROC17_QA_REPORT_REASON_OFFSET);
    termination.kind = proc17_qa_wire_get_u16(
        report + PROC17_QA_REPORT_REASON_OFFSET + 2U);
    termination.exit_code = proc17_qa_wire_get_u32(
        report + PROC17_QA_REPORT_REASON_OFFSET + 4U);
    termination.signal_number = proc17_qa_wire_get_u32(
        report + PROC17_QA_REPORT_REASON_OFFSET + 8U);
    cause.kind = proc17_qa_wire_get_u16(report + PROC17_QA_REPORT_CAUSE_OFFSET);
    cause.monotonic_sequence = proc17_qa_wire_get_u64(
        report + PROC17_QA_REPORT_CAUSE_OFFSET + 4U);
    cause.observed_value = proc17_qa_wire_get_u64(
        report + PROC17_QA_REPORT_CAUSE_OFFSET + 12U);
    memset(&stdout_measurement, 0, sizeof(stdout_measurement));
    stdout_measurement.observed_bytes = proc17_qa_wire_get_u64(
        report + PROC17_QA_REPORT_STDOUT_OFFSET);
    stdout_measurement.hashed_bytes = proc17_qa_wire_get_u64(
        report + PROC17_QA_REPORT_STDOUT_OFFSET + 8U);
    stdout_measurement.limit_bytes = proc17_qa_wire_get_u64(
        report + PROC17_QA_REPORT_STDOUT_OFFSET + 16U);
    memcpy(stdout_measurement.prefix_digest,
        report + PROC17_QA_REPORT_STDOUT_OFFSET + 24U,
        PROC17_QA_WIRE_DIGEST_BYTES);
    stdout_measurement.limit_crossed
        = report[PROC17_QA_REPORT_STDOUT_OFFSET + 56U];
    stdout_measurement.eof_observed
        = report[PROC17_QA_REPORT_STDOUT_OFFSET + 57U];
    memset(&stderr_measurement, 0, sizeof(stderr_measurement));
    stderr_measurement.observed_bytes = proc17_qa_wire_get_u64(
        report + PROC17_QA_REPORT_STDERR_OFFSET);
    stderr_measurement.hashed_bytes = proc17_qa_wire_get_u64(
        report + PROC17_QA_REPORT_STDERR_OFFSET + 8U);
    stderr_measurement.limit_bytes = proc17_qa_wire_get_u64(
        report + PROC17_QA_REPORT_STDERR_OFFSET + 16U);
    memcpy(stderr_measurement.prefix_digest,
        report + PROC17_QA_REPORT_STDERR_OFFSET + 24U,
        PROC17_QA_WIRE_DIGEST_BYTES);
    stderr_measurement.limit_crossed
        = report[PROC17_QA_REPORT_STDERR_OFFSET + 56U];
    stderr_measurement.eof_observed
        = report[PROC17_QA_REPORT_STDERR_OFFSET + 57U];
    metrics.wall_time_ms = proc17_qa_wire_get_u64(resource);
    metrics.cpu_user_ms = proc17_qa_wire_get_u64(resource + 8U);
    metrics.cpu_system_ms = proc17_qa_wire_get_u64(resource + 16U);
    metrics.max_rss_bytes = proc17_qa_wire_get_u64(resource + 24U);
    current = proc17_qa_wire_get_u64(
        report + PROC17_QA_REPORT_ALLOCATOR_CURRENT_OFFSET);
    memset(&allocator, 0, sizeof(allocator));
    allocator.ceiling_bytes = proc17_qa_wire_get_u64(resource + 48U);
    allocator.current_bytes = current;
    allocator.peak_bytes = proc17_qa_wire_get_u64(resource + 40U);
    allocator.ceiling_denied = resource[80U];
    allocator.system_allocation_failed
        = report[PROC17_QA_REPORT_SYSTEM_FAILURE_OFFSET];
    allocator.status_notification_failed
        = report[PROC17_QA_REPORT_NOTIFICATION_FAILURE_OFFSET];
    return stdout_measurement.limit_bytes == PROC17_QA_STDOUT_BYTES
        && stderr_measurement.limit_bytes == PROC17_QA_STDERR_BYTES
        && allocator_shape_valid(&allocator,
            report[PROC17_QA_REPORT_HEAP_NOTIFICATION_OFFSET], reason)
        && reason_evidence_valid(reason, &cause, &termination,
            &stdout_measurement, &stderr_measurement, &metrics, &allocator);
}

int proc17_qa_controller_report_finalize(
    const unsigned char report[PROC17_QA_CONTROLLER_REPORT_BYTES],
    const struct proc17_qa_phase_identity *expected_identity,
    const unsigned char expected_process_token[PROC17_QA_WIRE_DIGEST_BYTES],
    int controller_wait_status,
    uint8_t namespace_cleanup_complete,
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES],
    size_t *frame_bytes)
{
    unsigned char payload[PROC17_QA_RUN_RESULT_V1_BYTES];
    size_t index;

    if (!private_report_valid(report)
        || !proc17_qa_phase_identity_valid(expected_identity)
        || expected_process_token == NULL
        || !proc17_qa_wire_digest_nonzero(expected_process_token)
        || memcmp(report + PROC17_QA_REPORT_IDENTITY_OFFSET,
            expected_identity, PROC17_QA_V1_IDENTITY_BYTES) != 0
        || memcmp(report + PROC17_QA_REPORT_TOKEN_OFFSET,
            expected_process_token, PROC17_QA_WIRE_DIGEST_BYTES) != 0
        || !WIFEXITED(controller_wait_status)
        || WEXITSTATUS(controller_wait_status) != 0
        || namespace_cleanup_complete != 1U
        || frame == NULL || frame_bytes == NULL) {
        return -1;
    }
    memset(payload, 0, sizeof(payload));
    memcpy(payload, expected_identity, PROC17_QA_V1_IDENTITY_BYTES);
    proc17_qa_wire_put_u16(payload + PROC17_QA_V1_PHASE_OFFSET,
        PROC17_QA_RUN_V1_PHASE_TERMINAL);
    proc17_qa_wire_put_u16(payload + 130U, PROC17_QA_RUN_CONTAINED);
    memcpy(payload + 132U, report + PROC17_QA_REPORT_REASON_OFFSET, 12U);
    memcpy(payload + 144U, report + PROC17_QA_REPORT_CAUSE_OFFSET, 20U);
    for (index = 0U; index < 8U; index++) {
        payload[PROC17_QA_V1_RESULT_FINALITY_OFFSET + index] = 1U;
    }
    memcpy(payload + PROC17_QA_V1_RESULT_STDOUT_OFFSET,
        report + PROC17_QA_REPORT_STDOUT_OFFSET,
        PROC17_QA_STREAM_MEASUREMENT_V1_BYTES);
    memcpy(payload + PROC17_QA_V1_RESULT_STDERR_OFFSET,
        report + PROC17_QA_REPORT_STDERR_OFFSET,
        PROC17_QA_STREAM_MEASUREMENT_V1_BYTES);
    memcpy(payload + PROC17_QA_V1_RESULT_RESOURCE_OFFSET,
        report + PROC17_QA_REPORT_RESOURCE_OFFSET,
        PROC17_QA_RESOURCE_MEASUREMENT_V1_BYTES);
    memcpy(payload + PROC17_QA_V1_RESULT_SCRATCH_OFFSET,
        report + PROC17_QA_REPORT_SCRATCH_OFFSET,
        PROC17_QA_SCRATCH_MEASUREMENT_V1_BYTES);
    memcpy(payload + PROC17_QA_V1_RESULT_STAGE_OFFSET,
        report + PROC17_QA_REPORT_STAGE_OFFSET,
        PROC17_QA_SOURCE_STAGE_V1_BYTES);
    if (!proc17_qa_wire_v1_result_valid(payload, sizeof(payload))) return -1;
    return proc17_qa_wire_encode_run_v1(PROC17_QA_WIRE_RUN_RESULT_V1,
        expected_identity->transaction, payload, sizeof(payload),
        frame, frame_bytes);
}
