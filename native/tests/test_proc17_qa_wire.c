#include "../proc17_qa_wire.h"

#include <stdio.h>
#include <string.h>

#ifndef PROC17_QA_WIRE_MAGIC_BYTES
#error "wire magic width required"
#endif
#ifndef PROC17_QA_WIRE_VERSION
#error "wire protocol version required"
#endif
#ifndef PROC17_QA_WIRE_NONCE_BYTES
#error "wire transaction nonce width required"
#endif
#ifndef PROC17_QA_WIRE_DIGEST_BYTES
#error "wire digest width required"
#endif
#ifndef PROC17_QA_WIRE_ENVELOPE_BYTES
#error "wire envelope width required"
#endif
#ifndef PROC17_QA_WIRE_MAX_FRAME_BYTES
#error "wire frame ceiling required"
#endif
#ifndef PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS
#error "wire resource-limit field count required"
#endif

_Static_assert(PROC17_QA_WIRE_MAGIC_BYTES == 8U, "wire magic width");
_Static_assert(PROC17_QA_WIRE_VERSION == 0U, "wire protocol version");
_Static_assert(PROC17_QA_WIRE_NONCE_BYTES == 32U, "wire nonce width");
_Static_assert(PROC17_QA_WIRE_DIGEST_BYTES == 32U, "wire digest width");
_Static_assert(PROC17_QA_WIRE_ENVELOPE_BYTES == 80U, "wire envelope width");
_Static_assert(PROC17_QA_WIRE_MAX_FRAME_BYTES == 4096U, "wire frame ceiling");
_Static_assert(PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS == 10U,
    "wire resource-limit field count");
_Static_assert(PROC17_QA_RUN_STARTED_V1_BYTES == 252U,
    "RUN STARTED v1 width");
_Static_assert(PROC17_QA_RUN_RESULT_V1_BYTES == 512U,
    "RUN RESULT v1 width");
_Static_assert(PROC17_QA_RUN_ERROR_V1_BYTES == 268U,
    "RUN ERROR v1 width");
_Static_assert(PROC17_QA_V1_STARTED_STAGE_OFFSET
        + PROC17_QA_SOURCE_STAGE_V1_BYTES == PROC17_QA_RUN_STARTED_V1_BYTES,
    "RUN STARTED v1 layout");
_Static_assert(PROC17_QA_V1_RESULT_STAGE_OFFSET
        + PROC17_QA_SOURCE_STAGE_V1_BYTES == PROC17_QA_RUN_RESULT_V1_BYTES,
    "RUN RESULT v1 layout");
_Static_assert(PROC17_QA_V1_ERROR_STAGE_OFFSET
        + PROC17_QA_SOURCE_STAGE_V1_BYTES == PROC17_QA_RUN_ERROR_V1_BYTES,
    "RUN ERROR v1 layout");

int proc17_qa_wire_contract_syntax_only(void)
{
    return 0;
}

static int rejected(const unsigned char *frame, size_t bytes)
{
    struct proc17_qa_wire_view view;
    return proc17_qa_wire_decode(frame, bytes, &view) != 0;
}

static void fill_identity(unsigned char *payload)
{
    memset(payload, 0x11, 32U);
    memset(payload + 32U, 0x22, 32U);
    memset(payload + 64U, 0x33, 32U);
    memset(payload + 96U, 0x44, 32U);
}

static void fill_stage(unsigned char *stage)
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

static void fill_stream(
    unsigned char *stream,
    const unsigned char empty_digest[PROC17_SHA256_BYTES])
{
    memset(stream, 0, PROC17_QA_STREAM_MEASUREMENT_V1_BYTES);
    proc17_qa_wire_put_u64(stream + 16U, 1024U);
    memcpy(stream + 24U, empty_digest, PROC17_SHA256_BYTES);
    stream[57U] = 1U;
}

