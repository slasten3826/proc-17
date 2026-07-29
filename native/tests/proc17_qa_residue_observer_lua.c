#include "proc17_qa_residue_observer.h"

#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>

#define SESSION_METATABLE "proc17.qa.residue_observer.session.v0"
#define SUBJECT_METATABLE "proc17.qa.residue_observer.subject.v0"
#define SNAPSHOT_METATABLE "proc17.qa.residue_observer.snapshot.v0"
#define LUA_PROTOCOL "qa.residue_observer.lua54.v0"
#define ERROR_PROTOCOL "qa.residue_observer_error.v0"

struct lua_session_ref {
    struct proc17_qa_residue_session *value;
};

struct lua_subject_ref {
    struct proc17_qa_residue_subject *value;
};

struct lua_snapshot_ref {
    struct proc17_qa_residue_snapshot *value;
};

static struct proc17_qa_residue_api observer_api;

static void set_string(lua_State *L, const char *key, const char *value)
{
    lua_pushstring(L, value);
    lua_setfield(L, -2, key);
}

static void set_integer(lua_State *L, const char *key, uint64_t value)
{
    lua_pushinteger(L, (lua_Integer)value);
    lua_setfield(L, -2, key);
}

static void set_boolean(lua_State *L, const char *key, int value)
{
    lua_pushboolean(L, value);
    lua_setfield(L, -2, key);
}

static int push_error(
    lua_State *L,
    const struct proc17_qa_residue_error *error,
    const char *fallback_code,
    const char *fallback_stage)
{
    const char *code = error != NULL && error->code[0] != '\0'
        ? error->code : fallback_code;
    const char *stage = error != NULL && error->stage[0] != '\0'
        ? error->stage : fallback_stage;

    lua_pushnil(L);
    lua_createtable(L, 0, 6);
    set_string(L, "protocol_version", ERROR_PROTOCOL);
    set_string(L, "code", code);
    set_string(L, "stage", stage);
    if (error != NULL && error->system_errno > 0) {
        set_integer(L, "errno", (uint64_t)error->system_errno);
    }
    set_string(L, "diagnostic", code);
    set_string(L, "event_truth_status", "runtime_confirmed");
    return 2;
}

static int push_contract_error(lua_State *L, const char *code, const char *stage)
{
    struct proc17_qa_residue_error error;

    memset(&error, 0, sizeof(error));
    (void)snprintf(error.code, sizeof(error.code), "%s", code);
    (void)snprintf(error.stage, sizeof(error.stage), "%s", stage);
    error.system_errno = EINVAL;
    return push_error(L, &error, code, stage);
}

static struct lua_session_ref *test_session(lua_State *L, int index)
{
    return luaL_testudata(L, index, SESSION_METATABLE);
}

static struct lua_subject_ref *test_subject(lua_State *L, int index)
{
    return luaL_testudata(L, index, SUBJECT_METATABLE);
}

static struct lua_snapshot_ref *test_snapshot(lua_State *L, int index)
{
    return luaL_testudata(L, index, SNAPSHOT_METATABLE);
}

static int session_gc(lua_State *L)
{
    struct lua_session_ref *reference = test_session(L, 1);
    if (reference != NULL && reference->value != NULL) {
        observer_api.session_destroy(reference->value);
        reference->value = NULL;
    }
    return 0;
}

static int subject_gc(lua_State *L)
{
    struct lua_subject_ref *reference = test_subject(L, 1);
    if (reference != NULL && reference->value != NULL) {
        observer_api.subject_destroy(reference->value);
        reference->value = NULL;
    }
    return 0;
}

static int snapshot_gc(lua_State *L)
{
    struct lua_snapshot_ref *reference = test_snapshot(L, 1);
    if (reference != NULL && reference->value != NULL) {
        observer_api.snapshot_destroy(reference->value);
        reference->value = NULL;
    }
    return 0;
}

static int open_observer(lua_State *L)
{
    struct proc17_qa_residue_session *session = NULL;
    struct proc17_qa_residue_error error;
    struct lua_session_ref *reference;

    if (lua_gettop(L) != 0) {
        return push_contract_error(L, "caller_configuration_forbidden", "open");
    }
    memset(&error, 0, sizeof(error));
    if (observer_api.session_open(&session, &error) != 0 || session == NULL) {
        return push_error(L, &error, "observer_open_failed", "open");
    }
    reference = lua_newuserdatauv(L, sizeof(*reference), 0);
    reference->value = session;
    luaL_setmetatable(L, SESSION_METATABLE);
    return 1;
}

