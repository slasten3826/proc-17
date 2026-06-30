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

if not output:find('"work_mode":"build"', 1, true) then
    error("cli output should default to build work mode")
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

if not output:find('"type":"hint_pressure"', 1, true) then
    error("cli output should include operator hint pressure by default")
end

if not output:find('"operator_hints"', 1, true) then
    error("cli substrate call should include operator hints payload by default")
end

if not output:find('"system_prompt"', 1, true) then
    error("cli substrate call should include proc-17 system prompt")
end

if not output:find("You are substrate current inside proc-17.", 1, true) then
    error("cli system prompt should place substrate inside proc-17")
end

if not output:find("Do not use external meanings of 'plan mode' or 'build mode'", 1, true) then
    error("cli system prompt should bind plan/build meanings")
end

if not output:find('"enabled":true', 1, true) then
    error("cli operator hints should be enabled by default")
end

if not output:find('"reason":"work_mode_build"', 1, true) then
    error("cli operator hints should derive from build work mode by default")
end

if not output:find('"hint_count":32', 1, true) then
    error("cli operator hints trace should include v0 hint count")
end

if not output:find("Choice kills alternatives.", 1, true) then
    error("cli prompt payload should include CHOOSE procesis word when enabled")
end

if not output:find("[procesis word]", 1, true) then
    error("cli prompt payload should label operator block as procesis word")
end

if not output:find('"kind":"choose_collapse"', 1, true) then
    error("cli output should include CHOOSE collapse by default")
end

if not output:find('"kind":"encoded_field"', 1, true) then
    error("cli output should include ENCODE field by default before CHOOSE")
end

if not output:find('"shape":"semantic_line_field"', 1, true) then
    error("cli output should include semantic field shape")
end

if not output:find('"field_shape":"semantic_line_field"', 1, true) then
    error("cli CHOOSE pressure should include semantic field shape")
end

if not output:find('"collapse_level":"item"', 1, true) then
    error("cli CHOOSE loss should include item collapse level")
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

local no_hints_handle = io.popen('lua cli/procesis-body.lua run --task "fake task" --fake --jsonl --no-hints')
local no_hints_output = no_hints_handle:read("*a")
local no_hints_ok, _, no_hints_code = no_hints_handle:close()

if not no_hints_ok or no_hints_code ~= 0 then
    error("cli no-hints run exited with non-zero code")
end

if not no_hints_output:find('"type":"hint_pressure"', 1, true) then
    error("cli no-hints output should still record hint pressure state")
end

if not no_hints_output:find('"enabled":false', 1, true) then
    error("cli no-hints output should mark hints disabled")
end

if not no_hints_output:find('"hint_count":0', 1, true) then
    error("cli no-hints output should have zero hint count")
end

if not no_hints_output:find('"reason":"cli_override"', 1, true) then
    error("cli no-hints output should mark cli override")
end

if no_hints_output:find("Choice kills alternatives.", 1, true) then
    error("cli no-hints prompt payload should not include CHOOSE procesis word")
end

local hints_handle = io.popen('lua cli/procesis-body.lua run --task "fake task" --fake --jsonl --hints')
local hints_output = hints_handle:read("*a")
local hints_ok, _, hints_code = hints_handle:close()

if not hints_ok or hints_code ~= 0 then
    error("cli explicit hints run exited with non-zero code")
end

if not hints_output:find('"enabled":true', 1, true) then
    error("cli explicit hints output should mark hints enabled")
end

if not hints_output:find('"reason":"cli_override"', 1, true) then
    error("cli explicit hints output should mark cli override")
end

if not hints_output:find("Do not promote prose into runtime truth.", 1, true) then
    error("cli explicit hints prompt payload should include ENCODE boundary")
end

local plan_handle = io.popen('lua cli/procesis-body.lua run --task "plan task" --fake --jsonl --work-mode plan')
local plan_output = plan_handle:read("*a")
local plan_ok, _, plan_code = plan_handle:close()

if not plan_ok or plan_code ~= 0 then
    error("cli plan work mode run exited with non-zero code")
end

if not plan_output:find('"work_mode":"plan"', 1, true) then
    error("cli plan output should expose work mode")
end

if not plan_output:find('"enabled":false', 1, true) then
    error("cli plan work mode should disable hints by default")
end

if not plan_output:find('"reason":"work_mode_plan"', 1, true) then
    error("cli plan work mode should explain hint pressure reason")
end

if plan_output:find("Choice kills alternatives.", 1, true) then
    error("cli plan work mode should not inject hint text by default")
end

