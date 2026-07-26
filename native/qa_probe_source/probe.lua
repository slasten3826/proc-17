local function check(value, code)
    assert(value, code)
end

check(_VERSION == "Lua 5.4", "P01")
check(package.path == "./?.lua;./?/init.lua", "P02")
check(package.cpath == "", "P03")
check(package.loadlib == nil, "P04")
check(debug == nil, "P05")
check(io.popen == nil and io.tmpfile == nil, "P06")
check(os.execute == nil and os.tmpname == nil, "P07")
check(os.getenv("HOME") == "/qa/scratch/home", "P08")
check(os.getenv("TMPDIR") == "/qa/scratch/tmp", "P09")
check(os.getenv("LANG") == "C", "P10")
check(os.getenv("LC_ALL") == "C", "P11")
check(os.getenv("TZ") == "UTC", "P12")
check(os.getenv("PATH") == nil, "P13")

local forbidden = io.open("probe-source-write-must-fail", "wb")
check(forbidden == nil, "P14")

local scratch = io.open("/qa/scratch/probe-result", "wb")
check(scratch ~= nil, "P15")
check(scratch:write("proc17 qa probe\n"), "P15")
check(scratch:close(), "P15")

print("proc17 qa restricted Lua probe ok")
