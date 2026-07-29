#define _GNU_SOURCE

#include "proc17_qa_residue_observer.h"

#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <limits.h>
#include <sched.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/prctl.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define OBSERVER_MODULE "./tests/proc17_qa_residue_observer.so"
#define SUPERVISOR_PATH "./proc17_qa_supervisor"
#define CONTROL_COUNT 15U

struct observer_fixture {
    struct proc17_qa_residue_session *session;
    struct proc17_qa_residue_snapshot *baseline;
    struct proc17_qa_residue_projection baseline_projection;
};

struct control {
    const char *id;
    const char *description;
    int (*run)(const struct proc17_qa_residue_api *api);
};

static void report_fixture_failure(
    const struct proc17_qa_residue_api *api,
    struct observer_fixture *fixture,
    const struct proc17_qa_residue_error *error,
    const char *stage)
{
    struct proc17_qa_residue_snapshot *snapshot = NULL;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_error diagnostic_error;

    fprintf(stderr,
        "qa-residue-observer fixture failure: stage=%s code=%s owner=%s errno=%d\n",
        stage, error->code[0] == '\0' ? "none" : error->code,
        error->stage[0] == '\0' ? "none" : error->stage,
        error->system_errno);
    if (fixture->session == NULL
        || strcmp(error->code, "dirty_precondition") != 0) {
        return;
    }
    memset(&projection, 0, sizeof(projection));
    memset(&diagnostic_error, 0, sizeof(diagnostic_error));
    if (api->capture(fixture->session, PROC17_QA_RESIDUE_FINAL,
            NULL, &snapshot, &projection, &diagnostic_error) == 0) {
        fprintf(stderr,
            "qa-residue-observer dirty channels: live=%" PRIu64
            " zombie=%" PRIu64 " supervisor=%" PRIu64
            " unresolved=%" PRIu64 " mounts=%" PRIu64
            " roots=%" PRIu64 "\n",
            projection.direct_live_child_count,
            projection.direct_zombie_count,
            projection.matching_supervisor_process_count,
            projection.unresolved_supervisor_zombie_count,
            projection.qa_host_mount_count,
            projection.owned_root_count);
    } else {
        fprintf(stderr,
            "qa-residue-observer diagnostic capture failed: code=%s stage=%s errno=%d\n",
            diagnostic_error.code, diagnostic_error.stage,
            diagnostic_error.system_errno);
    }
    if (snapshot != NULL) api->snapshot_destroy(snapshot);
}

static void close_if_open(int *descriptor)
{
    if (*descriptor >= 0) {
        (void)close(*descriptor);
        *descriptor = -1;
    }
}

static int write_all(int descriptor, const char *bytes, size_t length)
{
    while (length > 0U) {
        ssize_t written = write(descriptor, bytes, length);
        if (written < 0 && errno == EINTR) continue;
        if (written <= 0) return -1;
        bytes += (size_t)written;
        length -= (size_t)written;
    }
    return 0;
}

static int write_text_file(const char *path, const char *text)
{
    int descriptor = open(path, O_WRONLY | O_CLOEXEC);
    size_t length = strlen(text);
    int result = -1;

    if (descriptor < 0) return -1;
    if (write_all(descriptor, text, length) == 0) {
        int closing = descriptor;
        descriptor = -1;
        if (close(closing) == 0) result = 0;
    }
    close_if_open(&descriptor);
    return result;
}

static int fixture_open(
    const struct proc17_qa_residue_api *api,
    struct observer_fixture *fixture)
{
    struct proc17_qa_residue_error error;

