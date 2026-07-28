#define _GNU_SOURCE

#include <lua.h>
#include <lauxlib.h>

#include <errno.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <limits.h>
#include <poll.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>
#include <sys/random.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/timerfd.h>
#include <sys/wait.h>
#include <unistd.h>

#include "generated/proc17_qa_build_identity.h"
#include "generated/proc17_qa_prebuild.h"
#include "proc17_qa_launcher_internal.h"
#include "proc17_qa_launcher_v1.h"
#include "proc17_qa_policy.h"
#include "proc17_qa_wire.h"
#include "proc17_repository_handle_abi.h"
#include "proc17_sha256.h"

#ifdef PROC17_QA_FAULT_TESTING
#include "tests/proc17_qa_fault_testing.h"
#endif

#define PROC17_QA_LAUNCHER_PROTOCOL "qa.native_launcher.v0"
#ifndef PROC17_QA_LAUNCHER_ABI
#define PROC17_QA_LAUNCHER_ABI "proc17.qa.launcher.lua54.v0"
#endif
#define PROC17_QA_PROVIDER_ID "linux.qa_supervisor.lua54.v0"
#define PROC17_QA_SUPERVISOR_ABI "proc17.qa_supervisor.v0"
#define PROC17_QA_PROBE_RESULT_BYTES 292U
#define PROC17_QA_NATIVE_FILE_CEILING (64U * 1024U * 1024U)
#define PROC17_QA_LAUNCHER_WATCHDOG_SECONDS 40
#define PROC17_QA_SOURCE_POLICY_DETACHED_MOUNT_V0 1U
#define PROC17_QA_SOURCE_MOUNT_REQUIRED 15U

struct proc17_qa_mount_identity {
    uint64_t device;
    uint64_t inode;
    uint64_t mount_id;
};

int luaopen_proc17_qa_launcher(lua_State *L);

static int observe_mount_identity(
    int descriptor,
    struct proc17_qa_mount_identity *identity)
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

static int exact_repository_identity(
    int descriptor,
    const struct proc17_repository_handle_prefix_v0 *prefix)
{
    struct stat status;
    struct statx extended;

    if (fstat(descriptor, &status) != 0 || !S_ISDIR(status.st_mode)) {
        return 0;
    }
    memset(&extended, 0, sizeof(extended));
    if (statx(descriptor, "", AT_EMPTY_PATH | AT_STATX_SYNC_AS_STAT,
            STATX_TYPE | STATX_MNT_ID, &extended) != 0
        || (extended.stx_mask & STATX_MNT_ID) == 0) {
        return 0;
    }
    return prefix->repository_device == (uint64_t)(uintmax_t)status.st_dev
        && prefix->repository_inode == (uint64_t)(uintmax_t)status.st_ino
        && prefix->repository_mount_id == extended.stx_mnt_id;
}

int proc17_qa_with_repository_source(
    lua_State *L,
    int index,
    proc17_qa_source_consumer consumer,
    void *context)
{
    struct proc17_repository_handle_prefix_v0 *prefix;
    int duplicate;
    int consumed;
    int close_result;

    if (consumer == NULL) {
        return PROC17_QA_SOURCE_CONSUMER_FAILED;
    }
    prefix = (struct proc17_repository_handle_prefix_v0 *)luaL_testudata(
        L, index, PROC17_REPOSITORY_HANDLE_METATABLE);
    if (prefix == NULL) {
        return PROC17_QA_SOURCE_INVALID_USERDATA;
    }
    if (lua_rawlen(L, index) < sizeof(*prefix)
        || prefix->abi_magic != PROC17_REPOSITORY_HANDLE_MAGIC
        || prefix->abi_version != PROC17_REPOSITORY_HANDLE_ABI
        || prefix->struct_bytes < sizeof(*prefix)
        || prefix->struct_bytes > lua_rawlen(L, index)
        || prefix->reserved != 0U) {
        return PROC17_QA_SOURCE_INVALID_ABI;
    }
    if (prefix->closed || prefix->repository_fd < 0) {
        return PROC17_QA_SOURCE_CLOSED;
    }

    duplicate = fcntl(prefix->repository_fd, F_DUPFD_CLOEXEC, 3);
    if (duplicate < 0) {
        return PROC17_QA_SOURCE_DUPLICATE_FAILED;
    }
    if (!exact_repository_identity(duplicate, prefix)) {
        (void)close(duplicate);
        return PROC17_QA_SOURCE_IDENTITY_CHANGED;
    }

    consumed = consumer(duplicate, context);
    close_result = close(duplicate);
    if (consumed != 0) {
        return PROC17_QA_SOURCE_CONSUMER_FAILED;
    }
    if (close_result != 0) {
        return PROC17_QA_SOURCE_CLOSE_FAILED;
    }
    return PROC17_QA_SOURCE_OK;
}

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

static int hash_descriptor(
    int descriptor,
    unsigned char digest[PROC17_SHA256_BYTES])
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
        if ((size_t)observed > PROC17_QA_NATIVE_FILE_CEILING - total) {
            return -1;
        }
        proc17_sha256_update(&context, buffer, (size_t)observed);
        total += (size_t)observed;
        offset += observed;
    }
    proc17_sha256_final(&context, digest);
    return 0;
}

static int exact_sibling_path(const char *name, char output[PATH_MAX])
{
    Dl_info information;
    const char *slash;
    size_t prefix;
    static const char expected_name[] = "proc17_qa_launcher.so";

    memset(&information, 0, sizeof(information));
    if (dladdr((void *)(uintptr_t)&luaopen_proc17_qa_launcher, &information) == 0
        || information.dli_fname == NULL
        || (slash = strrchr(information.dli_fname, '/')) == NULL
        || strcmp(slash + 1, expected_name) != 0
        || name == NULL || strchr(name, '/') != NULL) {
        return -1;
    }
    prefix = (size_t)(slash - information.dli_fname + 1);
    if (prefix + strlen(name) + 1U > PATH_MAX) {
        return -1;
    }
    memcpy(output, information.dli_fname, prefix);
    strcpy(output + prefix, name);
    return 0;
}

static int open_exact_supervisor_path(
    const char *path,
    unsigned char digest[PROC17_SHA256_BYTES],
    int *descriptor)
{
    unsigned char expected[PROC17_SHA256_BYTES];
    struct stat status;
    int opened;

    if (path == NULL || proc17_sha256_parse_hex(
            PROC17_QA_EXPECTED_SUPERVISOR_BUILD_ID_HEX, expected) != 0) {
        return -1;
    }
    opened = open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (opened < 0 || fstat(opened, &status) != 0
        || !S_ISREG(status.st_mode) || status.st_size <= 0
        || (uintmax_t)status.st_size > PROC17_QA_NATIVE_FILE_CEILING
        || hash_descriptor(opened, digest) != 0
        || memcmp(digest, expected, sizeof(expected)) != 0) {
        if (opened >= 0) {
            close(opened);
        }
        return -1;
    }
    *descriptor = opened;
    return 0;
}

static int open_exact_supervisor(
    unsigned char digest[PROC17_SHA256_BYTES],
    int *descriptor)
{
    char path[PATH_MAX];

    return exact_sibling_path("proc17_qa_supervisor", path) == 0
        ? open_exact_supervisor_path(path, digest, descriptor) : -1;
}

