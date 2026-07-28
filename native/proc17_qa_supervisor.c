#define _GNU_SOURCE

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <errno.h>
#include <fcntl.h>
#include <linux/audit.h>
#include <linux/capability.h>
#include <linux/filter.h>
#include <linux/mount.h>
#include <linux/sched.h>
#include <linux/seccomp.h>
#include <linux/stat.h>
#include <limits.h>
#include <poll.h>
#include <sched.h>
#include <signal.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/prctl.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/syscall.h>
#include <sys/timerfd.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "generated/proc17_qa_prebuild.h"
#include "proc17_qa_policy.h"
#include "proc17_qa_wire.h"
#include "proc17_sha256.h"

#define PROC17_QA_PROBE_RESULT_BYTES 292U
#define PROC17_QA_SELF_MAX_BYTES (64U * 1024U * 1024U)
#define PROC17_QA_PROBE_OUTPUT_BYTES 4096U
#define PROC17_QA_SOURCE_POLICY_DETACHED_MOUNT_V0 1U
#define PROC17_QA_SOURCE_MOUNT_RDONLY (1U << 0)
#define PROC17_QA_SOURCE_MOUNT_NOSUID (1U << 1)
#define PROC17_QA_SOURCE_MOUNT_NODEV (1U << 2)
#define PROC17_QA_SOURCE_MOUNT_NOEXEC (1U << 3)
#define PROC17_QA_SOURCE_MOUNT_REQUIRED \
    (PROC17_QA_SOURCE_MOUNT_RDONLY | PROC17_QA_SOURCE_MOUNT_NOSUID \
    | PROC17_QA_SOURCE_MOUNT_NODEV | PROC17_QA_SOURCE_MOUNT_NOEXEC)
#define PROC17_QA_CANDIDATE_LUA_ERROR_EXIT 70

enum proc17_qa_probe_status {
    PROC17_QA_PROBE_OK = 0,
    PROC17_QA_PROBE_SELF_FAILED = 1,
    PROC17_QA_PROBE_REQUEST_FAILED = 2,
    PROC17_QA_PROBE_SOURCE_FAILED = 3,
    PROC17_QA_PROBE_NAMESPACE_FAILED = 4,
    PROC17_QA_PROBE_MAPPING_FAILED = 5,
    PROC17_QA_PROBE_MOUNT_FAILED = 6,
    PROC17_QA_PROBE_LUA_FAILED = 7,
    PROC17_QA_PROBE_POLICY_FAILED = 8,
    PROC17_QA_PROBE_REAP_FAILED = 9,
    PROC17_QA_PROBE_MOUNT_PRIVATE_FAILED = 10,
    PROC17_QA_PROBE_MOUNT_TMPFS_FAILED = 11,
    PROC17_QA_PROBE_MOUNT_ROOT_FAILED = 12,
    PROC17_QA_PROBE_MOUNT_SOURCE_FAILED = 13,
    PROC17_QA_PROBE_MOUNT_SOURCE_POLICY_FAILED = 14,
    PROC17_QA_PROBE_MOUNT_SCRATCH_FAILED = 15,
    PROC17_QA_PROBE_MOUNT_PIVOT_FAILED = 16,
    PROC17_QA_PROBE_MOUNT_ROOT_POLICY_FAILED = 17,
    PROC17_QA_PROBE_RESOURCE_LIMIT_FAILED = 18,
    PROC17_QA_PROBE_CANDIDATE_ENVIRONMENT_FAILED = 19,
    PROC17_QA_PROBE_LUA_STATE_FAILED = 20,
    PROC17_QA_PROBE_LUA_LOAD_FAILED = 21,
    PROC17_QA_PROBE_LUA_RUNTIME_FAILED = 22,
    PROC17_QA_PROBE_LUA_ASSERT_BASE = 22,
    PROC17_QA_PROBE_OUTPUT_PIPE_FAILED = 38,
    PROC17_QA_PROBE_CANDIDATE_FORK_FAILED = 39,
    PROC17_QA_PROBE_CANDIDATE_STDIO_FAILED = 40,
    PROC17_QA_PROBE_OUTPUT_FLAGS_FAILED = 41,
    PROC17_QA_PROBE_CANDIDATE_PIDFD_FAILED = 42,
    PROC17_QA_PROBE_OUTPUT_EMPTY = 43,
    PROC17_QA_PROBE_SOURCE_MUTATED = 44,
    PROC17_QA_PROBE_SCRATCH_MISSING = 45,
    PROC17_QA_PROBE_OUTPUT_WRITE_FAILED = 46,
    PROC17_QA_PROBE_SOURCE_LOCATOR_FAILED = 47,
    PROC17_QA_PROBE_SOURCE_SELF_BIND_FAILED = 48,
    PROC17_QA_PROBE_SOURCE_CLONE_FAILED = 49,
    PROC17_QA_PROBE_SOURCE_DETACH_FAILED = 50,
    PROC17_QA_PROBE_SOURCE_HARDEN_FAILED = 51,
    PROC17_QA_PROBE_SOURCE_ATTACH_FAILED = 52,
    PROC17_QA_PROBE_SOURCE_ATTEST_FAILED = 53,
    PROC17_QA_PROBE_SOURCE_READLINK_FAILED = 54,
    PROC17_QA_PROBE_SOURCE_DELETED_FAILED = 55,
    PROC17_QA_PROBE_SOURCE_LOCATOR_IDENTITY_FAILED = 56,
};

struct proc17_qa_root_identity {
    uint64_t device;
    uint64_t inode;
    uint64_t mount_id;
};

struct proc17_qa_source_stage {
    int source_fd;
    int detached_mount_fd;
    int temporary_self_bind_live;
    int detached_attached;
    int host_tmp_hidden;
    int candidate_started;
    struct proc17_qa_root_identity original;
    struct proc17_qa_root_identity detached;
    struct proc17_qa_root_identity attached;
    uint32_t mount_policy_flags;
};

struct proc17_qa_run_request {
    unsigned char transaction[PROC17_SHA256_BYTES];
    unsigned char witness[PROC17_SHA256_BYTES];
    unsigned char profile[PROC17_SHA256_BYTES];
    unsigned char environment[PROC17_SHA256_BYTES];
    struct proc17_qa_root_identity root;
    uint64_t limits[PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS];
    uint32_t expected_exit;
    char entrypoint[1025];
};

struct proc17_qa_run_metrics {
    uint64_t wall_ms;
    uint64_t user_cpu_ms;
    uint64_t system_cpu_ms;
    uint64_t max_rss_bytes;
};

struct proc17_qa_allocator {
    size_t used;
    size_t ceiling;
};

union proc17_qa_allocation_header {
    max_align_t alignment;
    size_t bytes;
};

static int write_exact(int descriptor, const void *bytes, size_t length)
{
    const unsigned char *cursor = bytes;

    while (length > 0U) {
        ssize_t written = write(descriptor, cursor, length);
        if (written < 0 && errno == EINTR) {
            continue;
        }
        if (written <= 0) {
            return -1;
        }
        cursor += (size_t)written;
        length -= (size_t)written;
    }
    return 0;
}

static int read_exact(int descriptor, void *bytes, size_t length)
{
    unsigned char *cursor = bytes;
    while (length > 0U) {
        ssize_t observed = read(descriptor, cursor, length);
        if (observed < 0 && errno == EINTR) continue;
        if (observed <= 0) return -1;
        cursor += (size_t)observed;
        length -= (size_t)observed;
    }
    return 0;
}

static int read_frame(int descriptor, unsigned char *frame, size_t *frame_bytes)
{
    size_t used = 0;

    for (;;) {
        ssize_t observed;
        if (used == PROC17_QA_WIRE_MAX_FRAME_BYTES) {
            unsigned char overflow;
            observed = read(descriptor, &overflow, 1U);
            if (observed == 0) {
                break;
            }
            return -1;
        }
        observed = read(descriptor, frame + used,
            PROC17_QA_WIRE_MAX_FRAME_BYTES - used);
        if (observed < 0 && errno == EINTR) {
            continue;
        }
        if (observed < 0) {
            return -1;
        }
        if (observed == 0) {
            break;
        }
        used += (size_t)observed;
    }
    *frame_bytes = used;
    return 0;
}

