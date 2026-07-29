#define _GNU_SOURCE

#include "proc17_qa_residue_observer.h"

#include "../generated/proc17_qa_build_identity.h"
#include "../proc17_sha256.h"

#include <ctype.h>
#include <dirent.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <limits.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <sys/types.h>
#include <unistd.h>

#define SESSION_MAGIC UINT64_C(0x71617265736f6273)
#define SUBJECT_MAGIC UINT64_C(0x716172657375626a)
#define SNAPSHOT_MAGIC UINT64_C(0x71617265736e6170)
#define PROC_FILE_LIMIT (1024U * 1024U)
#define CGROUP_FILE_LIMIT (64U * 1024U)
#define SUPERVISOR_FILE_LIMIT (64U * 1024U * 1024U)
#define MAX_FD_RECORDS 4096U
#define MAX_ROOT_RECORDS 256U
#define MAX_PROCESS_RECORDS 32768U
#define ROOT_PARENT "/tmp"
#define ROOT_PREFIX "proc17-repository-hand-"
#define ROOT_PREFIX_BYTES (sizeof(ROOT_PREFIX) - 1U)
#define ROOT_SUFFIX_BYTES 6U
#define ROOT_PATH_BYTES (sizeof(ROOT_PARENT) - 1U + 1U \
    + ROOT_PREFIX_BYTES + ROOT_SUFFIX_BYTES + 1U)
#define SOURCE_SUFFIX "/projects/candidate"
#define NAMESPACE_COUNT 6U

struct fd_record {
    int number;
    uint64_t device;
    uint64_t inode;
    uint32_t mode;
    int descriptor_flags;
    int status_flags;
    uint8_t link_available;
    unsigned char link_digest[PROC17_SHA256_BYTES];
};

struct root_record {
    char basename[ROOT_PREFIX_BYTES + ROOT_SUFFIX_BYTES + 1U];
    uint64_t device;
    uint64_t inode;
    uint64_t mount_id;
    uint32_t mode;
};

struct namespace_record {
    uint64_t device;
    uint64_t inode;
};

struct proc17_qa_residue_session {
    uint64_t magic;
    uint64_t cookie;
    pid_t campaign_pid;
    uint64_t campaign_starttime;
    uint64_t supervisor_device;
    uint64_t supervisor_inode;
    unsigned char supervisor_digest[PROC17_SHA256_BYTES];
    char *cgroup;
    size_t cgroup_bytes;
    char session_id[PROC17_QA_RESIDUE_ID_BYTES];
};

struct proc17_qa_residue_subject {
    uint64_t magic;
    uint64_t session_cookie;
    struct proc17_qa_residue_root_identity identity;
    char basename[ROOT_PREFIX_BYTES + ROOT_SUFFIX_BYTES + 1U];
    char source_path[PROC17_QA_RESIDUE_PATH_BYTES + sizeof(SOURCE_SUFFIX)];
    char subject_id[PROC17_QA_RESIDUE_ID_BYTES];
};

struct proc17_qa_residue_snapshot {
    uint64_t magic;
    uint64_t session_cookie;
    enum proc17_qa_residue_scope scope;
    uint8_t has_subject;
    struct proc17_qa_residue_root_identity subject_identity;
    char subject_id[PROC17_QA_RESIDUE_ID_BYTES];
    struct fd_record *fds;
    size_t fd_count;
    struct root_record *roots;
    size_t root_count;
    struct namespace_record namespaces[NAMESPACE_COUNT];
    uint64_t direct_live_children;
    uint64_t direct_zombies;
    uint64_t matching_supervisors;
    uint64_t unresolved_supervisor_zombies;
    uint64_t qa_mounts;
    uint64_t owned_source_mounts;
    char snapshot_id[PROC17_QA_RESIDUE_ID_BYTES];
    char fd_set_id[PROC17_QA_RESIDUE_ID_BYTES];
    char namespace_set_id[PROC17_QA_RESIDUE_ID_BYTES];
    char root_set_id[PROC17_QA_RESIDUE_ID_BYTES];
};

struct mount_counts {
    uint64_t qa;
    uint64_t owned_source;
};

static _Atomic uint64_t next_session_cookie = UINT64_C(1);

static int set_error(
    struct proc17_qa_residue_error *error,
    const char *code,
    const char *stage,
    int system_errno)
{
    if (error != NULL) {
        memset(error, 0, sizeof(*error));
        if (code != NULL) {
            (void)snprintf(error->code, sizeof(error->code), "%s", code);
        }
        if (stage != NULL) {
            (void)snprintf(error->stage, sizeof(error->stage), "%s", stage);
        }
        error->system_errno = system_errno;
    }
    return -1;
}

static int close_owned(int *descriptor)
{
    int closing;

    if (descriptor == NULL || *descriptor < 0) return 0;
    closing = *descriptor;
    *descriptor = -1;
    return close(closing);
}

static int ascii_alnum(unsigned char byte)
{
    return (byte >= 'a' && byte <= 'z')
        || (byte >= 'A' && byte <= 'Z')
        || (byte >= '0' && byte <= '9');
}

static int valid_root_path(const char *path, const char **basename_out)
{
    static const char prefix[] = ROOT_PARENT "/" ROOT_PREFIX;
    size_t prefix_bytes = sizeof(prefix) - 1U;
    size_t length;
    size_t index;

    if (path == NULL || strncmp(path, prefix, prefix_bytes) != 0) {
        errno = EINVAL;
        return -1;
    }
    length = strlen(path);
    if (length != prefix_bytes + ROOT_SUFFIX_BYTES) {
        errno = EINVAL;
        return -1;
    }
    for (index = prefix_bytes; index < length; index++) {
        if (!ascii_alnum((unsigned char)path[index])) {
            errno = EINVAL;
            return -1;
        }
    }
    if (basename_out != NULL) {
        *basename_out = path + sizeof(ROOT_PARENT);
    }
    return 0;
}

static int valid_root_basename(const char *name)
{
    size_t index;

    if (name == NULL || strlen(name) != ROOT_PREFIX_BYTES + ROOT_SUFFIX_BYTES
        || strncmp(name, ROOT_PREFIX, ROOT_PREFIX_BYTES) != 0) {
        return 0;
    }
    for (index = ROOT_PREFIX_BYTES;
            index < ROOT_PREFIX_BYTES + ROOT_SUFFIX_BYTES; index++) {
        if (!ascii_alnum((unsigned char)name[index])) return 0;
    }
    return 1;
}

static void hash_u64(struct proc17_sha256 *hash, uint64_t value)
{
    unsigned char bytes[8];
    size_t index;

    for (index = 0U; index < sizeof(bytes); index++) {
        bytes[sizeof(bytes) - index - 1U] =
            (unsigned char)(value >> (index * 8U));
    }
    proc17_sha256_update(hash, bytes, sizeof(bytes));
}

static void hash_i64(struct proc17_sha256 *hash, int64_t value)
{
    hash_u64(hash, (uint64_t)value);
}

static int finish_tagged_id(
    struct proc17_sha256 *hash,
    const char *prefix,
    char output[PROC17_QA_RESIDUE_ID_BYTES])
{
    unsigned char digest[PROC17_SHA256_BYTES];
    char hex[PROC17_SHA256_BYTES * 2U + 1U];
    int length;

    proc17_sha256_final(hash, digest);
    proc17_sha256_hex(digest, hex);
    length = snprintf(output, PROC17_QA_RESIDUE_ID_BYTES, "%s%s", prefix, hex);
    return length > 0 && (size_t)length < PROC17_QA_RESIDUE_ID_BYTES ? 0 : -1;
}

