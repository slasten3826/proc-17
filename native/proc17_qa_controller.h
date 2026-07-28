#ifndef PROC17_QA_CONTROLLER_H
#define PROC17_QA_CONTROLLER_H

#include <stdint.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <time.h>

#include "proc17_qa_phase.h"

enum proc17_qa_epoch_result {
    PROC17_QA_EPOCH_INVALID = -1,
    PROC17_QA_EPOCH_NO_CAUSE = 0,
    PROC17_QA_EPOCH_CAUSE_CLAIMED = 1,
    PROC17_QA_EPOCH_CAUSE_ALREADY_SET = 2,
    PROC17_QA_EPOCH_AMBIGUOUS = 3,
};

struct proc17_qa_observation_epoch {
    uint8_t stdout_limit_crossed;
    uint8_t stderr_limit_crossed;
    uint8_t heap_denied;
    uint8_t wall_timer_expired;
    uint8_t candidate_terminal;
    int wait_status;
    uint64_t stdout_observed_bytes;
    uint64_t stderr_observed_bytes;
    uint64_t heap_peak_bytes;
    uint64_t wall_limit_ms;
};

struct proc17_qa_candidate_clock {
    int timer_descriptor;
    uint64_t started_ns;
    uint64_t deadline_ns;
    uint64_t wall_limit_ms;
    uint8_t armed;
    uint8_t timer_consumed;
};

struct proc17_qa_candidate_metrics {
    uint64_t wall_time_ms;
    uint64_t cpu_user_ms;
    uint64_t cpu_system_ms;
    uint64_t max_rss_bytes;
};

void proc17_qa_candidate_clock_init(
    struct proc17_qa_candidate_clock *clock);

int proc17_qa_candidate_clock_arm(
    struct proc17_qa_candidate_clock *clock,
    uint64_t wall_limit_ms);

int proc17_qa_candidate_clock_consume_timer(
    struct proc17_qa_candidate_clock *clock);

int proc17_qa_candidate_clock_finish(
    const struct proc17_qa_candidate_clock *clock,
    const struct rusage *usage,
    struct proc17_qa_candidate_metrics *metrics);

int proc17_qa_candidate_clock_close(
    struct proc17_qa_candidate_clock *clock);

int proc17_qa_candidate_apply_cpu_limit(uint64_t cpu_limit_ms);

int proc17_qa_wait_candidate(
    pid_t candidate,
    int *wait_status,
    struct rusage *usage);

int proc17_qa_controller_resolve_epoch(
    struct proc17_qa_phase_state *phase,
    const struct proc17_qa_observation_epoch *epoch);

#endif