static int hash_descriptor(
    int descriptor,
    size_t ceiling,
    unsigned char output[PROC17_SHA256_BYTES])
{
    struct proc17_sha256 context;
    unsigned char buffer[16384];
    off_t offset = 0;
    size_t total = 0;

    proc17_sha256_init(&context);
    for (;;) {
        ssize_t observed = pread(descriptor, buffer, sizeof(buffer), offset);
        if (observed < 0 && errno == EINTR) {
            continue;
        }
        if (observed < 0) {
            return -1;
        }
        if (observed == 0) {
            break;
        }
        if ((size_t)observed > ceiling - total) {
            return -1;
        }
        proc17_sha256_update(&context, buffer, (size_t)observed);
        total += (size_t)observed;
        offset += observed;
    }
    proc17_sha256_final(&context, output);
    return 0;
}

static int observe_root(int descriptor, struct proc17_qa_root_identity *identity)
{
    struct stat status;
    struct statx extended;

    memset(&extended, 0, sizeof(extended));
    if (fstat(descriptor, &status) != 0 || !S_ISDIR(status.st_mode)
        || statx(descriptor, "", AT_EMPTY_PATH | AT_STATX_SYNC_AS_STAT,
            STATX_TYPE | STATX_MNT_ID, &extended) != 0
        || (extended.stx_mask & STATX_MNT_ID) == 0) {
        return -1;
    }
    identity->device = (uint64_t)(uintmax_t)status.st_dev;
    identity->inode = (uint64_t)(uintmax_t)status.st_ino;
    identity->mount_id = extended.stx_mnt_id;
    return 0;
}

static int sha_self(unsigned char output[PROC17_SHA256_BYTES])
{
    return hash_descriptor(6, PROC17_QA_SELF_MAX_BYTES, output);
}

static int exact_static_lua_selftest(void)
{
    static const unsigned char expected[PROC17_SHA256_BYTES] = {
        0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14,
        0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f, 0xb9, 0x24,
        0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c,
        0xa4, 0x95, 0x99, 0x1b, 0x78, 0x52, 0xb8, 0x55,
    };
    unsigned char observed[PROC17_SHA256_BYTES];
    lua_State *state;

    proc17_sha256_bytes("", 0U, observed);
    if (memcmp(observed, expected, sizeof(expected)) != 0
        || LUA_VERSION_NUM != 504) {
        return -1;
    }
    state = luaL_newstate();
    if (state == NULL) {
        return -1;
    }
    lua_pushliteral(state, "Lua 5.4");
    if (strcmp(lua_tostring(state, -1), LUA_VERSION) != 0) {
        lua_close(state);
        return -1;
    }
    lua_close(state);
    return 0;
}

static int set_limit(int resource, uint64_t value)
{
    struct rlimit limit;
    limit.rlim_cur = (rlim_t)value;
    limit.rlim_max = (rlim_t)value;
    return setrlimit(resource, &limit);
}

static int apply_candidate_limits(void)
{
    return set_limit(RLIMIT_CPU, PROC17_QA_CPU_TIME_MS / 1000U) == 0
        && set_limit(RLIMIT_AS, PROC17_QA_ADDRESS_SPACE_BYTES) == 0
        && set_limit(RLIMIT_NOFILE, PROC17_QA_MAX_OPEN_FILES) == 0
        && set_limit(RLIMIT_FSIZE, PROC17_QA_MAX_FILE_BYTES) == 0
        && set_limit(RLIMIT_NPROC, PROC17_QA_MAX_PROCESSES) == 0
        && set_limit(RLIMIT_STACK, PROC17_QA_STACK_BYTES) == 0
        && set_limit(RLIMIT_CORE, 0U) == 0 ? 0 : -1;
}

static int drop_capabilities(void)
{
    struct __user_cap_header_struct header;
    struct __user_cap_data_struct data[2];
    int capability;

    for (capability = 0; capability <= CAP_LAST_CAP; capability++) {
        if (prctl(PR_CAPBSET_DROP, capability, 0L, 0L, 0L) != 0
            && errno != EINVAL) {
            return -1;
        }
    }
    memset(&header, 0, sizeof(header));
    memset(data, 0, sizeof(data));
    header.version = _LINUX_CAPABILITY_VERSION_3;
    if (syscall(SYS_capset, &header, data) != 0
        || prctl(PR_CAP_AMBIENT, PR_CAP_AMBIENT_CLEAR_ALL, 0L, 0L, 0L) != 0
        || prctl(PR_SET_NO_NEW_PRIVS, 1L, 0L, 0L, 0L) != 0) {
        return -1;
    }
    return 0;
}

static int install_candidate_seccomp(void)
{
    static const int allowed[] = {
        SYS_read, SYS_write, SYS_readv, SYS_writev, SYS_close,
        SYS_openat, SYS_openat2, SYS_newfstatat, SYS_fstat, SYS_statx,
        SYS_lseek, SYS_pread64, SYS_fcntl, SYS_readlinkat, SYS_access,
        SYS_faccessat2, SYS_getcwd, SYS_getdents64,
        SYS_mkdir, SYS_mkdirat, SYS_unlink, SYS_unlinkat,
        SYS_rename, SYS_renameat, SYS_renameat2, SYS_symlinkat,
        SYS_ftruncate, SYS_fsync, SYS_fdatasync, SYS_umask,
        SYS_brk, SYS_mmap, SYS_mprotect, SYS_munmap, SYS_mremap,
        SYS_madvise, SYS_rt_sigaction, SYS_rt_sigprocmask,
        SYS_rt_sigreturn, SYS_sigaltstack, SYS_clock_gettime,
        SYS_gettimeofday, SYS_time, SYS_nanosleep, SYS_clock_nanosleep,
        SYS_futex, SYS_set_tid_address, SYS_set_robust_list, SYS_rseq,
        SYS_arch_prctl, SYS_getpid, SYS_gettid, SYS_getuid, SYS_geteuid,
        SYS_getgid, SYS_getegid, SYS_uname, SYS_getrandom,
        SYS_exit, SYS_exit_group,
    };
    struct sock_filter filter[5U + 2U * (sizeof(allowed) / sizeof(allowed[0]))];
    struct sock_fprog program;
    size_t index = 0;
    size_t allowed_index;

    filter[index++] = (struct sock_filter)BPF_STMT(
        BPF_LD | BPF_W | BPF_ABS, offsetof(struct seccomp_data, arch));
    filter[index++] = (struct sock_filter)BPF_JUMP(
        BPF_JMP | BPF_JEQ | BPF_K, AUDIT_ARCH_X86_64, 1, 0);
    filter[index++] = (struct sock_filter)BPF_STMT(
        BPF_RET | BPF_K, SECCOMP_RET_KILL_PROCESS);
    filter[index++] = (struct sock_filter)BPF_STMT(
        BPF_LD | BPF_W | BPF_ABS, offsetof(struct seccomp_data, nr));
    for (allowed_index = 0;
            allowed_index < sizeof(allowed) / sizeof(allowed[0]);
            allowed_index++) {
        filter[index++] = (struct sock_filter)BPF_JUMP(
            BPF_JMP | BPF_JEQ | BPF_K, (uint32_t)allowed[allowed_index], 0, 1);
        filter[index++] = (struct sock_filter)BPF_STMT(
            BPF_RET | BPF_K, SECCOMP_RET_ALLOW);
    }
    filter[index++] = (struct sock_filter)BPF_STMT(
        BPF_RET | BPF_K, SECCOMP_RET_KILL_PROCESS);
    program.len = (unsigned short)index;
    program.filter = filter;
    return syscall(SYS_seccomp, SECCOMP_SET_MODE_FILTER, 0U, &program) == 0
        ? 0 : -1;
}

