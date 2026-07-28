#define _GNU_SOURCE

#include "../proc17_qa_stream.h"

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static int set_nonblocking(int descriptor)
{
    int flags = fcntl(descriptor, F_GETFL);
    return flags >= 0
        && fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) == 0 ? 0 : -1;
}

static int write_all(int descriptor, const void *bytes, size_t length)
{
    const unsigned char *cursor = bytes;
    while (length != 0U) {
        ssize_t written = write(descriptor, cursor, length);
        if (written < 0 && errno == EINTR) continue;
        if (written <= 0) return -1;
        cursor += (size_t)written;
        length -= (size_t)written;
    }
    return 0;
}

static int same_digest(
    const unsigned char *bytes,
    size_t length,
    const unsigned char digest[PROC17_SHA256_BYTES])
{
    unsigned char expected[PROC17_SHA256_BYTES];
    proc17_sha256_bytes(bytes, length, expected);
    return memcmp(expected, digest, sizeof(expected)) == 0;
}

static int measurement_round_trip(
    struct proc17_qa_stream_observer *observer,
    struct proc17_qa_stream_measurement *measurement)
{
    unsigned char wire[PROC17_QA_STREAM_MEASUREMENT_V1_BYTES];
    return proc17_qa_stream_snapshot(observer, measurement) == 0
        && proc17_qa_stream_encode_v1(measurement, wire) == 0
        && proc17_qa_wire_v1_stream_valid(wire) ? 0 : -1;
}

static int test_empty_stream(void)
{
    struct proc17_qa_stream_observer observer;
    struct proc17_qa_stream_measurement measurement;
    int descriptors[2];

    if (proc17_qa_stream_init(&observer, 16U) != 0
        || pipe2(descriptors, O_CLOEXEC) != 0) {
        return -1;
    }
    close(descriptors[1]);
    if (set_nonblocking(descriptors[0]) != 0
        || proc17_qa_stream_snapshot(&observer, &measurement) == 0
        || proc17_qa_stream_drain_nonblocking(&observer, descriptors[0])
            != PROC17_QA_STREAM_DRAIN_EOF
        || measurement_round_trip(&observer, &measurement) != 0
        || measurement.observed_bytes != 0U
        || measurement.hashed_bytes != 0U
        || measurement.limit_crossed != 0U
        || !same_digest((const unsigned char *)"", 0U,
            measurement.prefix_digest)
        || proc17_qa_stream_consume(&observer, "x", 1U) == 0) {
        close(descriptors[0]);
        return -1;
    }
    close(descriptors[0]);
    return 0;
}

static int test_independent_dual_pipe(void)
{
    static const unsigned char stdout_bytes[] = {
        's', 't', 'd', 'o', 'u', 't', 0x00, 0x7f,
    };
    static const unsigned char stderr_bytes[] = {
        's', 't', 'd', 'e', 'r', 'r', 0xff,
    };
    struct proc17_qa_stream_observer observers[2];
    struct proc17_qa_stream_measurement measurements[2];
    struct pollfd poll_fds[2];
    int stdout_pipe[2];
    int stderr_pipe[2];
    pid_t child;
    int status;
    int complete = 0;

    if (pipe2(stdout_pipe, O_CLOEXEC) != 0
        || pipe2(stderr_pipe, O_CLOEXEC) != 0) {
        return -1;
    }
    child = fork();
    if (child < 0) return -1;
    if (child == 0) {
        close(stdout_pipe[0]);
        close(stderr_pipe[0]);
        if (dup2(stdout_pipe[1], STDOUT_FILENO) < 0
            || dup2(stderr_pipe[1], STDERR_FILENO) < 0) {
            _exit(120);
        }
        close(stdout_pipe[1]);
        close(stderr_pipe[1]);
        if (write_all(STDOUT_FILENO, stdout_bytes, sizeof(stdout_bytes)) != 0
            || write_all(STDERR_FILENO, stderr_bytes,
                sizeof(stderr_bytes)) != 0) {
            _exit(121);
        }
        _exit(0);
    }
    close(stdout_pipe[1]);
    close(stderr_pipe[1]);
    if (set_nonblocking(stdout_pipe[0]) != 0
        || set_nonblocking(stderr_pipe[0]) != 0
        || proc17_qa_stream_init(&observers[0], 1024U) != 0
        || proc17_qa_stream_init(&observers[1], 1024U) != 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
        return -1;
    }
    while (complete != 3) {
        int polled;
        size_t index;
        poll_fds[0] = (struct pollfd){
            .fd = stdout_pipe[0], .events = POLLIN | POLLHUP};
        poll_fds[1] = (struct pollfd){
            .fd = stderr_pipe[0], .events = POLLIN | POLLHUP};
        polled = poll(poll_fds, 2, 2000);
        if (polled <= 0) {
            (void)kill(child, SIGKILL);
            (void)waitpid(child, NULL, 0);
            return -1;
        }
        for (index = 0; index < 2U; index++) {
            int bit = 1 << index;
            int drained;
            if ((complete & bit) != 0
                || (poll_fds[index].revents & (POLLIN | POLLHUP)) == 0) {
                continue;
            }
            drained = proc17_qa_stream_drain_nonblocking(
                &observers[index], poll_fds[index].fd);
            if (drained == PROC17_QA_STREAM_DRAIN_EOF) complete |= bit;
            else if (drained == PROC17_QA_STREAM_DRAIN_ERROR
                || drained == PROC17_QA_STREAM_DRAIN_LIMIT_CROSSED) {
                (void)kill(child, SIGKILL);
                (void)waitpid(child, NULL, 0);
                return -1;
            }
        }
    }
    close(stdout_pipe[0]);
    close(stderr_pipe[0]);
    if (waitpid(child, &status, 0) != child || !WIFEXITED(status)
        || WEXITSTATUS(status) != 0
        || measurement_round_trip(&observers[0], &measurements[0]) != 0
        || measurement_round_trip(&observers[1], &measurements[1]) != 0
        || measurements[0].observed_bytes != sizeof(stdout_bytes)
        || measurements[1].observed_bytes != sizeof(stderr_bytes)
        || !same_digest(stdout_bytes, sizeof(stdout_bytes),
            measurements[0].prefix_digest)
        || !same_digest(stderr_bytes, sizeof(stderr_bytes),
            measurements[1].prefix_digest)
        || memcmp(measurements[0].prefix_digest,
            measurements[1].prefix_digest, PROC17_SHA256_BYTES) == 0) {
        return -1;
    }
    return 0;
}