    memset(fixture, 0, sizeof(*fixture));
    memset(&error, 0, sizeof(error));
    if (api->session_open(&fixture->session, &error) != 0
        || fixture->session == NULL) {
        report_fixture_failure(api, fixture, &error, "session_open");
        goto failure;
    }
    if (api->capture(fixture->session, PROC17_QA_RESIDUE_BASELINE,
            NULL, &fixture->baseline, &fixture->baseline_projection,
            &error) != 0 || fixture->baseline == NULL) {
        report_fixture_failure(api, fixture, &error, "baseline_capture");
        goto failure;
    }
    if (fixture->baseline_projection.abi_version
            != PROC17_QA_RESIDUE_C_ABI
        || fixture->baseline_projection.scope
            != PROC17_QA_RESIDUE_BASELINE
        || fixture->baseline_projection.event_truth_runtime_confirmed != 1U) {
        memset(&error, 0, sizeof(error));
        strcpy(error.code, "baseline_projection_invalid");
        strcpy(error.stage, "fixture_open");
        report_fixture_failure(api, fixture, &error, "projection_contract");
        goto failure;
    }
    return 0;

failure:
    if (fixture->baseline != NULL) {
        api->snapshot_destroy(fixture->baseline);
        fixture->baseline = NULL;
    }
    if (fixture->session != NULL) {
        api->session_destroy(fixture->session);
        fixture->session = NULL;
    }
    return -1;
}

static void fixture_close(
    const struct proc17_qa_residue_api *api,
    struct observer_fixture *fixture)
{
    if (fixture->baseline != NULL) {
        api->snapshot_destroy(fixture->baseline);
        fixture->baseline = NULL;
    }
    if (fixture->session != NULL) {
        api->session_destroy(fixture->session);
        fixture->session = NULL;
    }
}

static int capture_final(
    const struct proc17_qa_residue_api *api,
    struct observer_fixture *fixture,
    struct proc17_qa_residue_projection *projection,
    struct proc17_qa_residue_delta *delta)
{
    struct proc17_qa_residue_snapshot *snapshot = NULL;
    struct proc17_qa_residue_error error;
    int result = -1;

    memset(&error, 0, sizeof(error));
    memset(projection, 0, sizeof(*projection));
    memset(delta, 0, sizeof(*delta));
    if (api->capture(fixture->session, PROC17_QA_RESIDUE_FINAL,
            NULL, &snapshot, projection, &error) != 0
        || snapshot == NULL
        || api->compare(fixture->baseline, snapshot, delta, &error) != 0) {
        goto cleanup;
    }
    result = 0;

cleanup:
    if (snapshot != NULL) api->snapshot_destroy(snapshot);
    return result;
}

static int test_clean_snapshot(const struct proc17_qa_residue_api *api)
{
    struct observer_fixture fixture;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_delta delta;
    int result = -1;

    if (fixture_open(api, &fixture) != 0) return -1;
    if (capture_final(api, &fixture, &projection, &delta) == 0
        && delta.exact == 1U
        && delta.event_truth_runtime_confirmed == 1U) {
        result = 0;
    }
    fixture_close(api, &fixture);
    return result;
}

static int make_temp_file(char path[64], const char *template)
{
    int descriptor;

    if (strlen(template) >= 64U) return -1;
    strcpy(path, template);
    descriptor = mkstemp(path);
    if (descriptor < 0) return -1;
    if (write_all(descriptor, "identity\n", 9U) != 0) {
        close_if_open(&descriptor);
        (void)unlink(path);
        return -1;
    }
    {
        int closing = descriptor;
        descriptor = -1;
        if (close(closing) == 0) return 0;
    }
    (void)unlink(path);
    return -1;
}

