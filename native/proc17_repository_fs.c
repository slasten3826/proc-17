#define _GNU_SOURCE

#include <lua.h>
#include <lauxlib.h>

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <linux/fs.h>
#include <linux/openat2.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#ifdef PROC17_REPOSITORY_FS_TESTING
#include "proc17_repository_fs_test.h"
#endif

#define PROC17_NATIVE_PROTOCOL "repository.native_provider.v0"
#define PROC17_NATIVE_ABI "proc17.repository.fs.lua54.v0"
#define PROC17_PROVIDER_ID "linux.openat2.renameat2.v0"
#define PROC17_CONTRACT_ID "repository.provider.create_readback.v0"
#define PROC17_HANDLE_METATABLE "proc17.repository.handle.internal.v0"
#define PROC17_HANDLE_TAG "repository.handle.v0"

#define PROC17_MAX_PROJECT_BASE_BYTES 4096U
#define PROC17_MAX_RELATIVE_PATH_BYTES 1024U
#define PROC17_MAX_COMPONENT_BYTES 255U
#define PROC17_MAX_COMPONENTS 64U
#define PROC17_MAX_CONTENT_BYTES 1048576U
#define PROC17_MAX_READ_BYTES (PROC17_MAX_CONTENT_BYTES + 1U)
#define PROC17_MAX_INVENTORY_ENTRIES 4096U
#define PROC17_MAX_INVENTORY_TOTAL_BYTES 67108864U
#define PROC17_FILE_MODE 0600
#define PROC17_TEMP_PREFIX ".proc17-tmp-"
#define PROC17_RANDOM_BYTES 16U
#define PROC17_MAX_WRITE_EINTR_RETRIES 64U
#define PROC17_MAX_READ_EINTR_RETRIES 64U
#define PROC17_TEMP_HEX_BYTES (PROC17_RANDOM_BYTES * 2U)
#define PROC17_TEMP_NAME_BYTES \
    ((sizeof(PROC17_TEMP_PREFIX) - 1U) + PROC17_TEMP_HEX_BYTES)

struct proc17_identity {
    dev_t device;
    ino_t inode;
    uint64_t mount_id;
};

struct proc17_repository_handle {
    int project_base_fd;
    int repository_fd;
    int closed;
    size_t project_base_length;
    size_t repository_path_length;
    struct proc17_identity project_base_identity;
    struct proc17_identity repository_identity;
    char paths[];
};

struct proc17_create_result {
    int succeeded;
    const char *class_name;
    const char *code;
    const char *stage;
    int error_number;
    int mutation_primitive_entered;
    int published;
    int has_temp_residue;
    size_t bytes;
    lua_Integer time_ms;
    struct proc17_identity root_identity;
    char temp_name[PROC17_TEMP_NAME_BYTES + 1U];
};

enum proc17_read_target_kind {
    PROC17_READ_TARGET_MISSING = 0,
    PROC17_READ_TARGET_REGULAR,
    PROC17_READ_TARGET_OTHER,
};

struct proc17_read_result {
    int succeeded;
    const char *class_name;
    const char *code;
    const char *stage;
    int error_number;
    enum proc17_read_target_kind target_kind;
    char *content;
    size_t bytes;
    lua_Integer time_ms;
    struct proc17_identity root_identity;
};

enum proc17_inventory_kind {
    PROC17_INVENTORY_DIRECTORY = 0,
    PROC17_INVENTORY_REGULAR,
    PROC17_INVENTORY_SYMLINK,
    PROC17_INVENTORY_SPECIAL,
};

struct proc17_inventory_bounds {
    size_t max_entries;
    size_t max_depth;
    size_t max_path_bytes;
    size_t max_component_bytes;
    size_t max_file_bytes;
    size_t max_total_bytes;
};

struct proc17_inventory_entry {
    char *relative_path;
    enum proc17_inventory_kind kind;
    struct stat identity_before;
    struct stat identity_after;
    char *content;
    size_t bytes;
};

struct proc17_inventory_snapshot {
    struct proc17_inventory_entry *entries;
    size_t count;
    size_t capacity;
    size_t total_bytes;
    int bound_exceeded;
    int unstable;
};

static const char *handle_project_base(
    const struct proc17_repository_handle *handle);
static const char *handle_repository_path(
    const struct proc17_repository_handle *handle);

#ifdef PROC17_REPOSITORY_FS_TESTING
struct proc17_test_control {
    const struct proc17_fs_test_case *test_case;
    unsigned int temp_open_attempts;
    unsigned int write_attempts;
    unsigned int read_attempts;
    int injected_eintr;
    int injected_short_write;
    int partial_final_observed;
    int parent_fd;
    int initial_target_absent;
    char final_name[PROC17_MAX_COMPONENT_BYTES + 1U];
};

static struct proc17_test_control *active_test_control;
static int write_all_raw(int descriptor, const char *content, size_t length);
#endif

static void set_string(lua_State *L, const char *key, const char *value)
{
    lua_pushstring(L, value);
    lua_setfield(L, -2, key);
}

static void set_integer(lua_State *L, const char *key, lua_Integer value)
{
    lua_pushinteger(L, value);
    lua_setfield(L, -2, key);
}

static void set_boolean(lua_State *L, const char *key, int value)
{
    lua_pushboolean(L, value);
    lua_setfield(L, -2, key);
}

static void push_cost(
    lua_State *L,
    int tool_calls,
    int file_writes,
    lua_Integer time_ms)
{
    lua_createtable(L, 0, 3);
    set_integer(L, "tool_calls", tool_calls);
    set_integer(L, "file_writes", file_writes);
    set_integer(L, "time_ms", time_ms);
}

static int push_error_full(
    lua_State *L,
    const char *class_name,
    const char *code,
    const char *stage,
    int error_number,
    int mutation_primitive_entered,
    int published,
    int tool_calls,
    int file_writes,
    lua_Integer time_ms,
    const char *temp_residue)
{
    lua_pushnil(L);
    lua_createtable(L, 0, temp_residue == NULL ? 9 : 10);
    set_string(L, "protocol_version", "repository.provider_error.v0");
    set_string(L, "class", class_name);
    set_string(L, "code", code);
    set_string(L, "stage", stage);
    if (error_number > 0) {
        set_integer(L, "errno", error_number);
    }
    set_boolean(L, "mutation_primitive_entered", mutation_primitive_entered);
    set_boolean(L, "published", published);
    push_cost(L, tool_calls, file_writes, time_ms);
    lua_setfield(L, -2, "cost");
    if (temp_residue != NULL) {
        lua_createtable(L, 0, 3);
        set_string(L, "protocol_version", "repository.provider_residue.v0");
        set_string(L, "kind", "reserved_temp");
        set_string(L, "relative_name", temp_residue);
        lua_setfield(L, -2, "residue");
    }
    return 2;
}

static int push_error(
    lua_State *L,
    const char *class_name,
    const char *code,
    const char *stage,
    int error_number,
    int tool_calls)
{
    return push_error_full(L, class_name, code, stage, error_number,
        0, 0, tool_calls, 0, 0, NULL);
}

static int ascii_alnum(unsigned char byte)
{
    return (byte >= 'a' && byte <= 'z')
        || (byte >= 'A' && byte <= 'Z')
        || (byte >= '0' && byte <= '9');
}

static int forbidden_repository_component(const char *value, size_t length)
{
    static const char *const forbidden[] = {
        ".git", ".agents", ".codex", "packets", "graves", "compost", "trace",
    };
    size_t index;

    for (index = 0; index < sizeof(forbidden) / sizeof(forbidden[0]); index++) {
        size_t forbidden_length = strlen(forbidden[index]);
        if (length == forbidden_length
            && memcmp(value, forbidden[index], length) == 0) {
            return 1;
        }
    }
    return 0;
}

static int valid_project_base(const char *path, size_t length)
{
    size_t component_start;
    size_t index;

    if (length < 2 || length > PROC17_MAX_PROJECT_BASE_BYTES
        || path[0] != '/' || path[length - 1] == '/'
        || memchr(path, '\0', length) != NULL) {
        return 0;
    }
    component_start = 1;
    for (index = 1; index <= length; index++) {
        unsigned char byte = index < length ? (unsigned char)path[index] : '/';
        if (index < length && (byte == 0 || byte < 32)) {
            return 0;
        }
        if (byte == '/') {
            size_t component_length = index - component_start;
            if (component_length == 0
                || (component_length == 1 && path[component_start] == '.')
                || (component_length == 2 && path[component_start] == '.'
                    && path[component_start + 1] == '.')) {
                return 0;
            }
            component_start = index + 1;
        }
    }
    return 1;
}

static int valid_repository_path(const char *path, size_t length)
{
    size_t component_start = 0;
    size_t components = 0;
    size_t index;

    if (length == 0 || length > PROC17_MAX_RELATIVE_PATH_BYTES
        || path[0] == '/' || path[length - 1] == '/'
        || memchr(path, '\0', length) != NULL) {
        return 0;
    }
    for (index = 0; index <= length; index++) {
        unsigned char byte = index < length ? (unsigned char)path[index] : '/';
        if (byte == '/') {
            size_t component_length = index - component_start;
            size_t component_index;

            components++;
            if (component_length == 0
                || component_length > PROC17_MAX_COMPONENT_BYTES
                || components > PROC17_MAX_COMPONENTS
                || !ascii_alnum((unsigned char)path[component_start])
                || forbidden_repository_component(
                    path + component_start, component_length)) {
                return 0;
            }
            for (component_index = 1;
                    component_index < component_length; component_index++) {
                unsigned char component_byte =
                    (unsigned char)path[component_start + component_index];
                if (!ascii_alnum(component_byte)
                    && component_byte != '.'
                    && component_byte != '_'
                    && component_byte != '-') {
                    return 0;
                }
            }
            component_start = index + 1;
        } else if (byte == 0 || byte < 32) {
            return 0;
        }
    }
    return 1;
}

static int valid_utf8_text(const unsigned char *value, size_t length)
{
    size_t index = 0;

    while (index < length) {
        unsigned char first = value[index];

        if (first == 0) {
            return 0;
        }
        if (first <= 0x7f) {
            index++;
            continue;
        }
        if (first >= 0xc2 && first <= 0xdf) {
            if (index + 1 >= length
                || value[index + 1] < 0x80 || value[index + 1] > 0xbf) {
                return 0;
            }
            index += 2;
            continue;
        }
        if (first >= 0xe0 && first <= 0xef) {
            unsigned char second;
            unsigned char third;

            if (index + 2 >= length) {
                return 0;
            }
            second = value[index + 1];
            third = value[index + 2];
            if (third < 0x80 || third > 0xbf
                || (first == 0xe0 && (second < 0xa0 || second > 0xbf))
                || (first == 0xed && (second < 0x80 || second > 0x9f))
                || ((first != 0xe0 && first != 0xed)
                    && (second < 0x80 || second > 0xbf))) {
                return 0;
            }
            index += 3;
            continue;
        }
        if (first >= 0xf0 && first <= 0xf4) {
            unsigned char second;
            unsigned char third;
            unsigned char fourth;

            if (index + 3 >= length) {
                return 0;
            }
            second = value[index + 1];
            third = value[index + 2];
            fourth = value[index + 3];
            if (third < 0x80 || third > 0xbf
                || fourth < 0x80 || fourth > 0xbf
                || (first == 0xf0 && (second < 0x90 || second > 0xbf))
                || (first == 0xf4 && (second < 0x80 || second > 0x8f))
                || ((first != 0xf0 && first != 0xf4)
                    && (second < 0x80 || second > 0xbf))) {
                return 0;
            }
            index += 4;
            continue;
        }
        return 0;
    }
    return 1;
}

static int split_target_path(
    const char *path,
    size_t length,
    char *parent,
    size_t parent_size,
    char *basename,
    size_t basename_size)
{
    size_t slash = length;
    size_t parent_length;
    size_t basename_start;
    size_t basename_length;

    while (slash > 0 && path[slash - 1] != '/') {
        slash--;
    }
    if (slash == 0) {
        parent_length = 1;
        basename_start = 0;
        if (parent_size < 2) {
            return -1;
        }
        parent[0] = '.';
        parent[1] = '\0';
    } else {
        parent_length = slash - 1;
        basename_start = slash;
        if (parent_length + 1 > parent_size) {
            return -1;
        }
        memcpy(parent, path, parent_length);
        parent[parent_length] = '\0';
    }
    basename_length = length - basename_start;
    if (basename_length == 0 || basename_length + 1 > basename_size) {
        return -1;
    }
    memcpy(basename, path + basename_start, basename_length);
    basename[basename_length] = '\0';
    return 0;
}

