#define _GNU_SOURCE

#include "proc17_qa_allocator.h"

#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

#define PROC17_QA_ALLOCATOR_TELEMETRY_MAGIC UINT64_C(0x5031375141485031)

union proc17_qa_allocation_header {
    max_align_t alignment;
    size_t bytes;
};

_Static_assert(sizeof(struct proc17_qa_allocator_telemetry)
        == PROC17_QA_ALLOCATOR_TELEMETRY_BYTES,
    "allocator telemetry ABI must be 64 bytes");
_Static_assert(offsetof(struct proc17_qa_allocator_telemetry, ceiling_bytes)
        == 16U, "allocator telemetry ceiling offset");
_Static_assert(offsetof(struct proc17_qa_allocator_telemetry, current_bytes)
        == 24U, "allocator telemetry current offset");
_Static_assert(offsetof(struct proc17_qa_allocator_telemetry, peak_bytes)
        == 32U, "allocator telemetry peak offset");
_Static_assert(offsetof(struct proc17_qa_allocator_telemetry, ceiling_denied)
        == 40U, "allocator telemetry denial offset");
_Static_assert(sizeof(_Atomic uint64_t) == sizeof(uint64_t),
    "allocator uint64 atomics must preserve ABI width");
_Static_assert(sizeof(_Atomic uint32_t) == sizeof(uint32_t),
    "allocator uint32 atomics must preserve ABI width");
_Static_assert(SIZE_MAX <= UINT64_MAX,
    "allocator accounting requires size_t no wider than uint64_t");

static int atomics_lock_free(
    const struct proc17_qa_allocator_telemetry *telemetry)
{
    return atomic_is_lock_free(&telemetry->current_bytes)
        && atomic_is_lock_free(&telemetry->peak_bytes)
        && atomic_is_lock_free(&telemetry->ceiling_denied)
        && atomic_is_lock_free(&telemetry->system_allocation_failed)
        && atomic_is_lock_free(&telemetry->status_notification_failed);
}

static int header_valid(
    const struct proc17_qa_allocator_telemetry *telemetry)
{
    return telemetry != NULL
        && telemetry->magic == PROC17_QA_ALLOCATOR_TELEMETRY_MAGIC
        && telemetry->version == PROC17_QA_ALLOCATOR_TELEMETRY_VERSION
        && telemetry->record_bytes == PROC17_QA_ALLOCATOR_TELEMETRY_BYTES
        && telemetry->reserved_header == 0U
        && telemetry->ceiling_bytes != 0U
        && telemetry->ceiling_bytes <= SIZE_MAX
        && telemetry->reserved_flags == 0U
        && telemetry->reserved_tail == 0U
        && atomics_lock_free(telemetry);
}

int proc17_qa_allocator_telemetry_init(
    struct proc17_qa_allocator_telemetry *telemetry,
    uint64_t ceiling_bytes)
{
    if (telemetry == NULL || ceiling_bytes == 0U
        || ceiling_bytes > SIZE_MAX) {
        return -1;
    }
    memset(telemetry, 0, sizeof(*telemetry));
    telemetry->magic = PROC17_QA_ALLOCATOR_TELEMETRY_MAGIC;
    telemetry->version = PROC17_QA_ALLOCATOR_TELEMETRY_VERSION;
    telemetry->record_bytes = PROC17_QA_ALLOCATOR_TELEMETRY_BYTES;
    telemetry->ceiling_bytes = ceiling_bytes;
    atomic_init(&telemetry->current_bytes, 0U);
    atomic_init(&telemetry->peak_bytes, 0U);
    atomic_init(&telemetry->ceiling_denied, 0U);
    atomic_init(&telemetry->system_allocation_failed, 0U);
    atomic_init(&telemetry->status_notification_failed, 0U);
    return header_valid(telemetry) ? 0 : -1;
}

int proc17_qa_allocator_telemetry_map(
    uint64_t ceiling_bytes,
    struct proc17_qa_allocator_telemetry **telemetry)
{
    struct proc17_qa_allocator_telemetry *mapped;

    if (telemetry == NULL) return -1;
    *telemetry = NULL;
    mapped = mmap(NULL, sizeof(*mapped), PROT_READ | PROT_WRITE,
        MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (mapped == MAP_FAILED) return -1;
    if (proc17_qa_allocator_telemetry_init(mapped, ceiling_bytes) != 0) {
        (void)munmap(mapped, sizeof(*mapped));
        return -1;
    }
    *telemetry = mapped;
    return 0;
}

int proc17_qa_allocator_telemetry_make_read_only(
    struct proc17_qa_allocator_telemetry *telemetry)
{
    return header_valid(telemetry)
        && mprotect(telemetry, sizeof(*telemetry), PROT_READ) == 0 ? 0 : -1;
}

int proc17_qa_allocator_telemetry_unmap(
    struct proc17_qa_allocator_telemetry *telemetry)
{
    return telemetry != NULL
        && munmap(telemetry, sizeof(*telemetry)) == 0 ? 0 : -1;
}

int proc17_qa_allocator_snapshot(
    const struct proc17_qa_allocator_telemetry *telemetry,
    struct proc17_qa_allocator_snapshot *snapshot)
{
    uint64_t current;
    uint64_t peak;
    uint32_t denied;
    uint32_t system_failed;
    uint32_t notification_failed;

