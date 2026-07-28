#define _GNU_SOURCE

#include "../proc17_qa_phase.h"
#include "../proc17_qa_status.h"

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static void fill_identity(struct proc17_qa_phase_identity *identity)
{
    memset(identity, 0, sizeof(*identity));
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
    for (index = 0; index < 9U; index++) {
        proc17_qa_wire_put_u64(stage + 8U + index * 8U, index + 1U);
    }
    stage[80U] = 1U;
    stage[81U] = 1U;
}

static int test_started_and_release(void)
{
    struct proc17_qa_phase_identity identity;
    struct proc17_qa_phase_state state;
    struct proc17_qa_started_writer_state writer;
    struct proc17_qa_status_message ready = {
        .kind = PROC17_QA_STATUS_READY,
        .sequence = 1U,
    };
    unsigned char stage[PROC17_QA_SOURCE_STAGE_V1_BYTES];
    unsigned char token[PROC17_QA_WIRE_DIGEST_BYTES];
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    struct proc17_qa_wire_view view;
    int descriptors[2];
    int duplicate[2];
    ssize_t observed;

    fill_identity(&identity);
    fill_stage(stage);
    proc17_qa_phase_init(&state);
    proc17_qa_started_writer_init(&writer);
    if (!proc17_qa_phase_identity_valid(&identity)
        || proc17_qa_phase_make_process_token(&identity, token) != 0
        || proc17_qa_phase_authorize_candidate(&state) == 0
        || pipe2(descriptors, O_CLOEXEC) != 0) {
        return -1;
    }
    if (proc17_qa_phase_emit_started_and_close(&writer, &descriptors[1],
            &identity, token, stage) != 0
        || descriptors[1] != -1
        || writer.started_emitted != 1U
        || writer.result_descriptor_closed != 1U
        || state.started_attested != 0U
        || state.candidate_release_authorized != 0U) {
        close(descriptors[0]);
        return -1;
    }
    observed = read(descriptors[0], frame, sizeof(frame));
    close(descriptors[0]);
    if (observed != (ssize_t)(PROC17_QA_WIRE_ENVELOPE_BYTES
            + PROC17_QA_RUN_STARTED_V1_BYTES)
        || proc17_qa_wire_decode_run_v1(frame, (size_t)observed, &view) != 0
        || view.kind != PROC17_QA_WIRE_RUN_STARTED_V1
        || memcmp(view.nonce, identity.transaction,
            PROC17_QA_WIRE_DIGEST_BYTES) != 0
        || memcmp(view.payload, &identity, sizeof(identity)) != 0
        || memcmp(view.payload + 136U, token, sizeof(token)) != 0
        || proc17_qa_status_accept_ready(&ready, &state) != 0
        || proc17_qa_status_accept_ready(&ready, &state) == 0
        || proc17_qa_phase_authorize_candidate(&state) != 0
        || proc17_qa_phase_authorize_candidate(&state) == 0) {
        return -1;
    }
    if (pipe2(duplicate, O_CLOEXEC) != 0) return -1;
    if (proc17_qa_phase_emit_started_and_close(&writer, &duplicate[1],
            &identity, token, stage) == 0
        || duplicate[1] != -1
        || read(duplicate[0], frame, sizeof(frame)) != 0) {
        close(duplicate[0]);
        if (duplicate[1] >= 0) close(duplicate[1]);
        return -1;
    }
    close(duplicate[0]);
    return 0;
}