#ifdef PROC17_QA_FAULT_TESTING
int proc17_qa_fault_test_supervisor_identity_accepts(const char *path)
{
    unsigned char digest[PROC17_SHA256_BYTES];
    int descriptor = -1;
    int accepted = open_exact_supervisor_path(path, digest, &descriptor) == 0;

    if (descriptor >= 0) (void)close(descriptor);
    explicit_bzero(digest, sizeof(digest));
    return accepted;
}
#endif

static int open_probe_source(int *descriptor)
{
    unsigned char expected[PROC17_SHA256_BYTES];
    unsigned char observed[PROC17_SHA256_BYTES];
    char path[PATH_MAX];
    struct stat status;
    struct stat fixture_status;
    int opened;
    int fixture = -1;

    if (exact_sibling_path("qa_probe_source", path) != 0) {
        return -1;
    }
    opened = open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_DIRECTORY);
    if (opened < 0) {
        return -1;
    }
    if (fstat(opened, &status) != 0 || !S_ISDIR(status.st_mode)
        || proc17_sha256_parse_hex(PROC17_QA_PROBE_SOURCE_ID_HEX, expected) != 0) {
        goto fail;
    }
    fixture = openat(opened, "probe.lua",
        O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (fixture < 0 || fstat(fixture, &fixture_status) != 0
        || !S_ISREG(fixture_status.st_mode)
        || fixture_status.st_size <= 0
        || fixture_status.st_size > 65536
        || hash_descriptor(fixture, observed) != 0
        || memcmp(observed, expected, sizeof(expected)) != 0) {
        goto fail;
    }
    {
        int close_result = close(fixture);
        fixture = -1;
        if (close_result != 0) {
            goto fail;
        }
    }
    *descriptor = opened;
    return 0;

fail:
    if (fixture >= 0) {
        (void)close(fixture);
    }
    (void)close(opened);
    return -1;
}

static int random_nonce(unsigned char nonce[PROC17_QA_WIRE_NONCE_BYTES])
{
    size_t used = 0;
    while (used < PROC17_QA_WIRE_NONCE_BYTES) {
        ssize_t observed = getrandom(nonce + used,
            PROC17_QA_WIRE_NONCE_BYTES - used, 0U);
        if (observed < 0 && errno == EINTR) {
            continue;
        }
        if (observed <= 0) {
            return -1;
        }
        used += (size_t)observed;
    }
    return 0;
}

static int high_duplicate(int descriptor)
{
    return fcntl(descriptor, F_DUPFD_CLOEXEC, 10);
}

static void supervisor_exec_child(
    int source,
    int request,
    int result,
    int supervisor,
    const char *mode)
{
    char *const arguments[] = {(char *)"proc17_qa_supervisor",
        (char *)mode, NULL};
    char *const environment[] = {NULL};
    int fixed_source = -1;
    int fixed_request = -1;
    int fixed_result = -1;
    int fixed_supervisor = -1;

    fixed_source = dup3(source, 3, 0);
    if (fixed_source < 0) {
        goto setup_failed;
    }
    fixed_request = dup3(request, 4, 0);
    if (fixed_request < 0) {
        goto setup_failed;
    }
    fixed_result = dup3(result, 5, 0);
    if (fixed_result < 0) {
        goto setup_failed;
    }
    fixed_supervisor = dup3(supervisor, 6, 0);
    if (fixed_supervisor < 0) {
        goto setup_failed;
    }
    if (syscall(SYS_close_range, 7U, UINT_MAX, 0U) != 0
        || prctl(PR_SET_PDEATHSIG, SIGKILL, 0L, 0L, 0L) != 0) {
        goto setup_failed;
    }
    (void)close(STDIN_FILENO);
    (void)close(STDOUT_FILENO);
    (void)close(STDERR_FILENO);
    execveat(6, "", arguments, environment, AT_EMPTY_PATH);
    (void)close(fixed_supervisor);
    (void)close(fixed_result);
    (void)close(fixed_request);
    (void)close(fixed_source);
    _exit(127);

setup_failed:
    if (fixed_supervisor >= 0) {
        (void)close(fixed_supervisor);
    }
    if (fixed_result >= 0) {
        (void)close(fixed_result);
    }
    if (fixed_request >= 0) {
        (void)close(fixed_request);
    }
    if (fixed_source >= 0) {
        (void)close(fixed_source);
    }
    _exit(126);
}

static int collect_probe_result(
    pid_t child,
    int pidfd,
    int result_fd,
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES],
    size_t *frame_bytes)
{
    struct itimerspec timer_spec;
    struct pollfd descriptors[3];
    size_t used = 0;
    int result_eof = 0;
    int child_ready = 0;
    int timerfd;
    int status;

    timerfd = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);
    if (timerfd < 0) {
        return -1;
    }
    memset(&timer_spec, 0, sizeof(timer_spec));
    timer_spec.it_value.tv_sec = PROC17_QA_LAUNCHER_WATCHDOG_SECONDS;
    if (timerfd_settime(timerfd, 0, &timer_spec, NULL) != 0) {
        close(timerfd);
        return -1;
    }
    for (;;) {
        int polled;
        descriptors[0] = (struct pollfd){.fd = result_fd,
            .events = POLLIN | POLLHUP};
        descriptors[1] = (struct pollfd){.fd = pidfd, .events = POLLIN};
        descriptors[2] = (struct pollfd){.fd = timerfd, .events = POLLIN};
        polled = poll(descriptors, 3, -1);
        if (polled < 0 && errno == EINTR) {
            continue;
        }
        if (polled < 0 || (descriptors[2].revents & POLLIN) != 0) {
            (void)syscall(SYS_pidfd_send_signal, pidfd, SIGKILL, NULL, 0U);
            (void)waitpid(child, NULL, 0);
            close(timerfd);
            return -90;
        }
        if ((descriptors[0].revents & (POLLIN | POLLHUP)) != 0) {
            for (;;) {
                ssize_t observed;
                if (used == PROC17_QA_WIRE_MAX_FRAME_BYTES) {
                    unsigned char overflow;
                    observed = read(result_fd, &overflow, 1U);
                    if (observed != 0) {
                        close(timerfd);
                        return -91;
                    }
                    result_eof = 1;
                    break;
                }
                observed = read(result_fd, frame + used,
                    PROC17_QA_WIRE_MAX_FRAME_BYTES - used);
                if (observed > 0) {
                    used += (size_t)observed;
                    continue;
                }
                if (observed == 0) {
                    result_eof = 1;
                } else if (errno != EAGAIN && errno != EWOULDBLOCK
                    && errno != EINTR) {
                    close(timerfd);
                    return -92;
                }
                break;
            }
        }
        if ((descriptors[1].revents & POLLIN) != 0) {
            child_ready = 1;
        }
        if (child_ready && result_eof) {
            break;
        }
    }
    close(timerfd);
    if (waitpid(child, &status, 0) != child) return -93;
    if (WIFSIGNALED(status)) return -100 - WTERMSIG(status);
    if (!WIFEXITED(status)) return -94;
    if (WEXITSTATUS(status) != 0) return -(int)WEXITSTATUS(status);
    *frame_bytes = used;
    return 0;
}

static int launch_probe(
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES],
    size_t *frame_bytes,
    unsigned char nonce[PROC17_QA_WIRE_NONCE_BYTES],
    struct proc17_qa_mount_identity *source_identity)
{
    unsigned char request_frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char supervisor_digest[PROC17_SHA256_BYTES];
    size_t request_bytes;
    int source = -1;
    int supervisor = -1;
    int request_pipe[2] = {-1, -1};
    int result_pipe[2] = {-1, -1};
    int child_source = -1;
    int child_supervisor = -1;
    int child_request = -1;
    int child_result = -1;
    int pidfd = -1;
    pid_t child = -1;
    int result = -1;

