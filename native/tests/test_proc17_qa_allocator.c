#define _GNU_SOURCE

#include "../proc17_qa_allocator.h"
#include "../proc17_qa_status.h"

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <unistd.h>

void *__real_malloc(size_t bytes);

static int fail_next_malloc;

void *__wrap_malloc(size_t bytes)
{
    if (fail_next_malloc != 0) {
        fail_next_malloc = 0;
        errno = ENOMEM;
        return NULL;
    }
    return __real_malloc(bytes);
}

static void fill_status_context(struct proc17_qa_status_context *context)
{
    memset(context, 0, sizeof(*context));
    memset(context->identity.transaction, 0x11,
        sizeof(context->identity.transaction));
    memset(context->identity.witness, 0x22,
        sizeof(context->identity.witness));
    memset(context->identity.profile, 0x33,
        sizeof(context->identity.profile));
    memset(context->identity.environment, 0x44,
        sizeof(context->identity.environment));
    memset(context->process_token, 0x55, sizeof(context->process_token));
}

static int test_status_protocol(void)
{
    struct proc17_qa_status_context context;
    struct proc17_qa_status_message message;
    struct proc17_qa_phase_state phase;
    unsigned char malformed[PROC17_QA_STATUS_PACKET_BYTES];
    int descriptors[2];
    int descriptor_flags;

    fill_status_context(&context);
    proc17_qa_phase_init(&phase);
    if (proc17_qa_status_ignore_sigpipe() != 0
        || !proc17_qa_status_context_valid(&context)
        || proc17_qa_status_socket_pair(descriptors) != 0) {
        return -101;
    }
    descriptor_flags = fcntl(descriptors[0], F_GETFD);
    if (descriptor_flags < 0 || (descriptor_flags & FD_CLOEXEC) == 0) {
        close(descriptors[0]);
        close(descriptors[1]);
        return -102;
    }
    if (proc17_qa_status_send(descriptors[1], &context,
            PROC17_QA_STATUS_READY, 1U, 0) != 0) {
        close(descriptors[0]);
        close(descriptors[1]);
        return -103;
    }
    if (proc17_qa_status_receive(descriptors[0], &context, 0, &message)
            != PROC17_QA_STATUS_RECEIVE_MESSAGE
        || message.kind != PROC17_QA_STATUS_READY || message.sequence != 1U
        || proc17_qa_status_accept_ready(&message, &phase) != 0
        || phase.started_attested != 1U
        || proc17_qa_status_accept_ready(&message, &phase) == 0) {
        close(descriptors[0]);
        close(descriptors[1]);
        return -104;
    }
    if (proc17_qa_status_send(descriptors[0], &context,
            PROC17_QA_STATUS_RELEASE, 2U, 0) != 0
        || proc17_qa_status_receive(descriptors[1], &context, 0, &message)
            != PROC17_QA_STATUS_RECEIVE_MESSAGE
        || message.kind != PROC17_QA_STATUS_RELEASE
        || message.sequence != 2U) {
        close(descriptors[0]);
        close(descriptors[1]);
        return -105;
    }
    if (proc17_qa_status_set_nonblocking(descriptors[0]) != 0
        || proc17_qa_status_receive(descriptors[0], &context, 1, &message)
            != PROC17_QA_STATUS_RECEIVE_IDLE) {
        close(descriptors[0]);
        close(descriptors[1]);
        return -106;
    }
    close(descriptors[1]);
    if (proc17_qa_status_receive(descriptors[0], &context, 1, &message)
            != PROC17_QA_STATUS_RECEIVE_EOF) {
        close(descriptors[0]);
        return -107;
    }
    close(descriptors[0]);

    if (proc17_qa_status_socket_pair(descriptors) != 0
        || proc17_qa_status_encode(&context, PROC17_QA_STATUS_READY,
            1U, malformed) != 0) {
        return -108;
    }
    malformed[8U] ^= 1U;
    if (write(descriptors[1], malformed, sizeof(malformed))
            != (ssize_t)sizeof(malformed)
        || proc17_qa_status_receive(descriptors[0], &context, 0, &message)
            != PROC17_QA_STATUS_RECEIVE_ERROR
        || proc17_qa_status_encode(&context, PROC17_QA_STATUS_READY,
            2U, malformed) == 0) {
        close(descriptors[0]);
        close(descriptors[1]);
        return -109;
    }
    close(descriptors[0]);
    close(descriptors[1]);

    if (proc17_qa_status_socket_pair(descriptors) != 0
        || proc17_qa_status_set_nonblocking(descriptors[1]) != 0) {
        return -110;
    }
    close(descriptors[0]);
    if (proc17_qa_status_send(descriptors[1], &context,
            PROC17_QA_STATUS_HEAP_DENIED, 3U, 1) == 0) {
        close(descriptors[1]);
        return -111;
    }
    close(descriptors[1]);
    return 0;
}

