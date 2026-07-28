#define _GNU_SOURCE

#include "proc17_qa_scratch.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/openat2.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/syscall.h>
#include <unistd.h>

#include "proc17_qa_policy.h"

_Static_assert(PROC17_QA_SCRATCH_MEASUREMENT_V1_BYTES == 40U,
    "scratch measurement must match RUN v1 wire layout");
_Static_assert(PROC17_QA_SCRATCH_MAX_DEPTH == UINT64_C(64),
    "scratch depth is part of the isolation policy");

struct walk_state {
    const struct proc17_qa_scratch_baseline *baseline;
    struct proc17_qa_scratch_measurement *measurement;
    uint8_t home_seen;
    uint8_t temporary_seen;
};

static int open_beneath(int directory_descriptor, const char *name, int flags)
{
    struct open_how how;

    if (directory_descriptor < 0 || name == NULL || name[0] == '\0') {
        errno = EINVAL;
        return -1;
    }
    memset(&how, 0, sizeof(how));
    how.flags = (uint64_t)(flags | O_CLOEXEC);
    how.resolve = RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS
        | RESOLVE_NO_MAGICLINKS | RESOLVE_NO_XDEV;
    return (int)syscall(SYS_openat2, directory_descriptor,
        name, &how, sizeof(how));
}

static int identity_from_descriptor(
    int descriptor,
    struct proc17_qa_scratch_identity *identity)
{
    struct stat status;

    if (descriptor < 0 || identity == NULL || fstat(descriptor, &status) != 0
        || (uintmax_t)status.st_dev > UINT64_MAX
        || (uintmax_t)status.st_ino > UINT64_MAX) {
        return -1;
    }
    identity->device = (uint64_t)status.st_dev;
    identity->inode = (uint64_t)status.st_ino;
    identity->mode = (uint32_t)status.st_mode;
    return 0;
}

static int same_identity(
    const struct proc17_qa_scratch_identity *left,
    const struct proc17_qa_scratch_identity *right)
{
    return left != NULL && right != NULL
        && left->device == right->device
        && left->inode == right->inode
        && left->mode == right->mode;
}

static int close_directory(DIR *stream, int result)
{
    int saved = errno;
    if (closedir(stream) != 0 && result == 0) result = -1;
    errno = saved;
    return result;
}

static int directory_is_empty(int descriptor)
{
    DIR *stream;
    struct dirent *entry;
    int scan_descriptor = open_beneath(descriptor, ".",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW);
    int result = 0;

    if (scan_descriptor < 0) return -1;
    stream = fdopendir(scan_descriptor);
    if (stream == NULL) {
        close(scan_descriptor);
        return -1;
    }
    errno = 0;
    while ((entry = readdir(stream)) != NULL) {
        if (strcmp(entry->d_name, ".") != 0
            && strcmp(entry->d_name, "..") != 0) {
            result = -1;
            break;
        }
        errno = 0;
    }
    if (entry == NULL && errno != 0) result = -1;
    return close_directory(stream, result);
}

static int capture_initial_directory(
    int root_descriptor,
    const char *name,
    struct proc17_qa_scratch_identity *identity)
{
    int descriptor = open_beneath(root_descriptor, name,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW);
    int result;

    if (descriptor < 0) return -1;
    result = identity_from_descriptor(descriptor, identity);
    if (result == 0
        && (!S_ISDIR((mode_t)identity->mode)
            || (identity->mode & 07777U) != 0700U
            || directory_is_empty(descriptor) != 0)) {
        result = -1;
    }
    if (close(descriptor) != 0) result = -1;
    return result;
}

static int initial_root_is_exact(int root_descriptor)
{
    int scan_descriptor = open_beneath(root_descriptor, ".",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW);
    DIR *stream;
    struct dirent *entry;
    unsigned int seen = 0U;
    int result = 0;

    if (scan_descriptor < 0) return -1;
    stream = fdopendir(scan_descriptor);
    if (stream == NULL) {
        close(scan_descriptor);
        return -1;
    }
    errno = 0;
    while ((entry = readdir(stream)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0
            || strcmp(entry->d_name, "..") == 0) {
            errno = 0;
            continue;
        }
        if (strcmp(entry->d_name, "home") == 0 && (seen & 1U) == 0U) {
            seen |= 1U;
        } else if (strcmp(entry->d_name, "tmp") == 0
                && (seen & 2U) == 0U) {
            seen |= 2U;
        } else {
            result = -1;
            break;
        }
        errno = 0;
    }
    if (entry == NULL && errno != 0) result = -1;
    if (seen != 3U) result = -1;
    return close_directory(stream, result);
}

int proc17_qa_scratch_capture_baseline(
    int scratch_root_descriptor,
    struct proc17_qa_scratch_baseline *baseline)
{
    struct proc17_qa_scratch_baseline captured;