static int test_failed_started_never_releases(void)
{
    struct proc17_qa_phase_identity identity;
    struct proc17_qa_phase_state state;
    struct proc17_qa_started_writer_state writer;
    unsigned char stage[PROC17_QA_SOURCE_STAGE_V1_BYTES];
    unsigned char token[PROC17_QA_WIRE_DIGEST_BYTES];
    unsigned char fill[4096];
    int descriptors[2];
    int flags;

    fill_identity(&identity);
    fill_stage(stage);
    memset(token, 0x55, sizeof(token));
    memset(fill, 0xa5, sizeof(fill));
    proc17_qa_phase_init(&state);
    proc17_qa_started_writer_init(&writer);
    if (pipe2(descriptors, O_CLOEXEC | O_NONBLOCK) != 0) return -1;
    for (;;) {
        ssize_t written = write(descriptors[1], fill, sizeof(fill));
        if (written > 0) continue;
        if (written < 0 && errno == EINTR) continue;
        if (written < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) break;
        close(descriptors[0]);
        close(descriptors[1]);
        return -1;
    }
    flags = proc17_qa_phase_emit_started_and_close(&writer, &descriptors[1],
        &identity, token, stage);
    close(descriptors[0]);
    if (flags == 0 || descriptors[1] != -1 || writer.started_emitted != 0U
        || writer.result_descriptor_closed != 0U
        || state.candidate_release_authorized != 0U
        || state.finality_mask != 0U
        || proc17_qa_phase_candidate_result_ready(&state)
        || proc17_qa_phase_authorize_candidate(&state) == 0) {
        return -1;
    }
    return 0;
}

static int test_first_cause_and_finality(void)
{
    struct proc17_qa_phase_state state;
    struct proc17_qa_first_cause first;
    struct proc17_qa_status_message ready = {
        .kind = PROC17_QA_STATUS_READY,
        .sequence = 1U,
    };
    int member;

    proc17_qa_phase_init(&state);
    if (proc17_qa_phase_claim_first_cause(&state, 0U, 1U)
            != PROC17_QA_CAUSE_INVALID
        || state.next_sequence != 0U
        || proc17_qa_phase_claim_first_cause(&state,
            PROC17_QA_RUN_CPU_LIMIT, 20000U) != PROC17_QA_CAUSE_SET) {
        return -1;
    }
    first = state.first_cause;
    if (proc17_qa_phase_claim_first_cause(&state,
            PROC17_QA_RUN_WALL_TIMEOUT, 30000U)
            != PROC17_QA_CAUSE_ALREADY_SET
        || first.kind != state.first_cause.kind
        || first.monotonic_sequence != state.first_cause.monotonic_sequence
        || first.observed_value != state.first_cause.observed_value
        || first.kind != PROC17_QA_RUN_CPU_LIMIT
        || first.monotonic_sequence != 1U
        || first.observed_value != 20000U
        || state.next_sequence != 2U
        || proc17_qa_phase_finality_complete(&state)
        || proc17_qa_phase_candidate_result_ready(&state)) {
        return -1;
    }
    proc17_qa_phase_init(&state);
    if (proc17_qa_status_accept_ready(&ready, &state) != 0
        || proc17_qa_phase_authorize_candidate(&state) != 0
        || proc17_qa_phase_claim_first_cause(&state,
            PROC17_QA_RUN_CPU_LIMIT, 20000U) != PROC17_QA_CAUSE_SET
        || proc17_qa_phase_mark_finality(&state,
            PROC17_QA_FINALITY_COUNT) == 0
        || state.finality_mask != 3U) {
        return -1;
    }
    for (member = PROC17_QA_FINAL_CANDIDATE_TERMINAL;
            member < PROC17_QA_FINALITY_COUNT; member++) {
        if (proc17_qa_phase_mark_finality(&state,
                (enum proc17_qa_phase_finality)member) != 0) {
            return -1;
        }
        if (member + 1 < PROC17_QA_FINALITY_COUNT
            && proc17_qa_phase_candidate_result_ready(&state)) {
            return -1;
        }
        if ((member == PROC17_QA_FINAL_SCRATCH_OBSERVED)
                != proc17_qa_phase_controller_report_ready(&state)) {
            return -1;
        }
    }
    if (!proc17_qa_phase_finality_complete(&state)
        || !proc17_qa_phase_candidate_result_ready(&state)
        || proc17_qa_phase_controller_report_ready(&state)
        || proc17_qa_phase_mark_finality(&state,
            PROC17_QA_FINAL_NAMESPACE_CLEAN) != 0
        || !proc17_qa_phase_candidate_result_ready(&state)) {
        return -1;
    }
    return 0;
}

int main(void)
{
    if (test_started_and_release() != 0
        || test_failed_started_never_releases() != 0
        || test_first_cause_and_finality() != 0) {
        return 1;
    }
    puts("proc17 QA phase physics ok");
    return 0;
}