static int test_fd_identity_exchange(const struct proc17_qa_residue_api *api)
{
    char first[64] = {0};
    char second[64] = {0};
    struct observer_fixture fixture;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_delta delta;
    struct proc17_qa_residue_error error;
    int original = -1;
    int replacement = -1;
    int original_number = -1;
    int result = -1;

    memset(&fixture, 0, sizeof(fixture));
    memset(&error, 0, sizeof(error));
    if (make_temp_file(first, "/tmp/proc17-qa-fd-a-XXXXXX") != 0
        || make_temp_file(second, "/tmp/proc17-qa-fd-b-XXXXXX") != 0
        || api->session_open(&fixture.session, &error) != 0) {
        goto cleanup;
    }
    original = open(first, O_RDONLY | O_CLOEXEC);
    if (original < 0) goto cleanup;
    original_number = original;
    if (api->capture(fixture.session, PROC17_QA_RESIDUE_BASELINE,
            NULL, &fixture.baseline, &fixture.baseline_projection,
            &error) != 0) {
        goto cleanup;
    }
    close_if_open(&original);
    replacement = open(second, O_RDONLY | O_CLOEXEC);
    if (replacement < 0) goto cleanup;
    if (replacement != original_number) {
        if (dup3(replacement, original_number, O_CLOEXEC) < 0) goto cleanup;
        close_if_open(&replacement);
        replacement = original_number;
    }
    if (capture_final(api, &fixture, &projection, &delta) == 0
        && projection.parent_fd_count
            == fixture.baseline_projection.parent_fd_count
        && delta.fd_opened == 0U && delta.fd_missing == 0U
        && delta.fd_identity_changed >= 1U && delta.exact == 0U) {
        result = 0;
    }

cleanup:
    close_if_open(&original);
    close_if_open(&replacement);
    fixture_close(api, &fixture);
    if (first[0] != '\0') (void)unlink(first);
    if (second[0] != '\0') (void)unlink(second);
    return result;
}

static int wait_for_zombie(pid_t child)
{
    siginfo_t information;

    memset(&information, 0, sizeof(information));
    while (waitid(P_PID, (id_t)child, &information,
            WEXITED | WNOWAIT) != 0) {
        if (errno != EINTR) return -1;
    }
    return information.si_pid == child ? 0 : -1;
}

static int test_direct_live_child(const struct proc17_qa_residue_api *api)
{
    struct observer_fixture fixture;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_delta delta;
    pid_t child = -1;
    int result = -1;

    if (fixture_open(api, &fixture) != 0) return -1;
    child = fork();
    if (child < 0) goto cleanup;
    if (child == 0) {
        for (;;) pause();
    }
    if (capture_final(api, &fixture, &projection, &delta) == 0
        && projection.direct_live_child_count >= 1U
        && delta.direct_live_children >= 1U && delta.exact == 0U) {
        result = 0;
    }

cleanup:
    if (child > 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
    }
    fixture_close(api, &fixture);
    return result;
}

static int test_direct_zombie(const struct proc17_qa_residue_api *api)
{
    struct observer_fixture fixture;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_delta delta;
    pid_t child = -1;
    int result = -1;

    if (fixture_open(api, &fixture) != 0) return -1;
    child = fork();
    if (child < 0) goto cleanup;
    if (child == 0) _exit(0);
    if (wait_for_zombie(child) != 0) goto cleanup;
    if (capture_final(api, &fixture, &projection, &delta) == 0
        && projection.direct_zombie_count >= 1U
        && delta.direct_zombies >= 1U && delta.exact == 0U) {
        result = 0;
    }

cleanup:
    if (child > 0) (void)waitpid(child, NULL, 0);
    fixture_close(api, &fixture);
    return result;
}

static int test_namespace_fd(const struct proc17_qa_residue_api *api)
{
    struct observer_fixture fixture;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_delta delta;
    int namespace_fd = -1;
    int result = -1;

    if (fixture_open(api, &fixture) != 0) return -1;
    namespace_fd = open("/proc/self/ns/mnt", O_RDONLY | O_CLOEXEC);
    if (namespace_fd >= 0
        && capture_final(api, &fixture, &projection, &delta) == 0
        && delta.fd_opened >= 1U && delta.exact == 0U) {
        result = 0;
    }
    close_if_open(&namespace_fd);
    fixture_close(api, &fixture);
    return result;
}