static int read_bounded_file(
    const char *path,
    size_t limit,
    char **bytes_out,
    size_t *length_out)
{
    char *bytes = NULL;
    size_t length = 0U;
    int descriptor = -1;
    int result = -1;

    if (path == NULL || bytes_out == NULL || length_out == NULL
        || limit == 0U || limit == SIZE_MAX) {
        errno = EINVAL;
        return -1;
    }
    descriptor = open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (descriptor < 0) goto cleanup;
    bytes = calloc(limit + 1U, 1U);
    if (bytes == NULL) goto cleanup;
    while (length <= limit) {
        ssize_t observed = read(descriptor, bytes + length, limit + 1U - length);
        if (observed < 0 && errno == EINTR) continue;
        if (observed < 0) goto cleanup;
        if (observed == 0) break;
        length += (size_t)observed;
        if (length > limit) {
            errno = EFBIG;
            goto cleanup;
        }
    }
    if (close_owned(&descriptor) != 0) goto cleanup;
    bytes[length] = '\0';
    *bytes_out = bytes;
    *length_out = length;
    bytes = NULL;
    result = 0;

cleanup:
    {
        int saved = errno;
        (void)close_owned(&descriptor);
        free(bytes);
        errno = saved;
    }
    return result;
}

static int hash_descriptor(
    int descriptor,
    unsigned char digest[PROC17_SHA256_BYTES])
{
    struct proc17_sha256 hash;
    unsigned char buffer[16384];
    off_t offset = 0;
    size_t total = 0U;

    proc17_sha256_init(&hash);
    for (;;) {
        ssize_t observed = pread(descriptor, buffer, sizeof(buffer), offset);
        if (observed < 0 && errno == EINTR) continue;
        if (observed < 0) return -1;
        if (observed == 0) break;
        if ((size_t)observed > SUPERVISOR_FILE_LIMIT - total) {
            errno = EFBIG;
            return -1;
        }
        proc17_sha256_update(&hash, buffer, (size_t)observed);
        total += (size_t)observed;
        offset += observed;
    }
    proc17_sha256_final(&hash, digest);
    return 0;
}

static int supervisor_module_relative_path(char output[PATH_MAX])
{
    Dl_info information;
    const char *slash;
    size_t prefix;
    static const char suffix[] = "../proc17_qa_supervisor";

    memset(&information, 0, sizeof(information));
    if (dladdr((void *)(uintptr_t)&proc17_qa_residue_observer_get_api,
            &information) == 0
        || information.dli_fname == NULL
        || (slash = strrchr(information.dli_fname, '/')) == NULL) {
        errno = ENOENT;
        return -1;
    }
    prefix = (size_t)(slash - information.dli_fname + 1);
    if (prefix + sizeof(suffix) > PATH_MAX) {
        errno = ENAMETOOLONG;
        return -1;
    }
    memcpy(output, information.dli_fname, prefix);
    memcpy(output + prefix, suffix, sizeof(suffix));
    return 0;
}

static int open_verified_supervisor(
    uint64_t *device,
    uint64_t *inode,
    unsigned char digest[PROC17_SHA256_BYTES])
{
    unsigned char expected[PROC17_SHA256_BYTES];
    char path[PATH_MAX];
    struct stat status;
    int descriptor = -1;
    int result = -1;

    if (proc17_sha256_parse_hex(PROC17_QA_EXPECTED_SUPERVISOR_BUILD_ID_HEX,
            expected) != 0
        || supervisor_module_relative_path(path) != 0) {
        return -1;
    }
    descriptor = open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (descriptor < 0 || fstat(descriptor, &status) != 0
        || !S_ISREG(status.st_mode) || status.st_size <= 0
        || (uintmax_t)status.st_size > SUPERVISOR_FILE_LIMIT
        || hash_descriptor(descriptor, digest) != 0
        || memcmp(digest, expected, sizeof(expected)) != 0) {
        goto cleanup;
    }
    *device = (uint64_t)status.st_dev;
    *inode = (uint64_t)status.st_ino;
    result = 0;

cleanup:
    {
        int saved = errno;
        if (close_owned(&descriptor) != 0 && result == 0) result = -1;
        errno = saved;
    }
    return result;
}

static int parse_integer_token(
    const char **cursor,
    const char *end,
    int64_t *value)
{
    char buffer[64];
    size_t length = 0U;
    char *parsed_end = NULL;
    long long parsed;

    while (*cursor < end && **cursor == ' ') (*cursor)++;
    while (*cursor < end && **cursor != ' ' && **cursor != '\n') {
        if (length + 1U >= sizeof(buffer)) return -1;
        buffer[length++] = **cursor;
        (*cursor)++;
    }
    if (length == 0U) return -1;
    buffer[length] = '\0';
    errno = 0;
    parsed = strtoll(buffer, &parsed_end, 10);
    if (errno != 0 || parsed_end == NULL || *parsed_end != '\0') return -1;
    *value = (int64_t)parsed;
    return 0;
}

static int parse_proc_stat_bytes(
    const char *bytes,
    size_t length,
    struct proc17_qa_residue_process_record *record)
{
    const char *end = bytes + length;
    const char *left;
    const char *right = NULL;
    const char *cursor;
    const char *scan;
    int64_t value;
    int field;
    size_t comm_bytes;

    if (bytes == NULL || length == 0U || record == NULL) return -1;
    left = memchr(bytes, '(', length);
    if (left == NULL || left == bytes) return -1;
    for (scan = end; scan > left; scan--) {
        if (scan[-1] == ')') {
            right = scan - 1;
            break;
        }
    }
    if (right == NULL || right <= left + 1 || right + 3 > end) return -1;
    cursor = bytes;
    if (parse_integer_token(&cursor, left, &value) != 0 || value <= 0) {
        return -1;
    }
    while (cursor < left && *cursor == ' ') cursor++;
    if (cursor != left) return -1;
    memset(record, 0, sizeof(*record));
    record->pid = value;
    comm_bytes = (size_t)(right - left - 1);
    if (comm_bytes == 0U || comm_bytes >= sizeof(record->comm)) return -1;
    memcpy(record->comm, left + 1, comm_bytes);
    record->comm[comm_bytes] = '\0';
    cursor = right + 1;
    if (*cursor != ' ') return -1;
    cursor++;
    record->state = *cursor++;
    if (record->state == '\0' || cursor >= end || *cursor != ' ') return -1;
    for (field = 4; field <= 22; field++) {
        if (parse_integer_token(&cursor, end, &value) != 0) return -1;
        if (field == 4) record->ppid = value;
        if (field == 22) {
            if (value < 0) return -1;
            record->starttime = (uint64_t)value;
        }
    }
    return 0;
}

static int read_process_stat(
    pid_t pid,
    struct proc17_qa_residue_process_record *record)
{
    char path[64];
    char *bytes = NULL;
    size_t length = 0U;
    int result = -1;

    if (snprintf(path, sizeof(path), "/proc/%ld/stat", (long)pid) <= 0
        || read_bounded_file(path, 4096U, &bytes, &length) != 0) {
        return -1;
    }
    if (parse_proc_stat_bytes(bytes, length, record) == 0) result = 0;
    else errno = EPROTO;
    free(bytes);
    return result;
}

static int parse_decimal_bytes(
    const char *bytes,
    size_t length,
    int64_t *value)
{
    uint64_t current = 0U;
    size_t index;

    if (length == 0U) return -1;
    for (index = 0U; index < length; index++) {
        unsigned char byte = (unsigned char)bytes[index];
        if (byte < '0' || byte > '9'
            || current > ((uint64_t)INT64_MAX - (uint64_t)(byte - '0')) / 10U) {
            return -1;
        }
        current = current * 10U + (uint64_t)(byte - '0');
    }
    *value = (int64_t)current;
    return 0;
}

static int parse_process_status_bytes(
    pid_t pid,
    const char *bytes,
    size_t length,
    struct proc17_qa_residue_process_record *record)
{
    size_t offset = 0U;
    int have_name = 0;
    int have_state = 0;
    int have_ppid = 0;