static int openat2_with_flags(
    int directory_fd,
    const char *path,
    uint64_t open_flags,
    uint64_t resolve_flags)
{
#ifdef SYS_openat2
    struct open_how how;

    memset(&how, 0, sizeof(how));
    how.flags = open_flags;
    how.resolve = resolve_flags;
    return (int)syscall(SYS_openat2, directory_fd, path, &how, sizeof(how));
#else
    (void)directory_fd;
    (void)path;
    (void)resolve_flags;
    errno = ENOSYS;
    return -1;
#endif
}

static int openat2_exact(
    int directory_fd,
    const char *path,
    uint64_t resolve_flags)
{
    return openat2_with_flags(directory_fd, path,
        O_PATH | O_DIRECTORY | O_CLOEXEC, resolve_flags);
}

static int observe_identity(int descriptor, struct proc17_identity *identity)
{
    struct stat status;
    struct statx extended;

    if (fstat(descriptor, &status) != 0) {
        return -1;
    }
    if (!S_ISDIR(status.st_mode)) {
        errno = ENOTDIR;
        return -1;
    }
    memset(&extended, 0, sizeof(extended));
    if (statx(descriptor, "", AT_EMPTY_PATH | AT_STATX_SYNC_AS_STAT,
            STATX_TYPE | STATX_MNT_ID, &extended) != 0) {
        return -1;
    }
    if ((extended.stx_mask & STATX_MNT_ID) == 0) {
        errno = ENOTSUP;
        return -1;
    }
    identity->device = status.st_dev;
    identity->inode = status.st_ino;
    identity->mount_id = extended.stx_mnt_id;
    return 0;
}

static void close_once(int *descriptor)
{
    int value = *descriptor;

    *descriptor = -1;
    if (value >= 0) {
        (void)close(value);
    }
}

static int close_pair(int *project_base_fd, int *repository_fd)
{
    int first_error = 0;
    int value;

    value = *repository_fd;
    *repository_fd = -1;
    if (value >= 0 && close(value) != 0) {
        first_error = errno;
    }
    value = *project_base_fd;
    *project_base_fd = -1;
    if (value >= 0 && close(value) != 0 && first_error == 0) {
        first_error = errno;
    }
    return first_error;
}

static int open_identity_pair(
    const char *project_base,
    const char *repository_path,
    int *project_base_fd,
    int *repository_fd,
    struct proc17_identity *project_base_identity,
    struct proc17_identity *repository_identity,
    const char **stage)
{
    *project_base_fd = -1;
    *repository_fd = -1;
    *stage = "open_project_base";
    *project_base_fd = openat2_exact(AT_FDCWD, project_base,
        RESOLVE_NO_SYMLINKS | RESOLVE_NO_MAGICLINKS);
    if (*project_base_fd < 0) {
        return -1;
    }
    *stage = "observe_project_base";
    if (observe_identity(*project_base_fd, project_base_identity) != 0) {
        int saved = errno;
        close_once(project_base_fd);
        errno = saved;
        return -1;
    }

    *stage = "open_repository_root";
    *repository_fd = openat2_exact(*project_base_fd, repository_path,
        RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS
            | RESOLVE_NO_MAGICLINKS | RESOLVE_NO_XDEV);
    if (*repository_fd < 0) {
        int saved = errno;
        close_once(project_base_fd);
        errno = saved;
        return -1;
    }
    *stage = "observe_repository_root";
    if (observe_identity(*repository_fd, repository_identity) != 0) {
        int saved = errno;
        close_once(repository_fd);
        close_once(project_base_fd);
        errno = saved;
        return -1;
    }
    if (repository_identity->mount_id != project_base_identity->mount_id) {
        close_once(repository_fd);
        close_once(project_base_fd);
        errno = EXDEV;
        return -1;
    }
    return 0;
}

static const char *open_error_code(int error_number)
{
    switch (error_number) {
    case ELOOP:
        return "path_symlink";
    case EXDEV:
        return "path_containment_denied";
    case ENOENT:
        return "root_missing";
    case ENOTDIR:
        return "root_invalid";
    case EACCES:
    case EPERM:
        return "permission_denied";
    case ENOSYS:
    case EINVAL:
    case ENOTSUP:
        return "provider_unavailable";
    default:
        return "io_failure";
    }
}

static int identity_equal(
    const struct proc17_identity *left,
    const struct proc17_identity *right)
{
    return left->device == right->device
        && left->inode == right->inode
        && left->mount_id == right->mount_id;
}

static uint64_t monotonic_milliseconds(void)
{
    struct timespec value;

    if (clock_gettime(CLOCK_MONOTONIC, &value) != 0) {
        return 0;
    }
    return (uint64_t)value.tv_sec * 1000U
        + (uint64_t)value.tv_nsec / 1000000U;
}

static lua_Integer elapsed_milliseconds(uint64_t started)
{
    uint64_t finished = monotonic_milliseconds();
    uint64_t elapsed = finished >= started ? finished - started : 0;

    if (elapsed > (uint64_t)LUA_MAXINTEGER) {
        return LUA_MAXINTEGER;
    }
    return (lua_Integer)elapsed;
}

static ssize_t random_bytes_once(void *buffer, size_t length)
{
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL
        && active_test_control->test_case->fault_stage == PROC17_FAULT_GETRANDOM) {
        errno = EIO;
        return -1;
    }
#endif
#ifdef SYS_getrandom
    return syscall(SYS_getrandom, buffer, length, 0);
#else
    (void)buffer;
    (void)length;
    errno = ENOSYS;
    return -1;
#endif
}

static int open_private_temp(int parent_fd, const char *name, mode_t mode)
{
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL) {
        const struct proc17_fs_test_case *test_case =
            active_test_control->test_case;

        active_test_control->temp_open_attempts++;
        if (test_case->fault_stage == PROC17_FAULT_OPEN_TEMP) {
            errno = EIO;
            return -1;
        }
        if (test_case->inject_temp_collision) {
            int collision_fd = openat(parent_fd, name,
                O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, mode);
            if (collision_fd < 0) {
                return -1;
            }
            if (close(collision_fd) != 0) {
                return -1;
            }
        }
    }
#endif
    return openat(parent_fd, name,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, mode);
}

static ssize_t write_private_bytes(int descriptor, const void *buffer, size_t length)
{
    ssize_t written;

#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL) {
        const struct proc17_fs_test_case *test_case =
            active_test_control->test_case;

        active_test_control->write_attempts++;
        if (test_case->fault_stage == PROC17_FAULT_WRITE_ZERO) {
            return 0;
        }
        if (test_case->fault_stage == PROC17_FAULT_WRITE_ERROR) {
            errno = EIO;
            return -1;
        }
        if (test_case->fault_stage == PROC17_FAULT_WRITE_EINTR_FOREVER) {
            errno = EINTR;
            return -1;
        }
        if (test_case->inject_eintr && !active_test_control->injected_eintr) {
            active_test_control->injected_eintr = 1;
            errno = EINTR;
            return -1;
        }
        if (test_case->inject_short_write
            && !active_test_control->injected_short_write && length > 1) {
            active_test_control->injected_short_write = 1;
            length /= 2;
        }
    }
#endif
    written = write(descriptor, buffer, length);
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (written > 0 && active_test_control != NULL
        && active_test_control->initial_target_absent
        && active_test_control->parent_fd >= 0) {
        struct stat status;
        if (fstatat(active_test_control->parent_fd,
                active_test_control->final_name, &status,
                AT_SYMLINK_NOFOLLOW) == 0) {
            active_test_control->partial_final_observed = 1;
        }
    }
#endif
    return written;
}

static int sync_private_file(int descriptor)
{
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL
        && active_test_control->test_case->fault_stage == PROC17_FAULT_FSYNC_TEMP) {
        errno = EIO;
        return -1;
    }
#endif
    return fsync(descriptor);
}

static int close_private_file(int *descriptor)
{
    int value = *descriptor;
    int result;

    *descriptor = -1;
    result = close(value);
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (result == 0 && active_test_control != NULL
        && active_test_control->test_case->fault_stage == PROC17_FAULT_CLOSE_TEMP) {
        errno = EIO;
        return -1;
    }
#endif
    return result;
}

static int before_publish(void)
{
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL
        && (active_test_control->test_case->fault_stage
                == PROC17_FAULT_BEFORE_RENAME
            || active_test_control->test_case->fault_stage
                == PROC17_FAULT_CLEANUP_UNLINK)) {
        errno = EIO;
        return -1;
    }
#endif
    return 0;
}

static int publish_no_replace(
    int parent_fd,
    const char *temporary_name,
    const char *final_name)
{
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL
        && active_test_control->test_case->fault_stage == PROC17_FAULT_RENAME) {
        errno = EIO;
        return -1;
    }
    if (active_test_control != NULL
        && active_test_control->test_case->inject_final_race) {
        static const char race_content[] = "racer\n";
        int race_fd = openat(parent_fd, final_name,
            O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
        size_t offset = 0;

        if (race_fd < 0) {
            return -1;
        }
        while (offset < sizeof(race_content) - 1U) {
            ssize_t written = write(race_fd, race_content + offset,
                sizeof(race_content) - 1U - offset);
            if (written < 0 && errno == EINTR) {
                continue;
            }
            if (written <= 0) {
                break;
            }
            offset += (size_t)written;
        }
        if (close(race_fd) != 0
            || offset != sizeof(race_content) - 1U) {
            errno = EIO;
            return -1;
        }
    }
#endif
#ifdef SYS_renameat2
    return (int)syscall(SYS_renameat2, parent_fd, temporary_name,
        parent_fd, final_name, RENAME_NOREPLACE);
#else
    (void)parent_fd;
    (void)temporary_name;
    (void)final_name;
    errno = ENOSYS;
    return -1;
#endif
}

static int after_publish(void)
{
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL
        && active_test_control->test_case->fault_stage == PROC17_FAULT_AFTER_RENAME) {
        errno = EIO;
        return -1;
    }
#endif
    return 0;
}

static int sync_parent_directory(int descriptor)
{
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL
        && active_test_control->test_case->fault_stage == PROC17_FAULT_FSYNC_PARENT) {
        errno = EIO;
        return -1;
    }
#endif
    return fsync(descriptor);
}

static int remove_private_temp(int parent_fd, const char *name)
{
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL
        && active_test_control->test_case->fault_stage
            == PROC17_FAULT_CLEANUP_UNLINK) {
        errno = EIO;
        return -1;
    }
#endif
    return unlinkat(parent_fd, name, 0);
}

static const char *parent_error_code(int error_number)
{
    switch (error_number) {
    case ENOENT:
        return "parent_missing";
    case ENOTDIR:
        return "parent_not_directory";
    case ELOOP:
        return "path_symlink";
    case EXDEV:
        return "path_containment_denied";
    case EACCES:
    case EPERM:
    case EROFS:
        return "permission_denied";
    case ENOSYS:
    case EINVAL:
    case ENOTSUP:
        return "provider_unavailable";
    default:
        return "io_failure";
    }
}

static const char *mutation_error_code(int error_number)
{
    switch (error_number) {
    case ENOSPC:
    case EDQUOT:
        return "no_space";
    case EACCES:
    case EPERM:
    case EROFS:
        return "permission_denied";
    default:
        return "io_failure";
    }
}

static const char *random_error_code(int error_number)
{
    return error_number == ENOSYS ? "provider_unavailable" : "io_failure";
}

static const char *rename_error_code(int error_number)
{
    if (error_number == EEXIST) {
        return "target_exists";
    }
    if (error_number == ENOSYS || error_number == EINVAL
        || error_number == ENOTSUP) {
        return "provider_unavailable";
    }
    return mutation_error_code(error_number);
}

static void set_create_failure(
    struct proc17_create_result *result,
    const char *class_name,
    const char *code,
    const char *stage,
    int error_number,
    int mutation_primitive_entered,
    int published,
    uint64_t started)
{
    result->succeeded = 0;
    result->class_name = class_name;
    result->code = code;
    result->stage = stage;
    result->error_number = error_number;
    result->mutation_primitive_entered = mutation_primitive_entered;
    result->published = published;
    result->time_ms = elapsed_milliseconds(started);
}

static int create_file_transaction(
    const struct proc17_repository_handle *handle,
    const char *relative_path,
    size_t relative_path_length,
    const char *content,
    size_t content_length,
    mode_t file_mode,
    struct proc17_create_result *result)
{
    static const char hex[] = "0123456789abcdef";
    unsigned char random_value[PROC17_RANDOM_BYTES];
    char parent_path[PROC17_MAX_RELATIVE_PATH_BYTES + 1U];
    char final_name[PROC17_MAX_COMPONENT_BYTES + 1U];
    struct proc17_identity project_base_identity;
    struct proc17_identity repository_identity;
    const char *open_stage = NULL;
    const char *failure_class = "world";
    const char *failure_code = "io_failure";
    const char *failure_stage = "create_transaction";
    uint64_t started = monotonic_milliseconds();
    size_t offset = 0;
    size_t index;
    unsigned int write_eintr_retries = 0;
    int project_base_fd = -1;
    int repository_fd = -1;
    int parent_fd = -1;
    int temp_fd = -1;
    int temp_owned = 0;
    int saved_error = 0;
    int close_error = 0;
    ssize_t random_count;

