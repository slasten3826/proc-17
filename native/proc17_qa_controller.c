#define _GNU_SOURCE

#include "proc17_qa_controller.h"

#include <errno.h>
#include <limits.h>
#include <signal.h>
#include <string.h>
#include <sys/timerfd.h>
#include <sys/wait.h>
#include <unistd.h>

#define PROC17_QA_NS_PER_SECOND UINT64_C(1000000000)
#define PROC17_QA_NS_PER_MS UINT64_C(1000000)
#define PROC17_QA_US_PER_SECOND INT64_C(1000000)

static int boolean(uint8_t value)
{
    return value == 0U || value == 1U;
}

static int monotonic_ns(uint64_t *output)
{
    struct timespec now;
    uint64_t seconds;

    if (output == NULL || clock_gettime(CLOCK_MONOTONIC, &now) != 0
        || now.tv_sec < 0 || now.tv_nsec < 0
        || now.tv_nsec >= (long)PROC17_QA_NS_PER_SECOND) {
        return -1;
    }
    seconds = (uint64_t)now.tv_sec;
    if (seconds > UINT64_MAX / PROC17_QA_NS_PER_SECOND) return -1;
    *output = seconds * PROC17_QA_NS_PER_SECOND + (uint64_t)now.tv_nsec;
    return 0;
}

void proc17_qa_candidate_clock_init(
    struct proc17_qa_candidate_clock *clock)
{
    if (clock != NULL) {
        memset(clock, 0, sizeof(*clock));
        clock->timer_descriptor = -1;
    }
}

int proc17_qa_candidate_clock_arm(
    struct proc17_qa_candidate_clock *clock,
    uint64_t wall_limit_ms)
{
    struct itimerspec timer;
    uint64_t duration_ns;
    uint64_t deadline_seconds;
    time_t deadline_time;

    if (clock == NULL || clock->timer_descriptor != -1
        || clock->armed != 0U || wall_limit_ms == 0U
        || wall_limit_ms > UINT64_MAX / PROC17_QA_NS_PER_MS) {
        return -1;
    }
    clock->timer_descriptor = timerfd_create(
        CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);
    if (clock->timer_descriptor < 0) return -1;
    if (monotonic_ns(&clock->started_ns) != 0) {
        (void)close(clock->timer_descriptor);
        clock->timer_descriptor = -1;
        return -1;
    }
    duration_ns = wall_limit_ms * PROC17_QA_NS_PER_MS;
    if (clock->started_ns > UINT64_MAX - duration_ns) {
        (void)close(clock->timer_descriptor);
        clock->timer_descriptor = -1;
        return -1;
    }
    clock->deadline_ns = clock->started_ns + duration_ns;
    clock->wall_limit_ms = wall_limit_ms;
    deadline_seconds = clock->deadline_ns / PROC17_QA_NS_PER_SECOND;
    deadline_time = (time_t)deadline_seconds;
    if (deadline_time < 0 || (uint64_t)deadline_time != deadline_seconds) {
        (void)close(clock->timer_descriptor);
        clock->timer_descriptor = -1;
        return -1;
    }
    memset(&timer, 0, sizeof(timer));
    timer.it_value.tv_sec = deadline_time;
    timer.it_value.tv_nsec = (long)(
        clock->deadline_ns % PROC17_QA_NS_PER_SECOND);
    if (timerfd_settime(clock->timer_descriptor, TFD_TIMER_ABSTIME,
            &timer, NULL) != 0) {
        (void)close(clock->timer_descriptor);
        clock->timer_descriptor = -1;
        return -1;
    }
    clock->armed = 1U;
    return 0;
}

int proc17_qa_candidate_clock_consume_timer(
    struct proc17_qa_candidate_clock *clock)
{
    uint64_t expirations = 0U;
    ssize_t observed;

