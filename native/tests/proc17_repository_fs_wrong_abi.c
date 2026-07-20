#include <lua.h>
#include <lauxlib.h>

static void set_string(lua_State *L, const char *key, const char *value)
{
    lua_pushstring(L, value);
    lua_setfield(L, -2, key);
}

static void set_integer(lua_State *L, const char *key, lua_Integer value)
{
    lua_pushinteger(L, value);
    lua_setfield(L, -2, key);
}

static int unavailable(lua_State *L)
{
    lua_pushnil(L);
    lua_pushliteral(L, "wrong ABI fixture must never be called");
    return 2;
}

int luaopen_proc17_repository_fs(lua_State *L)
{
    lua_createtable(L, 0, 10);
    set_string(L, "protocol_version", "repository.native_provider.v0");
    set_string(L, "abi_version", "proc17.repository.fs.lua54.wrong");
    set_string(L, "provider_id", "linux.openat2.renameat2.v0");
    set_string(L, "contract_id", "repository.provider.create_readback.v0");

    lua_createtable(L, 0, 5);
    set_integer(L, "max_relative_path_bytes", 1024);
    set_integer(L, "max_component_bytes", 255);
    set_integer(L, "max_components", 64);
    set_integer(L, "max_content_bytes", 1048576);
    set_integer(L, "file_mode", 0600);
    lua_setfield(L, -2, "limits");

    lua_pushcfunction(L, unavailable);
    lua_setfield(L, -2, "open_repository");
    lua_pushcfunction(L, unavailable);
    lua_setfield(L, -2, "revalidate");
    lua_pushcfunction(L, unavailable);
    lua_setfield(L, -2, "create_text_file");
    lua_pushcfunction(L, unavailable);
    lua_setfield(L, -2, "read_text_file");
    lua_pushcfunction(L, unavailable);
    lua_setfield(L, -2, "close");
    return 1;
}
