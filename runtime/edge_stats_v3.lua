local authority_epoch = require("runtime.authority_epoch")
local digest = require("core.digest")
local edge_catalog = require("runtime.edge_catalog")
local edge_credit = require("runtime.edge_credit")
local json = require("core.json")
local topology = require("core.topology")

local stats = {
    protocol_version = "edge-stats.v3",
    source_protocol_version = "edge-source-evidence.v0",
    error_protocol_version = "authority-instrument-error.v0",
}

local source_kinds = {
    packet_trace = true,
    runner_tick = true,
    runner_effect = true,
    policy_evidence = true,
    edge_credit = true,
    observer = true,
}

local error_classes = {
    configuration = true,
    identity = true,
    ledger = true,
    bounds = true,
    merge = true,
    corpus = true,
}

local route_authorities = {
    legacy_control = true,
    tree = true,
    harness_override = true,
}

local corpus_layers = {
    L0 = true,
    L1 = true,
    unit = true,
    archaeology = true,
}

local default_bounds = {
    kind = "authority_instrument_bounds",
    protocol_version = "authority-instrument-bounds.v0",
    calibration_status = "unmeasured_safety_control",
    max_source_records = 4096,
    max_single_source_bytes = 2 * 1024 * 1024,
    max_source_bytes_per_life = 32 * 1024 * 1024,
    max_projection_bytes = 16 * 1024 * 1024,
    max_error_records = 256,
}

local observer_authorities = {
    tree = "legacy_control",
    legacy = "tree",
}

local rail_channel_definitions = {
    tree_shadow = {
        id = "tree_shadow",
        evidence_role = "counterfactual_prediction",
        observer = "tree",
        observed_authority = "legacy_control",
        authority = "none",
        target_kind = "predicted_to",
    },
    tree_authority = {
        id = "tree_authority",
        evidence_role = "authoritative_derivation",
        authority = "tree",
        target_kind = "selected_to",
    },
}