    if (clock == NULL || clock->armed != 1U
        || clock->timer_descriptor < 0 || clock->timer_consumed != 0U) {
        return -1;
    }
    do {
        observed = read(clock->timer_descriptor,
            &expirations, sizeof(expirations));
    } while (observed < 0 && errno == EINTR);
    if (observed < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) return 0;
    if (observed != (ssize_t)sizeof(expirations) || expirations != 1U) {
        return -1;
    }
    clock->timer_consumed = 1U;
    return 1;
}

static int timeval_ms(const struct timeval *value, uint64_t *milliseconds)
{
    uint64_t seconds;

    if (value == NULL || milliseconds == NULL || value->tv_sec < 0
        || value->tv_usec < 0 || value->tv_usec >= PROC17_QA_US_PER_SECOND) {
        return -1;
    }
    seconds = (uint64_t)value->tv_sec;
    if (seconds > UINT64_MAX / UINT64_C(1000)) return -1;
    *milliseconds = seconds * UINT64_C(1000)
        + (uint64_t)value->tv_usec / UINT64_C(1000);
    return 0;
}

int proc17_qa_candidate_clock_finish(
    const struct proc17_qa_candidate_clock *clock,
    const struct rusage *usage,
    struct proc17_qa_candidate_metrics *metrics)
{
    uint64_t finished_ns;

    if (clock == NULL || usage == NULL || metrics == NULL
        || clock->armed != 1U || clock->timer_descriptor < 0
        || usage->ru_maxrss < 0
        || (uint64_t)usage->ru_maxrss > UINT64_MAX / UINT64_C(1024)
        || monotonic_ns(&finished_ns) != 0
        || finished_ns < clock->started_ns) {
        return -1;
    }
    memset(metrics, 0, sizeof(*metrics));
    metrics->wall_time_ms = (finished_ns - clock->started_ns)
        / PROC17_QA_NS_PER_MS;
    if (timeval_ms(&usage->ru_utime, &metrics->cpu_user_ms) != 0
        || timeval_ms(&usage->ru_stime, &metrics->cpu_system_ms) != 0) {
        return -1;
    }
    metrics->max_rss_bytes = (uint64_t)usage->ru_maxrss * UINT64_C(1024);
    return 0;
}

int proc17_qa_candidate_clock_close(
    struct proc17_qa_candidate_clock *clock)
{
    int result = 0;
    if (clock == NULL) return -1;
    if (clock->timer_descriptor >= 0) {
        result = close(clock->timer_descriptor);
        clock->timer_descriptor = -1;
    }
    return result == 0 ? 0 : -1;
}

int proc17_qa_candidate_apply_cpu_limit(uint64_t cpu_limit_ms)
{
    struct rlimit limit;
    uint64_t soft;

    if (cpu_limit_ms == 0U || cpu_limit_ms % UINT64_C(1000) != 0U) {
        return -1;
    }
    soft = cpu_limit_ms / UINT64_C(1000);
    if (soft == 0U || soft >= (uint64_t)RLIM_INFINITY
        || soft == UINT64_MAX) {
        return -1;
    }
    limit.rlim_cur = (rlim_t)soft;
    limit.rlim_max = (rlim_t)(soft + 1U);
    return setrlimit(RLIMIT_CPU, &limit) == 0 ? 0 : -1;
}

int proc17_qa_wait_candidate(
    pid_t candidate,
    int *wait_status,
    struct rusage *usage)
{
    pid_t observed;
    if (candidate <= 0 || wait_status == NULL || usage == NULL) return -1;
    memset(usage, 0, sizeof(*usage));
    do {
        observed = wait4(candidate, wait_status, 0, usage);
    } while (observed < 0 && errno == EINTR);
    return observed == candidate
        && (WIFEXITED(*wait_status) || WIFSIGNALED(*wait_status)) ? 0 : -1;
}

static int add_cause(
    uint16_t candidate,
    uint64_t value,
    uint16_t *kind,
    uint64_t *observed_value)
{
    if (*kind == 0U) {
        *kind = candidate;
        *observed_value = value;
        return 0;
    }
    if (*kind != candidate) return -1;
    if (value > *observed_value) *observed_value = value;
    return 0;
}