static void *bounded_lua_allocator(
    void *opaque,
    void *pointer,
    size_t old_size,
    size_t new_size)
{
    struct proc17_qa_allocator *allocator = opaque;
    union proc17_qa_allocation_header *header;
    size_t prior = 0;
    size_t total;
    (void)old_size;

    if (pointer != NULL) {
        header = (union proc17_qa_allocation_header *)pointer - 1;
        prior = header->bytes;
    }
    if (new_size == 0U) {
        if (pointer != NULL) {
            allocator->used -= prior;
            free(header);
        }
        return NULL;
    }
    if (new_size > allocator->ceiling - (allocator->used - prior)
        || new_size > SIZE_MAX - sizeof(*header)) {
        return NULL;
    }
    total = sizeof(*header) + new_size;
    header = pointer == NULL ? malloc(total) : realloc(header, total);
    if (header == NULL) {
        return NULL;
    }
    allocator->used = allocator->used - prior + new_size;
    header->bytes = new_size;
    return header + 1;
}

static void open_restricted_libraries(lua_State *state)
{
    static const struct {
        const char *name;
        lua_CFunction function;
    } libraries[] = {
        {LUA_GNAME, luaopen_base},
        {LUA_LOADLIBNAME, luaopen_package},
        {LUA_COLIBNAME, luaopen_coroutine},
        {LUA_TABLIBNAME, luaopen_table},
        {LUA_IOLIBNAME, luaopen_io},
        {LUA_OSLIBNAME, luaopen_os},
        {LUA_STRLIBNAME, luaopen_string},
        {LUA_MATHLIBNAME, luaopen_math},
        {LUA_UTF8LIBNAME, luaopen_utf8},
    };
    size_t index;

    for (index = 0; index < sizeof(libraries) / sizeof(libraries[0]); index++) {
        luaL_requiref(state, libraries[index].name, libraries[index].function, 1);
        lua_pop(state, 1);
    }
}

static void remove_field(lua_State *state, const char *table, const char *field)
{
    lua_getglobal(state, table);
    lua_pushnil(state);
    lua_setfield(state, -2, field);
    lua_pop(state, 1);
}

static int run_restricted_lua(const char *entrypoint, int probe_mode)
{
    struct proc17_qa_allocator allocator = {
        .used = 0,
        .ceiling = (size_t)PROC17_QA_RUNTIME_HEAP_BYTES,
    };
    lua_State *state = lua_newstate(bounded_lua_allocator, &allocator);
    int result = -1;

    if (state == NULL) {
        return PROC17_QA_PROBE_LUA_STATE_FAILED;
    }
    open_restricted_libraries(state);
    lua_pushnil(state);
    lua_setglobal(state, "debug");
    remove_field(state, "io", "popen");
    remove_field(state, "io", "tmpfile");
    remove_field(state, "os", "execute");
    remove_field(state, "os", "tmpname");

    lua_getglobal(state, "package");
    lua_pushliteral(state, "./?.lua;./?/init.lua");
    lua_setfield(state, -2, "path");
    /* package.cpath is closed before any candidate chunk can execute. */
    lua_pushliteral(state, "");
    lua_setfield(state, -2, "cpath");
    lua_pushnil(state);
    lua_setfield(state, -2, "loadlib");
    lua_getfield(state, -1, "searchers");
    lua_pushnil(state);
    lua_rawseti(state, -2, 3);
    lua_pushnil(state);
    lua_rawseti(state, -2, 4);
    lua_pop(state, 2);

    lua_createtable(state, 1, 0);
    lua_pushstring(state, entrypoint);
    lua_rawseti(state, -2, 0);
    lua_setglobal(state, "arg");

    if (luaL_loadfilex(state, entrypoint, "t") != LUA_OK) {
        result = probe_mode ? PROC17_QA_PROBE_LUA_LOAD_FAILED
            : PROC17_QA_CANDIDATE_LUA_ERROR_EXIT;
    } else if (lua_pcall(state, 0, 0, 0) != LUA_OK) {
        const char *message = lua_tostring(state, -1);
        int assertion;
        result = probe_mode ? PROC17_QA_PROBE_LUA_RUNTIME_FAILED
            : PROC17_QA_CANDIDATE_LUA_ERROR_EXIT;
        for (assertion = 1; probe_mode && assertion <= 15; assertion++) {
            char marker[4];
            snprintf(marker, sizeof(marker), "P%02d", assertion);
            if (message != NULL && strstr(message, marker) != NULL) {
                result = PROC17_QA_PROBE_LUA_ASSERT_BASE + assertion;
                break;
            }
        }
    } else {
        result = PROC17_QA_PROBE_OK;
    }
    lua_close(state);
    return result;
}

static int prepare_candidate(void)
{
    if (clearenv() != 0
        || setenv("HOME", "/qa/scratch/home", 1) != 0
        || setenv("TMPDIR", "/qa/scratch/tmp", 1) != 0
        || setenv("LANG", "C", 1) != 0
        || setenv("LC_ALL", "C", 1) != 0
        || setenv("TZ", "UTC", 1) != 0
        || chdir("/qa/source") != 0) {
        return PROC17_QA_PROBE_CANDIDATE_ENVIRONMENT_FAILED;
    }
    if (apply_candidate_limits() != 0) {
        return PROC17_QA_PROBE_RESOURCE_LIMIT_FAILED;
    }
    if (drop_capabilities() != 0 || install_candidate_seccomp() != 0) {
        return PROC17_QA_PROBE_POLICY_FAILED;
    }
    return PROC17_QA_PROBE_OK;
}

static int drain_probe_output(
    int descriptor,
    pid_t child,
    int pidfd,
    int require_output)
{
    struct itimerspec timer_spec;
    struct pollfd poll_fds[3];
    unsigned char output[512];
    struct proc17_sha256 output_hash;
    size_t output_bytes = 0;
    int timerfd;
    int child_ready = 0;
    int output_eof = 0;
    int status = 0;

    timerfd = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);
    if (timerfd < 0) {
        return PROC17_QA_PROBE_REAP_FAILED;
    }
    memset(&timer_spec, 0, sizeof(timer_spec));
    timer_spec.it_value.tv_sec = (time_t)(
        (PROC17_QA_WALL_TIME_MS + PROC17_QA_SETUP_GRACE_MS) / 1000U);
    if (timerfd_settime(timerfd, 0, &timer_spec, NULL) != 0) {
        close(timerfd);
        return PROC17_QA_PROBE_REAP_FAILED;
    }
    proc17_sha256_init(&output_hash);
    while (!child_ready || !output_eof) {
        int polled;
        poll_fds[0] = (struct pollfd){.fd = descriptor, .events = POLLIN | POLLHUP};
        poll_fds[1] = (struct pollfd){.fd = pidfd, .events = POLLIN};
        poll_fds[2] = (struct pollfd){.fd = timerfd, .events = POLLIN};
        polled = poll(poll_fds, 3, -1);
        if (polled < 0 && errno == EINTR) {
            continue;
        }
        if (polled < 0 || (poll_fds[2].revents & POLLIN) != 0) {
            (void)kill(child, SIGKILL);
            (void)waitpid(child, NULL, 0);
            close(timerfd);
            return PROC17_QA_PROBE_REAP_FAILED;
        }
        if ((poll_fds[0].revents & (POLLIN | POLLHUP)) != 0) {
            for (;;) {
                ssize_t count = read(descriptor, output, sizeof(output));
                if (count > 0) {
                    if ((size_t)count > PROC17_QA_PROBE_OUTPUT_BYTES - output_bytes) {
                        (void)kill(child, SIGKILL);
                        (void)waitpid(child, NULL, 0);
                        close(timerfd);
                        return PROC17_QA_PROBE_REAP_FAILED;
                    }
                    proc17_sha256_update(&output_hash, output, (size_t)count);
                    output_bytes += (size_t)count;
                    continue;
                }
                if (count == 0) {
                    output_eof = 1;
                } else if (errno != EAGAIN && errno != EWOULDBLOCK
                    && errno != EINTR) {
                    close(timerfd);
                    return PROC17_QA_PROBE_REAP_FAILED;
                }
                break;
            }
        }
        if ((poll_fds[1].revents & POLLIN) != 0) {
            child_ready = 1;
        }
    }
    close(timerfd);
    if (waitpid(child, &status, 0) != child) {
        return PROC17_QA_PROBE_REAP_FAILED;
    }
    if (WIFSIGNALED(status) && WTERMSIG(status) == SIGSYS) {
        return PROC17_QA_PROBE_POLICY_FAILED;
    }
    if (WIFSIGNALED(status)) {
        return 64 + WTERMSIG(status);
    }
    if (!WIFEXITED(status)) {
        return PROC17_QA_PROBE_LUA_FAILED;
    }
    if (WEXITSTATUS(status) != 0) {
        return WEXITSTATUS(status);
    }
    if (require_output && output_bytes == 0U) {
        return PROC17_QA_PROBE_OUTPUT_EMPTY;
    }
    {
        unsigned char ignored[PROC17_SHA256_BYTES];
        proc17_sha256_final(&output_hash, ignored);
    }
    return PROC17_QA_PROBE_OK;
}

