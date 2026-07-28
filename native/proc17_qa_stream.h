#ifndef PROC17_QA_STREAM_H
#define PROC17_QA_STREAM_H

#include <stddef.h>
#include <stdint.h>

#include "proc17_qa_wire.h"
#include "proc17_sha256.h"

enum proc17_qa_stream_drain_result {
    PROC17_QA_STREAM_DRAIN_ERROR = -1,
    PROC17_QA_STREAM_DRAIN_IDLE = 0,
    PROC17_QA_STREAM_DRAIN_PROGRESS = 1,
    PROC17_QA_STREAM_DRAIN_LIMIT_CROSSED = 2,
    PROC17_QA_STREAM_DRAIN_EOF = 3,
};

struct proc17_qa_stream_measurement {
    uint64_t observed_bytes;
    uint64_t hashed_bytes;
    uint64_t limit_bytes;
    unsigned char prefix_digest[PROC17_SHA256_BYTES];
    uint8_t limit_crossed;
    uint8_t eof_observed;
};

struct proc17_qa_stream_observer {
    uint64_t observed_bytes;
    uint64_t hashed_bytes;
    uint64_t limit_bytes;
    struct proc17_sha256 hash;
    unsigned char prefix_digest[PROC17_SHA256_BYTES];
    uint8_t limit_crossed;
    uint8_t eof_observed;
    uint8_t finalized;
    uint8_t failed;
};

int proc17_qa_stream_init(
    struct proc17_qa_stream_observer *observer,
    uint64_t limit_bytes);

int proc17_qa_stream_consume(
    struct proc17_qa_stream_observer *observer,
    const void *bytes,
    size_t length);

int proc17_qa_stream_drain_nonblocking(
    struct proc17_qa_stream_observer *observer,
    int descriptor);

int proc17_qa_stream_snapshot(
    struct proc17_qa_stream_observer *observer,
    struct proc17_qa_stream_measurement *measurement);

int proc17_qa_stream_encode_v1(
    const struct proc17_qa_stream_measurement *measurement,
    unsigned char output[PROC17_QA_STREAM_MEASUREMENT_V1_BYTES]);

#endif
