#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <stdio.h>
#include <limits.h>
#include <stdlib.h>

int luaopen_proc17_repository_fs(lua_State *L);

static const char script[] =
    "local open=assert(package.loadlib('./proc17_qa_launcher.so',"
    "'luaopen_proc17_qa_launcher')); proc17_qa_launcher=open()\n"
    "local limits={protocol_version='qa.resource_limits.v0',"
    "wall_time_ms=30000,cpu_time_ms=20000,address_space_bytes=268435456,"
    "max_processes=1,max_open_files=64,max_file_bytes=16777216,"
    "scratch_bytes=67108864,scratch_entries=4096,"
    "stdout_bytes=1048576,stderr_bytes=1048576}\n"
    "local function run(root, expected_reason, expected_exit)\n"
    "  local handle,err=proc17_repository_fs.open_repository("
    "QA_CANDIDATE_BASE,root); assert(handle,err and err.code)\n"
    "  local request={protocol_version='qa.native_run_request.v0',"
    "operation='run_lua54_test_suite',"
    "transaction_id='qa-provider-transaction:'..string.rep('a',64),"
    "witness_id='qa-provider-witness:'..string.rep('b',64),"
    "profile_id='qa.profile.lua54_test_suite.v0',"
    "environment_id='qa-environment:'..string.rep('c',64),"
    "entrypoint_relative_path='tests/run.lua',expected_exit_code=0,"
    "resource_limits=limits}\n"
    "  local result,failure=proc17_qa_launcher.run_lua54_test_suite("
    "handle,request); assert(result,failure and failure.stage)\n"
    "  assert(result.protocol_version=='qa.native_run_result.v0')\n"
    "  assert(result.disposition_code==1 and result.reason_code==expected_reason)\n"
    "  assert(result.exit_code==expected_exit and result.candidate_started)\n"
    "  assert(result.cleanup_complete and result.stdout_bytes==0)\n"
    "  assert(result.stderr_bytes==0)\n"
    "  assert(result.stdout_sha256=='sha256:e3b0c44298fc1c149afbf4c8996fb924"
    "27ae41e4649b934ca495991b7852b855')\n"
    "  assert(proc17_repository_fs.close(handle))\n"
    "end\n"
    "run('clean_silent',1,0)\n"
    "run('runtime_error_silent',2,70)\n";

int main(void)
{
    lua_State *L = luaL_newstate();
    char candidate_base[PATH_MAX];
    if (L == NULL) return 1;
    if (realpath("tests/qa_candidates", candidate_base) == NULL) {
        lua_close(L);
        return 1;
    }
    luaL_openlibs(L);
    luaL_requiref(L, "proc17_repository_fs", luaopen_proc17_repository_fs, 1);
    lua_setglobal(L, "proc17_repository_fs");
    lua_pushstring(L, candidate_base);
    lua_setglobal(L, "QA_CANDIDATE_BASE");
    if (luaL_dostring(L, script) != LUA_OK) {
        fprintf(stderr, "proc17 QA basic RUN failed: %s\n",
            lua_tostring(L, -1));
        lua_close(L);
        return 1;
    }
    lua_close(L);
    puts("proc17 QA basic RUN fixtures ok");
    return 0;
}