    if (open_probe_source(&source) != 0
        || observe_mount_identity(source, source_identity) != 0
        || open_exact_supervisor(supervisor_digest, &supervisor) != 0
        || random_nonce(nonce) != 0
        || proc17_qa_wire_encode(PROC17_QA_WIRE_PROBE_REQUEST, nonce,
            supervisor_digest, sizeof(supervisor_digest),
            request_frame, &request_bytes) != 0
        || pipe2(request_pipe, O_CLOEXEC) != 0
        || pipe2(result_pipe, O_CLOEXEC) != 0
        || (child_source = high_duplicate(source)) < 0
        || (child_supervisor = high_duplicate(supervisor)) < 0
        || (child_request = high_duplicate(request_pipe[0])) < 0
        || (child_result = high_duplicate(result_pipe[1])) < 0
        || write_exact(request_pipe[1], request_frame, request_bytes) != 0
        || close(request_pipe[1]) != 0) {
        goto cleanup;
    }
    request_pipe[1] = -1;
    child = fork();
    if (child < 0) {
        goto cleanup;
    }
    if (child == 0) {
        supervisor_exec_child(child_source, child_request, child_result,
            child_supervisor, "probe");
    }
    close(child_source);
    child_source = -1;
    close(child_supervisor);
    child_supervisor = -1;
    close(child_request);
    child_request = -1;
    close(child_result);
    child_result = -1;
    close(source);
    source = -1;
    close(supervisor);
    supervisor = -1;
    pidfd = (int)syscall(SYS_pidfd_open, child, 0U);
    close(request_pipe[0]);
    request_pipe[0] = -1;
    close(result_pipe[1]);
    result_pipe[1] = -1;
    if (pidfd < 0) {
        goto cleanup_child;
    }
    {
        int flags = fcntl(result_pipe[0], F_GETFL);
        if (flags < 0 || fcntl(result_pipe[0], F_SETFL, flags | O_NONBLOCK) != 0
            || collect_probe_result(child, pidfd, result_pipe[0],
                frame, frame_bytes) != 0) {
            goto cleanup_child;
        }
    }
    child = -1;
    result = 0;
    goto cleanup;

cleanup_child:
    if (child > 0) {
        if (pidfd >= 0) {
            (void)syscall(SYS_pidfd_send_signal, pidfd, SIGKILL, NULL, 0U);
        } else {
            (void)kill(child, SIGKILL);
        }
        (void)waitpid(child, NULL, 0);
        child = -1;
    }
cleanup:
    {
        int descriptors[] = {source, supervisor, request_pipe[0], request_pipe[1],
            result_pipe[0], result_pipe[1], child_source, child_supervisor,
            child_request, child_result, pidfd};
        size_t index;
        for (index = 0; index < sizeof(descriptors) / sizeof(descriptors[0]); index++) {
            if (descriptors[index] >= 0) {
                (void)close(descriptors[index]);
            }
        }
    }
    return result;
}

enum proc17_qa_launch_v1_status {
    PROC17_QA_LAUNCH_V1_COMPLETE = 0,
    PROC17_QA_LAUNCH_V1_UNAVAILABLE = 1,
    PROC17_QA_LAUNCH_V1_SYSTEM_FAILURE = 2,
    PROC17_QA_LAUNCH_V1_TRUSTED_INVARIANT = 3,
};

static enum proc17_qa_launch_v1_status launch_run_v1(
    int source,
    const unsigned char *request_frame,
    size_t request_bytes,
    const struct proc17_qa_launcher_v1_expectation *expectation,
    struct proc17_qa_launcher_v1_terminal *terminal)
{
    unsigned char supervisor_digest[PROC17_SHA256_BYTES];
    int supervisor = -1;
    int request_pipe[2] = {-1, -1};
    int result_pipe[2] = {-1, -1};
    int child_source = -1;
    int child_supervisor = -1;
    int child_request = -1;
    int child_result = -1;
    int pidfd = -1;
    pid_t child = -1;
    enum proc17_qa_launch_v1_status result
        = PROC17_QA_LAUNCH_V1_UNAVAILABLE;

    if (source < 0 || request_frame == NULL || request_bytes == 0U
        || expectation == NULL || terminal == NULL
        || open_exact_supervisor(supervisor_digest, &supervisor) != 0) {
        goto cleanup;
    }
    if (pipe2(request_pipe, O_CLOEXEC) != 0) goto cleanup;
    if (pipe2(result_pipe, O_CLOEXEC) != 0) goto cleanup;
    child_source = high_duplicate(source);
    if (child_source < 0) goto cleanup;
    child_supervisor = high_duplicate(supervisor);
    if (child_supervisor < 0) goto cleanup;
    child_request = high_duplicate(request_pipe[0]);
    if (child_request < 0) goto cleanup;
    child_result = high_duplicate(result_pipe[1]);
    if (child_result < 0) goto cleanup;
    if (write_exact(request_pipe[1], request_frame, request_bytes) != 0) {
        goto cleanup;
    }
    if (close(request_pipe[1]) != 0) goto cleanup;
    request_pipe[1] = -1;
    child = fork();
    if (child < 0) goto cleanup;
    result = PROC17_QA_LAUNCH_V1_SYSTEM_FAILURE;
    if (child == 0) {
        supervisor_exec_child(child_source, child_request, child_result,
            child_supervisor, "run");
    }
    close(child_source); child_source = -1;
    close(child_supervisor); child_supervisor = -1;
    close(child_request); child_request = -1;
    close(child_result); child_result = -1;
    close(supervisor); supervisor = -1;
    close(request_pipe[0]); request_pipe[0] = -1;
    close(result_pipe[1]); result_pipe[1] = -1;
    pidfd = (int)syscall(SYS_pidfd_open, child, 0U);
    if (pidfd < 0) goto cleanup_child;
    {
        int collected = proc17_qa_launcher_collect_v1(child, pidfd,
            result_pipe[0], PROC17_QA_LAUNCHER_WATCHDOG_SECONDS,
            expectation, terminal);
        if (collected == PROC17_QA_LAUNCHER_V1_INVALID_ARGUMENT) {
            goto cleanup_child;
        }
        child = -1;
        if (collected == PROC17_QA_LAUNCHER_V1_TRUSTED_INVARIANT) {
            result = PROC17_QA_LAUNCH_V1_TRUSTED_INVARIANT;
        } else if (collected == PROC17_QA_LAUNCHER_V1_OK) {
            result = PROC17_QA_LAUNCH_V1_COMPLETE;
        } else {
            result = PROC17_QA_LAUNCH_V1_SYSTEM_FAILURE;
        }
        if (collected != PROC17_QA_LAUNCHER_V1_OK) {
            goto cleanup;
        }
    }
    goto cleanup;

cleanup_child:
    if (child > 0) {
        if (pidfd >= 0) {
            (void)syscall(SYS_pidfd_send_signal, pidfd, SIGKILL, NULL, 0U);
        } else {
            (void)kill(child, SIGKILL);
        }
        (void)waitpid(child, NULL, 0);
        child = -1;
    }
cleanup:
    {
        int descriptors[] = {supervisor, request_pipe[0], request_pipe[1],
            result_pipe[0], result_pipe[1], child_source, child_supervisor,
            child_request, child_result, pidfd};
        size_t index;
        for (index = 0; index < sizeof(descriptors) / sizeof(descriptors[0]); index++) {
            if (descriptors[index] >= 0) (void)close(descriptors[index]);
        }
    }
    return result;
}