    if (bytes == NULL || length == 0U || record == NULL) return -1;
    memset(record, 0, sizeof(*record));
    record->pid = (int64_t)pid;
    while (offset < length) {
        const char *line = bytes + offset;
        const char *newline = memchr(line, '\n', length - offset);
        size_t line_length;
        const char *value;
        size_t value_length;

        if (newline == NULL) return -1;
        line_length = (size_t)(newline - line);
        if (line_length >= 5U && memcmp(line, "Name:", 5U) == 0) {
            if (have_name) return -1;
            value = line + 5U;
            value_length = line_length - 5U;
            while (value_length > 0U
                    && (*value == ' ' || *value == '\t')) {
                value++;
                value_length--;
            }
            if (value_length == 0U || value_length >= sizeof(record->comm)) {
                return -1;
            }
            memcpy(record->comm, value, value_length);
            record->comm[value_length] = '\0';
            have_name = 1;
        } else if (line_length >= 6U
                && memcmp(line, "State:", 6U) == 0) {
            if (have_state) return -1;
            value = line + 6U;
            value_length = line_length - 6U;
            while (value_length > 0U
                    && (*value == ' ' || *value == '\t')) {
                value++;
                value_length--;
            }
            if (value_length == 0U) return -1;
            record->state = *value;
            have_state = 1;
        } else if (line_length >= 5U
                && memcmp(line, "PPid:", 5U) == 0) {
            int64_t parsed;
            if (have_ppid) return -1;
            value = line + 5U;
            value_length = line_length - 5U;
            while (value_length > 0U
                    && (*value == ' ' || *value == '\t')) {
                value++;
                value_length--;
            }
            while (value_length > 0U
                    && (value[value_length - 1U] == ' '
                        || value[value_length - 1U] == '\t')) {
                value_length--;
            }
            if (parse_decimal_bytes(value, value_length, &parsed) != 0) {
                return -1;
            }
            record->ppid = parsed;
            have_ppid = 1;
        }
        offset += line_length + 1U;
    }
    return have_name && have_state && have_ppid ? 0 : -1;
}

static int read_process_status(
    pid_t pid,
    struct proc17_qa_residue_process_record *record)
{
    char path[64];
    char *bytes = NULL;
    size_t length = 0U;
    int result = -1;

    if (snprintf(path, sizeof(path), "/proc/%ld/status", (long)pid) <= 0) {
        errno = EOVERFLOW;
        return -1;
    }
    if (read_bounded_file(path, 16384U, &bytes, &length) != 0) {
        return -1;
    }
    if (parse_process_status_bytes(pid, bytes, length, record) == 0) result = 0;
    else {
        errno = EPROTO;
    }
    free(bytes);
    return result;
}

static int read_process_stat_stable(
    pid_t pid,
    struct proc17_qa_residue_process_record *record)
{
    unsigned int attempt;

    for (attempt = 0U; attempt < 3U; attempt++) {
        if (read_process_stat(pid, record) == 0) return 0;
        if (errno != EPROTO) return -1;
    }
    return read_process_status(pid, record);
}

static int mount_id_at(
    int directory_fd,
    const char *path,
    int flags,
    uint64_t *mount_id)
{
    struct statx status;

    memset(&status, 0, sizeof(status));
    if (statx(directory_fd, path, flags | AT_STATX_SYNC_AS_STAT,
            STATX_TYPE | STATX_MNT_ID, &status) != 0) {
        return -1;
    }
    if ((status.stx_mask & STATX_MNT_ID) == 0) {
        errno = ENOTSUP;
        return -1;
    }
    *mount_id = status.stx_mnt_id;
    return 0;
}

static int root_identity_id(
    const struct proc17_qa_residue_root_identity *identity,
    const char *prefix,
    char output[PROC17_QA_RESIDUE_ID_BYTES])
{
    struct proc17_sha256 hash;

    proc17_sha256_init(&hash);
    hash_u64(&hash, identity->device);
    hash_u64(&hash, identity->inode);
    hash_u64(&hash, identity->mount_id);
    return finish_tagged_id(&hash, prefix, output);
}

static int session_valid(const struct proc17_qa_residue_session *session)
{
    return session != NULL && session->magic == SESSION_MAGIC
        && session->cookie != 0U && session->cgroup != NULL;
}

static int subject_valid(const struct proc17_qa_residue_subject *subject)
{
    return subject != NULL && subject->magic == SUBJECT_MAGIC
        && subject->session_cookie != 0U;
}

static int snapshot_valid(const struct proc17_qa_residue_snapshot *snapshot)
{
    return snapshot != NULL && snapshot->magic == SNAPSHOT_MAGIC
        && snapshot->session_cookie != 0U;
}

static int session_open_impl(
    struct proc17_qa_residue_session **session_out,
    struct proc17_qa_residue_error *error)
{
    struct proc17_qa_residue_session *session = NULL;
    struct proc17_qa_residue_process_record self;
    struct proc17_sha256 hash;
    char *cgroup = NULL;
    size_t cgroup_bytes = 0U;
    uint64_t cookie;
    int saved;

    if (session_out == NULL) {
        return set_error(error, "invalid_request", "session_open", EINVAL);
    }
    *session_out = NULL;
    session = calloc(1U, sizeof(*session));
    if (session == NULL) {
        return set_error(error, "observer_allocation_failed", "session_open", errno);
    }
    if (open_verified_supervisor(&session->supervisor_device,
            &session->supervisor_inode, session->supervisor_digest) != 0) {
        saved = errno;
        free(session);
        return set_error(error, "supervisor_identity_unavailable",
            "session_open", saved);
    }
    session->campaign_pid = getpid();
    if (read_process_stat(session->campaign_pid, &self) != 0
        || self.pid != session->campaign_pid
        || read_bounded_file("/proc/self/cgroup", CGROUP_FILE_LIMIT,
            &cgroup, &cgroup_bytes) != 0
        || cgroup_bytes == 0U) {
        saved = errno == 0 ? EPROTO : errno;
        free(cgroup);
        free(session);
        return set_error(error, "observer_environment_unsupported",
            "session_open", saved);
    }
    cookie = atomic_fetch_add_explicit(
        &next_session_cookie, UINT64_C(1), memory_order_relaxed);
    if (cookie == 0U) {
        free(cgroup);
        free(session);
        return set_error(error, "session_identity_exhausted",
            "session_open", EOVERFLOW);
    }
    session->magic = SESSION_MAGIC;
    session->cookie = cookie;
    session->campaign_starttime = self.starttime;
    session->cgroup = cgroup;
    session->cgroup_bytes = cgroup_bytes;
    proc17_sha256_init(&hash);
    hash_u64(&hash, cookie);
    hash_i64(&hash, session->campaign_pid);
    hash_u64(&hash, session->campaign_starttime);
    proc17_sha256_update(&hash, session->supervisor_digest,
        sizeof(session->supervisor_digest));
    proc17_sha256_update(&hash, cgroup, cgroup_bytes);
    if (finish_tagged_id(&hash, "qa-observer-session:",
            session->session_id) != 0) {
        free(cgroup);
        free(session);
        return set_error(error, "session_identity_unrepresentable",
            "session_open", EOVERFLOW);
    }
    *session_out = session;
    if (error != NULL) memset(error, 0, sizeof(*error));
    return 0;
}

static void session_destroy_impl(struct proc17_qa_residue_session *session)
{
    if (!session_valid(session)) return;
    session->magic = 0U;
    free(session->cgroup);
    session->cgroup = NULL;
    memset(session, 0, sizeof(*session));
    free(session);
}

