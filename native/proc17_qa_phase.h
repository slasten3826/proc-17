#ifndef PROC17_QA_PHASE_H
#define PROC17_QA_PHASE_H

#include <stddef.h>
#include <stdint.h>

#include "proc17_qa_wire.h"

enum proc17_qa_phase_finality {
    PROC17_QA_FINAL_SOURCE_STAGED = 0,
    PROC17_QA_FINAL_CANDIDATE_STARTED = 1,
    PROC17_QA_FINAL_CANDIDATE_TERMINAL = 2,
    PROC17_QA_FINAL_PROCESS_TREE_REAPED = 3,
    PROC17_QA_FINAL_STDOUT_EOF = 4,
    PROC17_QA_FINAL_STDERR_EOF = 5,
    PROC17_QA_FINAL_SCRATCH_OBSERVED = 6,
    PROC17_QA_FINAL_NAMESPACE_CLEAN = 7,
    PROC17_QA_FINALITY_COUNT = 8,
};

enum proc17_qa_phase_claim_result {
    PROC17_QA_CAUSE_INVALID = -1,
    PROC17_QA_CAUSE_ALREADY_SET = 0,
    PROC17_QA_CAUSE_SET = 1,
};

struct proc17_qa_phase_identity {
    unsigned char transaction[PROC17_QA_WIRE_DIGEST_BYTES];
    unsigned char witness[PROC17_QA_WIRE_DIGEST_BYTES];
    unsigned char profile[PROC17_QA_WIRE_DIGEST_BYTES];
    unsigned char environment[PROC17_QA_WIRE_DIGEST_BYTES];
};

struct proc17_qa_first_cause {
    uint16_t kind;
    uint64_t monotonic_sequence;
    uint64_t observed_value;
};

struct proc17_qa_phase_state {
    uint64_t next_sequence;
    struct proc17_qa_first_cause first_cause;
    uint16_t finality_mask;
    uint8_t started_attested;
    uint8_t candidate_release_authorized;
};

struct proc17_qa_started_writer_state {
    uint8_t started_emitted;
    uint8_t result_descriptor_closed;
};

void proc17_qa_phase_init(struct proc17_qa_phase_state *state);

void proc17_qa_started_writer_init(
    struct proc17_qa_started_writer_state *state);

int proc17_qa_phase_identity_valid(
    const struct proc17_qa_phase_identity *identity);

int proc17_qa_phase_make_process_token(
    const struct proc17_qa_phase_identity *identity,
    unsigned char output[PROC17_QA_WIRE_DIGEST_BYTES]);

int proc17_qa_phase_emit_started_and_close(
    struct proc17_qa_started_writer_state *state,
    int *result_descriptor,
    const struct proc17_qa_phase_identity *identity,
    const unsigned char process_token[PROC17_QA_WIRE_DIGEST_BYTES],
    const unsigned char source_stage[PROC17_QA_SOURCE_STAGE_V1_BYTES]);

int proc17_qa_phase_authorize_candidate(
    struct proc17_qa_phase_state *state);

int proc17_qa_phase_claim_first_cause(
    struct proc17_qa_phase_state *state,
    uint16_t kind,
    uint64_t observed_value);

int proc17_qa_phase_mark_finality(
    struct proc17_qa_phase_state *state,
    enum proc17_qa_phase_finality member);

int proc17_qa_phase_finality_complete(
    const struct proc17_qa_phase_state *state);

int proc17_qa_phase_candidate_result_ready(
    const struct proc17_qa_phase_state *state);

int proc17_qa_phase_controller_report_ready(
    const struct proc17_qa_phase_state *state);

#endif