static int enter_private_user_mount_namespace(void)
{
    char map[128];
    uid_t uid = getuid();
    gid_t gid = getgid();

    if (unshare(CLONE_NEWUSER | CLONE_NEWNS) != 0) return -1;
    if (write_text_file("/proc/self/setgroups", "deny\n") != 0
        && errno != ENOENT) {
        return -1;
    }
    if (snprintf(map, sizeof(map), "0 %lu 1\n",
            (unsigned long)uid) <= 0
        || write_text_file("/proc/self/uid_map", map) != 0
        || snprintf(map, sizeof(map), "0 %lu 1\n",
            (unsigned long)gid) <= 0
        || write_text_file("/proc/self/gid_map", map) != 0
        || setresgid(0, 0, 0) != 0 || setresuid(0, 0, 0) != 0
        || mount(NULL, "/", NULL, MS_REC | MS_PRIVATE, NULL) != 0) {
        return -1;
    }
    return 0;
}

static int namespace_change_child(const struct proc17_qa_residue_api *api)
{
    struct observer_fixture fixture;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_delta delta;
    int result = 1;

    if (fixture_open(api, &fixture) != 0) return 1;
    if (enter_private_user_mount_namespace() == 0
        && capture_final(api, &fixture, &projection, &delta) == 0
        && delta.parent_namespace_changed == 1U && delta.exact == 0U) {
        result = 0;
    }
    fixture_close(api, &fixture);
    return result;
}

static int run_child_control(
    const struct proc17_qa_residue_api *api,
    int (*child_control)(const struct proc17_qa_residue_api *api))
{
    pid_t child = fork();
    int status = 0;

    if (child < 0) return -1;
    if (child == 0) _exit(child_control(api) == 0 ? 0 : 1);
    while (waitpid(child, &status, 0) < 0) {
        if (errno != EINTR) return -1;
    }
    return WIFEXITED(status) && WEXITSTATUS(status) == 0 ? 0 : -1;
}

static int test_namespace_change(const struct proc17_qa_residue_api *api)
{
    return run_child_control(api, namespace_change_child);
}

static int make_mount_root(char root[PATH_MAX])
{
    char template[] = "/tmp/proc17-qa-observer-ns-XXXXXX";
    char path[PATH_MAX];

    if (mkdtemp(template) == NULL) return -1;
    strcpy(root, template);
    if (snprintf(path, sizeof(path), "%s/proc", root) <= 0
        || mkdir(path, 0700) != 0
        || snprintf(path, sizeof(path), "%s/qa", root) <= 0
        || mkdir(path, 0700) != 0
        || snprintf(path, sizeof(path), "%s/tmp", root) <= 0
        || mkdir(path, 0700) != 0) {
        return -1;
    }
    return 0;
}

static void cleanup_mount_root(const char *root)
{
    char path[PATH_MAX];

    if (root == NULL || root[0] == '\0') return;
    if (snprintf(path, sizeof(path), "%s/proc", root) > 0) (void)rmdir(path);
    if (snprintf(path, sizeof(path), "%s/qa", root) > 0) (void)rmdir(path);
    if (snprintf(path, sizeof(path), "%s/tmp", root) > 0) (void)rmdir(path);
    (void)rmdir(root);
}

static int mount_change_child(
    const struct proc17_qa_residue_api *api,
    const char *root)
{
    struct observer_fixture fixture;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_delta delta;
    char proc_path[PATH_MAX];
    char qa_path[PATH_MAX];
    int result = 1;

    if (fixture_open(api, &fixture) != 0
        || enter_private_user_mount_namespace() != 0
        || snprintf(proc_path, sizeof(proc_path), "%s/proc", root) <= 0
        || snprintf(qa_path, sizeof(qa_path), "%s/qa", root) <= 0
        || mount("/proc", proc_path, NULL, MS_BIND | MS_REC, NULL) != 0
        || mount("tmpfs", qa_path, "tmpfs",
            MS_NOSUID | MS_NODEV | MS_NOEXEC, "size=4096") != 0
        || chroot(root) != 0 || chdir("/") != 0) {
        fixture_close(api, &fixture);
        return 1;
    }
    if (capture_final(api, &fixture, &projection, &delta) == 0
        && projection.qa_host_mount_count >= 1U
        && delta.qa_host_mounts >= 1U
        && delta.parent_namespace_changed == 1U && delta.exact == 0U) {
        result = 0;
    }
    fixture_close(api, &fixture);
    return result;
}