static int subject_bind_impl(
    struct proc17_qa_residue_session *session,
    const struct proc17_qa_residue_root_identity *identity,
    struct proc17_qa_residue_subject **subject_out,
    struct proc17_qa_residue_error *error)
{
    struct proc17_qa_residue_subject *subject = NULL;
    const char *basename = NULL;
    struct stat status;
    uint64_t mount_id = 0U;
    int parent = -1;
    int root = -1;
    int saved;

    if (!session_valid(session) || identity == NULL || subject_out == NULL) {
        return set_error(error, "invalid_request", "subject_bind", EINVAL);
    }
    *subject_out = NULL;
    if (valid_root_path(identity->path, &basename) != 0) {
        return set_error(error, "owned_root_path_rejected", "subject_bind", errno);
    }
    parent = open(ROOT_PARENT, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW);
    if (parent < 0) goto world_error;
    root = openat(parent, basename,
        O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW);
    if (root < 0 || fstat(root, &status) != 0
        || mount_id_at(root, "", AT_EMPTY_PATH, &mount_id) != 0
        || (uint64_t)status.st_dev != identity->device
        || (uint64_t)status.st_ino != identity->inode
        || mount_id != identity->mount_id) {
        if (errno == 0) errno = ESTALE;
        goto world_error;
    }
    subject = calloc(1U, sizeof(*subject));
    if (subject == NULL) goto world_error;
    subject->magic = SUBJECT_MAGIC;
    subject->session_cookie = session->cookie;
    subject->identity = *identity;
    (void)snprintf(subject->basename, sizeof(subject->basename), "%s", basename);
    if (snprintf(subject->source_path, sizeof(subject->source_path), "%s%s",
            identity->path, SOURCE_SUFFIX) <= 0
        || root_identity_id(identity, "qa-owned-source:",
            subject->subject_id) != 0) {
        errno = EOVERFLOW;
        goto world_error;
    }
    if (close_owned(&root) != 0 || close_owned(&parent) != 0) {
        goto world_error;
    }
    *subject_out = subject;
    if (error != NULL) memset(error, 0, sizeof(*error));
    return 0;

world_error:
    saved = errno;
    (void)close_owned(&root);
    (void)close_owned(&parent);
    if (subject != NULL) {
        memset(subject, 0, sizeof(*subject));
        free(subject);
    }
    return set_error(error, "owned_root_identity_mismatch", "subject_bind", saved);
}

static void subject_destroy_impl(struct proc17_qa_residue_subject *subject)
{
    if (!subject_valid(subject)) return;
    memset(subject, 0, sizeof(*subject));
    free(subject);
}

static int parse_pid_name(const char *name, pid_t *pid)
{
    uintmax_t value = 0U;
    size_t index;

    if (name == NULL || *name == '\0') return -1;
    for (index = 0U; name[index] != '\0'; index++) {
        unsigned char byte = (unsigned char)name[index];
        if (byte < '0' || byte > '9') return -1;
        if (value > ((uintmax_t)INT_MAX - (uintmax_t)(byte - '0')) / 10U) {
            return -1;
        }
        value = value * 10U + (uintmax_t)(byte - '0');
    }
    if (value == 0U || value > (uintmax_t)INT_MAX) return -1;
    *pid = (pid_t)value;
    return 0;
}

static int process_cgroup_matches(
    const struct proc17_qa_residue_session *session,
    pid_t pid,
    int *matches)
{
    char path[64];
    char *bytes = NULL;
    size_t length = 0U;
    int result = -1;

    *matches = 0;
    if (snprintf(path, sizeof(path), "/proc/%ld/cgroup", (long)pid) <= 0
        || read_bounded_file(path, CGROUP_FILE_LIMIT, &bytes, &length) != 0) {
        return -1;
    }
    *matches = length == session->cgroup_bytes
        && memcmp(bytes, session->cgroup, length) == 0;
    result = 0;
    free(bytes);
    return result;
}

static int process_executable_identity(
    pid_t pid,
    uint64_t *device,
    uint64_t *inode,
    int *readable)
{
    char path[64];
    struct stat status;

    *readable = 0;
    if (snprintf(path, sizeof(path), "/proc/%ld/exe", (long)pid) <= 0) {
        errno = EOVERFLOW;
        return -1;
    }
    if (stat(path, &status) == 0) {
        *device = (uint64_t)status.st_dev;
        *inode = (uint64_t)status.st_ino;
        *readable = 1;
        return 0;
    }
    if (errno == ENOENT || errno == ESRCH || errno == EACCES
        || errno == EPERM) {
        return 0;
    }
    return -1;
}

static int scan_processes(
    const struct proc17_qa_residue_session *session,
    struct proc17_qa_residue_snapshot *snapshot,
    struct proc17_qa_residue_error *error)
{
    DIR *stream = NULL;
    struct dirent *entry;
    size_t observed = 0U;
    int result = -1;

    stream = opendir("/proc");
    if (stream == NULL) {
        return set_error(error, "process_census_unavailable",
            "capture_processes", errno);
    }
    errno = 0;
    while ((entry = readdir(stream)) != NULL) {
        struct proc17_qa_residue_process_record record;
        uint64_t executable_device = 0U;
        uint64_t executable_inode = 0U;
        int executable_readable = 0;
        int cgroup_matches = 0;
        pid_t pid;

        if (parse_pid_name(entry->d_name, &pid) != 0) continue;
        if (++observed > MAX_PROCESS_RECORDS) {
            errno = EOVERFLOW;
            goto cleanup;
        }
        if (read_process_stat_stable(pid, &record) != 0) {
            if (errno == ENOENT || errno == ESRCH) {
                errno = 0;
                continue;
            }
            goto cleanup;
        }
        if (process_cgroup_matches(session, pid, &cgroup_matches) != 0) {
            if (errno == ENOENT || errno == ESRCH) {
                errno = 0;
                continue;
            }
            goto cleanup;
        }
        if (process_executable_identity(pid, &executable_device,
                &executable_inode, &executable_readable) != 0) {
            if (errno == ENOENT || errno == ESRCH) {
                errno = 0;
                continue;
            }
            goto cleanup;
        }
        if (record.ppid == session->campaign_pid) {
            if (record.state == 'Z') snapshot->direct_zombies++;
            else snapshot->direct_live_children++;
        }
        if (executable_readable
            && executable_device == session->supervisor_device
            && executable_inode == session->supervisor_inode) {
            snapshot->matching_supervisors++;
        } else if (!executable_readable && record.state == 'Z'
            && cgroup_matches
            && strcmp(record.comm, PROC17_QA_RESIDUE_SUPERVISOR_COMM) == 0) {
            snapshot->unresolved_supervisor_zombies++;
        } else if (!executable_readable && record.state != 'Z'
            && cgroup_matches
            && strcmp(record.comm, PROC17_QA_RESIDUE_SUPERVISOR_COMM) == 0) {
            errno = EACCES;
            goto cleanup;
        }
        errno = 0;
    }
    if (errno != 0) goto cleanup;
    result = 0;

cleanup:
    {
        int saved = errno;
        if (closedir(stream) != 0 && result == 0) result = -1;
        if (result != 0) {
            (void)set_error(error, "process_census_incomplete",
                "capture_processes", saved);
        }
        errno = saved;
    }
    return result;
}

static int scan_namespaces(
    struct proc17_qa_residue_snapshot *snapshot,
    struct proc17_qa_residue_error *error)
{
    static const char *const names[NAMESPACE_COUNT] = {
        "user", "mnt", "pid", "net", "ipc", "uts",
    };
    size_t index;

    for (index = 0U; index < NAMESPACE_COUNT; index++) {
        char path[64];
        struct stat status;

        if (snprintf(path, sizeof(path), "/proc/self/ns/%s", names[index]) <= 0
            || stat(path, &status) != 0) {
            return set_error(error, "namespace_identity_unavailable",
                "capture_namespaces", errno);
        }
        snapshot->namespaces[index].device = (uint64_t)status.st_dev;
        snapshot->namespaces[index].inode = (uint64_t)status.st_ino;
    }
    return 0;
}

