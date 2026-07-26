#ifndef PROC17_SHA256_H
#define PROC17_SHA256_H

#include <stddef.h>
#include <stdint.h>

#define PROC17_SHA256_BYTES 32U

struct proc17_sha256 {
    uint32_t state[8];
    uint64_t total_bytes;
    unsigned char block[64];
    size_t block_bytes;
};

void proc17_sha256_init(struct proc17_sha256 *context);
void proc17_sha256_update(
    struct proc17_sha256 *context,
    const void *bytes,
    size_t length);
void proc17_sha256_final(
    struct proc17_sha256 *context,
    unsigned char digest[PROC17_SHA256_BYTES]);
void proc17_sha256_bytes(
    const void *bytes,
    size_t length,
    unsigned char digest[PROC17_SHA256_BYTES]);
void proc17_sha256_hex(
    const unsigned char digest[PROC17_SHA256_BYTES],
    char output[PROC17_SHA256_BYTES * 2U + 1U]);
int proc17_sha256_parse_hex(
    const char *input,
    unsigned char digest[PROC17_SHA256_BYTES]);

#endif
