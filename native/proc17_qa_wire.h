#ifndef PROC17_QA_WIRE_H
#define PROC17_QA_WIRE_H

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "proc17_sha256.h"

#define PROC17_QA_WIRE_MAGIC_BYTES 8U
#define PROC17_QA_WIRE_VERSION 0U
#define PROC17_QA_WIRE_NONCE_BYTES 32U
#define PROC17_QA_WIRE_DIGEST_BYTES 32U
#define PROC17_QA_WIRE_ENVELOPE_BYTES 80U
#define PROC17_QA_WIRE_MAX_FRAME_BYTES 4096U
#define PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS 10U
#define PROC17_QA_RUN_REQUEST_FIXED_BYTES 238U
#define PROC17_QA_RUN_RESULT_BYTES 388U
#define PROC17_QA_RUN_REQUEST_V1_FIXED_BYTES 238U
#define PROC17_QA_RUN_STARTED_V1_BYTES 252U
#define PROC17_QA_RUN_RESULT_V1_BYTES 512U
#define PROC17_QA_RUN_ERROR_V1_BYTES 268U
#define PROC17_QA_SOURCE_STAGE_V1_BYTES 84U
#define PROC17_QA_STREAM_MEASUREMENT_V1_BYTES 64U
#define PROC17_QA_RESOURCE_MEASUREMENT_V1_BYTES 88U
#define PROC17_QA_SCRATCH_MEASUREMENT_V1_BYTES 40U

#define PROC17_QA_V1_IDENTITY_BYTES 128U
#define PROC17_QA_V1_PHASE_OFFSET 128U
#define PROC17_QA_V1_STARTED_STAGE_OFFSET 168U
#define PROC17_QA_V1_RESULT_FINALITY_OFFSET 164U
#define PROC17_QA_V1_RESULT_STDOUT_OFFSET 172U
#define PROC17_QA_V1_RESULT_STDERR_OFFSET 236U
#define PROC17_QA_V1_RESULT_RESOURCE_OFFSET 300U
#define PROC17_QA_V1_RESULT_SCRATCH_OFFSET 388U
#define PROC17_QA_V1_RESULT_STAGE_OFFSET 428U
#define PROC17_QA_V1_ERROR_COST_OFFSET 144U
#define PROC17_QA_V1_ERROR_STAGE_OFFSET 184U

enum proc17_qa_run_disposition {
    PROC17_QA_RUN_CONTAINED = 1,
    PROC17_QA_RUN_PROCESS_ERROR = 2,
};

enum proc17_qa_run_reason {
    PROC17_QA_RUN_EXPECTED_EXIT = 1,
    PROC17_QA_RUN_UNEXPECTED_EXIT = 2,
    PROC17_QA_RUN_SIGNAL = 3,
    PROC17_QA_RUN_WALL_TIMEOUT = 4,
    PROC17_QA_RUN_CPU_LIMIT = 5,
    PROC17_QA_RUN_MEMORY_LIMIT = 6,
    PROC17_QA_RUN_OUTPUT_LIMIT = 7,
    PROC17_QA_RUN_SCRATCH_LIMIT = 8,
    PROC17_QA_RUN_SANDBOX_POLICY_VIOLATION = 9,
};

enum proc17_qa_termination_kind {
    PROC17_QA_TERMINATION_EXIT = 1,
    PROC17_QA_TERMINATION_SIGNAL = 2,
    PROC17_QA_TERMINATION_SUPERVISOR_KILL = 3,
};

enum proc17_qa_wire_kind {
    PROC17_QA_WIRE_PROBE_REQUEST = 1,
    PROC17_QA_WIRE_PROBE_RESULT = 2,
    PROC17_QA_WIRE_RUN_REQUEST = 3,
    PROC17_QA_WIRE_RUN_RESULT = 4,
    PROC17_QA_WIRE_RUN_REQUEST_V1 = 5,
    PROC17_QA_WIRE_RUN_STARTED_V1 = 6,
    PROC17_QA_WIRE_RUN_RESULT_V1 = 7,
    PROC17_QA_WIRE_RUN_ERROR_V1 = 8,
};

enum proc17_qa_run_v1_phase {
    PROC17_QA_RUN_V1_PHASE_STARTED = 1,
    PROC17_QA_RUN_V1_PHASE_TERMINAL = 2,
};