static int decode_mount_field(
    const char *bytes,
    size_t length,
    char output[PATH_MAX])
{
    size_t source = 0U;
    size_t target = 0U;

    while (source < length) {
        unsigned char byte = (unsigned char)bytes[source++];
        if (byte == '\\') {
            unsigned int value;
            if (source + 3U > length
                || bytes[source] < '0' || bytes[source] > '7'
                || bytes[source + 1U] < '0' || bytes[source + 1U] > '7'
                || bytes[source + 2U] < '0' || bytes[source + 2U] > '7') {
                return -1;
            }
            value = ((unsigned int)(bytes[source] - '0') << 6U)
                | ((unsigned int)(bytes[source + 1U] - '0') << 3U)
                | (unsigned int)(bytes[source + 2U] - '0');
            if (value == 0U || value > UCHAR_MAX) return -1;
            byte = (unsigned char)value;
            source += 3U;
        }
        if (target + 1U >= PATH_MAX) return -1;
        output[target++] = (char)byte;
    }
    output[target] = '\0';
    return 0;
}

static int parse_mountinfo_bytes(
    const char *bytes,
    size_t length,
    const struct proc17_qa_residue_subject *subject,
    struct mount_counts *counts)
{
    size_t line_start = 0U;

    if (bytes == NULL || length == 0U || counts == NULL
        || bytes[length - 1U] != '\n') {
        return -1;
    }
    memset(counts, 0, sizeof(*counts));
    while (line_start < length) {
        const char *tokens[128];
        size_t token_lengths[128];
        size_t token_count = 0U;
        size_t cursor = line_start;
        size_t separator = SIZE_MAX;
        char mountpoint[PATH_MAX];
        size_t index;

        while (cursor < length && bytes[cursor] != '\n') {
            size_t start;
            while (cursor < length && bytes[cursor] == ' ') cursor++;
            if (cursor >= length || bytes[cursor] == '\n') break;
            if (token_count == sizeof(tokens) / sizeof(tokens[0])) return -1;
            start = cursor;
            while (cursor < length && bytes[cursor] != ' '
                    && bytes[cursor] != '\n') {
                cursor++;
            }
            tokens[token_count] = bytes + start;
            token_lengths[token_count] = cursor - start;
            token_count++;
        }
        if (cursor >= length || bytes[cursor] != '\n' || token_count < 10U) {
            return -1;
        }
        for (index = 6U; index < token_count; index++) {
            if (token_lengths[index] == 1U && tokens[index][0] == '-') {
                separator = index;
                break;
            }
        }
        if (separator == SIZE_MAX || separator + 3U >= token_count
            || decode_mount_field(tokens[4], token_lengths[4], mountpoint) != 0) {
            return -1;
        }
        if (strcmp(mountpoint, "/qa") == 0
            || strcmp(mountpoint, "/qa/source") == 0
            || strcmp(mountpoint, "/qa/scratch") == 0) {
            counts->qa++;
        }
        if (subject != NULL
            && (strcmp(mountpoint, subject->identity.path) == 0
                || strcmp(mountpoint, subject->source_path) == 0)) {
            counts->owned_source++;
        }
        line_start = cursor + 1U;
    }
    return 0;
}

static int scan_mounts(
    const struct proc17_qa_residue_subject *subject,
    struct proc17_qa_residue_snapshot *snapshot,
    struct proc17_qa_residue_error *error)
{
    char *bytes = NULL;
    size_t length = 0U;
    struct mount_counts counts;
    int saved;

    if (read_bounded_file("/proc/self/mountinfo", PROC_FILE_LIMIT,
            &bytes, &length) != 0
        || parse_mountinfo_bytes(bytes, length, subject, &counts) != 0) {
        saved = errno == 0 ? EPROTO : errno;
        free(bytes);
        return set_error(error, "mountinfo_unavailable",
            "capture_mounts", saved);
    }
    free(bytes);
    snapshot->qa_mounts = counts.qa;
    snapshot->owned_source_mounts = counts.owned_source;
    return 0;
}

static int compare_root_record(const void *left, const void *right)
{
    const struct root_record *a = left;
    const struct root_record *b = right;
    int name = strcmp(a->basename, b->basename);

    if (name != 0) return name;
    if (a->device != b->device) return a->device < b->device ? -1 : 1;
    if (a->inode != b->inode) return a->inode < b->inode ? -1 : 1;
    if (a->mount_id != b->mount_id) return a->mount_id < b->mount_id ? -1 : 1;
    if (a->mode != b->mode) return a->mode < b->mode ? -1 : 1;
    return 0;
}

static int append_root_record(
    struct proc17_qa_residue_snapshot *snapshot,
    const char *name,
    const struct statx *status)
{
    struct root_record *grown;
    struct root_record *record;
    size_t name_bytes = strlen(name);

    if (name_bytes == 0U || name_bytes >= sizeof(record->basename)) {
        errno = EINVAL;
        return -1;
    }
    if (snapshot->root_count >= MAX_ROOT_RECORDS) {
        errno = EOVERFLOW;
        return -1;
    }
    grown = realloc(snapshot->roots,
        (snapshot->root_count + 1U) * sizeof(*snapshot->roots));
    if (grown == NULL) return -1;
    snapshot->roots = grown;
    record = &snapshot->roots[snapshot->root_count++];
    memset(record, 0, sizeof(*record));
    memcpy(record->basename, name, name_bytes + 1U);
    record->device = (uint64_t)makedev(status->stx_dev_major,
        status->stx_dev_minor);
    record->inode = status->stx_ino;
    record->mount_id = status->stx_mnt_id;
    record->mode = status->stx_mode;
    return 0;
}

static int scan_roots(
    struct proc17_qa_residue_snapshot *snapshot,
    struct proc17_qa_residue_error *error)
{
    DIR *stream = NULL;
    struct dirent *entry;
    int descriptor = -1;
    int result = -1;

    descriptor = open(ROOT_PARENT,
        O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW);
    if (descriptor < 0) goto cleanup;
    stream = fdopendir(descriptor);
    if (stream == NULL) goto cleanup;
    descriptor = -1;
    errno = 0;
    while ((entry = readdir(stream)) != NULL) {
        struct statx status;

        if (!valid_root_basename(entry->d_name)) continue;
        memset(&status, 0, sizeof(status));
        if (statx(dirfd(stream), entry->d_name,
                AT_SYMLINK_NOFOLLOW | AT_STATX_SYNC_AS_STAT,
                STATX_TYPE | STATX_INO | STATX_MNT_ID, &status) != 0
            || (status.stx_mask & (STATX_TYPE | STATX_INO | STATX_MNT_ID))
                != (STATX_TYPE | STATX_INO | STATX_MNT_ID)
            || append_root_record(snapshot, entry->d_name, &status) != 0) {
            goto cleanup;
        }
        errno = 0;
    }
    if (errno != 0) goto cleanup;
    if (closedir(stream) != 0) {
        stream = NULL;
        goto cleanup;
    }
    stream = NULL;
    if (snapshot->root_count > 1U) {
        qsort(snapshot->roots, snapshot->root_count,
            sizeof(*snapshot->roots), compare_root_record);
    }
    result = 0;

cleanup:
    {
        int saved = errno;
        if (stream != NULL) (void)closedir(stream);
        (void)close_owned(&descriptor);
        if (result != 0) {
            (void)set_error(error, "owned_root_census_incomplete",
                "capture_roots", saved);
        }
        errno = saved;
    }
    return result;
}

