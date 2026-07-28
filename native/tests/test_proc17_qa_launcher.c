#define _GNU_SOURCE

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include "../proc17_qa_launcher_internal.h"
#include "../proc17_qa_policy.h"
#include "../proc17_sha256.h"

int luaopen_proc17_repository_fs(lua_State *L);

struct borrow_observation {
    int calls;
    int cloexec;
    int directory;
};

static int observe_borrow(int descriptor, void *context)
{
    struct borrow_observation *observation = context;
    struct stat status;
    int flags = fcntl(descriptor, F_GETFD);

    observation->calls++;
    observation->cloexec = flags >= 0 && (flags & FD_CLOEXEC) != 0;
    observation->directory = fstat(descriptor, &status) == 0
        && S_ISDIR(status.st_mode);
    return observation->cloexec && observation->directory ? 0 : -1;
}

static int count_descriptors(void)
{
    DIR *stream = opendir("/proc/self/fd");
    struct dirent *entry;
    int count = 0;

    if (stream == NULL) {
        return -1;
    }
    while ((entry = readdir(stream)) != NULL) {
        if (strcmp(entry->d_name, ".") != 0
            && strcmp(entry->d_name, "..") != 0) {
            count++;
        }
    }
    if (closedir(stream) != 0) {
        return -1;
    }
    return count;
}

static int module_call(lua_State *L, const char *name, int arguments, int results)
{
    int base = lua_gettop(L) - arguments + 1;

    lua_getglobal(L, "proc17_repository_fs");
    lua_getfield(L, -1, name);
    lua_remove(L, -2);
    lua_insert(L, base);
    return lua_pcall(L, arguments, results, 0);
}

static int fail(lua_State *L, const char *message)
{
    if (L != NULL && lua_gettop(L) > 0 && lua_isstring(L, -1)) {
        fprintf(stderr, "%s: %s\n", message, lua_tostring(L, -1));
    } else {
        fprintf(stderr, "%s\n", message);
    }
    return 1;
}

static int run_shared_abi(void)
{
    char base[] = "/tmp/proc17-qa-abi-XXXXXX";
    char repository[sizeof(base) + 8U];
    struct borrow_observation observation = {0};
    lua_State *L = NULL;
    int handle_ref = LUA_NOREF;
    int before;
    int after;
    int status;
    int result = 1;

    if (mkdtemp(base) == NULL) {
        perror("mkdtemp");
        return 1;
    }
    if (snprintf(repository, sizeof(repository), "%s/repo", base)
            >= (int)sizeof(repository)
        || mkdir(repository, 0700) != 0) {
        perror("mkdir");
        goto cleanup_path;
    }

    L = luaL_newstate();
    if (L == NULL) {
        goto cleanup_path;
    }
    luaL_requiref(L, "proc17_repository_fs", luaopen_proc17_repository_fs, 1);
    lua_pop(L, 1);

    lua_pushstring(L, base);
    lua_pushliteral(L, "repo");
    if (module_call(L, "open_repository", 2, 2) != LUA_OK
        || !lua_isuserdata(L, -2) || !lua_istable(L, -1)) {
        fail(L, "open_repository failed");
        goto cleanup_lua;
    }
    lua_pop(L, 1);
    handle_ref = luaL_ref(L, LUA_REGISTRYINDEX);

    before = count_descriptors();
    lua_rawgeti(L, LUA_REGISTRYINDEX, handle_ref);
    status = proc17_qa_with_repository_source(
        L, -1, observe_borrow, &observation);
    lua_pop(L, 1);
    after = count_descriptors();
    if (status != PROC17_QA_SOURCE_OK || observation.calls != 1
        || !observation.cloexec || !observation.directory
        || before < 0 || before != after) {
        fail(L, "exact repository borrow failed or leaked a descriptor");
        goto cleanup_lua;
    }

    lua_newuserdatauv(L, 1U, 0);
    status = proc17_qa_with_repository_source(
        L, -1, observe_borrow, &observation);
    lua_pop(L, 1);
    if (status != PROC17_QA_SOURCE_INVALID_USERDATA) {
        fail(L, "foreign userdata crossed the repository ABI");
        goto cleanup_lua;
    }

    lua_rawgeti(L, LUA_REGISTRYINDEX, handle_ref);
    if (module_call(L, "revalidate", 1, 1) != LUA_OK
        || !lua_istable(L, -1)) {
        fail(L, "borrow changed the original repository handle");
        goto cleanup_lua;
    }
    lua_pop(L, 1);

    lua_rawgeti(L, LUA_REGISTRYINDEX, handle_ref);
    if (module_call(L, "close", 1, 1) != LUA_OK
        || !lua_toboolean(L, -1)) {
        fail(L, "close failed");
        goto cleanup_lua;
    }
    lua_pop(L, 1);
    lua_rawgeti(L, LUA_REGISTRYINDEX, handle_ref);
    status = proc17_qa_with_repository_source(
        L, -1, observe_borrow, &observation);
    lua_pop(L, 1);
    if (status != PROC17_QA_SOURCE_CLOSED) {
        fail(L, "closed repository handle was borrowed");
        goto cleanup_lua;
    }

    result = 0;

cleanup_lua:
    if (handle_ref != LUA_NOREF) {
        luaL_unref(L, LUA_REGISTRYINDEX, handle_ref);
    }
    lua_close(L);
cleanup_path:
    (void)rmdir(repository);
    (void)rmdir(base);
    if (result == 0) {
        puts("proc17 QA shared repository ABI ok");
    }
    return result;
}

