local modes = {}

modes.allowed = {
    chaos = true,
    table = true,
    crystall = true,
    manifest = true,
}

modes.permissions = {
    chaos = {
        layer = "docs/00_chaos",
        code_writes = false,
        hallucination = "tolerate_raw_pressure",
    },
    table = {
        layer = "docs/01_table",
        code_writes = false,
        hallucination = "tag_unsupported_unknown",
    },
    crystall = {
        layer = "docs/02_crystall",
        code_writes = false,
        hallucination = "strict_validation",
    },
    manifest = {
        layer = "implementation",
        code_writes = true,
        hallucination = "runtime_truth_required",
    },
}

function modes.is_valid(mode)
    return modes.allowed[mode] == true
end

function modes.default()
    return "manifest"
end

function modes.can_write_code(mode)
    local permissions = modes.permissions[mode]
    return permissions and permissions.code_writes == true
end

function modes.describe(mode)
    return modes.permissions[mode]
end

local function starts_with(value, prefix)
    return value:sub(1, #prefix) == prefix
end

function modes.can_write_path(mode, path)
    if not modes.is_valid(mode) then
        return false, "invalid mode"
    end
    if type(path) ~= "string" or path == "" then
        return false, "path is required"
    end

    if mode == "chaos" then
        return starts_with(path, "docs/00_chaos/"), "chaos may write only docs/00_chaos"
    elseif mode == "table" then
        return starts_with(path, "docs/01_table/"), "table may write only docs/01_table"
    elseif mode == "crystall" then
        return starts_with(path, "docs/02_crystall/"), "crystall may write only docs/02_crystall"
    elseif mode == "manifest" then
        return true, "manifest may write implementation, tests, and manifest docs"
    end

    return false, "unhandled mode"
end

return modes
