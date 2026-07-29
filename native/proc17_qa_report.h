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

#define PROC17_QA_CONTROLLER_REPORT_VERSION 2U
#define PROC17_QA_CONTROLLER_REPORT_BYTES 572U

enum proc17_qa_controller_terminal_kind {
    PROC17_QA_CONTROLLER_TERMINAL_RESULT = 1,
    PROC17_QA_CONTROLLER_TERMINAL_ERROR = 2,
};

enum proc17_qa_controller_error_subject {
    PROC17_QA_CONTROLLER_ERROR_STDOUT = 1,
    PROC17_QA_CONTROLLER_ERROR_STDERR = 2,
    PROC17_QA_CONTROLLER_ERROR_SCRATCH = 3,
};

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

struct proc17_qa_controller_error_input {
    const struct proc17_qa_phase_identity *identity;
    const unsigned char *process_token;
    const unsigned char *source_stage;
    uint16_t error_code;
    uint16_t subject;
    uint8_t candidate_terminal_observed;
    uint8_t process_tree_reaped;
    uint8_t stdout_eof_observed;
    uint8_t stderr_eof_observed;
    uint8_t scratch_observation_complete;
    uint8_t status_eof_observed;
};

struct proc17_qa_namespace_observation {
    uint8_t controller_pidfd_identity_retained;
    uint8_t terminal_record_complete;
    uint8_t terminal_record_eof_observed;
    uint8_t controller_reaped;
    uint8_t controller_authority_closed;
};

int proc17_qa_controller_report_build(
    const struct proc17_qa_controller_report_input *input,
    unsigned char output[PROC17_QA_CONTROLLER_REPORT_BYTES]);

int proc17_qa_controller_error_build(
    const struct proc17_qa_controller_error_input *input,
    unsigned char output[PROC17_QA_CONTROLLER_REPORT_BYTES]);

int proc17_qa_namespace_cleanup_observe(
    const struct proc17_qa_namespace_observation *observation,
    int controller_wait_status,
    uint8_t *complete);

int proc17_qa_controller_report_finalize(
    const unsigned char report[PROC17_QA_CONTROLLER_REPORT_BYTES],
    const struct proc17_qa_phase_identity *expected_identity,
    const unsigned char expected_process_token[PROC17_QA_WIRE_DIGEST_BYTES],
    int controller_wait_status,
    const struct proc17_qa_namespace_observation *namespace_observation,
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES],
    size_t *frame_bytes);

#endif
