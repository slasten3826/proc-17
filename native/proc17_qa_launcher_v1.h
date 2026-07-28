#ifndef PROC17_QA_LAUNCHER_V1_H
#define PROC17_QA_LAUNCHER_V1_H

#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>

#include "proc17_qa_wire.h"

enum proc17_qa_launcher_v1_collect_status {
    PROC17_QA_LAUNCHER_V1_OK = 0,
    PROC17_QA_LAUNCHER_V1_INVALID_ARGUMENT = -1,
    PROC17_QA_LAUNCHER_V1_SYSTEM_FAILURE = -2,
    PROC17_QA_LAUNCHER_V1_TRUSTED_INVARIANT = -3,
};

enum proc17_qa_launcher_v1_terminal_kind {
    PROC17_QA_LAUNCHER_V1_TERMINAL_RESULT = 1,
    PROC17_QA_LAUNCHER_V1_TERMINAL_ERROR = 2,
    PROC17_QA_LAUNCHER_V1_TERMINAL_DERIVED_ERROR = 3,
};

struct proc17_qa_launcher_v1_expectation {
    unsigned char identity[PROC17_QA_V1_IDENTITY_BYTES];
    uint64_t source_device;
    uint64_t source_inode;
    uint64_t source_mount_id;
    uint32_t source_mount_policy_flags;
};

struct proc17_qa_launcher_v1_terminal {
    enum proc17_qa_launcher_v1_terminal_kind kind;
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t frame_bytes;
    uint16_t phase;
    uint16_t error_class;
    uint16_t error_code;
    uint16_t error_stage;
    uint8_t candidate_start_state;
    uint8_t cleanup_state;
    uint8_t started_attested;
    uint8_t launcher_reap_state;
    uint8_t result_eof_state;
    int supervisor_wait_status;
};

/* Every non-ambiguous return owns the reap; ambiguity is reported explicitly. */
int proc17_qa_launcher_collect_v1(
    pid_t supervisor,
    int supervisor_pidfd,
    int result_descriptor,
    unsigned int watchdog_seconds,
    const struct proc17_qa_launcher_v1_expectation *expectation,
    struct proc17_qa_launcher_v1_terminal *terminal);

#endif