static int push_native_error(lua_State *L, const char *code, const char *stage)
{
    lua_pushnil(L);
    lua_createtable(L, 0, 5);
    lua_pushliteral(L, "qa.native_provider_error.v0");
    lua_setfield(L, -2, "protocol_version");
    lua_pushstring(L, code);
    lua_setfield(L, -2, "code");
    lua_pushstring(L, stage);
    lua_setfield(L, -2, "stage");
    lua_pushstring(L, code);
    lua_setfield(L, -2, "diagnostic");
    lua_pushliteral(L, "runtime_confirmed");
    lua_setfield(L, -2, "event_truth_status");
    return 2;
}

static void push_sha(lua_State *L, const unsigned char digest[PROC17_SHA256_BYTES])
{
    char hexadecimal[PROC17_SHA256_BYTES * 2U + 1U];
    char tagged[sizeof("sha256:") - 1U + sizeof(hexadecimal)];
    proc17_sha256_hex(digest, hexadecimal);
    snprintf(tagged, sizeof(tagged), "sha256:%s", hexadecimal);
    lua_pushstring(L, tagged);
}

static int probe_environment(lua_State *L)
{
    unsigned char frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char nonce[PROC17_QA_WIRE_NONCE_BYTES];
    unsigned char expected_supervisor[PROC17_SHA256_BYTES];
    unsigned char expected_runtime[PROC17_SHA256_BYTES];
    unsigned char expected_closure[PROC17_SHA256_BYTES];
    unsigned char expected_policy[PROC17_SHA256_BYTES];
    struct proc17_qa_wire_view view;
    struct proc17_qa_mount_identity source_identity = {0};
    uint32_t probe_status;
    size_t frame_bytes;
    const unsigned char *payload;

    if (lua_gettop(L) != 0) {
        return luaL_error(L, "probe_environment accepts no arguments");
    }
    if (launch_probe(frame, &frame_bytes, nonce, &source_identity) != 0
        || proc17_qa_wire_decode(frame, frame_bytes, &view) != 0
        || view.kind != PROC17_QA_WIRE_PROBE_RESULT
        || view.payload_bytes != PROC17_QA_PROBE_RESULT_BYTES
        || memcmp(view.nonce, nonce, sizeof(nonce)) != 0
        || proc17_sha256_parse_hex(
            PROC17_QA_EXPECTED_SUPERVISOR_BUILD_ID_HEX, expected_supervisor) != 0
        || proc17_sha256_parse_hex(
            PROC17_QA_RUNTIME_BUILD_ID_HEX, expected_runtime) != 0
        || proc17_sha256_parse_hex(
            PROC17_QA_RUNTIME_DEPENDENCY_CLOSURE_ID_HEX, expected_closure) != 0
        || proc17_sha256_parse_hex(PROC17_QA_POLICY_DIGEST_HEX,
            expected_policy) != 0) {
        return push_native_error(L, "environment_probe_unavailable",
            "probe_transaction");
    }
    payload = view.payload;
    probe_status = proc17_qa_wire_get_u32(payload);
    if (probe_status != 0U) {
        static const char *const stages[] = {
            "probe_complete", "static_self_test", "request_frame",
            "probe_source", "namespace_probe", "identity_mapping",
            "mount_world", "restricted_lua", "seccomp_policy", "complete_reap",
            "mount_private_propagation", "mount_tmpfs_root",
            "mount_root_construction", "mount_source_bind",
            "mount_source_policy", "mount_scratch",
            "mount_pivot_root", "mount_root_policy",
            "candidate_resource_limits", "candidate_environment",
            "lua_state", "lua_load", "lua_runtime",
            "lua_runtime_version", "lua_package_path", "lua_package_cpath",
            "lua_native_loader", "lua_debug_library", "lua_io_authority",
            "lua_os_authority", "lua_home", "lua_tmpdir", "lua_lang",
            "lua_lc_all", "lua_timezone", "lua_host_path", "lua_source_write",
            "lua_scratch_write",
            "output_pipe", "candidate_fork", "candidate_stdio",
            "output_pipe_flags", "candidate_pidfd", "output_empty",
            "source_mutated", "scratch_missing",
            "output_write",
            "source_locator", "source_self_bind", "source_clone",
            "source_self_bind_detach", "source_harden",
            "source_attach", "source_attestation",
            "source_readlink", "source_deleted", "source_locator_identity",
        };
        char signal_stage[64];
        const char *stage;
        if (probe_status >= 64U && probe_status < 128U) {
            snprintf(signal_stage, sizeof(signal_stage), "candidate_signal_%u",
                probe_status - 64U);
            stage = signal_stage;
        } else {
            stage = probe_status < sizeof(stages) / sizeof(stages[0])
                ? stages[probe_status] : "unknown_probe_status";
        }
        return push_native_error(L, "environment_probe_unavailable", stage);
    }
    if (proc17_qa_wire_get_u32(payload + 4U)
            != PROC17_QA_REQUIRED_PROBE_FEATURES
        || memcmp(payload + 8U, expected_supervisor, PROC17_SHA256_BYTES) != 0
        || memcmp(payload + 40U, expected_runtime, PROC17_SHA256_BYTES) != 0
        || memcmp(payload + 72U, expected_closure, PROC17_SHA256_BYTES) != 0
        || memcmp(payload + 104U, expected_policy, PROC17_SHA256_BYTES) != 0) {
        return push_native_error(L, "environment_probe_rejected",
            "probe_result_validation");
    }
    if (proc17_qa_wire_get_u16(payload + 200U)
            != PROC17_QA_SOURCE_POLICY_DETACHED_MOUNT_V0
        || payload[202U] != 0U || payload[203U] != 0U
        || proc17_qa_wire_get_u32(payload + 204U)
            != PROC17_QA_SOURCE_MOUNT_REQUIRED
        || proc17_qa_wire_get_u64(payload + 208U) != source_identity.device
        || proc17_qa_wire_get_u64(payload + 216U) != source_identity.inode
        || proc17_qa_wire_get_u64(payload + 224U) != source_identity.mount_id
        || proc17_qa_wire_get_u64(payload + 232U) != source_identity.device
        || proc17_qa_wire_get_u64(payload + 240U) != source_identity.inode
        || proc17_qa_wire_get_u64(payload + 256U)
            != proc17_qa_wire_get_u64(payload + 232U)
        || proc17_qa_wire_get_u64(payload + 264U)
            != proc17_qa_wire_get_u64(payload + 240U)
        || proc17_qa_wire_get_u64(payload + 272U)
            != proc17_qa_wire_get_u64(payload + 248U)
        || payload[280U] != 1U || payload[281U] != 1U
        || payload[282U] != 0U || payload[283U] != 0U
        || proc17_qa_wire_get_u64(payload + 284U)
            != PROC17_QA_RUNTIME_HEAP_BYTES) {
        return push_native_error(L, "environment_probe_rejected",
            "source_staging_attestation");
    }

    lua_createtable(L, 0, 15);
    lua_pushliteral(L, "qa.native_probe.v1");
    lua_setfield(L, -2, "protocol_version");
    lua_pushliteral(L, PROC17_QA_PROVIDER_ID);
    lua_setfield(L, -2, "provider_id");
    lua_pushliteral(L, PROC17_QA_SUPERVISOR_ABI);
    lua_setfield(L, -2, "supervisor_abi");
    push_sha(L, payload + 8U);
    lua_setfield(L, -2, "supervisor_build_id");
    push_sha(L, payload + 72U);
    lua_setfield(L, -2, "runtime_dependency_closure_id");
    lua_pushliteral(L, "Lua 5.4");
    lua_setfield(L, -2, "runtime_name");
    push_sha(L, payload + 40U);
    lua_setfield(L, -2, "runtime_build_id");
    lua_pushinteger(L, (lua_Integer)proc17_qa_wire_get_u64(payload + 284U));
    lua_setfield(L, -2, "runtime_heap_limit_bytes");
    lua_pushliteral(L, "linux");
    lua_setfield(L, -2, "platform");
    lua_pushliteral(L, "x86_64");
    lua_setfield(L, -2, "machine_arch");
    push_sha(L, payload + 136U);
    lua_setfield(L, -2, "kernel_identity_id");
    push_sha(L, payload + 168U);
    lua_setfield(L, -2, "isolation_feature_set_id");
    push_sha(L, payload + 104U);
    lua_setfield(L, -2, "isolation_policy_digest");
    lua_pushliteral(L, "runtime_confirmed");
    lua_setfield(L, -2, "event_truth_status");
    return 1;
}