    memset(result, 0, sizeof(*result));
    if (split_target_path(relative_path, relative_path_length,
            parent_path, sizeof(parent_path),
            final_name, sizeof(final_name)) != 0) {
        set_create_failure(result, "contract", "invalid_request",
            "validate_create_request", EINVAL, 0, 0, started);
        return -1;
    }

    if (open_identity_pair(handle_project_base(handle),
            handle_repository_path(handle), &project_base_fd, &repository_fd,
            &project_base_identity, &repository_identity, &open_stage) != 0) {
        saved_error = errno;
        failure_code = (saved_error == ENOSYS || saved_error == EINVAL
            || saved_error == ENOTSUP) ? "provider_unavailable" : "root_changed";
        set_create_failure(result, "world", failure_code, open_stage,
            saved_error, 0, 0, started);
        return -1;
    }
    if (!identity_equal(&project_base_identity, &handle->project_base_identity)
        || !identity_equal(&repository_identity, &handle->repository_identity)) {
        (void)close_pair(&project_base_fd, &repository_fd);
        set_create_failure(result, "world", "root_changed",
            "compare_root_identity", ESTALE, 0, 0, started);
        return -1;
    }

    parent_fd = openat2_with_flags(repository_fd, parent_path,
        O_RDONLY | O_DIRECTORY | O_CLOEXEC,
        RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS
            | RESOLVE_NO_MAGICLINKS | RESOLVE_NO_XDEV);
    if (parent_fd < 0) {
        saved_error = errno;
        failure_code = parent_error_code(saved_error);
        failure_stage = "open_parent";
        goto fail_before_temp;
    }
    {
        struct stat parent_status;
        if (fstat(parent_fd, &parent_status) != 0) {
            saved_error = errno;
            failure_code = "io_failure";
            failure_stage = "observe_parent_policy";
            goto fail_before_temp;
        }
        if (!S_ISDIR(parent_status.st_mode)
            || parent_status.st_uid != geteuid()
            || (parent_status.st_mode & 0022) != 0) {
            saved_error = EPERM;
            failure_code = "parent_not_private";
            failure_stage = "observe_parent_policy";
            goto fail_before_temp;
        }
    }
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL) {
        active_test_control->parent_fd = parent_fd;
        memcpy(active_test_control->final_name, final_name,
            strlen(final_name) + 1);
    }
#endif

    random_count = random_bytes_once(random_value, sizeof(random_value));
    if (random_count != (ssize_t)sizeof(random_value)) {
        saved_error = random_count < 0 && errno != 0 ? errno : EIO;
        failure_code = random_error_code(saved_error);
        failure_stage = "getrandom";
        goto fail_before_temp;
    }
    memcpy(result->temp_name, PROC17_TEMP_PREFIX,
        sizeof(PROC17_TEMP_PREFIX) - 1U);
    for (index = 0; index < sizeof(random_value); index++) {
        size_t target = sizeof(PROC17_TEMP_PREFIX) - 1U + index * 2U;
        result->temp_name[target] = hex[random_value[index] >> 4];
        result->temp_name[target + 1] = hex[random_value[index] & 0x0f];
    }
    result->temp_name[PROC17_TEMP_NAME_BYTES] = '\0';

    result->mutation_primitive_entered = 1;
    temp_fd = open_private_temp(parent_fd, result->temp_name, file_mode);
    if (temp_fd < 0) {
        saved_error = errno;
        failure_code = saved_error == EEXIST
            ? "temp_name_collision" : mutation_error_code(saved_error);
        failure_stage = "open_temp";
        goto fail_after_temp_attempt;
    }
    temp_owned = 1;
    if (fchmod(temp_fd, file_mode) != 0) {
        saved_error = errno;
        failure_code = mutation_error_code(saved_error);
        failure_stage = "set_temp_mode";
        goto fail_private;
    }
    {
        struct stat temp_status;
        if (fstat(temp_fd, &temp_status) != 0) {
            saved_error = errno;
            failure_code = "io_failure";
            failure_stage = "observe_temp_identity";
            goto fail_private;
        }
        if (!S_ISREG(temp_status.st_mode)
            || temp_status.st_uid != geteuid()
            || temp_status.st_nlink != 1
            || temp_status.st_size != 0
            || (temp_status.st_mode & 0777) != file_mode
#ifdef PROC17_REPOSITORY_FS_TESTING
            || (active_test_control != NULL
                && active_test_control->test_case->fault_stage
                    == PROC17_FAULT_TEMP_IDENTITY)
#endif
            ) {
            saved_error = EIO;
            failure_code = "temp_identity_invalid";
            failure_stage = "observe_temp_identity";
            goto fail_private;
        }
    }
    while (offset < content_length) {
        ssize_t written = write_private_bytes(temp_fd,
            content + offset, content_length - offset);
        if (written < 0) {
            if (errno == EINTR) {
                write_eintr_retries++;
                if (write_eintr_retries > PROC17_MAX_WRITE_EINTR_RETRIES) {
                    saved_error = EINTR;
                    failure_code = "io_failure";
                    failure_stage = "write_temp";
                    goto fail_private;
                }
                continue;
            }
            saved_error = errno;
            failure_code = mutation_error_code(saved_error);
            failure_stage = "write_temp";
            goto fail_private;
        }
        if (written == 0 || (size_t)written > content_length - offset) {
            saved_error = EIO;
            failure_code = "io_failure";
            failure_stage = "write_temp";
            goto fail_private;
        }
        offset += (size_t)written;
    }
    if (sync_private_file(temp_fd) != 0) {
        saved_error = errno;
        failure_code = mutation_error_code(saved_error);
        failure_stage = "fsync_temp";
        goto fail_private;
    }
    if (close_private_file(&temp_fd) != 0) {
        saved_error = errno;
        failure_code = mutation_error_code(saved_error);
        failure_stage = "close_temp";
        goto fail_private;
    }
    if (before_publish() != 0) {
        saved_error = errno;
        failure_code = mutation_error_code(saved_error);
        failure_stage = "before_rename";
        goto fail_private;
    }
    if (publish_no_replace(parent_fd, result->temp_name, final_name) != 0) {
        saved_error = errno;
        failure_code = rename_error_code(saved_error);
        failure_stage = "rename_noreplace";
        goto fail_private;
    }
    temp_owned = 0;
    result->published = 1;
    if (after_publish() != 0) {
        saved_error = errno;
        failure_stage = "after_rename";
        goto fail_published;
    }
    if (sync_parent_directory(parent_fd) != 0) {
        saved_error = errno;
        failure_stage = "fsync_parent";
        goto fail_published;
    }
    if (close(parent_fd) != 0) {
        saved_error = errno;
        parent_fd = -1;
        failure_stage = "close_transaction_descriptors";
        goto fail_published;
    }
    parent_fd = -1;
    close_error = close_pair(&project_base_fd, &repository_fd);
    if (close_error != 0) {
        set_create_failure(result, "ambiguous", "ambiguous_effect",
            "close_transaction_descriptors", close_error, 1, 1, started);
        return -1;
    }

    result->succeeded = 1;
    result->bytes = content_length;
    result->root_identity = repository_identity;
    result->mutation_primitive_entered = 1;
    result->published = 1;
    result->time_ms = elapsed_milliseconds(started);
    result->temp_name[0] = '\0';
    return 0;

fail_private:
    if (temp_fd >= 0) {
        close_once(&temp_fd);
    }
    if (temp_owned && remove_private_temp(parent_fd, result->temp_name) != 0) {
        int cleanup_error = errno;
        result->has_temp_residue = 1;
        if (parent_fd >= 0) {
            close_once(&parent_fd);
        }
        (void)close_pair(&project_base_fd, &repository_fd);
        set_create_failure(result, "ambiguous", "temp_cleanup_failed",
            "cleanup_unlink", cleanup_error, 1, 0, started);
        return -1;
    }

fail_after_temp_attempt:
    if (parent_fd >= 0) {
        close_once(&parent_fd);
    }
    (void)close_pair(&project_base_fd, &repository_fd);
    set_create_failure(result, failure_class, failure_code, failure_stage,
        saved_error, 1, 0, started);
    return -1;

fail_before_temp:
    if (parent_fd >= 0) {
        close_once(&parent_fd);
    }
    (void)close_pair(&project_base_fd, &repository_fd);
    set_create_failure(result, failure_class, failure_code, failure_stage,
        saved_error, 0, 0, started);
    return -1;

fail_published:
    if (parent_fd >= 0) {
        close_once(&parent_fd);
    }
    (void)close_pair(&project_base_fd, &repository_fd);
    set_create_failure(result, "ambiguous", "ambiguous_effect",
        failure_stage, saved_error, 1, 1, started);
    return -1;
}

static int close_checked(int *descriptor)
{
    int value = *descriptor;

    *descriptor = -1;
    if (value >= 0 && close(value) != 0) {
        return errno;
    }
    return 0;
}

static int close_read_descriptors(
    int *read_fd,
    int *target_fd,
    int *parent_fd,
    int *project_base_fd,
    int *repository_fd)
{
    int first_error = 0;
    int close_error;

    close_error = close_checked(read_fd);
    if (close_error != 0) {
        first_error = close_error;
    }
    close_error = close_checked(target_fd);
    if (close_error != 0 && first_error == 0) {
        first_error = close_error;
    }
    close_error = close_checked(parent_fd);
    if (close_error != 0 && first_error == 0) {
        first_error = close_error;
    }
    close_error = close_pair(project_base_fd, repository_fd);
    if (close_error != 0 && first_error == 0) {
        first_error = close_error;
    }
    return first_error;
}

static int same_file_identity(const struct stat *left, const struct stat *right)
{
    return left->st_dev == right->st_dev
        && left->st_ino == right->st_ino
        && (left->st_mode & S_IFMT) == (right->st_mode & S_IFMT);
}

static int same_timespec(
    const struct timespec *left,
    const struct timespec *right)
{
    return left->tv_sec == right->tv_sec
        && left->tv_nsec == right->tv_nsec;
}

static int same_file_version(const struct stat *left, const struct stat *right)
{
    return same_file_identity(left, right)
        && left->st_mode == right->st_mode
        && left->st_uid == right->st_uid
        && left->st_gid == right->st_gid
        && left->st_nlink == right->st_nlink
        && left->st_size == right->st_size
        && same_timespec(&left->st_mtim, &right->st_mtim)
        && same_timespec(&left->st_ctim, &right->st_ctim);
}

static void free_inventory_snapshot(struct proc17_inventory_snapshot *snapshot)
{
    size_t index;

    if (snapshot == NULL) {
        return;
    }
    for (index = 0; index < snapshot->count; index++) {
        free(snapshot->entries[index].relative_path);
        free(snapshot->entries[index].content);
    }
    free(snapshot->entries);
    memset(snapshot, 0, sizeof(*snapshot));
}

static int inventory_entry_compare(const void *left_value, const void *right_value)
{
    const struct proc17_inventory_entry *left =
        (const struct proc17_inventory_entry *)left_value;
    const struct proc17_inventory_entry *right =
        (const struct proc17_inventory_entry *)right_value;

    return strcmp(left->relative_path, right->relative_path);
}

static int reserve_inventory_entry(
    struct proc17_inventory_snapshot *snapshot,
    const struct proc17_inventory_bounds *bounds)
{
    size_t capacity;
    struct proc17_inventory_entry *grown;

    if (snapshot->count >= bounds->max_entries) {
        snapshot->bound_exceeded = 1;
        return 1;
    }
    if (snapshot->count < snapshot->capacity) {
        return 0;
    }
    capacity = snapshot->capacity == 0 ? 16U : snapshot->capacity * 2U;
    if (capacity > bounds->max_entries) {
        capacity = bounds->max_entries;
    }
    if (capacity <= snapshot->capacity
        || capacity > SIZE_MAX / sizeof(*snapshot->entries)) {
        errno = EOVERFLOW;
        return -1;
    }
    grown = (struct proc17_inventory_entry *)realloc(snapshot->entries,
        capacity * sizeof(*snapshot->entries));
    if (grown == NULL) {
        return -1;
    }
    memset(grown + snapshot->capacity, 0,
        (capacity - snapshot->capacity) * sizeof(*snapshot->entries));
    snapshot->entries = grown;
    snapshot->capacity = capacity;
    return 0;
}

static enum proc17_inventory_kind inventory_kind(mode_t mode)
{
    if (S_ISDIR(mode)) {
        return PROC17_INVENTORY_DIRECTORY;
    }
    if (S_ISREG(mode)) {
        return PROC17_INVENTORY_REGULAR;
    }
    if (S_ISLNK(mode)) {
        return PROC17_INVENTORY_SYMLINK;
    }
    return PROC17_INVENTORY_SPECIAL;
}

