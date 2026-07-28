#ifndef PROC17_QA_FAULT_TESTING_H
#define PROC17_QA_FAULT_TESTING_H

#ifndef PROC17_QA_FAULT_TESTING
#error "proc17_qa_fault_testing.h is test-build only"
#endif

#define PROC17_QA_LAUNCHER_ABI \
    "proc17.qa.launcher.lua54.fault-test.v0"
#define PROC17_QA_FAULT_SUPERVISOR_IDENTITY_ARGUMENT \
    "fault-build-identity"
#define PROC17_QA_FAULT_SUPERVISOR_IDENTITY \
    "proc17.qa.supervisor.fault-test.v0"

enum proc17_qa_trusted_fault_case {
    PROC17_QA_FAULT_WRONG_SUPERVISOR_IDENTITY = 1,
    PROC17_QA_FAULT_MALFORMED_REQUEST_FRAMES = 2,
    PROC17_QA_FAULT_MALFORMED_RESULT_FRAMES = 3,
    PROC17_QA_FAULT_CRASH_BEFORE_START = 4,
    PROC17_QA_FAULT_CRASH_AFTER_START = 5,
    PROC17_QA_FAULT_LOST_RESULT_PIPE = 6,
    PROC17_QA_FAULT_WAIT_REAP_AMBIGUITY = 7,
};

int proc17_qa_fault_test_supervisor_identity_accepts(const char *path);

#endif
