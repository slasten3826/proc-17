local handle = io.popen('lua cli/procesis-body.lua run --task "fake task" --fake --jsonl')
local output = handle:read("*a")
local ok, _, code = handle:close()

if not ok or code ~= 0 then
    error("cli exited with non-zero code")
end

if not output:find('"type":"birth"', 1, true) then
    error("cli output missing birth event")
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

print("test_cli ok")
