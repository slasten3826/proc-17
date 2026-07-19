local json = require("core.json")
local field = require("runtime.field")
local upper_coverage = require("runtime.upper_coverage")

local inspection = {
    protocol_version = "structure.inspection.v0",
    proposal_protocol = "packet.structure.proposal.v0",
    adapter_policy_id = "encode.packet_structure.v0",
    receiver_contract_id = "calm.work_structure.v0",
    formation_protocol = "field.structure_formation.v0",
    choice_consumer_id = "calm.singular_focus.v0",
    choice_policy_id = "formation_order.v0",
}

local accepted_shapes = {
    work_sequence = true,
    work_hierarchy = true,
    alternative_set = true,
    artifact_set = true,
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

local function same_value(left, right)
    return json.encode(left) == json.encode(right)
end

local function validate_keys(value, allowed, name)
    if type(value) ~= "table" then
        return nil, name .. " must be table"
    end
    for key in pairs(value) do
        if not allowed[key] then
            return nil, name .. " contains unknown key: " .. tostring(key)
        end
    end
    return true
end

local function exact_ref(id, version)
    return table.concat({"coverage", "field_unit", id, tostring(version)}, ":")
end

local function positive_integer(value, fallback, name)
    value = value == nil and fallback or value
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, name .. " must be a positive integer"
    end
    return value
end

local function normalize_string_array(value, name)
    if value == nil then
        return {}
    end
    if type(value) ~= "table" then
        return nil, name .. " must be table"
    end
    local result = {}
    local seen = {}
    for index, item in ipairs(value) do
        if type(item) ~= "string" or item == "" then
            return nil, name .. " must contain non-empty strings"
        end
        if seen[item] then
            return nil, name .. " must not contain duplicates"
        end
        if value[index] ~= item then
            return nil, name .. " must be an array"
        end
        seen[item] = true
        result[#result + 1] = item
    end
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key > #result
            or key ~= math.floor(key) then
            return nil, name .. " must be an array"
        end
    end
    return result
end

local function normalize_json_value(value, depth, seen)
    depth = depth or 0
    if depth > 32 then
        return nil, "proposal value exceeds maximum depth"
    end
    local kind = type(value)
    if kind == "string" or kind == "boolean" then
        return value
    end
    if kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return nil, "proposal value contains non-finite number"
        end
        return value
    end
    if kind ~= "table" then
        return nil, "proposal value is not JSON-compatible"
    end
    seen = seen or {}
    if seen[value] then
        return nil, "proposal value contains cycle"
    end
    seen[value] = true

    local count = 0
    local max_index = 0
    local numeric = true
    for key in pairs(value) do
        count = count + 1
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            numeric = false
        elseif key > max_index then
            max_index = key
        end
    end
    local array = numeric and max_index == count
    local result = {}
    if array then
        for index = 1, max_index do
            local child, child_err = normalize_json_value(
                value[index],
                depth + 1,
                seen
            )
            if child == nil then
                seen[value] = nil
                return nil, child_err
            end
            result[index] = child
        end
    else
        for key, raw in pairs(value) do
            if type(key) ~= "string" or key == "" then
                seen[value] = nil
                return nil, "proposal object keys must be non-empty strings"
            end
            local child, child_err = normalize_json_value(raw, depth + 1, seen)
            if child == nil then
                seen[value] = nil
                return nil, child_err
            end
            result[key] = child
        end
    end
    seen[value] = nil
    return result
end

local function proposal_value(carrier)
    if type(carrier) ~= "table" then
        return nil, "structure proposal carrier must be table"
    end
    if carrier.protocol_version ~= nil then
        return carrier
    end
    if type(carrier.structured) == "table" then
        return carrier.structured
    end
    if type(carrier.text) ~= "string" or carrier.text == "" then
        return nil, "structure proposal carrier has no strict envelope"
    end
    local ok, decoded = pcall(json.decode, carrier.text)
    if not ok or type(decoded) ~= "table" then
        return nil, "structure proposal text is not strict JSON"
    end
    return decoded
end

local function normalize_item(value)
    local valid, valid_err = validate_keys(value, {
        key = true,
        kind = true,
        value = true,
        source_keys = true,
    }, "structure proposal item")
    if not valid then
        return nil, valid_err
    end
    if type(value.key) ~= "string" or value.key == ""
        or type(value.kind) ~= "string" or value.kind == ""
        or value.value == nil then
        return nil, "structure proposal item requires key, kind, and value"
    end
    local normalized_value, value_err = normalize_json_value(value.value)
    if normalized_value == nil then
        return nil, value_err
    end
    local source_keys, source_err = normalize_string_array(
        value.source_keys,
        "structure proposal source_keys"
    )
    if not source_keys then
        return nil, source_err
    end
    return {
        key = value.key,
        kind = value.kind,
        value = normalized_value,
        source_keys = source_keys,
    }
end

local function normalize_edge(value, item_keys)
    local valid, valid_err = validate_keys(value, {
        from_key = true,
        to_key = true,
        relation = true,
    }, "structure proposal edge")
    if not valid then
        return nil, valid_err
    end
    if type(value.from_key) ~= "string" or value.from_key == ""
        or type(value.to_key) ~= "string" or value.to_key == ""
        or type(value.relation) ~= "string" or value.relation == "" then
        return nil, "structure proposal edge requires from_key, to_key, and relation"
    end
    if not item_keys[value.from_key] or not item_keys[value.to_key] then
        return nil, "structure proposal edge endpoint is unknown"
    end
    return {
        from_key = value.from_key,
        to_key = value.to_key,
        relation = value.relation,
    }
end

function inspection.normalize(value)
    local valid, valid_err = validate_keys(value, {
        protocol_version = true,
        receiver_contract_id = true,
        shape = true,
        items = true,
        edges = true,
        choice = true,
    }, "structure proposal")
    if not valid then
        return nil, valid_err
    end
    if value.protocol_version ~= inspection.proposal_protocol then
        return nil, "unsupported structure proposal protocol"
    end
    if type(value.receiver_contract_id) ~= "string"
        or value.receiver_contract_id == "" then
        return nil, "structure proposal receiver contract is required"
    end
    if not accepted_shapes[value.shape] then
        return nil, "unsupported structure proposal shape"
    end
    if type(value.items) ~= "table" or #value.items == 0 then
        return nil, "structure proposal items must be non-empty"
    end

    local items = {}
    local item_keys = {}
    for _, raw_item in ipairs(value.items) do
        local item, item_err = normalize_item(raw_item)
        if not item then
            return nil, item_err
        end
        if item_keys[item.key] then
            return nil, "structure proposal item keys must be unique"
        end
        item_keys[item.key] = true
        items[#items + 1] = item
    end
    for key in pairs(value.items) do
        if type(key) ~= "number" or key < 1 or key > #items
            or key ~= math.floor(key) then
            return nil, "structure proposal items must be an array"
        end
    end

    local edges = {}
    if value.edges ~= nil then
        if type(value.edges) ~= "table" then
            return nil, "structure proposal edges must be table"
        end
        for _, raw_edge in ipairs(value.edges) do
            local edge, edge_err = normalize_edge(raw_edge, item_keys)
            if not edge then
                return nil, edge_err
            end
            edges[#edges + 1] = edge
        end
        for key in pairs(value.edges) do
            if type(key) ~= "number" or key < 1 or key > #edges
                or key ~= math.floor(key) then
                return nil, "structure proposal edges must be an array"
            end
        end
    end

    local choice
    if value.choice ~= nil then
        local choice_valid, choice_err = validate_keys(value.choice, {
            kind = true,
        }, "structure proposal choice")
        if not choice_valid then
            return nil, choice_err
        end
        if value.choice.kind ~= "mutually_exclusive" then
            return nil, "unsupported structure proposal choice kind"
        end
        choice = {kind = "mutually_exclusive"}
    end
    if value.shape == "alternative_set" and choice == nil then
        return nil, "alternative_set requires mutually_exclusive choice metadata"
    end
    if value.shape ~= "alternative_set" and choice ~= nil then
        return nil, "choice metadata requires alternative_set shape"
    end

    return {
        protocol_version = inspection.proposal_protocol,
        receiver_contract_id = value.receiver_contract_id,
        shape = value.shape,
        items = items,
        edges = edges,
        choice = choice,
    }
end

function inspection.from_unit(unit)
    if type(unit) ~= "table" or unit.kind ~= "substrate_response" then
        return nil, "structure proposal requires substrate_response unit"
    end
    local value, value_err = proposal_value(unit.carrier)
    if not value then
        return nil, value_err
    end
    local envelope, envelope_err = inspection.normalize(value)
    if not envelope then
        return nil, envelope_err
    end
    return envelope, "structure-proposal:" .. json.encode(envelope)
end

local function regime(instance)
    local encoding = instance.regime and instance.regime.encoding or {}
    local bounds = encoding.bounds or {}
    local max_source_units, source_err = positive_integer(
        bounds.max_source_units,
        1,
        "encoding max_source_units"
    )
    if not max_source_units then
        return nil, source_err
    end
    local max_output_units, output_err = positive_integer(
        bounds.max_output_units,
        128,
        "encoding max_output_units"
    )
    if not max_output_units then
        return nil, output_err
    end
    local max_loss_log_entries, loss_err = positive_integer(
        bounds.max_loss_log_entries,
        32,
        "encoding max_loss_log_entries"
    )
    if not max_loss_log_entries then
        return nil, loss_err
    end
    return {
        policy_id = encoding.policy_id,
        receiver_contract_id = encoding.receiver_contract_id,
        bounds = {
            max_source_units = max_source_units,
            max_output_units = max_output_units,
            max_loss_log_entries = max_loss_log_entries,
        },
    }
end

local function semantic_coverage(instance)
    local view, view_err = upper_coverage.derive(instance)
    if not view then
        return nil, view_err
    end
    local result = {}
    for _, entry in ipairs(view.entries or {}) do
        if entry.observation_class == "semantic" then
            result[entry.object_id] = entry
        end
    end
    return result, view
end

local function event_by_id(instance, id)
    for _, event in ipairs(instance.trace or {}) do
        if event.id == id then
            return event
        end
    end
    return nil
end

local function identity_map_by_id(instance, id)
    for _, record in ipairs(instance.field and instance.field.identity_maps or {}) do
        if record.id == id then
            return record
        end
    end
    return nil
end

local function loss_record_by_ref(instance, ref)
    for _, record in ipairs(instance.boundary and instance.boundary.loss_records or {}) do
        if record.trace_event_id == ref then
            return record
        end
    end
    return nil
end

local function matching_formation(instance, candidate)
    for index = #(instance.trace or {}), 1, -1 do
        local event = instance.trace[index]
        local payload = event.type == "structure_formation" and event.payload or nil
        local source = type(payload) == "table" and payload.source or nil
        if type(source) == "table"
            and source.unit_id == candidate.source_unit_id
            and source.version == candidate.source_version
            and payload.receiver_contract_id == candidate.receiver_contract_id
            and payload.requested_shape == candidate.requested_shape
            and payload.envelope_fingerprint == candidate.envelope_fingerprint then
            return event
        end
    end
    return nil
end

local function verify_formation(instance, event, candidate)
    local payload = event and event.payload or nil
    local source = type(payload) == "table" and payload.source or nil
    if type(payload) ~= "table"
        or payload.protocol_version ~= inspection.formation_protocol
        or event.operator ~= "☵"
        or event.truth_status ~= "runtime_confirmed"
        or type(source) ~= "table"
        or source.unit_id ~= candidate.source_unit_id
        or source.version ~= candidate.source_version
        or source.observation_event_ref ~= candidate.source_observation_event_ref
        or source.content_truth_status ~= candidate.source_content_truth_status
        or payload.receiver_contract_id ~= candidate.receiver_contract_id
        or payload.requested_shape ~= candidate.requested_shape
        or payload.envelope_fingerprint ~= candidate.envelope_fingerprint
        or payload.event_truth_status ~= "runtime_confirmed"
        or payload.content_truth_status ~= candidate.source_content_truth_status
        or type(payload.formed_unit_ids) ~= "table"
        or #payload.formed_unit_ids == 0
        or type(payload.formed_unit_versions) ~= "table"
        or type(payload.identity_map_ref) ~= "string"
        or type(payload.identity_map_event_ref) ~= "string"
        or type(payload.crystallization_event_ref) ~= "string"
        or type(payload.loss_record_ref) ~= "string" then
        return nil, "malformed_structure_formation"
    end
    local identity_map = identity_map_by_id(instance, payload.identity_map_ref)
    if not identity_map or identity_map.shadow_only == true
        or identity_map.trace_event_id ~= payload.identity_map_event_ref
        or identity_map.encode_event_id ~= payload.crystallization_event_ref
        or identity_map.mapping_kind ~= "packet_structure"
        or identity_map.source_versions[candidate.source_unit_id] ~= candidate.source_version
        or identity_map.receiver_contract_id ~= candidate.receiver_contract_id
        or identity_map.requested_shape ~= candidate.requested_shape
        or identity_map.envelope_fingerprint ~= candidate.envelope_fingerprint
        or #identity_map.old_ids ~= 1
        or identity_map.old_ids[1] ~= candidate.source_unit_id then
        return nil, "malformed_structure_formation"
    end
    local mapped = identity_map.mapping[candidate.source_unit_id]
    if type(mapped) ~= "table" or #mapped ~= #payload.formed_unit_ids then
        return nil, "malformed_structure_formation"
    end
    if not same_value(identity_map.new_ids, payload.formed_unit_ids) then
        return nil, "malformed_structure_formation"
    end
    local formed_seen = {}
    local version_count = 0
    for id in pairs(payload.formed_unit_versions) do
        version_count = version_count + 1
        if type(id) ~= "string" or id == "" then
            return nil, "malformed_structure_formation"
        end
    end
    if version_count ~= #payload.formed_unit_ids then
        return nil, "malformed_structure_formation"
    end
    for index, id in ipairs(payload.formed_unit_ids) do
        if formed_seen[id] then
            return nil, "malformed_structure_formation"
        end
        formed_seen[id] = true
        if mapped[index] ~= id or payload.formed_unit_versions[id] ~= 1 then
            return nil, "malformed_structure_formation"
        end
        local unit = field.get_unit(instance, id)
        if not unit or unit.created_by ~= "☵"
            or unit.created_event_id ~= payload.crystallization_event_ref
            or unit.activation == "dissolved" then
            return nil, "formation_repair_pressure"
        end
    end
    local source_unit = field.get_unit(instance, candidate.source_unit_id)
    if not source_unit or source_unit.version ~= candidate.source_version
        or source_unit.content_truth_status ~= candidate.source_content_truth_status then
        return nil, "malformed_structure_formation"
    end
    local observation = event_by_id(instance, candidate.source_observation_event_ref)
    local covered = false
    for _, entry in ipairs(observation and observation.payload
        and observation.payload.read_units and observation.payload.read_units.entries or {}) do
        if entry.object_id == candidate.source_unit_id
            and entry.version == candidate.source_version then
            covered = true
            break
        end
    end
    if not observation or observation.type ~= "observation" or not covered then
        return nil, "malformed_structure_formation"
    end
    local crystallization = event_by_id(instance, payload.crystallization_event_ref)
    local loss_record = loss_record_by_ref(instance, payload.loss_record_ref)
    if not crystallization or crystallization.type ~= "crystallization"
        or not loss_record
        or payload.loss_record_ref ~= payload.crystallization_event_ref
        or not same_value(loss_record.loss, crystallization.payload.loss) then
        return nil, "malformed_structure_formation"
    end
    local choice = payload.choice_contract
    if choice ~= nil then
        if candidate.requested_shape ~= "alternative_set"
            or choice.consumer_contract_id ~= inspection.choice_consumer_id
            or choice.selection_policy_id ~= inspection.choice_policy_id
            or choice.max_selected ~= 1
            or choice.selection_basis_truth_status ~= candidate.source_content_truth_status
            or not same_value(choice.ordered_alternative_ids, payload.formed_unit_ids) then
            return nil, "malformed_structure_formation"
        end
    elseif candidate.requested_shape == "alternative_set" then
        local choice_regime = instance.regime and instance.regime.choice or {}
        if choice_regime.consumer_contract_id == inspection.choice_consumer_id
            and choice_regime.policy_id == inspection.choice_policy_id then
            return nil, "malformed_structure_formation"
        end
    end
    return true, identity_map
end

local function diagnostic(kind, unit, reason)
    return {
        kind = kind,
        object_id = unit and unit.id,
        version = unit and unit.version,
        reason = reason,
        scope_refs = unit and {exact_ref(unit.id, unit.version)} or {},
        provenance_refs = unit and {unit.created_event_id} or {},
        event_truth_status = "runtime_confirmed",
    }
end

function inspection.derive(instance, options)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    options = options or {}
    local configured, regime_err = regime(instance)
    if not configured then
        return nil, regime_err
    end
    local coverage, coverage_view = semantic_coverage(instance)
    if not coverage then
        return nil, coverage_view
    end
    local source_view = field.view(instance, {
        created_by = "☴",
        activation = {live = true, selected = true},
        generation = instance.generation,
        limit = options.max_scan_units or 256,
    }) or {units = {}, truncated = false}

    local candidates = {}
    local missing = {}
    local current = {}
    local diagnostics = {}
    for _, unit in ipairs(source_view.units or {}) do
        if unit.kind == "substrate_response" then
            local envelope, fingerprint_or_err = inspection.from_unit(unit)
            if not envelope then
                diagnostics[#diagnostics + 1] = diagnostic(
                    "unsupported_structure_proposal",
                    unit,
                    fingerprint_or_err
                )
            elseif configured.policy_id ~= inspection.adapter_policy_id
                or configured.receiver_contract_id ~= inspection.receiver_contract_id
                or envelope.receiver_contract_id ~= configured.receiver_contract_id then
                diagnostics[#diagnostics + 1] = diagnostic(
                    "receiver_not_enabled",
                    unit,
                    "structure proposal receiver or adapter is not enabled"
                )
            else
                local covered = coverage[unit.id]
                if not covered or covered.version ~= unit.version then
                    diagnostics[#diagnostics + 1] = diagnostic(
                        "source_semantic_observation_missing",
                        unit,
                        "source version lacks semantic observation coverage"
                    )
                else
                    local candidate = {
                        source_unit_id = unit.id,
                        source_version = unit.version,
                        source_creation_event_ref = unit.created_event_id,
                        source_observation_event_ref = covered.observation_event_ref,
                        source_content_truth_status = unit.content_truth_status,
                        exact_ref = exact_ref(unit.id, unit.version),
                        envelope = envelope,
                        envelope_fingerprint = fingerprint_or_err,
                        receiver_contract_id = envelope.receiver_contract_id,
                        requested_shape = envelope.shape,
                        bounds = copy_value(configured.bounds),
                    }
                    local formation = matching_formation(instance, candidate)
                    if formation then
                        local valid, formation_err = verify_formation(
                            instance,
                            formation,
                            candidate
                        )
                        candidate.formation_event_ref = formation.id
                        if valid then
                            candidate.formation_status = "current"
                            current[#current + 1] = candidate
                        else
                            candidate.formation_status = "repair"
                            diagnostics[#diagnostics + 1] = diagnostic(
                                formation_err,
                                unit,
                                formation_err
                            )
                        end
                    else
                        candidate.formation_status = "missing"
                        missing[#missing + 1] = candidate
                    end
                    candidates[#candidates + 1] = candidate
                end
            end
        end
    end
    if source_view.truncated then
        diagnostics[#diagnostics + 1] = {
            kind = "incomplete_structure_scope",
            reason = "structure source scan truncated",
            scope_refs = {},
            provenance_refs = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    table.sort(candidates, function(left, right)
        return left.exact_ref < right.exact_ref
    end)
    table.sort(missing, function(left, right)
        return left.exact_ref < right.exact_ref
    end)
    table.sort(current, function(left, right)
        return left.exact_ref < right.exact_ref
    end)

    return {
        protocol_version = inspection.protocol_version,
        candidates = copy_value(candidates),
        missing = copy_value(missing),
        current = copy_value(current),
        diagnostics = copy_value(diagnostics),
        source_count = source_view.total_count or #source_view.units,
        truncated = source_view.truncated == true or coverage_view.truncated == true,
        qualification_status = (source_view.truncated or coverage_view.truncated)
            and "incomplete_scope" or "qualified",
        event_truth_status = "runtime_confirmed",
    }
end

function inspection.resolve(instance, input)
    if type(input) ~= "table" then
        return nil, "structure_input required"
    end
    local result, result_err = inspection.derive(instance)
    if not result then
        return nil, result_err
    end
    for _, candidate in ipairs(result.missing) do
        if candidate.source_unit_id == input.source_unit_id
            and candidate.source_version == input.source_version then
            if candidate.envelope_fingerprint ~= input.envelope_fingerprint
                or candidate.receiver_contract_id ~= input.receiver_contract_id
                or candidate.requested_shape ~= input.requested_shape
                or input.adapter_policy_id ~= inspection.adapter_policy_id
                or type(input.bounds) ~= "table"
                or input.bounds.max_output_units ~= candidate.bounds.max_output_units
                or input.bounds.max_loss_log_entries ~= candidate.bounds.max_loss_log_entries then
                return nil, "structure_input does not match current candidate"
            end
            return copy_value(candidate)
        end
    end
    for _, candidate in ipairs(result.current) do
        if candidate.source_unit_id == input.source_unit_id
            and candidate.source_version == input.source_version then
            return nil, "structure already formed"
        end
    end
    for _, item in ipairs(result.diagnostics) do
        if item.object_id == input.source_unit_id then
            return nil, item.kind .. ":" .. tostring(item.reason)
        end
    end
    return nil, "structure source is not a current missing candidate"
end

function inspection.verify_effect(instance, plan, payload)
    if type(instance) ~= "table" then
        return nil, "structure formation effect requires packet instance"
    end
    local structure_input = plan and plan.options and plan.options.encode
        and plan.options.encode.structure_input
    local formation_payload = type(payload) == "table" and payload.structure_formation or nil
    if type(structure_input) ~= "table"
        or payload.mode ~= "structure_formation"
        or payload.formation_basis ~= "packet_structure"
        or type(formation_payload) ~= "table"
        or type(payload.formation_event_id) ~= "string"
        or type(payload.trace_event_id) ~= "string"
        or type(payload.identity_map) ~= "table"
        or type(payload.loss) ~= "table"
        or type(payload.work_units) ~= "table"
        or payload.truth_status ~= "runtime_confirmed" then
        return nil, "malformed structure formation effect"
    end

    local event = event_by_id(instance, payload.formation_event_id)
    if not event or event.type ~= "structure_formation"
        or not same_value(event.payload, formation_payload) then
        return nil, "structure formation effect event mismatch"
    end
    local candidate = {
        source_unit_id = structure_input.source_unit_id,
        source_version = structure_input.source_version,
        source_observation_event_ref = formation_payload.source
            and formation_payload.source.observation_event_ref,
        source_content_truth_status = payload.content_truth_status,
        receiver_contract_id = structure_input.receiver_contract_id,
        requested_shape = structure_input.requested_shape,
        envelope_fingerprint = structure_input.envelope_fingerprint,
    }
    local valid, identity_or_err = verify_formation(instance, event, candidate)
    if not valid then
        return nil, identity_or_err
    end
    local identity_map = identity_or_err
    if payload.trace_event_id ~= formation_payload.crystallization_event_ref
        or payload.identity_map.id ~= identity_map.id
        or payload.identity_map.trace_event_id ~= identity_map.trace_event_id
        or not same_value(payload.loss, event_by_id(
            instance,
            formation_payload.crystallization_event_ref
        ).payload.loss) then
        return nil, "structure formation linked effect mismatch"
    end
    if #payload.work_units ~= #formation_payload.formed_unit_ids then
        return nil, "structure formation work unit count mismatch"
    end
    for index, unit_id in ipairs(formation_payload.formed_unit_ids) do
        local work = payload.work_units[index]
        if type(work) ~= "table" or work.id ~= unit_id then
            return nil, "structure formation work unit order mismatch"
        end
    end
    return true
end

inspection.accepted_shapes = copy_value(accepted_shapes)
inspection.exact_ref = exact_ref

return inspection