static int run_lua_task(const char *entrypoint, int probe_mode)
{
    int output_pipe[2];
    int read_end = -1;
    int write_end = -1;
    pid_t child;
    int pidfd;
    int flags;

    if (pipe2(output_pipe, O_CLOEXEC) != 0) {
        return PROC17_QA_PROBE_OUTPUT_PIPE_FAILED;
    }
    read_end = fcntl(output_pipe[0], F_DUPFD_CLOEXEC, 10);
    write_end = fcntl(output_pipe[1], F_DUPFD_CLOEXEC, 10);
    close(output_pipe[0]);
    close(output_pipe[1]);
    if (read_end < 0 || write_end < 0) {
        if (read_end >= 0) close(read_end);
        if (write_end >= 0) close(write_end);
        return PROC17_QA_PROBE_OUTPUT_PIPE_FAILED;
    }
    child = fork();
    if (child < 0) {
        close(read_end);
        close(write_end);
        return PROC17_QA_PROBE_CANDIDATE_FORK_FAILED;
    }
    if (child == 0) {
        close(read_end);
        close(STDIN_FILENO);
        if (dup2(write_end, STDOUT_FILENO) < 0
            || dup2(write_end, STDERR_FILENO) < 0) {
            _exit(PROC17_QA_PROBE_CANDIDATE_STDIO_FAILED);
        }
        close(write_end);
        if (setvbuf(stdout, NULL, _IONBF, 0) != 0
            || setvbuf(stderr, NULL, _IONBF, 0) != 0) {
            _exit(PROC17_QA_PROBE_CANDIDATE_STDIO_FAILED);
        }
        (void)syscall(SYS_close_range, 3U, UINT_MAX, 0U);
        {
            int preparation = prepare_candidate();
            if (preparation != PROC17_QA_PROBE_OK) {
                _exit(preparation);
            }
        }
        {
            int lua_status = run_restricted_lua(entrypoint, probe_mode);
            if (lua_status != PROC17_QA_PROBE_OK) {
                _exit(lua_status);
            }
        }
        {
            if (probe_mode) {
                static const char output_witness[] =
                    "proc17 qa output pipe witness\n";
                if (write_exact(STDOUT_FILENO, output_witness,
                        sizeof(output_witness) - 1U) != 0) {
                    _exit(PROC17_QA_PROBE_OUTPUT_WRITE_FAILED);
                }
            }
        }
        _exit(0);
    }
    close(write_end);
    flags = fcntl(read_end, F_GETFL);
    if (flags < 0 || fcntl(read_end, F_SETFL, flags | O_NONBLOCK) != 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
        close(read_end);
        return PROC17_QA_PROBE_OUTPUT_FLAGS_FAILED;
    }
    pidfd = (int)syscall(SYS_pidfd_open, child, 0U);
    if (pidfd < 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
        close(read_end);
        return PROC17_QA_PROBE_CANDIDATE_PIDFD_FAILED;
    }
    flags = drain_probe_output(read_end, child, pidfd, probe_mode);
    close(pidfd);
    close(read_end);
    return flags;
}

static int run_denial_probe(int kind)
{
    pid_t child = fork();
    int status;

    if (child < 0) {
        return -1;
    }
    if (child == 0) {
        char *const arguments[] = {(char *)"denied", NULL};
        char *const environment[] = {NULL};
        if (apply_candidate_limits() != 0 || drop_capabilities() != 0
            || install_candidate_seccomp() != 0) {
            _exit(122);
        }
        if (kind == 0) {
            (void)syscall(SYS_clone3, NULL, 0U);
        } else if (kind == 1) {
            (void)syscall(SYS_execveat, -1, "", arguments, environment,
                AT_EMPTY_PATH);
        } else {
            (void)syscall(SYS_socket, AF_INET, SOCK_STREAM, 0);
        }
        _exit(123);
    }
    if (waitpid(child, &status, 0) != child
        || !WIFSIGNALED(status) || WTERMSIG(status) != SIGSYS) {
        return -1;
    }
    return 0;
}

static int same_mount_identity(
    const struct proc17_qa_root_identity *left,
    const struct proc17_qa_root_identity *right)
{
    return left->device == right->device && left->inode == right->inode
        && left->mount_id == right->mount_id;
}

static int same_mount_object(
    const struct proc17_qa_root_identity *left,
    const struct proc17_qa_root_identity *right)
{
    return left->device == right->device && left->inode == right->inode;
}

static int observe_path_root(
    const char *path,
    struct proc17_qa_root_identity *identity)
{
    int descriptor = open(path, O_PATH | O_CLOEXEC | O_DIRECTORY | O_NOFOLLOW);
    int result;
    if (descriptor < 0) {
        return -1;
    }
    result = observe_root(descriptor, identity);
    if (close(descriptor) != 0) {
        return -1;
    }
    return result;
}

static int source_mount_flags(int descriptor, uint32_t *flags)
{
    struct statvfs status;
    uint32_t observed = 0;
    if (fstatvfs(descriptor, &status) != 0) {
        return -1;
    }
    if ((status.f_flag & ST_RDONLY) != 0) observed |= PROC17_QA_SOURCE_MOUNT_RDONLY;
    if ((status.f_flag & ST_NOSUID) != 0) observed |= PROC17_QA_SOURCE_MOUNT_NOSUID;
    if ((status.f_flag & ST_NODEV) != 0) observed |= PROC17_QA_SOURCE_MOUNT_NODEV;
    if ((status.f_flag & ST_NOEXEC) != 0) observed |= PROC17_QA_SOURCE_MOUNT_NOEXEC;
    *flags = observed;
    return 0;
}

static int mount_isolated_world(
    int source_fd,
    struct proc17_qa_source_stage *stage)
{
    static const char root[] = "/tmp/proc17-qa-root";
    static const char source[] = "/tmp/proc17-qa-root/qa/source";
    static const char scratch[] = "/tmp/proc17-qa-root/qa/scratch";
    static const char old_root[] = "/tmp/proc17-qa-root/old-root";
    struct mount_attr source_attributes;
    char scratch_options[128];
    char descriptor_link[64];
    char source_path[PATH_MAX];
    ssize_t source_path_bytes;
    int attached_fd = -1;
    int probe_fd = -1;
    int failure = PROC17_QA_PROBE_MOUNT_SOURCE_FAILED;