struct proc17_qa_launcher_run {
    unsigned char transaction[PROC17_SHA256_BYTES];
    unsigned char witness[PROC17_SHA256_BYTES];
    unsigned char profile[PROC17_SHA256_BYTES];
    unsigned char environment[PROC17_SHA256_BYTES];
    uint64_t limits[PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS];
    char entrypoint[1025];
    struct proc17_qa_launcher_v1_terminal terminal;
    int trusted_invariant;
};

static int exact_table_keys(
    lua_State *L,
    int index,
    const char *const *keys,
    size_t count)
{
    size_t found = 0;
    index = lua_absindex(L, index);
    if (!lua_istable(L, index) || lua_getmetatable(L, index)) {
        if (lua_gettop(L) > index) lua_pop(L, 1);
        return -1;
    }
    lua_pushnil(L);
    while (lua_next(L, index) != 0) {
        const char *key = lua_tostring(L, -2);
        size_t item;
        int known = 0;
        if (key == NULL || lua_type(L, -2) != LUA_TSTRING) {
            lua_pop(L, 2);
            return -1;
        }
        for (item = 0; item < count; item++) {
            if (strcmp(key, keys[item]) == 0) { known = 1; break; }
        }
        if (!known) { lua_pop(L, 2); return -1; }
        found++;
        lua_pop(L, 1);
    }
    if (found != count) return -1;
    for (found = 0; found < count; found++) {
        lua_getfield(L, index, keys[found]);
        if (lua_isnil(L, -1)) { lua_pop(L, 1); return -1; }
        lua_pop(L, 1);
    }
    return 0;
}

static int exact_string(
    lua_State *L,
    int index,
    const char *field,
    const char *expected)
{
    const char *value;
    size_t bytes;
    lua_getfield(L, index, field);
    value = lua_tolstring(L, -1, &bytes);
    if (value == NULL || lua_type(L, -1) != LUA_TSTRING
        || strlen(expected) != bytes || memcmp(value, expected, bytes) != 0) {
        lua_pop(L, 1);
        return -1;
    }
    lua_pop(L, 1);
    return 0;
}

static int tagged_digest_field(
    lua_State *L,
    int index,
    const char *field,
    const char *prefix,
    unsigned char output[PROC17_SHA256_BYTES])
{
    const char *value;
    size_t bytes;
    size_t prefix_bytes = strlen(prefix);
    int result = -1;
    lua_getfield(L, index, field);
    value = lua_tolstring(L, -1, &bytes);
    if (value != NULL && lua_type(L, -1) == LUA_TSTRING
        && bytes == prefix_bytes + PROC17_SHA256_BYTES * 2U
        && memcmp(value, prefix, prefix_bytes) == 0
        && proc17_sha256_parse_hex(value + prefix_bytes, output) == 0) {
        result = 0;
    }
    lua_pop(L, 1);
    return result;
}

