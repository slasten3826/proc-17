#define _GNU_SOURCE

#include "proc17_qa_phase.h"

#include <errno.h>
#include <limits.h>
#include <string.h>
#include <sys/random.h>
#include <unistd.h>

#include "proc17_sha256.h"

#define PROC17_QA_FINALITY_MASK ((UINT16_C(1) << PROC17_QA_FINALITY_COUNT) - 1U)

_Static_assert(PROC17_QA_WIRE_ENVELOPE_BYTES
        + PROC17_QA_RUN_STARTED_V1_BYTES <= PIPE_BUF,
    "STARTED v1 must fit one atomic pipe write");
_Static_assert(sizeof(struct proc17_qa_phase_identity)
        == PROC17_QA_V1_IDENTITY_BYTES,
    "phase identity must match the RUN v1 wire identity prefix");
_Static_assert(PROC17_QA_FINALITY_COUNT == 8,
    "phase finality must match the RUN v1 wire contract");

static void close_owned_descriptor(int *descriptor)
{
    if (descriptor != NULL && *descriptor >= 0) {
        int ignored = close(*descriptor);
        (void)ignored;
        *descriptor = -1;
    }
}

void proc17_qa_phase_init(struct proc17_qa_phase_state *state)
{
    if (state != NULL) memset(state, 0, sizeof(*state));
}

int proc17_qa_phase_identity_valid(
    const struct proc17_qa_phase_identity *identity)
{
    return identity != NULL
        && proc17_qa_wire_digest_nonzero(identity->transaction)
        && proc17_qa_wire_digest_nonzero(identity->witness)
        && proc17_qa_wire_digest_nonzero(identity->profile)
        && proc17_qa_wire_digest_nonzero(identity->environment);
}

int proc17_qa_phase_make_process_token(
    const struct proc17_qa_phase_identity *identity,
    unsigned char output[PROC17_QA_WIRE_DIGEST_BYTES])
{
    unsigned char entropy[PROC17_QA_WIRE_DIGEST_BYTES];
    struct proc17_sha256 hash;
    ssize_t observed;

    if (!proc17_qa_phase_identity_valid(identity) || output == NULL) return -1;
    do {
        observed = getrandom(entropy, sizeof(entropy), 0U);
    } while (observed < 0 && errno == EINTR);
    if (observed != (ssize_t)sizeof(entropy)) {
        memset(entropy, 0, sizeof(entropy));
        return -1;
    }
    proc17_sha256_init(&hash);
    proc17_sha256_update(&hash, entropy, sizeof(entropy));
    proc17_sha256_update(&hash, identity, sizeof(*identity));
    proc17_sha256_final(&hash, output);
    memset(entropy, 0, sizeof(entropy));
    return proc17_qa_wire_digest_nonzero(output) ? 0 : -1;
}

int proc17_qa_phase_mark_finality(
    struct proc17_qa_phase_state *state,
    enum proc17_qa_phase_finality member)
{
    uint16_t bit;

    if (state == NULL || member < 0 || member >= PROC17_QA_FINALITY_COUNT) {
        return -1;
    }
    bit = (uint16_t)(UINT16_C(1) << (unsigned int)member);
    state->finality_mask = (uint16_t)(state->finality_mask | bit);
    return 0;
}