enum proc17_qa_run_v1_ready_state {
    PROC17_QA_RUN_V1_PREPARED_UNDER_POLICY = 1,
};

enum proc17_qa_run_v1_tri_state {
    PROC17_QA_RUN_V1_UNKNOWN = 1,
    PROC17_QA_RUN_V1_FALSE = 2,
    PROC17_QA_RUN_V1_TRUE = 3,
};

enum proc17_qa_run_v1_error_class {
    PROC17_QA_RUN_V1_ERROR_WORLD = 1,
    PROC17_QA_RUN_V1_ERROR_UNAVAILABLE = 2,
    PROC17_QA_RUN_V1_ERROR_AMBIGUOUS = 3,
};

enum proc17_qa_run_v1_error_code {
    PROC17_QA_RUN_V1_SUPERVISOR_UNAVAILABLE = 1,
    PROC17_QA_RUN_V1_SOURCE_STAGING_FAILED = 2,
    PROC17_QA_RUN_V1_SUPERVISOR_CRASHED = 3,
    PROC17_QA_RUN_V1_RESULT_PIPE_LOST = 4,
    PROC17_QA_RUN_V1_TERMINAL_FRAME_MISSING = 5,
    PROC17_QA_RUN_V1_REAP_AMBIGUOUS = 6,
    PROC17_QA_RUN_V1_OUTPUT_OBSERVATION_INCOMPLETE = 7,
    PROC17_QA_RUN_V1_SCRATCH_OBSERVATION_INCOMPLETE = 8,
    PROC17_QA_RUN_V1_NAMESPACE_CLEANUP_INCOMPLETE = 9,
};

enum proc17_qa_run_v1_error_stage {
    PROC17_QA_RUN_V1_ERROR_PREFLIGHT = 1,
    PROC17_QA_RUN_V1_ERROR_SOURCE_STAGING = 2,
    PROC17_QA_RUN_V1_ERROR_NAMESPACE = 3,
    PROC17_QA_RUN_V1_ERROR_LAUNCH = 4,
    PROC17_QA_RUN_V1_ERROR_SUPERVISION = 5,
    PROC17_QA_RUN_V1_ERROR_POSTFLIGHT = 6,
    PROC17_QA_RUN_V1_ERROR_CLEANUP = 7,
};

struct proc17_qa_wire_view {
    uint16_t kind;
    const unsigned char *nonce;
    const unsigned char *payload;
    uint32_t payload_bytes;
};

static inline void proc17_qa_wire_put_u16(unsigned char *output, uint16_t value)
{
    output[0] = (unsigned char)(value >> 8U);
    output[1] = (unsigned char)value;
}

static inline void proc17_qa_wire_put_u32(unsigned char *output, uint32_t value)
{
    output[0] = (unsigned char)(value >> 24U);
    output[1] = (unsigned char)(value >> 16U);
    output[2] = (unsigned char)(value >> 8U);
    output[3] = (unsigned char)value;
}

static inline void proc17_qa_wire_put_u64(unsigned char *output, uint64_t value)
{
    size_t index;
    for (index = 0; index < 8U; index++) {
        output[7U - index] = (unsigned char)(value >> (index * 8U));
    }
}

static inline uint16_t proc17_qa_wire_get_u16(const unsigned char *input)
{
    return (uint16_t)(((uint16_t)input[0] << 8U) | input[1]);
}

static inline uint32_t proc17_qa_wire_get_u32(const unsigned char *input)
{
    return ((uint32_t)input[0] << 24U)
        | ((uint32_t)input[1] << 16U)
        | ((uint32_t)input[2] << 8U)
        | input[3];
}

static inline uint64_t proc17_qa_wire_get_u64(const unsigned char *input)
{
    uint64_t value = 0;
    size_t index;
    for (index = 0; index < 8U; index++) {
        value = (value << 8U) | input[index];
    }
    return value;
}

static inline int proc17_qa_wire_kind_known(uint16_t kind)
{
    return kind == PROC17_QA_WIRE_PROBE_REQUEST
        || kind == PROC17_QA_WIRE_PROBE_RESULT
        || kind == PROC17_QA_WIRE_RUN_REQUEST
        || kind == PROC17_QA_WIRE_RUN_RESULT
        || kind == PROC17_QA_WIRE_RUN_REQUEST_V1
        || kind == PROC17_QA_WIRE_RUN_STARTED_V1
        || kind == PROC17_QA_WIRE_RUN_RESULT_V1
        || kind == PROC17_QA_WIRE_RUN_ERROR_V1;
}

