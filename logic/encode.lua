local encode = {}

local DEFAULT_MAX_ITEMS = 128

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function normalize_limits(limits)
    limits = limits or {}
    if type(limits) ~= "table" then
        return nil, "invalid_limits"
    end

    local max_items = limits.max_items or DEFAULT_MAX_ITEMS
    if type(max_items) ~= "number" or max_items < 1 then
        return nil, "invalid_limits"
    end

    return {
        max_items = math.floor(max_items),
    }
end

local function clone_array(source)
    local result = {}
    if type(source) ~= "table" then
        return result
    end
    for index, value in ipairs(source) do
        result[index] = value
    end
    return result
end

local function source_ref(kind, value)
    return kind .. ":" .. tostring(value)
end

local function connection(from_ref, to_ref, relation_kind, source_truth_status)
    return {
        from = from_ref,
        to = to_ref,
        relation_kind = relation_kind,
        source_truth_status = source_truth_status or "unknown",
        relation_truth_status = "runtime_confirmed",
        pressure = "source_binding",
        evidence = {
            kind = "encode_source_relation",
        },
    }
end

local function field_truth(items)
    if #items == 0 then
        return "unknown"
    end

    local first = items[1].content_truth_status
    for _, item in ipairs(items) do
        if item.content_truth_status ~= first then
            return "mixed"
        end
    end
    return first or "unknown"
end