static int parse_native_run(lua_State *L, struct proc17_qa_launcher_run *run)
{
    static const char *const request_keys[] = {
        "protocol_version", "operation", "transaction_id", "witness_id",
        "profile_id", "environment_id", "entrypoint_relative_path",
        "expected_exit_code", "resource_limits",
    };
    static const char *const limit_keys[] = {
        "protocol_version", "wall_time_ms", "cpu_time_ms",
        "address_space_bytes", "max_processes", "max_open_files",
        "max_file_bytes", "scratch_bytes", "scratch_entries",
        "stdout_bytes", "stderr_bytes",
    };
    static const uint64_t exact_limits[PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS] = {
        PROC17_QA_WALL_TIME_MS, PROC17_QA_CPU_TIME_MS,
        PROC17_QA_ADDRESS_SPACE_BYTES, PROC17_QA_MAX_PROCESSES,
        PROC17_QA_MAX_OPEN_FILES, PROC17_QA_MAX_FILE_BYTES,
        PROC17_QA_SCRATCH_BYTES, PROC17_QA_SCRATCH_ENTRIES,
        PROC17_QA_STDOUT_BYTES, PROC17_QA_STDERR_BYTES,
    };
    static const char *const limit_names[PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS] = {
        "wall_time_ms", "cpu_time_ms", "address_space_bytes",
        "max_processes", "max_open_files", "max_file_bytes",
        "scratch_bytes", "scratch_entries", "stdout_bytes", "stderr_bytes",
    };
    const char *entrypoint;
    size_t entrypoint_bytes;
    size_t index;

    memset(run, 0, sizeof(*run));
    if (exact_table_keys(L, 2, request_keys,
            sizeof(request_keys) / sizeof(request_keys[0])) != 0
        || exact_string(L, 2, "protocol_version", "qa.native_run_request.v1") != 0
        || exact_string(L, 2, "operation", "run_lua54_test_suite") != 0
        || tagged_digest_field(L, 2, "transaction_id",
            "qa-provider-transaction:", run->transaction) != 0
        || tagged_digest_field(L, 2, "witness_id",
            "qa-provider-witness:", run->witness) != 0
        || exact_string(L, 2, "profile_id",
            "qa.profile.lua54_test_suite.v0") != 0
        || tagged_digest_field(L, 2, "environment_id",
            "qa-environment:", run->environment) != 0) {
        return -1;
    }
    proc17_sha256_bytes("qa.profile.lua54_test_suite.v0",
        sizeof("qa.profile.lua54_test_suite.v0") - 1U, run->profile);
    lua_getfield(L, 2, "entrypoint_relative_path");
    entrypoint = lua_tolstring(L, -1, &entrypoint_bytes);
    if (entrypoint == NULL || lua_type(L, -1) != LUA_TSTRING
        || entrypoint_bytes != sizeof("tests/run.lua") - 1U
        || memcmp(entrypoint, "tests/run.lua", entrypoint_bytes) != 0) {
        lua_pop(L, 1);
        return -1;
    }
    memcpy(run->entrypoint, entrypoint, entrypoint_bytes);
    run->entrypoint[entrypoint_bytes] = '\0';
    lua_pop(L, 1);
    lua_getfield(L, 2, "expected_exit_code");
    if (!lua_isinteger(L, -1) || lua_tointeger(L, -1) != 0) {
        lua_pop(L, 1);
        return -1;
    }
    lua_pop(L, 1);
    lua_getfield(L, 2, "resource_limits");
    if (exact_table_keys(L, -1, limit_keys,
            sizeof(limit_keys) / sizeof(limit_keys[0])) != 0
        || exact_string(L, -1, "protocol_version", "qa.resource_limits.v0") != 0) {
        lua_pop(L, 1);
        return -1;
    }
    for (index = 0; index < PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS; index++) {
        lua_getfield(L, -1, limit_names[index]);
        if (!lua_isinteger(L, -1)
            || (uint64_t)lua_tointeger(L, -1) != exact_limits[index]) {
            lua_pop(L, 2);
            return -1;
        }
        run->limits[index] = exact_limits[index];
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
    return 0;
}

static void set_derived_launcher_error(
    struct proc17_qa_launcher_run *run,
    uint16_t error_class,
    uint16_t error_code,
    uint16_t error_stage,
    uint8_t candidate_start_state,
    uint8_t cleanup_state,
    uint8_t launcher_reap_state,
    uint8_t result_eof_state)
{
    memset(&run->terminal, 0, sizeof(run->terminal));
    run->terminal.kind = PROC17_QA_LAUNCHER_V1_TERMINAL_DERIVED_ERROR;
    run->terminal.phase = candidate_start_state == PROC17_QA_RUN_V1_TRUE
        ? PROC17_QA_RUN_V1_PHASE_TERMINAL
        : PROC17_QA_RUN_V1_PHASE_STARTED;
    run->terminal.error_class = error_class;
    run->terminal.error_code = error_code;
    run->terminal.error_stage = error_stage;
    run->terminal.candidate_start_state = candidate_start_state;
    run->terminal.cleanup_state = cleanup_state;
    run->terminal.started_attested
        = candidate_start_state == PROC17_QA_RUN_V1_TRUE ? 1U : 0U;
    run->terminal.launcher_reap_state = launcher_reap_state;
    run->terminal.result_eof_state = result_eof_state;
}

static int run_source_consumer(int descriptor, void *opaque)
{
    struct proc17_qa_launcher_run *run = opaque;
    struct proc17_qa_mount_identity source;
    struct proc17_qa_launcher_v1_expectation expectation;
    unsigned char payload[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    unsigned char request_frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t entrypoint_bytes = strlen(run->entrypoint);
    size_t payload_bytes
        = PROC17_QA_RUN_REQUEST_V1_FIXED_BYTES + entrypoint_bytes;
    size_t request_bytes;
    size_t index;
    enum proc17_qa_launch_v1_status launched;

    if (observe_mount_identity(descriptor, &source) != 0) {
        set_derived_launcher_error(run, PROC17_QA_RUN_V1_ERROR_WORLD,
            PROC17_QA_RUN_V1_SOURCE_STAGING_FAILED,
            PROC17_QA_RUN_V1_ERROR_SOURCE_STAGING,
            PROC17_QA_RUN_V1_FALSE, PROC17_QA_RUN_V1_TRUE,
            PROC17_QA_RUN_V1_TRUE, PROC17_QA_RUN_V1_TRUE);
        return 0;
    }
    memset(payload, 0, sizeof(payload));
    memcpy(payload, run->transaction, PROC17_SHA256_BYTES);
    memcpy(payload + 32U, run->witness, PROC17_SHA256_BYTES);
    memcpy(payload + 64U, run->profile, PROC17_SHA256_BYTES);
    memcpy(payload + 96U, run->environment, PROC17_SHA256_BYTES);
    proc17_qa_wire_put_u64(payload + 128U, source.device);
    proc17_qa_wire_put_u64(payload + 136U, source.inode);
    proc17_qa_wire_put_u64(payload + 144U, source.mount_id);
    for (index = 0; index < PROC17_QA_WIRE_RESOURCE_LIMIT_FIELDS; index++) {
        proc17_qa_wire_put_u64(payload + 152U + index * 8U, run->limits[index]);
    }
    proc17_qa_wire_put_u32(payload + 232U, 0U);
    proc17_qa_wire_put_u16(payload + 236U, (uint16_t)entrypoint_bytes);
    memcpy(payload + 238U, run->entrypoint, entrypoint_bytes);
    if (proc17_qa_wire_encode_run_v1(PROC17_QA_WIRE_RUN_REQUEST_V1,
            run->transaction, payload, (uint32_t)payload_bytes,
            request_frame, &request_bytes) != 0) {
        run->trusted_invariant = 1;
        return -1;
    }
    memset(&expectation, 0, sizeof(expectation));
    memcpy(expectation.identity, payload, PROC17_QA_V1_IDENTITY_BYTES);
    expectation.source_device = source.device;
    expectation.source_inode = source.inode;
    expectation.source_mount_id = source.mount_id;
    expectation.source_mount_policy_flags = PROC17_QA_SOURCE_MOUNT_REQUIRED;
    launched = launch_run_v1(descriptor, request_frame, request_bytes,
        &expectation, &run->terminal);
    if (launched == PROC17_QA_LAUNCH_V1_COMPLETE) return 0;
    if (launched == PROC17_QA_LAUNCH_V1_TRUSTED_INVARIANT) {
        run->trusted_invariant = 1;
        return -1;
    }
    if (launched == PROC17_QA_LAUNCH_V1_UNAVAILABLE) {
        set_derived_launcher_error(run, PROC17_QA_RUN_V1_ERROR_UNAVAILABLE,
            PROC17_QA_RUN_V1_SUPERVISOR_UNAVAILABLE,
            PROC17_QA_RUN_V1_ERROR_LAUNCH,
            PROC17_QA_RUN_V1_FALSE, PROC17_QA_RUN_V1_TRUE,
            PROC17_QA_RUN_V1_TRUE, PROC17_QA_RUN_V1_TRUE);
    } else {
        run->trusted_invariant = 1;
        return -1;
    }
    return 0;
}

static void push_tagged_digest(
    lua_State *L,
    const char *prefix,
    const unsigned char value[PROC17_SHA256_BYTES])
{
    char hexadecimal[PROC17_SHA256_BYTES * 2U + 1U];
    char tagged[160];
    proc17_sha256_hex(value, hexadecimal);
    snprintf(tagged, sizeof(tagged), "%s%s", prefix, hexadecimal);
    lua_pushstring(L, tagged);
}

static void set_string(lua_State *L, const char *field, const char *value)
{
    lua_pushstring(L, value);
    lua_setfield(L, -2, field);
}

static void set_integer(lua_State *L, const char *field, uint64_t value)
{
    lua_pushinteger(L, (lua_Integer)value);
    lua_setfield(L, -2, field);
}

static void set_boolean(lua_State *L, const char *field, int value)
{
    lua_pushboolean(L, value);
    lua_setfield(L, -2, field);
}

static const char *reason_name(uint16_t value)
{
    static const char *const names[] = {
        NULL, "expected_exit", "unexpected_exit", "signal",
        "wall_timeout", "cpu_limit", "memory_limit", "output_limit",
        "scratch_limit", "sandbox_policy_violation",
    };
    return value < sizeof(names) / sizeof(names[0]) ? names[value] : NULL;
}

static const char *error_class_name(uint16_t value)
{
    static const char *const names[] = {
        NULL, "world", "unavailable", "ambiguous",
    };
    return value < sizeof(names) / sizeof(names[0]) ? names[value] : NULL;
}

static const char *error_code_name(uint16_t value)
{
    static const char *const names[] = {
        NULL, "supervisor_unavailable", "source_staging_failed",
        "supervisor_crashed", "result_pipe_lost",
        "terminal_frame_missing", "reap_ambiguous",
        "output_observation_incomplete", "scratch_observation_incomplete",
        "namespace_cleanup_incomplete",
    };
    return value < sizeof(names) / sizeof(names[0]) ? names[value] : NULL;
}

static const char *error_stage_name(uint16_t value)
{
    static const char *const names[] = {
        NULL, "preflight", "source_staging", "namespace", "launch",
        "supervision", "postflight", "cleanup",
    };
    return value < sizeof(names) / sizeof(names[0]) ? names[value] : NULL;
}

static const char *start_state_name(uint8_t value)
{
    if (value == PROC17_QA_RUN_V1_UNKNOWN) return "unknown";
    if (value == PROC17_QA_RUN_V1_FALSE) return "not_started";
    if (value == PROC17_QA_RUN_V1_TRUE) return "started";
    return NULL;
}

static const char *completion_state_name(uint8_t value)
{
    if (value == PROC17_QA_RUN_V1_UNKNOWN) return "unknown";
    if (value == PROC17_QA_RUN_V1_FALSE) return "incomplete";
    if (value == PROC17_QA_RUN_V1_TRUE) return "complete";
    return NULL;
}

static void push_run_identity(lua_State *L, const struct proc17_qa_launcher_run *run)
{
    push_tagged_digest(L, "qa-provider-transaction:", run->transaction);
    lua_setfield(L, -2, "transaction_id");
    push_tagged_digest(L, "qa-provider-witness:", run->witness);
    lua_setfield(L, -2, "witness_id");
    set_string(L, "profile_id", "qa.profile.lua54_test_suite.v0");
    push_tagged_digest(L, "qa-environment:", run->environment);
    lua_setfield(L, -2, "environment_id");
}

static void push_v1_stream(lua_State *L, const unsigned char *stream)
{
    lua_createtable(L, 0, 8);
    set_string(L, "protocol_version", "qa.stream_measurement.v1");
    set_integer(L, "observed_bytes", proc17_qa_wire_get_u64(stream));
    set_integer(L, "hashed_bytes", proc17_qa_wire_get_u64(stream + 8U));
    push_sha(L, stream + 24U);
    lua_setfield(L, -2, "sha256");
    set_integer(L, "limit_bytes", proc17_qa_wire_get_u64(stream + 16U));
    set_boolean(L, "limit_reached", stream[56U] != 0U);
    set_boolean(L, "eof_observed", stream[57U] != 0U);
    set_boolean(L, "raw_retained", stream[58U] != 0U);
}

static void push_v1_resources(lua_State *L, const unsigned char *resource)
{
    lua_createtable(L, 0, 12);
    set_string(L, "protocol_version", "qa.resource_measurement.v1");
    set_integer(L, "wall_time_ms", proc17_qa_wire_get_u64(resource));
    set_integer(L, "cpu_user_ms", proc17_qa_wire_get_u64(resource + 8U));
    set_integer(L, "cpu_system_ms", proc17_qa_wire_get_u64(resource + 16U));
    set_integer(L, "max_rss_bytes", proc17_qa_wire_get_u64(resource + 24U));
    set_integer(L, "address_space_limit_bytes",
        proc17_qa_wire_get_u64(resource + 32U));
    set_integer(L, "runtime_heap_peak_bytes",
        proc17_qa_wire_get_u64(resource + 40U));
    set_integer(L, "runtime_heap_limit_bytes",
        proc17_qa_wire_get_u64(resource + 48U));
    set_boolean(L, "runtime_heap_denied", resource[80U] != 0U);
    set_integer(L, "max_processes", proc17_qa_wire_get_u64(resource + 56U));
    set_integer(L, "max_open_files", proc17_qa_wire_get_u64(resource + 64U));
    set_integer(L, "max_file_bytes", proc17_qa_wire_get_u64(resource + 72U));
}

static void push_v1_scratch(lua_State *L, const unsigned char *scratch)
{
    lua_createtable(L, 0, 8);
    set_string(L, "protocol_version", "qa.scratch_measurement.v1");
    set_integer(L, "stored_regular_bytes",
        proc17_qa_wire_get_u64(scratch));
    set_integer(L, "stored_entries", proc17_qa_wire_get_u64(scratch + 8U));
    set_integer(L, "limit_bytes", proc17_qa_wire_get_u64(scratch + 16U));
    set_integer(L, "limit_entries", proc17_qa_wire_get_u64(scratch + 24U));
    set_boolean(L, "byte_capacity_exhausted", scratch[32U] != 0U);
    set_boolean(L, "entry_capacity_exhausted", scratch[33U] != 0U);
    set_boolean(L, "inventory_complete", scratch[34U] != 0U);
}

static int push_v1_result(
    lua_State *L,
    const struct proc17_qa_launcher_run *run)
{
    struct proc17_qa_wire_view view;
    const unsigned char *payload;
    const char *reason;
    size_t index;
    static const char *const finality_names[] = {
        "source_staging_complete", "candidate_started",
        "candidate_terminal_observed", "process_tree_reaped",
        "stdout_eof_observed", "stderr_eof_observed",
        "scratch_observation_complete", "namespace_cleanup_complete",
    };

    if (run->terminal.kind != PROC17_QA_LAUNCHER_V1_TERMINAL_RESULT
        || proc17_qa_wire_decode_run_v1(run->terminal.frame,
            run->terminal.frame_bytes, &view) != 0
        || view.kind != PROC17_QA_WIRE_RUN_RESULT_V1
        || run->terminal.started_attested != 1U) {
        return luaL_error(L, "trusted RUN v1 result invariant failed");
    }
    payload = view.payload;
    reason = reason_name(proc17_qa_wire_get_u16(payload + 132U));
    if (reason == NULL) {
        return luaL_error(L, "trusted RUN v1 reason is unknown");
    }
    lua_createtable(L, 0, 19);
    set_string(L, "protocol_version", "qa.native_run_result.v1");
    push_run_identity(L, run);
    set_integer(L, "phase_ordinal",
        proc17_qa_wire_get_u16(payload + PROC17_QA_V1_PHASE_OFFSET));
    set_string(L, "disposition", "contained_candidate");
    set_boolean(L, "start_attested", 1);
    set_string(L, "source_staging_policy",
        "qa.source_staging.detached_mount.v0");
    set_boolean(L, "source_staging_complete", 1);
    set_string(L, "reason", reason);

    lua_createtable(L, 0, 3);
    set_integer(L, "kind", proc17_qa_wire_get_u16(payload + 134U));
    set_integer(L, "exit_code", proc17_qa_wire_get_u32(payload + 136U));
    set_integer(L, "signal", proc17_qa_wire_get_u32(payload + 140U));
    lua_setfield(L, -2, "termination");

    lua_createtable(L, 0, 4);
    set_string(L, "protocol_version", "qa.first_cause.v1");
    set_string(L, "kind", reason);
    set_integer(L, "monotonic_sequence",
        proc17_qa_wire_get_u64(payload + 148U));
    set_integer(L, "observed_value",
        proc17_qa_wire_get_u64(payload + 156U));
    lua_setfield(L, -2, "cause");

    lua_createtable(L, 0, 8);
    for (index = 0U; index < 8U; index++) {
        set_boolean(L, finality_names[index],
            payload[PROC17_QA_V1_RESULT_FINALITY_OFFSET + index] != 0U);
    }
    lua_setfield(L, -2, "finality");
    push_v1_stream(L, payload + PROC17_QA_V1_RESULT_STDOUT_OFFSET);
    lua_setfield(L, -2, "stdout");
    push_v1_stream(L, payload + PROC17_QA_V1_RESULT_STDERR_OFFSET);
    lua_setfield(L, -2, "stderr");
    push_v1_resources(L, payload + PROC17_QA_V1_RESULT_RESOURCE_OFFSET);
    lua_setfield(L, -2, "resources");
    push_v1_scratch(L, payload + PROC17_QA_V1_RESULT_SCRATCH_OFFSET);
    lua_setfield(L, -2, "scratch");
    set_string(L, "event_truth_status", "runtime_confirmed");
    return 1;
}

static int push_v1_error(
    lua_State *L,
    const struct proc17_qa_launcher_run *run)
{
    const struct proc17_qa_launcher_v1_terminal *terminal = &run->terminal;
    const char *error_class = error_class_name(terminal->error_class);
    const char *error_code = error_code_name(terminal->error_code);
    const char *error_stage = error_stage_name(terminal->error_stage);
    const char *start_state = start_state_name(terminal->candidate_start_state);
    const char *cleanup_state = completion_state_name(terminal->cleanup_state);
    const char *reap_state = completion_state_name(terminal->launcher_reap_state);
    const char *eof_state = completion_state_name(terminal->result_eof_state);

    if (terminal->kind == PROC17_QA_LAUNCHER_V1_TERMINAL_ERROR) {
        struct proc17_qa_wire_view view;
        if (proc17_qa_wire_decode_run_v1(terminal->frame,
                terminal->frame_bytes, &view) != 0
            || view.kind != PROC17_QA_WIRE_RUN_ERROR_V1
            || view.payload[138U] != 0U) {
            return luaL_error(L,
                "trusted RUN v1 error or measured-cost invariant failed");
        }
    }
    if ((terminal->kind != PROC17_QA_LAUNCHER_V1_TERMINAL_ERROR
            && terminal->kind
                != PROC17_QA_LAUNCHER_V1_TERMINAL_DERIVED_ERROR)
        || error_class == NULL || error_code == NULL || error_stage == NULL
        || start_state == NULL || cleanup_state == NULL
        || reap_state == NULL || eof_state == NULL) {
        return luaL_error(L, "trusted RUN v1 error state is malformed");
    }
    lua_pushnil(L);
    lua_createtable(L, 0, 14);
    set_string(L, "protocol_version", "qa.native_run_error.v1");
    push_run_identity(L, run);
    set_integer(L, "phase_ordinal", terminal->phase);
    set_string(L, "class", error_class);
    set_string(L, "code", error_code);
    set_string(L, "stage", error_stage);
    set_string(L, "candidate_start_state", start_state);
    set_string(L, "cleanup_state", cleanup_state);
    set_string(L, "launcher_reaped", reap_state);
    set_string(L, "result_eof", eof_state);
    set_string(L, "event_truth_status", "runtime_confirmed");
    return 2;
}

static int run_lua54_test_suite(lua_State *L)
{
    struct proc17_qa_launcher_run run;
    int status;
    if (lua_gettop(L) != 2) {
        return luaL_error(L, "run_lua54_test_suite requires exactly two arguments");
    }
    if (parse_native_run(L, &run) != 0) {
        return luaL_error(L, "RUN v1 request rejected by native boundary");
    }
    status = proc17_qa_with_repository_source(
        L, 1, run_source_consumer, &run);
    if (status != PROC17_QA_SOURCE_OK) {
        if (run.trusted_invariant) {
            return luaL_error(L, "trusted RUN v1 sequence invariant failed");
        }
        set_derived_launcher_error(&run, PROC17_QA_RUN_V1_ERROR_WORLD,
            PROC17_QA_RUN_V1_SOURCE_STAGING_FAILED,
            PROC17_QA_RUN_V1_ERROR_SOURCE_STAGING,
            PROC17_QA_RUN_V1_FALSE, PROC17_QA_RUN_V1_TRUE,
            PROC17_QA_RUN_V1_TRUE, PROC17_QA_RUN_V1_TRUE);
        return push_v1_error(L, &run);
    }
    if (run.terminal.kind == PROC17_QA_LAUNCHER_V1_TERMINAL_RESULT) {
        return push_v1_result(L, &run);
    }
    return push_v1_error(L, &run);
}

static void push_limits(lua_State *L)
{
    lua_createtable(L, 0, 11);
    lua_pushliteral(L, "qa.resource_limits.v0");
    lua_setfield(L, -2, "protocol_version");
#define PROC17_QA_PUSH_LIMIT(name, value) \
    do { lua_pushinteger(L, (lua_Integer)(value)); lua_setfield(L, -2, name); } while (0)
    PROC17_QA_PUSH_LIMIT("wall_time_ms", PROC17_QA_WALL_TIME_MS);
    PROC17_QA_PUSH_LIMIT("cpu_time_ms", PROC17_QA_CPU_TIME_MS);
    PROC17_QA_PUSH_LIMIT("address_space_bytes", PROC17_QA_ADDRESS_SPACE_BYTES);
    PROC17_QA_PUSH_LIMIT("max_processes", PROC17_QA_MAX_PROCESSES);
    PROC17_QA_PUSH_LIMIT("max_open_files", PROC17_QA_MAX_OPEN_FILES);
    PROC17_QA_PUSH_LIMIT("max_file_bytes", PROC17_QA_MAX_FILE_BYTES);
    PROC17_QA_PUSH_LIMIT("scratch_bytes", PROC17_QA_SCRATCH_BYTES);
    PROC17_QA_PUSH_LIMIT("scratch_entries", PROC17_QA_SCRATCH_ENTRIES);
    PROC17_QA_PUSH_LIMIT("stdout_bytes", PROC17_QA_STDOUT_BYTES);
    PROC17_QA_PUSH_LIMIT("stderr_bytes", PROC17_QA_STDERR_BYTES);
#undef PROC17_QA_PUSH_LIMIT
}

int luaopen_proc17_qa_launcher(lua_State *L)
{
    lua_createtable(L, 0, 10);
    lua_pushliteral(L, PROC17_QA_LAUNCHER_PROTOCOL);
    lua_setfield(L, -2, "protocol_version");
    lua_pushliteral(L, PROC17_QA_LAUNCHER_ABI);
    lua_setfield(L, -2, "abi_version");
    lua_pushliteral(L, PROC17_QA_PROVIDER_ID);
    lua_setfield(L, -2, "provider_id");
    lua_pushliteral(L, PROC17_QA_SUPERVISOR_ABI);
    lua_setfield(L, -2, "supervisor_abi");
    lua_pushliteral(L, "sha256:" PROC17_QA_EXPECTED_SUPERVISOR_BUILD_ID_HEX);
    lua_setfield(L, -2, "expected_supervisor_build_id");
    lua_pushliteral(L, "sha256:" PROC17_QA_RUNTIME_BUILD_ID_HEX);
    lua_setfield(L, -2, "runtime_build_id");
    lua_pushliteral(L, "sha256:" PROC17_QA_POLICY_DIGEST_HEX);
    lua_setfield(L, -2, "policy_digest");
    push_limits(L);
    lua_setfield(L, -2, "limits");
    lua_pushcfunction(L, probe_environment);
    lua_setfield(L, -2, "probe_environment");
    lua_pushcfunction(L, run_lua54_test_suite);
    lua_setfield(L, -2, "run_lua54_test_suite");
    return 1;
}