local plan_hints_handle = io.popen('lua cli/procesis-body.lua run --task "plan task" --fake --jsonl --work-mode plan --hints')
local plan_hints_output = plan_hints_handle:read("*a")
local plan_hints_ok, _, plan_hints_code = plan_hints_handle:close()

if not plan_hints_ok or plan_hints_code ~= 0 then
    error("cli plan work mode with hints override exited with non-zero code")
end

if not plan_hints_output:find('"work_mode":"plan"', 1, true) then
    error("cli plan hints override should keep plan work mode")
end

if not plan_hints_output:find('"enabled":true', 1, true) then
    error("cli plan hints override should enable hints")
end

if not plan_hints_output:find('"reason":"cli_override"', 1, true) then
    error("cli plan hints override should mark cli override")
end

local build_handle = io.popen('lua cli/procesis-body.lua run --task "build task" --fake --jsonl --work-mode build')
local build_output = build_handle:read("*a")
local build_ok, _, build_code = build_handle:close()

if not build_ok or build_code ~= 0 then
    error("cli build work mode run exited with non-zero code")
end

if not build_output:find('"work_mode":"build"', 1, true) then
    error("cli build output should expose work mode")
end

if not build_output:find('"enabled":true', 1, true) then
    error("cli build work mode should enable hints by default")
end

if not build_output:find('"reason":"work_mode_build"', 1, true) then
    error("cli build work mode should explain hint pressure reason")
end

local build_no_hints_handle = io.popen('lua cli/procesis-body.lua run --task "build task" --fake --jsonl --work-mode build --no-hints')
local build_no_hints_output = build_no_hints_handle:read("*a")
local build_no_hints_ok, _, build_no_hints_code = build_no_hints_handle:close()

if not build_no_hints_ok or build_no_hints_code ~= 0 then
    error("cli build work mode with no-hints override exited with non-zero code")
end

if not build_no_hints_output:find('"work_mode":"build"', 1, true) then
    error("cli build no-hints override should keep build work mode")
end

if not build_no_hints_output:find('"enabled":false', 1, true) then
    error("cli build no-hints override should disable hints")
end

if not build_no_hints_output:find('"reason":"cli_override"', 1, true) then
    error("cli build no-hints override should mark cli override")
end

local no_choose_handle = io.popen('lua cli/procesis-body.lua run --task "fake task" --fake --jsonl --no-choose')
local no_choose_output = no_choose_handle:read("*a")
local no_choose_ok, _, no_choose_code = no_choose_handle:close()

if not no_choose_ok or no_choose_code ~= 0 then
    error("cli no-choose run exited with non-zero code")
end

if no_choose_output:find('"kind":"choose_collapse"', 1, true) then
    error("cli output should omit CHOOSE collapse only when disabled")
end

if no_choose_output:find('"kind":"encoded_field"', 1, true) then
    error("cli output should omit ENCODE field when CHOOSE is disabled in v0")
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

if not no_logic_output:find('"kind":"choose_collapse"', 1, true) then
    error("CHOOSE should remain default-on when LOGIC is disabled")
end

if not no_logic_output:find('"kind":"encoded_field"', 1, true) then
    error("ENCODE should remain default-on when LOGIC is disabled")
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

if not listing_output:find('"shape":"repo_path_field"', 1, true) then
    error("cli repo listing output missing repo path field shape")
end

if not listing_output:find('"collapse_level":"path"', 1, true) then
    error("cli repo listing CHOOSE should use path collapse level")
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

local bad_hints_handle = io.popen('lua cli/procesis-body.lua run --task "bad hints" --fake --jsonl --hints --no-hints 2>/dev/null')
bad_hints_handle:read("*a")
local bad_hints_ok, _, bad_hints_code = bad_hints_handle:close()

if bad_hints_ok or bad_hints_code ~= 2 then
    error("conflicting hints flags should exit with code 2")
end

local bad_work_mode_handle = io.popen('lua cli/procesis-body.lua run --task "bad work mode" --fake --jsonl --work-mode nope 2>/dev/null')
bad_work_mode_handle:read("*a")
local bad_work_mode_ok, _, bad_work_mode_code = bad_work_mode_handle:close()

if bad_work_mode_ok or bad_work_mode_code ~= 2 then
    error("invalid work mode should exit with code 2")
end

local conflict_work_mode_handle = io.popen('lua cli/procesis-body.lua run --task "bad work mode" --fake --jsonl --work-mode plan --work-mode build 2>/dev/null')
conflict_work_mode_handle:read("*a")
local conflict_work_mode_ok, _, conflict_work_mode_code = conflict_work_mode_handle:close()

if conflict_work_mode_ok or conflict_work_mode_code ~= 2 then
    error("conflicting work modes should exit with code 2")
end

print("test_cli ok")