struct count_notify {
    int calls;
    int result;
};

static int count_denial(void *opaque)
{
    struct count_notify *notify = opaque;
    notify->calls++;
    return notify->result;
}

static int test_allocator_accounting(void)
{
    struct proc17_qa_allocator_telemetry telemetry;
    struct proc17_qa_allocator_snapshot snapshot;
    struct proc17_qa_allocator_state state;
    struct count_notify notify = {0, 0};
    void *pointer;

    if (proc17_qa_allocator_telemetry_init(&telemetry, 64U) != 0
        || proc17_qa_allocator_state_init(
            &state, &telemetry, count_denial, &notify) != 0) {
        return -1;
    }
    pointer = proc17_qa_lua_allocator(&state, NULL, 0U, 8U);
    if (pointer == NULL) return -1;
    pointer = proc17_qa_lua_allocator(&state, pointer, 8U, 16U);
    if (pointer == NULL) return -1;
    pointer = proc17_qa_lua_allocator(&state, pointer, 16U, 4U);
    if (pointer == NULL
        || proc17_qa_lua_allocator(&state, pointer, 4U, 0U) != NULL
        || proc17_qa_allocator_snapshot(&telemetry, &snapshot) != 0
        || snapshot.current_bytes != 0U || snapshot.peak_bytes != 16U
        || snapshot.ceiling_bytes != 64U || snapshot.ceiling_denied != 0U
        || snapshot.system_allocation_failed != 0U || notify.calls != 0) {
        return -1;
    }
    return 0;
}

static int test_denial_and_system_failure_separate(void)
{
    struct proc17_qa_allocator_telemetry telemetry;
    struct proc17_qa_allocator_snapshot snapshot;
    struct proc17_qa_allocator_state state;
    struct count_notify notify = {0, 0};
    void *pointer;

    if (proc17_qa_allocator_telemetry_init(&telemetry, 8U) != 0
        || proc17_qa_allocator_state_init(
            &state, &telemetry, count_denial, &notify) != 0) {
        return -1;
    }
    pointer = proc17_qa_lua_allocator(&state, NULL, 0U, 8U);
    if (pointer == NULL
        || proc17_qa_lua_allocator(&state, pointer, 8U, 9U) != NULL
        || proc17_qa_lua_allocator(&state, NULL, 0U, 9U) != NULL
        || notify.calls != 1
        || proc17_qa_lua_allocator(&state, pointer, 8U, 0U) != NULL
        || proc17_qa_allocator_snapshot(&telemetry, &snapshot) != 0
        || snapshot.ceiling_denied != 1U
        || snapshot.system_allocation_failed != 0U
        || snapshot.status_notification_failed != 0U) {
        return -1;
    }

    if (proc17_qa_allocator_telemetry_init(&telemetry, 64U) != 0
        || proc17_qa_allocator_state_init(
            &state, &telemetry, count_denial, &notify) != 0) {
        return -1;
    }
    fail_next_malloc = 1;
    if (proc17_qa_lua_allocator(&state, NULL, 0U, 8U) != NULL
        || proc17_qa_allocator_snapshot(&telemetry, &snapshot) != 0
        || snapshot.system_allocation_failed != 1U
        || snapshot.ceiling_denied != 0U
        || snapshot.current_bytes != 0U || snapshot.peak_bytes != 8U) {
        return -1;
    }

    notify.calls = 0;
    notify.result = -1;
    if (proc17_qa_allocator_telemetry_init(&telemetry, 4U) != 0
        || proc17_qa_allocator_state_init(
            &state, &telemetry, count_denial, &notify) != 0
        || proc17_qa_lua_allocator(&state, NULL, 0U, 5U) != NULL
        || proc17_qa_allocator_snapshot(&telemetry, &snapshot) != 0
        || notify.calls != 1 || snapshot.ceiling_denied != 1U
        || snapshot.status_notification_failed != 1U) {
        return -1;
    }
    return 0;
}

