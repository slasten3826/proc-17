#ifndef PROC17_QA_LAUNCHER_INTERNAL_H
#define PROC17_QA_LAUNCHER_INTERNAL_H

#include <lua.h>

enum proc17_qa_source_status {
    PROC17_QA_SOURCE_OK = 0,
    PROC17_QA_SOURCE_INVALID_USERDATA,
    PROC17_QA_SOURCE_INVALID_ABI,
    PROC17_QA_SOURCE_CLOSED,
    PROC17_QA_SOURCE_DUPLICATE_FAILED,
    PROC17_QA_SOURCE_IDENTITY_CHANGED,
    PROC17_QA_SOURCE_CONSUMER_FAILED,
    PROC17_QA_SOURCE_CLOSE_FAILED,
};

typedef int (*proc17_qa_source_consumer)(int repository_fd, void *context);

int proc17_qa_with_repository_source(
    lua_State *L,
    int index,
    proc17_qa_source_consumer consumer,
    void *context);

#endif
