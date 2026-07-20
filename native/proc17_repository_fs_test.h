#ifndef PROC17_REPOSITORY_FS_TEST_H
#define PROC17_REPOSITORY_FS_TEST_H

#include <stddef.h>

enum proc17_fs_test_operation {
    PROC17_OPERATION_CREATE = 0,
    PROC17_OPERATION_READ = 1,
};

enum proc17_fs_fault_stage {
    PROC17_FAULT_NONE = 0,
    PROC17_FAULT_GETRANDOM,
    PROC17_FAULT_OPEN_TEMP,
    PROC17_FAULT_TEMP_IDENTITY,
    PROC17_FAULT_WRITE_ZERO,
    PROC17_FAULT_WRITE_ERROR,
    PROC17_FAULT_WRITE_EINTR_FOREVER,
    PROC17_FAULT_FSYNC_TEMP,
    PROC17_FAULT_CLOSE_TEMP,
    PROC17_FAULT_BEFORE_RENAME,
    PROC17_FAULT_RENAME,
    PROC17_FAULT_AFTER_RENAME,
    PROC17_FAULT_FSYNC_PARENT,
    PROC17_FAULT_CLEANUP_UNLINK,
    PROC17_FAULT_READ_OPEN,
    PROC17_FAULT_READ_GROW,
    PROC17_FAULT_READ_REPLACE,
    PROC17_FAULT_READ_ERROR,
    PROC17_FAULT_READ_EINTR_FOREVER,
};

enum proc17_fs_test_outcome {
    PROC17_OUTCOME_CREATED = 1,
    PROC17_OUTCOME_OBSERVED,
    PROC17_OUTCOME_TARGET_EXISTS,
    PROC17_OUTCOME_WORLD_FAILURE,
    PROC17_OUTCOME_AMBIGUOUS,
};

enum proc17_fs_test_target {
    PROC17_TARGET_ABSENT = 0,
    PROC17_TARGET_REGULAR,
    PROC17_TARGET_DIRECTORY,
    PROC17_TARGET_SYMLINK,
    PROC17_TARGET_FIFO,
};

struct proc17_fs_test_case {
    enum proc17_fs_test_operation operation;
    enum proc17_fs_fault_stage fault_stage;
    enum proc17_fs_test_target initial_target;
    const char *initial_content;
    const char *request_path;
    const char *request_content;
    unsigned int request_mode;
    size_t read_limit;
    int inject_short_write;
    int inject_eintr;
    int inject_temp_collision;
    int inject_final_race;
};

struct proc17_fs_test_result {
    enum proc17_fs_test_outcome outcome;
    enum proc17_fs_test_target final_target;
    enum proc17_fs_test_target observed_target;
    const char *error_code;
    const char *final_content;
    unsigned int final_mode;
    size_t observed_bytes;
    const char *observed_content;
    unsigned int temp_open_attempts;
    unsigned int write_attempts;
    unsigned int read_attempts;
    unsigned int temp_entries;
    size_t temp_residue_bytes;
    int temp_residue_reported;
    int partial_final_observed;
    int read_truncated;
    int mutation_primitive_entered;
    unsigned int file_writes;
    int published;
    int open_fd_delta;
};

int proc17_fs_run_test_case(
    const struct proc17_fs_test_case *test_case,
    struct proc17_fs_test_result *result);

int proc17_fs_test_close_twice(void);

#endif
