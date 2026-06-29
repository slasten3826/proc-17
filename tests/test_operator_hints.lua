package.path = "./?.lua;./?/init.lua;" .. package.path

local hints = require("runtime.operator_hints")

local payload = hints.payload()

if payload.enabled ~= true then
    error("operator hints should be enabled by default")
end

if payload.density ~= "short" then
    error("operator hints should use short density")
end

if #payload.active ~= 10 then
    error("operator hints should include all 10 operators in v0")
end

if hints.count(payload) <= 0 then
    error("operator hints count should be positive")
end

local formatted = hints.format_for_substrate(payload)
if type(formatted) ~= "string" or formatted == "" then
    error("operator hints should format for substrate when enabled")
end

if not formatted:find("These are local pressure hints, not runtime truth.", 1, true) then
    error("operator hints formatted text should preserve truth boundary")
end

if not formatted:find("Choice kills alternatives.", 1, true) then
    error("operator hints formatted text should include CHOOSE pressure")
end

if not formatted:find("Do not promote prose into runtime truth.", 1, true) then
    error("operator hints formatted text should include ENCODE prose boundary")
end

local trace_payload = hints.trace_payload(payload, "default")
if trace_payload.enabled ~= true then
    error("operator hints trace payload should be enabled")
end

if trace_payload.hint_count ~= hints.count(payload) then
    error("operator hints trace payload should report hint count")
end

if #trace_payload.operators ~= 10 then
    error("operator hints trace payload should report all operators")
end

local disabled = hints.payload({enabled = false})
if disabled.enabled ~= false then
    error("operator hints disabled payload should be disabled")
end

if #disabled.active ~= 0 then
    error("operator hints disabled payload should have no active hints")
end

if hints.format_for_substrate(disabled) ~= nil then
    error("operator hints should not format disabled payload for substrate")
end

local disabled_trace = hints.trace_payload(disabled, "cli")
if disabled_trace.enabled ~= false then
    error("operator hints disabled trace should be disabled")
end

if disabled_trace.reason ~= "cli" then
    error("operator hints disabled trace should preserve reason")
end

if disabled_trace.hint_count ~= 0 then
    error("operator hints disabled trace should have zero hints")
end

print("test_operator_hints ok")