    memset(stage, 0, sizeof(*stage));
    stage->source_fd = source_fd;
    stage->detached_mount_fd = -1;
    if (snprintf(scratch_options, sizeof(scratch_options),
            "size=%llu,nr_inodes=%llu,mode=0700",
            (unsigned long long)PROC17_QA_SCRATCH_BYTES,
            (unsigned long long)PROC17_QA_SCRATCH_ENTRIES)
            >= (int)sizeof(scratch_options)
        || snprintf(descriptor_link, sizeof(descriptor_link),
            "/proc/self/fd/%d", source_fd) >= (int)sizeof(descriptor_link)
        || observe_root(source_fd, &stage->original) != 0) {
        return PROC17_QA_PROBE_SOURCE_LOCATOR_FAILED;
    }
    source_path_bytes = readlink(descriptor_link, source_path,
        sizeof(source_path) - 1U);
    if (source_path_bytes <= 0 || source_path_bytes >= (ssize_t)sizeof(source_path)
        || source_path[0] != '/') {
        return PROC17_QA_PROBE_SOURCE_READLINK_FAILED;
    }
    source_path[source_path_bytes] = '\0';
    if (strstr(source_path, " (deleted)") != NULL) {
        return PROC17_QA_PROBE_SOURCE_DELETED_FAILED;
    }
    {
        struct proc17_qa_root_identity locator;
        if (observe_path_root(source_path, &locator) != 0
            || !same_mount_object(&locator, &stage->original)) {
            return PROC17_QA_PROBE_SOURCE_LOCATOR_IDENTITY_FAILED;
        }
    }
    if (mount(NULL, "/", NULL, MS_REC | MS_PRIVATE, NULL) != 0) {
        return PROC17_QA_PROBE_MOUNT_PRIVATE_FAILED;
    }
    if (mount(source_path, source_path, NULL, MS_BIND, NULL) != 0) {
        return PROC17_QA_PROBE_SOURCE_SELF_BIND_FAILED;
    }
    stage->temporary_self_bind_live = 1;
    {
        struct proc17_qa_root_identity self_bound;
        if (observe_path_root(source_path, &self_bound) != 0
            || !same_mount_object(&self_bound, &stage->original)) {
            failure = PROC17_QA_PROBE_SOURCE_SELF_BIND_FAILED;
            goto cleanup;
        }
    }
    stage->detached_mount_fd = (int)syscall(SYS_open_tree, AT_FDCWD,
        source_path, OPEN_TREE_CLONE | OPEN_TREE_CLOEXEC);
    if (stage->detached_mount_fd < 0
        || observe_root(stage->detached_mount_fd, &stage->detached) != 0
        || !same_mount_object(&stage->detached, &stage->original)) {
        failure = PROC17_QA_PROBE_SOURCE_CLONE_FAILED;
        goto cleanup;
    }
    if (umount2(source_path, MNT_DETACH) != 0) {
        failure = PROC17_QA_PROBE_SOURCE_DETACH_FAILED;
        goto cleanup;
    }
    stage->temporary_self_bind_live = 0;
    memset(source_path, 0, sizeof(source_path));
    memset(&source_attributes, 0, sizeof(source_attributes));
    source_attributes.attr_set = MOUNT_ATTR_RDONLY | MOUNT_ATTR_NOSUID
        | MOUNT_ATTR_NODEV | MOUNT_ATTR_NOEXEC;
    if (syscall(SYS_mount_setattr, stage->detached_mount_fd, "",
            AT_EMPTY_PATH | AT_RECURSIVE, &source_attributes,
            sizeof(source_attributes)) != 0
        || source_mount_flags(stage->detached_mount_fd,
            &stage->mount_policy_flags) != 0
        || stage->mount_policy_flags != PROC17_QA_SOURCE_MOUNT_REQUIRED) {
        failure = PROC17_QA_PROBE_SOURCE_HARDEN_FAILED;
        goto cleanup;
    }
    if (mount("tmpfs", "/tmp", "tmpfs", MS_NOSUID | MS_NODEV,
            "size=83886080,nr_inodes=8192,mode=0700") != 0) {
        failure = PROC17_QA_PROBE_MOUNT_TMPFS_FAILED;
        goto cleanup;
    }
    stage->host_tmp_hidden = 1;
    if (mkdir(root, 0700) != 0
        || mount(root, root, NULL, MS_BIND, NULL) != 0
        || mkdir("/tmp/proc17-qa-root/qa", 0555) != 0
        || mkdir(source, 0555) != 0
        || mkdir(scratch, 0700) != 0
        || mkdir(old_root, 0555) != 0) {
        failure = PROC17_QA_PROBE_MOUNT_ROOT_FAILED;
        goto cleanup;
    }
    if (syscall(SYS_move_mount, stage->detached_mount_fd, "", AT_FDCWD,
            source, MOVE_MOUNT_F_EMPTY_PATH) != 0) {
        failure = PROC17_QA_PROBE_SOURCE_ATTACH_FAILED;
        goto cleanup;
    }
    stage->detached_attached = 1;
    if (close(stage->detached_mount_fd) != 0) {
        stage->detached_mount_fd = -1;
        goto cleanup;
    }
    stage->detached_mount_fd = -1;
    attached_fd = open(source, O_PATH | O_CLOEXEC | O_DIRECTORY | O_NOFOLLOW);
    if (attached_fd < 0 || observe_root(attached_fd, &stage->attached) != 0
        || !same_mount_identity(&stage->attached, &stage->detached)
        || source_mount_flags(attached_fd, &stage->mount_policy_flags) != 0
        || stage->mount_policy_flags != PROC17_QA_SOURCE_MOUNT_REQUIRED) {
        failure = PROC17_QA_PROBE_SOURCE_ATTEST_FAILED;
        goto cleanup;
    }
    errno = 0;
    probe_fd = openat(attached_fd, "probe-source-write-must-fail",
        O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0600);
    if (probe_fd >= 0 || errno != EROFS) {
        if (probe_fd >= 0) close(probe_fd);
        failure = PROC17_QA_PROBE_SOURCE_ATTEST_FAILED;
        goto cleanup;
    }
    if (close(attached_fd) != 0) {
        attached_fd = -1;
        goto cleanup;
    }
    attached_fd = -1;
    if (mount("tmpfs", scratch, "tmpfs", MS_NOSUID | MS_NODEV | MS_NOEXEC,
            scratch_options) != 0
        || mkdir("/tmp/proc17-qa-root/qa/scratch/home", 0700) != 0
        || mkdir("/tmp/proc17-qa-root/qa/scratch/tmp", 0700) != 0) {
        return PROC17_QA_PROBE_MOUNT_SCRATCH_FAILED;
    }
    if (chdir(root) != 0
        || syscall(SYS_pivot_root, ".", "old-root") != 0
        || chdir("/") != 0
        || umount2("/old-root", MNT_DETACH) != 0
        || rmdir("/old-root") != 0) {
        return PROC17_QA_PROBE_MOUNT_PIVOT_FAILED;
    }
    {
        struct mount_attr root_attributes;
        memset(&root_attributes, 0, sizeof(root_attributes));
        root_attributes.attr_set = MOUNT_ATTR_RDONLY | MOUNT_ATTR_NOSUID
            | MOUNT_ATTR_NODEV | MOUNT_ATTR_NOEXEC;
        if (syscall(SYS_mount_setattr, AT_FDCWD, "/", 0U,
                &root_attributes, sizeof(root_attributes)) != 0) {
            return PROC17_QA_PROBE_MOUNT_ROOT_POLICY_FAILED;
        }
    }
    return PROC17_QA_PROBE_OK;

cleanup:
    if (attached_fd >= 0) close(attached_fd);
    if (stage->detached_mount_fd >= 0) {
        close(stage->detached_mount_fd);
        stage->detached_mount_fd = -1;
    }
    if (stage->temporary_self_bind_live) {
        if (umount2(source_path, MNT_DETACH) == 0) {
            stage->temporary_self_bind_live = 0;
        }
    }
    return failure;
}