static int read_inventory_file(
    int directory_fd,
    const char *name,
    const struct stat *classified,
    struct proc17_inventory_entry *entry)
{
    struct stat before_status;
    struct stat after_status;
    unsigned int retries = 0;
    size_t offset = 0;
    char extra;
    int descriptor;

    descriptor = openat2_with_flags(directory_fd, name,
        O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC,
        RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS
            | RESOLVE_NO_MAGICLINKS | RESOLVE_NO_XDEV);
    if (descriptor < 0) {
        if (errno == ENOENT || errno == ELOOP || errno == ENOTDIR) {
            errno = ESTALE;
            return 1;
        }
        return -1;
    }
    if (fstat(descriptor, &before_status) != 0) {
        int saved = errno;
        close(descriptor);
        errno = saved;
        return -1;
    }
    if (!S_ISREG(before_status.st_mode)
        || !same_file_identity(classified, &before_status)) {
        close(descriptor);
        errno = ESTALE;
        return 1;
    }
    entry->identity_before = before_status;
    entry->content = (char *)malloc(entry->bytes == 0 ? 1U : entry->bytes);
    if (entry->content == NULL) {
        close(descriptor);
        return -1;
    }
    while (offset < entry->bytes) {
        ssize_t observed = read(descriptor, entry->content + offset,
            entry->bytes - offset);
        if (observed < 0 && errno == EINTR) {
            retries++;
            if (retries <= PROC17_MAX_READ_EINTR_RETRIES) {
                continue;
            }
        }
        if (observed <= 0 || (size_t)observed > entry->bytes - offset) {
            int saved = observed < 0 ? errno : ESTALE;
            close(descriptor);
            errno = saved;
            return observed < 0 ? -1 : 1;
        }
        offset += (size_t)observed;
    }
    while (1) {
        ssize_t observed = read(descriptor, &extra, 1U);
        if (observed < 0 && errno == EINTR) {
            retries++;
            if (retries <= PROC17_MAX_READ_EINTR_RETRIES) {
                continue;
            }
        }
        if (observed < 0) {
            int saved = errno;
            close(descriptor);
            errno = saved;
            return -1;
        }
        if (observed != 0) {
            close(descriptor);
            errno = ESTALE;
            return 1;
        }
        break;
    }
    if (fstat(descriptor, &after_status) != 0) {
        int saved = errno;
        close(descriptor);
        errno = saved;
        return -1;
    }
    if (close(descriptor) != 0) {
        return -1;
    }
    if (!same_file_version(&before_status, &after_status)) {
        errno = ESTALE;
        return 1;
    }
    entry->identity_after = after_status;
    return 0;
}

static int collect_inventory_directory(
    int directory_fd,
    const char *prefix,
    size_t depth,
    const struct proc17_inventory_bounds *bounds,
    int capture_content,
    struct proc17_inventory_snapshot *snapshot)
{
    int scan_fd = dup(directory_fd);
    DIR *stream;
    struct dirent *item = NULL;
    int result = 0;

    if (scan_fd < 0) {
        return -1;
    }
    stream = fdopendir(scan_fd);
    if (stream == NULL) {
        close(scan_fd);
        return -1;
    }
    errno = 0;
    while (!snapshot->bound_exceeded && !snapshot->unstable
        && (item = readdir(stream)) != NULL) {
        size_t name_length;
        size_t prefix_length;
        size_t path_length;
        char *path;
        struct stat status;
        struct proc17_inventory_entry *entry;
        enum proc17_inventory_kind kind;
        int reserved;

        if (strcmp(item->d_name, ".") == 0
            || strcmp(item->d_name, "..") == 0) {
            errno = 0;
            continue;
        }
        name_length = strlen(item->d_name);
        prefix_length = strlen(prefix);
        path_length = prefix_length == 0 ? name_length
            : prefix_length + 1U + name_length;
        if (name_length == 0 || name_length > bounds->max_component_bytes
            || path_length > bounds->max_path_bytes
            || depth + 1U > bounds->max_depth) {
            snapshot->bound_exceeded = 1;
            break;
        }
        path = (char *)malloc(path_length + 1U);
        if (path == NULL) {
            result = -1;
            break;
        }
        if (prefix_length == 0) {
            memcpy(path, item->d_name, name_length + 1U);
        } else {
            memcpy(path, prefix, prefix_length);
            path[prefix_length] = '/';
            memcpy(path + prefix_length + 1U, item->d_name, name_length + 1U);
        }
        if (fstatat(directory_fd, item->d_name, &status,
                AT_SYMLINK_NOFOLLOW) != 0) {
            int saved = errno;
            free(path);
            if (saved == ENOENT) {
                snapshot->unstable = 1;
                errno = ESTALE;
                break;
            }
            errno = saved;
            result = -1;
            break;
        }
        kind = inventory_kind(status.st_mode);
        if (kind == PROC17_INVENTORY_REGULAR) {
            if (status.st_size < 0
                || (uintmax_t)status.st_size > (uintmax_t)bounds->max_file_bytes
                || (uintmax_t)status.st_size
                    > (uintmax_t)(bounds->max_total_bytes - snapshot->total_bytes)) {
                free(path);
                snapshot->bound_exceeded = 1;
                break;
            }
        }
        reserved = reserve_inventory_entry(snapshot, bounds);
        if (reserved != 0) {
            free(path);
            if (reserved < 0) {
                result = -1;
            }
            break;
        }
        entry = &snapshot->entries[snapshot->count++];
        entry->relative_path = path;
        entry->kind = kind;
        entry->identity_before = status;
        entry->identity_after = status;
        if (kind == PROC17_INVENTORY_REGULAR) {
            entry->bytes = (size_t)status.st_size;
            snapshot->total_bytes += entry->bytes;
            if (capture_content) {
                int read_result = read_inventory_file(directory_fd,
                    item->d_name, &status, entry);
                if (read_result < 0) {
                    result = -1;
                    break;
                }
                if (read_result > 0) {
                    snapshot->unstable = 1;
                    break;
                }
            }
        } else if (kind == PROC17_INVENTORY_DIRECTORY) {
            int child_fd = openat2_with_flags(directory_fd, item->d_name,
                O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC,
                RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS
                    | RESOLVE_NO_MAGICLINKS | RESOLVE_NO_XDEV);
            struct stat opened_status;
            int child_result;
            int close_result;

            if (child_fd < 0) {
                if (errno == ENOENT || errno == ELOOP || errno == ENOTDIR) {
                    snapshot->unstable = 1;
                    errno = ESTALE;
                    break;
                }
                result = -1;
                break;
            }
            if (fstat(child_fd, &opened_status) != 0
                || !same_file_identity(&status, &opened_status)) {
                int saved = errno != 0 ? errno : ESTALE;
                close(child_fd);
                snapshot->unstable = 1;
                errno = saved;
                break;
            }
            entry->identity_after = opened_status;
            child_result = collect_inventory_directory(child_fd, path,
                depth + 1U, bounds, capture_content, snapshot);
            close_result = close(child_fd);
            if (child_result != 0 || close_result != 0) {
                result = -1;
                break;
            }
        }
        errno = 0;
    }
    if (item == NULL && errno != 0 && !snapshot->unstable) {
        result = -1;
    }
    {
        int saved = errno;
        if (closedir(stream) != 0 && result == 0) {
            return -1;
        }
        errno = saved;
    }
    return result;
}

static void sort_inventory_snapshot(struct proc17_inventory_snapshot *snapshot)
{
    qsort(snapshot->entries, snapshot->count, sizeof(*snapshot->entries),
        inventory_entry_compare);
}

static int compare_inventory_snapshots(
    struct proc17_inventory_snapshot *first,
    const struct proc17_inventory_snapshot *second)
{
    size_t index;

    if (first->count != second->count
        || first->bound_exceeded != second->bound_exceeded
        || first->total_bytes != second->total_bytes) {
        return 0;
    }
    for (index = 0; index < first->count; index++) {
        struct proc17_inventory_entry *left = &first->entries[index];
        const struct proc17_inventory_entry *right = &second->entries[index];
        if (strcmp(left->relative_path, right->relative_path) != 0
            || left->kind != right->kind
            || !same_file_version(&left->identity_after,
                &right->identity_before)) {
            return 0;
        }
        left->identity_after = right->identity_before;
    }
    return 1;
}

static const char *read_path_error_code(int error_number)
{
    switch (error_number) {
    case ELOOP:
        return "path_symlink";
    case EXDEV:
        return "path_containment_denied";
    case EACCES:
    case EPERM:
        return "permission_denied";
    case ENOSYS:
    case EINVAL:
    case ENOTSUP:
        return "provider_unavailable";
    default:
        return "io_failure";
    }
}

static void set_read_failure(
    struct proc17_read_result *result,
    const char *code,
    const char *stage,
    int error_number,
    uint64_t started)
{
    result->succeeded = 0;
    result->class_name = "world";
    result->code = code;
    result->stage = stage;
    result->error_number = error_number;
    result->time_ms = elapsed_milliseconds(started);
}

static int reobserve_named_target(
    const struct proc17_repository_handle *handle,
    const char *parent_path,
    const char *final_name,
    enum proc17_read_target_kind expected_kind,
    const struct stat *expected_status,
    struct proc17_identity *root_identity,
    const char **failure_code,
    const char **failure_stage,
    int *failure_error)
{
    struct proc17_identity project_base_identity;
    struct stat observed_status;
    const char *open_stage = NULL;
    int project_base_fd = -1;
    int repository_fd = -1;
    int parent_fd = -1;
    int target_fd = -1;
    int read_fd = -1;
    int saved_error = 0;
    int close_error;

    if (open_identity_pair(handle_project_base(handle),
            handle_repository_path(handle), &project_base_fd, &repository_fd,
            &project_base_identity, root_identity, &open_stage) != 0) {
        saved_error = errno;
        *failure_code = (saved_error == ENOSYS || saved_error == EINVAL
            || saved_error == ENOTSUP) ? "provider_unavailable" : "root_changed";
        *failure_stage = open_stage;
        goto fail;
    }
    if (!identity_equal(&project_base_identity, &handle->project_base_identity)
        || !identity_equal(root_identity, &handle->repository_identity)) {
        saved_error = ESTALE;
        *failure_code = "root_changed";
        *failure_stage = "compare_root_identity";
        goto fail;
    }
    parent_fd = openat2_with_flags(repository_fd, parent_path,
        O_PATH | O_DIRECTORY | O_CLOEXEC,
        RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS
            | RESOLVE_NO_MAGICLINKS | RESOLVE_NO_XDEV);
    if (parent_fd < 0) {
        saved_error = errno;
        *failure_code = (saved_error == ENOSYS || saved_error == EINVAL
            || saved_error == ENOTSUP) ? "provider_unavailable" : "target_changed";
        *failure_stage = "reobserve_read_target";
        goto fail;
    }
    target_fd = openat2_with_flags(parent_fd, final_name,
        O_PATH | O_NOFOLLOW | O_CLOEXEC,
        RESOLVE_BENEATH | RESOLVE_NO_MAGICLINKS | RESOLVE_NO_XDEV);
    if (expected_kind == PROC17_READ_TARGET_MISSING) {
        if (target_fd >= 0 || errno != ENOENT) {
            saved_error = target_fd >= 0 ? ESTALE : errno;
            *failure_code = "target_changed";
            *failure_stage = "reobserve_read_target";
            goto fail;
        }
    } else {
        if (target_fd < 0 || fstat(target_fd, &observed_status) != 0) {
            saved_error = errno != 0 ? errno : ESTALE;
            *failure_code = "target_changed";
            *failure_stage = "reobserve_read_target";
            goto fail;
        }
        if (expected_status == NULL
            || !same_file_version(expected_status, &observed_status)
            || (expected_kind == PROC17_READ_TARGET_REGULAR
                && !S_ISREG(observed_status.st_mode))
            || (expected_kind == PROC17_READ_TARGET_OTHER
                && S_ISREG(observed_status.st_mode))) {
            saved_error = ESTALE;
            *failure_code = "target_changed";
            *failure_stage = "reobserve_read_target";
            goto fail;
        }
    }

    close_error = close_read_descriptors(&read_fd, &target_fd,
        &parent_fd, &project_base_fd, &repository_fd);
    if (close_error != 0) {
        *failure_code = "io_failure";
        *failure_stage = "close_read_descriptors";
        *failure_error = close_error;
        return -1;
    }
    return 0;

fail:
    (void)close_read_descriptors(&read_fd, &target_fd,
        &parent_fd, &project_base_fd, &repository_fd);
    *failure_error = saved_error != 0 ? saved_error : EIO;
    return -1;
}