    if (scratch_root_descriptor < 0 || baseline == NULL) return -1;
    memset(&captured, 0, sizeof(captured));
    if (identity_from_descriptor(scratch_root_descriptor, &captured.root) != 0
        || !S_ISDIR((mode_t)captured.root.mode)
        || initial_root_is_exact(scratch_root_descriptor) != 0
        || capture_initial_directory(scratch_root_descriptor,
            "home", &captured.home) != 0
        || capture_initial_directory(scratch_root_descriptor,
            "tmp", &captured.temporary) != 0) {
        return -1;
    }
    captured.captured = 1U;
    *baseline = captured;
    return 0;
}

static int count_candidate_entry(
    struct proc17_qa_scratch_measurement *measurement)
{
    if (measurement->stored_entries == UINT64_MAX
        || measurement->stored_entries + 1U > measurement->limit_entries) {
        return -1;
    }
    measurement->stored_entries++;
    return 0;
}

static int count_regular_bytes(
    struct proc17_qa_scratch_measurement *measurement,
    off_t bytes)
{
    uint64_t amount;

    if (bytes < 0 || (uintmax_t)bytes > UINT64_MAX) return -1;
    amount = (uint64_t)bytes;
    if (amount > UINT64_MAX - measurement->stored_regular_bytes
        || measurement->stored_regular_bytes + amount
            > measurement->limit_bytes) {
        return -1;
    }
    measurement->stored_regular_bytes += amount;
    return 0;
}

static int walk_directory(
    int directory_descriptor,
    uint64_t parent_depth,
    struct walk_state *state)
{
    DIR *stream = fdopendir(directory_descriptor);
    struct dirent *entry;
    int result = 0;

    if (stream == NULL) {
        close(directory_descriptor);
        return -1;
    }
    errno = 0;
    while ((entry = readdir(stream)) != NULL) {
        struct proc17_qa_scratch_identity identity;
        struct stat status;
        uint64_t depth;
        int object_descriptor;
        int baseline_entry = 0;

        if (strcmp(entry->d_name, ".") == 0
            || strcmp(entry->d_name, "..") == 0) {
            errno = 0;
            continue;
        }
        if (parent_depth == UINT64_MAX) {
            result = -1;
            break;
        }
        depth = parent_depth + 1U;
        if (depth > PROC17_QA_SCRATCH_MAX_DEPTH) {
            result = -1;
            break;
        }
        object_descriptor = open_beneath(dirfd(stream), entry->d_name,
            O_PATH | O_NOFOLLOW);
        if (object_descriptor < 0
            || identity_from_descriptor(object_descriptor, &identity) != 0
            || fstat(object_descriptor, &status) != 0) {
            if (object_descriptor >= 0) close(object_descriptor);
            result = -1;
            break;
        }
        if (parent_depth == 0U && strcmp(entry->d_name, "home") == 0) {
            baseline_entry = 1;
            state->home_seen++;
            if (state->home_seen != 1U
                || !same_identity(&identity, &state->baseline->home)) {
                close(object_descriptor);
                result = -1;
                break;
            }
        } else if (parent_depth == 0U
                && strcmp(entry->d_name, "tmp") == 0) {
            baseline_entry = 1;
            state->temporary_seen++;
            if (state->temporary_seen != 1U
                || !same_identity(&identity, &state->baseline->temporary)) {
                close(object_descriptor);
                result = -1;
                break;
            }
        }
        if (!baseline_entry
            && count_candidate_entry(state->measurement) != 0) {
            close(object_descriptor);
            result = -1;
            break;
        }
        if (S_ISREG(status.st_mode)) {
            if (baseline_entry
                || count_regular_bytes(state->measurement, status.st_size) != 0) {
                close(object_descriptor);
                result = -1;
                break;
            }
            if (close(object_descriptor) != 0) {
                result = -1;
                break;
            }
        } else if (S_ISDIR(status.st_mode)) {
            struct proc17_qa_scratch_identity opened_identity;
            int child_descriptor = open_beneath(dirfd(stream), entry->d_name,
                O_RDONLY | O_DIRECTORY | O_NOFOLLOW);
            if (child_descriptor < 0
                || identity_from_descriptor(
                    child_descriptor, &opened_identity) != 0
                || !same_identity(&identity, &opened_identity)
                || close(object_descriptor) != 0) {
                if (child_descriptor >= 0) close(child_descriptor);
                result = -1;
                break;
            }
            if (walk_directory(child_descriptor, depth, state) != 0) {
                result = -1;
                break;
            }
        } else {
            close(object_descriptor);
            result = -1;
            break;
        }
        errno = 0;
    }
    if (entry == NULL && errno != 0) result = -1;
    return close_directory(stream, result);
}

