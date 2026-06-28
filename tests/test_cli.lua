local handle = io.popen('lua cli/procesis-body.lua run --task "fake task" --fake --jsonl')
local output = handle:read("*a")
local ok, _, code = handle:close()

if not ok or code ~= 0 then
    error("cli exited with non-zero code")
end

if not output:find('"type":"birth"', 1, true) then
    error("cli output missing birth event")
end

if not output:find('"type":"mode_enter"', 1, true) then
    error("cli output missing mode_enter event")
end

if not output:find('"type":"substrate_result"', 1, true) then
    error("cli output missing substrate_result event")
end

if not output:find('"type":"tool_call"', 1, true) then
    error("cli output missing tool_call event")
end

if not output:find('"type":"tool_result"', 1, true) then
    error("cli output missing tool_result event")
end

if not output:find('"truth_status":"semantic_proposal"', 1, true) then
    error("cli output missing semantic_proposal truth status")
end

if not output:find('"type":"final"', 1, true) then
    error("cli output missing final envelope")
end

if not output:find('"kind":"runtime_pressure_snapshot"', 1, true) then
    error("cli output should include runtime pressure snapshot by default")
end

if not output:find('"kind":"substrate_result_boundary"', 1, true) then
    error("cli output should include LOGIC boundary by default")
end

if not output:find('"kind":"cycle_decision"', 1, true) then
    error("cli output should include CYCLE decision by default")
end

if not output:find('"result":"substrate loop complete"', 1, true) then
    error("cli output missing neutral manifest result")
end

local no_runtime_handle = io.popen('lua cli/procesis-body.lua run --task "fake task" --fake --jsonl --no-runtime-snapshot')
local no_runtime_output = no_runtime_handle:read("*a")
local no_runtime_ok, _, no_runtime_code = no_runtime_handle:close()

if not no_runtime_ok or no_runtime_code ~= 0 then
    error("cli no-runtime snapshot run exited with non-zero code")
end

if no_runtime_output:find('"kind":"runtime_pressure_snapshot"', 1, true) then
    error("cli output should omit runtime pressure snapshot only when disabled")
end

local no_logic_handle = io.popen('lua cli/procesis-body.lua run --task "fake task" --fake --jsonl --no-logic')
local no_logic_output = no_logic_handle:read("*a")
local no_logic_ok, _, no_logic_code = no_logic_handle:close()

if not no_logic_ok or no_logic_code ~= 0 then
    error("cli no-logic run exited with non-zero code")
end

if no_logic_output:find('"kind":"substrate_result_boundary"', 1, true) then
    error("cli output should omit LOGIC boundary only when disabled")
end

if not no_logic_output:find('"kind":"cycle_decision"', 1, true) then
    error("CYCLE should remain default-on when LOGIC is disabled")
end

local no_cycle_handle = io.popen('lua cli/procesis-body.lua run --task "fake task" --fake --jsonl --no-cycle')
local no_cycle_output = no_cycle_handle:read("*a")
local no_cycle_ok, _, no_cycle_code = no_cycle_handle:close()

if not no_cycle_ok or no_cycle_code ~= 0 then
    error("cli no-cycle run exited with non-zero code")
end

if no_cycle_output:find('"kind":"cycle_decision"', 1, true) then
    error("cli output should omit CYCLE decision only when disabled")
end

if not no_cycle_output:find('"kind":"substrate_result_boundary"', 1, true) then
    error("LOGIC should remain default-on when CYCLE is disabled")
end

local mode_handle = io.popen('lua cli/procesis-body.lua run --task "mode task" --fake --jsonl --mode chaos')
local mode_output = mode_handle:read("*a")
local mode_ok, _, mode_code = mode_handle:close()

if not mode_ok or mode_code ~= 0 then
    error("cli mode run exited with non-zero code")
end

if not mode_output:find('"mode":"chaos"', 1, true) then
    error("cli output missing selected mode")
end

local listing_handle = io.popen('lua cli/procesis-body.lua run --task "listing task" --fake --jsonl --repo-list')
local listing_output = listing_handle:read("*a")
local listing_ok, _, listing_code = listing_handle:close()

if not listing_ok or listing_code ~= 0 then
    error("cli repo listing run exited with non-zero code")
end

if not listing_output:find('"kind":"repo_listing"', 1, true) then
    error("cli output missing repo_listing observation")
end

if not listing_output:find('"repo_listing"', 1, true) then
    error("cli output missing repo_listing payload")
end

local context_handle = io.popen('lua cli/procesis-body.lua run --task "context task" --fake --jsonl --repo-context README.md')
local context_output = context_handle:read("*a")
local context_ok, _, context_code = context_handle:close()

if not context_ok or context_code ~= 0 then
    error("cli repo context run exited with non-zero code")
end

if not context_output:find('"kind":"repo_context"', 1, true) then
    error("cli output missing repo_context observation")
end

if not context_output:find('"truth_status":"runtime_confirmed"', 1, true) then
    error("cli output missing runtime_confirmed repo context")
end

local runtime_handle = io.popen('lua cli/procesis-body.lua run --task "runtime task" --fake --jsonl')
local runtime_output = runtime_handle:read("*a")
local runtime_ok, _, runtime_code = runtime_handle:close()

if not runtime_ok or runtime_code ~= 0 then
    error("cli runtime snapshot run exited with non-zero code")
end

if not runtime_output:find('"kind":"runtime_pressure_snapshot"', 1, true) then
    error("cli output missing runtime pressure snapshot observation")
end

if not runtime_output:find('"kind":"runtime_pressure_snapshot_payload"', 1, true) then
    error("cli output missing runtime pressure snapshot payload")
end

if runtime_output:find('"next_action"', 1, true) then
    error("runtime pressure snapshot must not expose next_action")
end

local bad_context_handle = io.popen('lua cli/procesis-body.lua run --task "bad context" --fake --jsonl --repo-context ../README.md 2>/dev/null')
bad_context_handle:read("*a")
local bad_context_ok, _, bad_context_code = bad_context_handle:close()

if bad_context_ok or bad_context_code ~= 2 then
    error("unsafe repo context should exit with code 2")
end

local bad_listing_handle = io.popen('lua cli/procesis-body.lua run --task "bad listing" --fake --jsonl --repo-list ../ 2>/dev/null')
bad_listing_handle:read("*a")
local bad_listing_ok, _, bad_listing_code = bad_listing_handle:close()

if bad_listing_ok or bad_listing_code ~= 2 then
    error("unsafe repo listing should exit with code 2")
end

local bad_mode_handle = io.popen('lua cli/procesis-body.lua run --task "bad mode" --fake --jsonl --mode nope 2>/dev/null')
bad_mode_handle:read("*a")
local bad_ok, _, bad_code = bad_mode_handle:close()

if bad_ok or bad_code ~= 2 then
    error("invalid mode should exit with code 2")
end

print("test_cli ok")
