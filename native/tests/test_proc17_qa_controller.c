#define _GNU_SOURCE

#include "../proc17_qa_controller.h"

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <sys/syscall.h>
#include <sys/wait.h>
#include <unistd.h>

enum child_mode {
    CHILD_CLEAN = 1,
    CHILD_WALL = 2,
    CHILD_CPU = 3,
};

static int write_byte(int descriptor)
{
    unsigned char byte = 0xa5U;
    ssize_t written;
    do {
        written = write(descriptor, &byte, 1U);
    } while (written < 0 && errno == EINTR);
    return written == 1 ? 0 : -1;
}

static int read_byte(int descriptor)
{
    unsigned char byte = 0U;
    ssize_t observed;
    do {
        observed = read(descriptor, &byte, 1U);
    } while (observed < 0 && errno == EINTR);
    return observed == 1 && byte == 0xa5U ? 0 : -1;
}

static void run_child(enum child_mode mode, int release_descriptor)
{
    volatile uint64_t accumulator = 0U;

    if (mode == CHILD_CPU
        && proc17_qa_candidate_apply_cpu_limit(1000U) != 0) {
        _exit(120);
    }
    if (read_byte(release_descriptor) != 0) _exit(121);
    close(release_descriptor);
    if (mode == CHILD_CLEAN) _exit(0);
    if (mode == CHILD_WALL) {
        for (;;) pause();
    }
    for (;;) accumulator++;
}

static int poll_once(struct pollfd *descriptors, nfds_t count)
{
    int observed;
    do {
        observed = poll(descriptors, count, -1);
    } while (observed < 0 && errno == EINTR);
    return observed;
}

static int run_real_case(
    enum child_mode mode,
    struct proc17_qa_phase_state *phase,
    struct proc17_qa_candidate_metrics *metrics,
    int *terminal_status)
{
    struct proc17_qa_candidate_clock clock;
    struct proc17_qa_observation_epoch epoch;
    struct rusage usage;
    struct pollfd poll_fds[2];
    uint64_t wall_limit = mode == CHILD_WALL ? 50U
        : mode == CHILD_CPU ? 5000U : 2000U;
    int release_pipe[2];
    int pidfd = -1;
    pid_t child;
    int reaped = 0;
    int resolution;

    proc17_qa_phase_init(phase);
    proc17_qa_candidate_clock_init(&clock);
    if (pipe2(release_pipe, O_CLOEXEC) != 0) return -1;
    child = fork();
    if (child < 0) return -1;
    if (child == 0) {
        close(release_pipe[1]);
        run_child(mode, release_pipe[0]);
        _exit(122);
    }
    close(release_pipe[0]);
    pidfd = (int)syscall(SYS_pidfd_open, child, 0U);
    if (pidfd < 0 || proc17_qa_candidate_clock_arm(&clock, wall_limit) != 0
        || write_byte(release_pipe[1]) != 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
        return -1;
    }
    close(release_pipe[1]);
    poll_fds[0] = (struct pollfd){.fd = pidfd, .events = POLLIN};
    poll_fds[1] = (struct pollfd){
        .fd = clock.timer_descriptor, .events = POLLIN};
    if (poll_once(poll_fds, 2) <= 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
        return -1;
    }
    memset(&epoch, 0, sizeof(epoch));
    if ((poll_fds[1].revents & POLLIN) != 0) {
        if (proc17_qa_candidate_clock_consume_timer(&clock) != 1) {
            (void)kill(child, SIGKILL);
            (void)waitpid(child, NULL, 0);
            return -1;
        }
        epoch.wall_timer_expired = 1U;
        epoch.wall_limit_ms = wall_limit;
    }
    if ((poll_fds[0].revents & POLLIN) != 0) {
        if (proc17_qa_wait_candidate(child, terminal_status, &usage) != 0) {
            (void)kill(child, SIGKILL);
            (void)waitpid(child, NULL, 0);
            return -1;
        }
        reaped = 1;
        epoch.candidate_terminal = 1U;
        epoch.wait_status = *terminal_status;
    }
    resolution = proc17_qa_controller_resolve_epoch(phase, &epoch);
    if (resolution == PROC17_QA_EPOCH_CAUSE_CLAIMED
        && phase->first_cause.kind == PROC17_QA_RUN_WALL_TIMEOUT
        && reaped == 0) {
        struct proc17_qa_observation_epoch terminal_epoch;
        if (syscall(SYS_pidfd_send_signal,
                pidfd, SIGKILL, NULL, 0U) != 0
            || proc17_qa_wait_candidate(
                child, terminal_status, &usage) != 0) {
            (void)kill(child, SIGKILL);
            (void)waitpid(child, NULL, 0);
            return -1;
        }
        reaped = 1;
        memset(&terminal_epoch, 0, sizeof(terminal_epoch));
        terminal_epoch.candidate_terminal = 1U;
        terminal_epoch.wait_status = *terminal_status;
        if (proc17_qa_controller_resolve_epoch(phase, &terminal_epoch)
                != PROC17_QA_EPOCH_CAUSE_ALREADY_SET) {
            return -1;
        }
    }
    if (reaped == 0) {
        (void)kill(child, SIGKILL);
        (void)waitpid(child, NULL, 0);
        return -1;
    }
    if (proc17_qa_candidate_clock_finish(&clock, &usage, metrics) != 0
        || proc17_qa_candidate_clock_close(&clock) != 0) {
        return -1;
    }
    close(pidfd);
    return resolution;
}