static int test_private_qa_mount(const struct proc17_qa_residue_api *api)
{
    char root[PATH_MAX] = {0};
    pid_t child = -1;
    int status = 0;
    int result = -1;

    if (make_mount_root(root) != 0) goto cleanup;
    child = fork();
    if (child < 0) goto cleanup;
    if (child == 0) _exit(mount_change_child(api, root) == 0 ? 0 : 1);
    while (waitpid(child, &status, 0) < 0) {
        if (errno != EINTR) goto cleanup;
    }
    child = -1;
    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) result = 0;

cleanup:
    if (child > 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
    }
    cleanup_mount_root(root);
    return result;
}

static int test_owned_root_residue(const struct proc17_qa_residue_api *api)
{
    char root[] = "/tmp/proc17-repository-hand-XXXXXX";
    struct observer_fixture fixture;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_delta delta;
    int made = 0;
    int result = -1;

    if (fixture_open(api, &fixture) != 0) return -1;
    if (mkdtemp(root) == NULL) goto cleanup;
    made = 1;
    if (capture_final(api, &fixture, &projection, &delta) == 0
        && projection.owned_root_count >= 1U
        && delta.owned_roots_added >= 1U && delta.exact == 0U) {
        result = 0;
    }

cleanup:
    if (made) (void)rmdir(root);
    fixture_close(api, &fixture);
    return result;
}

static int test_truncated_parsers(const struct proc17_qa_residue_api *api)
{
    static const char bad_stat[] = "10 (unterminated S 1";
    static const char bad_mount[] = "36 25 0:32 / /qa rw -";
    struct proc17_qa_residue_process_record record;
    struct proc17_qa_residue_error error;
    uint64_t mounts = 0U;

    memset(&record, 0, sizeof(record));
    memset(&error, 0, sizeof(error));
    if (api->test_parse_proc_stat(bad_stat, sizeof(bad_stat) - 1U,
            &record, &error) == 0 || error.code[0] == '\0') {
        return -1;
    }
    memset(&error, 0, sizeof(error));
    return api->test_parse_mountinfo(bad_mount, sizeof(bad_mount) - 1U,
        &mounts, &error) != 0 && error.code[0] != '\0' ? 0 : -1;
}

static int test_equal_repeated_snapshots(
    const struct proc17_qa_residue_api *api)
{
    struct observer_fixture fixture;
    struct proc17_qa_residue_projection first_projection;
    struct proc17_qa_residue_projection second_projection;
    struct proc17_qa_residue_delta first_delta;
    struct proc17_qa_residue_delta second_delta;
    int result = -1;

    if (fixture_open(api, &fixture) != 0) return -1;
    if (capture_final(api, &fixture, &first_projection, &first_delta) == 0
        && capture_final(api, &fixture, &second_projection, &second_delta) == 0
        && first_delta.exact == 1U && second_delta.exact == 1U
        && strcmp(first_projection.parent_fd_set_id,
            second_projection.parent_fd_set_id) == 0) {
        result = 0;
    }
    fixture_close(api, &fixture);
    return result;
}