static int parse_fd_name(const char *name, int *descriptor)
{
    uintmax_t value = 0U;
    size_t index;

    if (name == NULL || *name == '\0') return -1;
    for (index = 0U; name[index] != '\0'; index++) {
        unsigned char byte = (unsigned char)name[index];
        if (byte < '0' || byte > '9') return -1;
        if (value > ((uintmax_t)INT_MAX - (uintmax_t)(byte - '0')) / 10U) {
            return -1;
        }
        value = value * 10U + (uintmax_t)(byte - '0');
    }
    if (value > (uintmax_t)INT_MAX) return -1;
    *descriptor = (int)value;
    return 0;
}

static int compare_fd_record(const void *left, const void *right)
{
    const struct fd_record *a = left;
    const struct fd_record *b = right;
    return a->number < b->number ? -1 : a->number > b->number ? 1 : 0;
}

static int append_fd_record(
    struct proc17_qa_residue_snapshot *snapshot,
    int descriptor,
    int scan_descriptor)
{
    struct fd_record *grown;
    struct fd_record *record;
    struct stat status;
    char name[32];
    char target[PATH_MAX];
    ssize_t target_bytes;

    if (descriptor == scan_descriptor) return 0;
    if (snapshot->fd_count >= MAX_FD_RECORDS) {
        errno = EOVERFLOW;
        return -1;
    }
    if (fstat(descriptor, &status) != 0) return -1;
    grown = realloc(snapshot->fds,
        (snapshot->fd_count + 1U) * sizeof(*snapshot->fds));
    if (grown == NULL) return -1;
    snapshot->fds = grown;
    record = &snapshot->fds[snapshot->fd_count];
    memset(record, 0, sizeof(*record));
    record->number = descriptor;
    record->device = (uint64_t)status.st_dev;
    record->inode = (uint64_t)status.st_ino;
    record->mode = (uint32_t)status.st_mode;
    record->descriptor_flags = fcntl(descriptor, F_GETFD);
    record->status_flags = fcntl(descriptor, F_GETFL);
    if (record->descriptor_flags < 0 || record->status_flags < 0
        || snprintf(name, sizeof(name), "%d", descriptor) <= 0) {
        return -1;
    }
    target_bytes = readlinkat(scan_descriptor, name, target, sizeof(target));
    if (target_bytes < 0) return -1;
    if ((size_t)target_bytes >= sizeof(target)) {
        errno = EOVERFLOW;
        return -1;
    }
    record->link_available = 1U;
    proc17_sha256_bytes(target, (size_t)target_bytes, record->link_digest);
    snapshot->fd_count++;
    return 0;
}

static int scan_fds(
    struct proc17_qa_residue_snapshot *snapshot,
    struct proc17_qa_residue_error *error)
{
    DIR *stream = NULL;
    struct dirent *entry;
    int scan_descriptor;
    int result = -1;

    stream = opendir("/proc/self/fd");
    if (stream == NULL) {
        return set_error(error, "fd_census_unavailable", "capture_fds", errno);
    }
    scan_descriptor = dirfd(stream);
    if (scan_descriptor < 0) goto cleanup;
    errno = 0;
    while ((entry = readdir(stream)) != NULL) {
        int descriptor;

        if (parse_fd_name(entry->d_name, &descriptor) != 0) continue;
        if (append_fd_record(snapshot, descriptor, scan_descriptor) != 0) {
            goto cleanup;
        }
        errno = 0;
    }
    if (errno != 0) goto cleanup;
    if (closedir(stream) != 0) {
        stream = NULL;
        goto cleanup;
    }
    stream = NULL;
    if (snapshot->fd_count > 1U) {
        qsort(snapshot->fds, snapshot->fd_count,
            sizeof(*snapshot->fds), compare_fd_record);
    }
    result = 0;

cleanup:
    {
        int saved = errno;
        if (stream != NULL) (void)closedir(stream);
        if (result != 0) {
            (void)set_error(error, "fd_census_incomplete", "capture_fds", saved);
        }
        errno = saved;
    }
    return result;
}

static int hash_fd_set(struct proc17_qa_residue_snapshot *snapshot)
{
    struct proc17_sha256 hash;
    size_t index;

    proc17_sha256_init(&hash);
    for (index = 0U; index < snapshot->fd_count; index++) {
        const struct fd_record *record = &snapshot->fds[index];
        hash_i64(&hash, record->number);
        hash_u64(&hash, record->device);
        hash_u64(&hash, record->inode);
        hash_u64(&hash, record->mode);
        hash_i64(&hash, record->descriptor_flags);
        hash_i64(&hash, record->status_flags);
        hash_u64(&hash, record->link_available);
        proc17_sha256_update(&hash, record->link_digest,
            sizeof(record->link_digest));
    }
    return finish_tagged_id(&hash, "qa-fd-set:", snapshot->fd_set_id);
}

static int hash_namespace_set(struct proc17_qa_residue_snapshot *snapshot)
{
    struct proc17_sha256 hash;
    size_t index;

    proc17_sha256_init(&hash);
    for (index = 0U; index < NAMESPACE_COUNT; index++) {
        hash_u64(&hash, snapshot->namespaces[index].device);
        hash_u64(&hash, snapshot->namespaces[index].inode);
    }
    return finish_tagged_id(&hash, "qa-ns-set:",
        snapshot->namespace_set_id);
}

static int hash_root_set(struct proc17_qa_residue_snapshot *snapshot)
{
    struct proc17_sha256 hash;
    size_t index;

    proc17_sha256_init(&hash);
    for (index = 0U; index < snapshot->root_count; index++) {
        const struct root_record *record = &snapshot->roots[index];
        proc17_sha256_update(&hash, record->basename,
            strlen(record->basename) + 1U);
        hash_u64(&hash, record->device);
        hash_u64(&hash, record->inode);
        hash_u64(&hash, record->mount_id);
        hash_u64(&hash, record->mode);
    }
    return finish_tagged_id(&hash, "qa-owned-root-set:",
        snapshot->root_set_id);
}

static int hash_snapshot(struct proc17_qa_residue_snapshot *snapshot)
{
    struct proc17_sha256 hash;

    proc17_sha256_init(&hash);
    hash_u64(&hash, snapshot->session_cookie);
    hash_u64(&hash, (uint64_t)snapshot->scope);
    proc17_sha256_update(&hash, snapshot->fd_set_id,
        strlen(snapshot->fd_set_id) + 1U);
    proc17_sha256_update(&hash, snapshot->namespace_set_id,
        strlen(snapshot->namespace_set_id) + 1U);
    proc17_sha256_update(&hash, snapshot->root_set_id,
        strlen(snapshot->root_set_id) + 1U);
    hash_u64(&hash, snapshot->direct_live_children);
    hash_u64(&hash, snapshot->direct_zombies);
    hash_u64(&hash, snapshot->matching_supervisors);
    hash_u64(&hash, snapshot->unresolved_supervisor_zombies);
    hash_u64(&hash, snapshot->qa_mounts);
    hash_u64(&hash, snapshot->owned_source_mounts);
    hash_u64(&hash, snapshot->has_subject);
    if (snapshot->has_subject) {
        proc17_sha256_update(&hash, snapshot->subject_id,
            strlen(snapshot->subject_id) + 1U);
    }
    return finish_tagged_id(&hash, "qa-host-snapshot:",
        snapshot->snapshot_id);
}

static int root_matches_subject(
    const struct root_record *root,
    const struct proc17_qa_residue_subject *subject)
{
    return strcmp(root->basename, subject->basename) == 0
        && root->device == subject->identity.device
        && root->inode == subject->identity.inode
        && root->mount_id == subject->identity.mount_id
        && S_ISDIR(root->mode);
}

static int baseline_is_clean(const struct proc17_qa_residue_snapshot *snapshot)
{
    return snapshot->direct_live_children == 0U
        && snapshot->direct_zombies == 0U
        && snapshot->matching_supervisors == 0U
        && snapshot->unresolved_supervisor_zombies == 0U
        && snapshot->qa_mounts == 0U
        && snapshot->root_count == 0U;
}