static int test_epoch_arbitration(void)
{
    struct proc17_qa_phase_state phase;
    struct proc17_qa_observation_epoch epoch;
    struct proc17_qa_first_cause first;

    proc17_qa_phase_init(&phase);
    memset(&epoch, 0, sizeof(epoch));
    epoch.stdout_limit_crossed = 1U;
    epoch.stderr_limit_crossed = 1U;
    epoch.stdout_observed_bytes = 11U;
    epoch.stderr_observed_bytes = 17U;
    if (proc17_qa_controller_resolve_epoch(&phase, &epoch)
            != PROC17_QA_EPOCH_CAUSE_CLAIMED
        || phase.first_cause.kind != PROC17_QA_RUN_OUTPUT_LIMIT
        || phase.first_cause.observed_value != 17U) {
        return -1;
    }
    first = phase.first_cause;
    memset(&epoch, 0, sizeof(epoch));
    epoch.wall_timer_expired = 1U;
    epoch.wall_limit_ms = 30U;
    if (proc17_qa_controller_resolve_epoch(&phase, &epoch)
            != PROC17_QA_EPOCH_CAUSE_ALREADY_SET
        || memcmp(&first, &phase.first_cause, sizeof(first)) != 0) {
        return -1;
    }

    proc17_qa_phase_init(&phase);
    memset(&epoch, 0, sizeof(epoch));
    epoch.heap_denied = 1U;
    epoch.heap_peak_bytes = 8U;
    epoch.wall_timer_expired = 1U;
    epoch.wall_limit_ms = 30U;
    if (proc17_qa_controller_resolve_epoch(&phase, &epoch)
            != PROC17_QA_EPOCH_AMBIGUOUS
        || phase.first_cause.kind != 0U) {
        return -1;
    }

    memset(&epoch, 0, sizeof(epoch));
    if (proc17_qa_controller_resolve_epoch(&phase, &epoch)
            != PROC17_QA_EPOCH_NO_CAUSE) {
        return -1;
    }
    epoch.candidate_terminal = 1U;
    epoch.wait_status = 0;
    epoch.wall_timer_expired = 1U;
    epoch.wall_limit_ms = 30U;
    if (proc17_qa_controller_resolve_epoch(&phase, &epoch)
            != PROC17_QA_EPOCH_AMBIGUOUS) {
        return -1;
    }
    epoch.stdout_limit_crossed = 2U;
    if (proc17_qa_controller_resolve_epoch(&phase, &epoch)
            != PROC17_QA_EPOCH_INVALID) {
        return -1;
    }
    return 0;
}

static int test_real_candidate_clocks(void)
{
    struct proc17_qa_phase_state phase;
    struct proc17_qa_candidate_metrics metrics;
    int status;

    if (run_real_case(CHILD_CLEAN, &phase, &metrics, &status)
            != PROC17_QA_EPOCH_CAUSE_CLAIMED
        || phase.first_cause.kind != PROC17_QA_RUN_EXPECTED_EXIT
        || !WIFEXITED(status) || WEXITSTATUS(status) != 0
        || metrics.wall_time_ms >= 2000U) {
        return -1;
    }
    if (run_real_case(CHILD_WALL, &phase, &metrics, &status)
            != PROC17_QA_EPOCH_CAUSE_CLAIMED
        || phase.first_cause.kind != PROC17_QA_RUN_WALL_TIMEOUT
        || !WIFSIGNALED(status) || WTERMSIG(status) != SIGKILL
        || metrics.wall_time_ms < 40U) {
        return -1;
    }
    if (run_real_case(CHILD_CPU, &phase, &metrics, &status)
            != PROC17_QA_EPOCH_CAUSE_CLAIMED
        || phase.first_cause.kind != PROC17_QA_RUN_CPU_LIMIT
        || !WIFSIGNALED(status) || WTERMSIG(status) != SIGXCPU
        || metrics.cpu_user_ms + metrics.cpu_system_ms == 0U
        || metrics.wall_time_ms >= 5000U) {
        return -1;
    }
    return 0;
}

static int test_invalid_clock_inputs(void)
{
    struct proc17_qa_candidate_clock clock;
    struct proc17_qa_candidate_metrics metrics;
    struct rusage usage;

    proc17_qa_candidate_clock_init(&clock);
    memset(&usage, 0, sizeof(usage));
    if (proc17_qa_candidate_apply_cpu_limit(0U) == 0
        || proc17_qa_candidate_apply_cpu_limit(1500U) == 0
        || proc17_qa_candidate_clock_arm(&clock, 1000U) != 0) {
        return -1;
    }
    usage.ru_utime.tv_usec = 1000000;
    if (proc17_qa_candidate_clock_finish(&clock, &usage, &metrics) == 0
        || proc17_qa_candidate_clock_close(&clock) != 0) {
        return -1;
    }
    return 0;
}

int main(void)
{
    if (test_epoch_arbitration() != 0
        || test_real_candidate_clocks() != 0
        || test_invalid_clock_inputs() != 0) {
        return 1;
    }
    puts("proc17 QA candidate clock and cause arbitration ok");
    return 0;
}
