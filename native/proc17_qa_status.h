#ifndef PROC17_QA_STATUS_H
#define PROC17_QA_STATUS_H

#include <stdint.h>

#include "proc17_qa_phase.h"

#define PROC17_QA_STATUS_PACKET_BYTES 184U

enum proc17_qa_status_kind {
    PROC17_QA_STATUS_READY = 1,
    PROC17_QA_STATUS_RELEASE = 2,
    PROC17_QA_STATUS_HEAP_DENIED = 3,
};

enum proc17_qa_status_receive_result {
    PROC17_QA_STATUS_RECEIVE_ERROR = -1,
    PROC17_QA_STATUS_RECEIVE_IDLE = 0,
    PROC17_QA_STATUS_RECEIVE_MESSAGE = 1,
    PROC17_QA_STATUS_RECEIVE_EOF = 2,
};

struct proc17_qa_status_context {
    struct proc17_qa_phase_identity identity;
    unsigned char process_token[PROC17_QA_WIRE_DIGEST_BYTES];
};

struct proc17_qa_status_message {
    uint16_t kind;
    uint64_t sequence;
};

int proc17_qa_status_context_valid(
    const struct proc17_qa_status_context *context);

int proc17_qa_status_socket_pair(int descriptors[2]);

int proc17_qa_status_ignore_sigpipe(void);

int proc17_qa_status_set_nonblocking(int descriptor);

int proc17_qa_status_encode(
    const struct proc17_qa_status_context *context,
    uint16_t kind,
    uint64_t sequence,
    unsigned char output[PROC17_QA_STATUS_PACKET_BYTES]);

int proc17_qa_status_send(
    int descriptor,
    const struct proc17_qa_status_context *context,
    uint16_t kind,
    uint64_t sequence,
    int nonblocking);

int proc17_qa_status_receive(
    int descriptor,
    const struct proc17_qa_status_context *context,
    int nonblocking,
    struct proc17_qa_status_message *message);

int proc17_qa_status_accept_ready(
    const struct proc17_qa_status_message *message,
    struct proc17_qa_phase_state *controller_phase);

#endif