int proc17_qa_phase_emit_started_and_close(
    struct proc17_qa_phase_state *state,
    int *result_descriptor,
    const struct proc17_qa_phase_identity *identity,
    const unsigned char process_token[PROC17_QA_WIRE_DIGEST_BYTES],
    const unsigned char source_stage[PROC17_QA_SOURCE_STAGE_V1_BYTES])
{
    unsigned char payload[PROC17_QA_RUN_STARTED_V1_BYTES];
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t frame_bytes = 0;
    ssize_t written;
    int close_result;

    if (state == NULL || result_descriptor == NULL || *result_descriptor < 0
        || state->started_emitted != 0U
        || state->candidate_release_authorized != 0U
        || !proc17_qa_phase_identity_valid(identity)
        || !proc17_qa_wire_digest_nonzero(process_token)
        || !proc17_qa_wire_v1_source_stage_valid(source_stage)) {
        close_owned_descriptor(result_descriptor);
        return -1;
    }
    memset(payload, 0, sizeof(payload));
    memcpy(payload, identity, PROC17_QA_V1_IDENTITY_BYTES);
    proc17_qa_wire_put_u16(payload + PROC17_QA_V1_PHASE_OFFSET,
        PROC17_QA_RUN_V1_PHASE_STARTED);
    proc17_qa_wire_put_u16(payload + 130U, 1U);
    payload[132U] = 1U;
    payload[133U] = PROC17_QA_RUN_V1_PREPARED_UNDER_POLICY;
    memcpy(payload + 136U, process_token, PROC17_QA_WIRE_DIGEST_BYTES);
    memcpy(payload + PROC17_QA_V1_STARTED_STAGE_OFFSET, source_stage,
        PROC17_QA_SOURCE_STAGE_V1_BYTES);
    if (proc17_qa_wire_encode_run_v1(PROC17_QA_WIRE_RUN_STARTED_V1,
            identity->transaction, payload, sizeof(payload), frame,
            &frame_bytes) != 0 || frame_bytes > PIPE_BUF) {
        close_owned_descriptor(result_descriptor);
        return -1;
    }
    written = write(*result_descriptor, frame, frame_bytes);
    if (written != (ssize_t)frame_bytes) {
        close_owned_descriptor(result_descriptor);
        return -1;
    }
    state->started_emitted = 1U;
    (void)proc17_qa_phase_mark_finality(
        state, PROC17_QA_FINAL_SOURCE_STAGED);
    (void)proc17_qa_phase_mark_finality(
        state, PROC17_QA_FINAL_CANDIDATE_STARTED);
    close_result = close(*result_descriptor);
    *result_descriptor = -1;
    if (close_result != 0) return -1;
    state->result_descriptor_closed = 1U;
    return 0;
}

int proc17_qa_phase_authorize_candidate(
    struct proc17_qa_phase_state *state)
{
    if (state == NULL || state->started_emitted != 1U
        || state->result_descriptor_closed != 1U
        || state->candidate_release_authorized != 0U) {
        return -1;
    }
    state->candidate_release_authorized = 1U;
    return 0;
}

int proc17_qa_phase_claim_first_cause(
    struct proc17_qa_phase_state *state,
    uint16_t kind,
    uint64_t observed_value)
{
    uint64_t sequence;

    if (state == NULL || kind < PROC17_QA_RUN_EXPECTED_EXIT
        || kind > PROC17_QA_RUN_SANDBOX_POLICY_VIOLATION
        || state->next_sequence == UINT64_MAX) {
        return PROC17_QA_CAUSE_INVALID;
    }
    sequence = ++state->next_sequence;
    if (state->first_cause.kind != 0U) {
        return PROC17_QA_CAUSE_ALREADY_SET;
    }
    state->first_cause.kind = kind;
    state->first_cause.monotonic_sequence = sequence;
    state->first_cause.observed_value = observed_value;
    return PROC17_QA_CAUSE_SET;
}

int proc17_qa_phase_finality_complete(
    const struct proc17_qa_phase_state *state)
{
    return state != NULL && state->finality_mask == PROC17_QA_FINALITY_MASK;
}

int proc17_qa_phase_candidate_result_ready(
    const struct proc17_qa_phase_state *state)
{
    return state != NULL
        && state->started_emitted == 1U
        && state->result_descriptor_closed == 1U
        && state->candidate_release_authorized == 1U
        && state->first_cause.kind != 0U
        && state->first_cause.monotonic_sequence != 0U
        && proc17_qa_phase_finality_complete(state);
}