static void fill_result(
    unsigned char *payload,
    const unsigned char empty_digest[PROC17_SHA256_BYTES])
{
    unsigned char *resource;
    unsigned char *scratch;
    memset(payload, 0, PROC17_QA_RUN_RESULT_V1_BYTES);
    fill_identity(payload);
    proc17_qa_wire_put_u16(payload + 128U, PROC17_QA_RUN_V1_PHASE_TERMINAL);
    proc17_qa_wire_put_u16(payload + 130U, PROC17_QA_RUN_CONTAINED);
    proc17_qa_wire_put_u16(payload + 132U, PROC17_QA_RUN_EXPECTED_EXIT);
    proc17_qa_wire_put_u16(payload + 134U, PROC17_QA_TERMINATION_EXIT);
    proc17_qa_wire_put_u32(payload + 136U, 0U);
    proc17_qa_wire_put_u32(payload + 140U, UINT32_MAX);
    proc17_qa_wire_put_u16(payload + 144U, PROC17_QA_RUN_EXPECTED_EXIT);
    proc17_qa_wire_put_u64(payload + 148U, 1U);
    memset(payload + PROC17_QA_V1_RESULT_FINALITY_OFFSET, 1, 8U);
    fill_stream(payload + PROC17_QA_V1_RESULT_STDOUT_OFFSET, empty_digest);
    fill_stream(payload + PROC17_QA_V1_RESULT_STDERR_OFFSET, empty_digest);
    resource = payload + PROC17_QA_V1_RESULT_RESOURCE_OFFSET;
    proc17_qa_wire_put_u64(resource + 32U, 268435456U);
    proc17_qa_wire_put_u64(resource + 48U, 67108864U);
    proc17_qa_wire_put_u64(resource + 56U, 1U);
    proc17_qa_wire_put_u64(resource + 64U, 64U);
    proc17_qa_wire_put_u64(resource + 72U, 16777216U);
    scratch = payload + PROC17_QA_V1_RESULT_SCRATCH_OFFSET;
    proc17_qa_wire_put_u64(scratch + 16U, 67108864U);
    proc17_qa_wire_put_u64(scratch + 24U, 4096U);
    scratch[34U] = 1U;
    fill_stage(payload + PROC17_QA_V1_RESULT_STAGE_OFFSET);
}

static int v1_round_trip(
    uint16_t kind,
    unsigned char *payload,
    uint32_t payload_bytes)
{
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    struct proc17_qa_wire_view view;
    size_t frame_bytes;

    if (proc17_qa_wire_encode_run_v1(kind, payload, payload,
            payload_bytes, frame, &frame_bytes) != 0
        || proc17_qa_wire_decode_run_v1(frame, frame_bytes, &view) != 0
        || view.kind != kind || view.payload_bytes != payload_bytes
        || memcmp(view.payload, payload, payload_bytes) != 0) {
        return -1;
    }
    return 0;
}