static int parse_decimal_u64(const char *value, size_t length, uint64_t *result)
{
    uint64_t parsed = 0U;
    size_t index;

    if (value == NULL || length == 0U) return -1;
    for (index = 0U; index < length; index++) {
        unsigned char byte = (unsigned char)value[index];
        if (byte < '0' || byte > '9') return -1;
        if (parsed > (UINT64_MAX - (uint64_t)(byte - '0')) / UINT64_C(10)) {
            return -1;
        }
        parsed = parsed * UINT64_C(10) + (uint64_t)(byte - '0');
    }
    *result = parsed;
    return 0;
}

static int allowed_identity_key(const char *key)
{
    return strcmp(key, "protocol_version") == 0
        || strcmp(key, "path") == 0
        || strcmp(key, "device") == 0
        || strcmp(key, "inode") == 0
        || strcmp(key, "mount_id") == 0;
}

static int exact_identity_table(lua_State *L, int index)
{
    int absolute = lua_absindex(L, index);

    if (!lua_istable(L, absolute)) return 0;
    lua_pushnil(L);
    while (lua_next(L, absolute) != 0) {
        const char *key;
        if (lua_type(L, -2) != LUA_TSTRING
            || (key = lua_tostring(L, -2)) == NULL
            || !allowed_identity_key(key)) {
            lua_pop(L, 2);
            return 0;
        }
        lua_pop(L, 1);
    }
    return 1;
}

static int read_identity_string(
    lua_State *L,
    int index,
    const char *key,
    const char **value,
    size_t *length)
{
    int absolute = lua_absindex(L, index);

    lua_getfield(L, absolute, key);
    if (lua_type(L, -1) != LUA_TSTRING) {
        lua_pop(L, 1);
        return -1;
    }
    *value = lua_tolstring(L, -1, length);
    if (*value == NULL || memchr(*value, '\0', *length) != NULL) {
        lua_pop(L, 1);
        return -1;
    }
    return 0;
}

static int read_root_identity(
    lua_State *L,
    int index,
    struct proc17_qa_residue_root_identity *identity)
{
    const char *value;
    size_t length;

    memset(identity, 0, sizeof(*identity));
    if (!exact_identity_table(L, index)
        || read_identity_string(L, index, "protocol_version",
            &value, &length) != 0) {
        return -1;
    }
    if (length != sizeof("repository.test_owned_root_identity.v0") - 1U
        || memcmp(value, "repository.test_owned_root_identity.v0", length) != 0) {
        lua_pop(L, 1);
        return -1;
    }
    lua_pop(L, 1);
    if (read_identity_string(L, index, "path", &value, &length) != 0) return -1;
    if (length == 0U || length >= sizeof(identity->path)) {
        lua_pop(L, 1);
        return -1;
    }
    memcpy(identity->path, value, length);
    identity->path[length] = '\0';
    lua_pop(L, 1);

#define READ_IDENTITY_NUMBER(field_name, member) \
    do { \
        if (read_identity_string(L, index, field_name, &value, &length) != 0) \
            return -1; \
        if (parse_decimal_u64(value, length, &identity->member) != 0) { \
            lua_pop(L, 1); \
            return -1; \
        } \
        lua_pop(L, 1); \
    } while (0)

    READ_IDENTITY_NUMBER("device", device);
    READ_IDENTITY_NUMBER("inode", inode);
    READ_IDENTITY_NUMBER("mount_id", mount_id);
#undef READ_IDENTITY_NUMBER
    return 0;
}