struct status_notify {
    int descriptor;
    const struct proc17_qa_status_context *context;
};

static int send_heap_denied(void *opaque)
{
    struct status_notify *notify = opaque;
    return proc17_qa_status_send(notify->descriptor, notify->context,
        PROC17_QA_STATUS_HEAP_DENIED, 3U, 1);
}

static int test_abrupt_death_preserves_telemetry(void)
{
    struct proc17_qa_allocator_telemetry *telemetry;
    struct proc17_qa_allocator_snapshot snapshot;
    struct proc17_qa_status_context context;
    struct proc17_qa_status_message message;
    struct pollfd poll_fd;
    int descriptors[2];
    pid_t child;
    int status;

    fill_status_context(&context);
    if (proc17_qa_allocator_telemetry_map(16U, &telemetry) != 0
        || proc17_qa_status_socket_pair(descriptors) != 0) {
        return -1;
    }
    child = fork();
    if (child < 0) return -1;
    if (child == 0) {
        struct proc17_qa_allocator_state state;
        struct status_notify notify = {descriptors[1], &context};
        void *pointer;

        close(descriptors[0]);
        if (proc17_qa_status_set_nonblocking(descriptors[1]) != 0) {
            _exit(119);
        }
        if (proc17_qa_allocator_state_init(
                &state, telemetry, send_heap_denied, &notify) != 0) {
            _exit(120);
        }
        pointer = proc17_qa_lua_allocator(&state, NULL, 0U, 8U);
        if (pointer == NULL
            || proc17_qa_lua_allocator(&state, NULL, 0U, 9U) != NULL) {
            _exit(121);
        }
        for (;;) pause();
    }
    close(descriptors[1]);
    if (proc17_qa_status_set_nonblocking(descriptors[0]) != 0
        || proc17_qa_allocator_telemetry_make_read_only(telemetry) != 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
        return -1;
    }
    poll_fd = (struct pollfd){.fd = descriptors[0], .events = POLLIN | POLLHUP};
    if (poll(&poll_fd, 1, 2000) <= 0
        || proc17_qa_status_receive(descriptors[0], &context, 1, &message)
            != PROC17_QA_STATUS_RECEIVE_MESSAGE
        || message.kind != PROC17_QA_STATUS_HEAP_DENIED
        || message.sequence != 3U
        || kill(child, SIGKILL) != 0
        || waitpid(child, &status, 0) != child || !WIFSIGNALED(status)
        || WTERMSIG(status) != SIGKILL
        || proc17_qa_status_receive(descriptors[0], &context, 1, &message)
            != PROC17_QA_STATUS_RECEIVE_EOF
        || proc17_qa_allocator_snapshot(telemetry, &snapshot) != 0
        || snapshot.ceiling_bytes != 16U || snapshot.current_bytes != 8U
        || snapshot.peak_bytes != 8U || snapshot.ceiling_denied != 1U
        || snapshot.system_allocation_failed != 0U
        || snapshot.status_notification_failed != 0U) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
        return -1;
    }
    close(descriptors[0]);
    return proc17_qa_allocator_telemetry_unmap(telemetry);
}

int main(void)
{
    int status_result = test_status_protocol();
    if (status_result != 0) {
        fprintf(stderr, "status protocol failed: %d errno=%d (%s)\n",
            status_result, errno, strerror(errno));
        return 1;
    }
    if (test_allocator_accounting() != 0) {
        fputs("allocator accounting failed\n", stderr);
        return 1;
    }
    if (test_denial_and_system_failure_separate() != 0) {
        fputs("allocator failure separation failed\n", stderr);
        return 1;
    }
    if (test_abrupt_death_preserves_telemetry() != 0) {
        fputs("abrupt-death telemetry failed\n", stderr);
        return 1;
    }
    puts("proc17 QA allocator telemetry and private status ok");
    return 0;
}
