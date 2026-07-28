#define _GNU_SOURCE

#include "proc17_qa_launcher_v1.h"

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <string.h>
#include <sys/syscall.h>
#include <sys/timerfd.h>
#include <sys/wait.h>
#include <unistd.h>

struct proc17_qa_launcher_v1_machine {
    const struct proc17_qa_launcher_v1_expectation *expectation;
    unsigned char pending[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t pending_bytes;
    size_t expected_frame_bytes;
    unsigned char started_token[PROC17_QA_WIRE_DIGEST_BYTES];
    unsigned char started_stage[PROC17_QA_SOURCE_STAGE_V1_BYTES];
    unsigned char terminal_frame[PROC17_QA_WIRE_MAX_FRAME_BYTES];
    size_t terminal_bytes;
    uint16_t terminal_kind;
    uint8_t started_seen;
    uint8_t terminal_seen;
    uint8_t invariant_failed;
};

static int expectation_valid(
    const struct proc17_qa_launcher_v1_expectation *expectation)
{
    return expectation != NULL
        && proc17_qa_wire_v1_identity_valid(expectation->identity)
        && expectation->source_device != 0U
        && expectation->source_inode != 0U
        && expectation->source_mount_id != 0U
        && expectation->source_mount_policy_flags != 0U;
}

static int stage_matches_source(
    const unsigned char stage[PROC17_QA_SOURCE_STAGE_V1_BYTES],
    const struct proc17_qa_launcher_v1_expectation *expectation)
{
    if (!proc17_qa_wire_v1_source_stage_valid(stage)
        || proc17_qa_wire_get_u32(stage + 4U)
            != expectation->source_mount_policy_flags
        || proc17_qa_wire_get_u64(stage + 8U)
            != expectation->source_device
        || proc17_qa_wire_get_u64(stage + 16U)
            != expectation->source_inode
        || proc17_qa_wire_get_u64(stage + 24U)
            != expectation->source_mount_id
        || proc17_qa_wire_get_u64(stage + 32U)
            != expectation->source_device
        || proc17_qa_wire_get_u64(stage + 40U)
            != expectation->source_inode
        || proc17_qa_wire_get_u64(stage + 56U)
            != proc17_qa_wire_get_u64(stage + 32U)
        || proc17_qa_wire_get_u64(stage + 64U)
            != proc17_qa_wire_get_u64(stage + 40U)
        || proc17_qa_wire_get_u64(stage + 72U)
            != proc17_qa_wire_get_u64(stage + 48U)
        || stage[80U] != 1U || stage[81U] != 1U) {
        return 0;
    }
    return 1;
}

static void machine_fail(struct proc17_qa_launcher_v1_machine *machine)
{
    machine->invariant_failed = 1U;
}

static int accept_complete_frame(
    struct proc17_qa_launcher_v1_machine *machine)
{
    struct proc17_qa_wire_view view;
    const unsigned char *stage = NULL;
    uint16_t phase;

