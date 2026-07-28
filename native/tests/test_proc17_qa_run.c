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
    "local function request(version) return {protocol_version=version,"
    "operation='run_lua54_test_suite',"
    "transaction_id='qa-provider-transaction:'..string.rep('a',64),"
    "witness_id='qa-provider-witness:'..string.rep('b',64),"
    "profile_id='qa.profile.lua54_test_suite.v0',"
    "environment_id='qa-environment:'..string.rep('c',64),"
    "entrypoint_relative_path='tests/run.lua',expected_exit_code=0,"
    "resource_limits=limits} end\n"
    "local function open_root(root)\n"
    "  local handle,err=proc17_repository_fs.open_repository("
    "QA_CANDIDATE_BASE,root); assert(handle,err and err.code)\n"
    "  return handle\n"
    "end\n"
    "local function run(root, expected_reason, expected_exit)\n"
    "  local handle=open_root(root)\n"
    "  local result,failure=proc17_qa_launcher.run_lua54_test_suite("
    "handle,request('qa.native_run_request.v1')); "
    "assert(result,failure and table.concat({"
    "tostring(failure.code),tostring(failure.stage),"
    "tostring(failure.candidate_start_state),"
    "tostring(failure.cleanup_state),tostring(failure.launcher_reaped),"
    "tostring(failure.result_eof)},'/'))\n"
    "  assert(result.protocol_version=='qa.native_run_result.v1' "
    "and result.phase_ordinal==2)\n"
    "  assert(result.transaction_id=='qa-provider-transaction:'.."
    "string.rep('a',64))\n"
    "  assert(result.witness_id=='qa-provider-witness:'.."
    "string.rep('b',64))\n"
    "  assert(result.profile_id=='qa.profile.lua54_test_suite.v0')\n"
    "  assert(result.environment_id=='qa-environment:'.."
    "string.rep('c',64))\n"
    "  assert(result.disposition=='contained_candidate')\n"
    "  assert(result.reason==expected_reason and result.start_attested)\n"
    "  assert(result.source_staging_policy=="
    "'qa.source_staging.detached_mount.v0' "
    "and result.source_staging_complete)\n"
    "  assert(result.event_truth_status=='runtime_confirmed')\n"
    "  assert(result.termination.kind==1)\n"
    "  assert(result.termination.exit_code==expected_exit)\n"
    "  assert(result.cause.protocol_version=='qa.first_cause.v1' "
    "and result.cause.kind==expected_reason "
    "and result.cause.monotonic_sequence>=1)\n"
    "  assert(result.finality.source_staging_complete)\n"
    "  assert(result.finality.candidate_started)\n"
    "  assert(result.finality.candidate_terminal_observed)\n"
    "  assert(result.finality.namespace_cleanup_complete)\n"
    "  assert(result.finality.process_tree_reaped)\n"
    "  assert(result.finality.stdout_eof_observed)\n"
    "  assert(result.finality.stderr_eof_observed)\n"
    "  assert(result.finality.scratch_observation_complete)\n"
    "  assert(result.stdout.observed_bytes==0 and result.stdout.eof_observed)\n"
    "  assert(result.stderr.observed_bytes==0 and result.stderr.eof_observed)\n"
    "  assert(result.stdout.protocol_version=='qa.stream_measurement.v1' "
    "and result.stderr.protocol_version=='qa.stream_measurement.v1')\n"
    "  assert(result.stdout.sha256=='sha256:e3b0c44298fc1c149afbf4c8996fb924"
    "27ae41e4649b934ca495991b7852b855')\n"
    "  assert(result.resources.protocol_version=="
    "'qa.resource_measurement.v1')\n"
    "  assert(result.scratch.protocol_version=='qa.scratch_measurement.v1' "
    "and result.scratch.inventory_complete)\n"
    "  assert(result.candidate_process_token==nil)\n"
    "  assert(proc17_repository_fs.close(handle))\n"
    "end\n"
    "local function reject_v0(root)\n"
    "  local handle=open_root(root)\n"
    "  local ok,err=pcall(proc17_qa_launcher.run_lua54_test_suite,handle,"
    "request('qa.native_run_request.v0'))\n"
    "  assert(not ok and string.find(err,'RUN v1 request rejected',1,true))\n"
    "  assert(proc17_repository_fs.close(handle))\n"
    "end\n"
    "run('clean_silent','expected_exit',0)\n"
    "run('runtime_error_silent','unexpected_exit',70)\n"
    "reject_v0('clean_silent')\n";

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