static int test_arbitrary_root_rejected(
    const struct proc17_qa_residue_api *api)
{
    struct proc17_qa_residue_session *session = NULL;
    struct proc17_qa_residue_subject *subject = NULL;
    struct proc17_qa_residue_root_identity identity;
    struct proc17_qa_residue_error error;
    int result = -1;

    memset(&identity, 0, sizeof(identity));
    memset(&error, 0, sizeof(error));
    strcpy(identity.path, "/tmp/not-a-proc17-owned-root");
    if (api->session_open(&session, &error) != 0) goto cleanup;
    memset(&error, 0, sizeof(error));
    if (api->subject_bind(session, &identity, &subject, &error) != 0
        && subject == NULL && error.code[0] != '\0') {
        result = 0;
    }

cleanup:
    if (subject != NULL) api->subject_destroy(subject);
    if (session != NULL) api->session_destroy(session);
    return result;
}

static int test_observer_scan_closes(const struct proc17_qa_residue_api *api)
{
    struct observer_fixture fixture;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_delta delta;
    int result = -1;

    if (fixture_open(api, &fixture) != 0) return -1;
    if (capture_final(api, &fixture, &projection, &delta) == 0
        && projection.parent_fd_count
            == fixture.baseline_projection.parent_fd_count
        && delta.fd_opened == 0U && delta.fd_missing == 0U
        && delta.fd_identity_changed == 0U
        && delta.fd_flags_changed == 0U && delta.exact == 1U) {
        result = 0;
    }
    fixture_close(api, &fixture);
    return result;
}

static int high_duplicate(int descriptor)
{
    return fcntl(descriptor, F_DUPFD_CLOEXEC, 10);
}

static void supervisor_child(
    int source,
    int request,
    int result,
    int supervisor)
{
    char *const arguments[] = {
        (char *)"proc17_qa_supervisor", (char *)"run", NULL,
    };
    char *const environment[] = {NULL};

    if (dup3(source, 3, 0) < 0 || dup3(request, 4, 0) < 0
        || dup3(result, 5, 0) < 0 || dup3(supervisor, 6, 0) < 0
        || syscall(SYS_close_range, 7U, UINT_MAX, 0U) != 0) {
        _exit(125);
    }
    (void)close(STDIN_FILENO);
    (void)close(STDOUT_FILENO);
    (void)close(STDERR_FILENO);
    execveat(6, "", arguments, environment, AT_EMPTY_PATH);
    _exit(126);
}

static int wait_for_comm(pid_t child, const char *expected)
{
    char path[64];
    struct timespec delay = {.tv_sec = 0, .tv_nsec = 10000000L};
    int attempt;

    if (snprintf(path, sizeof(path), "/proc/%ld/comm", (long)child) <= 0) {
        return -1;
    }
    for (attempt = 0; attempt < 100; attempt++) {
        char observed[64] = {0};
        int descriptor = open(path, O_RDONLY | O_CLOEXEC);
        if (descriptor >= 0) {
            ssize_t length = read(descriptor, observed, sizeof(observed) - 1U);
            (void)close(descriptor);
            if (length > 0) {
                observed[strcspn(observed, "\n")] = '\0';
                if (strcmp(observed, expected) == 0) return 0;
            }
        }
        (void)nanosleep(&delay, NULL);
    }
    return -1;
}