static inline int proc17_qa_wire_encode(
    uint16_t kind,
    const unsigned char nonce[PROC17_QA_WIRE_NONCE_BYTES],
    const void *payload,
    uint32_t payload_bytes,
    unsigned char output[PROC17_QA_WIRE_MAX_FRAME_BYTES],
    size_t *output_bytes)
{
    static const unsigned char magic[PROC17_QA_WIRE_MAGIC_BYTES] = {
        'P', '1', '7', 'Q', 'A', '0', 0, 0,
    };
    unsigned char digest[PROC17_QA_WIRE_DIGEST_BYTES];
    size_t before_digest;
    size_t total;

    if (!proc17_qa_wire_kind_known(kind) || nonce == NULL
        || (payload_bytes > 0U && payload == NULL) || output == NULL
        || output_bytes == NULL
        || payload_bytes > PROC17_QA_WIRE_MAX_FRAME_BYTES
            - PROC17_QA_WIRE_ENVELOPE_BYTES) {
        return -1;
    }
    before_digest = 48U + payload_bytes;
    total = before_digest + PROC17_QA_WIRE_DIGEST_BYTES;
    memcpy(output, magic, sizeof(magic));
    proc17_qa_wire_put_u16(output + 8U, PROC17_QA_WIRE_VERSION);
    proc17_qa_wire_put_u16(output + 10U, kind);
    proc17_qa_wire_put_u32(output + 12U, payload_bytes);
    memcpy(output + 16U, nonce, PROC17_QA_WIRE_NONCE_BYTES);
    if (payload_bytes > 0U) {
        memcpy(output + 48U, payload, payload_bytes);
    }
    proc17_sha256_bytes(output, before_digest, digest);
    memcpy(output + before_digest, digest, sizeof(digest));
    *output_bytes = total;
    return 0;
}

static inline int proc17_qa_wire_decode(
    const unsigned char *frame,
    size_t frame_bytes,
    struct proc17_qa_wire_view *view)
{
    static const unsigned char magic[PROC17_QA_WIRE_MAGIC_BYTES] = {
        'P', '1', '7', 'Q', 'A', '0', 0, 0,
    };
    unsigned char expected[PROC17_QA_WIRE_DIGEST_BYTES];
    unsigned char mismatch = 0;
    uint16_t version;
    uint16_t kind;
    uint32_t payload_bytes;
    size_t before_digest;
    size_t index;

    if (frame == NULL || view == NULL
        || frame_bytes < PROC17_QA_WIRE_ENVELOPE_BYTES
        || frame_bytes > PROC17_QA_WIRE_MAX_FRAME_BYTES
        || memcmp(frame, magic, sizeof(magic)) != 0) {
        return -1;
    }
    version = proc17_qa_wire_get_u16(frame + 8U);
    kind = proc17_qa_wire_get_u16(frame + 10U);
    payload_bytes = proc17_qa_wire_get_u32(frame + 12U);
    if (version != PROC17_QA_WIRE_VERSION || !proc17_qa_wire_kind_known(kind)
        || payload_bytes > PROC17_QA_WIRE_MAX_FRAME_BYTES
            - PROC17_QA_WIRE_ENVELOPE_BYTES
        || frame_bytes != PROC17_QA_WIRE_ENVELOPE_BYTES + payload_bytes) {
        return -1;
    }
    before_digest = 48U + payload_bytes;
    proc17_sha256_bytes(frame, before_digest, expected);
    for (index = 0; index < sizeof(expected); index++) {
        mismatch |= expected[index] ^ frame[before_digest + index];
    }
    if (mismatch != 0U) {
        return -1;
    }
    view->kind = kind;
    view->nonce = frame + 16U;
    view->payload = frame + 48U;
    view->payload_bytes = payload_bytes;
    return 0;
}

static inline int proc17_qa_wire_bytes_zero(
    const unsigned char *bytes,
    size_t length)
{
    unsigned char combined = 0U;
    size_t index;

    if (bytes == NULL) return 0;
    for (index = 0; index < length; index++) combined |= bytes[index];
    return combined == 0U;
}

static inline int proc17_qa_wire_digest_nonzero(
    const unsigned char value[PROC17_QA_WIRE_DIGEST_BYTES])
{
    return value != NULL
        && !proc17_qa_wire_bytes_zero(value, PROC17_QA_WIRE_DIGEST_BYTES);
}

