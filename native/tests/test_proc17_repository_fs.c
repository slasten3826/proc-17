#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#include "../proc17_repository_fs_test.h"

static void prepublish_failure_leaves_no_final(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.fault_stage = PROC17_FAULT_BEFORE_RENAME;
    test_case.initial_target = PROC17_TARGET_ABSENT;
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_WORLD_FAILURE);
    assert(result.final_target == PROC17_TARGET_ABSENT);
    assert(result.partial_final_observed == 0);
    assert(result.temp_entries == 0);
    assert(result.mutation_primitive_entered == 1);
    assert(result.file_writes == 1);
}

static void no_replace_preserves_existing_bytes(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.initial_target = PROC17_TARGET_REGULAR;
    test_case.initial_content = "before\n";
    test_case.request_content = "after\n";
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_TARGET_EXISTS);
    assert(strcmp(result.final_content, "before\n") == 0);
    assert(result.partial_final_observed == 0);
}

static void competing_final_wins_without_overwrite(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.inject_final_race = 1;
    test_case.request_content = "proc17\n";
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_TARGET_EXISTS);
    assert(result.final_target == PROC17_TARGET_REGULAR);
    assert(strcmp(result.final_content, "racer\n") == 0);
    assert(result.temp_entries == 0);
    assert(result.partial_final_observed == 0);
}

static void postpublish_failure_is_ambiguous(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.fault_stage = PROC17_FAULT_AFTER_RENAME;
    test_case.initial_target = PROC17_TARGET_ABSENT;
    test_case.request_content = "complete\n";
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_AMBIGUOUS);
    assert(result.outcome != PROC17_OUTCOME_CREATED);
    assert(result.final_target == PROC17_TARGET_REGULAR);
    assert(strcmp(result.final_content, "complete\n") == 0);
    assert(result.partial_final_observed == 0);
}

static void short_write_and_eintr_are_retried(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.inject_short_write = 1;
    test_case.inject_eintr = 1;
    test_case.request_content = "complete bytes\n";
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_CREATED);
    assert(strcmp(result.final_content, "complete bytes\n") == 0);
    assert(result.partial_final_observed == 0);
}

static void random_failure_has_no_fallback(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.fault_stage = PROC17_FAULT_GETRANDOM;
    test_case.request_content = "never written\n";
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_WORLD_FAILURE);
    assert(result.temp_open_attempts == 0);
    assert(result.temp_entries == 0);
    assert(result.mutation_primitive_entered == 0);
    assert(result.file_writes == 0);
    assert(result.final_target == PROC17_TARGET_ABSENT);
}

static void temp_collision_is_one_bounded_attempt(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.inject_temp_collision = 1;
    test_case.request_content = "never published\n";
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_WORLD_FAILURE);
    assert(result.temp_open_attempts == 1);
    assert(result.temp_entries == 1);
    assert(result.mutation_primitive_entered == 1);
    assert(result.file_writes == 1);
    assert(result.final_target == PROC17_TARGET_ABSENT);
}

static void zero_write_never_publishes(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.fault_stage = PROC17_FAULT_WRITE_ZERO;
    test_case.request_content = "must remain private\n";
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_WORLD_FAILURE);
    assert(result.final_target == PROC17_TARGET_ABSENT);
    assert(result.temp_entries == 0);
    assert(result.partial_final_observed == 0);
}

static void perpetual_eintr_is_bounded(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.fault_stage = PROC17_FAULT_WRITE_EINTR_FOREVER;
    test_case.request_content = "must terminate\n";
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_WORLD_FAILURE);
    assert(result.write_attempts == 65);
    assert(result.final_target == PROC17_TARGET_ABSENT);
    assert(result.temp_entries == 0);
    assert(result.partial_final_observed == 0);
}

static void cleanup_failure_is_ambiguous_and_bounded(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.fault_stage = PROC17_FAULT_CLEANUP_UNLINK;
    test_case.request_content = "not final\n";
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_AMBIGUOUS);
    assert(result.final_target == PROC17_TARGET_ABSENT);
    assert(result.temp_entries == 1);
    assert(result.temp_residue_reported == 1);
    assert(result.temp_residue_bytes == 44);
    assert(result.published == 0);
}

static void every_prepublish_failure_cleans_private_state(void)
{
    static const enum proc17_fs_fault_stage stages[] = {
        PROC17_FAULT_OPEN_TEMP,
        PROC17_FAULT_TEMP_IDENTITY,
        PROC17_FAULT_WRITE_ERROR,
        PROC17_FAULT_FSYNC_TEMP,
        PROC17_FAULT_CLOSE_TEMP,
        PROC17_FAULT_BEFORE_RENAME,
        PROC17_FAULT_RENAME,
    };
    size_t index;

    for (index = 0; index < sizeof(stages) / sizeof(stages[0]); index++) {
        struct proc17_fs_test_case test_case = {0};
        struct proc17_fs_test_result result = {0};

        test_case.fault_stage = stages[index];
        test_case.request_content = "private until publish\n";
        assert(proc17_fs_run_test_case(&test_case, &result) == 0);
        assert(result.outcome == PROC17_OUTCOME_WORLD_FAILURE);
        assert(result.final_target == PROC17_TARGET_ABSENT);
        assert(result.temp_entries == 0);
        assert(result.partial_final_observed == 0);
        assert(result.open_fd_delta == 0);
    }
}