static void fill_projection(
    const struct proc17_qa_residue_snapshot *snapshot,
    struct proc17_qa_residue_projection *projection)
{
    memset(projection, 0, sizeof(*projection));
    projection->abi_version = PROC17_QA_RESIDUE_C_ABI;
    projection->scope = snapshot->scope;
    (void)snprintf(projection->snapshot_id, sizeof(projection->snapshot_id),
        "%s", snapshot->snapshot_id);
    (void)snprintf(projection->parent_fd_set_id,
        sizeof(projection->parent_fd_set_id), "%s", snapshot->fd_set_id);
    projection->parent_fd_count = snapshot->fd_count;
    (void)snprintf(projection->parent_namespace_set_id,
        sizeof(projection->parent_namespace_set_id), "%s",
        snapshot->namespace_set_id);
    projection->direct_live_child_count = snapshot->direct_live_children;
    projection->direct_zombie_count = snapshot->direct_zombies;
    projection->matching_supervisor_process_count =
        snapshot->matching_supervisors;
    projection->unresolved_supervisor_zombie_count =
        snapshot->unresolved_supervisor_zombies;
    projection->qa_host_mount_count = snapshot->qa_mounts;
    if (snapshot->has_subject) {
        (void)snprintf(projection->owned_source_identity_id,
            sizeof(projection->owned_source_identity_id), "%s",
            snapshot->subject_id);
        projection->has_owned_source = 1U;
    }
    projection->owned_source_host_mount_count =
        snapshot->owned_source_mounts;
    (void)snprintf(projection->owned_root_set_id,
        sizeof(projection->owned_root_set_id), "%s", snapshot->root_set_id);
    projection->owned_root_count = snapshot->root_count;
    projection->event_truth_runtime_confirmed = 1U;
}

static void snapshot_destroy_impl(struct proc17_qa_residue_snapshot *snapshot)
{
    if (!snapshot_valid(snapshot)) return;
    snapshot->magic = 0U;
    free(snapshot->fds);
    free(snapshot->roots);
    snapshot->fds = NULL;
    snapshot->roots = NULL;
    memset(snapshot, 0, sizeof(*snapshot));
    free(snapshot);
}

static int capture_impl(
    struct proc17_qa_residue_session *session,
    enum proc17_qa_residue_scope scope,
    const struct proc17_qa_residue_subject *subject,
    struct proc17_qa_residue_snapshot **snapshot_out,
    struct proc17_qa_residue_projection *projection,
    struct proc17_qa_residue_error *error)
{
    struct proc17_qa_residue_snapshot *snapshot = NULL;
    size_t subject_matches = 0U;
    size_t subject_name_matches = 0U;
    size_t index;

    if (!session_valid(session) || snapshot_out == NULL || projection == NULL
        || scope < PROC17_QA_RESIDUE_BASELINE
        || scope > PROC17_QA_RESIDUE_FINAL) {
        return set_error(error, "invalid_request", "capture", EINVAL);
    }
    *snapshot_out = NULL;
    if ((scope == PROC17_QA_RESIDUE_BASELINE
            || scope == PROC17_QA_RESIDUE_FINAL) && subject != NULL) {
        return set_error(error, "subject_forbidden", "capture_scope", EINVAL);
    }
    if ((scope == PROC17_QA_RESIDUE_ITERATION
            || scope == PROC17_QA_RESIDUE_POST_CLEANUP)
        && (!subject_valid(subject)
            || subject->session_cookie != session->cookie)) {
        return set_error(error, "verified_subject_required",
            "capture_scope", EINVAL);
    }
    snapshot = calloc(1U, sizeof(*snapshot));
    if (snapshot == NULL) {
        return set_error(error, "observer_allocation_failed", "capture", errno);
    }
    snapshot->magic = SNAPSHOT_MAGIC;
    snapshot->session_cookie = session->cookie;
    snapshot->scope = scope;
    if (subject != NULL) {
        snapshot->has_subject = 1U;
        snapshot->subject_identity = subject->identity;
        (void)snprintf(snapshot->subject_id, sizeof(snapshot->subject_id),
            "%s", subject->subject_id);
    }
    if (scan_processes(session, snapshot, error) != 0
        || scan_namespaces(snapshot, error) != 0
        || scan_mounts(subject, snapshot, error) != 0
        || scan_roots(snapshot, error) != 0) {
        snapshot_destroy_impl(snapshot);
        return -1;
    }
    if (scope == PROC17_QA_RESIDUE_ITERATION
        || scope == PROC17_QA_RESIDUE_POST_CLEANUP) {
        for (index = 0U; index < snapshot->root_count; index++) {
            if (strcmp(snapshot->roots[index].basename,
                    subject->basename) == 0) {
                subject_name_matches++;
            }
            if (root_matches_subject(&snapshot->roots[index], subject)) {
                subject_matches++;
            }
        }
    }
    if (scope == PROC17_QA_RESIDUE_ITERATION) {
        if (subject_matches != 1U) {
            snapshot_destroy_impl(snapshot);
            return set_error(error, "owned_root_subject_not_current",
                "capture_roots", ESTALE);
        }
    }
    if (scope == PROC17_QA_RESIDUE_POST_CLEANUP
        && subject_name_matches != 0U) {
        snapshot_destroy_impl(snapshot);
        return set_error(error, "owned_root_subject_still_present",
            "capture_roots", EEXIST);
    }
    if (scan_fds(snapshot, error) != 0
        || hash_fd_set(snapshot) != 0
        || hash_namespace_set(snapshot) != 0
        || hash_root_set(snapshot) != 0
        || hash_snapshot(snapshot) != 0) {
        int saved = errno == 0 ? EPROTO : errno;
        snapshot_destroy_impl(snapshot);
        return set_error(error, "snapshot_normalization_failed",
            "capture_finalize", saved);
    }
    if (scope == PROC17_QA_RESIDUE_BASELINE && !baseline_is_clean(snapshot)) {
        snapshot_destroy_impl(snapshot);
        return set_error(error, "dirty_precondition", "capture_baseline", EBUSY);
    }
    fill_projection(snapshot, projection);
    *snapshot_out = snapshot;
    if (error != NULL) memset(error, 0, sizeof(*error));
    return 0;
}

static int fd_identity_equal(
    const struct fd_record *left,
    const struct fd_record *right)
{
    return left->device == right->device
        && left->inode == right->inode
        && left->mode == right->mode
        && left->link_available == right->link_available
        && memcmp(left->link_digest, right->link_digest,
            sizeof(left->link_digest)) == 0;
}

static int fd_flags_equal(
    const struct fd_record *left,
    const struct fd_record *right)
{
    return left->descriptor_flags == right->descriptor_flags
        && left->status_flags == right->status_flags;
}

static int root_record_equal(
    const struct root_record *left,
    const struct root_record *right)
{
    return compare_root_record(left, right) == 0;
}

static int observed_root_is_admitted(
    const struct proc17_qa_residue_snapshot *observed,
    const struct root_record *record)
{
    return observed->scope == PROC17_QA_RESIDUE_ITERATION
        && observed->has_subject
        && strcmp(record->basename,
            observed->subject_identity.path + sizeof(ROOT_PARENT)) == 0
        && record->device == observed->subject_identity.device
        && record->inode == observed->subject_identity.inode
        && record->mount_id == observed->subject_identity.mount_id
        && S_ISDIR(record->mode);
}

static void compare_fds(
    const struct proc17_qa_residue_snapshot *baseline,
    const struct proc17_qa_residue_snapshot *observed,
    struct proc17_qa_residue_delta *delta)
{
    size_t left = 0U;
    size_t right = 0U;