static inline int proc17_qa_wire_boolean(unsigned char value)
{
    return value == 0U || value == 1U;
}

static inline int proc17_qa_wire_tri_state(uint8_t value)
{
    return value == PROC17_QA_RUN_V1_UNKNOWN
        || value == PROC17_QA_RUN_V1_FALSE
        || value == PROC17_QA_RUN_V1_TRUE;
}

static inline int proc17_qa_wire_v1_identity_valid(
    const unsigned char *payload)
{
    return payload != NULL
        && proc17_qa_wire_digest_nonzero(payload)
        && proc17_qa_wire_digest_nonzero(payload + 32U)
        && proc17_qa_wire_digest_nonzero(payload + 64U)
        && proc17_qa_wire_digest_nonzero(payload + 96U);
}

static inline int proc17_qa_wire_v1_source_stage_valid(
    const unsigned char *stage)
{
    return stage != NULL
        && proc17_qa_wire_get_u16(stage) == 1U
        && stage[2U] == 0U && stage[3U] == 0U
        && proc17_qa_wire_get_u32(stage + 4U) != 0U
        && proc17_qa_wire_get_u64(stage + 8U) != 0U
        && proc17_qa_wire_get_u64(stage + 16U) != 0U
        && proc17_qa_wire_get_u64(stage + 24U) != 0U
        && proc17_qa_wire_get_u64(stage + 32U) != 0U
        && proc17_qa_wire_get_u64(stage + 40U) != 0U
        && proc17_qa_wire_get_u64(stage + 48U) != 0U
        && proc17_qa_wire_get_u64(stage + 56U) != 0U
        && proc17_qa_wire_get_u64(stage + 64U) != 0U
        && proc17_qa_wire_get_u64(stage + 72U) != 0U
        && proc17_qa_wire_boolean(stage[80U])
        && proc17_qa_wire_boolean(stage[81U])
        && stage[82U] == 0U && stage[83U] == 0U;
}

static inline int proc17_qa_wire_v1_stream_valid(
    const unsigned char *stream)
{
    uint64_t observed;
    uint64_t hashed;
    uint64_t limit;

    if (stream == NULL) return 0;
    observed = proc17_qa_wire_get_u64(stream);
    hashed = proc17_qa_wire_get_u64(stream + 8U);
    limit = proc17_qa_wire_get_u64(stream + 16U);
    return limit != 0U && hashed <= observed && hashed <= limit
        && proc17_qa_wire_digest_nonzero(stream + 24U)
        && proc17_qa_wire_boolean(stream[56U])
        && stream[57U] == 1U && stream[58U] == 0U
        && proc17_qa_wire_bytes_zero(stream + 59U, 5U)
        && ((stream[56U] != 0U) == (observed > limit));
}

static inline int proc17_qa_wire_v1_resource_valid(
    const unsigned char *resource)
{
    return resource != NULL
        && proc17_qa_wire_get_u64(resource + 32U) != 0U
        && proc17_qa_wire_get_u64(resource + 48U) != 0U
        && proc17_qa_wire_get_u64(resource + 56U) != 0U
        && proc17_qa_wire_get_u64(resource + 64U) != 0U
        && proc17_qa_wire_get_u64(resource + 72U) != 0U
        && proc17_qa_wire_boolean(resource[80U])
        && proc17_qa_wire_bytes_zero(resource + 81U, 7U);
}

static inline int proc17_qa_wire_v1_scratch_valid(
    const unsigned char *scratch)
{
    uint64_t bytes;
    uint64_t entries;
    uint64_t byte_limit;
    uint64_t entry_limit;

    if (scratch == NULL) return 0;
    bytes = proc17_qa_wire_get_u64(scratch);
    entries = proc17_qa_wire_get_u64(scratch + 8U);
    byte_limit = proc17_qa_wire_get_u64(scratch + 16U);
    entry_limit = proc17_qa_wire_get_u64(scratch + 24U);
    return byte_limit != 0U && entry_limit != 0U
        && bytes <= byte_limit && entries <= entry_limit
        && proc17_qa_wire_boolean(scratch[32U])
        && proc17_qa_wire_boolean(scratch[33U])
        && scratch[34U] == 1U
        && proc17_qa_wire_bytes_zero(scratch + 35U, 5U);
}

