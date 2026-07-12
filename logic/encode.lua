local encode = {}

local DEFAULT_MAX_ITEMS = 128

local LOSS_BY_ENCODING = {
    hierarchy = 0.30,
    sequence = 0.25,
    category = 0.40,
    teaching = 0.60,
    language = 0.50,
}

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
        state.loss_log[#state.loss_log + 1] = {
            kind = "omitted_item",
            source_kind = item.source_kind or "unknown",
            source_ref = item.source_ref or item.id or "unknown",
            item_id = item.id or ("omitted:" .. tostring(state.omitted_count)),
            reason = "max_items",
            content_preview = tostring(item.content or item.value or item.label or ""):sub(1, 160),
            truth_status = item.content_truth_status or item.truth_status or "unknown",
        }
        return
    end
    state.items[#state.items + 1] = item
end

local function append_connection(state, record)
    state.connections[#state.connections + 1] = record
end

local function loss_level(loss)
    if loss < 0.15 then
        return "minimal"
    end
    if loss < 0.45 then
        return "moderate"
    end
    if loss < 0.75 then
        return "severe"
    end
    return "total"
end

local function item_content(item)
    return item.content or item.value or item.label or item.id
end

local function item_refs(item)
    if type(item.source_refs) == "table" then
        return clone_array(item.source_refs)
    end
    if item.source_ref ~= nil then
        return {item.source_ref}
    end
    return {}
end

local function enrich_items(items)
    for index, item in ipairs(items) do
        item.label = item.label or tostring(item.value or item.id or index)
        item.content = item.content or item.value or item.label
        item.source_refs = item_refs(item)
        item.potential = item.potential or 1.0
        item.status = item.status or "pending"
    end
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

local function is_section_header(value)
    value = trim(value)
    if value == "" then
        return false
    end
    if value:sub(-1) ~= ":" then
        return false
    end
    local label = value:sub(1, -2)
    if label:match("^%d+%s+[%a_][%w_%s%-]+$") then
        return true
    end
    if label:match("^[%a_][%w_%s%-]+$") then
        return true
    end
    return false
end

local function section_value(value)
    value = trim(value)
    if value:sub(-1) == ":" then
        return trim(value:sub(1, -2))
    end
    return value
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
                role = "alternative",
                order = state.input_count,
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

    state.raw_text = response.text
    local lines = response_lines(response.text)
    local has_sections = false
    for _, value in ipairs(lines) do
        if is_section_header(value) then
            has_sections = true
            break
        end
    end
    local current_section_id
    local section_count = 0
    for index, value in ipairs(lines) do
        state.input_count = state.input_count + 1
        local id = "line:" .. tostring(index)
        local ref = source_ref("substrate_response_line", id)
        local kind = "semantic_line"
        local role = "alternative"
        local parent_id
        local item_value = value
        if has_sections and is_section_header(value) then
            section_count = section_count + 1
            id = "section:" .. tostring(section_count)
            current_section_id = id
            kind = "section"
            role = "container"
            item_value = section_value(value)
        elseif has_sections then
            kind = "section_child"
            role = "alternative"
            parent_id = current_section_id
        end
        local item = {
            id = id,
            kind = kind,
            value = item_value,
            role = role,
            parent_id = parent_id,
            order = index,
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
    if has_sections then
        state.detected_shape = "structured_reflection_field"
        state.detected_intent = "preserve_reflection"
    end
    return #lines > 0
end

local function raw_has_order(text)
    text = tostring(text or "")
    if text:match("\n%s*%d+[%.)]%s+") or text:match("^%s*%d+[%.)]%s+") then
        return true
    end
    local lowered = text:lower()
    return lowered:find("step", 1, true) ~= nil
        or lowered:find("todo", 1, true) ~= nil
        or lowered:find("phase", 1, true) ~= nil
        or lowered:find("stage", 1, true) ~= nil
        or lowered:find("next", 1, true) ~= nil
        or lowered:find("before", 1, true) ~= nil
        or lowered:find("after", 1, true) ~= nil
        or lowered:find("then", 1, true) ~= nil
end

local function raw_has_categories(text)
    local lowered = tostring(text or ""):lower()
    return lowered:find("option", 1, true) ~= nil
        or lowered:find("alternative", 1, true) ~= nil
        or lowered:find("category", 1, true) ~= nil
        or lowered:find("bucket", 1, true) ~= nil
        or lowered:find("allowed", 1, true) ~= nil
        or lowered:find("denied", 1, true) ~= nil
        or lowered:find(" vs ", 1, true) ~= nil
end

local function raw_has_teaching(text)
    local lowered = tostring(text or ""):lower()
    return lowered:find("rule", 1, true) ~= nil
        or lowered:find("warning", 1, true) ~= nil
        or lowered:find("explain", 1, true) ~= nil
        or lowered:find("because", 1, true) ~= nil
        or lowered:find("why", 1, true) ~= nil
        or lowered:find("must", 1, true) ~= nil
end

local function select_encoding_type(state, shape, used_repo_listing)
    if used_repo_listing or shape == "repo_path_field" then
        return "hierarchy"
    end
    if shape == "residue_field" then
        return "category"
    end
    if raw_has_order(state.raw_text) then
        return "sequence"
    end
    if raw_has_categories(state.raw_text) then
        return "category"
    end
    if shape == "structured_reflection_field" or raw_has_teaching(state.raw_text) then
        return "teaching"
    end
    return "language"
end

local function empty_structure(kind)
    return {
        kind = kind,
        entry = nil,
        root = nil,
        exit = nil,
        nodes = {},
        edges = {},
        levels = {},
        steps = {},
        categories = {},
        unknowns = {},
    }
end

local function build_hierarchy(items)
    local structure = empty_structure("hierarchy")
    structure.root = "field"
    structure.nodes[#structure.nodes + 1] = {id = "field", kind = "root", label = "field"}
    structure.levels[1] = {"field"}
    structure.levels[2] = {}
    for _, item in ipairs(items) do
        structure.nodes[#structure.nodes + 1] = {id = item.id, kind = item.kind, label = item.label}
        structure.levels[2][#structure.levels[2] + 1] = item.id
        structure.edges[#structure.edges + 1] = {from = item.parent_id or "field", to = item.id, relation = "contains"}
    end
    return structure
end

local function build_sequence(items)
    local structure = empty_structure("sequence")
    structure.entry = items[1] and items[1].id or nil
    structure.exit = items[#items] and items[#items].id or nil
    for index, item in ipairs(items) do
        structure.steps[#structure.steps + 1] = {id = item.id, order = index, label = item.label}
        if index > 1 then
            structure.edges[#structure.edges + 1] = {from = items[index - 1].id, to = item.id, relation = "next"}
        end
    end
    return structure
end

local function build_category(items)
    local structure = empty_structure("category")
    local by_kind = {}
    for _, item in ipairs(items) do
        local category = item.kind or "unknown"
        if not by_kind[category] then
            by_kind[category] = {id = category, label = category, members = {}}
            structure.categories[#structure.categories + 1] = by_kind[category]
        end
        by_kind[category].members[#by_kind[category].members + 1] = item.id
    end
    return structure
end

local function build_teaching(items)
    local structure = empty_structure("teaching")
    structure.claims = {}
    structure.rules = {}
    structure.examples = {}
    structure.warnings = {}
    structure.residue = {}
    for _, item in ipairs(items) do
        local target = structure.claims
        local text = tostring(item_content(item)):lower()
        if text:find("must", 1, true) or text:find("rule", 1, true) then
            target = structure.rules
        elseif text:find("warning", 1, true) or text:find("risk", 1, true) then
            target = structure.warnings
        elseif text:find("example", 1, true) then
            target = structure.examples
        elseif item.role == "residue" then
            target = structure.residue
        end
        target[#target + 1] = item.id
    end
    return structure
end

local function build_language(items)
    local structure = empty_structure("language")
    structure.utterances = {}
    structure.claims = {}
    structure.possible_actions = {}
    structure.residue = {}
    for _, item in ipairs(items) do
        structure.utterances[#structure.utterances + 1] = item.id
        local text = tostring(item_content(item)):lower()
        if text:find("do ", 1, true) or text:find("implement", 1, true) or text:find("create", 1, true) then
            structure.possible_actions[#structure.possible_actions + 1] = item.id
        elseif item.role == "residue" then
            structure.residue[#structure.residue + 1] = item.id
        else
            structure.claims[#structure.claims + 1] = item.id
        end
    end
    return structure
end

local function build_structure(kind, items)
    if kind == "hierarchy" then
        return build_hierarchy(items)
    end
    if kind == "sequence" then
        return build_sequence(items)
    end
    if kind == "category" then
        return build_category(items)
    end
    if kind == "teaching" then
        return build_teaching(items)
    end
    return build_language(items)
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
            role = "evidence",
            order = state.input_count,
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
            role = "residue",
            order = state.input_count,
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
        detected_shape = nil,
        detected_intent = nil,
        loss_log = {},
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
    local shape = state.detected_shape
    local intent = state.detected_intent
    if not shape then
        if used_repo_listing then
            shape = "repo_path_field"
            intent = "select_focus"
        elseif type(input.dissolved_records) == "table" and #input.dissolved_records > 0 and #state.basis == 1 then
            shape = "residue_field"
            intent = "carry_residue"
        elseif #state.basis > 1 then
            shape = "mixed_context_field"
            intent = "choose_next_context"
        else
            shape = "semantic_line_field"
            intent = "rank_candidates"
        end
    end
    enrich_items(state.items)
    local encoding_type = select_encoding_type(state, shape, used_repo_listing)
    local encoding_loss = LOSS_BY_ENCODING[encoding_type] or LOSS_BY_ENCODING.language
    local structure = build_structure(encoding_type, state.items)
    local encoding_metadata = {
        encoding_type = encoding_type,
        loss_percentage = encoding_loss,
        loss_level = loss_level(encoding_loss),
        creates_hierarchy = encoding_type == "hierarchy" or encoding_type == "teaching",
        creates_sequence = encoding_type == "sequence" or encoding_type == "teaching",
        reversible = encoding_loss < 0.35,
        hierarchy_lens_visible = encoding_type == "hierarchy",
        source_refs = {},
        loss_log = clone_array(state.loss_log),
    }
    local seen_refs = {}
    for _, item in ipairs(state.items) do
        for _, ref in ipairs(item.source_refs or {}) do
            if not seen_refs[ref] then
                seen_refs[ref] = true
                encoding_metadata.source_refs[#encoding_metadata.source_refs + 1] = ref
            end
        end
    end

    return {
        kind = "encoded_field_payload",
        field = {
            shape = shape,
            intent = intent,
            truth_status = truth,
            items = state.items,
            structure = structure,
            encoding = encoding_metadata,
            loss_log = clone_array(state.loss_log),
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
            structure_kind = structure.kind,
        },
        loss = {
            kind = used_repo_listing and "source_projection" or "field_compression",
            input_count = state.input_count,
            output_count = #state.items,
            omitted_count = state.omitted_count,
            source_detail_loss = state.omitted_count > 0,
            hierarchy_loss = encoding_type == "hierarchy" and not encoding_metadata.hierarchy_lens_visible,
            truncated = state.truncated,
            encoding_type = encoding_type,
            loss_percentage = encoding_loss,
            loss_level = encoding_metadata.loss_level,
            loss_log = clone_array(state.loss_log),
        },
        limits = limits,
        truth_status = "runtime_confirmed",
    }
end

return encode
