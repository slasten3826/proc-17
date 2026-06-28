package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local trace_store = require("runtime.trace_store")

local path = "/tmp/procesis-body-trace-store-test.jsonl"
local p = packet.new("trace task", {id = "packet-trace-test"})
packet.manifest(p, {truth_status = "runtime_confirmed", result = "ok"})
packet.die(p, "complete")

local ok, err = trace_store.write_jsonl(path, p)
if not ok then
    error(err)
end

local file = io.open(path, "r")
if not file then
    error("trace file was not written")
end

local content = file:read("*a")
file:close()
os.remove(path)

if not content:find('"type":"birth"', 1, true) then
    error("trace file missing birth event")
end

if not content:find('"type":"final"', 1, true) then
    error("trace file missing final envelope")
end

print("test_trace_store ok")