static ssize_t read_observed_bytes(
    int descriptor,
    void *buffer,
    size_t length)
{
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL) {
        active_test_control->read_attempts++;
        if (active_test_control->test_case->fault_stage
                == PROC17_FAULT_READ_ERROR) {
            errno = EIO;
            return -1;
        }
        if (active_test_control->test_case->fault_stage
                == PROC17_FAULT_READ_EINTR_FOREVER) {
            errno = EINTR;
            return -1;
        }
    }
#endif
    return read(descriptor, buffer, length);
}

#ifdef PROC17_REPOSITORY_FS_TESTING
static int inject_read_mutation(
    int parent_fd,
    const char *final_name,
    enum proc17_fs_fault_stage stage)
{
    static const char replacement[] = "replacement\n";
    int descriptor;
    int result;

    if (stage == PROC17_FAULT_READ_GROW) {
        descriptor = openat(parent_fd, final_name,
            O_WRONLY | O_NOFOLLOW | O_CLOEXEC);
        if (descriptor < 0) {
            return -1;
        }
        if (lseek(descriptor, 0, SEEK_END) < 0) {
            close(descriptor);
            return -1;
        }
        result = write_all_raw(descriptor, "x", 1U);
        if (close(descriptor) != 0) {
            return -1;
        }
        return result;
    }
    if (stage == PROC17_FAULT_READ_REPLACE) {
        if (unlinkat(parent_fd, final_name, 0) != 0) {
            return -1;
        }
        descriptor = openat(parent_fd, final_name,
            O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
        if (descriptor < 0) {
            return -1;
        }
        result = write_all_raw(descriptor, replacement,
            sizeof(replacement) - 1U);
        if (close(descriptor) != 0) {
            return -1;
        }
        return result;
    }
    return 0;
}
#endif

static int read_file_transaction(
    const struct proc17_repository_handle *handle,
    const char *relative_path,
    size_t relative_path_length,
    size_t max_bytes,
    struct proc17_read_result *result)
{
    char parent_path[PROC17_MAX_RELATIVE_PATH_BYTES + 1U];
    char final_name[PROC17_MAX_COMPONENT_BYTES + 1U];
    struct proc17_identity project_base_identity;
    struct proc17_identity repository_identity;
    struct stat classified_status;
    struct stat before_status;
    struct stat after_status;
    const char *open_stage = NULL;
    const char *failure_code = "io_failure";
    const char *failure_stage = "read_transaction";
    uint64_t started = monotonic_milliseconds();
    unsigned int read_eintr_retries = 0;
    size_t offset = 0;
    int project_base_fd = -1;
    int repository_fd = -1;
    int parent_fd = -1;
    int target_fd = -1;
    int read_fd = -1;
    int saved_error = 0;
    int close_error;

    memset(result, 0, sizeof(*result));
    if (split_target_path(relative_path, relative_path_length,
            parent_path, sizeof(parent_path),
            final_name, sizeof(final_name)) != 0) {
        result->class_name = "contract";
        result->code = "invalid_request";
        result->stage = "validate_read_request";
        result->error_number = EINVAL;
        return -1;
    }

    if (open_identity_pair(handle_project_base(handle),
            handle_repository_path(handle), &project_base_fd, &repository_fd,
            &project_base_identity, &repository_identity, &open_stage) != 0) {
        saved_error = errno;
        failure_code = (saved_error == ENOSYS || saved_error == EINVAL
            || saved_error == ENOTSUP) ? "provider_unavailable" : "root_changed";
        set_read_failure(result, failure_code, open_stage, saved_error, started);
        return -1;
    }
    if (!identity_equal(&project_base_identity, &handle->project_base_identity)
        || !identity_equal(&repository_identity, &handle->repository_identity)) {
        (void)close_pair(&project_base_fd, &repository_fd);
        set_read_failure(result, "root_changed", "compare_root_identity",
            ESTALE, started);
        return -1;
    }

    parent_fd = openat2_with_flags(repository_fd, parent_path,
        O_PATH | O_DIRECTORY | O_CLOEXEC,
        RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS
            | RESOLVE_NO_MAGICLINKS | RESOLVE_NO_XDEV);
    if (parent_fd < 0) {
        saved_error = errno;
        failure_code = parent_error_code(saved_error);
        failure_stage = "open_read_parent";
        goto fail;
    }
#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL) {
        active_test_control->parent_fd = parent_fd;
        memcpy(active_test_control->final_name, final_name,
            strlen(final_name) + 1U);
        if (active_test_control->test_case->fault_stage
                == PROC17_FAULT_READ_OPEN) {
            saved_error = EIO;
            failure_code = "io_failure";
            failure_stage = "classify_read_target";
            goto fail;
        }
    }
#endif

    target_fd = openat2_with_flags(parent_fd, final_name,
        O_PATH | O_NOFOLLOW | O_CLOEXEC,
        RESOLVE_BENEATH | RESOLVE_NO_MAGICLINKS | RESOLVE_NO_XDEV);
    if (target_fd < 0) {
        saved_error = errno;
        if (saved_error == ENOENT) {
            close_error = close_read_descriptors(&read_fd, &target_fd,
                &parent_fd, &project_base_fd, &repository_fd);
            if (close_error != 0) {
                set_read_failure(result, "io_failure",
                    "close_read_descriptors", close_error, started);
                return -1;
            }
            if (reobserve_named_target(handle, parent_path, final_name,
                    PROC17_READ_TARGET_MISSING, NULL, &repository_identity,
                    &failure_code, &failure_stage, &saved_error) != 0) {
                goto fail;
            }
            result->succeeded = 1;
            result->target_kind = PROC17_READ_TARGET_MISSING;
            result->root_identity = repository_identity;
            result->time_ms = elapsed_milliseconds(started);
            return 0;
        }
        failure_code = read_path_error_code(saved_error);
        failure_stage = "classify_read_target";
        goto fail;
    }
    if (fstat(target_fd, &classified_status) != 0) {
        saved_error = errno;
        failure_code = "io_failure";
        failure_stage = "observe_read_target";
        goto fail;
    }
    if (!S_ISREG(classified_status.st_mode)) {
        close_error = close_read_descriptors(&read_fd, &target_fd,
            &parent_fd, &project_base_fd, &repository_fd);
        if (close_error != 0) {
            set_read_failure(result, "io_failure",
                "close_read_descriptors", close_error, started);
            return -1;
        }
        if (reobserve_named_target(handle, parent_path, final_name,
                PROC17_READ_TARGET_OTHER, &classified_status,
                &repository_identity, &failure_code, &failure_stage,
                &saved_error) != 0) {
            goto fail;
        }
        result->succeeded = 1;
        result->target_kind = PROC17_READ_TARGET_OTHER;
        result->root_identity = repository_identity;
        result->time_ms = elapsed_milliseconds(started);
        return 0;
    }

#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL
        && active_test_control->test_case->fault_stage
            == PROC17_FAULT_READ_REPLACE
        && inject_read_mutation(parent_fd, final_name,
            PROC17_FAULT_READ_REPLACE) != 0) {
        saved_error = errno != 0 ? errno : EIO;
        failure_code = "io_failure";
        failure_stage = "test_read_replacement";
        goto fail;
    }
#endif

    read_fd = openat2_with_flags(parent_fd, final_name,
        O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC,
        RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS
            | RESOLVE_NO_MAGICLINKS | RESOLVE_NO_XDEV);
    if (read_fd < 0) {
        saved_error = errno;
        failure_code = (saved_error == ENOENT || saved_error == ELOOP
            || saved_error == ENOTDIR) ? "target_changed"
            : read_path_error_code(saved_error);
        failure_stage = "open_read_target";
        goto fail;
    }
    if (fstat(read_fd, &before_status) != 0) {
        saved_error = errno;
        failure_code = "io_failure";
        failure_stage = "observe_read_target";
        goto fail;
    }
    if (!S_ISREG(before_status.st_mode)
        || !same_file_identity(&classified_status, &before_status)) {
        saved_error = ESTALE;
        failure_code = "target_changed";
        failure_stage = "observe_read_target";
        goto fail;
    }

    result->content = (char *)malloc(max_bytes);
    if (result->content == NULL) {
        saved_error = ENOMEM;
        failure_code = "io_failure";
        failure_stage = "allocate_read_buffer";
        goto fail;
    }
    while (offset < max_bytes) {
        ssize_t observed = read_observed_bytes(read_fd,
            result->content + offset, max_bytes - offset);
        if (observed < 0) {
            if (errno == EINTR) {
                read_eintr_retries++;
                if (read_eintr_retries > PROC17_MAX_READ_EINTR_RETRIES) {
                    saved_error = EINTR;
                    failure_code = "io_failure";
                    failure_stage = "read_target";
                    goto fail;
                }
                continue;
            }
            saved_error = errno;
            failure_code = "io_failure";
            failure_stage = "read_target";
            goto fail;
        }
        if (observed == 0) {
            break;
        }
        if ((size_t)observed > max_bytes - offset) {
            saved_error = EIO;
            failure_code = "io_failure";
            failure_stage = "read_target";
            goto fail;
        }
        offset += (size_t)observed;
    }

#ifdef PROC17_REPOSITORY_FS_TESTING
    if (active_test_control != NULL
        && active_test_control->test_case->fault_stage == PROC17_FAULT_READ_GROW
        && inject_read_mutation(parent_fd, final_name,
            PROC17_FAULT_READ_GROW) != 0) {
        saved_error = errno != 0 ? errno : EIO;
        failure_code = "io_failure";
        failure_stage = "test_read_growth";
        goto fail;
    }
#endif

    if (fstat(read_fd, &after_status) != 0) {
        saved_error = errno;
        failure_code = "io_failure";
        failure_stage = "verify_read_stability";
        goto fail;
    }
    if (!same_file_version(&before_status, &after_status)) {
        saved_error = ESTALE;
        failure_code = "read_unstable";
        failure_stage = "verify_read_stability";
        goto fail;
    }

    close_error = close_read_descriptors(&read_fd, &target_fd,
        &parent_fd, &project_base_fd, &repository_fd);
    if (close_error != 0) {
        set_read_failure(result, "io_failure", "close_read_descriptors",
            close_error, started);
        free(result->content);
        result->content = NULL;
        return -1;
    }

    if (reobserve_named_target(handle, parent_path, final_name,
            PROC17_READ_TARGET_REGULAR, &after_status, &repository_identity,
            &failure_code, &failure_stage, &saved_error) != 0) {
        goto fail;
    }
    result->succeeded = 1;
    result->target_kind = PROC17_READ_TARGET_REGULAR;
    result->bytes = offset;
    result->root_identity = repository_identity;
    result->time_ms = elapsed_milliseconds(started);
    return 0;

fail:
    (void)close_read_descriptors(&read_fd, &target_fd,
        &parent_fd, &project_base_fd, &repository_fd);
    free(result->content);
    result->content = NULL;
    set_read_failure(result, failure_code, failure_stage,
        saved_error != 0 ? saved_error : EIO, started);
    return -1;
}

static const char *handle_project_base(
    const struct proc17_repository_handle *handle)
{
    return handle->paths;
}

static const char *handle_repository_path(
    const struct proc17_repository_handle *handle)
{
    return handle->paths + handle->project_base_length + 1;
}

static struct proc17_repository_handle *check_handle(lua_State *L, int index)
{
    struct proc17_repository_handle *handle =
        (struct proc17_repository_handle *)luaL_testudata(
            L, index, PROC17_HANDLE_METATABLE);
    if (handle == NULL) {
        luaL_error(L, "repository provider handle has invalid native identity");
    }
    return handle;
}

static int identity_representable(const struct proc17_identity *identity)
{
    return (uintmax_t)identity->device <= (uintmax_t)LUA_MAXINTEGER
        && (uintmax_t)identity->inode <= (uintmax_t)LUA_MAXINTEGER;
}

static void push_identity(lua_State *L, const struct proc17_identity *identity)
{
    lua_createtable(L, 0, 2);
    set_integer(L, "device", (lua_Integer)(uintmax_t)identity->device);
    set_integer(L, "inode", (lua_Integer)(uintmax_t)identity->inode);
}

static int stat_identity_representable(const struct stat *status)
{
    return (uintmax_t)status->st_dev <= (uintmax_t)LUA_MAXINTEGER
        && (uintmax_t)status->st_ino <= (uintmax_t)LUA_MAXINTEGER;
}

static void push_stat_identity(lua_State *L, const struct stat *status)
{
    lua_createtable(L, 0, 2);
    set_integer(L, "device", (lua_Integer)(uintmax_t)status->st_dev);
    set_integer(L, "inode", (lua_Integer)(uintmax_t)status->st_ino);
}

static int close_handle_descriptors(struct proc17_repository_handle *handle)
{
    int result;

    if (handle->closed) {
        return 0;
    }
    result = close_pair(&handle->project_base_fd, &handle->repository_fd);
    handle->closed = 1;
    return result;
}

