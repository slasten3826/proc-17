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
        || kind == PROC17_QA_WIRE_RUN_RESULT;
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

#endif
