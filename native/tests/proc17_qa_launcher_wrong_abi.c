#include <lua.h>

static int refused(lua_State *L)
{
    lua_pushnil(L);
    return 1;
}

static void push_limits(lua_State *L)
{
    lua_createtable(L, 0, 11);
    lua_pushliteral(L, "qa.resource_limits.v0");
    lua_setfield(L, -2, "protocol_version");
#define PUSH_LIMIT(name, value) \
    do { lua_pushinteger(L, value); lua_setfield(L, -2, name); } while (0)
    PUSH_LIMIT("wall_time_ms", 30000);
    PUSH_LIMIT("cpu_time_ms", 20000);
    PUSH_LIMIT("address_space_bytes", 268435456);
    PUSH_LIMIT("max_processes", 1);
    PUSH_LIMIT("max_open_files", 64);
    PUSH_LIMIT("max_file_bytes", 16777216);
    PUSH_LIMIT("scratch_bytes", 67108864);
    PUSH_LIMIT("scratch_entries", 4096);
    PUSH_LIMIT("stdout_bytes", 1048576);
    PUSH_LIMIT("stderr_bytes", 1048576);
#undef PUSH_LIMIT
}

int luaopen_proc17_qa_launcher(lua_State *L)
{
    static const char digest[] =
        "sha256:0000000000000000000000000000000000000000000000000000000000000000";
    lua_createtable(L, 0, 10);
    lua_pushliteral(L, "qa.native_launcher.v0");
    lua_setfield(L, -2, "protocol_version");
    lua_pushliteral(L, "proc17.qa.launcher.lua54.wrong");
    lua_setfield(L, -2, "abi_version");
    lua_pushliteral(L, "linux.qa_supervisor.lua54.v0");
    lua_setfield(L, -2, "provider_id");
    lua_pushliteral(L, "proc17.qa_supervisor.v0");
    lua_setfield(L, -2, "supervisor_abi");
    lua_pushstring(L, digest);
    lua_setfield(L, -2, "expected_supervisor_build_id");
    lua_pushstring(L, digest);
    lua_setfield(L, -2, "runtime_build_id");
    lua_pushstring(L, digest);
    lua_setfield(L, -2, "policy_digest");
    push_limits(L);
    lua_setfield(L, -2, "limits");
    lua_pushcfunction(L, refused);
    lua_setfield(L, -2, "probe_environment");
    lua_pushcfunction(L, refused);
    lua_setfield(L, -2, "run_lua54_test_suite");
    return 1;
}