static int load_launcher(lua_State *L)
{
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "loadlib");
    lua_remove(L, -2);
    lua_pushliteral(L, "./proc17_qa_launcher.so");
    lua_pushliteral(L, "luaopen_proc17_qa_launcher");
    if (lua_pcall(L, 2, 1, 0) != LUA_OK || !lua_isfunction(L, -1)
        || lua_pcall(L, 0, 1, 0) != LUA_OK || !lua_istable(L, -1)) {
        return -1;
    }
    return 0;
}

static int exact_string_field(
    lua_State *L,
    int index,
    const char *name,
    const char *expected)
{
    int result;
    lua_getfield(L, index, name);
    result = lua_isstring(L, -1) && strcmp(lua_tostring(L, -1), expected) == 0;
    lua_pop(L, 1);
    return result;
}

static int table_key_count(lua_State *L, int index)
{
    int count = 0;
    index = lua_absindex(L, index);
    lua_pushnil(L);
    while (lua_next(L, index) != 0) {
        count++;
        lua_pop(L, 1);
    }
    return count;
}

static int call_probe(lua_State *L)
{
    if (load_launcher(L) != 0) {
        return -1;
    }
    lua_getfield(L, -1, "probe_environment");
    lua_remove(L, -2);
    if (lua_pcall(L, 0, LUA_MULTRET, 0) != LUA_OK
        || lua_gettop(L) != 1 || !lua_istable(L, -1)
        || !exact_string_field(L, -1, "protocol_version", "qa.native_probe.v1")
        || !exact_string_field(L, -1, "provider_id",
            "linux.qa_supervisor.lua54.v0")
        || !exact_string_field(L, -1, "supervisor_abi",
            "proc17.qa_supervisor.v0")
        || !exact_string_field(L, -1, "event_truth_status",
            "runtime_confirmed")) {
        return -1;
    }
    lua_getfield(L, -1, "runtime_heap_limit_bytes");
    if (!lua_isinteger(L, -1)
        || lua_tointeger(L, -1) != (lua_Integer)PROC17_QA_RUNTIME_HEAP_BYTES) {
        lua_pop(L, 1);
        return -1;
    }
    lua_pop(L, 1);
    return 0;
}