static int namespace_probe_child(
    int synchronization_fd,
    int source_fd,
    int stage_report_fd,
    const char *entrypoint,
    int probe_mode)
{
    unsigned char ready;
    struct stat scratch_status;
    struct proc17_qa_source_stage stage;

    if (read(synchronization_fd, &ready, 1U) != 1 || ready != 0xa5U
        || close(synchronization_fd) != 0
        || getuid() != 0 || geteuid() != 0 || getgid() != 0 || getegid() != 0
        || sethostname("proc17-qa", sizeof("proc17-qa") - 1U) != 0) {
        return PROC17_QA_PROBE_MAPPING_FAILED;
    }
    {
        int mount_status = mount_isolated_world(source_fd, &stage);
        if (mount_status != 0 || close(source_fd) != 0) {
            return mount_status != 0
                ? mount_status : PROC17_QA_PROBE_MOUNT_FAILED;
        }
    }
    stage.candidate_started = 1;
    if (!stage.detached_attached || !stage.host_tmp_hidden
        || stage.temporary_self_bind_live
        || write_exact(stage_report_fd, &stage, sizeof(stage)) != 0
        || close(stage_report_fd) != 0) {
        return PROC17_QA_PROBE_MOUNT_SOURCE_POLICY_FAILED;
    }
    {
        int lua_status = run_lua_task(entrypoint, probe_mode);
        if (lua_status != PROC17_QA_PROBE_OK) {
            return lua_status;
        }
    }
    if (!probe_mode) {
        return PROC17_QA_PROBE_OK;
    }
    if (access("/qa/source/probe-source-write-must-fail", F_OK) == 0) {
        return PROC17_QA_PROBE_SOURCE_MUTATED;
    }
    if (stat("/qa/scratch/probe-result", &scratch_status) != 0
        || !S_ISREG(scratch_status.st_mode)) {
        return PROC17_QA_PROBE_SCRATCH_MISSING;
    }
    if (run_denial_probe(0) != 0
        || run_denial_probe(1) != 0
        || run_denial_probe(2) != 0) {
        return PROC17_QA_PROBE_POLICY_FAILED;
    }
    return PROC17_QA_PROBE_OK;
}

static int write_text_file(const char *path, const char *bytes)
{
    int descriptor = open(path, O_WRONLY | O_CLOEXEC);
    size_t length = strlen(bytes);
    int result;

    if (descriptor < 0) {
        return -1;
    }
    result = write_exact(descriptor, bytes, length);
    if (close(descriptor) != 0) {
        return -1;
    }
    return result;
}

static int map_namespace_identity(pid_t child)
{
    char path[64];
    char mapping[128];

    if (snprintf(path, sizeof(path), "/proc/%ld/setgroups", (long)child)
            >= (int)sizeof(path)
        || write_text_file(path, "deny\n") != 0
        || snprintf(path, sizeof(path), "/proc/%ld/uid_map", (long)child)
            >= (int)sizeof(path)
        || snprintf(mapping, sizeof(mapping), "0 %lu 1\n",
            (unsigned long)geteuid()) >= (int)sizeof(mapping)
        || write_text_file(path, mapping) != 0
        || snprintf(path, sizeof(path), "/proc/%ld/gid_map", (long)child)
            >= (int)sizeof(path)
        || snprintf(mapping, sizeof(mapping), "0 %lu 1\n",
            (unsigned long)getegid()) >= (int)sizeof(mapping)
        || write_text_file(path, mapping) != 0) {
        return -1;
    }
    return 0;
}

static int wait_namespace(pid_t child, int pidfd, struct rusage *usage)
{
    struct itimerspec timer_spec;
    struct pollfd descriptors[2];
    int timerfd = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC);
    int status;

    if (timerfd < 0) {
        return PROC17_QA_PROBE_REAP_FAILED;
    }
    memset(&timer_spec, 0, sizeof(timer_spec));
    timer_spec.it_value.tv_sec = (time_t)(
        (PROC17_QA_WALL_TIME_MS + PROC17_QA_SETUP_GRACE_MS) / 1000U);
    if (timerfd_settime(timerfd, 0, &timer_spec, NULL) != 0) {
        close(timerfd);
        return PROC17_QA_PROBE_REAP_FAILED;
    }
    descriptors[0] = (struct pollfd){.fd = pidfd, .events = POLLIN};
    descriptors[1] = (struct pollfd){.fd = timerfd, .events = POLLIN};
    for (;;) {
        int polled = poll(descriptors, 2, -1);
        if (polled < 0 && errno == EINTR) {
            continue;
        }
        if (polled < 0 || (descriptors[1].revents & POLLIN) != 0) {
            (void)syscall(SYS_pidfd_send_signal, pidfd, SIGKILL, NULL, 0U);
            (void)wait4(child, NULL, 0, usage);
            close(timerfd);
            return PROC17_QA_PROBE_REAP_FAILED;
        }
        if ((descriptors[0].revents & POLLIN) != 0) {
            break;
        }
    }
    close(timerfd);
    if (wait4(child, &status, 0, usage) != child || !WIFEXITED(status)) {
        return PROC17_QA_PROBE_REAP_FAILED;
    }
    return WEXITSTATUS(status);
}

static uint32_t run_namespace_probe(
    int source_fd,
    struct proc17_qa_source_stage *stage,
    const char *entrypoint,
    int probe_mode,
    struct proc17_qa_run_metrics *metrics)
{
    struct clone_args arguments;
    int synchronization[2] = {-1, -1};
    int report[2] = {-1, -1};
    int pidfd = -1;
    pid_t child;
    unsigned char ready = 0xa5U;
    uint32_t result = PROC17_QA_PROBE_NAMESPACE_FAILED;
    struct timespec started = {0};
    struct timespec finished = {0};
    struct rusage usage;

    memset(stage, 0, sizeof(*stage));
    memset(&usage, 0, sizeof(usage));
    if (metrics != NULL) {
        memset(metrics, 0, sizeof(*metrics));
        if (clock_gettime(CLOCK_MONOTONIC, &started) != 0) {
            return PROC17_QA_PROBE_NAMESPACE_FAILED;
        }
    }
    stage->detached_mount_fd = -1;
    if (pipe2(synchronization, O_CLOEXEC) != 0
        || pipe2(report, O_CLOEXEC) != 0) {
        if (synchronization[0] >= 0) close(synchronization[0]);
        if (synchronization[1] >= 0) close(synchronization[1]);
        return PROC17_QA_PROBE_NAMESPACE_FAILED;
    }
    memset(&arguments, 0, sizeof(arguments));
    arguments.flags = CLONE_NEWUSER | CLONE_NEWNS | CLONE_NEWPID
        | CLONE_NEWNET | CLONE_NEWIPC | CLONE_NEWUTS | CLONE_PIDFD;
    arguments.pidfd = (uint64_t)(uintptr_t)&pidfd;
    arguments.exit_signal = SIGCHLD;
    child = (pid_t)syscall(SYS_clone3, &arguments, sizeof(arguments));
    if (child < 0) {
        close(synchronization[0]);
        close(synchronization[1]);
        close(report[0]);
        close(report[1]);
        return PROC17_QA_PROBE_NAMESPACE_FAILED;
    }
    if (child == 0) {
        int child_result;
        close(synchronization[1]);
        close(report[0]);
        child_result = namespace_probe_child(
            synchronization[0], source_fd, report[1], entrypoint, probe_mode);
        _exit(child_result);
    }
    close(synchronization[0]);
    close(report[1]);
    if (pidfd < 0 || map_namespace_identity(child) != 0
        || write_exact(synchronization[1], &ready, 1U) != 0
        || close(synchronization[1]) != 0) {
        result = PROC17_QA_PROBE_MAPPING_FAILED;
    } else {
        synchronization[1] = -1;
        result = (uint32_t)wait_namespace(child, pidfd, &usage);
        child = -1;
        if (read_exact(report[0], stage, sizeof(*stage)) != 0
            && (result == PROC17_QA_PROBE_OK
                || (!probe_mode
                    && result == PROC17_QA_CANDIDATE_LUA_ERROR_EXIT))) {
            result = PROC17_QA_PROBE_MOUNT_SOURCE_POLICY_FAILED;
        }
    }
    if (child > 0) {
        if (synchronization[1] >= 0) {
            close(synchronization[1]);
        }
        if (pidfd >= 0) {
            (void)syscall(SYS_pidfd_send_signal, pidfd, SIGKILL, NULL, 0U);
        } else {
            (void)kill(child, SIGKILL);
        }
        (void)waitpid(child, NULL, 0);
    }
    if (pidfd >= 0) {
        close(pidfd);
    }
    close(report[0]);
    if (metrics != NULL) {
        uint64_t started_ns;
        uint64_t finished_ns;
        if (clock_gettime(CLOCK_MONOTONIC, &finished) != 0) {
            return PROC17_QA_PROBE_REAP_FAILED;
        }
        started_ns = (uint64_t)started.tv_sec * UINT64_C(1000000000)
            + (uint64_t)started.tv_nsec;
        finished_ns = (uint64_t)finished.tv_sec * UINT64_C(1000000000)
            + (uint64_t)finished.tv_nsec;
        if (finished_ns < started_ns || usage.ru_maxrss < 0) {
            return PROC17_QA_PROBE_REAP_FAILED;
        }
        metrics->wall_ms = (finished_ns - started_ns) / UINT64_C(1000000);
        metrics->user_cpu_ms = (uint64_t)usage.ru_utime.tv_sec * UINT64_C(1000)
            + (uint64_t)usage.ru_utime.tv_usec / UINT64_C(1000);
        metrics->system_cpu_ms = (uint64_t)usage.ru_stime.tv_sec * UINT64_C(1000)
            + (uint64_t)usage.ru_stime.tv_usec / UINT64_C(1000);
        metrics->max_rss_bytes = (uint64_t)usage.ru_maxrss * UINT64_C(1024);
    }
    return result;
}