static inline int proc17_qa_wire_v1_request_valid(
    const unsigned char *payload,
    uint32_t payload_bytes)
{
    uint16_t path_bytes;

    if (payload == NULL
        || payload_bytes < PROC17_QA_RUN_REQUEST_V1_FIXED_BYTES
        || !proc17_qa_wire_v1_identity_valid(payload)) {
        return 0;
    }
    path_bytes = proc17_qa_wire_get_u16(payload + 236U);
    return path_bytes != 0U && path_bytes <= 1024U
        && payload_bytes == PROC17_QA_RUN_REQUEST_V1_FIXED_BYTES + path_bytes
        && proc17_qa_wire_get_u32(payload + 232U) == 0U
        && memchr(payload + PROC17_QA_RUN_REQUEST_V1_FIXED_BYTES,
            '\0', path_bytes) == NULL;
}

static inline int proc17_qa_wire_v1_started_valid(
    const unsigned char *payload,
    uint32_t payload_bytes)
{
    return payload_bytes == PROC17_QA_RUN_STARTED_V1_BYTES
        && proc17_qa_wire_v1_identity_valid(payload)
        && proc17_qa_wire_get_u16(payload + PROC17_QA_V1_PHASE_OFFSET)
            == PROC17_QA_RUN_V1_PHASE_STARTED
        && proc17_qa_wire_get_u16(payload + 130U) == 1U
        && payload[132U] == 1U
        && payload[133U] == PROC17_QA_RUN_V1_PREPARED_UNDER_POLICY
        && payload[134U] == 0U && payload[135U] == 0U
        && proc17_qa_wire_digest_nonzero(payload + 136U)
        && proc17_qa_wire_v1_source_stage_valid(
            payload + PROC17_QA_V1_STARTED_STAGE_OFFSET);
}

static inline int proc17_qa_wire_v1_result_valid(
    const unsigned char *payload,
    uint32_t payload_bytes)
{
    uint16_t reason;
    uint16_t termination;
    size_t index;

    if (payload_bytes != PROC17_QA_RUN_RESULT_V1_BYTES
        || !proc17_qa_wire_v1_identity_valid(payload)
        || proc17_qa_wire_get_u16(payload + PROC17_QA_V1_PHASE_OFFSET)
            != PROC17_QA_RUN_V1_PHASE_TERMINAL
        || proc17_qa_wire_get_u16(payload + 130U)
            != PROC17_QA_RUN_CONTAINED) {
        return 0;
    }
    reason = proc17_qa_wire_get_u16(payload + 132U);
    termination = proc17_qa_wire_get_u16(payload + 134U);
    if (reason < PROC17_QA_RUN_EXPECTED_EXIT
        || reason > PROC17_QA_RUN_SANDBOX_POLICY_VIOLATION
        || termination < PROC17_QA_TERMINATION_EXIT
        || termination > PROC17_QA_TERMINATION_SUPERVISOR_KILL
        || proc17_qa_wire_get_u16(payload + 144U) != reason
        || proc17_qa_wire_get_u16(payload + 146U) != 0U
        || proc17_qa_wire_get_u64(payload + 148U) == 0U) {
        return 0;
    }
    for (index = 0; index < 8U; index++) {
        if (payload[PROC17_QA_V1_RESULT_FINALITY_OFFSET + index] != 1U) {
            return 0;
        }
    }
    return proc17_qa_wire_v1_stream_valid(
            payload + PROC17_QA_V1_RESULT_STDOUT_OFFSET)
        && proc17_qa_wire_v1_stream_valid(
            payload + PROC17_QA_V1_RESULT_STDERR_OFFSET)
        && proc17_qa_wire_v1_resource_valid(
            payload + PROC17_QA_V1_RESULT_RESOURCE_OFFSET)
        && proc17_qa_wire_v1_scratch_valid(
            payload + PROC17_QA_V1_RESULT_SCRATCH_OFFSET)
        && proc17_qa_wire_v1_source_stage_valid(
            payload + PROC17_QA_V1_RESULT_STAGE_OFFSET);
}