    if (machine->terminal_seen != 0U
        || proc17_qa_wire_decode_run_v1(machine->pending,
            machine->pending_bytes, &view) != 0
        || memcmp(view.payload, machine->expectation->identity,
            PROC17_QA_V1_IDENTITY_BYTES) != 0) {
        return -1;
    }
    phase = proc17_qa_wire_get_u16(
        view.payload + PROC17_QA_V1_PHASE_OFFSET);
    if (view.kind == PROC17_QA_WIRE_RUN_STARTED_V1) {
        stage = view.payload + PROC17_QA_V1_STARTED_STAGE_OFFSET;
        if (machine->started_seen != 0U
            || phase != PROC17_QA_RUN_V1_PHASE_STARTED
            || !stage_matches_source(stage, machine->expectation)) {
            return -1;
        }
        memcpy(machine->started_token, view.payload + 136U,
            PROC17_QA_WIRE_DIGEST_BYTES);
        memcpy(machine->started_stage, stage,
            PROC17_QA_SOURCE_STAGE_V1_BYTES);
        machine->started_seen = 1U;
        return 0;
    }
    if (view.kind == PROC17_QA_WIRE_RUN_RESULT_V1) {
        stage = view.payload + PROC17_QA_V1_RESULT_STAGE_OFFSET;
        if (machine->started_seen != 1U
            || phase != PROC17_QA_RUN_V1_PHASE_TERMINAL
            || !stage_matches_source(stage, machine->expectation)
            || memcmp(stage, machine->started_stage,
                PROC17_QA_SOURCE_STAGE_V1_BYTES) != 0) {
            return -1;
        }
    } else if (view.kind == PROC17_QA_WIRE_RUN_ERROR_V1) {
        int source_known = view.payload[139U] != 0U;
        if (phase == PROC17_QA_RUN_V1_PHASE_STARTED) {
            if (machine->started_seen != 0U) return -1;
            if (source_known) {
                stage = view.payload + PROC17_QA_V1_ERROR_STAGE_OFFSET;
                if (!stage_matches_source(stage, machine->expectation)) {
                    return -1;
                }
            }
        } else {
            stage = view.payload + PROC17_QA_V1_ERROR_STAGE_OFFSET;
            if (machine->started_seen != 1U || !source_known
                || !stage_matches_source(stage, machine->expectation)
                || memcmp(stage, machine->started_stage,
                    PROC17_QA_SOURCE_STAGE_V1_BYTES) != 0) {
                return -1;
            }
        }
    } else {
        return -1;
    }
    memcpy(machine->terminal_frame, machine->pending,
        machine->pending_bytes);
    machine->terminal_bytes = machine->pending_bytes;
    machine->terminal_kind = view.kind;
    machine->terminal_seen = 1U;
    return 0;
}

static int feed_public_bytes(
    struct proc17_qa_launcher_v1_machine *machine,
    const unsigned char *bytes,
    size_t length)
{
    while (length > 0U) {
        size_t target;
        size_t take;

        if (machine->invariant_failed != 0U
            || machine->terminal_seen != 0U) {
            machine_fail(machine);
            return -1;
        }
        target = machine->expected_frame_bytes == 0U
            ? 16U : machine->expected_frame_bytes;
        take = target - machine->pending_bytes;
        if (take > length) take = length;
        memcpy(machine->pending + machine->pending_bytes, bytes, take);
        machine->pending_bytes += take;
        bytes += take;
        length -= take;
        if (machine->expected_frame_bytes == 0U
            && machine->pending_bytes == 16U) {
            uint32_t payload_bytes = proc17_qa_wire_get_u32(
                machine->pending + 12U);
            if (payload_bytes > PROC17_QA_WIRE_MAX_FRAME_BYTES
                    - PROC17_QA_WIRE_ENVELOPE_BYTES) {
                machine_fail(machine);
                return -1;
            }
            machine->expected_frame_bytes = PROC17_QA_WIRE_ENVELOPE_BYTES
                + (size_t)payload_bytes;
        }
        if (machine->expected_frame_bytes != 0U
            && machine->pending_bytes == machine->expected_frame_bytes) {
            if (accept_complete_frame(machine) != 0) {
                machine_fail(machine);
                return -1;
            }
            memset(machine->pending, 0, machine->pending_bytes);
            machine->pending_bytes = 0U;
            machine->expected_frame_bytes = 0U;
        }
    }
    return 0;
}

static int child_wait_is_clean(int wait_status)
{
    return WIFEXITED(wait_status) && WEXITSTATUS(wait_status) == 0;
}

static int finish_machine(
    struct proc17_qa_launcher_v1_machine *machine,
    int wait_status,
    int supervisor_reaped,
    int result_eof,
    int watchdog_fired,
    struct proc17_qa_launcher_v1_terminal *terminal)
{
    struct proc17_qa_wire_view view;

