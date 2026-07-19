local harness = {}

local function render(value)
    if type(value) == "string" then
        return value
    end
    return tostring(value)
end

function harness.optional_require(name)
    local ok, value = pcall(require, name)
    if ok then
        return value
    end
    return nil, tostring(value):match("^[^\n]+") or tostring(value)
end

function harness.new(name)
    local suite = {
        name = name,
        failures = {},
        passes = 0,
        skips = {},
    }

    function suite:check(id, callback)
        local ok, err = pcall(callback)
        if ok then
            self.passes = self.passes + 1
            print(self.name .. " GREEN " .. id)
        else
            self.failures[#self.failures + 1] = id .. ": " .. render(err)
            print(self.name .. " RED " .. id .. " " .. render(err))
        end
    end

    function suite:skip(id, reason)
        self.skips[#self.skips + 1] = id .. ": " .. tostring(reason)
        print(self.name .. " SKIP " .. id .. " " .. tostring(reason))
    end

    function suite:require_module(value, err, name)
        if value == nil then
            error("missing contract module " .. tostring(name) .. ": " .. tostring(err), 2)
        end
        return value
    end

    function suite:finish()
        print(string.format(
            "%s summary: green=%d red=%d skip=%d",
            self.name,
            self.passes,
            #self.failures,
            #self.skips
        ))
        if #self.failures > 0 then
            error(table.concat(self.failures, "\n"), 0)
        end
        return true
    end

    return suite
end

function harness.assert_true(value, message)
    if not value then
        error(message or "expected true", 2)
    end
end

function harness.assert_false(value, message)
    if value then
        error(message or "expected false", 2)
    end
end

function harness.assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

function harness.assert_nil(value, message)
    if value ~= nil then
        error((message or "expected nil") .. ": " .. tostring(value), 2)
    end
end

function harness.assert_contains(text, fragment, message)
    text = tostring(text)
    if text:find(fragment, 1, true) == nil then
        error((message or "text does not contain fragment") .. ": "
            .. text .. " !~ " .. tostring(fragment), 2)
    end
end

function harness.copy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[harness.copy(key, seen)] = harness.copy(child, seen)
    end
    return result
end

return harness
