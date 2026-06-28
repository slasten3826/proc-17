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

if not output:find('"result":"substrate loop complete"', 1, true) then
    error("cli output missing neutral manifest result")
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

local bad_mode_handle = io.popen('lua cli/procesis-body.lua run --task "bad mode" --fake --jsonl --mode nope 2>/dev/null')
bad_mode_handle:read("*a")
local bad_ok, _, bad_code = bad_mode_handle:close()

if bad_ok or bad_code ~= 2 then
    error("invalid mode should exit with code 2")
end

print("test_cli ok")
