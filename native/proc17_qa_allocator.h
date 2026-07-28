#ifndef PROC17_QA_ALLOCATOR_H
#define PROC17_QA_ALLOCATOR_H

#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>

#define PROC17_QA_ALLOCATOR_TELEMETRY_VERSION 1U
#define PROC17_QA_ALLOCATOR_TELEMETRY_BYTES 64U

typedef int (*proc17_qa_allocator_notify_fn)(void *opaque);

struct proc17_qa_allocator_telemetry {
    uint64_t magic;
    uint16_t version;
    uint16_t record_bytes;
    uint32_t reserved_header;
    uint64_t ceiling_bytes;
    _Atomic uint64_t current_bytes;
    _Atomic uint64_t peak_bytes;
    _Atomic uint32_t ceiling_denied;
    _Atomic uint32_t system_allocation_failed;
    _Atomic uint32_t status_notification_failed;
    uint32_t reserved_flags;
    uint64_t reserved_tail;
};

struct proc17_qa_allocator_snapshot {
    uint64_t ceiling_bytes;
    uint64_t current_bytes;
    uint64_t peak_bytes;
    uint8_t ceiling_denied;
    uint8_t system_allocation_failed;
    uint8_t status_notification_failed;
};

struct proc17_qa_allocator_state {
    struct proc17_qa_allocator_telemetry *telemetry;
    proc17_qa_allocator_notify_fn notify_heap_denied;
    void *notify_opaque;
};

int proc17_qa_allocator_telemetry_init(
    struct proc17_qa_allocator_telemetry *telemetry,
    uint64_t ceiling_bytes);

int proc17_qa_allocator_telemetry_map(
    uint64_t ceiling_bytes,
    struct proc17_qa_allocator_telemetry **telemetry);

int proc17_qa_allocator_telemetry_make_read_only(
    struct proc17_qa_allocator_telemetry *telemetry);

int proc17_qa_allocator_telemetry_unmap(
    struct proc17_qa_allocator_telemetry *telemetry);

int proc17_qa_allocator_snapshot(
    const struct proc17_qa_allocator_telemetry *telemetry,
    struct proc17_qa_allocator_snapshot *snapshot);

int proc17_qa_allocator_state_init(
    struct proc17_qa_allocator_state *state,
    struct proc17_qa_allocator_telemetry *telemetry,
    proc17_qa_allocator_notify_fn notify_heap_denied,
    void *notify_opaque);

void *proc17_qa_lua_allocator(
    void *opaque,
    void *pointer,
    size_t old_size,
    size_t new_size);

#endif
