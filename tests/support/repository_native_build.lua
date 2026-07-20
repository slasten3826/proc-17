local native_build = {}
local built = false

local function command_ok(command)
    local ok, why, code = os.execute(command)
    return ok == true and (code == nil or code == 0), why, code
end

function native_build.ensure_loader_fixtures()
    if built then
        return true
    end
    local ok, why, code = command_ok(
        "make -C native provider-shell loader-test-fixture"
    )
    if not ok then
        return nil, "native loader fixture build failed: "
            .. tostring(why) .. ":" .. tostring(code)
    end
    built = true
    return true
end

return native_build
