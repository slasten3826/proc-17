#include <assert.h>
#include <stdio.h>
#include <string.h>

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

static void close_is_idempotent(void)
{
    assert(proc17_fs_test_close_twice() == 0);
}

int main(void)
{
    prepublish_failure_leaves_no_final();
    no_replace_preserves_existing_bytes();
    postpublish_failure_is_ambiguous();
    short_write_and_eintr_are_retried();
    close_is_idempotent();
    puts("test_proc17_repository_fs ok");
    return 0;
}