static void derive_kernel_identity(unsigned char output[PROC17_SHA256_BYTES])
{
    struct utsname identity;
    char canonical[1024];
    int length;

    memset(&identity, 0, sizeof(identity));
    if (uname(&identity) != 0) {
        memset(output, 0, PROC17_SHA256_BYTES);
        return;
    }
    length = snprintf(canonical, sizeof(canonical), "%s\n%s\n%s\n%s\n%s\n",
        identity.sysname, identity.release, identity.version,
        identity.machine, identity.nodename);
    if (length < 0 || length >= (int)sizeof(canonical)) {
        memset(output, 0, PROC17_SHA256_BYTES);
        return;
    }
    proc17_sha256_bytes(canonical, (size_t)length, output);
}

static void derive_feature_identity(
    const unsigned char kernel[PROC17_SHA256_BYTES],
    unsigned char output[PROC17_SHA256_BYTES])
{
    struct proc17_sha256 context;
    uint32_t features = PROC17_QA_REQUIRED_PROBE_FEATURES;

    proc17_sha256_init(&context);
    proc17_sha256_update(&context, PROC17_QA_POLICY_VERSION,
        sizeof(PROC17_QA_POLICY_VERSION) - 1U);
    proc17_sha256_update(&context, &features, sizeof(features));
    proc17_sha256_update(&context, kernel, PROC17_SHA256_BYTES);
    proc17_sha256_final(&context, output);
}

static int emit_probe_result(
    const unsigned char nonce[PROC17_QA_WIRE_NONCE_BYTES],
    uint32_t status,
    const struct proc17_qa_root_identity *source_identity,
    const struct proc17_qa_source_stage *stage,
    const unsigned char supervisor_digest[PROC17_SHA256_BYTES])
{
    unsigned char payload[PROC17_QA_PROBE_RESULT_BYTES];
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char runtime[PROC17_SHA256_BYTES];
    unsigned char closure[PROC17_SHA256_BYTES];
    unsigned char policy[PROC17_SHA256_BYTES];
    unsigned char kernel[PROC17_SHA256_BYTES];
    unsigned char features[PROC17_SHA256_BYTES];
    size_t frame_bytes;

    if (proc17_sha256_parse_hex(PROC17_QA_RUNTIME_BUILD_ID_HEX, runtime) != 0
        || proc17_sha256_parse_hex(
            PROC17_QA_RUNTIME_DEPENDENCY_CLOSURE_ID_HEX, closure) != 0
        || proc17_sha256_parse_hex(PROC17_QA_POLICY_DIGEST_HEX, policy) != 0) {
        return -1;
    }
    derive_kernel_identity(kernel);
    derive_feature_identity(kernel, features);
    memset(payload, 0, sizeof(payload));
    proc17_qa_wire_put_u32(payload, status);
    proc17_qa_wire_put_u32(payload + 4U,
        status == PROC17_QA_PROBE_OK ? PROC17_QA_REQUIRED_PROBE_FEATURES : 0U);
    memcpy(payload + 8U, supervisor_digest, PROC17_SHA256_BYTES);
    memcpy(payload + 40U, runtime, PROC17_SHA256_BYTES);
    memcpy(payload + 72U, closure, PROC17_SHA256_BYTES);
    memcpy(payload + 104U, policy, PROC17_SHA256_BYTES);
    memcpy(payload + 136U, kernel, PROC17_SHA256_BYTES);
    memcpy(payload + 168U, features, PROC17_SHA256_BYTES);
    proc17_qa_wire_put_u16(payload + 200U,
        PROC17_QA_SOURCE_POLICY_DETACHED_MOUNT_V0);
    proc17_qa_wire_put_u32(payload + 204U, stage->mount_policy_flags);
    proc17_qa_wire_put_u64(payload + 208U, stage->original.device);
    proc17_qa_wire_put_u64(payload + 216U, stage->original.inode);
    proc17_qa_wire_put_u64(payload + 224U, stage->original.mount_id);
    proc17_qa_wire_put_u64(payload + 232U, stage->detached.device);
    proc17_qa_wire_put_u64(payload + 240U, stage->detached.inode);
    proc17_qa_wire_put_u64(payload + 248U, stage->detached.mount_id);
    proc17_qa_wire_put_u64(payload + 256U, stage->attached.device);
    proc17_qa_wire_put_u64(payload + 264U, stage->attached.inode);
    proc17_qa_wire_put_u64(payload + 272U, stage->attached.mount_id);
    payload[280U] = stage->temporary_self_bind_live == 0 ? 1U : 0U;
    payload[281U] = stage->candidate_started != 0 ? 1U : 0U;
    proc17_qa_wire_put_u64(payload + 284U, PROC17_QA_RUNTIME_HEAP_BYTES);
    (void)source_identity;
    if (proc17_qa_wire_encode(PROC17_QA_WIRE_PROBE_RESULT, nonce,
            payload, sizeof(payload), frame, &frame_bytes) != 0) {
        return -1;
    }
    return write_exact(5, frame, frame_bytes);
}

static int digest_nonzero(const unsigned char value[PROC17_SHA256_BYTES])
{
    unsigned char combined = 0U;
    size_t index;
    for (index = 0; index < PROC17_SHA256_BYTES; index++) combined |= value[index];
    return combined != 0U;
}

static int parse_run_request(
    const struct proc17_qa_wire_view *view,
    const struct proc17_qa_root_identity *observed_root,
    struct proc17_qa_run_request *request)
{
    static const uint64_t exact_limits[PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS] = {
        PROC17_QA_WALL_TIME_MS, PROC17_QA_CPU_TIME_MS,
        PROC17_QA_ADDRESS_SPACE_BYTES, PROC17_QA_MAX_PROCESSES,
        PROC17_QA_MAX_OPEN_FILES, PROC17_QA_MAX_FILE_BYTES,
        PROC17_QA_SCRATCH_BYTES, PROC17_QA_SCRATCH_ENTRIES,
        PROC17_QA_STDOUT_BYTES, PROC17_QA_STDERR_BYTES,
    };
    const unsigned char *payload = view->payload;
    uint16_t path_bytes;
    size_t index;

    if (view->kind != PROC17_QA_WIRE_RUN_REQUEST
        || view->payload_bytes < PROC17_QA_RUN_REQUEST_FIXED_BYTES) {
        return -1;
    }
    path_bytes = proc17_qa_wire_get_u16(payload + 236U);
    if (path_bytes == 0U || path_bytes > 1024U
        || view->payload_bytes != PROC17_QA_RUN_REQUEST_FIXED_BYTES + path_bytes
        || memcmp(view->nonce, payload, PROC17_QA_WIRE_NONCE_BYTES) != 0) {
        return -1;
    }
    memset(request, 0, sizeof(*request));
    memcpy(request->transaction, payload, PROC17_SHA256_BYTES);
    memcpy(request->witness, payload + 32U, PROC17_SHA256_BYTES);
    memcpy(request->profile, payload + 64U, PROC17_SHA256_BYTES);
    memcpy(request->environment, payload + 96U, PROC17_SHA256_BYTES);
    if (!digest_nonzero(request->transaction) || !digest_nonzero(request->witness)
        || !digest_nonzero(request->profile)
        || !digest_nonzero(request->environment)) {
        return -1;
    }
    request->root.device = proc17_qa_wire_get_u64(payload + 128U);
    request->root.inode = proc17_qa_wire_get_u64(payload + 136U);
    request->root.mount_id = proc17_qa_wire_get_u64(payload + 144U);
    if (!same_mount_identity(&request->root, observed_root)) return -1;
    for (index = 0; index < PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS; index++) {
        request->limits[index] = proc17_qa_wire_get_u64(
            payload + 152U + index * 8U);
        if (request->limits[index] != exact_limits[index]) return -1;
    }
    request->expected_exit = proc17_qa_wire_get_u32(payload + 232U);
    if (request->expected_exit != 0U
        || memchr(payload + 238U, '\0', path_bytes) != NULL) {
        return -1;
    }
    memcpy(request->entrypoint, payload + 238U, path_bytes);
    request->entrypoint[path_bytes] = '\0';
    if (strcmp(request->entrypoint, "tests/run.lua") != 0) return -1;
    return 0;
}

