#define _GNU_SOURCE

#include "proc17_qa_status.h"
#include "proc17_qa_phase_internal.h"

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#define PROC17_QA_STATUS_VERSION 1U

static const unsigned char status_magic[8] = {
    'P', '1', '7', 'Q', 'A', 'S', 'T', '\0',
};

_Static_assert(sizeof(struct proc17_qa_phase_identity) == 128U,
    "private status identity join must be 128 bytes");
_Static_assert(24U + sizeof(struct proc17_qa_phase_identity)
        + PROC17_QA_WIRE_DIGEST_BYTES == PROC17_QA_STATUS_PACKET_BYTES,
    "private status packet layout must be exact");

static uint64_t exact_sequence(uint16_t kind)
{
    switch (kind) {
    case PROC17_QA_STATUS_READY:
        return 1U;
    case PROC17_QA_STATUS_RELEASE:
        return 2U;
    case PROC17_QA_STATUS_HEAP_DENIED:
        return 3U;
    default:
        return 0U;
    }
}

int proc17_qa_status_context_valid(
    const struct proc17_qa_status_context *context)
{
    return context != NULL
        && proc17_qa_phase_identity_valid(&context->identity)
        && proc17_qa_wire_digest_nonzero(context->process_token);
}

int proc17_qa_status_socket_pair(int descriptors[2])
{
    if (descriptors == NULL) return -1;
    descriptors[0] = -1;
    descriptors[1] = -1;
    return socketpair(AF_UNIX, SOCK_SEQPACKET | SOCK_CLOEXEC, 0,
        descriptors) == 0 ? 0 : -1;
}

int proc17_qa_status_ignore_sigpipe(void)
{
    struct sigaction action;
    memset(&action, 0, sizeof(action));
    action.sa_handler = SIG_IGN;
    if (sigemptyset(&action.sa_mask) != 0) return -1;
    return sigaction(SIGPIPE, &action, NULL) == 0 ? 0 : -1;
}

int proc17_qa_status_set_nonblocking(int descriptor)
{
    int flags;
    if (descriptor < 0) return -1;
    flags = fcntl(descriptor, F_GETFL);
    return flags >= 0
        && fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) == 0 ? 0 : -1;
}

int proc17_qa_status_encode(
    const struct proc17_qa_status_context *context,
    uint16_t kind,
    uint64_t sequence,
    unsigned char output[PROC17_QA_STATUS_PACKET_BYTES])
{
    if (!proc17_qa_status_context_valid(context) || output == NULL
        || exact_sequence(kind) != sequence) {
        return -1;
    }
    memset(output, 0, PROC17_QA_STATUS_PACKET_BYTES);
    memcpy(output, status_magic, sizeof(status_magic));
    proc17_qa_wire_put_u16(output + 8U, PROC17_QA_STATUS_VERSION);
    proc17_qa_wire_put_u16(output + 10U, kind);
    proc17_qa_wire_put_u32(output + 12U, PROC17_QA_STATUS_PACKET_BYTES);
    proc17_qa_wire_put_u64(output + 16U, sequence);
    memcpy(output + 24U, &context->identity, sizeof(context->identity));
    memcpy(output + 152U, context->process_token,
        sizeof(context->process_token));
    return 0;
}

static int decode(
    const unsigned char input[PROC17_QA_STATUS_PACKET_BYTES],
    const struct proc17_qa_status_context *context,
    struct proc17_qa_status_message *message)
{
    uint16_t kind;
    uint64_t sequence;

    if (input == NULL || !proc17_qa_status_context_valid(context)
        || message == NULL || memcmp(input, status_magic,
            sizeof(status_magic)) != 0
        || proc17_qa_wire_get_u16(input + 8U) != PROC17_QA_STATUS_VERSION
        || proc17_qa_wire_get_u32(input + 12U)
            != PROC17_QA_STATUS_PACKET_BYTES
        || memcmp(input + 24U, &context->identity,
            sizeof(context->identity)) != 0
        || memcmp(input + 152U, context->process_token,
            sizeof(context->process_token)) != 0) {
        return -1;
    }
    kind = proc17_qa_wire_get_u16(input + 10U);
    sequence = proc17_qa_wire_get_u64(input + 16U);
    if (exact_sequence(kind) != sequence) return -1;
    message->kind = kind;
    message->sequence = sequence;
    return 0;
}

int proc17_qa_status_send(
    int descriptor,
    const struct proc17_qa_status_context *context,
    uint16_t kind,
    uint64_t sequence,
    int nonblocking)
{
    unsigned char packet[PROC17_QA_STATUS_PACKET_BYTES];
    int descriptor_flags;
    ssize_t written;

    if (descriptor < 0
        || proc17_qa_status_encode(context, kind, sequence, packet) != 0) {
        return -1;
    }
    descriptor_flags = fcntl(descriptor, F_GETFL);
    if (descriptor_flags < 0
        || (nonblocking != 0 && (descriptor_flags & O_NONBLOCK) == 0)) {
        memset(packet, 0, sizeof(packet));
        return -1;
    }
    do {
        written = write(descriptor, packet, sizeof(packet));
    } while (written < 0 && errno == EINTR);
    memset(packet, 0, sizeof(packet));
    return written == (ssize_t)PROC17_QA_STATUS_PACKET_BYTES ? 0 : -1;
}

int proc17_qa_status_receive(
    int descriptor,
    const struct proc17_qa_status_context *context,
    int nonblocking,
    struct proc17_qa_status_message *message)
{
    unsigned char packet[PROC17_QA_STATUS_PACKET_BYTES + 1U];
    int descriptor_flags;
    ssize_t observed;

    if (descriptor < 0 || !proc17_qa_status_context_valid(context)
        || message == NULL) {
        return PROC17_QA_STATUS_RECEIVE_ERROR;
    }
    descriptor_flags = fcntl(descriptor, F_GETFL);
    if (descriptor_flags < 0
        || (nonblocking != 0 && (descriptor_flags & O_NONBLOCK) == 0)) {
        return PROC17_QA_STATUS_RECEIVE_ERROR;
    }
    memset(packet, 0, sizeof(packet));
    do {
        observed = read(descriptor, packet, sizeof(packet));
    } while (observed < 0 && errno == EINTR);
    if (observed < 0 && nonblocking != 0
        && (errno == EAGAIN || errno == EWOULDBLOCK)) {
        return PROC17_QA_STATUS_RECEIVE_IDLE;
    }
    if (observed == 0) return PROC17_QA_STATUS_RECEIVE_EOF;
    if (observed != (ssize_t)PROC17_QA_STATUS_PACKET_BYTES
        || decode(packet, context, message) != 0) {
        memset(packet, 0, sizeof(packet));
        return PROC17_QA_STATUS_RECEIVE_ERROR;
    }
    memset(packet, 0, sizeof(packet));
    return PROC17_QA_STATUS_RECEIVE_MESSAGE;
}

int proc17_qa_status_accept_ready(
    const struct proc17_qa_status_message *message,
    struct proc17_qa_phase_state *controller_phase)
{
    if (message == NULL || message->kind != PROC17_QA_STATUS_READY
        || message->sequence != 1U) {
        return -1;
    }
    return proc17_qa_phase_observe_started_ready(controller_phase);
}
