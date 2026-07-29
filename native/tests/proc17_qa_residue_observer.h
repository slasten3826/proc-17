#ifndef PROC17_QA_RESIDUE_OBSERVER_H
#define PROC17_QA_RESIDUE_OBSERVER_H

#include <stddef.h>
#include <stdint.h>

#define PROC17_QA_RESIDUE_C_ABI 1U
#define PROC17_QA_RESIDUE_DIGEST_BYTES 32U
#define PROC17_QA_RESIDUE_ID_BYTES 96U
#define PROC17_QA_RESIDUE_PATH_BYTES 96U
#define PROC17_QA_RESIDUE_ERROR_BYTES 64U
#define PROC17_QA_RESIDUE_SUPERVISOR_COMM "proc17_qa_super"
#define PROC17_QA_RESIDUE_PROTOCOL "qa.residue_observer.c.v0"
#define PROC17_QA_RESIDUE_GET_API_SYMBOL \
    "proc17_qa_residue_observer_get_api"

enum proc17_qa_residue_scope {
    PROC17_QA_RESIDUE_BASELINE = 1,
    PROC17_QA_RESIDUE_ITERATION = 2,
    PROC17_QA_RESIDUE_POST_CLEANUP = 3,
    PROC17_QA_RESIDUE_FINAL = 4,
};

struct proc17_qa_residue_session;
struct proc17_qa_residue_subject;
struct proc17_qa_residue_snapshot;

struct proc17_qa_residue_error {
    char code[PROC17_QA_RESIDUE_ERROR_BYTES];
    char stage[PROC17_QA_RESIDUE_ERROR_BYTES];
    int system_errno;
};

struct proc17_qa_residue_root_identity {
    char path[PROC17_QA_RESIDUE_PATH_BYTES];
    uint64_t device;
    uint64_t inode;
    uint64_t mount_id;
};

struct proc17_qa_residue_projection {
    uint32_t abi_version;
    enum proc17_qa_residue_scope scope;
    char snapshot_id[PROC17_QA_RESIDUE_ID_BYTES];
    char parent_fd_set_id[PROC17_QA_RESIDUE_ID_BYTES];
    uint64_t parent_fd_count;
    char parent_namespace_set_id[PROC17_QA_RESIDUE_ID_BYTES];
    uint64_t direct_live_child_count;
    uint64_t direct_zombie_count;
    uint64_t matching_supervisor_process_count;
    uint64_t unresolved_supervisor_zombie_count;
    uint64_t qa_host_mount_count;
    char owned_source_identity_id[PROC17_QA_RESIDUE_ID_BYTES];
    uint64_t owned_source_host_mount_count;
    char owned_root_set_id[PROC17_QA_RESIDUE_ID_BYTES];
    uint64_t owned_root_count;
    uint8_t has_owned_source;
    uint8_t event_truth_runtime_confirmed;
};

struct proc17_qa_residue_delta {
    uint32_t abi_version;
    char baseline_snapshot_id[PROC17_QA_RESIDUE_ID_BYTES];
    char observed_snapshot_id[PROC17_QA_RESIDUE_ID_BYTES];
    uint64_t fd_opened;
    uint64_t fd_missing;
    uint64_t fd_identity_changed;
    uint64_t fd_flags_changed;
    uint64_t direct_live_children;
    uint64_t direct_zombies;
    uint64_t matching_supervisor_processes;
    uint64_t unresolved_supervisor_zombies;
    uint64_t qa_host_mounts;
    uint64_t owned_source_host_mounts;
    uint64_t owned_roots_added;
    uint64_t owned_roots_missing;
    uint8_t parent_namespace_changed;
    uint8_t exact;
    uint8_t event_truth_runtime_confirmed;
};

struct proc17_qa_residue_process_record {
    int64_t pid;
    int64_t ppid;
    uint64_t starttime;
    char state;
    char comm[32];
};

struct proc17_qa_residue_api {
    uint32_t abi_version;
    const char *protocol_version;

    int (*session_open)(
        struct proc17_qa_residue_session **session,
        struct proc17_qa_residue_error *error);
    void (*session_destroy)(struct proc17_qa_residue_session *session);

    int (*subject_bind)(
        struct proc17_qa_residue_session *session,
        const struct proc17_qa_residue_root_identity *identity,
        struct proc17_qa_residue_subject **subject,
        struct proc17_qa_residue_error *error);
    void (*subject_destroy)(struct proc17_qa_residue_subject *subject);

    int (*capture)(
        struct proc17_qa_residue_session *session,
        enum proc17_qa_residue_scope scope,
        const struct proc17_qa_residue_subject *subject,
        struct proc17_qa_residue_snapshot **snapshot,
        struct proc17_qa_residue_projection *projection,
        struct proc17_qa_residue_error *error);
    int (*compare)(
        const struct proc17_qa_residue_snapshot *baseline,
        const struct proc17_qa_residue_snapshot *observed,
        struct proc17_qa_residue_delta *delta,
        struct proc17_qa_residue_error *error);
    void (*snapshot_destroy)(struct proc17_qa_residue_snapshot *snapshot);

    int (*test_parse_proc_stat)(
        const char *bytes,
        size_t length,
        struct proc17_qa_residue_process_record *record,
        struct proc17_qa_residue_error *error);
    int (*test_parse_mountinfo)(
        const char *bytes,
        size_t length,
        uint64_t *qa_mount_count,
        struct proc17_qa_residue_error *error);
    int (*test_capture_with_retained_scan_fd)(
        struct proc17_qa_residue_session *session,
        const struct proc17_qa_residue_snapshot *baseline,
        struct proc17_qa_residue_delta *delta,
        struct proc17_qa_residue_error *error);
};

typedef int (*proc17_qa_residue_get_api_fn)(
    uint32_t requested_abi,
    struct proc17_qa_residue_api *api);

int proc17_qa_residue_observer_get_api(
    uint32_t requested_abi,
    struct proc17_qa_residue_api *api);

#endif