static int bind_owned_root(lua_State *L)
{
    struct lua_session_ref *session;
    struct proc17_qa_residue_root_identity identity;
    struct proc17_qa_residue_subject *subject = NULL;
    struct proc17_qa_residue_error error;
    struct lua_subject_ref *reference;

    if (lua_gettop(L) != 2
        || (session = test_session(L, 1)) == NULL
        || session->value == NULL
        || read_root_identity(L, 2, &identity) != 0) {
        return push_contract_error(L, "invalid_owned_root_identity",
            "bind_owned_root");
    }
    memset(&error, 0, sizeof(error));
    if (observer_api.subject_bind(session->value, &identity,
            &subject, &error) != 0 || subject == NULL) {
        return push_error(L, &error, "owned_root_bind_failed",
            "bind_owned_root");
    }
    reference = lua_newuserdatauv(L, sizeof(*reference), 0);
    reference->value = subject;
    luaL_setmetatable(L, SUBJECT_METATABLE);
    return 1;
}

static int parse_scope(const char *scope, enum proc17_qa_residue_scope *value)
{
    if (scope == NULL) return -1;
    if (strcmp(scope, "baseline") == 0) *value = PROC17_QA_RESIDUE_BASELINE;
    else if (strcmp(scope, "iteration") == 0) {
        *value = PROC17_QA_RESIDUE_ITERATION;
    } else if (strcmp(scope, "post_cleanup") == 0) {
        *value = PROC17_QA_RESIDUE_POST_CLEANUP;
    } else if (strcmp(scope, "final") == 0) {
        *value = PROC17_QA_RESIDUE_FINAL;
    } else return -1;
    return 0;
}

static const char *scope_name(enum proc17_qa_residue_scope scope)
{
    switch (scope) {
    case PROC17_QA_RESIDUE_BASELINE: return "baseline";
    case PROC17_QA_RESIDUE_ITERATION: return "iteration";
    case PROC17_QA_RESIDUE_POST_CLEANUP: return "post_cleanup";
    case PROC17_QA_RESIDUE_FINAL: return "final";
    default: return "invalid";
    }
}

static void push_projection(
    lua_State *L,
    const struct proc17_qa_residue_projection *projection)
{
    lua_createtable(L, 0, 16);
    set_string(L, "protocol_version", "qa.residue_host_projection.v0");
    set_string(L, "snapshot_id", projection->snapshot_id);
    set_string(L, "scope", scope_name(projection->scope));
    set_string(L, "parent_fd_set_id", projection->parent_fd_set_id);
    set_integer(L, "parent_fd_count", projection->parent_fd_count);
    set_string(L, "parent_namespace_set_id",
        projection->parent_namespace_set_id);
    set_integer(L, "direct_live_child_count",
        projection->direct_live_child_count);
    set_integer(L, "direct_zombie_count", projection->direct_zombie_count);
    set_integer(L, "matching_supervisor_process_count",
        projection->matching_supervisor_process_count);
    set_integer(L, "unresolved_supervisor_zombie_count",
        projection->unresolved_supervisor_zombie_count);
    set_integer(L, "qa_host_mount_count", projection->qa_host_mount_count);
    if (projection->has_owned_source) {
        set_string(L, "owned_source_identity_id",
            projection->owned_source_identity_id);
        set_integer(L, "owned_source_host_mount_count",
            projection->owned_source_host_mount_count);
    }
    set_string(L, "owned_root_set_id", projection->owned_root_set_id);
    set_integer(L, "owned_root_count", projection->owned_root_count);
    set_string(L, "event_truth_status", "runtime_confirmed");
}

static int capture(lua_State *L)
{
    struct lua_session_ref *session;
    struct lua_subject_ref *subject = NULL;
    struct proc17_qa_residue_snapshot *snapshot = NULL;
    struct proc17_qa_residue_projection projection;
    struct proc17_qa_residue_error error;
    struct lua_snapshot_ref *reference;
    enum proc17_qa_residue_scope scope;
    const char *scope_text;

    if (lua_gettop(L) != 3
        || (session = test_session(L, 1)) == NULL || session->value == NULL
        || lua_type(L, 2) != LUA_TSTRING
        || (scope_text = lua_tostring(L, 2)) == NULL
        || parse_scope(scope_text, &scope) != 0) {
        return push_contract_error(L, "invalid_capture_request", "capture");
    }
    if (!lua_isnil(L, 3)) {
        subject = test_subject(L, 3);
        if (subject == NULL || subject->value == NULL) {
            return push_contract_error(L, "invalid_capture_subject", "capture");
        }
    }
    memset(&error, 0, sizeof(error));
    if (observer_api.capture(session->value, scope,
            subject == NULL ? NULL : subject->value,
            &snapshot, &projection, &error) != 0 || snapshot == NULL) {
        return push_error(L, &error, "observer_capture_failed", "capture");
    }
    reference = lua_newuserdatauv(L, sizeof(*reference), 0);
    reference->value = snapshot;
    luaL_setmetatable(L, SNAPSHOT_METATABLE);
    push_projection(L, &projection);
    return 2;
}