static int handle_gc(lua_State *L)
{
    struct proc17_repository_handle *handle = check_handle(L, 1);

    (void)close_handle_descriptors(handle);
    return 0;
}

static int handle_tostring(lua_State *L)
{
    struct proc17_repository_handle *handle = check_handle(L, 1);

    lua_pushliteral(L, "repository.handle.v0<opaque:");
    lua_pushstring(L, handle->closed ? "closed>" : "open>");
    lua_concat(L, 2);
    return 1;
}

static int open_repository(lua_State *L)
{
    size_t project_base_length;
    size_t repository_path_length;
    const char *project_base = luaL_checklstring(L, 1, &project_base_length);
    const char *repository_path = luaL_checklstring(L, 2, &repository_path_length);
    struct proc17_repository_handle *handle;
    const char *stage;

    if (!valid_project_base(project_base, project_base_length)
        || !valid_repository_path(repository_path, repository_path_length)) {
        return push_error(L, "contract", "invalid_request",
            "validate_root_request", EINVAL, 0);
    }

    handle = (struct proc17_repository_handle *)lua_newuserdatauv(L,
        sizeof(*handle) + project_base_length + repository_path_length + 2, 0);
    memset(handle, 0, sizeof(*handle));
    handle->project_base_fd = -1;
    handle->repository_fd = -1;
    handle->project_base_length = project_base_length;
    handle->repository_path_length = repository_path_length;
    memcpy(handle->paths, project_base, project_base_length);
    handle->paths[project_base_length] = '\0';
    memcpy(handle->paths + project_base_length + 1,
        repository_path, repository_path_length);
    handle->paths[project_base_length + 1 + repository_path_length] = '\0';
    luaL_getmetatable(L, PROC17_HANDLE_METATABLE);
    lua_setmetatable(L, -2);

    if (open_identity_pair(project_base, repository_path,
            &handle->project_base_fd, &handle->repository_fd,
            &handle->project_base_identity, &handle->repository_identity,
            &stage) != 0) {
        int saved = errno;
        const char *code = open_error_code(saved);

        (void)close_handle_descriptors(handle);
        return push_error(L, "world", code, stage, saved, 1);
    }
    if (!identity_representable(&handle->project_base_identity)
        || !identity_representable(&handle->repository_identity)) {
        (void)close_handle_descriptors(handle);
        return push_error(L, "contract", "identity_unrepresentable",
            "project_root_identity", EOVERFLOW, 1);
    }

    lua_createtable(L, 0, 4);
    push_identity(L, &handle->project_base_identity);
    lua_setfield(L, -2, "project_base");
    push_identity(L, &handle->repository_identity);
    lua_setfield(L, -2, "root");
    lua_pushlstring(L, repository_path, repository_path_length);
    lua_setfield(L, -2, "repository_path");
    lua_pushfstring(L, "%s/%s", project_base, repository_path);
    lua_setfield(L, -2, "host_path");
    return 2;
}

static int revalidate(lua_State *L)
{
    struct proc17_repository_handle *handle = check_handle(L, 1);
    struct proc17_identity project_base_identity;
    struct proc17_identity repository_identity;
    const char *stage;
    int project_base_fd;
    int repository_fd;

    if (handle->closed) {
        return push_error(L, "contract", "handle_closed",
            "revalidate_handle", 0, 0);
    }
    if (open_identity_pair(handle_project_base(handle),
            handle_repository_path(handle), &project_base_fd, &repository_fd,
            &project_base_identity, &repository_identity, &stage) != 0) {
        int saved = errno;
        const char *code = (saved == ENOSYS || saved == EINVAL || saved == ENOTSUP)
            ? "provider_unavailable" : "root_changed";
        return push_error(L, "world", code, stage, saved, 1);
    }
    if (project_base_identity.device != handle->project_base_identity.device
        || project_base_identity.inode != handle->project_base_identity.inode
        || project_base_identity.mount_id != handle->project_base_identity.mount_id
        || repository_identity.device != handle->repository_identity.device
        || repository_identity.inode != handle->repository_identity.inode
        || repository_identity.mount_id != handle->repository_identity.mount_id) {
        (void)close_pair(&project_base_fd, &repository_fd);
        return push_error(L, "world", "root_changed",
            "compare_root_identity", ESTALE, 1);
    }
    {
        int close_error = close_pair(&project_base_fd, &repository_fd);
        if (close_error != 0) {
            return push_error(L, "world", "io_failure",
                "close_revalidation_descriptors", close_error, 1);
        }
    }

    lua_createtable(L, 0, 7);
    set_string(L, "protocol_version", "repository.provider_result.v0");
    set_string(L, "operation", "revalidate");
    set_string(L, "outcome", "valid");
    push_identity(L, &repository_identity);
    lua_setfield(L, -2, "root");
    set_boolean(L, "mutation_primitive_entered", 0);
    set_boolean(L, "published", 0);
    push_cost(L, 1, 0, 0);
    lua_setfield(L, -2, "cost");
    return 1;
}

static int create_text_file(lua_State *L)
{
    struct proc17_repository_handle *handle = check_handle(L, 1);
    const char *relative_path;
    const char *content;
    size_t relative_path_length;
    size_t content_length;
    lua_Integer requested_mode;
    struct proc17_create_result result;

    if (handle->closed) {
        return push_error(L, "contract", "handle_closed",
            "create_handle", 0, 0);
    }
    if (lua_gettop(L) != 4
        || lua_type(L, 2) != LUA_TSTRING
        || lua_type(L, 3) != LUA_TSTRING
        || !lua_isinteger(L, 4)) {
        return push_error(L, "contract", "invalid_request",
            "validate_create_request", EINVAL, 0);
    }
    relative_path = lua_tolstring(L, 2, &relative_path_length);
    content = lua_tolstring(L, 3, &content_length);
    requested_mode = lua_tointeger(L, 4);
    if (!valid_repository_path(relative_path, relative_path_length)
        || content_length > PROC17_MAX_CONTENT_BYTES
        || !valid_utf8_text((const unsigned char *)content, content_length)
        || requested_mode != PROC17_FILE_MODE) {
        return push_error(L, "contract", "invalid_request",
            "validate_create_request", EINVAL, 0);
    }

    if (create_file_transaction(handle, relative_path, relative_path_length,
            content, content_length, (mode_t)requested_mode, &result) != 0) {
        return push_error_full(L, result.class_name, result.code, result.stage,
            result.error_number, result.mutation_primitive_entered,
            result.published, 1,
            result.mutation_primitive_entered ? 1 : 0,
            result.time_ms,
            result.has_temp_residue ? result.temp_name : NULL);
    }

    lua_createtable(L, 0, 8);
    set_string(L, "protocol_version", "repository.provider_result.v0");
    set_string(L, "operation", "create_text_file");
    set_string(L, "outcome", "created");
    set_integer(L, "bytes", (lua_Integer)result.bytes);
    push_identity(L, &result.root_identity);
    lua_setfield(L, -2, "root");
    set_boolean(L, "mutation_primitive_entered", 1);
    set_boolean(L, "published", 1);
    push_cost(L, 1, 1, result.time_ms);
    lua_setfield(L, -2, "cost");
    return 1;
}

static int read_text_file(lua_State *L)
{
    struct proc17_repository_handle *handle = check_handle(L, 1);
    const char *relative_path;
    size_t relative_path_length;
    lua_Integer requested_max_bytes;
    struct proc17_read_result result;
    const char *target_kind;

    if (handle->closed) {
        return push_error(L, "contract", "handle_closed",
            "read_handle", 0, 0);
    }
    if (lua_gettop(L) != 3
        || lua_type(L, 2) != LUA_TSTRING
        || !lua_isinteger(L, 3)) {
        return push_error(L, "contract", "invalid_request",
            "validate_read_request", EINVAL, 0);
    }
    relative_path = lua_tolstring(L, 2, &relative_path_length);
    requested_max_bytes = lua_tointeger(L, 3);
    if (!valid_repository_path(relative_path, relative_path_length)
        || requested_max_bytes < 1
        || (lua_Unsigned)requested_max_bytes
            > (lua_Unsigned)PROC17_MAX_READ_BYTES) {
        return push_error(L, "contract", "invalid_request",
            "validate_read_request", EINVAL, 0);
    }

    if (read_file_transaction(handle, relative_path, relative_path_length,
            (size_t)requested_max_bytes, &result) != 0) {
        return push_error_full(L, result.class_name, result.code, result.stage,
            result.error_number, 0, 0, 1, 0, result.time_ms, NULL);
    }

    switch (result.target_kind) {
    case PROC17_READ_TARGET_MISSING:
        target_kind = "missing";
        break;
    case PROC17_READ_TARGET_REGULAR:
        target_kind = "regular_file";
        break;
    default:
        target_kind = "other";
        break;
    }
    lua_createtable(L, 0, result.target_kind == PROC17_READ_TARGET_REGULAR
        ? 10 : 8);
    set_string(L, "protocol_version", "repository.provider_result.v0");
    set_string(L, "operation", "read_text_file");
    set_string(L, "outcome", "observed");
    set_string(L, "target_kind", target_kind);
    if (result.target_kind == PROC17_READ_TARGET_REGULAR) {
        set_integer(L, "bytes", (lua_Integer)result.bytes);
        lua_pushlstring(L, result.content, result.bytes);
        lua_setfield(L, -2, "content");
    }
    push_identity(L, &result.root_identity);
    lua_setfield(L, -2, "root");
    set_boolean(L, "mutation_primitive_entered", 0);
    set_boolean(L, "published", 0);
    push_cost(L, 1, 0, result.time_ms);
    lua_setfield(L, -2, "cost");
    free(result.content);
    return 1;
}

