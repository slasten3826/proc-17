local candidate_seal = require("runtime.candidate_seal")
local digest = require("core.digest")
local qa_schema = require("core.qa_schema")

local qa_contract = {
    protocol_version = "qa.contract_binding.v0",
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

local function sorted_unique(values)
    local result = {}
    local seen = {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function diagnostic(code, detail, refs)
    return {
        protocol_version = "qa.contract_diagnostic.v0",
        code = code,
        detail = detail or code,
        source_refs = sorted_unique(refs),
        event_truth_status = "runtime_confirmed",
    }
end

local function work_mode(instance)
    return instance and instance.regime and instance.regime.work
        and instance.regime.work.mode or instance and instance.metadata
        and instance.metadata.work_mode
end

local function birth_event(instance)
    local found
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.type == "birth" then
            if found then
                return nil, "Packet has more than one birth event"
            end
            found = event
        end
    end
    if not found then
        return nil, "Packet birth event is absent"
    end
    return found
end

function qa_contract.bind_for_birth(identity, authorized_policy, environment)
    if type(identity) ~= "table" or type(authorized_policy) ~= "table" then
        return nil, diagnostic("binding_input_invalid",
            "QA binding requires identity and authorized policy")
    end
    local environment_ok, environment_err = qa_schema.verify_environment(environment)
    if not environment_ok then
        return nil, diagnostic("environment_invalid", environment_err)
    end
    if identity.work_mode ~= nil and identity.work_mode ~= "build" then
        return nil, diagnostic("mode_not_applicable",
            "QA contract may bind only to build Packet birth")
    end
    local candidate = copy_value(authorized_policy)
    local coordinates = {
        lineage_id = identity.lineage_id,
        process_contract_id = identity.process_contract_id,
        context = identity.context or identity.work_context,
        stage_id = identity.stage_id,
    }
    for key, value in pairs(coordinates) do
        if candidate[key] ~= nil and candidate[key] ~= value then
            return nil, diagnostic("binding_coordinate_conflict",
                "authorized QA policy conflicts with " .. key)
        end
        candidate[key] = value
    end
    local check = candidate.required_checks and candidate.required_checks[1]
    if type(check) ~= "table" or check.environment_id ~= environment.environment_id then
        return nil, diagnostic("binding_environment_conflict",
            "QA policy does not name the exact measured environment")
    end
    local normalized, normalized_err = qa_schema.normalize_contract(candidate)
    if not normalized then
        return nil, diagnostic("binding_policy_invalid", normalized_err)
    end
    return copy_value(normalized)
end

function qa_contract.verify_birth(instance)
    if type(instance) ~= "table" then
        return nil, "Packet is required"
    end
    local mode = work_mode(instance)
    if mode == "plan" then
        if instance.qa_contract ~= nil or instance.qa_contract_id ~= nil
            or instance.metadata and instance.metadata.qa_contract_id ~= nil then
            return nil, "plan Packet contains forbidden QA contract authority"
        end
        return nil, "not_applicable"
    end
    if mode ~= "build" then
        return nil, "Packet work mode is invalid"
    end
    if instance.qa_contract == nil and instance.qa_contract_id == nil then
        return nil, "absent"
    end
    local normalized, normalized_err = qa_schema.normalize_contract(instance.qa_contract)
    if not normalized then
        return nil, "Packet QA contract is invalid: " .. tostring(normalized_err)
    end
    if not qa_schema.same(instance.qa_contract, normalized)
        or instance.qa_contract_id ~= normalized.qa_contract_id
        or type(instance.metadata) ~= "table"
        or instance.metadata.qa_contract_id ~= normalized.qa_contract_id then
        return nil, "Packet QA contract projections diverged"
    end
    if normalized.lineage_id ~= instance.lineage_id
        or normalized.process_contract_id ~= instance.process_contract_id
        or normalized.context ~= instance.work_context
        or normalized.stage_id ~= instance.stage_id then
        return nil, "Packet QA contract diverged from birth coordinates"
    end
    local birth, birth_err = birth_event(instance)
    if not birth then
        return nil, birth_err
    end
    local payload = birth.payload or {}
    if payload.qa_contract_id ~= normalized.qa_contract_id
        or not qa_schema.same(payload.qa_contract, normalized) then
        return nil, "Packet birth QA contract projection diverged"
    end
    return copy_value(normalized)
end

local function eligibility_record(instance)
    return {
        protocol_version = "qa.eligibility.v0",
        eligibility_id = nil,
        state = "not_ready",
        packet_id = instance and instance.id,
        lineage_id = instance and instance.lineage_id,
        generation = instance and instance.generation,
        stage_id = instance and instance.stage_id,
        repository_id = instance and instance.repository_id,
        candidate_seal_id = nil,
        artifact_alignment_id = nil,
        qa_contract_id = nil,
        check_id = nil,
        profile_id = nil,
        environment_id = nil,
        entrypoint_artifact_ref = nil,
        source_refs = {},
        missing_requirements = {},
        conflicting_refs = {},
        event_truth_status = "runtime_confirmed",
    }
end

local function finish_eligibility(value)
    value.source_refs = sorted_unique(value.source_refs)
    value.missing_requirements = sorted_unique(value.missing_requirements)
    value.conflicting_refs = sorted_unique(value.conflicting_refs)
    if #value.conflicting_refs > 0 then
        value.state = "conflict"
    elseif #value.missing_requirements > 0 then
        value.state = "not_ready"
    else
        value.state = "ready"
    end
    value.eligibility_id = nil
    local identity, identity_err = digest.record(value)
    if not identity then
        return nil, identity_err
    end
    value.eligibility_id = "qa-eligibility:" .. identity
    return copy_value(value)
end

function qa_contract.inspect_candidate(instance, seal, alignment, environment)
    if type(instance) ~= "table" or type(instance.id) ~= "string" then
        return nil, diagnostic("packet_invalid", "QA eligibility requires Packet")
    end
    local result = eligibility_record(instance)
    local birth = birth_event(instance)
    if birth then
        result.source_refs[#result.source_refs + 1] = birth.id
    end
    if work_mode(instance) ~= "build" or instance.status == "dead"
        or instance.status == "manifested" or instance.terminal ~= nil then
        result.missing_requirements[#result.missing_requirements + 1]
            = "living_build_packet"
    end
    if type(instance.repository_id) ~= "string" or instance.repository_id == "" then
        result.missing_requirements[#result.missing_requirements + 1]
            = "repository_identity"
    end

    local contract, contract_err = qa_contract.verify_birth(instance)
    if not contract then
        if contract_err == "absent" or contract_err == "not_applicable" then
            result.missing_requirements[#result.missing_requirements + 1]
                = "qa_contract"
        else
            result.conflicting_refs[#result.conflicting_refs + 1]
                = "qa-contract-birth:" .. tostring(contract_err)
        end
    else
        local check = contract.required_checks[1]
        result.qa_contract_id = contract.qa_contract_id
        result.check_id = check.check_id
        result.profile_id = check.profile_id
        result.environment_id = check.environment_id
        for _, ref in ipairs(contract.source_refs) do
            result.source_refs[#result.source_refs + 1] = ref
        end
        result.source_refs[#result.source_refs + 1] = contract.qa_contract_id
    end

    local current, current_event, current_err = candidate_seal.current(instance)
    local normalized_seal
    if seal ~= nil then
        local seal_ok, seal_err = candidate_seal.validate_record(instance, seal)
        if not seal_ok then
            result.conflicting_refs[#result.conflicting_refs + 1]
                = type(seal) == "table" and seal.candidate_seal_id
                    or "candidate-seal-invalid"
            result.conflicting_refs[#result.conflicting_refs + 1]
                = "candidate-seal-error:" .. tostring(seal_err)
        else
            normalized_seal = copy_value(seal)
        end
    elseif current then
        normalized_seal = current
    end
    if not current then
        if current_err == "candidate_seal_absent" then
            result.missing_requirements[#result.missing_requirements + 1]
                = "candidate_seal"
        else
            result.conflicting_refs[#result.conflicting_refs + 1]
                = "candidate-seal-current:" .. tostring(current_err)
        end
    elseif normalized_seal
        and normalized_seal.candidate_seal_id ~= current.candidate_seal_id then
        result.conflicting_refs[#result.conflicting_refs + 1]
            = normalized_seal.candidate_seal_id
        result.conflicting_refs[#result.conflicting_refs + 1]
            = current.candidate_seal_id
    end
    if current then
        result.candidate_seal_id = current.candidate_seal_id
        result.source_refs[#result.source_refs + 1] = current.candidate_seal_id
        result.source_refs[#result.source_refs + 1] = current_event and current_event.id
    end

    local exact_alignment
    if current and normalized_seal
        and normalized_seal.candidate_seal_id == current.candidate_seal_id then
        local derived, derived_err = candidate_seal.inspect_alignment(instance, current)
        if not derived then
            result.conflicting_refs[#result.conflicting_refs + 1]
                = "candidate-alignment-error:" .. tostring(derived_err)
        elseif alignment ~= nil and not qa_schema.same(alignment, derived) then
            result.conflicting_refs[#result.conflicting_refs + 1]
                = type(alignment) == "table" and alignment.alignment_id
                    or "candidate-alignment-invalid"
            result.conflicting_refs[#result.conflicting_refs + 1] = derived.alignment_id
        else
            exact_alignment = derived
            result.artifact_alignment_id = derived.alignment_id
            result.source_refs[#result.source_refs + 1] = derived.alignment_id
            for _, ref in ipairs(derived.source_refs or {}) do
                result.source_refs[#result.source_refs + 1] = ref
            end
            if derived.state ~= "aligned" then
                result.conflicting_refs[#result.conflicting_refs + 1]
                    = derived.alignment_id
            end
        end
    end

    if contract then
        local environment_ok, environment_err = qa_schema.verify_environment(environment)
        if not environment_ok then
            result.missing_requirements[#result.missing_requirements + 1]
                = "available_environment"
            if environment ~= nil then
                result.conflicting_refs[#result.conflicting_refs + 1]
                    = "qa-environment-error:" .. tostring(environment_err)
            end
        elseif environment.environment_id ~= result.environment_id
            or environment.profile_id ~= result.profile_id then
            result.conflicting_refs[#result.conflicting_refs + 1]
                = environment.environment_id
            result.conflicting_refs[#result.conflicting_refs + 1]
                = result.environment_id
        else
            result.source_refs[#result.source_refs + 1] = environment.environment_id
        end
    end

    if contract and current and exact_alignment
        and exact_alignment.state == "aligned" then
        local expected_path = contract.required_checks[1].entrypoint.relative_path
        local matches = {}
        for _, artifact in ipairs(current.artifacts or {}) do
            if artifact.relative_path == expected_path then
                matches[#matches + 1] = artifact
            end
        end
        if #matches == 0 then
            result.missing_requirements[#result.missing_requirements + 1]
                = "entrypoint_artifact"
        elseif #matches > 1 then
            result.conflicting_refs[#result.conflicting_refs + 1]
                = "entrypoint-duplicate:" .. expected_path
        else
            result.entrypoint_artifact_ref = matches[1].completion_ref
            result.source_refs[#result.source_refs + 1] = matches[1].completion_ref
            result.source_refs[#result.source_refs + 1] = matches[1].verification_ref
        end
    elseif contract then
        result.missing_requirements[#result.missing_requirements + 1]
            = "aligned_entrypoint_artifact"
    end

    return finish_eligibility(result)
end

return qa_contract