static int test_limit_crossing_and_complete_drain(void)
{
    static const unsigned char bytes[] = "abcdefgh";
    struct proc17_qa_stream_observer observer;
    struct proc17_qa_stream_measurement measurement;
    int descriptors[2];

    if (pipe2(descriptors, O_CLOEXEC) != 0
        || proc17_qa_stream_init(&observer, 5U) != 0
        || write_all(descriptors[1], bytes, sizeof(bytes) - 1U) != 0) {
        return -1;
    }
    close(descriptors[1]);
    if (set_nonblocking(descriptors[0]) != 0
        || proc17_qa_stream_drain_nonblocking(&observer, descriptors[0])
            != PROC17_QA_STREAM_DRAIN_LIMIT_CROSSED
        || proc17_qa_stream_drain_nonblocking(&observer, descriptors[0])
            != PROC17_QA_STREAM_DRAIN_EOF
        || measurement_round_trip(&observer, &measurement) != 0
        || measurement.observed_bytes != sizeof(bytes) - 1U
        || measurement.hashed_bytes != 5U
        || measurement.limit_bytes != 5U
        || measurement.limit_crossed != 1U
        || !same_digest(bytes, 5U, measurement.prefix_digest)) {
        close(descriptors[0]);
        return -1;
    }
    close(descriptors[0]);
    return 0;
}

static int test_invalid_state_is_sticky(void)
{
    struct proc17_qa_stream_observer observer;
    unsigned char byte = 0;
    int descriptors[2];

    if (proc17_qa_stream_init(&observer, 0U) == 0
        || proc17_qa_stream_init(&observer, 1U) != 0) {
        return -1;
    }
    observer.observed_bytes = UINT64_MAX;
    if (proc17_qa_stream_consume(&observer, &byte, 1U) == 0
        || observer.failed != 1U
        || proc17_qa_stream_consume(&observer, &byte, 1U) == 0) {
        return -1;
    }
    if (pipe2(descriptors, O_CLOEXEC) != 0
        || proc17_qa_stream_init(&observer, 1U) != 0
        || proc17_qa_stream_drain_nonblocking(&observer, descriptors[0])
            != PROC17_QA_STREAM_DRAIN_ERROR
        || observer.failed != 1U) {
        return -1;
    }
    close(descriptors[0]);
    close(descriptors[1]);
    return 0;
}

int main(void)
{
    if (test_empty_stream() != 0
        || test_independent_dual_pipe() != 0
        || test_limit_crossing_and_complete_drain() != 0
        || test_invalid_state_is_sticky() != 0) {
        return 1;
    }
    puts("proc17 QA independent stream witnesses ok");
    return 0;
}
