#include "proc17_sha256.h"

#include <string.h>

static const uint32_t round_constants[64] = {
    UINT32_C(0x428a2f98), UINT32_C(0x71374491), UINT32_C(0xb5c0fbcf),
    UINT32_C(0xe9b5dba5), UINT32_C(0x3956c25b), UINT32_C(0x59f111f1),
    UINT32_C(0x923f82a4), UINT32_C(0xab1c5ed5), UINT32_C(0xd807aa98),
    UINT32_C(0x12835b01), UINT32_C(0x243185be), UINT32_C(0x550c7dc3),
    UINT32_C(0x72be5d74), UINT32_C(0x80deb1fe), UINT32_C(0x9bdc06a7),
    UINT32_C(0xc19bf174), UINT32_C(0xe49b69c1), UINT32_C(0xefbe4786),
    UINT32_C(0x0fc19dc6), UINT32_C(0x240ca1cc), UINT32_C(0x2de92c6f),
    UINT32_C(0x4a7484aa), UINT32_C(0x5cb0a9dc), UINT32_C(0x76f988da),
    UINT32_C(0x983e5152), UINT32_C(0xa831c66d), UINT32_C(0xb00327c8),
    UINT32_C(0xbf597fc7), UINT32_C(0xc6e00bf3), UINT32_C(0xd5a79147),
    UINT32_C(0x06ca6351), UINT32_C(0x14292967), UINT32_C(0x27b70a85),
    UINT32_C(0x2e1b2138), UINT32_C(0x4d2c6dfc), UINT32_C(0x53380d13),
    UINT32_C(0x650a7354), UINT32_C(0x766a0abb), UINT32_C(0x81c2c92e),
    UINT32_C(0x92722c85), UINT32_C(0xa2bfe8a1), UINT32_C(0xa81a664b),
    UINT32_C(0xc24b8b70), UINT32_C(0xc76c51a3), UINT32_C(0xd192e819),
    UINT32_C(0xd6990624), UINT32_C(0xf40e3585), UINT32_C(0x106aa070),
    UINT32_C(0x19a4c116), UINT32_C(0x1e376c08), UINT32_C(0x2748774c),
    UINT32_C(0x34b0bcb5), UINT32_C(0x391c0cb3), UINT32_C(0x4ed8aa4a),
    UINT32_C(0x5b9cca4f), UINT32_C(0x682e6ff3), UINT32_C(0x748f82ee),
    UINT32_C(0x78a5636f), UINT32_C(0x84c87814), UINT32_C(0x8cc70208),
    UINT32_C(0x90befffa), UINT32_C(0xa4506ceb), UINT32_C(0xbef9a3f7),
    UINT32_C(0xc67178f2),
};

static uint32_t rotate_right(uint32_t value, unsigned int amount)
{
    return (value >> amount) | (value << (32U - amount));
}

static uint32_t load_u32(const unsigned char *input)
{
    return ((uint32_t)input[0] << 24U)
        | ((uint32_t)input[1] << 16U)
        | ((uint32_t)input[2] << 8U)
        | (uint32_t)input[3];
}

static void store_u32(unsigned char *output, uint32_t value)
{
    output[0] = (unsigned char)(value >> 24U);
    output[1] = (unsigned char)(value >> 16U);
    output[2] = (unsigned char)(value >> 8U);
    output[3] = (unsigned char)value;
}

static void transform(struct proc17_sha256 *context)
{
    uint32_t words[64];
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
    uint32_t e;
    uint32_t f;
    uint32_t g;
    uint32_t h;
    size_t index;

    for (index = 0; index < 16U; index++) {
        words[index] = load_u32(context->block + index * 4U);
    }
    for (; index < 64U; index++) {
        uint32_t left = words[index - 15U];
        uint32_t right = words[index - 2U];
        uint32_t sigma0 = rotate_right(left, 7U)
            ^ rotate_right(left, 18U) ^ (left >> 3U);
        uint32_t sigma1 = rotate_right(right, 17U)
            ^ rotate_right(right, 19U) ^ (right >> 10U);
        words[index] = words[index - 16U] + sigma0
            + words[index - 7U] + sigma1;
    }

    a = context->state[0];
    b = context->state[1];
    c = context->state[2];
    d = context->state[3];
    e = context->state[4];
    f = context->state[5];
    g = context->state[6];
    h = context->state[7];
    for (index = 0; index < 64U; index++) {
        uint32_t sum1 = rotate_right(e, 6U)
            ^ rotate_right(e, 11U) ^ rotate_right(e, 25U);
        uint32_t choose = (e & f) ^ ((~e) & g);
        uint32_t first = h + sum1 + choose
            + round_constants[index] + words[index];
        uint32_t sum0 = rotate_right(a, 2U)
            ^ rotate_right(a, 13U) ^ rotate_right(a, 22U);
        uint32_t majority = (a & b) ^ (a & c) ^ (b & c);
        uint32_t second = sum0 + majority;

        h = g;
        g = f;
        f = e;
        e = d + first;
        d = c;
        c = b;
        b = a;
        a = first + second;
    }
    context->state[0] += a;
    context->state[1] += b;
    context->state[2] += c;
    context->state[3] += d;
    context->state[4] += e;
    context->state[5] += f;
    context->state[6] += g;
    context->state[7] += h;
}

