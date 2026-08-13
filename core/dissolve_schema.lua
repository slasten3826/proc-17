local digest = require("core.digest")
local network_schema = require("core.network_projection_schema")

local schema = {
    release_protocol = "dissolve.inherited_rejected_form_release.v0",
    residue_protocol = "dissolve.rejected_form_residue.v0",
    bounds = {
        max_refs = 256,
        max_ref_bytes = 4096,
    },
}

local reason_keys = {
    kind = true,
    subtype = true,
    network_projection_id = true,
    carrier_id = true,
    source_corpse_id = true,
    historical_qa_id = true,
    candidate_seal_id = true,
    verdict_id = true,
}

local release_keys = {
    protocol_version = true,
    release_id = true,
    target = true,
    reason = true,
    residue_unit_id = true,
    released_mass = true,
    irreversible_identity_loss = true,
    source_refs = true,
    event_truth_status = true,
    content_truth_status = true,
}

local target_keys = {
    kind = true,
    id = true,
    before_version = true,
    after_version = true,
    before_activation = true,
    after_activation = true,
}

local released_mass_keys = {
    forms = true,
    relations = true,
}

local residue_keys = {
    protocol_version = true,
    source_packet_id = true,
    source_corpse_id = true,
    source_generation = true,
    historical_qa_id = true,
    candidate_seal_id = true,
    qa_contract_id = true,
    verdict_id = true,
    rejected_check_refs = true,
    failure_summary = true,
    release_id = true,
    ancestor_evidence_truth_status = true,
    prior_applicability_truth_status = true,
    release_truth_status = true,
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

local function same_value(left, right, seen)
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return left == right
    end
    seen = seen or {}
    if seen[left] ~= nil then
        return seen[left] == right
    end
    seen[left] = right
    for key, value in pairs(left) do
        if not same_value(value, right[key], seen) then
            return false
        end
    end
    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function exact_record(value, allowed, optional, label)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " must be a plain table"
    end
    optional = optional or {}
    for key in pairs(value) do
        if not allowed[key] then
            return nil, label .. " contains unknown key: " .. tostring(key)
        end
    end
    for key in pairs(allowed) do
        if value[key] == nil and not optional[key] then
            return nil, label .. " is missing key: " .. key
        end
    end
    return true
end

local function bounded_string(value, label, maximum)
    maximum = maximum or schema.bounds.max_ref_bytes
    if type(value) ~= "string" or value == "" or #value > maximum
        or value:find("[%z\1-\31\127]") or utf8.len(value) == nil then
        return nil, label .. " must be bounded control-free UTF-8"
    end
    return value
end

local function positive_integer(value, label)
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, label .. " must be an integer >= 1"
    end
    return value
end

local function prefixed_digest(value, prefix)
    return type(value) == "string" and #value == #prefix + 64
        and value:sub(1, #prefix) == prefix
        and value:sub(#prefix + 1):match("^[0-9a-f]+$") ~= nil
end

local function valid_unit_id(value)
    if type(value) ~= "string" then
        return false
    end
    local suffix = value:match("^unit:(%d+)$")
    return suffix ~= nil and tonumber(suffix) >= 1
        and tostring(tonumber(suffix)) == suffix
end

local function dense_array_shape(value, label)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " must be a dense array"
    end
    local count, maximum = 0, 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            return nil, label .. " must be a dense array"
        end
        count = count + 1
        maximum = math.max(maximum, key)
    end
    if count ~= maximum then
        return nil, label .. " must be a dense array"
    end
    return true
end

local function normalize_refs(value, label)
    local shape, shape_err = dense_array_shape(value, label)
    if not shape then
        return nil, shape_err
    end
    if #value == 0 or #value > schema.bounds.max_refs then
        return nil, label .. " has an invalid item count"
    end
    local result, seen = {}, {}
    for index, ref in ipairs(value) do
        local normalized, ref_err = bounded_string(
            ref,
            label .. "[" .. tostring(index) .. "]"
        )
        if not normalized then
            return nil, ref_err
        end
        if not seen[normalized] then
            seen[normalized] = true
            result[#result + 1] = normalized
        end
    end
    table.sort(result)
    return result
end

local function contains_ref(refs, expected)
    for _, ref in ipairs(refs or {}) do
        if ref == expected then
            return true
        end
    end
    return false
end

local function normalize_identity(value, key, prefix)
    local projected = copy_value(value)
    projected[key] = nil
    local hash, hash_err = digest.record(projected)
    if not hash then
        return nil, hash_err
    end
    local expected = prefix .. hash
    if value[key] ~= nil and value[key] ~= expected then
        return nil, key .. " identity mismatch"
    end
    projected[key] = expected
    return projected
end

function schema.normalize_inherited_reason(value)
    local exact, exact_err = exact_record(
        value,
        reason_keys,
        nil,
        "DISSOLVE inherited reason"
    )
    if not exact then
        return nil, exact_err
    end
    if value.kind ~= "rejected" or value.subtype ~= "ancestor_candidate"
        or not prefixed_digest(
            value.network_projection_id,
            "network-projection:"
        )
        or not prefixed_digest(value.historical_qa_id, "qa-history:")
        or not prefixed_digest(value.candidate_seal_id, "candidate-seal:")
        or not prefixed_digest(value.verdict_id, "qa-verdict:") then
        return nil, "DISSOLVE inherited reason identity is invalid"
    end
    for _, key in ipairs({"carrier_id", "source_corpse_id"}) do
        local _, string_err = bounded_string(
            value[key],
            "DISSOLVE inherited reason " .. key
        )
        if string_err then
            return nil, string_err
        end
    end
    return copy_value(value)
end

local function normalize_target(value)
    local exact, exact_err = exact_record(
        value,
        target_keys,
        nil,
        "DISSOLVE release target"
    )
    if not exact then
        return nil, exact_err
    end
    if value.kind ~= "unit" or not valid_unit_id(value.id)
        or (value.before_activation ~= "live"
            and value.before_activation ~= "selected")
        or value.after_activation ~= "dissolved" then
        return nil, "DISSOLVE release target is invalid"
    end
    local before, before_err = positive_integer(
        value.before_version,
        "DISSOLVE target before_version"
    )
    if not before then
        return nil, before_err
    end
    if value.after_version ~= before + 1 then
        return nil, "DISSOLVE target version transition is invalid"
    end
    return copy_value(value)
end

function schema.normalize_release(value)
    local exact, exact_err = exact_record(
        value,
        release_keys,
        {release_id = true},
        "DISSOLVE release"
    )
    if not exact then
        return nil, exact_err
    end
    if value.protocol_version ~= schema.release_protocol
        or value.irreversible_identity_loss ~= 0
        or value.event_truth_status ~= "runtime_confirmed"
        or value.content_truth_status ~= "mixed"
        or not valid_unit_id(value.residue_unit_id) then
        return nil, "DISSOLVE release envelope is invalid"
    end
    local target, target_err = normalize_target(value.target)
    if not target then
        return nil, target_err
    end
    if target.id == value.residue_unit_id then
        return nil, "DISSOLVE residue cannot alias its target"
    end
    local reason, reason_err = schema.normalize_inherited_reason(value.reason)
    if not reason then
        return nil, reason_err
    end
    local mass_ok, mass_err = exact_record(
        value.released_mass,
        released_mass_keys,
        nil,
        "DISSOLVE released mass"
    )
    if not mass_ok then
        return nil, mass_err
    end
    if value.released_mass.forms ~= 1 or value.released_mass.relations ~= 0 then
        return nil, "DISSOLVE released mass is invalid"
    end
    local refs, refs_err = normalize_refs(
        value.source_refs,
        "DISSOLVE release source_refs"
    )
    if not refs then
        return nil, refs_err
    end
    for _, required in ipairs({
        reason.network_projection_id,
        reason.carrier_id,
        reason.source_corpse_id,
        reason.historical_qa_id,
        reason.candidate_seal_id,
        reason.verdict_id,
        table.concat({
            "coverage",
            "field_unit",
            target.id,
            tostring(target.before_version),
        }, ":"),
    }) do
        if not contains_ref(refs, required) then
            return nil, "DISSOLVE release omits required ref: " .. required
        end
    end
    local normalized = {
        protocol_version = schema.release_protocol,
        release_id = value.release_id,
        target = target,
        reason = reason,
        residue_unit_id = value.residue_unit_id,
        released_mass = {forms = 1, relations = 0},
        irreversible_identity_loss = 0,
        source_refs = refs,
        event_truth_status = "runtime_confirmed",
        content_truth_status = "mixed",
    }
    return normalize_identity(normalized, "release_id", "dissolve-release:")
end

function schema.release_identity(value_without_release_id)
    local prepared = copy_value(value_without_release_id)
    prepared.release_id = nil
    local normalized, normalized_err = schema.normalize_release(prepared)
    if not normalized then
        return nil, normalized_err
    end
    return normalized.release_id
end

function schema.normalize_residue_carrier(value)
    local exact, exact_err = exact_record(
        value,
        residue_keys,
        nil,
        "DISSOLVE rejected-form residue"
    )
    if not exact then
        return nil, exact_err
    end
    if value.protocol_version ~= schema.residue_protocol
        or not prefixed_digest(value.historical_qa_id, "qa-history:")
        or not prefixed_digest(value.candidate_seal_id, "candidate-seal:")
        or not prefixed_digest(value.qa_contract_id, "qa-contract:")
        or not prefixed_digest(value.verdict_id, "qa-verdict:")
        or not prefixed_digest(value.release_id, "dissolve-release:")
        or value.ancestor_evidence_truth_status ~= "runtime_confirmed"
        or value.prior_applicability_truth_status ~= "inherited_proposal"
        or value.release_truth_status ~= "runtime_confirmed" then
        return nil, "DISSOLVE rejected-form residue envelope is invalid"
    end
    for _, key in ipairs({"source_packet_id", "source_corpse_id"}) do
        local _, string_err = bounded_string(
            value[key],
            "DISSOLVE residue " .. key
        )
        if string_err then
            return nil, string_err
        end
    end
    local generation, generation_err = positive_integer(
        value.source_generation,
        "DISSOLVE residue source_generation"
    )
    if not generation then
        return nil, generation_err
    end
    local check_refs, check_refs_err = normalize_refs(
        value.rejected_check_refs,
        "DISSOLVE residue rejected_check_refs"
    )
    if not check_refs then
        return nil, check_refs_err
    end
    local failure, failure_err = network_schema.normalize_failure_summary(
        value.failure_summary
    )
    if not failure then
        return nil, failure_err
    end
    return {
        protocol_version = schema.residue_protocol,
        source_packet_id = value.source_packet_id,
        source_corpse_id = value.source_corpse_id,
        source_generation = generation,
        historical_qa_id = value.historical_qa_id,
        candidate_seal_id = value.candidate_seal_id,
        qa_contract_id = value.qa_contract_id,
        verdict_id = value.verdict_id,
        rejected_check_refs = check_refs,
        failure_summary = failure,
        release_id = value.release_id,
        ancestor_evidence_truth_status = "runtime_confirmed",
        prior_applicability_truth_status = "inherited_proposal",
        release_truth_status = "runtime_confirmed",
    }
end

local function verify_normalized(value, normalizer, label)
    local normalized, normalized_err = normalizer(value)
    if not normalized then
        return nil, normalized_err
    end
    if not same_value(value, normalized) then
        return nil, label .. " is not normalized"
    end
    return true
end

function schema.verify_inherited_reason(value)
    return verify_normalized(
        value,
        schema.normalize_inherited_reason,
        "DISSOLVE inherited reason"
    )
end

function schema.verify_release(value)
    return verify_normalized(
        value,
        schema.normalize_release,
        "DISSOLVE release"
    )
end

function schema.verify_residue_carrier(value)
    return verify_normalized(
        value,
        schema.normalize_residue_carrier,
        "DISSOLVE rejected-form residue"
    )
end

function schema.same(left, right)
    return same_value(left, right)
end

return schema