static void parent_fsync_failure_is_ambiguous(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.fault_stage = PROC17_FAULT_FSYNC_PARENT;
    test_case.request_content = "published but uncertain\n";
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_AMBIGUOUS);
    assert(result.final_target == PROC17_TARGET_REGULAR);
    assert(strcmp(result.final_content, "published but uncertain\n") == 0);
    assert(result.published == 1);
    assert(result.partial_final_observed == 0);
}

static void every_existing_target_type_is_preserved(void)
{
    static const enum proc17_fs_test_target targets[] = {
        PROC17_TARGET_REGULAR,
        PROC17_TARGET_DIRECTORY,
        PROC17_TARGET_SYMLINK,
        PROC17_TARGET_FIFO,
    };
    size_t index;

    for (index = 0; index < sizeof(targets) / sizeof(targets[0]); index++) {
        struct proc17_fs_test_case test_case = {0};
        struct proc17_fs_test_result result = {0};

        test_case.initial_target = targets[index];
        test_case.initial_content = "before\n";
        test_case.request_content = "after\n";
        assert(proc17_fs_run_test_case(&test_case, &result) == 0);
        assert(result.outcome == PROC17_OUTCOME_TARGET_EXISTS);
        assert(result.final_target == targets[index]);
        assert(result.partial_final_observed == 0);
    }
}

static void first_hand_mode_is_exact(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};
    mode_t previous_mask;

    test_case.request_mode = 0600;
    test_case.request_content = "private bytes\n";
    previous_mask = umask(0777);
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    umask(previous_mask);
    assert(result.outcome == PROC17_OUTCOME_CREATED);
    assert(result.final_mode == 0600);
}

static void maximum_content_is_complete(void)
{
    const size_t maximum = 1048576U;
    char *content = malloc(maximum + 1U);
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    assert(content != NULL);
    memset(content, 'x', maximum);
    content[maximum] = '\0';
    test_case.request_content = content;
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_CREATED);
    assert(strlen(result.final_content) == maximum);
    assert(result.final_content[0] == 'x');
    assert(result.final_content[maximum - 1U] == 'x');
    assert(result.partial_final_observed == 0);
    free(content);
}

#ifndef PROC17_REPOSITORY_FS_CREATE_ONLY
static void read_back_is_expected_plus_one_bounded(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.operation = PROC17_OPERATION_READ;
    test_case.initial_target = PROC17_TARGET_REGULAR;
    test_case.initial_content = "123456";
    test_case.read_limit = 5;
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_OBSERVED);
    assert(result.observed_target == PROC17_TARGET_REGULAR);
    assert(result.observed_bytes == 6);
    assert(strcmp(result.observed_content, "123456") == 0);
    assert(result.read_truncated == 1);
    assert(result.open_fd_delta == 0);
}

static void missing_target_is_an_observation(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.operation = PROC17_OPERATION_READ;
    test_case.initial_target = PROC17_TARGET_ABSENT;
    test_case.read_limit = 8;
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_OBSERVED);
    assert(result.observed_target == PROC17_TARGET_ABSENT);
    assert(result.observed_content == NULL);
    assert(result.observed_bytes == 0);
    assert(result.read_attempts == 0);
    assert(result.open_fd_delta == 0);
}

static void non_regular_targets_are_never_read(void)
{
    static const enum proc17_fs_test_target targets[] = {
        PROC17_TARGET_DIRECTORY,
        PROC17_TARGET_SYMLINK,
        PROC17_TARGET_FIFO,
    };
    size_t index;

    for (index = 0; index < sizeof(targets) / sizeof(targets[0]); index++) {
        struct proc17_fs_test_case test_case = {0};
        struct proc17_fs_test_result result = {0};

        test_case.operation = PROC17_OPERATION_READ;
        test_case.initial_target = targets[index];
        test_case.read_limit = 8;
        assert(proc17_fs_run_test_case(&test_case, &result) == 0);
        assert(result.outcome == PROC17_OUTCOME_OBSERVED);
        assert(result.observed_target == targets[index]);
        assert(result.observed_content == NULL);
        assert(result.observed_bytes == 0);
        assert(result.read_attempts == 0);
        assert(result.open_fd_delta == 0);
    }
}

static void read_open_and_read_failures_are_typed_and_bounded(void)
{
    static const enum proc17_fs_fault_stage stages[] = {
        PROC17_FAULT_READ_OPEN,
        PROC17_FAULT_READ_ERROR,
    };
    size_t index;

    for (index = 0; index < sizeof(stages) / sizeof(stages[0]); index++) {
        struct proc17_fs_test_case test_case = {0};
        struct proc17_fs_test_result result = {0};

        test_case.operation = PROC17_OPERATION_READ;
        test_case.initial_target = PROC17_TARGET_REGULAR;
        test_case.fault_stage = stages[index];
        test_case.read_limit = 8;
        assert(proc17_fs_run_test_case(&test_case, &result) == 0);
        assert(result.outcome == PROC17_OUTCOME_WORLD_FAILURE);
        assert(strcmp(result.error_code, "io_failure") == 0);
        assert(result.read_attempts == (stages[index] == PROC17_FAULT_READ_ERROR));
        assert(result.mutation_primitive_entered == 0);
        assert(result.file_writes == 0);
        assert(result.open_fd_delta == 0);
    }
}