void proc17_sha256_init(struct proc17_sha256 *context)
{
    static const uint32_t initial[8] = {
        UINT32_C(0x6a09e667), UINT32_C(0xbb67ae85),
        UINT32_C(0x3c6ef372), UINT32_C(0xa54ff53a),
        UINT32_C(0x510e527f), UINT32_C(0x9b05688c),
        UINT32_C(0x1f83d9ab), UINT32_C(0x5be0cd19),
    };

    memcpy(context->state, initial, sizeof(initial));
    context->total_bytes = 0;
    context->block_bytes = 0;
    memset(context->block, 0, sizeof(context->block));
}

void proc17_sha256_update(
    struct proc17_sha256 *context,
    const void *bytes,
    size_t length)
{
    const unsigned char *input = bytes;

    context->total_bytes += length;
    while (length > 0U) {
        size_t available = sizeof(context->block) - context->block_bytes;
        size_t copied = length < available ? length : available;

        memcpy(context->block + context->block_bytes, input, copied);
        context->block_bytes += copied;
        input += copied;
        length -= copied;
        if (context->block_bytes == sizeof(context->block)) {
            transform(context);
            context->block_bytes = 0;
        }
    }
}

void proc17_sha256_final(
    struct proc17_sha256 *context,
    unsigned char digest[PROC17_SHA256_BYTES])
{
    uint64_t total_bits = context->total_bytes * UINT64_C(8);
    size_t index;

    context->block[context->block_bytes++] = 0x80U;
    if (context->block_bytes > 56U) {
        memset(context->block + context->block_bytes, 0,
            sizeof(context->block) - context->block_bytes);
        transform(context);
        context->block_bytes = 0;
    }
    memset(context->block + context->block_bytes, 0, 56U - context->block_bytes);
    for (index = 0; index < 8U; index++) {
        context->block[63U - index] = (unsigned char)(total_bits >> (index * 8U));
    }
    transform(context);
    for (index = 0; index < 8U; index++) {
        store_u32(digest + index * 4U, context->state[index]);
    }
    memset(context, 0, sizeof(*context));
}

void proc17_sha256_bytes(
    const void *bytes,
    size_t length,
    unsigned char digest[PROC17_SHA256_BYTES])
{
    struct proc17_sha256 context;

    proc17_sha256_init(&context);
    proc17_sha256_update(&context, bytes, length);
    proc17_sha256_final(&context, digest);
}

void proc17_sha256_hex(
    const unsigned char digest[PROC17_SHA256_BYTES],
    char output[PROC17_SHA256_BYTES * 2U + 1U])
{
    static const char alphabet[] = "0123456789abcdef";
    size_t index;

    for (index = 0; index < PROC17_SHA256_BYTES; index++) {
        output[index * 2U] = alphabet[digest[index] >> 4U];
        output[index * 2U + 1U] = alphabet[digest[index] & 0x0fU];
    }
    output[PROC17_SHA256_BYTES * 2U] = '\0';
}

int proc17_sha256_parse_hex(
    const char *input,
    unsigned char digest[PROC17_SHA256_BYTES])
{
    size_t index;

    if (input == NULL || strlen(input) != PROC17_SHA256_BYTES * 2U) {
        return -1;
    }
    for (index = 0; index < PROC17_SHA256_BYTES; index++) {
        unsigned int value = 0;
        size_t half;
        for (half = 0; half < 2U; half++) {
            unsigned char current = (unsigned char)input[index * 2U + half];
            unsigned int nibble;
            if (current >= '0' && current <= '9') {
                nibble = current - '0';
            } else if (current >= 'a' && current <= 'f') {
                nibble = current - 'a' + 10U;
            } else {
                return -1;
            }
            value = (value << 4U) | nibble;
        }
        digest[index] = (unsigned char)value;
    }
    return 0;
}