local rail_definitions = {
    {
        id = "rail.encode_observe",
        from = "☵",
        eye = "☴",
        debt_kind = "upper_observation_debt",
    },
    {
        id = "rail.choose_observe",
        from = "☳",
        eye = "☴",
        debt_kind = "upper_observation_debt",
    },
    {
        id = "rail.cycle_runtime",
        from = "☲",
        eye = "☱",
        debt_kind = "runtime_reconciliation_debt",
    },
    {
        id = "rail.logic_runtime",
        from = "☶",
        eye = "☱",
        debt_kind = "runtime_reconciliation_debt",
    },
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

local function replace_contents(target, source)
    for key in pairs(target) do
        target[key] = nil
    end
    for key, value in pairs(source) do
        target[key] = copy_value(value)
    end
end

local function same_value(left, right)
    local left_ok, left_encoded = pcall(json.encode, left)
    local right_ok, right_encoded = pcall(json.encode, right)
    return left_ok and right_ok and left_encoded == right_encoded
end

local function exact_keys(value, allowed, optional)
    if type(value) ~= "table" then
        return false
    end
    optional = optional or {}
    for key in pairs(value) do
        if not allowed[key] then
            return false
        end
    end
    for key in pairs(allowed) do
        if value[key] == nil and not optional[key] then
            return false
        end
    end
    return true
end

local function non_empty(value)
    return type(value) == "string" and value ~= ""
end

local function non_negative_integer(value)
    return type(value) == "number"
        and value >= 0
        and value % 1 == 0
        and value < math.huge
end

local function positive_integer(value)
    return non_negative_integer(value) and value > 0
end

local function finite_number(value)
    return type(value) == "number"
        and value == value
        and value > -math.huge
        and value < math.huge
end

local function tagged_hash(value)
    return type(value) == "string"
        and #value == 71
        and value:sub(1, 7) == "sha256:"
        and value:sub(8):match("^[0-9a-f]+$") ~= nil
end

local function tagged_digest(seed)
    local value, err = digest.record(seed)
    if not value then
        return nil, err
    end
    return "sha256:" .. value
end

local function normalized_strings(values)
    local seen = {}
    local result = {}
    for _, value in ipairs(values or {}) do
        if non_empty(value) and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function strict_sorted_strings(values)
    if type(values) ~= "table" then
        return false
    end
    local previous
    for index, value in ipairs(values) do
        if not non_empty(value) or (previous and value <= previous) then
            return false
        end
        previous = value
        if index ~= math.floor(index) then
            return false
        end
    end
    for key in pairs(values) do
        if type(key) ~= "number" or key < 1 or key > #values
            or key % 1 ~= 0 then
            return false
        end
    end
    return true
end

local function append_unique(values, value)
    if not non_empty(value) then
        return
    end
    for _, existing in ipairs(values) do
        if existing == value then
            return
        end
    end
    values[#values + 1] = value
    table.sort(values)
end

local function increment(map, key)
    key = non_empty(key) and key or "unknown"
    map[key] = (map[key] or 0) + 1
end

local function sum_map(map)
    local result = 0
    for key, value in pairs(map or {}) do
        if not non_empty(key) or not non_negative_integer(value) then
            return nil
        end
        result = result + value
    end
    return result
end

local function looks_live(value)
    if value.protocol_version == "packet.next.v1"
        and value.status ~= nil and value.trace ~= nil then
        return true
    end
    if value.protocol_version == "repository.capability_registry.v0"
        or value.protocol_version == "qa.capability_registry.v0"
        or value.protocol_version == "repository.capability_grant.v0" then
        return true
    end
    return false
end

local function validate_plain(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "string" then
        return true
    end
    if kind == "number" then
        return finite_number(value)
    end
    if kind ~= "table" or getmetatable(value) ~= nil then
        return false
    end
    seen = seen or {}
    if seen[value] or looks_live(value) then
        return false
    end
    seen[value] = true

    local numeric = false
    local textual = false
    local max_index = 0
    local count = 0
    for key, child in pairs(value) do
        if type(key) == "number" then
            if not positive_integer(key) then
                return false
            end
            numeric = true
            if key > max_index then
                max_index = key
            end
        elseif type(key) == "string" then
            textual = true
        else
            return false
        end
        if numeric and textual then
            return false
        end
        count = count + 1
        if not validate_plain(child, seen) then
            return false
        end
    end
    if numeric and max_index ~= count then
        return false
    end
    return true
end

local function plain_encoding(value)
    if not validate_plain(value) then
        return nil
    end
    local ok, encoded = pcall(json.encode, value)
    if not ok then
        return nil
    end
    return encoded
end

local function instrument_error(class, code, stage, route_id, refs, message)
    if not error_classes[class] or not non_empty(code) or not non_empty(stage) then
        return nil
    end
    local record = {
        kind = "authority_instrument_error",
        protocol_version = stats.error_protocol_version,
        class = class,
        code = code,
        stage = stage,
        route_evidence_id = non_empty(route_id) and route_id or nil,
        source_refs = normalized_strings(refs),
        message = type(message) == "string" and message or code,
        event_truth_status = "runtime_confirmed",
    }
    local id, err = tagged_digest({
        kind = record.kind,
        protocol_version = record.protocol_version,
        class = record.class,
        code = record.code,
        stage = record.stage,
        route_evidence_id = record.route_evidence_id or "none",
        source_refs = record.source_refs,
        event_truth_status = record.event_truth_status,
    })
    if not id then
        return nil, err
    end
    record.error_id = id
    return record
end

local function invalid(code, path)
    return instrument_error("ledger", code, "edge_stats_v3.verify", nil,
        path and {path} or {}, code)
end

local function life_seed(record)
    return {
        protocol_version = stats.protocol_version,
        evidence_run_id = record.evidence_run_id or "diagnostic-unscoped",
        packet_id = record.packet_id,
        lineage_id = record.lineage_id,
        generation = record.generation,
        session_id = record.session_id or "none",
        case_id = record.case_id or "none",
        corpus_layer = record.corpus_layer or "diagnostic",
    }
end

local function verify_life_source(record)
    if not exact_keys(record, {
        kind = true,
        protocol_version = true,
        life_id = true,
        packet_id = true,
        lineage_id = true,
        generation = true,
        session_id = true,
        work_mode = true,
        case_id = true,
        corpus_layer = true,
        evidence_run_id = true,
        model = true,
        prompt_hash = true,
        event_truth_status = true,
    }, {
        session_id = true,
        case_id = true,
        corpus_layer = true,
        evidence_run_id = true,
        model = true,
        prompt_hash = true,
    }) or record.kind ~= "edge_evidence_life_source"
        or record.protocol_version ~= stats.protocol_version
        or not tagged_hash(record.life_id)
        or not non_empty(record.packet_id)
        or not non_empty(record.lineage_id)
        or not positive_integer(record.generation)
        or (record.work_mode ~= "plan" and record.work_mode ~= "build")
        or (record.session_id ~= nil and not non_empty(record.session_id))
        or (record.case_id ~= nil and not non_empty(record.case_id))
        or (record.corpus_layer ~= nil and not corpus_layers[record.corpus_layer])
        or (record.evidence_run_id ~= nil and not non_empty(record.evidence_run_id))
        or (record.model ~= nil and not non_empty(record.model))
        or (record.prompt_hash ~= nil and not tagged_hash(record.prompt_hash))
        or record.event_truth_status ~= "runtime_confirmed" then
        return nil, instrument_error("identity", "life_source_invalid",
            "edge_stats_v3.life_source")
    end
    local expected, expected_err = tagged_digest(life_seed(record))
    if not expected or record.life_id ~= expected then
        return nil, expected_err or instrument_error(
            "identity", "life_source_identity_mismatch",
            "edge_stats_v3.life_source"
        )
    end
    return true
end

function stats.make_life_source(fields)
    if type(fields) ~= "table" then
        return nil, instrument_error("identity", "life_source_required",
            "edge_stats_v3.life_source")
    end
    local record = {
        kind = "edge_evidence_life_source",
        protocol_version = stats.protocol_version,
        packet_id = fields.packet_id,
        lineage_id = fields.lineage_id,
        generation = fields.generation,
        session_id = fields.session_id,
        work_mode = fields.work_mode,
        case_id = fields.case_id,
        corpus_layer = fields.corpus_layer,
        evidence_run_id = fields.evidence_run_id,
        model = fields.model,
        prompt_hash = fields.prompt_hash,
        event_truth_status = "runtime_confirmed",
    }
    local id, id_err = tagged_digest(life_seed(record))
    if not id then
        return nil, id_err
    end
    record.life_id = id
    local ok, err = verify_life_source(record)
    if not ok then
        return nil, err
    end
    return copy_value(record)
end

local function new_observer(observer_id, observed_authority)
    return {
        observer = observer_id,
        observed_authority = observed_authority
            or observer_authorities[observer_id],
        evidence_role = "route_comparison",
        comparison_count = 0,
        agreement_count = 0,
        divergence_count = 0,
        no_prediction_count = 0,
        unavailable_count = 0,
        outcome_counts = {},
    }
end

local function new_rail_channel(definition)
    return {
        id = definition.id,
        evidence_role = definition.evidence_role,
        observer = definition.observer,
        observed_authority = definition.observed_authority,
        authority = definition.authority,
        target_kind = definition.target_kind,
        cases = 0,
        target_count = 0,
        reference_eye_count = 0,
        eye_debt_cases = 0,
        eye_target_count = 0,
        debt_eye_target_count = 0,
        fresh_eye_target_count = 0,
        debt_bypass_count = 0,
        fresh_direct_count = 0,
        no_target_count = 0,
    }
end

local function new_rail(definition)
    return {
        id = definition.id,
        from = definition.from,
        eye = definition.eye,
        debt_kind = definition.debt_kind,
        channels = {
            tree_shadow = new_rail_channel(rail_channel_definitions.tree_shadow),
            tree_authority = new_rail_channel(
                rail_channel_definitions.tree_authority
            ),
        },
        promotion_status = "insufficient_evidence",
    }
end

local function new_direction(direction, legal)
    return {
        direction = direction,
        legal = legal == true,
        physical = {
            candidate_count = 0,
            selected_count = 0,
            committed_count = 0,
            executed_count = 0,
            failed_count = 0,
            pending_at_host_ceiling_count = 0,
            derivation_refs = {},
            selected_refs = {},
            committed_refs = {},
            executed_refs = {},
            failure_refs = {},
            pending_refs = {},
            authority_counts = {},
            arrival_kinds = {},
            failure_kinds = {},
        },
        promotion = {
            eligible_selected_count = 0,
            eligible_committed_count = 0,
            eligible_executed_count = 0,
            ineligible_executed_count = 0,
            unclassified_executed_count = 0,
            eligible_derivation_refs = {},
            eligible_committed_refs = {},
            eligible_executed_refs = {},
            credit_decision_refs = {},
            rejected_reason_counts = {},
            rejected_route_refs = {},
        },
        physical_status = "untested",
        promotion_status = "unqualified",
    }
end

local function new_edge(definition)
    local legal_directions = {}
    local directions = {}
    for _, direction in ipairs(definition.directions) do
        legal_directions[direction] = true
        directions[direction] = new_direction(direction, true)
    end
    return {
        id = definition.id,
        edge = definition.edge,
        left = definition.left,
        right = definition.right,
        legal_directions = legal_directions,
        directions = directions,
        physical_executed_direction_count = 0,
        promotion_executed_direction_count = 0,
        required_direction_count = #definition.directions,
        physical_coverage = "untested",
        promotion_coverage = "unqualified",
    }
end

local function verify_bounds(bounds)
    if not exact_keys(bounds, {
        kind = true,
        protocol_version = true,
        calibration_status = true,
        max_source_records = true,
        max_single_source_bytes = true,
        max_source_bytes_per_life = true,
        max_projection_bytes = true,
        max_error_records = true,
    }) or bounds.kind ~= "authority_instrument_bounds"
        or bounds.protocol_version ~= "authority-instrument-bounds.v0"
        or bounds.calibration_status ~= "unmeasured_safety_control" then
        return false
    end
    for _, key in ipairs({
        "max_source_records",
        "max_single_source_bytes",
        "max_source_bytes_per_life",
        "max_projection_bytes",
        "max_error_records",
    }) do
        if not positive_integer(bounds[key]) then
            return false
        end
    end
    return true
end

local function error_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        class = record.class,
        code = record.code,
        stage = record.stage,
        route_evidence_id = record.route_evidence_id or "none",
        source_refs = copy_value(record.source_refs),
        event_truth_status = record.event_truth_status,
    }
end

local function verify_error(record)
    if not exact_keys(record, {
        kind = true,
        protocol_version = true,
        error_id = true,
        class = true,
        code = true,
        stage = true,
        route_evidence_id = true,
        source_refs = true,
        message = true,
        event_truth_status = true,
    }, {
        route_evidence_id = true,
    }) or record.kind ~= "authority_instrument_error"
        or record.protocol_version ~= stats.error_protocol_version
        or not tagged_hash(record.error_id)
        or not error_classes[record.class]
        or not non_empty(record.code)
        or not non_empty(record.stage)
        or (record.route_evidence_id ~= nil
            and not tagged_hash(record.route_evidence_id))
        or not strict_sorted_strings(record.source_refs)
        or type(record.message) ~= "string"
        or record.event_truth_status ~= "runtime_confirmed" then
        return false
    end
    local expected = tagged_digest(error_seed(record))
    return expected == record.error_id
end

local function normalize_error(value)
    if verify_error(value) then
        return copy_value(value)
    end
    if type(value) ~= "table" or not non_empty(value.code) then
        return instrument_error("ledger", "instrument_error_invalid",
            "edge_stats_v3.note_error")
    end
    local class = error_classes[value.class] and value.class or nil
    if not class then
        class = value.class == "instrument_contract"
            and "configuration" or "ledger"
    end
    return instrument_error(
        class,
        value.code,
        non_empty(value.stage) and value.stage or "edge_stats_v3",
        value.route_evidence_id,
        value.source_refs,
        value.message
    )
end

local function overflow_digest(previous, record)
    return tagged_digest({
        protocol_version = stats.error_protocol_version,
        previous_digest = previous or "none",
        omitted_error = error_seed(record),
    })
end

local function append_error_on(ledger, value)
    local record, normalize_err = normalize_error(value)
    if not record then
        return nil, normalize_err
    end
    ledger.ledger_status = "invalid"
    local ordinary_limit = math.max(
        ledger.instrument_bounds.max_error_records - 1,
        0
    )
    if #ledger.errors < ordinary_limit then
        ledger.errors[#ledger.errors + 1] = record
        return record
    end
    local previous = ledger.error_overflow
        and ledger.error_overflow.overflow_digest or nil
    local next_digest, digest_err = overflow_digest(previous, record)
    if not next_digest then
        return nil, digest_err
    end
    ledger.error_overflow = {
        kind = "authority_instrument_error_overflow",
        protocol_version = stats.error_protocol_version,
        overflow_count = (ledger.error_overflow
            and ledger.error_overflow.overflow_count or 0) + 1,
        overflow_digest = next_digest,
        event_truth_status = "runtime_confirmed",
    }
    return record
end

local function source_seed(record)
    return {
        protocol_version = stats.source_protocol_version,
        life_id = record.life_id,
        source_kind = record.source_kind,
        original_source_id = record.original_source_id,
        source_digest = record.source_digest,
    }
end

local function verify_source_record(record)
    if not exact_keys(record, {
        kind = true,
        protocol_version = true,
        evidence_ref = true,
        life_id = true,
        source_kind = true,
        original_source_id = true,
        source_digest = true,
        source_record = true,
        source_truth_status = true,
        event_truth_status = true,
    }, {
        source_truth_status = true,
    }) or record.kind ~= "edge_source_evidence"
        or record.protocol_version ~= stats.source_protocol_version
        or not tagged_hash(record.evidence_ref)
        or not tagged_hash(record.life_id)
        or not source_kinds[record.source_kind]
        or not non_empty(record.original_source_id)
        or not tagged_hash(record.source_digest)
        or (record.source_truth_status ~= nil
            and not non_empty(record.source_truth_status))
        or record.event_truth_status ~= "runtime_confirmed" then
        return nil
    end
    local encoded = plain_encoding(record.source_record)
    if not encoded then
        return nil
    end
    local source_digest = tagged_digest(record.source_record)
    local evidence_ref = tagged_digest(source_seed(record))
    if source_digest ~= record.source_digest
        or evidence_ref ~= record.evidence_ref then
        return nil
    end
    if record.source_kind == "edge_credit" then
        local credit_ok = edge_credit.verify_record(record.source_record)
        if not credit_ok then
            return nil
        end
    end
    return encoded
end

local function normalize_source_descriptor(value, life_id)
    if not exact_keys(value, {
        source_kind = true,
        original_source_id = true,
        source_record = true,
    }) or not source_kinds[value.source_kind]
        or not non_empty(value.original_source_id) then
        return nil, instrument_error("identity", "source_evidence_invalid",
            "edge_stats_v3.source_capture")
    end
    local encoded = plain_encoding(value.source_record)
    if not encoded then
        return nil, instrument_error("identity", "source_evidence_not_plain",
            "edge_stats_v3.source_capture", nil,
            {value.original_source_id})
    end
    if value.source_kind == "edge_credit" then
        local credit_ok = edge_credit.verify_record(value.source_record)
        if not credit_ok then
            return nil, instrument_error(
                "identity",
                "edge_credit_source_invalid",
                "edge_stats_v3.source_capture",
                value.source_record.route_evidence_id,
                {value.original_source_id}
            )
        end
    end
    local source_digest, digest_err = tagged_digest(value.source_record)
    if not source_digest then
        return nil, digest_err
    end
    return {
        life_id = life_id,
        source_kind = value.source_kind,
        original_source_id = value.original_source_id,
        source_record = copy_value(value.source_record),
        source_digest = source_digest,
        encoded_bytes = #encoded,
    }
end

local function source_key(record)
    return record.source_kind .. "\0" .. record.original_source_id
end

local function prepare_source_descriptors(bundle, life_id, automatic)
    if bundle ~= nil then
        if not exact_keys(bundle, {life_id = true, records = true})
            or bundle.life_id ~= life_id
            or type(bundle.records) ~= "table" then
            return nil, instrument_error("identity", "source_bundle_invalid",
                "edge_stats_v3.source_capture")
        end
        for key in pairs(bundle.records) do
            if type(key) ~= "number" or key < 1 or key > #bundle.records
                or key % 1 ~= 0 then
                return nil, instrument_error("identity", "source_bundle_invalid",
                    "edge_stats_v3.source_capture")
            end
        end
    end

    local combined = {}
    for _, descriptor in ipairs(automatic or {}) do
        combined[#combined + 1] = descriptor
    end
    for _, descriptor in ipairs(bundle and bundle.records or {}) do
        combined[#combined + 1] = descriptor
    end

    local unique = {}
    for _, descriptor in ipairs(combined) do
        local normalized, normalize_err = normalize_source_descriptor(
            descriptor,
            life_id
        )
        if not normalized then
            return nil, normalize_err
        end
        local key = source_key(normalized)
        local existing = unique[key]
        if existing and existing.source_digest ~= normalized.source_digest then
            return nil, instrument_error(
                "identity",
                "source_evidence_conflict",
                "edge_stats_v3.source_capture",
                nil,
                {normalized.original_source_id}
            )
        end
        unique[key] = existing or normalized
    end

    local ordered = {}
    for _, descriptor in pairs(unique) do
        ordered[#ordered + 1] = descriptor
    end
    table.sort(ordered, function(left, right)
        if left.source_kind == right.source_kind then
            return left.original_source_id < right.original_source_id
        end
        return left.source_kind < right.source_kind
    end)
    return ordered
end

local function source_index_slot(ledger, life_id, kind)
    ledger.source_index[life_id] = ledger.source_index[life_id] or {}
    ledger.source_index[life_id][kind] = ledger.source_index[life_id][kind] or {}
    return ledger.source_index[life_id][kind]
end

local function source_usage_for_life(ledger, life_id)
    local count = 0
    local bytes = 0
    for _, by_original in pairs(ledger.source_index[life_id] or {}) do
        for _, ref in pairs(by_original) do
            local record = ledger.evidence_records[ref]
            if record then
                local encoded = plain_encoding(record.source_record)
                if encoded then
                    count = count + 1
                    bytes = bytes + #encoded
                end
            end
        end
    end
    return count, bytes
end

local function capture_source_on(ledger, descriptor, route_id)
    local slot = source_index_slot(
        ledger,
        descriptor.life_id,
        descriptor.source_kind
    )
    local existing_ref = slot[descriptor.original_source_id]
    if existing_ref then
        local existing = ledger.evidence_records[existing_ref]
        if not existing
            or existing.source_digest ~= descriptor.source_digest
            or not same_value(existing.source_record, descriptor.source_record) then
            return nil, instrument_error(
                "identity",
                "source_evidence_conflict",
                "edge_stats_v3.source_capture",
                route_id,
                {descriptor.original_source_id}
            )
        end
        return existing_ref, "reused"
    end

    local bounds = ledger.instrument_bounds
    local life_count, life_bytes = source_usage_for_life(
        ledger,
        descriptor.life_id
    )
    local bound_name
    if life_count >= bounds.max_source_records then
        bound_name = "max_source_records"
    elseif descriptor.encoded_bytes > bounds.max_single_source_bytes then
        bound_name = "max_single_source_bytes"
    elseif life_bytes + descriptor.encoded_bytes
        > bounds.max_source_bytes_per_life then
        bound_name = "max_source_bytes_per_life"
    end
    if bound_name then
        ledger.source_usage.omitted_record_count =
            ledger.source_usage.omitted_record_count + 1
        ledger.source_usage.omitted_encoded_bytes =
            ledger.source_usage.omitted_encoded_bytes
            + descriptor.encoded_bytes
        local recorded, record_err = append_error_on(ledger, assert(instrument_error(
            "bounds",
            "instrument_source_bound_exceeded",
            "edge_stats_v3.source_capture",
            route_id,
            {descriptor.original_source_id},
            bound_name
        )))
        if not recorded then
            return nil, record_err
        end
        return nil, "omitted"
    end

    local record = {
        kind = "edge_source_evidence",
        protocol_version = stats.source_protocol_version,
        life_id = descriptor.life_id,
        source_kind = descriptor.source_kind,
        original_source_id = descriptor.original_source_id,
        source_digest = descriptor.source_digest,
        source_record = copy_value(descriptor.source_record),
        source_truth_status = descriptor.source_record.event_truth_status
            or descriptor.source_record.truth_status,
        event_truth_status = "runtime_confirmed",
    }
    local evidence_ref, evidence_err = tagged_digest(source_seed(record))
    if not evidence_ref then
        return nil, evidence_err
    end
    record.evidence_ref = evidence_ref
    ledger.evidence_records[evidence_ref] = record
    slot[descriptor.original_source_id] = evidence_ref
    ledger.source_usage.record_count = ledger.source_usage.record_count + 1
    ledger.source_usage.encoded_bytes = ledger.source_usage.encoded_bytes
        + descriptor.encoded_bytes
    return evidence_ref, "captured"
end

local function capture_bundle_on(ledger, bundle, life_id, automatic, route_id)
    local descriptors, descriptor_err = prepare_source_descriptors(
        bundle,
        life_id,
        automatic
    )
    if not descriptors then
        return nil, descriptor_err
    end
    local refs = {}
    for _, descriptor in ipairs(descriptors) do
        local ref, status_or_err = capture_source_on(
            ledger,
            descriptor,
            route_id
        )
        if not ref and status_or_err ~= "omitted" then
            return nil, status_or_err
        end
        if ref then
            refs[source_key(descriptor)] = ref
        end
    end
    return refs
end

local function source_resolves(ledger, life_id, original_id)
    for kind in pairs(source_kinds) do
        local ref = ledger.source_index[life_id]
            and ledger.source_index[life_id][kind]
            and ledger.source_index[life_id][kind][original_id]
        if ref and ledger.evidence_records[ref] then
            return ref
        end
    end
    return nil
end

local function require_source_on(ledger, life_id, original_id, route_id)
    if non_empty(original_id) and not source_resolves(ledger, life_id, original_id) then
        local recorded, err = append_error_on(ledger, assert(instrument_error(
            "ledger",
            "source_evidence_unresolved",
            "edge_stats_v3.source_resolution",
            route_id,
            {original_id}
        )))
        if not recorded then
            return nil, err
        end
        return false
    end
    return true
end

local function counter_map_valid(value)
    return sum_map(value) ~= nil
end

local function expected_physical_status(physical)
    if physical.executed_count > 0 then
        return "executed"
    elseif physical.failed_count > 0 then
        return "failed"
    elseif physical.committed_count > 0 then
        return "committed"
    elseif physical.selected_count > 0 then
        return "selected"
    end
    return "untested"
end

local function refresh_direction(record)
    record.physical_status = expected_physical_status(record.physical)
    record.promotion_status = record.promotion.eligible_executed_count > 0
        and "eligible_executed" or "unqualified"
end

local function refresh_edge(record, ledger_status)
    local physical = 0
    local promotion = 0
    for direction in pairs(record.legal_directions) do
        local directional = record.directions[direction]
        refresh_direction(directional)
        if directional.physical.executed_count > 0 then
            physical = physical + 1
        end
        if directional.promotion.eligible_executed_count > 0 then
            promotion = promotion + 1
        end
    end
    record.physical_executed_direction_count = physical
    record.promotion_executed_direction_count = promotion
    record.physical_coverage = physical == record.required_direction_count
        and "complete" or (physical > 0 and "partial" or "untested")
    if ledger_status == "invalid" then
        record.promotion_coverage = "unqualified"
    else
        record.promotion_coverage = promotion == record.required_direction_count
            and "complete" or (promotion > 0 and "partial" or "unqualified")
    end
end

local function direction_for(ledger, from, to)
    from = topology.resolve(from)
    to = topology.resolve(to)
    local definition = from and to and edge_catalog.get(from, to) or nil
    local direction = from and to and (from .. "->" .. to) or nil
    if not definition or not direction
        or not ledger.edges[definition.edge]
        or not ledger.edges[definition.edge].legal_directions[direction] then
        return nil, nil, instrument_error(
            "identity", "route_outside_authority_surface",
            "edge_stats_v3.route"
        )
    end
    return ledger.edges[definition.edge].directions[direction],
        ledger.edges[definition.edge], nil
end

local function verify_physical(record)
    if not exact_keys(record, {
        candidate_count = true,
        selected_count = true,
        committed_count = true,
        executed_count = true,
        failed_count = true,
        pending_at_host_ceiling_count = true,
        derivation_refs = true,
        selected_refs = true,
        committed_refs = true,
        executed_refs = true,
        failure_refs = true,
        pending_refs = true,
        authority_counts = true,
        arrival_kinds = true,
        failure_kinds = true,
    }) then
        return false
    end
    for _, key in ipairs({
        "candidate_count", "selected_count", "committed_count",
        "executed_count", "failed_count", "pending_at_host_ceiling_count",
    }) do
        if not non_negative_integer(record[key]) then
            return false
        end
    end
    for _, pair in ipairs({
        {"candidate_count", "derivation_refs"},
        {"selected_count", "selected_refs"},
        {"committed_count", "committed_refs"},
        {"executed_count", "executed_refs"},
        {"failed_count", "failure_refs"},
        {"pending_at_host_ceiling_count", "pending_refs"},
    }) do
        if not strict_sorted_strings(record[pair[2]])
            or record[pair[1]] ~= #record[pair[2]] then
            return false
        end
    end
    local authority_total = sum_map(record.authority_counts)
    local arrival_total = sum_map(record.arrival_kinds)
    local failure_total = sum_map(record.failure_kinds)
    return authority_total == record.selected_count
        and arrival_total == record.executed_count
        and failure_total == record.failed_count
end

local function list_contains(values, expected)
    for _, value in ipairs(values or {}) do
        if value == expected then
            return true
        end
    end
    return false
end

local function verify_promotion(record, physical)
    if not exact_keys(record, {
        eligible_selected_count = true,
        eligible_committed_count = true,
        eligible_executed_count = true,
        ineligible_executed_count = true,
        unclassified_executed_count = true,
        eligible_derivation_refs = true,
        eligible_committed_refs = true,
        eligible_executed_refs = true,
        credit_decision_refs = true,
        rejected_reason_counts = true,
        rejected_route_refs = true,
    }) then
        return false
    end
    for _, key in ipairs({
        "eligible_selected_count", "eligible_committed_count",
        "eligible_executed_count", "ineligible_executed_count",
        "unclassified_executed_count",
    }) do
        if not non_negative_integer(record[key]) then
            return false
        end
    end
    for _, key in ipairs({
        "eligible_derivation_refs", "eligible_committed_refs",
        "eligible_executed_refs", "credit_decision_refs",
        "rejected_route_refs",
    }) do
        if not strict_sorted_strings(record[key]) then
            return false
        end
    end
    if not counter_map_valid(record.rejected_reason_counts) then
        return false
    end
    for reason in pairs(record.rejected_reason_counts) do
        if not edge_credit.is_eligibility_reason(reason) then
            return false
        end
    end
    if record.eligible_selected_count ~= #record.eligible_derivation_refs
        or record.eligible_committed_count ~= #record.eligible_committed_refs
        or record.eligible_executed_count ~= #record.eligible_executed_refs
        or record.ineligible_executed_count ~= #record.rejected_route_refs
        or record.eligible_selected_count > physical.selected_count
        or record.eligible_committed_count > physical.committed_count
        or record.eligible_executed_count > physical.executed_count
        or record.eligible_committed_count > record.eligible_selected_count
        or record.eligible_executed_count > record.eligible_committed_count
        or record.eligible_executed_count + record.ineligible_executed_count
            + record.unclassified_executed_count ~= physical.executed_count
        or #record.credit_decision_refs > physical.executed_count then
        return false
    end
    for _, ref in ipairs(record.eligible_derivation_refs) do
        if not list_contains(physical.derivation_refs, ref) then
            return false
        end
    end
    for _, ref in ipairs(record.eligible_committed_refs) do
        if not list_contains(physical.committed_refs, ref) then
            return false
        end
    end
    for _, ref in ipairs(record.eligible_executed_refs) do
        if not list_contains(physical.executed_refs, ref) then
            return false
        end
    end
    return true
end

local function verify_direction(record, key, legal)
    return exact_keys(record, {
        direction = true,
        legal = true,
        physical = true,
        promotion = true,
        physical_status = true,
        promotion_status = true,
    }) and record.direction == key
        and record.legal == legal
        and verify_physical(record.physical)
        and verify_promotion(record.promotion, record.physical)
        and record.physical_status == expected_physical_status(record.physical)
        and record.promotion_status
            == (record.promotion.eligible_executed_count > 0
                and "eligible_executed" or "unqualified")
end

local function verify_edge(record, definition, ledger_status)
    if not exact_keys(record, {
        id = true,
        edge = true,
        left = true,
        right = true,
        legal_directions = true,
        directions = true,
        physical_executed_direction_count = true,
        promotion_executed_direction_count = true,
        required_direction_count = true,
        physical_coverage = true,
        promotion_coverage = true,
    }) or record.id ~= definition.id
        or record.edge ~= definition.edge
        or record.left ~= definition.left
        or record.right ~= definition.right
        or record.required_direction_count ~= #definition.directions then
        return false
    end
    local expected = {}
    local physical = 0
    local promotion = 0
    for _, direction in ipairs(definition.directions) do
        expected[direction] = true
        local directional = record.directions[direction]
        if not directional or not record.legal_directions[direction]
            or not verify_direction(directional, direction, true) then
            return false
        end
        if directional.physical.executed_count > 0 then
            physical = physical + 1
        end
        if directional.promotion.eligible_executed_count > 0 then
            promotion = promotion + 1
        end
    end
    for direction in pairs(record.directions) do
        if not expected[direction] then
            return false
        end
    end
    for direction in pairs(record.legal_directions) do
        if not expected[direction] then
            return false
        end
    end
    local coverage = physical == #definition.directions and "complete"
        or (physical > 0 and "partial" or "untested")
    local expected_promotion_coverage
    if ledger_status == "invalid" then
        expected_promotion_coverage = "unqualified"
    else
        expected_promotion_coverage = promotion == #definition.directions
            and "complete" or (promotion > 0 and "partial" or "unqualified")
    end
    return record.physical_executed_direction_count == physical
        and record.promotion_executed_direction_count == promotion
        and record.physical_coverage == coverage
        and record.promotion_coverage == expected_promotion_coverage
end

local function verify_observer(record, observer_id)
    if not exact_keys(record, {
        observer = true,
        observed_authority = true,
        evidence_role = true,
        comparison_count = true,
        agreement_count = true,
        divergence_count = true,
        no_prediction_count = true,
        unavailable_count = true,
        outcome_counts = true,
    }) or record.observer ~= observer_id
        or record.observed_authority ~= observer_authorities[observer_id]
        or record.evidence_role ~= "route_comparison" then
        return false
    end
    for _, key in ipairs({
        "comparison_count", "agreement_count", "divergence_count",
        "no_prediction_count", "unavailable_count",
    }) do
        if not non_negative_integer(record[key]) then
            return false
        end
    end
    return record.agreement_count + record.divergence_count
            == record.comparison_count
        and record.no_prediction_count <= record.comparison_count
        and record.unavailable_count <= record.comparison_count
        and counter_map_valid(record.outcome_counts)
        and sum_map(record.outcome_counts) == record.comparison_count
end

local function verify_rail_channel(record, definition)
    if not exact_keys(record, {
        id = true,
        evidence_role = true,
        observer = true,
        observed_authority = true,
        authority = true,
        target_kind = true,
        cases = true,
        target_count = true,
        reference_eye_count = true,
        eye_debt_cases = true,
        eye_target_count = true,
        debt_eye_target_count = true,
        fresh_eye_target_count = true,
        debt_bypass_count = true,
        fresh_direct_count = true,
        no_target_count = true,
    }, {
        observer = true,
        observed_authority = true,
    }) then
        return false
    end
    for key, expected in pairs(definition) do
        if record[key] ~= expected then
            return false
        end
    end
    for _, key in ipairs({
        "cases", "target_count", "reference_eye_count", "eye_debt_cases",
        "eye_target_count", "debt_eye_target_count", "fresh_eye_target_count",
        "debt_bypass_count", "fresh_direct_count", "no_target_count",
    }) do
        if not non_negative_integer(record[key]) then
            return false
        end
    end
    return record.target_count + record.no_target_count == record.cases
        and record.debt_eye_target_count + record.fresh_eye_target_count
            == record.eye_target_count
        and record.eye_target_count + record.debt_bypass_count
            + record.fresh_direct_count == record.target_count
end

local function verify_rail(record, definition)
    return exact_keys(record, {
        id = true,
        from = true,
        eye = true,
        debt_kind = true,
        channels = true,
        promotion_status = true,
    }) and record.id == definition.id
        and record.from == definition.from
        and record.eye == definition.eye
        and record.debt_kind == definition.debt_kind
        and record.promotion_status == "insufficient_evidence"
        and exact_keys(record.channels, {
            tree_shadow = true,
            tree_authority = true,
        })
        and verify_rail_channel(
            record.channels.tree_shadow,
            rail_channel_definitions.tree_shadow
        )
        and verify_rail_channel(
            record.channels.tree_authority,
            rail_channel_definitions.tree_authority
        )
end

local function expected_phase(route)
    if route.arrival_ref then
        return "executed"
    elseif route.failure_ref then
        return "failed"
    elseif route.pending_ref then
        return "pending_at_host_ceiling"
    elseif route.commit_ref then
        return "committed"
    end
    return "selected"
end

local function verify_route(route, route_id, ledger)
    if not exact_keys(route, {
        kind = true,
        protocol_version = true,
        route_evidence_id = true,
        life_id = true,
        route_ordinal = true,
        edge_id = true,
        direction = true,
        selection_ref = true,
        commit_ref = true,
        authority_taint_ref = true,
        arrival_ref = true,
        failure_ref = true,
        pending_ref = true,
        credit_decision_ref = true,
        phase_status = true,
    }, {
        commit_ref = true,
        authority_taint_ref = true,
        arrival_ref = true,
        failure_ref = true,
        pending_ref = true,
        credit_decision_ref = true,
    }) or route.kind ~= "edge_route_phase_index"
        or route.protocol_version ~= stats.protocol_version
        or route.route_evidence_id ~= route_id
        or not tagged_hash(route_id)
        or not ledger.source_lives[route.life_id]
        or not positive_integer(route.route_ordinal)
        or not non_empty(route.edge_id)
        or not non_empty(route.direction)
        or not tagged_hash(route.selection_ref)
        or route.phase_status ~= expected_phase(route) then
        return false
    end
    local terminal_count = (route.arrival_ref and 1 or 0)
        + (route.failure_ref and 1 or 0)
        + (route.pending_ref and 1 or 0)
    if terminal_count > 1
        or (route.commit_ref == nil and terminal_count > 0)
        or (route.credit_decision_ref ~= nil and route.arrival_ref == nil) then
        return false
    end
    for _, key in ipairs({
        "commit_ref", "authority_taint_ref", "arrival_ref", "failure_ref",
        "pending_ref", "credit_decision_ref",
    }) do
        if route[key] ~= nil and not tagged_hash(route[key]) then
            return false
        end
    end
    local definition = edge_catalog.get(route.edge_id)
    if not definition or not definition.directions then
        return false
    end
    local legal = false
    for _, direction in ipairs(definition.directions) do
        if direction == route.direction then
            legal = true
            break
        end
    end
    if not legal then
        return false
    end
    if ledger.ledger_status == "valid" then
        for _, key in ipairs({
            "selection_ref", "commit_ref", "authority_taint_ref", "arrival_ref",
            "failure_ref", "pending_ref", "credit_decision_ref",
        }) do
            if route[key] and not source_resolves(
                ledger,
                route.life_id,
                route[key]
            ) then
                return false
            end
        end
    end
    return true
end

local function verify_sources(ledger)
    local indexed = {}
    local record_count = 0
    local encoded_bytes = 0
    local counts_by_life = {}
    local bytes_by_life = {}
    for life_id, by_kind in pairs(ledger.source_index) do
        if not ledger.source_lives[life_id] or type(by_kind) ~= "table" then
            return false
        end
        for kind, by_original in pairs(by_kind) do
            if not source_kinds[kind] or type(by_original) ~= "table" then
                return false
            end
            for original_id, ref in pairs(by_original) do
                local record = ledger.evidence_records[ref]
                if not non_empty(original_id) or indexed[ref] or not record
                    or record.evidence_ref ~= ref
                    or record.life_id ~= life_id
                    or record.source_kind ~= kind
                    or record.original_source_id ~= original_id then
                    return false
                end
                local encoded = verify_source_record(record)
                if not encoded then
                    return false
                end
                indexed[ref] = true
                record_count = record_count + 1
                encoded_bytes = encoded_bytes + #encoded
                counts_by_life[life_id] = (counts_by_life[life_id] or 0) + 1
                bytes_by_life[life_id] = (bytes_by_life[life_id] or 0)
                    + #encoded
                if #encoded > ledger.instrument_bounds.max_single_source_bytes
                    or counts_by_life[life_id]
                        > ledger.instrument_bounds.max_source_records
                    or bytes_by_life[life_id]
                        > ledger.instrument_bounds.max_source_bytes_per_life then
                    return false
                end
            end
        end
    end
    for ref in pairs(ledger.evidence_records) do
        if not indexed[ref] then
            return false
        end
    end
    return ledger.source_usage.record_count == record_count
        and ledger.source_usage.encoded_bytes == encoded_bytes
end

function stats.verify(ledger)
    if not exact_keys(ledger, {
        kind = true,
        protocol_version = true,
        authority_epoch = true,
        evidence_epoch_id = true,
        physics_epoch_id = true,
        ledger_status = true,
        instrument_bounds = true,
        source_usage = true,
        source_lives = true,
        errors = true,
        error_overflow = true,
        comparison_count = true,
        tree_derivation_count = true,
        tree_no_viable_count = true,
        tree_outcome_counts = true,
        observers = true,
        rails = true,
        evidence_records = true,
        source_index = true,
        routes = true,
        edges = true,
        edge_order = true,
        truth_status = true,
    }, {
        authority_epoch = true,
        evidence_epoch_id = true,
        physics_epoch_id = true,
        error_overflow = true,
    }) or ledger.kind ~= "edge_statistics"
        or ledger.protocol_version ~= stats.protocol_version
        or (ledger.ledger_status ~= "valid" and ledger.ledger_status ~= "invalid")
        or not verify_bounds(ledger.instrument_bounds)
        or ledger.truth_status ~= "runtime_confirmed" then
        return nil, invalid("edge_stats_invalid", "root")
    end
    if ledger.authority_epoch then
        local epoch_ok = authority_epoch.verify(ledger.authority_epoch)
        if not epoch_ok
            or ledger.evidence_epoch_id
                ~= ledger.authority_epoch.evidence_epoch_id
            or ledger.physics_epoch_id
                ~= ledger.authority_epoch.physics_epoch_id
            or not same_value(
                ledger.instrument_bounds,
                ledger.authority_epoch.instrumentation.bounds
            ) then
            return nil, invalid("authority_epoch_invalid", "authority_epoch")
        end
    elseif ledger.evidence_epoch_id ~= nil or ledger.physics_epoch_id ~= nil
        or ledger.ledger_status ~= "invalid" then
        return nil, invalid("authority_epoch_missing", "authority_epoch")
    end
    if not exact_keys(ledger.source_usage, {
        record_count = true,
        encoded_bytes = true,
        omitted_record_count = true,
        omitted_encoded_bytes = true,
    }) then
        return nil, invalid("edge_stats_invalid", "source_usage")
    end
    for _, key in ipairs({
        "record_count", "encoded_bytes", "omitted_record_count",
        "omitted_encoded_bytes",
    }) do
        if not non_negative_integer(ledger.source_usage[key]) then
            return nil, invalid("edge_stats_invalid", "source_usage." .. key)
        end
    end
    if type(ledger.source_lives) ~= "table"
        or type(ledger.evidence_records) ~= "table"
        or type(ledger.source_index) ~= "table"
        or type(ledger.routes) ~= "table"
        or type(ledger.errors) ~= "table" then
        return nil, invalid("edge_stats_invalid", "stores")
    end
    local life_count = 0
    for life_id, life in pairs(ledger.source_lives) do
        local life_ok = verify_life_source(life)
        if life_id ~= life.life_id or not life_ok then
            return nil, invalid("life_source_invalid", life_id)
        end
        life_count = life_count + 1
    end
    if life_count == 0 or not verify_sources(ledger) then
        return nil, invalid("source_evidence_invalid", "sources")
    end
    if #ledger.errors > math.max(
        ledger.instrument_bounds.max_error_records - 1,
        0
    ) then
        return nil, invalid("instrument_error_bound_invalid", "errors")
    end
    for key, record in pairs(ledger.errors) do
        if type(key) ~= "number" or key < 1 or key > #ledger.errors
            or key % 1 ~= 0 or not verify_error(record) then
            return nil, invalid("instrument_error_invalid", "errors")
        end
    end
    if ledger.error_overflow then
        local overflow = ledger.error_overflow
        if not exact_keys(overflow, {
            kind = true,
            protocol_version = true,
            overflow_count = true,
            overflow_digest = true,
            event_truth_status = true,
        }) or overflow.kind ~= "authority_instrument_error_overflow"
            or overflow.protocol_version ~= stats.error_protocol_version
            or not positive_integer(overflow.overflow_count)
            or not tagged_hash(overflow.overflow_digest)
            or overflow.event_truth_status ~= "runtime_confirmed" then
            return nil, invalid("instrument_error_overflow_invalid", "errors")
        end
    end
    if ledger.ledger_status == "valid"
        and (#ledger.errors > 0 or ledger.error_overflow ~= nil
            or ledger.source_usage.omitted_record_count > 0) then
        return nil, invalid("valid_ledger_has_errors", "ledger_status")
    end

    for _, key in ipairs({
        "comparison_count", "tree_derivation_count", "tree_no_viable_count",
    }) do
        if not non_negative_integer(ledger[key]) then
            return nil, invalid("edge_stats_invalid", key)
        end
    end
    if ledger.tree_no_viable_count > ledger.tree_derivation_count
        or not counter_map_valid(ledger.tree_outcome_counts)
        or sum_map(ledger.tree_outcome_counts) ~= ledger.tree_derivation_count
        or not exact_keys(ledger.observers, {tree = true, legacy = true})
        or not verify_observer(ledger.observers.tree, "tree")
        or not verify_observer(ledger.observers.legacy, "legacy")
        or ledger.comparison_count ~= ledger.observers.tree.comparison_count
            + ledger.observers.legacy.comparison_count then
        return nil, invalid("observer_invalid", "observers")
    end
    if type(ledger.rails) ~= "table" then
        return nil, invalid("rail_invalid", "rails")
    end
    local rail_seen = {}
    for _, definition in ipairs(rail_definitions) do
        if not verify_rail(ledger.rails[definition.id], definition) then
            return nil, invalid("rail_invalid", definition.id)
        end
        rail_seen[definition.id] = true
    end
    for id in pairs(ledger.rails) do
        if not rail_seen[id] then
            return nil, invalid("rail_invalid", id)
        end
    end

    if type(ledger.edge_order) ~= "table" or type(ledger.edges) ~= "table" then
        return nil, invalid("edge_stats_invalid", "edges")
    end
    local edge_seen = {}
    for index, definition in ipairs(edge_catalog.list()) do
        if ledger.edge_order[index] ~= definition.edge
            or edge_seen[definition.edge]
            or not verify_edge(
                ledger.edges[definition.edge],
                definition,
                ledger.ledger_status
            ) then
            return nil, invalid("edge_stats_invalid", definition.id)
        end
        edge_seen[definition.edge] = true
    end
    if #ledger.edge_order ~= 22 then
        return nil, invalid("edge_stats_invalid", "edge_order")
    end
    for edge in pairs(ledger.edges) do
        if not edge_seen[edge] then
            return nil, invalid("edge_stats_invalid", edge)
        end
    end

    local expected = {}
    local ordinals = {}
    for route_id, route in pairs(ledger.routes) do
        if not verify_route(route, route_id, ledger) then
            return nil, invalid("route_phase_invalid", route_id)
        end
        local ordinal_key = route.life_id .. "\0" .. tostring(route.route_ordinal)
        if ordinals[ordinal_key] then
            return nil, invalid("route_ordinal_replayed", route_id)
        end
        ordinals[ordinal_key] = true
        expected[route.direction] = expected[route.direction] or {
            selected = {}, committed = {}, executed = {}, failed = {}, pending = {},
        }
        local into = expected[route.direction]
        into.selected[#into.selected + 1] = route.selection_ref
        if route.commit_ref then
            into.committed[#into.committed + 1] = route.commit_ref
        end
        if route.arrival_ref then
            into.executed[#into.executed + 1] = route.arrival_ref
        elseif route.failure_ref then
            into.failed[#into.failed + 1] = route.failure_ref
        elseif route.pending_ref then
            into.pending[#into.pending + 1] = route.pending_ref
        end
    end
    for _, edge in pairs(ledger.edges) do
        for direction_key, directional in pairs(edge.directions) do
            local refs = expected[direction_key] or {
                selected = {}, committed = {}, executed = {}, failed = {}, pending = {},
            }
            for _, values in pairs(refs) do
                table.sort(values)
            end
            local physical = directional.physical
            if not same_value(physical.selected_refs, refs.selected)
                or not same_value(physical.committed_refs, refs.committed)
                or not same_value(physical.executed_refs, refs.executed)
                or not same_value(physical.failure_refs, refs.failed)
                or not same_value(physical.pending_refs, refs.pending) then
                return nil, invalid("route_counter_mismatch", direction_key)
            end
            if ledger.ledger_status == "valid" then
                for _, ref in ipairs(physical.derivation_refs) do
                    local found = ledger.evidence_records[ref] ~= nil
                    for life_id in pairs(ledger.source_lives) do
                        if source_resolves(ledger, life_id, ref) then
                            found = true
                            break
                        end
                    end
                    if not found then
                        return nil, invalid("source_evidence_unresolved", ref)
                    end
                end
            end
        end
    end
    return true
end

local function initial_ledger(epoch_record, life)
    local ledger = {
        kind = "edge_statistics",
        protocol_version = stats.protocol_version,
        authority_epoch = epoch_record and copy_value(epoch_record) or nil,
        evidence_epoch_id = epoch_record and epoch_record.evidence_epoch_id or nil,
        physics_epoch_id = epoch_record and epoch_record.physics_epoch_id or nil,
        ledger_status = epoch_record and "valid" or "invalid",
        instrument_bounds = epoch_record
            and copy_value(epoch_record.instrumentation.bounds)
            or copy_value(default_bounds),
        source_usage = {
            record_count = 0,
            encoded_bytes = 0,
            omitted_record_count = 0,
            omitted_encoded_bytes = 0,
        },
        source_lives = {[life.life_id] = copy_value(life)},
        errors = {},
        error_overflow = nil,
        comparison_count = 0,
        tree_derivation_count = 0,
        tree_no_viable_count = 0,
        tree_outcome_counts = {},
        observers = {
            tree = new_observer("tree"),
            legacy = new_observer("legacy"),
        },
        rails = {},
        evidence_records = {},
        source_index = {[life.life_id] = {}},
        routes = {},
        edges = {},
        edge_order = {},
        truth_status = "runtime_confirmed",
    }
    for _, definition in ipairs(rail_definitions) do
        ledger.rails[definition.id] = new_rail(definition)
    end
    for _, definition in ipairs(edge_catalog.list()) do
        ledger.edges[definition.edge] = new_edge(definition)
        ledger.edge_order[#ledger.edge_order + 1] = definition.edge
    end
    return ledger
end

function stats.new(epoch_record, life, epoch_error)
    local life_ok, life_err = verify_life_source(life)
    if not life_ok then
        return nil, life_err
    end
    if epoch_record ~= nil then
        local epoch_ok, epoch_err = authority_epoch.verify(epoch_record)
        if not epoch_ok then
            return nil, epoch_err
        end
        if epoch_error ~= nil then
            return nil, instrument_error(
                "configuration", "epoch_record_error_conflict",
                "edge_stats_v3.new"
            )
        end
    end
    local ledger = initial_ledger(epoch_record, life)
    if not epoch_record then
        local recorded, record_err = append_error_on(
            ledger,
            epoch_error or assert(instrument_error(
                "configuration", "authority_epoch_missing",
                "edge_stats_v3.new"
            ))
        )
        if not recorded then
            return nil, record_err
        end
    end
    local ok, err = stats.verify(ledger)
    if not ok then
        return nil, err
    end
    return ledger
end

local function working_state(ledger)
    local ok, err = stats.verify(ledger)
    if not ok then
        return nil, err
    end
    return copy_value(ledger)
end

local function commit_working_state(target, working)
    for _, edge in pairs(working.edges or {}) do
        refresh_edge(edge, working.ledger_status)
    end
    local ok, err = stats.verify(working)
    if not ok then
        return nil, err
    end
    replace_contents(target, working)
    return true
end

function stats.note_error(ledger, value)
    local working, working_err = working_state(ledger)
    if not working then
        return nil, working_err
    end
    local record, record_err = append_error_on(working, value)
    if not record then
        return nil, record_err
    end
    local committed, commit_err = commit_working_state(ledger, working)
    if not committed then
        return nil, commit_err
    end
    return true
end

function stats.summary(ledger)
    local ok, err = stats.verify(ledger)
    if not ok then
        return nil, err
    end
    return copy_value(ledger)
end

local function contribution_present(evidence, target, kind)
    for _, candidate in ipairs(evidence.candidates or {}) do
        if topology.resolve(candidate.to) == target then
            for _, contribution in ipairs(candidate.contributions or {}) do
                if contribution.kind == kind
                    and contribution.direction == "help" then
                    return true
                end
            end
        end
    end
    return false
end

local function rail_for_source(ledger, from)
    for _, definition in ipairs(rail_definitions) do
        if definition.from == from then
            return ledger.rails[definition.id]
        end
    end
    return nil
end

local function record_rail_on(ledger, evidence, channel_id)
    local rail = rail_for_source(ledger, topology.resolve(evidence.current_operator))
    if not rail then
        return true
    end
    local channel = rail.channels[channel_id]
    if not channel then
        return nil, instrument_error("ledger", "rail_channel_unknown",
            "edge_stats_v3.rail")
    end
    channel.cases = channel.cases + 1
    if topology.resolve(evidence.reference_to) == rail.eye then
        channel.reference_eye_count = channel.reference_eye_count + 1
    end
    local debt = contribution_present(evidence, rail.eye, rail.debt_kind)
    if debt then
        channel.eye_debt_cases = channel.eye_debt_cases + 1
    end
    local target = topology.resolve(evidence.target_to)
    if target == nil then
        channel.no_target_count = channel.no_target_count + 1
        return true
    end
    channel.target_count = channel.target_count + 1
    if target == rail.eye then
        channel.eye_target_count = channel.eye_target_count + 1
        if debt then
            channel.debt_eye_target_count = channel.debt_eye_target_count + 1
        else
            channel.fresh_eye_target_count = channel.fresh_eye_target_count + 1
        end
    elseif debt then
        channel.debt_bypass_count = channel.debt_bypass_count + 1
    else
        channel.fresh_direct_count = channel.fresh_direct_count + 1
    end
    return true
end

local function automatic_source(record)
    if type(record) ~= "table" then
        return nil
    end
    local original_id = record.record_id
        or record.eligibility_ref
        or record.credit_decision_ref
        or record.error_id
    if not non_empty(original_id) then
        return nil
    end
    return {
        source_kind = "edge_credit",
        original_source_id = original_id,
        source_record = record,
    }
end

local function automatic_sources(...)
    local result = {}
    for index = 1, select("#", ...) do
        local descriptor = automatic_source(select(index, ...))
        if descriptor then
            result[#result + 1] = descriptor
        end
    end
    return result
end

local function source_record_by_original(ledger, life_id, original_id)
    local ref = source_resolves(ledger, life_id, original_id)
    return ref and ledger.evidence_records[ref] or nil
end

local function selection_valid(record, ledger)
    if type(record) ~= "table"
        or record.kind ~= "route_evidence_selection"
        or record.protocol_version ~= "route-evidence.v0"
        or not tagged_hash(record.record_id)
        or not tagged_hash(record.route_evidence_id)
        or not tagged_hash(record.life_id)
        or not ledger.source_lives[record.life_id]
        or record.packet_id ~= ledger.source_lives[record.life_id].packet_id
        or record.lineage_id ~= ledger.source_lives[record.life_id].lineage_id
        or record.generation ~= ledger.source_lives[record.life_id].generation
        or not positive_integer(record.route_ordinal)
        or not route_authorities[record.route_authority]
        or (record.classification_status ~= "classified"
            and record.classification_status ~= "unclassified")
        or record.event_truth_status ~= "runtime_confirmed" then
        return false
    end
    local directional, edge = direction_for(ledger, record.from, record.to)
    if not directional or edge.id ~= record.edge_id then
        return false
    end
    if record.classification_status == "classified" then
        return type(record.eligibility) == "table"
            and record.eligibility.kind == "edge_credit_selection_eligibility"
            and tagged_hash(record.eligibility.eligibility_ref)
            and record.eligibility.route_evidence_id == record.route_evidence_id
    end
    return record.eligibility == nil
end

local function commit_valid(record)
    return type(record) == "table"
        and record.kind == "route_evidence_commit"
        and record.protocol_version == "route-evidence.v0"
        and tagged_hash(record.record_id)
        and tagged_hash(record.route_evidence_id)
        and tagged_hash(record.selection_ref)
        and non_empty(record.route_trace_ref)
        and route_authorities[record.route_authority]
        and record.event_truth_status == "runtime_confirmed"
end

local function arrival_valid(record)
    return type(record) == "table"
        and record.kind == "route_evidence_arrival"
        and record.protocol_version == "route-evidence.v0"
        and tagged_hash(record.record_id)
        and tagged_hash(record.route_evidence_id)
        and tagged_hash(record.commit_ref)
        and non_empty(record.destination_tick_ref)
        and strict_sorted_strings(record.effect_refs)
        and non_empty(record.payload_kind)
        and record.event_truth_status == "runtime_confirmed"
end

local function decision_valid(record, arrival)
    if record == nil then
        return true
    end
    return type(record) == "table"
        and record.kind == "edge_credit_decision"
        and record.protocol_version == "edge-credit.v0"
        and tagged_hash(record.credit_decision_ref)
        and record.route_evidence_id == arrival.route_evidence_id
        and record.commit_ref == arrival.commit_ref
        and record.arrival_ref == arrival.record_id
        and (record.status == "credited" or record.status == "rejected")
        and strict_sorted_strings(record.reasons)
        and strict_sorted_strings(record.basis_refs)
        and record.event_truth_status == "runtime_confirmed"
end

local function failure_valid(record)
    return type(record) == "table"
        and record.kind == "route_evidence_failure"
        and record.protocol_version == "route-evidence.v0"
        and tagged_hash(record.record_id)
        and tagged_hash(record.route_evidence_id)
        and tagged_hash(record.commit_ref)
        and non_empty(record.destination_tick_ref)
        and non_empty(record.failure_ref)
        and non_empty(record.failure_kind)
        and record.event_truth_status == "runtime_confirmed"
end

local function pending_valid(record)
    return type(record) == "table"
        and record.kind == "route_evidence_pending"
        and record.protocol_version == "route-evidence.v0"
        and tagged_hash(record.record_id)
        and tagged_hash(record.route_evidence_id)
        and tagged_hash(record.commit_ref)
        and record.stop_reason == "tick_limit"
        and record.event_truth_status == "runtime_confirmed"
end

local function finish_transaction(target, working)
    local committed, err = commit_working_state(target, working)
    if not committed then
        return nil, err
    end
    return true
end

local function record_observer_on(ledger, shadow, bundle)
    if type(shadow) ~= "table" or shadow.kind ~= "shadow_route_decision"
        or not non_empty(shadow.observer)
        or not non_empty(shadow.live_authority)
        or topology.resolve(shadow.current_operator) == nil then
        return nil, instrument_error("identity", "observer_record_invalid",
            "edge_stats_v3.record_observer")
    end
    local expected_authority = observer_authorities[shadow.observer]
    if not expected_authority or shadow.live_authority ~= expected_authority then
        return nil, instrument_error("identity", "observer_metadata_mismatch",
            "edge_stats_v3.record_observer")
    end
    if type(bundle) ~= "table" or not ledger.source_lives[bundle.life_id]
        or type(bundle.records) ~= "table" or #bundle.records == 0 then
        return nil, instrument_error("identity", "observer_source_missing",
            "edge_stats_v3.record_observer")
    end
    local observer_source_count = 0
    for _, descriptor in ipairs(bundle.records) do
        if descriptor.source_kind == "observer" then
            observer_source_count = observer_source_count + 1
            local existing_ref = ledger.source_index[bundle.life_id]
                and ledger.source_index[bundle.life_id].observer
                and ledger.source_index[bundle.life_id].observer[
                    descriptor.original_source_id
                ]
            if existing_ref then
                local normalized, normalize_err = normalize_source_descriptor(
                    descriptor,
                    bundle.life_id
                )
                if not normalized then
                    return nil, normalize_err
                end
                local existing = ledger.evidence_records[existing_ref]
                if not existing
                    or existing.source_digest ~= normalized.source_digest then
                    return nil, instrument_error(
                        "identity", "source_evidence_conflict",
                        "edge_stats_v3.source_capture", nil,
                        {descriptor.original_source_id}
                    )
                end
                return nil, instrument_error(
                    "ledger", "observer_record_replayed",
                    "edge_stats_v3.record_observer"
                )
            end
        end
    end
    if observer_source_count ~= 1 then
        return nil, instrument_error("identity", "observer_source_missing",
            "edge_stats_v3.record_observer")
    end
    local captured, capture_err = capture_bundle_on(
        ledger,
        bundle,
        bundle.life_id,
        nil,
        nil
    )
    if not captured then
        return nil, capture_err
    end
    local observer = ledger.observers[shadow.observer]
    ledger.comparison_count = ledger.comparison_count + 1
    observer.comparison_count = observer.comparison_count + 1
    if shadow.agreement == true then
        observer.agreement_count = observer.agreement_count + 1
    else
        observer.divergence_count = observer.divergence_count + 1
    end
    if topology.resolve(shadow.predicted_to) == nil then
        observer.no_prediction_count = observer.no_prediction_count + 1
    end
    if shadow.instrumentation_status == "unavailable" then
        observer.unavailable_count = observer.unavailable_count + 1
    end
    increment(observer.outcome_counts, shadow.prediction_outcome
        or (topology.resolve(shadow.predicted_to) and "selected" or "no_prediction"))
    if shadow.observer == "tree" then
        local rail_ok, rail_err = record_rail_on(ledger, {
            current_operator = shadow.current_operator,
            candidates = shadow.candidates,
            target_to = shadow.predicted_to,
            reference_to = shadow.live_to,
        }, "tree_shadow")
        if not rail_ok then
            return nil, rail_err
        end
    end
    return true
end

function stats.record_observer(ledger, shadow, bundle)
    local working, working_err = working_state(ledger)
    if not working then
        return nil, working_err
    end
    local ok, err = record_observer_on(working, shadow, bundle)
    if not ok then
        return nil, err
    end
    return finish_transaction(ledger, working)
end

local function record_tree_derivation_on(ledger, decision, bundle)
    if type(decision) ~= "table" or decision.authority ~= "tree"
        or not non_empty(decision.kind)
        or topology.resolve(decision.from) == nil
        or type(decision.candidates) ~= "table"
        or not non_empty(decision.derivation_ref)
        or decision.truth_status ~= "runtime_confirmed"
        or type(bundle) ~= "table" or not ledger.source_lives[bundle.life_id] then
        return nil, instrument_error("identity", "tree_derivation_invalid",
            "edge_stats_v3.record_tree_derivation")
    end
    if source_resolves(ledger, bundle.life_id, decision.derivation_ref) then
        return nil, instrument_error("ledger", "tree_derivation_replayed",
            "edge_stats_v3.record_tree_derivation")
    end
    local seen_directions = {}
    for key, candidate in pairs(decision.candidates) do
        if type(key) ~= "number" or key < 1 or key > #decision.candidates
            or key % 1 ~= 0 or type(candidate) ~= "table" then
            return nil, instrument_error("identity", "tree_derivation_invalid",
                "edge_stats_v3.record_tree_derivation")
        end
        local directional, edge, direction_err = direction_for(
            ledger,
            decision.from,
            candidate.to
        )
        if not directional then
            return nil, direction_err
        end
        local direction_key = topology.resolve(decision.from)
            .. "->" .. topology.resolve(candidate.to)
        if seen_directions[direction_key] then
            return nil, instrument_error("ledger", "tree_derivation_replayed",
                "edge_stats_v3.record_tree_derivation")
        end
        seen_directions[direction_key] = edge.id
    end

    local captured, capture_err = capture_bundle_on(
        ledger,
        bundle,
        bundle.life_id,
        nil,
        nil
    )
    if not captured then
        return nil, capture_err
    end
    require_source_on(
        ledger,
        bundle.life_id,
        decision.derivation_ref,
        nil
    )
    if non_empty(decision.pressure_snapshot_ref) then
        require_source_on(
            ledger,
            bundle.life_id,
            decision.pressure_snapshot_ref,
            nil
        )
    end
    local derivation_source_ref = source_resolves(
        ledger,
        bundle.life_id,
        decision.derivation_ref
    ) or decision.derivation_ref

    ledger.tree_derivation_count = ledger.tree_derivation_count + 1
    if decision.kind == "no_viable_edge" then
        ledger.tree_no_viable_count = ledger.tree_no_viable_count + 1
    end
    increment(ledger.tree_outcome_counts,
        decision.kind == "tree_route_decision" and "selected" or decision.kind)
    for _, candidate in ipairs(decision.candidates) do
        local directional, edge = direction_for(
            ledger,
            decision.from,
            candidate.to
        )
        directional.physical.candidate_count =
            directional.physical.candidate_count + 1
        append_unique(
            directional.physical.derivation_refs,
            derivation_source_ref
        )
        refresh_edge(edge, ledger.ledger_status)
    end
    local rail_ok, rail_err = record_rail_on(ledger, {
        current_operator = decision.from,
        candidates = decision.candidates,
        target_to = decision.to,
    }, "tree_authority")
    if not rail_ok then
        return nil, rail_err
    end
    return true
end

function stats.record_tree_derivation(ledger, decision, bundle)
    local working, working_err = working_state(ledger)
    if not working then
        return nil, working_err
    end
    local ok, err = record_tree_derivation_on(working, decision, bundle)
    if not ok then
        return nil, err
    end
    return finish_transaction(ledger, working)
end

local note_unclassified_on
local decision_matches_selection

local function record_selection_on(ledger, selection, bundle)
    if not selection_valid(selection, ledger)
        or ledger.routes[selection.route_evidence_id] then
        return nil, instrument_error("identity", "route_selection_invalid",
            "edge_stats_v3.record_selection", selection and selection.route_evidence_id)
    end
    for _, route in pairs(ledger.routes) do
        if route.life_id == selection.life_id
            and route.route_ordinal == selection.route_ordinal then
            return nil, instrument_error("ledger", "route_ordinal_replayed",
                "edge_stats_v3.record_selection", selection.route_evidence_id)
        end
    end
    local automatic = automatic_sources(selection, selection.eligibility)
    local captured, capture_err = capture_bundle_on(
        ledger,
        bundle,
        selection.life_id,
        automatic,
        selection.route_evidence_id
    )
    if not captured then
        return nil, capture_err
    end
    require_source_on(
        ledger,
        selection.life_id,
        selection.record_id,
        selection.route_evidence_id
    )
    if selection.eligibility then
        require_source_on(
            ledger,
            selection.life_id,
            selection.eligibility.eligibility_ref,
            selection.route_evidence_id
        )
    end
    local directional, edge = direction_for(ledger, selection.from, selection.to)
    local direction_key = topology.resolve(selection.from)
        .. "->" .. topology.resolve(selection.to)
    ledger.routes[selection.route_evidence_id] = {
        kind = "edge_route_phase_index",
        protocol_version = stats.protocol_version,
        route_evidence_id = selection.route_evidence_id,
        life_id = selection.life_id,
        route_ordinal = selection.route_ordinal,
        edge_id = edge.id,
        direction = direction_key,
        selection_ref = selection.record_id,
        commit_ref = nil,
        authority_taint_ref = nil,
        arrival_ref = nil,
        failure_ref = nil,
        pending_ref = nil,
        credit_decision_ref = nil,
        phase_status = "selected",
    }
    directional.physical.selected_count =
        directional.physical.selected_count + 1
    append_unique(directional.physical.selected_refs, selection.record_id)
    increment(directional.physical.authority_counts, selection.route_authority)
    if selection.classification_status == "unclassified" then
        local noted, note_err = note_unclassified_on(
            ledger,
            selection.route_evidence_id,
            {
                selection.derivation_ref,
                selection.pressure_snapshot_ref,
            }
        )
        if not noted then
            return nil, note_err
        end
    elseif selection.eligibility.status == "eligible"
        and ledger.ledger_status == "valid" then
        local derivation_ref = source_resolves(
            ledger,
            selection.life_id,
            selection.derivation_ref
        )
        if not derivation_ref
            or not list_contains(
                directional.physical.derivation_refs,
                derivation_ref
            ) then
            local noted, note_err = note_unclassified_on(
                ledger,
                selection.route_evidence_id,
                {selection.derivation_ref},
                "eligible_derivation_unresolved"
            )
            if not noted then
                return nil, note_err
            end
        else
            directional.promotion.eligible_selected_count =
                directional.promotion.eligible_selected_count + 1
            append_unique(
                directional.promotion.eligible_derivation_refs,
                derivation_ref
            )
        end
    end
    refresh_edge(edge, ledger.ledger_status)
    return true
end

function stats.record_selection(ledger, selection, bundle)
    local working, working_err = working_state(ledger)
    if not working then
        return nil, working_err
    end
    local ok, err = record_selection_on(working, selection, bundle)
    if not ok then
        return nil, err
    end
    return finish_transaction(ledger, working)
end

local function matching_selection_source(ledger, route)
    local source_record = source_record_by_original(
        ledger,
        route.life_id,
        route.selection_ref
    )
    return source_record and source_record.source_record or nil
end

note_unclassified_on = function(ledger, route_id, refs, code)
    return append_error_on(ledger, assert(instrument_error(
        "ledger",
        code or "promotion_classification_unavailable",
        "edge_stats_v3.promotion",
        route_id,
        refs
    )))
end

decision_matches_selection = function(decision, selection)
    if not decision or not selection
        or selection.classification_status ~= "classified"
        or type(selection.eligibility) ~= "table" then
        return false
    end
    local eligibility = selection.eligibility
    return decision.route_evidence_id == selection.route_evidence_id
        and decision.selection_eligibility_ref == eligibility.eligibility_ref
        and same_value(decision.reasons, eligibility.reasons)
        and decision.status == (eligibility.status == "eligible"
            and "credited" or "rejected")
end

local function taint_from_bundle(bundle, route_id)
    for _, descriptor in ipairs(bundle and bundle.records or {}) do
        local record = descriptor.source_record
        if type(record) == "table" and record.kind == "authority_taint"
            and record.route_evidence_id == route_id
            and tagged_hash(record.record_id) then
            return record
        end
    end
    return nil
end

local function record_transition_on(ledger, commit, bundle)
    if not commit_valid(commit) then
        return nil, instrument_error("identity", "route_commit_invalid",
            "edge_stats_v3.record_transition")
    end
    local route = ledger.routes[commit.route_evidence_id]
    local selection = route and matching_selection_source(ledger, route) or nil
    local committed_direction = topology.resolve(commit.from)
        and topology.resolve(commit.to)
        and (topology.resolve(commit.from) .. "->" .. topology.resolve(commit.to))
        or nil
    if not route or route.commit_ref ~= nil
        or commit.selection_ref ~= route.selection_ref
        or committed_direction ~= route.direction
        or (selection and (
            topology.resolve(commit.from) ~= topology.resolve(selection.from)
            or topology.resolve(commit.to) ~= topology.resolve(selection.to)
            or commit.route_authority ~= selection.route_authority
        ))
        or (not selection and ledger.ledger_status == "valid") then
        return nil, instrument_error("identity", "route_identity_mismatch",
            "edge_stats_v3.record_transition", commit.route_evidence_id)
    end
    local taint = taint_from_bundle(bundle, commit.route_evidence_id)
    local automatic = automatic_sources(commit, taint)
    local captured, capture_err = capture_bundle_on(
        ledger,
        bundle,
        route.life_id,
        automatic,
        commit.route_evidence_id
    )
    if not captured then
        return nil, capture_err
    end
    require_source_on(ledger, route.life_id, commit.record_id,
        commit.route_evidence_id)
    require_source_on(ledger, route.life_id, commit.route_trace_ref,
        commit.route_evidence_id)
    if taint then
        require_source_on(ledger, route.life_id, taint.record_id,
            commit.route_evidence_id)
        route.authority_taint_ref = taint.record_id
    end
    route.commit_ref = commit.record_id
    route.phase_status = "committed"
    local directional, edge = direction_for(
        ledger,
        commit.from,
        commit.to
    )
    directional.physical.committed_count =
        directional.physical.committed_count + 1
    append_unique(directional.physical.committed_refs, commit.record_id)
    if selection and selection.classification_status == "classified"
        and selection.eligibility.status == "eligible"
        and ledger.ledger_status == "valid" then
        directional.promotion.eligible_committed_count =
            directional.promotion.eligible_committed_count + 1
        append_unique(
            directional.promotion.eligible_committed_refs,
            commit.record_id
        )
    end
    refresh_edge(edge, ledger.ledger_status)
    return true
end

function stats.record_transition(ledger, commit, bundle)
    local working, working_err = working_state(ledger)
    if not working then
        return nil, working_err
    end
    local ok, err = record_transition_on(working, commit, bundle)
    if not ok then
        return nil, err
    end
    return finish_transaction(ledger, working)
end

local function phase_direction(ledger, route)
    local definition = edge_catalog.get(route.edge_id)
    if not definition then
        return nil
    end
    return ledger.edges[definition.edge].directions[route.direction],
        ledger.edges[definition.edge]
end

local function record_arrival_on(ledger, arrival, decision, bundle)
    if not arrival_valid(arrival) or not decision_valid(decision, arrival) then
        return nil, instrument_error("identity", "route_arrival_invalid",
            "edge_stats_v3.record_arrival")
    end
    local route = ledger.routes[arrival.route_evidence_id]
    if not route or route.commit_ref ~= arrival.commit_ref
        or route.arrival_ref or route.failure_ref or route.pending_ref then
        return nil, instrument_error("identity", "route_identity_mismatch",
            "edge_stats_v3.record_arrival", arrival.route_evidence_id)
    end
    local automatic = automatic_sources(arrival, decision)
    local captured, capture_err = capture_bundle_on(
        ledger,
        bundle,
        route.life_id,
        automatic,
        arrival.route_evidence_id
    )
    if not captured then
        return nil, capture_err
    end
    require_source_on(ledger, route.life_id, arrival.record_id,
        arrival.route_evidence_id)
    require_source_on(ledger, route.life_id, arrival.destination_tick_ref,
        arrival.route_evidence_id)
    for _, ref in ipairs(arrival.effect_refs) do
        require_source_on(ledger, route.life_id, ref, arrival.route_evidence_id)
    end
    if decision then
        require_source_on(ledger, route.life_id, decision.credit_decision_ref,
            arrival.route_evidence_id)
    end
    route.arrival_ref = arrival.record_id
    route.credit_decision_ref = decision and decision.credit_decision_ref or nil
    route.phase_status = "executed"
    local directional, edge = phase_direction(ledger, route)
    directional.physical.executed_count =
        directional.physical.executed_count + 1
    append_unique(directional.physical.executed_refs, arrival.record_id)
    increment(directional.physical.arrival_kinds, arrival.payload_kind)
    local selection = matching_selection_source(ledger, route)
    if decision then
        append_unique(
            directional.promotion.credit_decision_refs,
            decision.credit_decision_ref
        )
    end
    if ledger.ledger_status == "valid"
        and not decision_matches_selection(decision, selection) then
        local refs = {arrival.record_id}
        if decision then
            refs[#refs + 1] = decision.credit_decision_ref
        end
        local noted, note_err = note_unclassified_on(
            ledger,
            arrival.route_evidence_id,
            refs,
            "credit_decision_unresolved"
        )
        if not noted then
            return nil, note_err
        end
    end
    if ledger.ledger_status == "valid"
        and selection.eligibility.status == "eligible" then
        directional.promotion.eligible_executed_count =
            directional.promotion.eligible_executed_count + 1
        append_unique(
            directional.promotion.eligible_executed_refs,
            arrival.record_id
        )
    elseif ledger.ledger_status == "valid" then
        directional.promotion.ineligible_executed_count =
            directional.promotion.ineligible_executed_count + 1
        append_unique(
            directional.promotion.rejected_route_refs,
            arrival.route_evidence_id
        )
        for _, reason in ipairs(selection.eligibility.reasons) do
            increment(directional.promotion.rejected_reason_counts, reason)
        end
    else
        directional.promotion.unclassified_executed_count =
            directional.promotion.unclassified_executed_count + 1
    end
    refresh_edge(edge, ledger.ledger_status)
    return true
end

function stats.record_arrival(ledger, arrival, decision, bundle)
    local working, working_err = working_state(ledger)
    if not working then
        return nil, working_err
    end
    local ok, err = record_arrival_on(working, arrival, decision, bundle)
    if not ok then
        return nil, err
    end
    return finish_transaction(ledger, working)
end

local function record_failure_on(ledger, failure, bundle)
    if not failure_valid(failure) then
        return nil, instrument_error("identity", "route_failure_invalid",
            "edge_stats_v3.record_failure")
    end
    local route = ledger.routes[failure.route_evidence_id]
    if not route or route.commit_ref ~= failure.commit_ref
        or route.arrival_ref or route.failure_ref or route.pending_ref then
        return nil, instrument_error("identity", "route_identity_mismatch",
            "edge_stats_v3.record_failure", failure.route_evidence_id)
    end
    local captured, capture_err = capture_bundle_on(
        ledger,
        bundle,
        route.life_id,
        automatic_sources(failure),
        failure.route_evidence_id
    )
    if not captured then
        return nil, capture_err
    end
    require_source_on(ledger, route.life_id, failure.record_id,
        failure.route_evidence_id)
    require_source_on(ledger, route.life_id, failure.destination_tick_ref,
        failure.route_evidence_id)
    require_source_on(ledger, route.life_id, failure.failure_ref,
        failure.route_evidence_id)
    route.failure_ref = failure.record_id
    route.phase_status = "failed"
    local directional, edge = phase_direction(ledger, route)
    directional.physical.failed_count = directional.physical.failed_count + 1
    append_unique(directional.physical.failure_refs, failure.record_id)
    increment(directional.physical.failure_kinds, failure.failure_kind)
    refresh_edge(edge, ledger.ledger_status)
    return true
end

function stats.record_failure(ledger, failure, bundle)
    local working, working_err = working_state(ledger)
    if not working then
        return nil, working_err
    end
    local ok, err = record_failure_on(working, failure, bundle)
    if not ok then
        return nil, err
    end
    return finish_transaction(ledger, working)
end

local function record_pending_on(ledger, pending, bundle)
    if not pending_valid(pending) then
        return nil, instrument_error("identity", "route_pending_invalid",
            "edge_stats_v3.record_pending")
    end
    local route = ledger.routes[pending.route_evidence_id]
    if not route or route.commit_ref ~= pending.commit_ref
        or route.arrival_ref or route.failure_ref or route.pending_ref then
        return nil, instrument_error("identity", "route_identity_mismatch",
            "edge_stats_v3.record_pending", pending.route_evidence_id)
    end
    local captured, capture_err = capture_bundle_on(
        ledger,
        bundle,
        route.life_id,
        automatic_sources(pending),
        pending.route_evidence_id
    )
    if not captured then
        return nil, capture_err
    end
    require_source_on(ledger, route.life_id, pending.record_id,
        pending.route_evidence_id)
    route.pending_ref = pending.record_id
    route.phase_status = "pending_at_host_ceiling"
    local directional, edge = phase_direction(ledger, route)
    directional.physical.pending_at_host_ceiling_count =
        directional.physical.pending_at_host_ceiling_count + 1
    append_unique(directional.physical.pending_refs, pending.record_id)
    refresh_edge(edge, ledger.ledger_status)
    return true
end

function stats.record_pending(ledger, pending, bundle)
    local working, working_err = working_state(ledger)
    if not working then
        return nil, working_err
    end
    local ok, err = record_pending_on(working, pending, bundle)
    if not ok then
        return nil, err
    end
    return finish_transaction(ledger, working)
end

local function merge_error(code, refs)
    return instrument_error(
        "merge",
        code,
        "edge_stats_v3.merge",
        nil,
        refs
    )
end

local function unknown_reason_in_sources(ledger)
    for _, evidence in pairs(ledger.evidence_records or {}) do
        local record = evidence.source_record
        if evidence.source_kind == "edge_credit" and type(record) == "table"
            and (record.kind == "edge_credit_selection_eligibility"
                or record.kind == "edge_credit_decision") then
            for _, reason in ipairs(record.reasons or {}) do
                if not edge_credit.is_eligibility_reason(reason) then
                    return reason
                end
            end
        end
    end
    for _, edge in pairs(ledger.edges or {}) do
        for _, directional in pairs(edge.directions or {}) do
            for reason in pairs(
                directional.promotion
                    and directional.promotion.rejected_reason_counts or {}
            ) do
                if not edge_credit.is_eligibility_reason(reason) then
                    return reason
                end
            end
        end
    end
    return nil
end

local function merge_preflight(target, source)
    if type(target) ~= "table" or type(source) ~= "table"
        or target.kind ~= "edge_statistics"
        or source.kind ~= "edge_statistics"
        or target.protocol_version ~= stats.protocol_version
        or source.protocol_version ~= stats.protocol_version then
        return nil, merge_error("edge_stats_protocol_mismatch")
    end
    local unknown = unknown_reason_in_sources(target)
        or unknown_reason_in_sources(source)
    if unknown then
        return nil, merge_error("unknown_eligibility_reason", {unknown})
    end
    local target_ok = stats.verify(target)
    local source_ok = stats.verify(source)
    if not target_ok or not source_ok then
        return nil, merge_error("source_evidence_conflict")
    end
    if target.ledger_status ~= "valid" or source.ledger_status ~= "valid" then
        return nil, merge_error("source_evidence_unresolved")
    end
    if not target.authority_epoch or not source.authority_epoch then
        return nil, merge_error("authority_epoch_missing")
    end
    if target.evidence_epoch_id ~= source.evidence_epoch_id then
        return nil, merge_error("evidence_epoch_mismatch")
    end
    if not same_value(target.authority_epoch, source.authority_epoch) then
        return nil, merge_error("authority_epoch_invalid")
    end
    if not same_value(target.edge_order, source.edge_order) then
        return nil, merge_error("authority_surface_mismatch")
    end
    for life_id in pairs(source.source_lives) do
        if target.source_lives[life_id] then
            return nil, merge_error("life_source_overlap", {life_id})
        end
    end
    for ref in pairs(source.evidence_records) do
        if target.evidence_records[ref] then
            return nil, merge_error("source_evidence_conflict", {ref})
        end
    end
    for route_id in pairs(source.routes) do
        if target.routes[route_id] then
            return nil, merge_error("source_evidence_conflict", {route_id})
        end
    end
    return true
end

local function add_counter_fields(target, source, fields)
    for _, key in ipairs(fields) do
        target[key] = target[key] + source[key]
    end
end

local function merge_counter_map(target, source)
    for key, value in pairs(source) do
        target[key] = (target[key] or 0) + value
    end
end

local function merge_ref_list(target, source)
    for _, value in ipairs(source) do
        append_unique(target, value)
    end
end

local physical_counter_fields = {
    "candidate_count",
    "selected_count",
    "committed_count",
    "executed_count",
    "failed_count",
    "pending_at_host_ceiling_count",
}

local promotion_counter_fields = {
    "eligible_selected_count",
    "eligible_committed_count",
    "eligible_executed_count",
    "ineligible_executed_count",
    "unclassified_executed_count",
}

local physical_ref_fields = {
    "derivation_refs",
    "selected_refs",
    "committed_refs",
    "executed_refs",
    "failure_refs",
    "pending_refs",
}

local promotion_ref_fields = {
    "eligible_derivation_refs",
    "eligible_committed_refs",
    "eligible_executed_refs",
    "credit_decision_refs",
    "rejected_route_refs",
}

local observer_counter_fields = {
    "comparison_count",
    "agreement_count",
    "divergence_count",
    "no_prediction_count",
    "unavailable_count",
}

local rail_counter_fields = {
    "cases",
    "target_count",
    "reference_eye_count",
    "eye_debt_cases",
    "eye_target_count",
    "debt_eye_target_count",
    "fresh_eye_target_count",
    "debt_bypass_count",
    "fresh_direct_count",
    "no_target_count",
}

local function merge_on(target, source)
    add_counter_fields(target.source_usage, source.source_usage, {
        "record_count",
        "encoded_bytes",
        "omitted_record_count",
        "omitted_encoded_bytes",
    })
    for life_id, life in pairs(source.source_lives) do
        target.source_lives[life_id] = copy_value(life)
        target.source_index[life_id] = copy_value(source.source_index[life_id])
    end
    for ref, evidence in pairs(source.evidence_records) do
        target.evidence_records[ref] = copy_value(evidence)
    end
    for route_id, route in pairs(source.routes) do
        target.routes[route_id] = copy_value(route)
    end

    add_counter_fields(target, source, {
        "comparison_count",
        "tree_derivation_count",
        "tree_no_viable_count",
    })
    merge_counter_map(target.tree_outcome_counts, source.tree_outcome_counts)
    for observer_id, source_observer in pairs(source.observers) do
        local target_observer = target.observers[observer_id]
        add_counter_fields(
            target_observer,
            source_observer,
            observer_counter_fields
        )
        merge_counter_map(
            target_observer.outcome_counts,
            source_observer.outcome_counts
        )
    end
    for rail_id, source_rail in pairs(source.rails) do
        local target_rail = target.rails[rail_id]
        for channel_id, source_channel in pairs(source_rail.channels) do
            add_counter_fields(
                target_rail.channels[channel_id],
                source_channel,
                rail_counter_fields
            )
        end
    end
    for edge_key, source_edge in pairs(source.edges) do
        local target_edge = target.edges[edge_key]
        for direction_key, source_direction in pairs(source_edge.directions) do
            local target_direction = target_edge.directions[direction_key]
            add_counter_fields(
                target_direction.physical,
                source_direction.physical,
                physical_counter_fields
            )
            add_counter_fields(
                target_direction.promotion,
                source_direction.promotion,
                promotion_counter_fields
            )
            for _, key in ipairs(physical_ref_fields) do
                merge_ref_list(
                    target_direction.physical[key],
                    source_direction.physical[key]
                )
            end
            for _, key in ipairs(promotion_ref_fields) do
                merge_ref_list(
                    target_direction.promotion[key],
                    source_direction.promotion[key]
                )
            end
            for _, key in ipairs({
                "authority_counts", "arrival_kinds", "failure_kinds",
            }) do
                merge_counter_map(
                    target_direction.physical[key],
                    source_direction.physical[key]
                )
            end
            merge_counter_map(
                target_direction.promotion.rejected_reason_counts,
                source_direction.promotion.rejected_reason_counts
            )
        end
    end
    return target
end

function stats.merge(target, source)
    local preflight, preflight_err = merge_preflight(target, source)
    if not preflight then
        return nil, preflight_err
    end
    local working = copy_value(target)
    merge_on(working, source)
    for _, edge in pairs(working.edges) do
        refresh_edge(edge, working.ledger_status)
    end
    local verified = stats.verify(working)
    if not verified then
        return nil, merge_error("invalid_counter_subset")
    end
    replace_contents(target, working)
    return target
end

return stats
