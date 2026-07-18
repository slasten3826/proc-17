local coverage = {
    protocol_version = "object-version-coverage.v0",
}

local function copy_value(value, seen)
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
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function validate_entries(entries)
    if type(entries) ~= "table" then
        return nil, "coverage entries must be table"
    end
    local seen = {}
    for _, entry in ipairs(entries) do
        if type(entry) ~= "table" or entry.object_kind ~= "field_unit"
            or type(entry.object_id) ~= "string" or entry.object_id == ""
            or type(entry.version) ~= "number" or entry.version < 1
            or entry.version ~= math.floor(entry.version)
            or type(entry.source_ref) ~= "string" or entry.source_ref == "" then
            return nil, "invalid object coverage entry"
        end
        if seen[entry.object_id] then
            return nil, "duplicate object coverage id"
        end
        seen[entry.object_id] = true
    end
    return true
end

function coverage.validate(record)
    if type(record) ~= "table" or record.protocol_version ~= coverage.protocol_version
        or (record.domain ~= "relation" and record.domain ~= "upper_observation")
        or type(record.policy_id) ~= "string" or record.policy_id == ""
        or type(record.entries) ~= "table"
        or type(record.total_count) ~= "number" or record.total_count < 0
        or type(record.stored_count) ~= "number" or record.stored_count < 0
        or type(record.omitted_count) ~= "number" or record.omitted_count < 0
        or type(record.truncated) ~= "boolean"
        or type(record.global_revision_at_capture) ~= "number"
        or record.event_truth_status ~= "runtime_confirmed" then
        return nil, "invalid object coverage record"
    end
    local entries_ok, entries_err = validate_entries(record.entries)
    if not entries_ok then
        return nil, entries_err
    end
    if record.stored_count ~= #record.entries
        or record.total_count ~= record.stored_count + record.omitted_count
        or record.truncated ~= (record.omitted_count > 0) then
        return nil, "inconsistent object coverage bounds"
    end
    return true
end

function coverage.capture(entries, options)
    options = options or {}
    local entries_ok, entries_err = validate_entries(entries)
    if not entries_ok then
        return nil, entries_err
    end
    local domain = options.domain
    if domain ~= "relation" and domain ~= "upper_observation" then
        return nil, "invalid object coverage domain"
    end
    if type(options.policy_id) ~= "string" or options.policy_id == "" then
        return nil, "object coverage policy_id required"
    end
    local total_count = options.total_count or #entries
    if type(total_count) ~= "number" or total_count < #entries
        or total_count ~= math.floor(total_count) then
        return nil, "invalid object coverage total_count"
    end
    if type(options.global_revision) ~= "number" then
        return nil, "object coverage global revision required"
    end

    return {
        protocol_version = coverage.protocol_version,
        domain = domain,
        policy_id = options.policy_id,
        entries = copy_value(entries),
        total_count = total_count,
        stored_count = #entries,
        omitted_count = total_count - #entries,
        truncated = total_count > #entries,
        global_revision_at_capture = options.global_revision,
        capture_event_ref = options.capture_event_ref,
        event_truth_status = "runtime_confirmed",
    }
end

local function exact_ref(entry)
    return table.concat({
        "coverage",
        entry.object_kind,
        entry.object_id,
        tostring(entry.version),
    }, ":")
end

function coverage.diff(record, current_entries, options)
    options = options or {}
    local entries_ok, entries_err = validate_entries(current_entries)
    if not entries_ok then
        return nil, entries_err
    end
    if record ~= nil then
        local record_ok, record_err = coverage.validate(record)
        if not record_ok then
            return nil, record_err
        end
    end

    local covered = {}
    local current = {}
    for _, entry in ipairs(record and record.entries or {}) do
        covered[entry.object_id] = entry
    end
    for _, entry in ipairs(current_entries) do
        current[entry.object_id] = entry
    end

    local policy_changed = record ~= nil and options.policy_id ~= nil
        and record.policy_id ~= options.policy_id
    local missing = {}
    local stale = {}
    local departed = {}
    local source_refs = {}
    for _, entry in ipairs(current_entries) do
        local prior = not policy_changed and covered[entry.object_id] or nil
        if not prior then
            missing[#missing + 1] = {
                object_id = entry.object_id,
                current_version = entry.version,
            }
            source_refs[#source_refs + 1] = exact_ref(entry)
        elseif prior.version ~= entry.version then
            stale[#stale + 1] = {
                object_id = entry.object_id,
                covered_version = prior.version,
                current_version = entry.version,
            }
            source_refs[#source_refs + 1] = exact_ref(entry)
        end
    end
    for _, entry in ipairs(record and record.entries or {}) do
        if not current[entry.object_id] then
            departed[#departed + 1] = {
                object_id = entry.object_id,
                covered_version = entry.version,
                current_activation = nil,
            }
        end
    end

    local omitted = (record and record.omitted_count or 0)
        + (options.current_omitted_count or 0)
    if omitted > 0 then
        source_refs[#source_refs + 1] = "coverage:truncated:" .. tostring(omitted)
    end
    local changed_count = #missing + #stale + omitted
    if options.departed_is_change == true then
        changed_count = changed_count + #departed
    end

    return {
        kind = "object_version_delta",
        domain = options.domain or (record and record.domain),
        policy_id = options.policy_id or (record and record.policy_id),
        policy_changed = policy_changed,
        missing = missing,
        stale = stale,
        departed = departed,
        uncovered_by_truncation = omitted,
        changed_count = changed_count,
        source_refs = source_refs,
        event_truth_status = "runtime_confirmed",
    }
end

function coverage.source_refs(delta)
    return copy_value(delta and delta.source_refs or {})
end

function coverage.same_delta(left, right)
    if type(left) ~= "table" or type(right) ~= "table"
        or left.domain ~= right.domain or left.changed_count ~= right.changed_count
        or #left.source_refs ~= #right.source_refs then
        return false
    end
    for index, ref in ipairs(left.source_refs) do
        if right.source_refs[index] ~= ref then
            return false
        end
    end
    return true
end

return coverage
