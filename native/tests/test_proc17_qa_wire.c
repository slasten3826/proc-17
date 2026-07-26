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

int proc17_qa_wire_contract_syntax_only(void)
{
    return 0;
}

static int rejected(const unsigned char *frame, size_t bytes)
{
    struct proc17_qa_wire_view view;
    return proc17_qa_wire_decode(frame, bytes, &view) != 0;
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

    puts("proc17 QA wire contract ok");
    return 0;
}
