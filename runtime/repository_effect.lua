local digest = require("core.digest")
local packet_core = require("core.packet")
local body = require("runtime.body")
local repository_action = require("runtime.repository_action")
local capabilities = require("runtime.repository_capability")
local substrate_contract = require("substrates.contract")

local repository_effect = {
    protocol_version = "repository.effect_result.v0",
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

local function exact_record(value, allowed, required, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, name .. " must be a plain table"
    end
    for key in pairs(value) do
        if not allowed[key] then
            return nil, name .. " contains unknown key: " .. tostring(key)
        end
    end
    for key in pairs(required or allowed) do
        if value[key] == nil then
            return nil, name .. " is missing key: " .. key
        end
    end
    return true
end

local function non_negative_integer(value)
    return type(value) == "number" and value >= 0 and value == math.floor(value)
end

local function non_negative_number(value)
    return type(value) == "number" and value >= 0
        and value == value and value < math.huge
end

local cost_keys = {tool_calls = true, file_writes = true, time_ms = true}
local root_keys = {device = true, inode = true}
local create_result_keys = {
    protocol_version = true, operation = true, outcome = true, bytes = true,
    root = true, mutation_primitive_entered = true, published = true, cost = true,
}
local read_result_keys = {
    protocol_version = true, operation = true, outcome = true,
    target_kind = true, bytes = true, content = true, root = true,
    mutation_primitive_entered = true, published = true, cost = true,
}
local read_required_keys = {
    protocol_version = true, operation = true, outcome = true,
    target_kind = true, root = true, mutation_primitive_entered = true,
    published = true, cost = true,
}
local provider_error_keys = {
    protocol_version = true, class = true, code = true, stage = true,
    errno = true, mutation_primitive_entered = true, published = true,
    cost = true, residue = true,
}
local provider_error_required = {
    protocol_version = true, class = true, code = true, stage = true,
    mutation_primitive_entered = true, published = true, cost = true,
}
local provider_residue_keys = {
    protocol_version = true, kind = true, relative_name = true,
}

local function validate_cost(value, expected_calls, expected_writes, name)
    local valid, valid_err = exact_record(value, cost_keys, cost_keys, name)
    if not valid then
        return nil, valid_err
    end
    if value.tool_calls ~= expected_calls or value.file_writes ~= expected_writes
        or not non_negative_integer(value.tool_calls)
        or not non_negative_integer(value.file_writes)
        or not non_negative_number(value.time_ms) then
        return nil, name .. " contains impossible economics"
    end
    return copy_value(value)
end

local function validate_root(registry, lease, value, name)
    local valid, valid_err = exact_record(value, root_keys, root_keys, name)
    if not valid then
        return nil, valid_err
    end
    if not non_negative_integer(value.device) or not non_negative_integer(value.inode) then
        return nil, name .. " contains invalid identity"
    end
    local matches, match_err = capabilities.effect_root_matches(registry, lease, value)
    if matches == nil then
        return nil, match_err
    end
    if not matches then
        return nil, name .. " contradicts granted root identity"
    end
    return true
end

local function validate_create_result(registry, lease, action, value)
    local valid, valid_err = exact_record(value, create_result_keys,
        create_result_keys, "repository create result")
    if not valid then
        return nil, valid_err
    end
    local root_ok, root_err = validate_root(registry, lease, value.root,
        "repository create root")
    if not root_ok then
        return nil, root_err
    end
    local cost, cost_err = validate_cost(value.cost, 1, 1,
        "repository create cost")
    if not cost then
        return nil, cost_err
    end
    if value.protocol_version ~= "repository.provider_result.v0"
        or value.operation ~= "create_text_file" or value.outcome ~= "created"
        or value.bytes ~= action.content.bytes
        or value.mutation_primitive_entered ~= true or value.published ~= true then
        return nil, "repository create result contradicts exact action"
    end
    local result = copy_value(value)
    result.cost = cost
    return result
end

local function validate_read_result(registry, lease, action, value)
    local valid, valid_err = exact_record(value, read_result_keys,
        read_required_keys, "repository read result")
    if not valid then
        return nil, valid_err
    end
    local root_ok, root_err = validate_root(registry, lease, value.root,
        "repository read root")
    if not root_ok then
        return nil, root_err
    end
    local cost, cost_err = validate_cost(value.cost, 1, 0,
        "repository read cost")
    if not cost then
        return nil, cost_err
    end
    if value.protocol_version ~= "repository.provider_result.v0"
        or value.operation ~= "read_text_file" or value.outcome ~= "observed"
        or (value.target_kind ~= "regular_file" and value.target_kind ~= "missing"
            and value.target_kind ~= "other")
        or value.mutation_primitive_entered ~= false or value.published ~= false then
        return nil, "repository read result contradicts exact observation"
    end
    if value.target_kind == "regular_file" then
        if not non_negative_integer(value.bytes)
            or type(value.content) ~= "string" or #value.content ~= value.bytes then
            return nil, "repository read result contains invalid bounded bytes"
        end
    elseif value.bytes ~= nil or value.content ~= nil then
        return nil, "repository read result exposes bytes for non-regular target"
    end
    local result = copy_value(value)
    result.cost = cost
    return result
end

local function validate_provider_error(value)
    local valid, valid_err = exact_record(value, provider_error_keys,
        provider_error_required, "repository provider error")
    if not valid then
        return nil, valid_err
    end
    if value.protocol_version ~= "repository.provider_error.v0"
        or (value.class ~= "world" and value.class ~= "ambiguous"
            and value.class ~= "contract")
        or type(value.code) ~= "string" or value.code == ""
        or type(value.stage) ~= "string" or value.stage == ""
        or type(value.mutation_primitive_entered) ~= "boolean"
        or (type(value.published) ~= "boolean"
            and not (value.class == "ambiguous" and value.published == "unknown")) then
        return nil, "repository provider returned malformed error"
    end
    if value.errno ~= nil and (not non_negative_integer(value.errno) or value.errno == 0) then
        return nil, "repository provider returned invalid errno"
    end
    if type(value.cost) ~= "table" then
        return nil, "repository provider failure cost must be a plain table"
    end
    local cost, cost_err = validate_cost(value.cost, value.cost.tool_calls,
        value.cost.file_writes, "repository provider failure cost")
    if not cost then
        return nil, cost_err
    end
    if value.class == "contract" then
        return nil, "repository provider reported trusted contract failure: "
            .. value.stage .. "/" .. value.code
    end
    if value.residue ~= nil then
        local residue_ok, residue_err = exact_record(
            value.residue,
            provider_residue_keys,
            provider_residue_keys,
            "repository provider residue"
        )
        if not residue_ok then
            return nil, residue_err
        end
        if value.class ~= "ambiguous"
            or value.residue.protocol_version ~= "repository.provider_residue.v0"
            or value.residue.kind ~= "reserved_temp"
            or type(value.residue.relative_name) ~= "string"
            or #value.residue.relative_name ~= 44
            or not value.residue.relative_name:match("^%.proc17%-tmp%-%x+$") then
            return nil, "repository provider returned malformed residue"
        end
    end
    local result = copy_value(value)
    result.cost = cost
    return result
end

local function merge_cost(left, right)
    return {
        tool_calls = (left and left.tool_calls or 0) + (right and right.tool_calls or 0),
        file_writes = (left and left.file_writes or 0) + (right and right.file_writes or 0),
        time_ms = (left and left.time_ms or 0) + (right and right.time_ms or 0),
    }
end

local function capability_failure(value)
    local code = type(value) == "table" and value.code or nil
    local mapped = {
        revoked_capability = "grant_revoked",
        grant_revoked = "grant_revoked",
        quarantined_capability = "grant_quarantined",
        grant_quarantined = "grant_quarantined",
        missing_capability = "grant_missing",
        ambiguous_capability = "grant_ambiguous",
        action_already_dispatched = "action_already_dispatched",
        effect_limit_exhausted = "effect_limit_exhausted",
        capability_bounds_exceeded = "capability_bounds_exceeded",
    }
    if not mapped[code] then
        return nil
    end
    return substrate_contract.effect_failure({
        source = "sandbox",
        code = mapped[code],
        message = type(value.message) == "string" and value.message or mapped[code],
        retryability = (code == "grant_revoked" or code == "revoked_capability"
            or code == "grant_quarantined" or code == "quarantined_capability")
            and "terminal" or "unknown",
        cost = {},
    })
end

local function provider_failure(value, prior_cost)
    local validated, validation_err = validate_provider_error(value)
    if not validated then
        return nil, validation_err
    end
    return substrate_contract.effect_failure({
        source = "sandbox",
        code = validated.code,
        message = validated.stage .. "/" .. validated.code,
        retryability = validated.class == "ambiguous" and "terminal" or "unknown",
        cost = merge_cost(prior_cost, validated.cost),
        detail = validated,
    }), validated
end

local function unique_refs(...)
    local result, seen = {}, {}
    for _, source in ipairs({...}) do
        if type(source) == "string" then
            source = {source}
        end
        for _, ref in ipairs(source or {}) do
            if type(ref) == "string" and ref ~= "" and not seen[ref] then
                seen[ref] = true
                result[#result + 1] = ref
            end
        end
    end
    return result
end

local function call_boundary(fn, ...)
    local called = table.pack(pcall(fn, ...))
    if called[1] ~= true then
        return nil, "repository provider invariant failure: " .. tostring(called[2]), true
    end
    return called[2], called[3], false
end

function repository_effect.execute(instance, action, registry)
    local actor, actor_err = packet_core.assert_actor_tick(instance, "☶",
        "execute repository effect")
    if not actor then
        return nil, actor_err
    end

    local request, materialized_or_err = repository_action.materialize(
        instance, action, registry)
    if not request then
        return nil, capability_failure(materialized_or_err) or materialized_or_err
    end

    local target_digest, target_err = digest.record({
        root_fingerprint = action.capability.root_fingerprint,
        relative_path = action.target.relative_path,
        precondition = action.target.precondition,
    })
    if not target_digest then
        return nil, target_err
    end
    local target_ref = "repository-target:" .. target_digest
    local attempt_digest, attempt_err = digest.record({
        action_id = action.action_id,
        tick_ref = actor.id,
        target_ref = target_ref,
    })
    if not attempt_digest then
        return nil, attempt_err
    end
    local attempt, attempt_event = body.record_repository_effect_attempt(instance, {
        protocol_version = "repository.effect_attempt.v0",
        attempt_id = "repository-attempt:" .. attempt_digest,
        action_id = action.action_id,
        grant_id = action.capability.grant_id,
        grant_revision = action.capability.revision,
        operation = "create_text_file",
        target_ref = target_ref,
        work_unit_id = action.work_unit.id,
        work_unit_version = action.work_unit.version,
        source_refs = unique_refs(action.action_id, action.scope_refs, action.provenance_refs),
        event_truth_status = "runtime_confirmed",
    })
    if not attempt then
        return nil, attempt_event
    end

    local lease, lease_err = capabilities.begin_effect(registry, action, instance)
    if not lease then
        return nil, capability_failure(lease_err) or lease_err
    end

    local create_result, create_err, create_panicked = call_boundary(
        capabilities.effect_create, registry, lease, request)
    if create_panicked then
        return nil, create_err
    end
    if not create_result then
        if type(create_err) ~= "table" then
            return nil, create_err
        end
        local failure, validated_or_err = provider_failure(create_err)
        if not failure then
            return nil, validated_or_err
        end
        if validated_or_err.class == "ambiguous"
            or validated_or_err.published == "unknown" then
            local quarantined, quarantine_err = capabilities.quarantine_effect(
                registry, lease, validated_or_err)
            if not quarantined then
                return nil, "repository effect quarantine failed: " .. tostring(quarantine_err)
            end
        end
        return nil, failure
    end
    local writer, writer_err = validate_create_result(registry, lease, action, create_result)
    if not writer then
        return nil, writer_err
    end

    local receipt_digest, receipt_digest_err = digest.record({
        attempt_ref = attempt_event.id,
        result = writer,
        content_sha256 = action.content.sha256,
    })
    if not receipt_digest then
        return nil, receipt_digest_err
    end
    local receipt, receipt_event = body.record_repository_effect_receipt(instance, {
        protocol_version = "repository.effect_receipt.v0",
        receipt_id = "repository-receipt:" .. receipt_digest,
        attempt_id = attempt.attempt_id,
        action_id = action.action_id,
        grant_id = action.capability.grant_id,
        grant_revision = action.capability.revision,
        provider_id = action.capability.provider_id,
        operation = "create_text_file",
        outcome = "created",
        target = {
            relative_path = action.target.relative_path,
            kind = "regular_file",
        },
        provider_observation = {
            bytes = writer.bytes,
            sha256 = action.content.sha256,
        },
        cost = copy_value(writer.cost),
        source_refs = unique_refs(attempt_event.id, attempt.attempt_id,
            action.action_id, target_ref),
        event_truth_status = "runtime_confirmed",
        content_truth_status = action.content_truth_status,
    })
    if not receipt then
        return nil, receipt_event
    end

    local read_result, read_err, read_panicked = call_boundary(
        capabilities.effect_read_back, registry, lease)
    if read_panicked then
        return nil, read_err
    end
    if not read_result then
        if type(read_err) ~= "table" then
            return nil, read_err
        end
        local failure, validated_or_err = provider_failure(read_err, writer.cost)
        if not failure then
            return nil, validated_or_err
        end
        if validated_or_err.class == "ambiguous" then
            local quarantined, quarantine_err = capabilities.quarantine_effect(
                registry, lease, validated_or_err)
            if not quarantined then
                return nil, "repository effect quarantine failed: " .. tostring(quarantine_err)
            end
        end
        return nil, failure
    end
    local observed, observed_err = validate_read_result(
        registry, lease, action, read_result)
    if not observed then
        return nil, observed_err
    end

    local observed_projection = {}
    local verdict, reason = "rejected", "target_missing"
    if observed.target_kind == "regular_file" then
        local observed_sha, sha_err = digest.sha256(observed.content)
        if not observed_sha then
            return nil, sha_err
        end
        observed_projection = {bytes = observed.bytes, sha256 = observed_sha}
        if observed.bytes ~= action.content.bytes then
            reason = "content_length_mismatch"
        elseif observed_sha ~= action.content.sha256 then
            reason = "content_digest_mismatch"
        else
            verdict, reason = "accepted", "exact_content_observed"
        end
    elseif observed.target_kind == "other" then
        reason = "target_not_regular"
    end

    local verification_seed = {
        receipt_ref = receipt_event.id,
        action_id = action.action_id,
        observed = observed_projection,
        expected = {bytes = action.content.bytes, sha256 = action.content.sha256},
        verdict = verdict,
        reason = reason,
    }
    local verification_digest, verification_digest_err = digest.record(verification_seed)
    if not verification_digest then
        return nil, verification_digest_err
    end
    local verification, verification_event = body.record_repository_verification(instance, {
        protocol_version = "repository.verification.v0",
        verification_id = "repository-verification:" .. verification_digest,
        action_id = action.action_id,
        attempt_id = attempt.attempt_id,
        receipt_ref = receipt_event.id,
        grant_id = action.capability.grant_id,
        grant_revision = action.capability.revision,
        provider_id = action.capability.provider_id,
        target = {
            relative_path = action.target.relative_path,
            kind = observed.target_kind,
        },
        observed = observed_projection,
        expected = {
            bytes = action.content.bytes,
            sha256 = action.content.sha256,
        },
        verdict = verdict,
        reason = reason,
        cost = copy_value(observed.cost),
        source_refs = unique_refs(receipt_event.id, attempt_event.id,
            attempt.attempt_id, action.action_id),
        event_truth_status = "runtime_confirmed",
        content_truth_status = action.content_truth_status,
    })
    if not verification then
        return nil, verification_event
    end

    return copy_value({
        protocol_version = repository_effect.protocol_version,
        status = verdict,
        reason = reason,
        action_id = action.action_id,
        attempt_ref = attempt_event.id,
        receipt_ref = receipt_event.id,
        verification_ref = verification_event.id,
        receipt = receipt,
        verification = verification,
        cost = merge_cost(writer.cost, observed.cost),
        effect_scope_refs = assert(repository_action.route_scope(action)),
        truth_status = "runtime_confirmed",
        content_truth_status = action.content_truth_status,
    })
end

return repository_effect
