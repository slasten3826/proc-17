#ifndef PROC17_QA_REPORT_H
#define PROC17_QA_REPORT_H

#include <stddef.h>
#include <stdint.h>

#include "proc17_qa_allocator.h"
#include "proc17_qa_controller.h"
#include "proc17_qa_phase.h"
#include "proc17_qa_scratch.h"
#include "proc17_qa_stream.h"
#include "proc17_qa_wire.h"

#define PROC17_QA_CONTROLLER_REPORT_VERSION 1U
#define PROC17_QA_CONTROLLER_REPORT_BYTES 572U

struct proc17_qa_candidate_termination {
    uint16_t kind;
    uint32_t exit_code;
    uint32_t signal_number;
};

struct proc17_qa_controller_report_input {
    const struct proc17_qa_phase_identity *identity;
    const unsigned char *process_token;
    const struct proc17_qa_phase_state *phase;
    struct proc17_qa_candidate_termination termination;
    const struct proc17_qa_stream_measurement *stdout_measurement;
    const struct proc17_qa_stream_measurement *stderr_measurement;
    const struct proc17_qa_candidate_metrics *candidate_metrics;
    const struct proc17_qa_allocator_snapshot *allocator;
    const struct proc17_qa_scratch_measurement *scratch;
    const unsigned char *source_stage;
    uint8_t status_eof_observed;
    uint8_t allocator_observation_stable;
    uint8_t heap_denied_notifications;
};

int proc17_qa_controller_report_build(
    const struct proc17_qa_controller_report_input *input,
    unsigned char output[PROC17_QA_CONTROLLER_REPORT_BYTES]);

int proc17_qa_controller_report_finalize(
    const unsigned char report[PROC17_QA_CONTROLLER_REPORT_BYTES],
    const struct proc17_qa_phase_identity *expected_identity,
    const unsigned char expected_process_token[PROC17_QA_WIRE_DIGEST_BYTES],
    int controller_wait_status,
    uint8_t namespace_cleanup_complete,
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES],
    size_t *frame_bytes);

#endif
