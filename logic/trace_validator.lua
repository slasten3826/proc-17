local topology = require("core.topology")

local trace_validator = {}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function glyph_chars(text)
    local chars = {}
    for _, code in utf8.codes(tostring(text or "")) do
        local ch = utf8.char(code)
        if topology.is_operator(ch) then
            chars[#chars + 1] = ch
        end
    end
    return chars
end

local function trace_text(trace)
    return table.concat(trace or "")
end

local function copy_array(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = value
    end
    return result
end

local function has_validity_claim(line)
    local lowered = tostring(line or ""):lower()
    return lowered:find("validity", 1, true) ~= nil
        or lowered:find("valid:", 1, true) ~= nil
        or lowered:find("invalid:", 1, true) ~= nil
        or lowered:find("i believe", 1, true) ~= nil
        or lowered:find("believe it is valid", 1, true) ~= nil
        or lowered:find("first transition to check", 1, true) ~= nil
        or lowered:find("adjacency reasoning", 1, true) ~= nil
end

local function make_candidate(id, raw_line, trace)
    return {
        kind = "trace_candidate",
        channel = "trace_channel",
        id = id,
        raw_line = raw_line,
        trace = copy_array(trace),
        trace_text = trace_text(trace),
        truth_status = "semantic_proposal",
    }
end

function trace_validator.extract(text, options)
    options = options or {}
    local candidates = {}
    local ignored_validity_claims = {}

    for line in (tostring(text or "") .. "\n"):gmatch("([^\n]*)\n") do
        local raw_line = trim(line)
        if raw_line ~= "" then
            if has_validity_claim(raw_line) then
                ignored_validity_claims[#ignored_validity_claims + 1] = raw_line
            end

            local id, glyph_part = raw_line:match("^[Tt][Rr][Aa][Cc][Ee]%s+([^:]+):%s*(.+)$")
            if id and glyph_part then
                local trace = glyph_chars(glyph_part)
                candidates[#candidates + 1] = make_candidate(trim(id), raw_line, trace)
            end
        end
    end

    if options.include_ignored_validity_claims then
        return candidates, ignored_validity_claims
    end
    return candidates
end

local function invalid_result(candidate, reason, invalid_at, invalid_transition)
    return {
        kind = "trace_validation_result",
        channel = "runtime_channel",
        id = candidate.id,
        raw_line = candidate.raw_line,
        trace = copy_array(candidate.trace),
        trace_text = candidate.trace_text or trace_text(candidate.trace),
        valid = false,
        invalid_at = invalid_at,
        invalid_transition = invalid_transition,
        residue = reason,
        validator_source = "local_body_topology",
        truth_status = "runtime_confirmed",
    }
end

function trace_validator.validate_trace(trace_channel, options)
    options = options or {}
    local candidate = trace_channel or {}
    local trace = candidate.trace or {}

    if #trace < 2 then
        return invalid_result(candidate, "trace requires at least two operators", nil, nil)
    end

    for index, glyph in ipairs(trace) do
        if not topology.is_operator(glyph) then
            return invalid_result(candidate, "unknown operator glyph", index, tostring(glyph))
        end
    end

    local ok, err = topology.validate_trace(trace)
    if not ok then
        local transition = tostring(err.left) .. tostring(err.right)
        return invalid_result(candidate, err.message or "invalid operator transition", err.index, transition)
    end

    return {
        kind = "trace_validation_result",
        channel = "runtime_channel",
        id = candidate.id,
        raw_line = candidate.raw_line,
        trace = copy_array(trace),
        trace_text = candidate.trace_text or trace_text(trace),
        valid = true,
        invalid_at = nil,
        invalid_transition = nil,
        residue = nil,
        validator_source = "local_body_topology",
        truth_status = "runtime_confirmed",
    }
end

function trace_validator.validate_text(text, options)
    options = options or {}
    local candidates, ignored = trace_validator.extract(text, {include_ignored_validity_claims = true})
    local valid = {}
    local invalid = {}

    for _, candidate in ipairs(candidates) do
        local result = trace_validator.validate_trace(candidate, options)
        if result.valid then
            valid[#valid + 1] = result
        else
            invalid[#invalid + 1] = result
        end
    end

    local residue
    if #candidates == 0 then
        residue = "no trace candidates"
    elseif #valid == 0 then
        residue = "all trace candidates invalid"
    end

    return {
        kind = "trace_validation_payload",
        candidates = candidates,
        valid = valid,
        invalid = invalid,
        ignored_validity_claims = ignored,
        residue = residue,
        truth_status = "runtime_confirmed",
    }
end

function trace_validator.feedback(result)
    if type(result) ~= "table" or result.valid == true then
        return nil
    end
    if result.invalid_at and result.invalid_transition then
        return string.format(
            "TRACE %s invalid at index %s: %s. Generate another TRACE line. Do not explain validity.",
            tostring(result.id or "?"),
            tostring(result.invalid_at),
            tostring(result.invalid_transition)
        )
    end
    return string.format(
        "TRACE %s invalid: %s. Generate another TRACE line. Do not explain validity.",
        tostring(result.id or "?"),
        tostring(result.residue or "invalid trace")
    )
end

return trace_validator