static void encode_stage(
    unsigned char *payload,
    const struct proc17_qa_source_stage *stage)
{
    proc17_qa_wire_put_u16(payload, PROC17_QA_SOURCE_POLICY_DETACHED_MOUNT_V0);
    proc17_qa_wire_put_u32(payload + 4U, stage->mount_policy_flags);
    proc17_qa_wire_put_u64(payload + 8U, stage->original.device);
    proc17_qa_wire_put_u64(payload + 16U, stage->original.inode);
    proc17_qa_wire_put_u64(payload + 24U, stage->original.mount_id);
    proc17_qa_wire_put_u64(payload + 32U, stage->detached.device);
    proc17_qa_wire_put_u64(payload + 40U, stage->detached.inode);
    proc17_qa_wire_put_u64(payload + 48U, stage->detached.mount_id);
    proc17_qa_wire_put_u64(payload + 56U, stage->attached.device);
    proc17_qa_wire_put_u64(payload + 64U, stage->attached.inode);
    proc17_qa_wire_put_u64(payload + 72U, stage->attached.mount_id);
    payload[80U] = stage->temporary_self_bind_live == 0 ? 1U : 0U;
    payload[81U] = stage->candidate_started != 0 ? 1U : 0U;
}

static int emit_run_result(
    const struct proc17_qa_run_request *request,
    uint32_t status,
    const struct proc17_qa_source_stage *stage,
    const struct proc17_qa_run_metrics *metrics)
{
    static const unsigned char empty_digest[PROC17_SHA256_BYTES] = {
        0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14,
        0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f, 0xb9, 0x24,
        0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c,
        0xa4, 0x95, 0x99, 0x1b, 0x78, 0x52, 0xb8, 0x55,
    };
    unsigned char payload[PROC17_QA_RUN_RESULT_BYTES];
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t frame_bytes;
    int contained = status == 0U || status == PROC17_QA_CANDIDATE_LUA_ERROR_EXIT;

    memset(payload, 0, sizeof(payload));
    proc17_qa_wire_put_u16(payload,
        contained ? PROC17_QA_RUN_CONTAINED : PROC17_QA_RUN_PROCESS_ERROR);
    proc17_qa_wire_put_u16(payload + 2U, status == 0U
        ? PROC17_QA_RUN_EXPECTED_EXIT : PROC17_QA_RUN_UNEXPECTED_EXIT);
    if (!contained) {
        proc17_qa_wire_put_u16(payload + 4U, 1U);
        proc17_qa_wire_put_u16(payload + 6U, (uint16_t)status);
        proc17_qa_wire_put_u16(payload + 8U, 2U);
    }
    payload[10U] = stage->candidate_started != 0 ? 1U : 0U;
    payload[11U] = 1U;
    proc17_qa_wire_put_u16(payload + 12U, PROC17_QA_TERMINATION_EXIT);
    proc17_qa_wire_put_u32(payload + 16U, status);
    proc17_qa_wire_put_u32(payload + 20U, UINT32_MAX);
    proc17_qa_wire_put_u64(payload + 24U, metrics->wall_ms);
    proc17_qa_wire_put_u64(payload + 32U, metrics->user_cpu_ms);
    proc17_qa_wire_put_u64(payload + 40U, metrics->system_cpu_ms);
    memcpy(payload + 64U, empty_digest, sizeof(empty_digest));
    memcpy(payload + 112U, empty_digest, sizeof(empty_digest));
    proc17_qa_wire_put_u64(payload + 168U, metrics->max_rss_bytes);
    memcpy(payload + 176U, request->transaction, PROC17_SHA256_BYTES);
    memcpy(payload + 208U, request->witness, PROC17_SHA256_BYTES);
    memcpy(payload + 240U, request->profile, PROC17_SHA256_BYTES);
    memcpy(payload + 272U, request->environment, PROC17_SHA256_BYTES);
    encode_stage(payload + 304U, stage);
    if (proc17_qa_wire_encode(PROC17_QA_WIRE_RUN_RESULT,
            request->transaction, payload, sizeof(payload), frame,
            &frame_bytes) != 0) {
        return -1;
    }
    return write_exact(5, frame, frame_bytes);
}

static int run_execution_protocol(void)
{
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char self_digest[PROC17_SHA256_BYTES];
    size_t frame_bytes;
    struct proc17_qa_wire_view view;
    struct proc17_qa_root_identity source_identity = {0};
    struct proc17_qa_source_stage stage;
    struct proc17_qa_run_request request;
    struct proc17_qa_run_metrics metrics;
    uint32_t status;

    memset(&stage, 0, sizeof(stage));
    stage.detached_mount_fd = -1;
    if (read_frame(4, frame, &frame_bytes) != 0
        || proc17_qa_wire_decode(frame, frame_bytes, &view) != 0
        || sha_self(self_digest) != 0 || close(6) != 0
        || observe_root(3, &source_identity) != 0
        || parse_run_request(&view, &source_identity, &request) != 0
        || close(4) != 0) {
        return -1;
    }
    status = run_namespace_probe(3, &stage, request.entrypoint, 0, &metrics);
    return emit_run_result(&request, status, &stage, &metrics);
}

static int run_probe_protocol(void)
{
    unsigned char request[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char self_digest[PROC17_SHA256_BYTES];
    size_t request_bytes;
    struct proc17_qa_wire_view view;
    struct proc17_qa_root_identity source_identity = {0};
    struct proc17_qa_source_stage stage;
    uint32_t status = PROC17_QA_PROBE_OK;

    memset(&stage, 0, sizeof(stage));
    stage.detached_mount_fd = -1;

    if (read_frame(4, request, &request_bytes) != 0
        || proc17_qa_wire_decode(request, request_bytes, &view) != 0
        || view.kind != PROC17_QA_WIRE_PROBE_REQUEST
        || view.payload_bytes != PROC17_SHA256_BYTES) {
        return -1;
    }
    if (sha_self(self_digest) != 0
        || memcmp(self_digest, view.payload, PROC17_SHA256_BYTES) != 0
        || exact_static_lua_selftest() != 0
        || close(6) != 0) {
        status = PROC17_QA_PROBE_SELF_FAILED;
    } else if (observe_root(3, &source_identity) != 0) {
        status = PROC17_QA_PROBE_SOURCE_FAILED;
    } else {
        status = run_namespace_probe(3, &stage, "probe.lua", 1, NULL);
    }
    return emit_probe_result(view.nonce, status, &source_identity, &stage,
        self_digest);
}

int main(int argument_count, char **arguments)
{
    if (prctl(PR_SET_PDEATHSIG, SIGKILL, 0L, 0L, 0L) != 0) {
        return 125;
    }
    if (argument_count == 2 && strcmp(arguments[1], "self-test") == 0) {
        return exact_static_lua_selftest() == 0 ? 0 : 1;
    }
    if (argument_count != 2) {
        return 126;
    }
    if (strcmp(arguments[1], "probe") == 0) {
        return run_probe_protocol() == 0 ? 0 : 127;
    }
    if (strcmp(arguments[1], "run") == 0) {
        return run_execution_protocol() == 0 ? 0 : 127;
    }
    return 126;
}