static void push_delta(
    lua_State *L,
    const struct proc17_qa_residue_delta *delta)
{
    lua_createtable(L, 0, 18);
    set_string(L, "protocol_version", "qa.residue_host_delta.v0");
    set_string(L, "baseline_snapshot_id", delta->baseline_snapshot_id);
    set_string(L, "observed_snapshot_id", delta->observed_snapshot_id);
    set_integer(L, "fd_opened", delta->fd_opened);
    set_integer(L, "fd_missing", delta->fd_missing);
    set_integer(L, "fd_identity_changed", delta->fd_identity_changed);
    set_integer(L, "fd_flags_changed", delta->fd_flags_changed);
    set_boolean(L, "parent_namespace_changed",
        delta->parent_namespace_changed != 0U);
    set_integer(L, "direct_live_children", delta->direct_live_children);
    set_integer(L, "direct_zombies", delta->direct_zombies);
    set_integer(L, "matching_supervisor_processes",
        delta->matching_supervisor_processes);
    set_integer(L, "unresolved_supervisor_zombies",
        delta->unresolved_supervisor_zombies);
    set_integer(L, "qa_host_mounts", delta->qa_host_mounts);
    set_integer(L, "owned_source_host_mounts",
        delta->owned_source_host_mounts);
    set_integer(L, "owned_roots_added", delta->owned_roots_added);
    set_integer(L, "owned_roots_missing", delta->owned_roots_missing);
    set_boolean(L, "exact", delta->exact != 0U);
    set_string(L, "event_truth_status", "runtime_confirmed");
}

static int compare(lua_State *L)
{
    struct lua_snapshot_ref *baseline;
    struct lua_snapshot_ref *observed;
    struct proc17_qa_residue_delta delta;
    struct proc17_qa_residue_error error;

    if (lua_gettop(L) != 2
        || (baseline = test_snapshot(L, 1)) == NULL
        || (observed = test_snapshot(L, 2)) == NULL
        || baseline->value == NULL || observed->value == NULL) {
        return push_contract_error(L, "invalid_compare_request", "compare");
    }
    memset(&error, 0, sizeof(error));
    if (observer_api.compare(baseline->value, observed->value,
            &delta, &error) != 0) {
        return push_error(L, &error, "observer_compare_failed", "compare");
    }
    push_delta(L, &delta);
    return 1;
}

static void create_locked_metatable(
    lua_State *L,
    const char *name,
    lua_CFunction gc)
{
    if (luaL_newmetatable(L, name)) {
        lua_pushcfunction(L, gc);
        lua_setfield(L, -2, "__gc");
        lua_pushstring(L, name);
        lua_setfield(L, -2, "__metatable");
        lua_pushstring(L, name);
        lua_setfield(L, -2, "__name");
    }
    lua_pop(L, 1);
}

int luaopen_proc17_qa_residue_observer(lua_State *L)
{
    if (proc17_qa_residue_observer_get_api(
            PROC17_QA_RESIDUE_C_ABI, &observer_api) != 0) {
        return luaL_error(L, "proc17 QA residue observer ABI unavailable");
    }
    create_locked_metatable(L, SESSION_METATABLE, session_gc);
    create_locked_metatable(L, SUBJECT_METATABLE, subject_gc);
    create_locked_metatable(L, SNAPSHOT_METATABLE, snapshot_gc);
    lua_createtable(L, 0, 5);
    set_string(L, "protocol_version", LUA_PROTOCOL);
    lua_pushcfunction(L, open_observer);
    lua_setfield(L, -2, "open");
    lua_pushcfunction(L, bind_owned_root);
    lua_setfield(L, -2, "bind_owned_root");
    lua_pushcfunction(L, capture);
    lua_setfield(L, -2, "capture");
    lua_pushcfunction(L, compare);
    lua_setfield(L, -2, "compare");
    return 1;
}
