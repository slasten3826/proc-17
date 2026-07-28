#define _GNU_SOURCE

#include "proc17_qa_stream.h"

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <string.h>
#include <unistd.h>

#define PROC17_QA_STREAM_READ_BYTES 4096U
#define PROC17_QA_STREAM_DRAIN_SLICE_BYTES 65536U

_Static_assert(SIZE_MAX <= UINT64_MAX,
    "stream byte accounting requires size_t no wider than uint64_t");
_Static_assert(PROC17_QA_STREAM_MEASUREMENT_V1_BYTES == 64U,
    "stream measurement must match RUN v1 wire layout");

static int measurement_valid(
    const struct proc17_qa_stream_measurement *measurement)
{
    uint64_t expected_hashed;

    if (measurement == NULL || measurement->limit_bytes == 0U
        || measurement->eof_observed != 1U
        || measurement->limit_crossed > 1U) {
        return 0;
    }
    expected_hashed = measurement->observed_bytes < measurement->limit_bytes
        ? measurement->observed_bytes : measurement->limit_bytes;
    return measurement->hashed_bytes == expected_hashed
        && (measurement->limit_crossed != 0U)
            == (measurement->observed_bytes > measurement->limit_bytes);
}

int proc17_qa_stream_init(
    struct proc17_qa_stream_observer *observer,
    uint64_t limit_bytes)
{
    if (observer == NULL || limit_bytes == 0U) return -1;
    memset(observer, 0, sizeof(*observer));
    observer->limit_bytes = limit_bytes;
    proc17_sha256_init(&observer->hash);
    return 0;
}

int proc17_qa_stream_consume(
    struct proc17_qa_stream_observer *observer,
    const void *bytes,
    size_t length)
{
    uint64_t available;
    size_t hashed_now;
    int crossed = 0;

    if (observer == NULL || observer->limit_bytes == 0U
        || observer->failed != 0U || observer->finalized != 0U
        || observer->eof_observed != 0U
        || (length != 0U && bytes == NULL)) {
        return -1;
    }
    if ((uint64_t)length > UINT64_MAX - observer->observed_bytes
        || observer->hashed_bytes > observer->limit_bytes) {
        observer->failed = 1U;
        return -1;
    }
    available = observer->limit_bytes - observer->hashed_bytes;
    hashed_now = length;
    if ((uint64_t)hashed_now > available) hashed_now = (size_t)available;
    if (hashed_now != 0U) {
        proc17_sha256_update(&observer->hash, bytes, hashed_now);
        observer->hashed_bytes += (uint64_t)hashed_now;
    }
    observer->observed_bytes += (uint64_t)length;
    if (observer->limit_crossed == 0U
        && observer->observed_bytes > observer->limit_bytes) {
        observer->limit_crossed = 1U;
        crossed = 1;
    }
    return crossed;
}

int proc17_qa_stream_drain_nonblocking(
    struct proc17_qa_stream_observer *observer,
    int descriptor)
{
    unsigned char buffer[PROC17_QA_STREAM_READ_BYTES];
    size_t drained_bytes = 0U;
    int descriptor_flags;
    int progress = 0;

    if (observer == NULL || descriptor < 0 || observer->limit_bytes == 0U
        || observer->failed != 0U || observer->finalized != 0U) {
        return PROC17_QA_STREAM_DRAIN_ERROR;
    }
    if (observer->eof_observed != 0U) return PROC17_QA_STREAM_DRAIN_EOF;
    descriptor_flags = fcntl(descriptor, F_GETFL);
    if (descriptor_flags < 0 || (descriptor_flags & O_NONBLOCK) == 0) {
        observer->failed = 1U;
        return PROC17_QA_STREAM_DRAIN_ERROR;
    }
    for (;;) {
        ssize_t observed = read(descriptor, buffer, sizeof(buffer));
        if (observed > 0) {
            int consumed = proc17_qa_stream_consume(
                observer, buffer, (size_t)observed);
            memset(buffer, 0, sizeof(buffer));
            if (consumed < 0) return PROC17_QA_STREAM_DRAIN_ERROR;
            progress = 1;
            drained_bytes += (size_t)observed;
            if (consumed == 1) {
                return PROC17_QA_STREAM_DRAIN_LIMIT_CROSSED;
            }
            if (drained_bytes >= PROC17_QA_STREAM_DRAIN_SLICE_BYTES) {
                return PROC17_QA_STREAM_DRAIN_PROGRESS;
            }
            continue;
        }
        memset(buffer, 0, sizeof(buffer));
        if (observed == 0) {
            observer->eof_observed = 1U;
            return PROC17_QA_STREAM_DRAIN_EOF;
        }
        if (errno == EINTR) continue;
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            return progress != 0 ? PROC17_QA_STREAM_DRAIN_PROGRESS
                : PROC17_QA_STREAM_DRAIN_IDLE;
        }
        observer->failed = 1U;
        return PROC17_QA_STREAM_DRAIN_ERROR;
    }
}

int proc17_qa_stream_snapshot(
    struct proc17_qa_stream_observer *observer,
    struct proc17_qa_stream_measurement *measurement)
{
    if (observer == NULL || measurement == NULL
        || observer->limit_bytes == 0U || observer->failed != 0U
        || observer->eof_observed != 1U) {
        return -1;
    }
    if (observer->finalized == 0U) {
        proc17_sha256_final(&observer->hash, observer->prefix_digest);
        observer->finalized = 1U;
    }
    memset(measurement, 0, sizeof(*measurement));
    measurement->observed_bytes = observer->observed_bytes;
    measurement->hashed_bytes = observer->hashed_bytes;
    measurement->limit_bytes = observer->limit_bytes;
    memcpy(measurement->prefix_digest, observer->prefix_digest,
        sizeof(measurement->prefix_digest));
    measurement->limit_crossed = observer->limit_crossed;
    measurement->eof_observed = observer->eof_observed;
    return measurement_valid(measurement) ? 0 : -1;
}

int proc17_qa_stream_encode_v1(
    const struct proc17_qa_stream_measurement *measurement,
    unsigned char output[PROC17_QA_STREAM_MEASUREMENT_V1_BYTES])
{
    if (!measurement_valid(measurement) || output == NULL) return -1;
    memset(output, 0, PROC17_QA_STREAM_MEASUREMENT_V1_BYTES);
    proc17_qa_wire_put_u64(output, measurement->observed_bytes);
    proc17_qa_wire_put_u64(output + 8U, measurement->hashed_bytes);
    proc17_qa_wire_put_u64(output + 16U, measurement->limit_bytes);
    memcpy(output + 24U, measurement->prefix_digest,
        PROC17_SHA256_BYTES);
    output[56U] = measurement->limit_crossed;
    output[57U] = measurement->eof_observed;
    return proc17_qa_wire_v1_stream_valid(output) ? 0 : -1;
}
