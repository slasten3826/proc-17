local json = {}

local escapes = {
    ['"'] = '\\"',
    ["\\"] = "\\\\",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
}

local function escape_string(value)
    return value:gsub('[%z\1-\31\\"]', function(char)
        return escapes[char] or string.format("\\u%04x", char:byte())
    end)
end

local function is_array(value)
    local max = 0
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return false
        end
        if key > max then
            max = key
        end
        count = count + 1
    end
    return max == count
end

function json.encode(value)
    local kind = type(value)
    if kind == "nil" then
        return "null"
    elseif kind == "boolean" or kind == "number" then
        return tostring(value)
    elseif kind == "string" then
        return '"' .. escape_string(value) .. '"'
    elseif kind == "table" then
        local parts = {}
        if is_array(value) then
            for index = 1, #value do
                parts[#parts + 1] = json.encode(value[index])
            end
            return "[" .. table.concat(parts, ",") .. "]"
        end

        local keys = {}
        for key in pairs(value) do
            keys[#keys + 1] = key
        end
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)

        for _, key in ipairs(keys) do
            parts[#parts + 1] = json.encode(tostring(key)) .. ":" .. json.encode(value[key])
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end

    error("cannot encode " .. kind .. " as json")
end

local function new_parser(text)
    local parser = {text = text, index = 1}

    function parser:peek()
        return self.text:sub(self.index, self.index)
    end

    function parser:next()
        local char = self:peek()
        self.index = self.index + 1
        return char
    end

    function parser:skip_ws()
        while self:peek():match("%s") do
            self.index = self.index + 1
        end
    end

    function parser:parse_string()
        if self:next() ~= '"' then
            error("expected string")
        end
        local parts = {}
        while true do
            local char = self:next()
            if char == "" then
                error("unterminated string")
            elseif char == '"' then
                return table.concat(parts)
            elseif char == "\\" then
                local escaped = self:next()
                if escaped == '"' or escaped == "\\" or escaped == "/" then
                    parts[#parts + 1] = escaped
                elseif escaped == "b" then
                    parts[#parts + 1] = "\b"
                elseif escaped == "f" then
                    parts[#parts + 1] = "\f"
                elseif escaped == "n" then
                    parts[#parts + 1] = "\n"
                elseif escaped == "r" then
                    parts[#parts + 1] = "\r"
                elseif escaped == "t" then
                    parts[#parts + 1] = "\t"
                elseif escaped == "u" then
                    local hex = self.text:sub(self.index, self.index + 3)
                    self.index = self.index + 4
                    local code = tonumber(hex, 16)
                    if not code then
                        error("invalid unicode escape")
                    end
                    if utf8 and utf8.char then
                        parts[#parts + 1] = utf8.char(code)
                    else
                        parts[#parts + 1] = "?"
                    end
                else
                    error("invalid escape")
                end
            else
                parts[#parts + 1] = char
            end
        end
    end

    function parser:parse_number()
        local start = self.index
        while self:peek():match("[%d%+%-%.eE]") do
            self.index = self.index + 1
        end
        local value = tonumber(self.text:sub(start, self.index - 1))
        if value == nil then
            error("invalid number")
        end
        return value
    end

    function parser:consume_literal(literal, value)
        if self.text:sub(self.index, self.index + #literal - 1) ~= literal then
            error("expected " .. literal)
        end
        self.index = self.index + #literal
        return value
    end

    function parser:parse_array()
        self:next()
        local result = {}
        self:skip_ws()
        if self:peek() == "]" then
            self:next()
            return result
        end
        while true do
            result[#result + 1] = self:parse_value()
            self:skip_ws()
            local char = self:next()
            if char == "]" then
                return result
            elseif char ~= "," then
                error("expected comma or array end")
            end
        end
    end

    function parser:parse_object()
        self:next()
        local result = {}
        self:skip_ws()
        if self:peek() == "}" then
            self:next()
            return result
        end
        while true do
            self:skip_ws()
            local key = self:parse_string()
            self:skip_ws()
            if self:next() ~= ":" then
                error("expected colon")
            end
            result[key] = self:parse_value()
            self:skip_ws()
            local char = self:next()
            if char == "}" then
                return result
            elseif char ~= "," then
                error("expected comma or object end")
            end
        end
    end

    function parser:parse_value()
        self:skip_ws()
        local char = self:peek()
        if char == '"' then
            return self:parse_string()
        elseif char == "{" then
            return self:parse_object()
        elseif char == "[" then
            return self:parse_array()
        elseif char == "t" then
            return self:consume_literal("true", true)
        elseif char == "f" then
            return self:consume_literal("false", false)
        elseif char == "n" then
            return self:consume_literal("null", nil)
        elseif char:match("[%-%d]") then
            return self:parse_number()
        end
        error("unexpected json value")
    end

    return parser
end

function json.decode(text)
    local parser = new_parser(text)
    local value = parser:parse_value()
    parser:skip_ws()
    if parser.index <= #text then
        error("trailing json data")
    end
    return value
end

return json
