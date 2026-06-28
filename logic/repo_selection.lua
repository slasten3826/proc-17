local sandbox = require("core.sandbox")

local repo_selection = {}

local default_limits = {
    max_paths = 8,
}

local function listed_entries(listing)
    if type(listing) ~= "table" or type(listing.entries) ~= "table" then
        return nil, "listing.entries is required"
    end
    return listing.entries
end

function repo_selection.build_index(listing)
    local entries, err = listed_entries(listing)
    if not entries then
        return nil, err
    end

    local index = {}
    for _, entry in ipairs(entries) do
        if type(entry.path) == "string" and entry.path ~= "" then
            index[entry.path] = {
                path = entry.path,
                kind = entry.kind,
                truth_status = entry.truth_status,
            }
        end
    end
    return index
end

local function sorted_paths(index)
    local paths = {}
    for path in pairs(index) do
        paths[#paths + 1] = path
    end
    table.sort(paths, function(left, right)
        if #left == #right then
            return left < right
        end
        return #left > #right
    end)
    return paths
end

local function is_path_char(char)
    return char and char:match("[%w%._%-/]") ~= nil
end

local function looks_like_path(token)
    if token:find("/", 1, true) then
        return true
    end
    if token:match("^[%w%._%-]+%.[%a][%w]*$") then
        return true
    end
    return false
end

local function contains_path(text, path)
    if not looks_like_path(path) then
        return false
    end

    local start_at = 1
    while true do
        local from, to = text:find(path, start_at, true)
        if not from then
            return false
        end
        local before = from > 1 and text:sub(from - 1, from - 1) or nil
        local after = to < #text and text:sub(to + 1, to + 1) or nil
        if not is_path_char(before) and not is_path_char(after) then
            return true
        end
        start_at = to + 1
    end
end

local function add_candidate(candidates, seen, path, kind, source, text)
    if path == "" or seen[path] then
        return
    end
    seen[path] = true
    candidates[#candidates + 1] = {
        path = path,
        kind = kind,
        source = source,
        reason = {
            text = text,
            truth_status = "semantic_proposal",
        },
    }
end

local function clean_token(token)
    local cleaned = tostring(token or "")
    cleaned = cleaned:match("^%s*(.-)%s*$")
    cleaned = cleaned:gsub("^[%*%-%d%.%s]+", "")
    cleaned = cleaned:gsub("[%.,:;%)%]}]+$", "")
    cleaned = cleaned:gsub("^[%(%[%{]+", "")
    return cleaned
end

function repo_selection.extract_paths(text, listing, options)
    options = options or {}
    text = tostring(text or "")

    local index, err = repo_selection.build_index(listing)
    if not index then
        return nil, err
    end

    local found = {}
    local seen = {}
    for _, path in ipairs(sorted_paths(index)) do
        if contains_path(text, path) then
            add_candidate(found, seen, path, index[path].kind, "listed_exact_text_match", text)
        end
    end

    for token in text:gmatch("`([^`]+)`") do
        local trimmed = clean_token(token)
        if looks_like_path(trimmed) then
            add_candidate(found, seen, trimmed, index[trimmed] and index[trimmed].kind, "backtick_path_token", text)
        end
    end

    for token in text:gmatch("%*%*([^%*]+)%*%*") do
        local trimmed = clean_token(token)
        if looks_like_path(trimmed) then
            add_candidate(found, seen, trimmed, index[trimmed] and index[trimmed].kind, "bold_path_token", text)
        end
    end

    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        local candidate = line:match("^%s*[%-%*]?%s*`?([%w%._%-/]+)`?%s*[%-%—:]")
            or line:match("^%s*%d+%.%s*`?([%w%._%-/]+)`?%s*[%-%—:]")
        if candidate then
            local trimmed = clean_token(candidate)
            if looks_like_path(trimmed) then
                add_candidate(found, seen, trimmed, index[trimmed] and index[trimmed].kind, "line_leading_path", text)
            end
        end
    end

    return found
end

local function reject(path, reason)
    return {
        path = path,
        reason = reason,
        truth_status = "rejected",
    }
end

function repo_selection.validate(input)
    input = input or {}
    local listing = input.listing
    local text = input.text or ""
    local max_paths = input.max_paths or default_limits.max_paths
    local allow_directories = input.allow_directories == true

    if type(max_paths) ~= "number" or max_paths < 1 then
        return nil, "max_paths must be positive number"
    end

    local index, index_err = repo_selection.build_index(listing)
    if not index then
        return nil, index_err
    end

    local candidates, extract_err = repo_selection.extract_paths(text, listing, input)
    if not candidates then
        return nil, extract_err
    end

    local accepted = {}
    local rejected = {}
    local reasons = {}
    local seen = {}

    for _, candidate in ipairs(candidates) do
        local path = candidate.path
        local entry = index[path]
        if seen[path] then
            -- Duplicate paths are ignored after the first validation decision.
        elseif not entry then
            rejected[#rejected + 1] = reject(path, "absent_from_listing")
            seen[path] = true
        else
            local path_ok, path_reason = sandbox.check_path(path)
            if not path_ok then
                rejected[#rejected + 1] = reject(path, path_reason)
            elseif entry.kind == "directory" and not allow_directories then
                rejected[#rejected + 1] = reject(path, "directory_not_allowed")
            elseif #accepted >= max_paths then
                rejected[#rejected + 1] = reject(path, "max_paths_exceeded")
            else
                accepted[#accepted + 1] = {
                    path = path,
                    kind = entry.kind,
                    truth_status = "runtime_confirmed",
                }
                reasons[#reasons + 1] = {
                    path = path,
                    text = candidate.reason and candidate.reason.text or text,
                    truth_status = "semantic_proposal",
                }
            end
            seen[path] = true
        end
    end

    return {
        kind = "repo_selection_payload",
        accepted_paths = accepted,
        rejected_paths = rejected,
        reasons = reasons,
        unparsed_text = text,
        limits = {
            max_paths = max_paths,
            allow_directories = allow_directories,
        },
        truth_status = "runtime_confirmed",
    }
end

return repo_selection