    while (left < baseline->fd_count || right < observed->fd_count) {
        if (left == baseline->fd_count) {
            delta->fd_opened++;
            right++;
        } else if (right == observed->fd_count) {
            delta->fd_missing++;
            left++;
        } else if (baseline->fds[left].number < observed->fds[right].number) {
            delta->fd_missing++;
            left++;
        } else if (baseline->fds[left].number > observed->fds[right].number) {
            delta->fd_opened++;
            right++;
        } else {
            if (!fd_identity_equal(&baseline->fds[left],
                    &observed->fds[right])) {
                delta->fd_identity_changed++;
            }
            if (!fd_flags_equal(&baseline->fds[left],
                    &observed->fds[right])) {
                delta->fd_flags_changed++;
            }
            left++;
            right++;
        }
    }
}

static void compare_roots(
    const struct proc17_qa_residue_snapshot *baseline,
    const struct proc17_qa_residue_snapshot *observed,
    struct proc17_qa_residue_delta *delta)
{
    size_t left;
    size_t right;

    for (right = 0U; right < observed->root_count; right++) {
        int found = 0;
        for (left = 0U; left < baseline->root_count; left++) {
            if (root_record_equal(&baseline->roots[left],
                    &observed->roots[right])) {
                found = 1;
                break;
            }
        }
        if (!found && !observed_root_is_admitted(observed,
                &observed->roots[right])) {
            delta->owned_roots_added++;
        }
    }
    for (left = 0U; left < baseline->root_count; left++) {
        int found = 0;
        for (right = 0U; right < observed->root_count; right++) {
            if (root_record_equal(&baseline->roots[left],
                    &observed->roots[right])) {
                found = 1;
                break;
            }
        }
        if (!found) delta->owned_roots_missing++;
    }
}

static int compare_impl(
    const struct proc17_qa_residue_snapshot *baseline,
    const struct proc17_qa_residue_snapshot *observed,
    struct proc17_qa_residue_delta *delta,
    struct proc17_qa_residue_error *error)
{
    size_t index;

    if (!snapshot_valid(baseline) || !snapshot_valid(observed) || delta == NULL) {
        return set_error(error, "invalid_snapshot", "compare", EINVAL);
    }
    if (baseline->session_cookie != observed->session_cookie) {
        return set_error(error, "snapshot_session_mismatch", "compare", EXDEV);
    }
    if (baseline->scope != PROC17_QA_RESIDUE_BASELINE
        || observed->scope == PROC17_QA_RESIDUE_BASELINE) {
        return set_error(error, "snapshot_direction_invalid", "compare", EINVAL);
    }
    memset(delta, 0, sizeof(*delta));
    delta->abi_version = PROC17_QA_RESIDUE_C_ABI;
    (void)snprintf(delta->baseline_snapshot_id,
        sizeof(delta->baseline_snapshot_id), "%s", baseline->snapshot_id);
    (void)snprintf(delta->observed_snapshot_id,
        sizeof(delta->observed_snapshot_id), "%s", observed->snapshot_id);
    compare_fds(baseline, observed, delta);
    for (index = 0U; index < NAMESPACE_COUNT; index++) {
        if (baseline->namespaces[index].device
                != observed->namespaces[index].device
            || baseline->namespaces[index].inode
                != observed->namespaces[index].inode) {
            delta->parent_namespace_changed = 1U;
            break;
        }
    }
    delta->direct_live_children = observed->direct_live_children;
    delta->direct_zombies = observed->direct_zombies;
    delta->matching_supervisor_processes = observed->matching_supervisors;
    delta->unresolved_supervisor_zombies =
        observed->unresolved_supervisor_zombies;
    delta->qa_host_mounts = observed->qa_mounts;
    delta->owned_source_host_mounts = observed->owned_source_mounts;
    compare_roots(baseline, observed, delta);
    delta->exact = delta->fd_opened == 0U && delta->fd_missing == 0U
        && delta->fd_identity_changed == 0U && delta->fd_flags_changed == 0U
        && delta->parent_namespace_changed == 0U
        && delta->direct_live_children == 0U && delta->direct_zombies == 0U
        && delta->matching_supervisor_processes == 0U
        && delta->unresolved_supervisor_zombies == 0U
        && delta->qa_host_mounts == 0U
        && delta->owned_source_host_mounts == 0U
        && delta->owned_roots_added == 0U
        && delta->owned_roots_missing == 0U;
    delta->event_truth_runtime_confirmed = 1U;
    if (error != NULL) memset(error, 0, sizeof(*error));
    return 0;
}

static int test_parse_proc_stat_impl(
    const char *bytes,
    size_t length,
    struct proc17_qa_residue_process_record *record,
    struct proc17_qa_residue_error *error)
{
    if (parse_proc_stat_bytes(bytes, length, record) != 0) {
        return set_error(error, "proc_stat_malformed", "parse_proc_stat", EPROTO);
    }
    if (error != NULL) memset(error, 0, sizeof(*error));
    return 0;
}

static int test_parse_mountinfo_impl(
    const char *bytes,
    size_t length,
    uint64_t *qa_mount_count,
    struct proc17_qa_residue_error *error)
{
    struct mount_counts counts;

    if (qa_mount_count == NULL
        || parse_mountinfo_bytes(bytes, length, NULL, &counts) != 0) {
        return set_error(error, "mountinfo_malformed", "parse_mountinfo", EPROTO);
    }
    *qa_mount_count = counts.qa;
    if (error != NULL) memset(error, 0, sizeof(*error));
    return 0;
}

static int test_capture_with_retained_scan_fd_impl(
    struct proc17_qa_residue_session *session,
    const struct proc17_qa_residue_snapshot *baseline,
    struct proc17_qa_residue_delta *delta,
    struct proc17_qa_residue_error *error)
{
    struct proc17_qa_residue_snapshot *observed = NULL;
    struct proc17_qa_residue_projection projection;
    int retained = -1;
    int result = -1;

    if (!session_valid(session) || !snapshot_valid(baseline) || delta == NULL) {
        return set_error(error, "invalid_request", "retained_fd_capture", EINVAL);
    }
    retained = open("/proc/self/mountinfo", O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (retained < 0) {
        return set_error(error, "retained_fd_unavailable",
            "retained_fd_capture", errno);
    }
    if (capture_impl(session, PROC17_QA_RESIDUE_FINAL, NULL,
            &observed, &projection, error) != 0) {
        goto cleanup;
    }
    if (close_owned(&retained) != 0) {
        (void)set_error(error, "retained_fd_close_failed",
            "retained_fd_capture", errno);
        goto cleanup;
    }
    if (compare_impl(baseline, observed, delta, error) != 0) goto cleanup;
    result = 0;

cleanup:
    (void)close_owned(&retained);
    snapshot_destroy_impl(observed);
    return result;
}

int proc17_qa_residue_observer_get_api(
    uint32_t requested_abi,
    struct proc17_qa_residue_api *api)
{
    if (requested_abi != PROC17_QA_RESIDUE_C_ABI || api == NULL) return -1;
    memset(api, 0, sizeof(*api));
    api->abi_version = PROC17_QA_RESIDUE_C_ABI;
    api->protocol_version = PROC17_QA_RESIDUE_PROTOCOL;
    api->session_open = session_open_impl;
    api->session_destroy = session_destroy_impl;
    api->subject_bind = subject_bind_impl;
    api->subject_destroy = subject_destroy_impl;
    api->capture = capture_impl;
    api->compare = compare_impl;
    api->snapshot_destroy = snapshot_destroy_impl;
    api->test_parse_proc_stat = test_parse_proc_stat_impl;
    api->test_parse_mountinfo = test_parse_mountinfo_impl;
    api->test_capture_with_retained_scan_fd =
        test_capture_with_retained_scan_fd_impl;
    return 0;
}