static inline int proc17_qa_wire_v1_error_valid(
    const unsigned char *payload,
    uint32_t payload_bytes)
{
    uint16_t phase;
    uint16_t error_class;
    uint16_t code;
    uint16_t stage;
    int source_known;

    if (payload_bytes != PROC17_QA_RUN_ERROR_V1_BYTES
        || !proc17_qa_wire_v1_identity_valid(payload)) {
        return 0;
    }
    phase = proc17_qa_wire_get_u16(payload + PROC17_QA_V1_PHASE_OFFSET);
    error_class = proc17_qa_wire_get_u16(payload + 130U);
    code = proc17_qa_wire_get_u16(payload + 132U);
    stage = proc17_qa_wire_get_u16(payload + 134U);
    source_known = payload[139U] != 0U;
    if ((phase != PROC17_QA_RUN_V1_PHASE_STARTED
            && phase != PROC17_QA_RUN_V1_PHASE_TERMINAL)
        || error_class < PROC17_QA_RUN_V1_ERROR_WORLD
        || error_class > PROC17_QA_RUN_V1_ERROR_AMBIGUOUS
        || code < PROC17_QA_RUN_V1_SUPERVISOR_UNAVAILABLE
        || code > PROC17_QA_RUN_V1_NAMESPACE_CLEANUP_INCOMPLETE
        || stage < PROC17_QA_RUN_V1_ERROR_PREFLIGHT
        || stage > PROC17_QA_RUN_V1_ERROR_CLEANUP
        || !proc17_qa_wire_tri_state(payload[136U])
        || !proc17_qa_wire_tri_state(payload[137U])
        || !proc17_qa_wire_boolean(payload[138U])
        || !proc17_qa_wire_boolean(payload[139U])
        || !proc17_qa_wire_bytes_zero(payload + 140U, 4U)) {
        return 0;
    }
    if ((phase == PROC17_QA_RUN_V1_PHASE_STARTED
            && payload[136U] == PROC17_QA_RUN_V1_TRUE)
        || (phase == PROC17_QA_RUN_V1_PHASE_TERMINAL
            && payload[136U] != PROC17_QA_RUN_V1_TRUE)) {
        return 0;
    }
    if (payload[138U] == 0U
        && !proc17_qa_wire_bytes_zero(
            payload + PROC17_QA_V1_ERROR_COST_OFFSET, 40U)) {
        return 0;
    }
    if (source_known) {
        return proc17_qa_wire_v1_source_stage_valid(
            payload + PROC17_QA_V1_ERROR_STAGE_OFFSET);
    }
    return proc17_qa_wire_bytes_zero(
        payload + PROC17_QA_V1_ERROR_STAGE_OFFSET,
        PROC17_QA_SOURCE_STAGE_V1_BYTES);
}

static inline int proc17_qa_wire_v1_payload_valid(
    uint16_t kind,
    const unsigned char *payload,
    uint32_t payload_bytes)
{
    switch (kind) {
    case PROC17_QA_WIRE_RUN_REQUEST_V1:
        return proc17_qa_wire_v1_request_valid(payload, payload_bytes);
    case PROC17_QA_WIRE_RUN_STARTED_V1:
        return proc17_qa_wire_v1_started_valid(payload, payload_bytes);
    case PROC17_QA_WIRE_RUN_RESULT_V1:
        return proc17_qa_wire_v1_result_valid(payload, payload_bytes);
    case PROC17_QA_WIRE_RUN_ERROR_V1:
        return proc17_qa_wire_v1_error_valid(payload, payload_bytes);
    default:
        return 0;
    }
}

static inline int proc17_qa_wire_encode_run_v1(
    uint16_t kind,
    const unsigned char nonce[PROC17_QA_WIRE_NONCE_BYTES],
    const void *payload,
    uint32_t payload_bytes,
    unsigned char output[PROC17_QA_WIRE_MAX_FRAME_BYTES],
    size_t *output_bytes)
{
    if (!proc17_qa_wire_v1_payload_valid(
            kind, (const unsigned char *)payload, payload_bytes)) {
        return -1;
    }
    return proc17_qa_wire_encode(
        kind, nonce, payload, payload_bytes, output, output_bytes);
}

static inline int proc17_qa_wire_decode_run_v1(
    const unsigned char *frame,
    size_t frame_bytes,
    struct proc17_qa_wire_view *view)
{
    if (proc17_qa_wire_decode(frame, frame_bytes, view) != 0
        || !proc17_qa_wire_v1_payload_valid(
            view->kind, view->payload, view->payload_bytes)
        || memcmp(view->nonce, view->payload,
            PROC17_QA_WIRE_NONCE_BYTES) != 0) {
        return -1;
    }
    return 0;
}

#endif