    if (machine->invariant_failed != 0U || machine->pending_bytes != 0U
        || supervisor_reaped != 1 || result_eof != 1) {
        return PROC17_QA_LAUNCHER_V1_TRUSTED_INVARIANT;
    }
    memset(terminal, 0, sizeof(*terminal));
    terminal->started_attested = machine->started_seen;
    terminal->launcher_reap_state = PROC17_QA_RUN_V1_TRUE;
    terminal->result_eof_state = PROC17_QA_RUN_V1_TRUE;
    terminal->supervisor_wait_status = wait_status;
    if (machine->terminal_seen != 0U) {
        if (!child_wait_is_clean(wait_status)
            || proc17_qa_wire_decode_run_v1(machine->terminal_frame,
                machine->terminal_bytes, &view) != 0) {
            return PROC17_QA_LAUNCHER_V1_TRUSTED_INVARIANT;
        }
        terminal->kind = machine->terminal_kind
                == PROC17_QA_WIRE_RUN_RESULT_V1
            ? PROC17_QA_LAUNCHER_V1_TERMINAL_RESULT
            : PROC17_QA_LAUNCHER_V1_TERMINAL_ERROR;
        terminal->frame_bytes = machine->terminal_bytes;
        memcpy(terminal->frame, machine->terminal_frame,
            machine->terminal_bytes);
        terminal->phase = proc17_qa_wire_get_u16(
            view.payload + PROC17_QA_V1_PHASE_OFFSET);
        if (view.kind == PROC17_QA_WIRE_RUN_ERROR_V1) {
            terminal->error_class = proc17_qa_wire_get_u16(
                view.payload + 130U);
            terminal->error_code = proc17_qa_wire_get_u16(
                view.payload + 132U);
            terminal->error_stage = proc17_qa_wire_get_u16(
                view.payload + 134U);
            terminal->candidate_start_state = view.payload[136U];
            terminal->cleanup_state = view.payload[137U];
        }
        return PROC17_QA_LAUNCHER_V1_OK;
    }
    terminal->kind = PROC17_QA_LAUNCHER_V1_TERMINAL_DERIVED_ERROR;
    terminal->phase = machine->started_seen != 0U
        ? PROC17_QA_RUN_V1_PHASE_TERMINAL
        : PROC17_QA_RUN_V1_PHASE_STARTED;
    terminal->candidate_start_state = machine->started_seen != 0U
        ? PROC17_QA_RUN_V1_TRUE : PROC17_QA_RUN_V1_FALSE;
    terminal->cleanup_state = PROC17_QA_RUN_V1_UNKNOWN;
    if (watchdog_fired != 0 || !child_wait_is_clean(wait_status)) {
        terminal->error_class = PROC17_QA_RUN_V1_ERROR_UNAVAILABLE;
        terminal->error_code = PROC17_QA_RUN_V1_SUPERVISOR_CRASHED;
        terminal->error_stage = PROC17_QA_RUN_V1_ERROR_SUPERVISION;
    } else {
        terminal->error_class = PROC17_QA_RUN_V1_ERROR_AMBIGUOUS;
        terminal->error_code = PROC17_QA_RUN_V1_TERMINAL_FRAME_MISSING;
        terminal->error_stage = PROC17_QA_RUN_V1_ERROR_POSTFLIGHT;
    }
    return PROC17_QA_LAUNCHER_V1_OK;
}

static void set_infrastructure_error(
    const struct proc17_qa_launcher_v1_machine *machine,
    uint16_t error_code,
    uint16_t error_stage,
    int supervisor_reaped,
    int result_eof,
    int wait_status,
    struct proc17_qa_launcher_v1_terminal *terminal)
{
    memset(terminal, 0, sizeof(*terminal));
    terminal->kind = PROC17_QA_LAUNCHER_V1_TERMINAL_DERIVED_ERROR;
    terminal->phase = machine->started_seen != 0U
        ? PROC17_QA_RUN_V1_PHASE_TERMINAL
        : PROC17_QA_RUN_V1_PHASE_STARTED;
    terminal->error_class = PROC17_QA_RUN_V1_ERROR_AMBIGUOUS;
    terminal->error_code = error_code;
    terminal->error_stage = error_stage;
    terminal->candidate_start_state = machine->started_seen != 0U
        ? PROC17_QA_RUN_V1_TRUE : PROC17_QA_RUN_V1_FALSE;
    terminal->cleanup_state = PROC17_QA_RUN_V1_UNKNOWN;
    terminal->started_attested = machine->started_seen;
    terminal->launcher_reap_state = supervisor_reaped
        ? PROC17_QA_RUN_V1_TRUE : PROC17_QA_RUN_V1_UNKNOWN;
    terminal->result_eof_state = result_eof
        ? PROC17_QA_RUN_V1_TRUE : PROC17_QA_RUN_V1_UNKNOWN;
    if (supervisor_reaped) terminal->supervisor_wait_status = wait_status;
}

static void kill_supervisor_once(
    pid_t supervisor,
    int supervisor_pidfd,
    int *kill_sent)
{
    if (*kill_sent != 0) return;
    if (supervisor_pidfd >= 0) {
        (void)syscall(SYS_pidfd_send_signal,
            supervisor_pidfd, SIGKILL, NULL, 0U);
    } else if (supervisor > 0) {
        (void)kill(supervisor, SIGKILL);
    }
    *kill_sent = 1;
}

int proc17_qa_launcher_collect_v1(
    pid_t supervisor,
    int supervisor_pidfd,
    int result_descriptor,
    unsigned int watchdog_seconds,
    const struct proc17_qa_launcher_v1_expectation *expectation,
    struct proc17_qa_launcher_v1_terminal *terminal)
{
    struct proc17_qa_launcher_v1_machine machine;
    struct itimerspec timer_spec;
    struct pollfd descriptors[3];
    unsigned char input[1024];
    int descriptor_flags = -1;
    int timer_descriptor = -1;
    int wait_observation_complete = 0;
    int child_reaped = 0;
    int result_eof = 0;
    int wait_status = 0;
    int watchdog_fired = 0;
    int kill_sent = 0;
    int invariant_failed = 0;
    uint16_t infrastructure_error_code = 0U;
    uint16_t infrastructure_error_stage = 0U;
    int result = PROC17_QA_LAUNCHER_V1_SYSTEM_FAILURE;