static int test_exact_supervisor_process(
    const struct proc17_qa_residue_api *api)
{
    char source_root[] = "/tmp/proc17-qa-supervisor-live-XXXXXX";
    struct observer_fixture fixture;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_delta delta;
    int request_pipe[2] = {-1, -1};
    int result_pipe[2] = {-1, -1};
    int source = -1;
    int supervisor = -1;
    int child_source = -1;
    int child_request = -1;
    int child_result = -1;
    int child_supervisor = -1;
    pid_t child = -1;
    int result = -1;

    if (fixture_open(api, &fixture) != 0
        || mkdtemp(source_root) == NULL
        || (source = open(source_root,
            O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)) < 0
        || (supervisor = open(SUPERVISOR_PATH,
            O_RDONLY | O_NOFOLLOW | O_CLOEXEC)) < 0
        || pipe2(request_pipe, O_CLOEXEC) != 0
        || pipe2(result_pipe, O_CLOEXEC) != 0
        || (child_source = high_duplicate(source)) < 0
        || (child_request = high_duplicate(request_pipe[0])) < 0
        || (child_result = high_duplicate(result_pipe[1])) < 0
        || (child_supervisor = high_duplicate(supervisor)) < 0) {
        goto cleanup;
    }
    child = fork();
    if (child < 0) goto cleanup;
    if (child == 0) {
        supervisor_child(child_source, child_request, child_result,
            child_supervisor);
    }
    close_if_open(&child_source);
    close_if_open(&child_request);
    close_if_open(&child_result);
    close_if_open(&child_supervisor);
    close_if_open(&request_pipe[0]);
    close_if_open(&result_pipe[1]);
    if (wait_for_comm(child, PROC17_QA_RESIDUE_SUPERVISOR_COMM) != 0) {
        goto cleanup;
    }
    if (capture_final(api, &fixture, &projection, &delta) == 0
        && projection.matching_supervisor_process_count >= 1U
        && projection.direct_live_child_count >= 1U
        && delta.matching_supervisor_processes >= 1U
        && delta.direct_live_children >= 1U && delta.exact == 0U) {
        result = 0;
    }

cleanup:
    if (child > 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
    }
    close_if_open(&request_pipe[0]);
    close_if_open(&request_pipe[1]);
    close_if_open(&result_pipe[0]);
    close_if_open(&result_pipe[1]);
    close_if_open(&source);
    close_if_open(&supervisor);
    close_if_open(&child_source);
    close_if_open(&child_request);
    close_if_open(&child_result);
    close_if_open(&child_supervisor);
    (void)rmdir(source_root);
    fixture_close(api, &fixture);
    return result;
}

static int test_fixed_comm_zombie(const struct proc17_qa_residue_api *api)
{
    struct observer_fixture fixture;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_delta delta;
    pid_t child = -1;
    int result = -1;

    if (fixture_open(api, &fixture) != 0) return -1;
    child = fork();
    if (child < 0) goto cleanup;
    if (child == 0) {
        if (prctl(PR_SET_NAME, PROC17_QA_RESIDUE_SUPERVISOR_COMM,
                0L, 0L, 0L) != 0) {
            _exit(1);
        }
        _exit(0);
    }
    if (wait_for_zombie(child) != 0) goto cleanup;
    if (capture_final(api, &fixture, &projection, &delta) == 0
        && projection.direct_zombie_count >= 1U
        && projection.unresolved_supervisor_zombie_count >= 1U
        && delta.direct_zombies >= 1U
        && delta.unresolved_supervisor_zombies >= 1U
        && delta.exact == 0U) {
        result = 0;
    }

cleanup:
    if (child > 0) (void)waitpid(child, NULL, 0);
    fixture_close(api, &fixture);
    return result;
}

static int test_observer_self_fd(const struct proc17_qa_residue_api *api)
{
    struct observer_fixture fixture;
    struct proc17_qa_residue_delta delta;
    struct proc17_qa_residue_error error;
    int result = -1;

    if (fixture_open(api, &fixture) != 0) return -1;
    memset(&delta, 0, sizeof(delta));
    memset(&error, 0, sizeof(error));
    if (api->test_capture_with_retained_scan_fd(fixture.session,
            fixture.baseline, &delta, &error) == 0
        && delta.fd_opened >= 1U && delta.exact == 0U) {
        result = 0;
    }
    fixture_close(api, &fixture);
    return result;
}