static int terminal_cause(int wait_status, uint16_t *kind, uint64_t *value)
{
    if (WIFEXITED(wait_status)) {
        int exit_code = WEXITSTATUS(wait_status);
        *kind = exit_code == 0 ? PROC17_QA_RUN_EXPECTED_EXIT
            : PROC17_QA_RUN_UNEXPECTED_EXIT;
        *value = (uint64_t)exit_code;
        return 0;
    }
    if (WIFSIGNALED(wait_status)) {
        int signal_number = WTERMSIG(wait_status);
        *kind = signal_number == SIGXCPU ? PROC17_QA_RUN_CPU_LIMIT
            : signal_number == SIGSYS
                ? PROC17_QA_RUN_SANDBOX_POLICY_VIOLATION
                : PROC17_QA_RUN_SIGNAL;
        *value = (uint64_t)signal_number;
        return 0;
    }
    return -1;
}

int proc17_qa_controller_resolve_epoch(
    struct proc17_qa_phase_state *phase,
    const struct proc17_qa_observation_epoch *epoch)
{
    uint16_t kind = 0U;
    uint64_t observed_value = 0U;
    uint16_t terminal_kind = 0U;
    uint64_t terminal_value = 0U;

    if (phase == NULL || epoch == NULL
        || !boolean(epoch->stdout_limit_crossed)
        || !boolean(epoch->stderr_limit_crossed)
        || !boolean(epoch->heap_denied)
        || !boolean(epoch->wall_timer_expired)
        || !boolean(epoch->candidate_terminal)
        || (epoch->stdout_limit_crossed != 0U
            && epoch->stdout_observed_bytes == 0U)
        || (epoch->stderr_limit_crossed != 0U
            && epoch->stderr_observed_bytes == 0U)
        || (epoch->heap_denied != 0U && epoch->heap_peak_bytes == 0U)
        || (epoch->wall_timer_expired != 0U && epoch->wall_limit_ms == 0U)
        || (epoch->candidate_terminal != 0U
            && terminal_cause(epoch->wait_status,
                &terminal_kind, &terminal_value) != 0)) {
        return PROC17_QA_EPOCH_INVALID;
    }
    if (phase->first_cause.kind != 0U) {
        return PROC17_QA_EPOCH_CAUSE_ALREADY_SET;
    }
    if (epoch->stdout_limit_crossed != 0U
        && add_cause(PROC17_QA_RUN_OUTPUT_LIMIT,
            epoch->stdout_observed_bytes, &kind, &observed_value) != 0) {
        return PROC17_QA_EPOCH_AMBIGUOUS;
    }
    if (epoch->stderr_limit_crossed != 0U
        && add_cause(PROC17_QA_RUN_OUTPUT_LIMIT,
            epoch->stderr_observed_bytes, &kind, &observed_value) != 0) {
        return PROC17_QA_EPOCH_AMBIGUOUS;
    }
    if (epoch->heap_denied != 0U
        && add_cause(PROC17_QA_RUN_MEMORY_LIMIT,
            epoch->heap_peak_bytes, &kind, &observed_value) != 0) {
        return PROC17_QA_EPOCH_AMBIGUOUS;
    }
    if (epoch->wall_timer_expired != 0U
        && add_cause(PROC17_QA_RUN_WALL_TIMEOUT,
            epoch->wall_limit_ms, &kind, &observed_value) != 0) {
        return PROC17_QA_EPOCH_AMBIGUOUS;
    }
    if (epoch->candidate_terminal != 0U
        && add_cause(terminal_kind, terminal_value,
            &kind, &observed_value) != 0) {
        return PROC17_QA_EPOCH_AMBIGUOUS;
    }
    if (kind == 0U) return PROC17_QA_EPOCH_NO_CAUSE;
    return proc17_qa_phase_claim_first_cause(
            phase, kind, observed_value) == PROC17_QA_CAUSE_SET
        ? PROC17_QA_EPOCH_CAUSE_CLAIMED : PROC17_QA_EPOCH_INVALID;
}