static int run_launcher_contract(void)
{
    lua_State *L = luaL_newstate();
    int result = 1;

    if (L == NULL) {
        return 1;
    }
    luaL_openlibs(L);
    if (load_launcher(L) != 0 || table_key_count(L, -1) != 10
        || !exact_string_field(L, -1, "protocol_version",
            "qa.native_launcher.v0")
        || !exact_string_field(L, -1, "abi_version",
            "proc17.qa.launcher.lua54.v0")
        || !exact_string_field(L, -1, "provider_id",
            "linux.qa_supervisor.lua54.v0")
        || !exact_string_field(L, -1, "supervisor_abi",
            "proc17.qa_supervisor.v0")) {
        goto cleanup;
    }
    lua_getfield(L, -1, "limits");
    if (!lua_istable(L, -1) || table_key_count(L, -1) != 11) {
        goto cleanup;
    }
    lua_pop(L, 1);
    lua_getfield(L, -1, "probe_environment");
    if (!lua_isfunction(L, -1)) {
        goto cleanup;
    }
    lua_pop(L, 1);
    lua_getfield(L, -1, "run_lua54_test_suite");
    if (!lua_isfunction(L, -1)) {
        goto cleanup;
    }
    lua_pushnil(L);
    lua_pushnil(L);
    if (lua_pcall(L, 2, 2, 0) != LUA_OK || !lua_isnil(L, -2)
        || !lua_istable(L, -1)
        || !exact_string_field(L, -1, "code",
            "native_run_request_rejected")) {
        goto cleanup;
    }
    result = 0;

cleanup:
    lua_close(L);
    if (result == 0) {
        puts("proc17 QA launcher closed ABI ok");
    }
    return result;
}

static int hash_file(const char *path, char tagged[72])
{
    struct proc17_sha256 context;
    unsigned char digest[PROC17_SHA256_BYTES];
    char hexadecimal[PROC17_SHA256_BYTES * 2U + 1U];
    unsigned char buffer[16384];
    FILE *file = fopen(path, "rb");
    size_t total = 0;

    if (file == NULL) {
        return -1;
    }
    proc17_sha256_init(&context);
    for (;;) {
        size_t observed = fread(buffer, 1U, sizeof(buffer), file);
        if (observed > 0U) {
            total += observed;
            if (total > 64U * 1024U * 1024U) {
                fclose(file);
                return -1;
            }
            proc17_sha256_update(&context, buffer, observed);
        }
        if (observed < sizeof(buffer)) {
            if (ferror(file)) {
                fclose(file);
                return -1;
            }
            break;
        }
    }
    if (fclose(file) != 0) {
        return -1;
    }
    proc17_sha256_final(&context, digest);
    proc17_sha256_hex(digest, hexadecimal);
    snprintf(tagged, 72U, "sha256:%s", hexadecimal);
    return 0;
}

static int run_launcher_identity(void)
{
    lua_State *L = luaL_newstate();
    char observed[72];
    const char *expected;
    int result = 1;

    if (L == NULL || hash_file("./proc17_qa_supervisor", observed) != 0) {
        if (L != NULL) lua_close(L);
        return 1;
    }
    luaL_openlibs(L);
    if (load_launcher(L) != 0) {
        goto cleanup;
    }
    lua_getfield(L, -1, "expected_supervisor_build_id");
    expected = lua_tostring(L, -1);
    if (expected == NULL || strcmp(expected, observed) != 0) {
        goto cleanup;
    }
    result = 0;

cleanup:
    lua_close(L);
    if (result == 0) {
        puts("proc17 QA launcher identity ok");
    }
    return result;
}

static int run_launcher_probe(int check_descriptors)
{
    lua_State *L = luaL_newstate();
    int before = -1;
    int after = -1;
    int result = 1;

    if (L == NULL) {
        return 1;
    }
    luaL_openlibs(L);
    if (check_descriptors) {
        before = count_descriptors();
    }
    if (call_probe(L) != 0) {
        goto cleanup;
    }
    if (check_descriptors) {
        after = count_descriptors();
        if (before < 0 || before != after) {
            goto cleanup;
        }
    }
    result = 0;

cleanup:
    lua_close(L);
    if (result == 0) {
        puts(check_descriptors
            ? "proc17 QA launcher fd contract ok"
            : "proc17 QA launcher execveat probe ok");
    }
    return result;
}

int main(int argument_count, char **arguments)
{
    if (argument_count == 1) {
        return run_shared_abi();
    }
    if (argument_count != 2) {
        return 2;
    }
    if (strcmp(arguments[1], "contract") == 0) {
        return run_launcher_contract();
    }
    if (strcmp(arguments[1], "identity") == 0) {
        return run_launcher_identity();
    }
    if (strcmp(arguments[1], "exec") == 0) {
        return run_launcher_probe(0);
    }
    if (strcmp(arguments[1], "fd") == 0) {
        return run_launcher_probe(1);
    }
    return 2;
}