static int inventory_tree(lua_State *L)
{
    struct proc17_repository_handle *handle = check_handle(L, 1);
    struct proc17_inventory_bounds bounds;
    struct proc17_inventory_snapshot first;
    struct proc17_inventory_snapshot second;
    struct proc17_identity project_before;
    struct proc17_identity root_before;
    struct proc17_identity project_after;
    struct proc17_identity root_after;
    const char *open_stage = NULL;
    const char *failure_stage = "inventory_tree";
    const char *failure_code = "io_failure";
    uint64_t started = monotonic_milliseconds();
    int project_fd = -1;
    int repository_fd = -1;
    int scan_fd = -1;
    int after_project_fd = -1;
    int after_repository_fd = -1;
    int saved_error = 0;
    int stable = 1;
    size_t index;

    memset(&first, 0, sizeof(first));
    memset(&second, 0, sizeof(second));
    if (handle->closed) {
        return push_error(L, "contract", "handle_closed",
            "inventory_handle", 0, 0);
    }
    if (lua_gettop(L) != 7) {
        return push_error(L, "contract", "invalid_request",
            "validate_inventory_request", EINVAL, 0);
    }
    for (index = 2; index <= 7; index++) {
        if (!lua_isinteger(L, (int)index) || lua_tointeger(L, (int)index) < 1) {
            return push_error(L, "contract", "invalid_request",
                "validate_inventory_request", EINVAL, 0);
        }
    }
    bounds.max_entries = (size_t)lua_tointeger(L, 2);
    bounds.max_depth = (size_t)lua_tointeger(L, 3);
    bounds.max_path_bytes = (size_t)lua_tointeger(L, 4);
    bounds.max_component_bytes = (size_t)lua_tointeger(L, 5);
    bounds.max_file_bytes = (size_t)lua_tointeger(L, 6);
    bounds.max_total_bytes = (size_t)lua_tointeger(L, 7);
    if (bounds.max_entries > PROC17_MAX_INVENTORY_ENTRIES
        || bounds.max_depth > PROC17_MAX_COMPONENTS
        || bounds.max_path_bytes > PROC17_MAX_RELATIVE_PATH_BYTES
        || bounds.max_component_bytes > PROC17_MAX_COMPONENT_BYTES
        || bounds.max_file_bytes > PROC17_MAX_CONTENT_BYTES
        || bounds.max_total_bytes > PROC17_MAX_INVENTORY_TOTAL_BYTES) {
        return push_error(L, "contract", "invalid_request",
            "validate_inventory_request", EINVAL, 0);
    }

    if (open_identity_pair(handle_project_base(handle),
            handle_repository_path(handle), &project_fd, &repository_fd,
            &project_before, &root_before, &open_stage) != 0) {
        saved_error = errno;
        failure_stage = open_stage;
        failure_code = (saved_error == ENOSYS || saved_error == EINVAL
            || saved_error == ENOTSUP) ? "provider_unavailable" : "root_changed";
        goto fail;
    }
    if (!identity_equal(&project_before, &handle->project_base_identity)
        || !identity_equal(&root_before, &handle->repository_identity)) {
        saved_error = ESTALE;
        failure_stage = "compare_root_identity";
        failure_code = "root_changed";
        goto fail;
    }
    scan_fd = openat(repository_fd, ".",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (scan_fd < 0) {
        saved_error = errno;
        failure_stage = "open_inventory_root";
        failure_code = (saved_error == EACCES || saved_error == EPERM)
            ? "permission_denied" : "io_failure";
        goto fail;
    }
    if (collect_inventory_directory(scan_fd, "", 0U, &bounds, 1, &first) != 0) {
        saved_error = errno != 0 ? errno : EIO;
        failure_stage = "enumerate_inventory_tree";
        failure_code = (saved_error == EACCES || saved_error == EPERM)
            ? "permission_denied" : "io_failure";
        goto fail;
    }
    if (first.unstable) {
        saved_error = ESTALE;
        failure_stage = "verify_inventory_stability";
        failure_code = "inventory_unstable";
        goto fail;
    }
    sort_inventory_snapshot(&first);
    if (!first.bound_exceeded) {
        int second_fd = openat(repository_fd, ".",
            O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
        if (second_fd < 0) {
            saved_error = errno;
            failure_stage = "open_inventory_root";
            failure_code = "io_failure";
            goto fail;
        }
        if (collect_inventory_directory(second_fd, "", 0U,
                &bounds, 0, &second) != 0) {
            saved_error = errno != 0 ? errno : EIO;
            close(second_fd);
            failure_stage = "reobserve_inventory_tree";
            failure_code = "io_failure";
            goto fail;
        }
        if (close(second_fd) != 0) {
            saved_error = errno;
            failure_stage = "close_inventory_descriptors";
            failure_code = "io_failure";
            goto fail;
        }
        sort_inventory_snapshot(&second);
        if (second.unstable || !compare_inventory_snapshots(&first, &second)) {
            stable = 0;
        }
    }
    if (close(scan_fd) != 0) {
        saved_error = errno;
        scan_fd = -1;
        failure_stage = "close_inventory_descriptors";
        failure_code = "io_failure";
        goto fail;
    }
    scan_fd = -1;
    {
        int close_error = close_pair(&project_fd, &repository_fd);
        if (close_error != 0) {
            saved_error = close_error;
            failure_stage = "close_inventory_descriptors";
            failure_code = "io_failure";
            goto fail;
        }
    }
    if (open_identity_pair(handle_project_base(handle),
            handle_repository_path(handle), &after_project_fd,
            &after_repository_fd, &project_after, &root_after,
            &open_stage) != 0) {
        saved_error = errno;
        failure_stage = "revalidate_inventory_root";
        failure_code = "root_changed";
        goto fail;
    }
    if (!identity_equal(&project_after, &handle->project_base_identity)
        || !identity_equal(&root_after, &handle->repository_identity)) {
        saved_error = ESTALE;
        failure_stage = "revalidate_inventory_root";
        failure_code = "root_changed";
        goto fail;
    }
    {
        int close_error = close_pair(&after_project_fd, &after_repository_fd);
        if (close_error != 0) {
            saved_error = close_error;
            failure_stage = "close_inventory_descriptors";
            failure_code = "io_failure";
            goto fail;
        }
    }

    lua_createtable(L, 0, 11);
    set_string(L, "protocol_version", "repository.provider_inventory_result.v0");
    set_string(L, "operation", "inventory_tree");
    set_string(L, "outcome", first.bound_exceeded
        ? "bound_exceeded" : "observed");
    push_identity(L, &root_before);
    lua_setfield(L, -2, "root_before");
    push_identity(L, &root_after);
    lua_setfield(L, -2, "root_after");
    set_boolean(L, "stable", stable);
    lua_createtable(L, (int)first.count, 0);
    for (index = 0; index < first.count; index++) {
        const struct proc17_inventory_entry *entry = &first.entries[index];
        const char *kind;

        if (!stat_identity_representable(&entry->identity_before)
            || !stat_identity_representable(&entry->identity_after)) {
            lua_pop(L, 2);
            saved_error = EOVERFLOW;
            failure_stage = "project_inventory_identity";
            failure_code = "identity_unrepresentable";
            goto fail;
        }
        switch (entry->kind) {
        case PROC17_INVENTORY_DIRECTORY:
            kind = "directory";
            break;
        case PROC17_INVENTORY_REGULAR:
            kind = "regular_file";
            break;
        case PROC17_INVENTORY_SYMLINK:
            kind = "symlink";
            break;
        default:
            kind = "special";
            break;
        }
        lua_createtable(L, 0, entry->kind == PROC17_INVENTORY_REGULAR ? 7 : 5);
        set_string(L, "relative_path", entry->relative_path);
        set_string(L, "kind", kind);
        push_stat_identity(L, &entry->identity_before);
        lua_setfield(L, -2, "identity_before");
        push_stat_identity(L, &entry->identity_after);
        lua_setfield(L, -2, "identity_after");
        if (entry->kind == PROC17_INVENTORY_REGULAR) {
            set_integer(L, "bytes", (lua_Integer)entry->bytes);
            lua_pushlstring(L, entry->content, entry->bytes);
            lua_setfield(L, -2, "content");
        }
        lua_rawseti(L, -2, (lua_Integer)index + 1);
    }
    lua_setfield(L, -2, "entries");
    lua_createtable(L, 0, 8);
    set_integer(L, "max_entries", (lua_Integer)bounds.max_entries);
    set_integer(L, "max_depth", (lua_Integer)bounds.max_depth);
    set_integer(L, "max_path_bytes", (lua_Integer)bounds.max_path_bytes);
    set_integer(L, "max_component_bytes",
        (lua_Integer)bounds.max_component_bytes);
    set_integer(L, "max_file_bytes", (lua_Integer)bounds.max_file_bytes);
    set_integer(L, "max_total_bytes", (lua_Integer)bounds.max_total_bytes);
    set_integer(L, "observed_entries", (lua_Integer)first.count);
    set_integer(L, "observed_total_bytes", (lua_Integer)first.total_bytes);
    lua_setfield(L, -2, "bounds_observed");
    set_boolean(L, "mutation_primitive_entered", 0);
    set_boolean(L, "published", 0);
    push_cost(L, 1, 0, elapsed_milliseconds(started));
    lua_setfield(L, -2, "cost");
    free_inventory_snapshot(&first);
    free_inventory_snapshot(&second);
    return 1;

fail:
    if (scan_fd >= 0) {
        close(scan_fd);
    }
    (void)close_pair(&project_fd, &repository_fd);
    (void)close_pair(&after_project_fd, &after_repository_fd);
    free_inventory_snapshot(&first);
    free_inventory_snapshot(&second);
    return push_error(L,
        strcmp(failure_code, "identity_unrepresentable") == 0
            ? "contract" : "world",
        failure_code, failure_stage,
        saved_error != 0 ? saved_error : EIO, 1);
}

static int close_repository(lua_State *L)
{
    struct proc17_repository_handle *handle = check_handle(L, 1);
    int close_error = close_handle_descriptors(handle);

    if (close_error != 0) {
        return push_error(L, "world", "io_failure",
            "close_repository", close_error, 0);
    }
    lua_pushboolean(L, 1);
    return 1;
}

#ifdef PROC17_REPOSITORY_FS_TESTING

#define PROC17_TEST_TEMPLATE "/tmp/proc17-native-fs-XXXXXX"

static char test_final_content[PROC17_MAX_CONTENT_BYTES + 1U];
static char test_observed_content[PROC17_MAX_READ_BYTES + 1U];

static int count_open_descriptors(void)
{
    DIR *stream = opendir("/proc/self/fd");
    struct dirent *entry;
    int count = 0;

    if (stream == NULL) {
        return -1;
    }
    while ((entry = readdir(stream)) != NULL) {
        if (strcmp(entry->d_name, ".") != 0
            && strcmp(entry->d_name, "..") != 0) {
            count++;
        }
    }
    if (closedir(stream) != 0) {
        return -1;
    }
    return count;
}

static int remove_test_contents(int directory_fd)
{
    int scan_fd = dup(directory_fd);
    DIR *stream;
    struct dirent *entry;
    int result = 0;

    if (scan_fd < 0) {
        return -1;
    }
    stream = fdopendir(scan_fd);
    if (stream == NULL) {
        close(scan_fd);
        return -1;
    }
    errno = 0;
    while ((entry = readdir(stream)) != NULL) {
        struct stat status;

        if (strcmp(entry->d_name, ".") == 0
            || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        if (fstatat(directory_fd, entry->d_name, &status,
                AT_SYMLINK_NOFOLLOW) != 0) {
            result = -1;
            break;
        }
        if (S_ISDIR(status.st_mode)) {
            int child_fd = openat(directory_fd, entry->d_name,
                O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
            int child_result;
            int child_close;

            if (child_fd < 0) {
                result = -1;
                break;
            }
            child_result = remove_test_contents(child_fd);
            child_close = close(child_fd);
            child_fd = -1;
            if (child_result != 0 || child_close != 0
                || unlinkat(directory_fd, entry->d_name, AT_REMOVEDIR) != 0) {
                result = -1;
                break;
            }
        } else if (unlinkat(directory_fd, entry->d_name, 0) != 0) {
            result = -1;
            break;
        }
        errno = 0;
    }
    if (entry == NULL && errno != 0) {
        result = -1;
    }
    {
        int saved = errno;
        if (closedir(stream) != 0 && result == 0) {
            return -1;
        }
        errno = saved;
    }
    return result;
}

static int remove_test_fixture(const char *path)
{
    int root_fd = open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    int result = 0;

    if (root_fd < 0) {
        return -1;
    }
    if (remove_test_contents(root_fd) != 0) {
        result = -1;
    }
    if (close(root_fd) != 0) {
        result = -1;
    }
    if (rmdir(path) != 0) {
        result = -1;
    }
    return result;
}

static int create_test_fixture(char *path, size_t path_size)
{
    char template[] = PROC17_TEST_TEMPLATE;
    mode_t previous_mask;
    int root_fd = -1;
    int repository_fd = -1;
    int result = -1;

    if (path_size < sizeof(template)) {
        errno = ENAMETOOLONG;
        return -1;
    }
    previous_mask = umask(0077);
    if (mkdtemp(template) == NULL) {
        umask(previous_mask);
        return -1;
    }
    memcpy(path, template, sizeof(template));
    root_fd = open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (root_fd < 0 || mkdirat(root_fd, "repo", 0700) != 0) {
        goto done;
    }
    repository_fd = openat(root_fd, "repo",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (repository_fd < 0 || mkdirat(repository_fd, "src", 0700) != 0) {
        goto done;
    }
    result = 0;

done:
    if (repository_fd >= 0) {
        close(repository_fd);
    }
    if (root_fd >= 0) {
        close(root_fd);
    }
    umask(previous_mask);
    if (result != 0) {
        remove_test_fixture(path);
        path[0] = '\0';
    }
    return result;
}

static int write_all_raw(int descriptor, const char *content, size_t length)
{
    size_t offset = 0;

    while (offset < length) {
        ssize_t written = write(descriptor, content + offset, length - offset);
        if (written < 0 && errno == EINTR) {
            continue;
        }
        if (written <= 0) {
            return -1;
        }
        offset += (size_t)written;
    }
    return 0;
}

static int open_test_parent(
    const char *fixture_path,
    const char *request_path,
    int *repository_fd_out,
    int *parent_fd_out,
    char *final_name,
    size_t final_name_size)
{
    char parent_path[PROC17_MAX_RELATIVE_PATH_BYTES + 1U];
    int fixture_fd = -1;
    int repository_fd = -1;
    int parent_fd = -1;

    if (split_target_path(request_path, strlen(request_path),
            parent_path, sizeof(parent_path), final_name, final_name_size) != 0) {
        return -1;
    }
    fixture_fd = open(fixture_path,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (fixture_fd < 0) {
        return -1;
    }
    repository_fd = openat(fixture_fd, "repo",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    close(fixture_fd);
    if (repository_fd < 0) {
        return -1;
    }
    parent_fd = openat(repository_fd, parent_path,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (parent_fd < 0) {
        close(repository_fd);
        return -1;
    }
    *repository_fd_out = repository_fd;
    *parent_fd_out = parent_fd;
    return 0;
}

static int prepare_test_target(
    const char *fixture_path,
    const char *request_path,
    enum proc17_fs_test_target target,
    const char *content)
{
    char final_name[PROC17_MAX_COMPONENT_BYTES + 1U];
    int repository_fd = -1;
    int parent_fd = -1;
    int target_fd = -1;
    int result = -1;

    if (target == PROC17_TARGET_ABSENT) {
        return 0;
    }
    if (open_test_parent(fixture_path, request_path, &repository_fd,
            &parent_fd, final_name, sizeof(final_name)) != 0) {
        return -1;
    }
    switch (target) {
    case PROC17_TARGET_REGULAR:
        target_fd = openat(parent_fd, final_name,
            O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
        if (target_fd >= 0
            && write_all_raw(target_fd, content, strlen(content)) == 0) {
            int close_result = close(target_fd);
            target_fd = -1;
            if (close_result == 0) {
                result = 0;
            }
        }
        break;
    case PROC17_TARGET_DIRECTORY:
        result = mkdirat(parent_fd, final_name, 0700);
        break;
    case PROC17_TARGET_SYMLINK:
        result = symlinkat("proc17-test-missing-referent", parent_fd, final_name);
        break;
    case PROC17_TARGET_FIFO:
        result = mkfifoat(parent_fd, final_name, 0600);
        break;
    default:
        errno = EINVAL;
        break;
    }
    if (target_fd >= 0) {
        close(target_fd);
    }
    close(parent_fd);
    close(repository_fd);
    return result;
}

static enum proc17_fs_test_target classify_test_target(mode_t mode)
{
    if (S_ISREG(mode)) {
        return PROC17_TARGET_REGULAR;
    }
    if (S_ISDIR(mode)) {
        return PROC17_TARGET_DIRECTORY;
    }
    if (S_ISLNK(mode)) {
        return PROC17_TARGET_SYMLINK;
    }
    if (S_ISFIFO(mode)) {
        return PROC17_TARGET_FIFO;
    }
    return PROC17_TARGET_ABSENT;
}

static int observe_test_result(
    const char *fixture_path,
    const char *request_path,
    struct proc17_fs_test_result *result)
{
    char final_name[PROC17_MAX_COMPONENT_BYTES + 1U];
    int repository_fd = -1;
    int parent_fd = -1;
    struct stat status;
    DIR *stream = NULL;
    int scan_fd = -1;

    test_final_content[0] = '\0';
    result->final_content = test_final_content;
    if (open_test_parent(fixture_path, request_path, &repository_fd,
            &parent_fd, final_name, sizeof(final_name)) != 0) {
        return -1;
    }
    if (fstatat(parent_fd, final_name, &status, AT_SYMLINK_NOFOLLOW) != 0) {
        if (errno != ENOENT) {
            close(parent_fd);
            close(repository_fd);
            return -1;
        }
        result->final_target = PROC17_TARGET_ABSENT;
    } else {
        result->final_target = classify_test_target(status.st_mode);
        result->final_mode = (unsigned int)(status.st_mode & 0777);
        if (result->final_target == PROC17_TARGET_REGULAR) {
            int file_fd = openat(parent_fd, final_name,
                O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
            size_t offset = 0;
            if (file_fd < 0) {
                close(parent_fd);
                close(repository_fd);
                return -1;
            }
            while (offset < PROC17_MAX_CONTENT_BYTES) {
                ssize_t count = read(file_fd, test_final_content + offset,
                    PROC17_MAX_CONTENT_BYTES - offset);
                if (count < 0 && errno == EINTR) {
                    continue;
                }
                if (count < 0) {
                    close(file_fd);
                    close(parent_fd);
                    close(repository_fd);
                    return -1;
                }
                if (count == 0) {
                    break;
                }
                offset += (size_t)count;
            }
            test_final_content[offset] = '\0';
            if (close(file_fd) != 0) {
                close(parent_fd);
                close(repository_fd);
                return -1;
            }
        }
    }

    scan_fd = dup(parent_fd);
    if (scan_fd < 0) {
        close(parent_fd);
        close(repository_fd);
        return -1;
    }
    stream = fdopendir(scan_fd);
    if (stream == NULL) {
        close(scan_fd);
        close(parent_fd);
        close(repository_fd);
        return -1;
    }
    while (1) {
        struct dirent *entry = readdir(stream);
        if (entry == NULL) {
            break;
        }
        if (strncmp(entry->d_name, PROC17_TEMP_PREFIX,
                sizeof(PROC17_TEMP_PREFIX) - 1U) == 0) {
            result->temp_entries++;
        }
    }
    if (closedir(stream) != 0
        || close(parent_fd) != 0
        || close(repository_fd) != 0) {
        return -1;
    }
    return 0;
}

static struct proc17_repository_handle *create_test_handle(
    const char *project_base,
    const char *repository_path)
{
    size_t project_base_length = strlen(project_base);
    size_t repository_path_length = strlen(repository_path);
    struct proc17_repository_handle *handle = calloc(1,
        sizeof(*handle) + project_base_length + repository_path_length + 2U);
    const char *stage;

    if (handle == NULL) {
        return NULL;
    }
    handle->project_base_fd = -1;
    handle->repository_fd = -1;
    handle->project_base_length = project_base_length;
    handle->repository_path_length = repository_path_length;
    memcpy(handle->paths, project_base, project_base_length + 1U);
    memcpy(handle->paths + project_base_length + 1U,
        repository_path, repository_path_length + 1U);
    if (open_identity_pair(project_base, repository_path,
            &handle->project_base_fd, &handle->repository_fd,
            &handle->project_base_identity, &handle->repository_identity,
            &stage) != 0) {
        (void)stage;
        free(handle);
        return NULL;
    }
    return handle;
}

int proc17_fs_run_test_case(
    const struct proc17_fs_test_case *test_case,
    struct proc17_fs_test_result *result)
{
    char fixture_path[sizeof(PROC17_TEST_TEMPLATE)] = {0};
    const char *request_path;
    const char *request_content;
    const char *initial_content;
    mode_t request_mode;
    struct proc17_repository_handle *handle = NULL;
    struct proc17_create_result create_result;
    struct proc17_read_result read_result;
    struct proc17_test_control control;
    int before_fds;
    int after_fds;
    int transaction_result;
    int result_code = -1;

    if (test_case == NULL || result == NULL) {
        errno = EINVAL;
        return -1;
    }
    request_path = test_case->request_path != NULL
        ? test_case->request_path : "src/main.lua";
    request_content = test_case->request_content != NULL
        ? test_case->request_content : "created\n";
    initial_content = test_case->initial_content != NULL
        ? test_case->initial_content : "before\n";
    request_mode = test_case->request_mode != 0
        ? (mode_t)test_case->request_mode : PROC17_FILE_MODE;
    before_fds = count_open_descriptors();
    if (before_fds < 0) {
        return -1;
    }
    memset(result, 0, sizeof(*result));
    if (create_test_fixture(fixture_path, sizeof(fixture_path)) != 0
        || prepare_test_target(fixture_path, request_path,
            test_case->initial_target, initial_content) != 0) {
        goto done;
    }
    handle = create_test_handle(fixture_path, "repo");
    if (handle == NULL) {
        goto done;
    }
    memset(&control, 0, sizeof(control));
    control.test_case = test_case;
    control.parent_fd = -1;
    control.initial_target_absent =
        test_case->initial_target == PROC17_TARGET_ABSENT;
    active_test_control = &control;

    if (test_case->operation == PROC17_OPERATION_READ) {
        size_t hard_limit = test_case->read_limit < PROC17_MAX_READ_BYTES
            ? test_case->read_limit + 1U : PROC17_MAX_READ_BYTES;

        transaction_result = read_file_transaction(handle,
            request_path, strlen(request_path), hard_limit, &read_result);
        active_test_control = NULL;
        result->read_attempts = control.read_attempts;
        result->error_code = transaction_result == 0
            ? NULL : read_result.code;
        if (transaction_result == 0) {
            result->outcome = PROC17_OUTCOME_OBSERVED;
            if (read_result.target_kind == PROC17_READ_TARGET_REGULAR) {
                result->observed_target = PROC17_TARGET_REGULAR;
                result->observed_bytes = read_result.bytes;
                if (read_result.bytes > PROC17_MAX_READ_BYTES) {
                    free(read_result.content);
                    read_result.content = NULL;
                    goto done;
                }
                memcpy(test_observed_content, read_result.content,
                    read_result.bytes);
                test_observed_content[read_result.bytes] = '\0';
                result->observed_content = test_observed_content;
                result->read_truncated =
                    read_result.bytes > test_case->read_limit;
            } else if (read_result.target_kind == PROC17_READ_TARGET_MISSING) {
                result->observed_target = PROC17_TARGET_ABSENT;
            } else {
                result->observed_target = test_case->initial_target;
            }
        } else {
            result->outcome = PROC17_OUTCOME_WORLD_FAILURE;
        }
        free(read_result.content);
        if (observe_test_result(fixture_path, request_path, result) != 0) {
            goto done;
        }
        result_code = 0;
        goto done;
    }
    transaction_result = create_file_transaction(handle,
        request_path, strlen(request_path), request_content,
        strlen(request_content), request_mode, &create_result);
    active_test_control = NULL;

    result->temp_open_attempts = control.temp_open_attempts;
    result->write_attempts = control.write_attempts;
    result->partial_final_observed = control.partial_final_observed;
    result->mutation_primitive_entered =
        create_result.mutation_primitive_entered;
    result->file_writes = create_result.mutation_primitive_entered ? 1U : 0U;
    result->published = create_result.published;
    result->temp_residue_reported = create_result.has_temp_residue;
    result->temp_residue_bytes = create_result.has_temp_residue
        ? strlen(create_result.temp_name) : 0;
    if (transaction_result == 0) {
        result->outcome = PROC17_OUTCOME_CREATED;
    } else if (strcmp(create_result.code, "target_exists") == 0) {
        result->outcome = PROC17_OUTCOME_TARGET_EXISTS;
    } else if (strcmp(create_result.class_name, "ambiguous") == 0) {
        result->outcome = PROC17_OUTCOME_AMBIGUOUS;
    } else {
        result->outcome = PROC17_OUTCOME_WORLD_FAILURE;
    }
    if (observe_test_result(fixture_path, request_path, result) != 0) {
        goto done;
    }
    result_code = 0;

done:
    active_test_control = NULL;
    if (handle != NULL) {
        (void)close_handle_descriptors(handle);
        free(handle);
    }
    if (fixture_path[0] != '\0' && remove_test_fixture(fixture_path) != 0) {
        result_code = -1;
    }
    after_fds = count_open_descriptors();
    if (after_fds < 0) {
        return -1;
    }
    result->open_fd_delta = after_fds - before_fds;
    return result_code;
}

int proc17_fs_test_close_twice(void)
{
    char fixture_path[sizeof(PROC17_TEST_TEMPLATE)] = {0};
    struct proc17_repository_handle *handle;
    int before_fds = count_open_descriptors();
    int first;
    int second;
    int after_fds;

    if (before_fds < 0
        || create_test_fixture(fixture_path, sizeof(fixture_path)) != 0) {
        return -1;
    }
    handle = create_test_handle(fixture_path, "repo");
    if (handle == NULL) {
        remove_test_fixture(fixture_path);
        return -1;
    }
    first = close_handle_descriptors(handle);
    second = close_handle_descriptors(handle);
    free(handle);
    if (remove_test_fixture(fixture_path) != 0) {
        return -1;
    }
    after_fds = count_open_descriptors();
    return first == 0 && second == 0 && after_fds == before_fds ? 0 : -1;
}

#endif

int luaopen_proc17_repository_fs(lua_State *L)
{
    if (luaL_newmetatable(L, PROC17_HANDLE_METATABLE)) {
        lua_pushcfunction(L, handle_gc);
        lua_setfield(L, -2, "__gc");
        lua_pushcfunction(L, handle_tostring);
        lua_setfield(L, -2, "__tostring");
        lua_pushliteral(L, PROC17_HANDLE_TAG);
        lua_setfield(L, -2, "__metatable");
        lua_pushliteral(L, PROC17_HANDLE_TAG);
        lua_setfield(L, -2, "__name");
    }
    lua_pop(L, 1);

    lua_createtable(L, 0, 10);
    set_string(L, "protocol_version", PROC17_NATIVE_PROTOCOL);
    set_string(L, "abi_version", PROC17_NATIVE_ABI);
    set_string(L, "provider_id", PROC17_PROVIDER_ID);
    set_string(L, "contract_id", PROC17_CONTRACT_ID);

    lua_createtable(L, 0, 5);
    set_integer(L, "max_relative_path_bytes", PROC17_MAX_RELATIVE_PATH_BYTES);
    set_integer(L, "max_component_bytes", PROC17_MAX_COMPONENT_BYTES);
    set_integer(L, "max_components", PROC17_MAX_COMPONENTS);
    set_integer(L, "max_content_bytes", PROC17_MAX_CONTENT_BYTES);
    set_integer(L, "file_mode", 0600);
    lua_setfield(L, -2, "limits");

    lua_pushcfunction(L, open_repository);
    lua_setfield(L, -2, "open_repository");
    lua_pushcfunction(L, revalidate);
    lua_setfield(L, -2, "revalidate");
    lua_pushcfunction(L, create_text_file);
    lua_setfield(L, -2, "create_text_file");
    lua_pushcfunction(L, read_text_file);
    lua_setfield(L, -2, "read_text_file");
    lua_pushcfunction(L, inventory_tree);
    lua_setfield(L, -2, "inventory_tree");
    lua_pushcfunction(L, close_repository);
    lua_setfield(L, -2, "close");
    return 1;
}