int main(void)
{
    static const unsigned char expected_empty[PROC17_SHA256_BYTES] = {
        0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14,
        0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f, 0xb9, 0x24,
        0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c,
        0xa4, 0x95, 0x99, 0x1b, 0x78, 0x52, 0xb8, 0x55,
    };
    unsigned char nonce[PROC17_QA_WIRE_NONCE_BYTES];
    unsigned char payload[17];
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char mutated[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char hash[PROC17_SHA256_BYTES];
    unsigned char request_v1[PROC17_QA_RUN_REQUEST_V1_FIXED_BYTES + 13U];
    unsigned char started_v1[PROC17_QA_RUN_STARTED_V1_BYTES];
    unsigned char result_v1[PROC17_QA_RUN_RESULT_V1_BYTES];
    unsigned char error_v1[PROC17_QA_RUN_ERROR_V1_BYTES];
    struct proc17_qa_wire_view view;
    size_t bytes;

    memset(nonce, 0xa5, sizeof(nonce));
    memset(payload, 0x3c, sizeof(payload));
    proc17_sha256_bytes("", 0U, hash);
    if (memcmp(hash, expected_empty, sizeof(hash)) != 0) {
        return 1;
    }
    if (proc17_qa_wire_encode(PROC17_QA_WIRE_PROBE_REQUEST,
            nonce, payload, sizeof(payload), frame, &bytes) != 0
        || bytes != PROC17_QA_WIRE_ENVELOPE_BYTES + sizeof(payload)
        || proc17_qa_wire_decode(frame, bytes, &view) != 0
        || view.kind != PROC17_QA_WIRE_PROBE_REQUEST
        || view.payload_bytes != sizeof(payload)
        || memcmp(view.nonce, nonce, sizeof(nonce)) != 0
        || memcmp(view.payload, payload, sizeof(payload)) != 0) {
        return 1;
    }

    if (!rejected(frame, bytes - 1U) || !rejected(frame, bytes + 1U)) {
        return 1;
    }
    memcpy(mutated, frame, bytes);
    mutated[0] ^= 1U;
    if (!rejected(mutated, bytes)) return 1;
    memcpy(mutated, frame, bytes);
    mutated[9] = 1U;
    if (!rejected(mutated, bytes)) return 1;
    memcpy(mutated, frame, bytes);
    proc17_qa_wire_put_u16(mutated + 10U, UINT16_MAX);
    if (!rejected(mutated, bytes)) return 1;
    memcpy(mutated, frame, bytes);
    proc17_qa_wire_put_u32(mutated + 12U, UINT32_MAX);
    if (!rejected(mutated, bytes)) return 1;
    memcpy(mutated, frame, bytes);
    mutated[48U] ^= 1U;
    if (!rejected(mutated, bytes)) return 1;
    if (proc17_qa_wire_encode(PROC17_QA_WIRE_PROBE_REQUEST, nonce,
            frame, PROC17_QA_WIRE_MAX_FRAME_BYTES, mutated, &bytes) == 0) {
        return 1;
    }

    memset(request_v1, 0, sizeof(request_v1));
    fill_identity(request_v1);
    proc17_qa_wire_put_u64(request_v1 + 128U, 1U);
    proc17_qa_wire_put_u64(request_v1 + 136U, 2U);
    proc17_qa_wire_put_u64(request_v1 + 144U, 3U);
    proc17_qa_wire_put_u16(request_v1 + 236U, 13U);
    memcpy(request_v1 + PROC17_QA_RUN_REQUEST_V1_FIXED_BYTES,
        "tests/run.lua", 13U);
    if (v1_round_trip(PROC17_QA_WIRE_RUN_REQUEST_V1,
            request_v1, sizeof(request_v1)) != 0) return 1;

    memset(started_v1, 0, sizeof(started_v1));
    fill_identity(started_v1);
    proc17_qa_wire_put_u16(started_v1 + 128U,
        PROC17_QA_RUN_V1_PHASE_STARTED);
    proc17_qa_wire_put_u16(started_v1 + 130U, 1U);
    started_v1[132U] = 1U;
    started_v1[133U] = PROC17_QA_RUN_V1_PREPARED_UNDER_POLICY;
    memset(started_v1 + 136U, 0x55, PROC17_SHA256_BYTES);
    fill_stage(started_v1 + PROC17_QA_V1_STARTED_STAGE_OFFSET);
    if (v1_round_trip(PROC17_QA_WIRE_RUN_STARTED_V1,
            started_v1, sizeof(started_v1)) != 0) return 1;

    fill_result(result_v1, expected_empty);
    if (v1_round_trip(PROC17_QA_WIRE_RUN_RESULT_V1,
            result_v1, sizeof(result_v1)) != 0) return 1;
    if (proc17_qa_wire_encode(PROC17_QA_WIRE_RUN_RESULT_V1, nonce,
            result_v1, sizeof(result_v1), frame, &bytes) != 0
        || proc17_qa_wire_decode_run_v1(frame, bytes, &view) == 0) {
        return 1;
    }

    memset(error_v1, 0, sizeof(error_v1));
    fill_identity(error_v1);
    proc17_qa_wire_put_u16(error_v1 + 128U,
        PROC17_QA_RUN_V1_PHASE_STARTED);
    proc17_qa_wire_put_u16(error_v1 + 130U,
        PROC17_QA_RUN_V1_ERROR_UNAVAILABLE);
    proc17_qa_wire_put_u16(error_v1 + 132U,
        PROC17_QA_RUN_V1_SUPERVISOR_UNAVAILABLE);
    proc17_qa_wire_put_u16(error_v1 + 134U,
        PROC17_QA_RUN_V1_ERROR_PREFLIGHT);
    error_v1[136U] = PROC17_QA_RUN_V1_FALSE;
    error_v1[137U] = PROC17_QA_RUN_V1_TRUE;
    if (v1_round_trip(PROC17_QA_WIRE_RUN_ERROR_V1,
            error_v1, sizeof(error_v1)) != 0) return 1;

    started_v1[134U] = 1U;
    if (proc17_qa_wire_v1_started_valid(started_v1,
            sizeof(started_v1))) return 1;
    started_v1[134U] = 0U;
    memset(started_v1 + 136U, 0, PROC17_SHA256_BYTES);
    if (proc17_qa_wire_v1_started_valid(started_v1,
            sizeof(started_v1))) return 1;

    fill_result(result_v1, expected_empty);
    result_v1[PROC17_QA_V1_RESULT_FINALITY_OFFSET + 3U] = 0U;
    if (proc17_qa_wire_v1_result_valid(result_v1,
            sizeof(result_v1))) return 1;
    fill_result(result_v1, expected_empty);
    result_v1[PROC17_QA_V1_RESULT_RESOURCE_OFFSET + 80U] = 2U;
    if (proc17_qa_wire_v1_result_valid(result_v1,
            sizeof(result_v1))) return 1;

    error_v1[136U] = 0U;
    if (proc17_qa_wire_v1_error_valid(error_v1,
            sizeof(error_v1))) return 1;
    error_v1[136U] = PROC17_QA_RUN_V1_FALSE;
    error_v1[140U] = 1U;
    if (proc17_qa_wire_v1_error_valid(error_v1,
            sizeof(error_v1))) return 1;

    puts("proc17 QA wire contract ok");
    return 0;
}