static const struct control controls[] = {
    {"RO01", "clean self snapshot is exact", test_clean_snapshot},
    {"RO02", "equal-count fd identity exchange is visible", test_fd_identity_exchange},
    {"RO03", "direct live child is visible", test_direct_live_child},
    {"RO04", "direct zombie is visible without observer reap", test_direct_zombie},
    {"RO05", "retained namespace fd is residue", test_namespace_fd},
    {"RO06", "private /qa mount is visible", test_private_qa_mount},
    {"RO07", "owned-root grammar residue is visible", test_owned_root_residue},
    {"RO08", "parent namespace identity change is visible", test_namespace_change},
    {"RO09", "truncated proc and mount records fail closed", test_truncated_parsers},
    {"RO10", "equal normalized snapshots remain exact", test_equal_repeated_snapshots},
    {"RO11", "arbitrary root binding is rejected", test_arbitrary_root_rejected},
    {"RO12", "observer scan descriptors close before projection", test_observer_scan_closes},
    {"RO13", "exact production supervisor identity is visible", test_exact_supervisor_process},
    {"RO14", "fixed-comm unreadable zombie is unresolved", test_fixed_comm_zombie},
    {"RO15", "observer-owned pre-fd-scan descriptor is visible", test_observer_self_fd},
};

static int load_api(
    void **module,
    struct proc17_qa_residue_api *api,
    char error_text[256])
{
    proc17_qa_residue_get_api_fn get_api = NULL;
    void *symbol;

    *module = dlopen(OBSERVER_MODULE, RTLD_NOW | RTLD_LOCAL);
    if (*module == NULL) {
        snprintf(error_text, 256, "observer module absent: %s", dlerror());
        return -1;
    }
    dlerror();
    symbol = dlsym(*module, PROC17_QA_RESIDUE_GET_API_SYMBOL);
    if (symbol == NULL || dlerror() != NULL) {
        snprintf(error_text, 256, "observer C ABI symbol absent");
        return -1;
    }
    if (sizeof(get_api) != sizeof(symbol)) {
        snprintf(error_text, 256, "observer function pointer ABI mismatch");
        return -1;
    }
    memcpy(&get_api, &symbol, sizeof(get_api));
    memset(api, 0, sizeof(*api));
    if (get_api(PROC17_QA_RESIDUE_C_ABI, api) != 0
        || api->abi_version != PROC17_QA_RESIDUE_C_ABI
        || api->protocol_version == NULL
        || strcmp(api->protocol_version, PROC17_QA_RESIDUE_PROTOCOL) != 0
        || api->session_open == NULL || api->session_destroy == NULL
        || api->subject_bind == NULL || api->subject_destroy == NULL
        || api->capture == NULL || api->compare == NULL
        || api->snapshot_destroy == NULL
        || api->test_parse_proc_stat == NULL
        || api->test_parse_mountinfo == NULL
        || api->test_capture_with_retained_scan_fd == NULL) {
        snprintf(error_text, 256, "observer C ABI is incomplete");
        return -1;
    }
    return 0;
}

int main(void)
{
    struct proc17_qa_residue_api api;
    char load_error[256] = {0};
    void *module = NULL;
    size_t index;
    unsigned int green = 0U;
    unsigned int red = 0U;

    if (sizeof(controls) / sizeof(controls[0]) != CONTROL_COUNT) {
        fputs("proc17 QN20 observer catalog size mismatch\n", stderr);
        return 1;
    }
    if (load_api(&module, &api, load_error) != 0) {
        for (index = 0U; index < CONTROL_COUNT; index++) {
            printf("qa-residue-observer RED %s %s: %s\n",
                controls[index].id, controls[index].description, load_error);
        }
        printf("qa-residue-observer summary: green=0 red=%u\n",
            CONTROL_COUNT);
        if (module != NULL) (void)dlclose(module);
        return 1;
    }
    for (index = 0U; index < CONTROL_COUNT; index++) {
        if (controls[index].run(&api) == 0) {
            green++;
            printf("qa-residue-observer GREEN %s %s\n",
                controls[index].id, controls[index].description);
        } else {
            red++;
            printf("qa-residue-observer RED %s %s\n",
                controls[index].id, controls[index].description);
        }
    }
    printf("qa-residue-observer summary: green=%u red=%u\n", green, red);
    if (dlclose(module) != 0) red++;
    return red == 0U ? 0 : 1;
}