local function append_item(state, item)
    if #state.items >= state.limits.max_items then
        state.omitted_count = state.omitted_count + 1
        state.truncated = true
        return
    end
    state.items[#state.items + 1] = item
end

local function append_connection(state, record)
    state.connections[#state.connections + 1] = record
end

local function response_lines(text)
    local items = {}
    local seen = {}
    for line in (tostring(text or "") .. "\n"):gmatch("([^\n]*)\n") do
        local value = trim(line)
        value = value:gsub("^%s*[%-%*]%s*", "")
        value = value:gsub("^%s*%d+[%.)]%s*", "")
        value = trim(value)
        if value ~= "" and not seen[value] then
            seen[value] = true
            items[#items + 1] = value
        end
    end
    return items
end

local function encode_repo_listing(state, payload)
    if type(payload) ~= "table" or type(payload.entries) ~= "table" then
        return false
    end

    local encoded_any = false
    for _, entry in ipairs(payload.entries) do
        if entry.kind == "file" then
            encoded_any = true
            state.input_count = state.input_count + 1
            local ref = source_ref("repo_listing_entry", entry.path)
            local item = {
                id = entry.path,
                kind = "repo_path",
                value = entry.path,
                truth_status = entry.truth_status or "runtime_confirmed",
                source_kind = "repo_listing_entry",
                source_ref = ref,
                source_truth_status = entry.truth_status or "runtime_confirmed",
                content_truth_status = entry.truth_status or "runtime_confirmed",
                encoding_truth_status = "runtime_confirmed",
                connections = {ref},
            }
            append_item(state, item)
            append_connection(state, connection(ref, item.id, "repo_path_to_listing", item.source_truth_status))
        end
    end
    return encoded_any
end

local function encode_substrate_result(state, response)
    if type(response) ~= "table" or type(response.text) ~= "string" then
        return false
    end

    local lines = response_lines(response.text)
    for index, value in ipairs(lines) do
        state.input_count = state.input_count + 1
        local id = "line:" .. tostring(index)
        local ref = source_ref("substrate_response_line", id)
        local item = {
            id = id,
            kind = "semantic_line",
            value = value,
            truth_status = "semantic_proposal",
            source_kind = "substrate_response_line",
            source_ref = ref,
            source_truth_status = "semantic_proposal",
            content_truth_status = "semantic_proposal",
            encoding_truth_status = "runtime_confirmed",
            connections = {ref},
        }
        append_item(state, item)
        append_connection(state, connection(ref, id, "result_line_to_candidate", "semantic_proposal"))
    end
    return #lines > 0
end

local function encode_repo_context(state, payload)
    if type(payload) ~= "table" or type(payload.files) ~= "table" then
        return false
    end

    local encoded_any = false
    for _, file in ipairs(payload.files) do
        encoded_any = true
        state.input_count = state.input_count + 1
        local path = file.path or file.file or tostring(#state.items + 1)
        local ref = source_ref("repo_context_block", path)
        local item = {
            id = "context:" .. path,
            kind = "context_block",
            value = path,
            truth_status = file.truth_status or payload.truth_status or "runtime_confirmed",
            source_kind = "repo_context_block",
            source_ref = ref,
            source_truth_status = file.truth_status or payload.truth_status or "runtime_confirmed",
            content_truth_status = file.truth_status or payload.truth_status or "runtime_confirmed",
            encoding_truth_status = "runtime_confirmed",
            connections = {ref},
        }
        append_item(state, item)
        append_connection(state, connection(ref, item.id, "context_to_path", item.source_truth_status))
    end
    return encoded_any
end

local function validate_connections(records)
    if records == nil then
        return true
    end
    if type(records) ~= "table" then
        return false
    end
    for _, record in ipairs(records) do
        if type(record) ~= "table" or record.from == nil or record.to == nil then
            return false
        end
    end
    return true
end

local function validate_dissolved(records)
    if records == nil then
        return true
    end
    if type(records) ~= "table" then
        return false
    end
    for _, record in ipairs(records) do
        if type(record) ~= "table" or record.target == nil or record.new_status == nil then
            return false
        end
    end
    return true
end

local function carry_dissolved_records(state, records)
    if type(records) ~= "table" then
        return
    end
    for index, record in ipairs(records) do
        state.input_count = state.input_count + 1
        local id = "dissolved:" .. tostring(index)
        local ref = source_ref("dissolved_record", id)
        append_item(state, {
            id = id,
            kind = "dissolved_residue",
            value = record.residue or record.target,
            truth_status = record.new_status or "unsupported_residue",
            source_kind = "dissolved_record",
            source_ref = ref,
            source_truth_status = record.new_status or "unsupported_residue",
            content_truth_status = record.new_status or "unsupported_residue",
            encoding_truth_status = "runtime_confirmed",
            connections = {ref},
        })
        append_connection(state, connection(ref, id, "unsupported_to_origin", record.new_status or "unsupported_residue"))
    end
end

function encode.response_line_items(text)
    local items = {}
    for index, value in ipairs(response_lines(text)) do
        items[#items + 1] = {
            id = "line:" .. tostring(index),
            kind = "semantic_line",
            value = value,
            truth_status = "semantic_proposal",
        }
    end
    return items
end

function encode.encode(input)
    input = input or {}
    local limits, limits_err = normalize_limits(input.limits)
    if not limits then
        return nil, limits_err
    end
    if not validate_connections(input.connections) then
        return nil, "invalid_connection"
    end
    if not validate_dissolved(input.dissolved_records) then
        return nil, "invalid_dissolved_record"
    end

    local state = {
        limits = limits,
        items = {},
        connections = clone_array(input.connections),
        input_count = 0,
        omitted_count = 0,
        truncated = false,
        basis = {},
    }

    local used_repo_listing = encode_repo_listing(state, input.repo_listing)
    if used_repo_listing then
        state.basis[#state.basis + 1] = "repo_listing"
    else
        local used_substrate = encode_substrate_result(state, input.substrate_result)
        if used_substrate then
            state.basis[#state.basis + 1] = "substrate_result"
        end
    end

    if encode_repo_context(state, input.repo_context) then
        state.basis[#state.basis + 1] = "repo_context"
    end

    carry_dissolved_records(state, input.dissolved_records)
    if type(input.dissolved_records) == "table" and #input.dissolved_records > 0 then
        state.basis[#state.basis + 1] = "dissolved_records"
    end

    if #state.items == 0 then
        return nil, "empty_sources"
    end

    local truth = field_truth(state.items)
    return {
        kind = "encoded_field_payload",
        field = {
            truth_status = truth,
            items = state.items,
        },
        connections = state.connections,
        source_mix = state.basis,
        encoding_basis = {
            order = state.basis,
            rule = "repo_listing_else_substrate_lines_plus_context_and_residue",
        },
        hierarchy = {
            root = "field",
            item_count = #state.items,
            connection_count = #state.connections,
        },
        loss = {
            kind = used_repo_listing and "source_projection" or "field_compression",
            input_count = state.input_count,
            output_count = #state.items,
            omitted_count = state.omitted_count,
            source_detail_loss = state.omitted_count > 0,
            hierarchy_loss = false,
            truncated = state.truncated,
        },
        limits = limits,
        truth_status = "runtime_confirmed",
    }
end

return encode