static void perpetual_read_eintr_is_bounded(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.operation = PROC17_OPERATION_READ;
    test_case.initial_target = PROC17_TARGET_REGULAR;
    test_case.fault_stage = PROC17_FAULT_READ_EINTR_FOREVER;
    test_case.read_limit = 8;
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_WORLD_FAILURE);
    assert(strcmp(result.error_code, "io_failure") == 0);
    assert(result.read_attempts == 65);
    assert(result.open_fd_delta == 0);
}

static void concurrent_growth_is_not_stable_evidence(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.operation = PROC17_OPERATION_READ;
    test_case.initial_target = PROC17_TARGET_REGULAR;
    test_case.initial_content = "stable-before";
    test_case.fault_stage = PROC17_FAULT_READ_GROW;
    test_case.read_limit = 32;
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_WORLD_FAILURE);
    assert(strcmp(result.error_code, "read_unstable") == 0);
    assert(result.mutation_primitive_entered == 0);
    assert(result.file_writes == 0);
    assert(result.open_fd_delta == 0);
}

static void target_replacement_is_not_mixed_evidence(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.operation = PROC17_OPERATION_READ;
    test_case.initial_target = PROC17_TARGET_REGULAR;
    test_case.initial_content = "stable-before";
    test_case.fault_stage = PROC17_FAULT_READ_REPLACE;
    test_case.read_limit = 32;
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_WORLD_FAILURE);
    assert(strcmp(result.error_code, "target_changed") == 0);
    assert(result.mutation_primitive_entered == 0);
    assert(result.file_writes == 0);
    assert(result.open_fd_delta == 0);
}

static void maximum_read_bound_is_complete(void)
{
    const size_t maximum = 1048576U;
    char *content = malloc(maximum + 1U);
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    assert(content != NULL);
    memset(content, 'r', maximum);
    content[maximum] = '\0';
    test_case.operation = PROC17_OPERATION_READ;
    test_case.initial_target = PROC17_TARGET_REGULAR;
    test_case.initial_content = content;
    test_case.read_limit = maximum;
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.outcome == PROC17_OUTCOME_OBSERVED);
    assert(result.observed_bytes == maximum);
    assert(result.read_truncated == 0);
    assert(result.observed_content[0] == 'r');
    assert(result.observed_content[maximum - 1U] == 'r');
    assert(result.open_fd_delta == 0);
    free(content);
}
#endif

static void descriptors_return_to_baseline(void)
{
    struct proc17_fs_test_case test_case = {0};
    struct proc17_fs_test_result result = {0};

    test_case.request_content = "complete\n";
    assert(proc17_fs_run_test_case(&test_case, &result) == 0);
    assert(result.open_fd_delta == 0);
}

static void repeated_lives_leave_no_descriptor_debt(void)
{
    size_t index;

    for (index = 0; index < 128; index++) {
        struct proc17_fs_test_case test_case = {0};
        struct proc17_fs_test_result result = {0};

        test_case.request_content = "bounded repeated life\n";
        assert(proc17_fs_run_test_case(&test_case, &result) == 0);
        assert(result.outcome == PROC17_OUTCOME_CREATED);
        assert(result.open_fd_delta == 0);
        assert(result.temp_entries == 0);
        assert(result.partial_final_observed == 0);
    }
}

static void close_is_idempotent(void)
{
    assert(proc17_fs_test_close_twice() == 0);
}

int main(void)
{
    prepublish_failure_leaves_no_final();
    no_replace_preserves_existing_bytes();
    competing_final_wins_without_overwrite();
    postpublish_failure_is_ambiguous();
    short_write_and_eintr_are_retried();
    random_failure_has_no_fallback();
    temp_collision_is_one_bounded_attempt();
    zero_write_never_publishes();
    perpetual_eintr_is_bounded();
    cleanup_failure_is_ambiguous_and_bounded();
    every_prepublish_failure_cleans_private_state();
    parent_fsync_failure_is_ambiguous();
    every_existing_target_type_is_preserved();
    first_hand_mode_is_exact();
    maximum_content_is_complete();
#ifndef PROC17_REPOSITORY_FS_CREATE_ONLY
    read_back_is_expected_plus_one_bounded();
    missing_target_is_an_observation();
    non_regular_targets_are_never_read();
    read_open_and_read_failures_are_typed_and_bounded();
    perpetual_read_eintr_is_bounded();
    concurrent_growth_is_not_stable_evidence();
    target_replacement_is_not_mixed_evidence();
    maximum_read_bound_is_complete();
#endif
    descriptors_return_to_baseline();
    repeated_lives_leave_no_descriptor_debt();
    close_is_idempotent();
    puts("test_proc17_repository_fs ok");
    return 0;
}