static int measurement_valid(
    const struct proc17_qa_scratch_measurement *measurement)
{
    return measurement != NULL
        && measurement->limit_bytes != 0U
        && measurement->limit_entries != 0U
        && measurement->stored_regular_bytes <= measurement->limit_bytes
        && measurement->stored_entries <= measurement->limit_entries
        && measurement->byte_capacity_exhausted <= 1U
        && measurement->entry_capacity_exhausted <= 1U
        && measurement->inventory_complete == 1U;
}

int proc17_qa_scratch_measure_final(
    int scratch_root_descriptor,
    const struct proc17_qa_scratch_baseline *baseline,
    uint64_t limit_bytes,
    uint64_t limit_entries,
    struct proc17_qa_scratch_measurement *measurement)
{
    struct proc17_qa_scratch_identity root_identity;
    struct proc17_qa_scratch_measurement observed;
    struct walk_state state;
    struct statvfs capacity;
    int scan_descriptor;

    if (scratch_root_descriptor < 0 || baseline == NULL
        || baseline->captured != 1U || measurement == NULL
        || limit_bytes == 0U || limit_entries == 0U) {
        return PROC17_QA_SCRATCH_INVALID;
    }
    memset(measurement, 0, sizeof(*measurement));
    memset(&observed, 0, sizeof(observed));
    observed.limit_bytes = limit_bytes;
    observed.limit_entries = limit_entries;
    memset(&state, 0, sizeof(state));
    state.baseline = baseline;
    state.measurement = &observed;
    if (identity_from_descriptor(scratch_root_descriptor, &root_identity) != 0
        || !same_identity(&root_identity, &baseline->root)) {
        return PROC17_QA_SCRATCH_AMBIGUOUS;
    }
    scan_descriptor = open_beneath(scratch_root_descriptor, ".",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW);
    if (scan_descriptor < 0
        || walk_directory(scan_descriptor, 0U, &state) != 0
        || state.home_seen != 1U || state.temporary_seen != 1U
        || fstatvfs(scratch_root_descriptor, &capacity) != 0
        || capacity.f_bavail == (fsblkcnt_t)-1
        || capacity.f_favail == (fsfilcnt_t)-1) {
        if (scan_descriptor >= 0 && state.home_seen == 0U
            && state.temporary_seen == 0U) {
            /* walk_directory owns a successfully opened descriptor. */
        }
        return PROC17_QA_SCRATCH_AMBIGUOUS;
    }
    observed.byte_capacity_exhausted = capacity.f_bavail == 0 ? 1U : 0U;
    observed.entry_capacity_exhausted = capacity.f_favail == 0 ? 1U : 0U;
    observed.inventory_complete = 1U;
    if (!measurement_valid(&observed)) {
        return PROC17_QA_SCRATCH_AMBIGUOUS;
    }
    *measurement = observed;
    return PROC17_QA_SCRATCH_COMPLETE;
}

int proc17_qa_scratch_encode_v1(
    const struct proc17_qa_scratch_measurement *measurement,
    unsigned char output[PROC17_QA_SCRATCH_MEASUREMENT_V1_BYTES])
{
    if (!measurement_valid(measurement) || output == NULL) return -1;
    memset(output, 0, PROC17_QA_SCRATCH_MEASUREMENT_V1_BYTES);
    proc17_qa_wire_put_u64(output, measurement->stored_regular_bytes);
    proc17_qa_wire_put_u64(output + 8U, measurement->stored_entries);
    proc17_qa_wire_put_u64(output + 16U, measurement->limit_bytes);
    proc17_qa_wire_put_u64(output + 24U, measurement->limit_entries);
    output[32U] = measurement->byte_capacity_exhausted;
    output[33U] = measurement->entry_capacity_exhausted;
    output[34U] = measurement->inventory_complete;
    return proc17_qa_wire_v1_scratch_valid(output) ? 0 : -1;
}

int proc17_qa_scratch_decode_v1(
    const unsigned char input[PROC17_QA_SCRATCH_MEASUREMENT_V1_BYTES],
    struct proc17_qa_scratch_measurement *measurement)
{
    struct proc17_qa_scratch_measurement decoded;

    if (input == NULL || measurement == NULL
        || !proc17_qa_wire_v1_scratch_valid(input)) {
        return -1;
    }
    memset(&decoded, 0, sizeof(decoded));
    decoded.stored_regular_bytes = proc17_qa_wire_get_u64(input);
    decoded.stored_entries = proc17_qa_wire_get_u64(input + 8U);
    decoded.limit_bytes = proc17_qa_wire_get_u64(input + 16U);
    decoded.limit_entries = proc17_qa_wire_get_u64(input + 24U);
    decoded.byte_capacity_exhausted = input[32U];
    decoded.entry_capacity_exhausted = input[33U];
    decoded.inventory_complete = input[34U];
    if (!measurement_valid(&decoded)) return -1;
    *measurement = decoded;
    return 0;
}