    if (!header_valid(telemetry) || snapshot == NULL) return -1;
    current = atomic_load_explicit(
        &telemetry->current_bytes, memory_order_acquire);
    peak = atomic_load_explicit(
        &telemetry->peak_bytes, memory_order_acquire);
    denied = atomic_load_explicit(
        &telemetry->ceiling_denied, memory_order_acquire);
    system_failed = atomic_load_explicit(
        &telemetry->system_allocation_failed, memory_order_acquire);
    notification_failed = atomic_load_explicit(
        &telemetry->status_notification_failed, memory_order_acquire);
    if (current > peak || peak > telemetry->ceiling_bytes
        || denied > 1U || system_failed > 1U || notification_failed > 1U
        || (notification_failed != 0U && denied == 0U)) {
        return -1;
    }
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->ceiling_bytes = telemetry->ceiling_bytes;
    snapshot->current_bytes = current;
    snapshot->peak_bytes = peak;
    snapshot->ceiling_denied = (uint8_t)denied;
    snapshot->system_allocation_failed = (uint8_t)system_failed;
    snapshot->status_notification_failed = (uint8_t)notification_failed;
    return 0;
}

int proc17_qa_allocator_state_init(
    struct proc17_qa_allocator_state *state,
    struct proc17_qa_allocator_telemetry *telemetry,
    proc17_qa_allocator_notify_fn notify_heap_denied,
    void *notify_opaque)
{
    struct proc17_qa_allocator_snapshot snapshot;

    if (state == NULL || proc17_qa_allocator_snapshot(
            telemetry, &snapshot) != 0
        || snapshot.current_bytes != 0U || snapshot.peak_bytes != 0U
        || snapshot.ceiling_denied != 0U
        || snapshot.system_allocation_failed != 0U
        || snapshot.status_notification_failed != 0U) {
        return -1;
    }
    state->telemetry = telemetry;
    state->notify_heap_denied = notify_heap_denied;
    state->notify_opaque = notify_opaque;
    return 0;
}

static void publish_peak(
    struct proc17_qa_allocator_telemetry *telemetry,
    uint64_t value)
{
    uint64_t peak = atomic_load_explicit(
        &telemetry->peak_bytes, memory_order_relaxed);
    while (peak < value && !atomic_compare_exchange_weak_explicit(
            &telemetry->peak_bytes, &peak, value,
            memory_order_release, memory_order_relaxed)) {
    }
}

static void mark_ceiling_denied(struct proc17_qa_allocator_state *state)
{
    uint32_t prior = atomic_exchange_explicit(
        &state->telemetry->ceiling_denied, 1U, memory_order_release);
    if (prior == 0U && state->notify_heap_denied != NULL
        && state->notify_heap_denied(state->notify_opaque) != 0) {
        atomic_store_explicit(
            &state->telemetry->status_notification_failed,
            1U, memory_order_release);
    }
}

void *proc17_qa_lua_allocator(
    void *opaque,
    void *pointer,
    size_t old_size,
    size_t new_size)
{
    struct proc17_qa_allocator_state *state = opaque;
    struct proc17_qa_allocator_telemetry *telemetry;
    union proc17_qa_allocation_header *header = NULL;
    uint64_t current;
    uint64_t prior = 0U;
    uint64_t base;
    uint64_t next;
    size_t total;
    (void)old_size;

    if (state == NULL || !header_valid(state->telemetry)) return NULL;
    telemetry = state->telemetry;
    current = atomic_load_explicit(
        &telemetry->current_bytes, memory_order_relaxed);
    if (pointer != NULL) {
        header = (union proc17_qa_allocation_header *)pointer - 1;
        prior = header->bytes;
        if (prior > current) {
            atomic_store_explicit(&telemetry->system_allocation_failed,
                1U, memory_order_release);
            return NULL;
        }
    }
    base = current - prior;
    if (new_size == 0U) {
        if (pointer != NULL) {
            atomic_store_explicit(
                &telemetry->current_bytes, base, memory_order_release);
            free(header);
        }
        return NULL;
    }
    if ((uint64_t)new_size > telemetry->ceiling_bytes - base
        || new_size > SIZE_MAX - sizeof(*header)) {
        mark_ceiling_denied(state);
        return NULL;
    }
    total = sizeof(*header) + new_size;
    next = base + (uint64_t)new_size;
    publish_peak(telemetry, next);
    atomic_store_explicit(
        &telemetry->current_bytes, next, memory_order_release);
    header = pointer == NULL ? malloc(total) : realloc(header, total);
    if (header == NULL) {
        atomic_store_explicit(&telemetry->system_allocation_failed,
            1U, memory_order_release);
        atomic_store_explicit(
            &telemetry->current_bytes, current, memory_order_release);
        return NULL;
    }
    header->bytes = new_size;
    return header + 1;
}