    if (supervisor <= 0 || supervisor_pidfd < 0 || result_descriptor < 0
        || watchdog_seconds == 0U || !expectation_valid(expectation)
        || terminal == NULL) {
        return PROC17_QA_LAUNCHER_V1_INVALID_ARGUMENT;
    }
    memset(&machine, 0, sizeof(machine));
    memset(terminal, 0, sizeof(*terminal));
    machine.expectation = expectation;
    descriptor_flags = fcntl(result_descriptor, F_GETFL);
    if (descriptor_flags < 0
        || fcntl(result_descriptor, F_SETFL,
            descriptor_flags | O_NONBLOCK) != 0) {
        goto cleanup_kill;
    }
    timer_descriptor = timerfd_create(
        CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);
    if (timer_descriptor < 0) goto cleanup_kill;
    memset(&timer_spec, 0, sizeof(timer_spec));
    timer_spec.it_value.tv_sec = (time_t)watchdog_seconds;
    if (timerfd_settime(timer_descriptor, 0, &timer_spec, NULL) != 0) {
        goto cleanup_kill;
    }
    while (!wait_observation_complete
            || (!result_eof
                && infrastructure_error_code
                    != PROC17_QA_RUN_V1_RESULT_PIPE_LOST)) {
        int polled;
        descriptors[0] = (struct pollfd){.fd = result_eof
                || infrastructure_error_code
                    == PROC17_QA_RUN_V1_RESULT_PIPE_LOST
            ? -1 : result_descriptor,
            .events = POLLIN | POLLHUP | POLLERR};
        descriptors[1] = (struct pollfd){.fd = wait_observation_complete
            ? -1 : supervisor_pidfd, .events = POLLIN};
        descriptors[2] = (struct pollfd){.fd = watchdog_fired
            ? -1 : timer_descriptor, .events = POLLIN};
        polled = poll(descriptors, 3, -1);
        if (polled < 0 && errno == EINTR) continue;
        if (polled < 0) goto cleanup_kill;
        if ((descriptors[2].revents & POLLIN) != 0) {
            uint64_t expirations;
            ssize_t observed;
            do {
                observed = read(timer_descriptor,
                    &expirations, sizeof(expirations));
            } while (observed < 0 && errno == EINTR);
            if (observed != (ssize_t)sizeof(expirations)
                || expirations == 0U) {
                goto cleanup_kill;
            }
            watchdog_fired = 1;
            kill_supervisor_once(supervisor, supervisor_pidfd, &kill_sent);
        }
        if ((descriptors[0].revents & (POLLIN | POLLHUP | POLLERR)) != 0) {
            for (;;) {
                ssize_t observed = read(result_descriptor,
                    input, sizeof(input));
                if (observed > 0) {
                    if (!invariant_failed
                        && feed_public_bytes(&machine, input,
                            (size_t)observed) != 0) {
                        invariant_failed = 1;
                        kill_supervisor_once(
                            supervisor, supervisor_pidfd, &kill_sent);
                    }
                    continue;
                }
                if (observed == 0) {
                    result_eof = 1;
                    break;
                }
                if (errno == EINTR) continue;
                if (errno == EAGAIN || errno == EWOULDBLOCK) break;
                if (infrastructure_error_code == 0U) {
                    infrastructure_error_code
                        = PROC17_QA_RUN_V1_RESULT_PIPE_LOST;
                    infrastructure_error_stage
                        = PROC17_QA_RUN_V1_ERROR_SUPERVISION;
                }
                kill_supervisor_once(
                    supervisor, supervisor_pidfd, &kill_sent);
                break;
            }
        }
        if ((descriptors[1].revents & POLLIN) != 0) {
            pid_t observed = waitpid(supervisor, &wait_status, WNOHANG);
            if (observed == supervisor) {
                child_reaped = 1;
                wait_observation_complete = 1;
            } else if (observed < 0 && errno != EINTR) {
                wait_observation_complete = 1;
                if (infrastructure_error_code == 0U) {
                    infrastructure_error_code
                        = PROC17_QA_RUN_V1_REAP_AMBIGUOUS;
                    infrastructure_error_stage
                        = PROC17_QA_RUN_V1_ERROR_CLEANUP;
                }
                kill_supervisor_once(
                    supervisor, supervisor_pidfd, &kill_sent);
            }
        }
    }
    if (invariant_failed) {
        result = PROC17_QA_LAUNCHER_V1_TRUSTED_INVARIANT;
    } else if (infrastructure_error_code != 0U) {
        set_infrastructure_error(&machine, infrastructure_error_code,
            infrastructure_error_stage, child_reaped, result_eof,
            wait_status, terminal);
        result = PROC17_QA_LAUNCHER_V1_OK;
    } else {
        result = finish_machine(&machine, wait_status, child_reaped,
            result_eof, watchdog_fired, terminal);
    }
    goto cleanup;

cleanup_kill:
    kill_supervisor_once(supervisor, supervisor_pidfd, &kill_sent);
    if (!wait_observation_complete) {
        pid_t observed;
        do {
            observed = waitpid(supervisor, &wait_status, 0);
        } while (observed < 0 && errno == EINTR);
        if (observed == supervisor) child_reaped = 1;
    }
cleanup:
    if (timer_descriptor >= 0) (void)close(timer_descriptor);
    if (descriptor_flags >= 0) {
        (void)fcntl(result_descriptor, F_SETFL, descriptor_flags);
    }
    explicit_bzero(machine.started_token, sizeof(machine.started_token));
    explicit_bzero(machine.started_stage, sizeof(machine.started_stage));
    explicit_bzero(machine.pending, sizeof(machine.pending));
    explicit_bzero(machine.terminal_frame, sizeof(machine.terminal_frame));
    return result;
}
