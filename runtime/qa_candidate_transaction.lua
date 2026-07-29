local qa_process = require("runtime.qa_process")
local qa_schema = require("core.qa_schema")
local repository_capability = require("runtime.repository_capability")
local repository_inventory = require("runtime.repository_inventory")

local transaction = {
    protocol_version = "qa.candidate_transaction_runtime.v0",
}

local plan_keys = {
    protocol_version = true,
    transaction_kind = true,
    physical_transaction_id = true,
    physical_witness_id = true,
    profile_id = true,
    environment_id = true,
    repository_id = true,
    root_authority_id = true,
    lifecycle_id = true,
    root_fingerprint = true,
    closure_id = true,
    closure_request_id = true,
    candidate_seal_id = true,
    candidate_seal_event_ref = true,
    inventory_id = true,
    inventory_digest = true,
    inventory_bounds = true,
    native_request = true,
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

local function exact_plan(value)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, "QA candidate transaction plan must be a plain table"
    end
    for key in pairs(value) do
        if not plan_keys[key] then
            return nil, "QA candidate transaction plan contains unknown key: "
                .. tostring(key)
        end
    end
    for key in pairs(plan_keys) do
        if value[key] == nil then
            return nil, "QA candidate transaction plan is missing key: " .. key
        end
    end
    if value.protocol_version ~= "qa.candidate_transaction_plan.v0"
        or (value.transaction_kind ~= "provider_witness"
            and value.transaction_kind ~= "body_execution") then
        return nil, "QA candidate transaction plan envelope is invalid"
    end
    for _, key in ipairs({
        "physical_transaction_id", "physical_witness_id", "profile_id",
        "environment_id", "repository_id", "root_authority_id",
        "lifecycle_id", "root_fingerprint", "closure_id",
        "closure_request_id", "candidate_seal_id",
        "candidate_seal_event_ref", "inventory_id", "inventory_digest",
    }) do
        if type(value[key]) ~= "string" or value[key] == "" then
            return nil, "QA candidate transaction coordinate is invalid: " .. key
        end
    end
    local bounds, bounds_err = repository_inventory.normalize_bounds(
        value.inventory_bounds)
    if not bounds then
        return nil, bounds_err
    end
    local request, request_err = qa_process.normalize_request_v1(
        value.native_request)
    if not request then
        return nil, request_err
    end
    if request.transaction_id ~= value.physical_transaction_id
        or request.witness_id ~= value.physical_witness_id
        or request.profile_id ~= value.profile_id
        or request.environment_id ~= value.environment_id
        or value.profile_id ~= qa_schema.profile_id then
        return nil, "QA candidate transaction native identity mismatch"
    end
    local normalized = copy_value(value)
    normalized.inventory_bounds = bounds
    normalized.native_request = request
    return normalized
end

local function inventory_observation(provider, handle, registry, lease, plan)
    if type(provider) ~= "table"
        or type(provider.inventory_tree) ~= "function" then
        return nil, "root-bound repository inventory provider is invalid", "trusted"
    end
    local raw, provider_err = provider.inventory_tree(
        handle,
        copy_value(plan.inventory_bounds)
    )
    if not raw then
        return nil, provider_err or "repository inventory failed", "provider"
    end
    local root_ok, root_err =
        repository_capability.qa_source_inventory_root_matches(
            registry, lease, raw.root_before, raw.root_after)
    if root_ok ~= true then
        return nil, root_err or "QA source inventory root changed",
            root_ok == nil and "trusted" or "identity"
    end
    local normalized, normalize_err, normalize_class =
        repository_inventory.normalize_provider_result(raw, {
            request_id = plan.closure_request_id,
            root_fingerprint = plan.root_fingerprint,
            inventory_bounds = plan.inventory_bounds,
            root_continuity = "proven",
        })
    if not normalized then
        return nil, normalize_err,
            normalize_class == "malformed" and "trusted" or normalize_class
    end
    if normalized.status ~= "observed" or not normalized.inventory then
        return nil, "QA source inventory is not an exact observation", "world"
    end
    return normalized
end

local function matches_seal(observation, plan)
    local inventory = observation and observation.inventory
    return type(inventory) == "table"
        and inventory.inventory_id == plan.inventory_id
        and inventory.inventory_digest == plan.inventory_digest
        and repository_inventory.same(
            inventory.inventory_bounds,
            plan.inventory_bounds
        )
end

local function source_disposition(plan, state, reason)
    return {
        protocol_version = "repository.qa_source_disposition.v0",
        transaction_id = plan.physical_transaction_id,
        state = state,
        reason = reason,
        event_truth_status = "runtime_confirmed",
    }
end

local function run_candidate(with_environment, handle, plan)
    if type(with_environment) ~= "function" then
        return nil, "measured QA environment callback is required"
    end
    local joined, joined_err = with_environment(function(provider, measured)
        if type(provider) ~= "table" or type(provider.run) ~= "function"
            or type(measured) ~= "table"
            or measured.environment_id ~= plan.environment_id
            or measured.profile_id ~= plan.profile_id
            or measured.provider_id ~= qa_schema.provider_id
            or measured.supervisor_abi ~= qa_schema.supervisor_abi then
            error("measured QA provider/environment pair changed", 0)
        end
        local process, process_err = provider.run(
            handle,
            copy_value(plan.native_request)
        )
        return {
            process = copy_value(process),
            process_error = copy_value(process_err),
        }
    end)
    if not joined then
        return nil, joined_err or "measured QA environment callback failed"
    end
    if type(joined) ~= "table" then
        return nil, "measured QA environment callback returned invalid data"
    end
    return joined
end

local function pending_error(disposition, code, class, stage, process,
        source_stable, loud, detail)
    return {
        kind = "error",
        disposition = disposition,
        loud = loud,
        code = code,
        class = class,
        stage = stage,
        process = process,
        source_stable = source_stable,
        detail = detail,
    }
end

function transaction.execute(repository_registry, source_lease, supplied_plan,
        with_environment)
    local plan, plan_err = exact_plan(supplied_plan)
    if not plan then
        return nil, plan_err
    end

    local pending, callback_err = repository_capability.with_qa_source(
        repository_registry,
        source_lease,
        function(handle, repository_provider)
            local pre, pre_err, pre_class = inventory_observation(
                repository_provider,
                handle,
                repository_registry,
                source_lease,
                plan
            )
            if not pre then
                local trusted = pre_class == "trusted"
                    or pre_class == "identity"
                return pending_error(
                    trusted and "quarantined" or "consumed",
                    trusted and "trusted_inventory_contradiction"
                        or "source_preflight_unavailable",
                    trusted and "ambiguous" or "world",
                    "preflight",
                    nil,
                    false,
                    trusted,
                    pre_err
                )
            end
            if not matches_seal(pre, plan) then
                return pending_error(
                    "consumed",
                    "source_preflight_mismatch",
                    "world",
                    "preflight",
                    nil,
                    true
                )
            end

            local process_join, process_join_err = run_candidate(
                with_environment,
                handle,
                plan
            )
            if not process_join then
                error("QA candidate environment callback failed: "
                    .. tostring(process_join_err), 0)
            end
            local process = process_join.process
            local process_err = process_join.process_error

            local post, post_err, post_class = inventory_observation(
                repository_provider,
                handle,
                repository_registry,
                source_lease,
                plan
            )
            if not post or not repository_inventory.same(
                pre.inventory, post.inventory) then
                local trusted = post_class == "trusted"
                    or post_class == "identity"
                return pending_error(
                    "quarantined",
                    trusted and "trusted_inventory_contradiction"
                        or "source_drift",
                    "ambiguous",
                    "postflight",
                    process or process_err,
                    false,
                    trusted,
                    post_err
                )
            end
            if process then
                return {
                    kind = "report",
                    disposition = "consumed",
                    process = process,
                    pre_inventory_id = pre.inventory.inventory_id,
                    post_inventory_id = post.inventory.inventory_id,
                }
            end
            if type(process_err) ~= "table"
                or process_err.protocol_version
                    ~= "qa.provider_process_error.v1" then
                error("QA provider returned an invalid process error", 0)
            end
            local reuse_class, topology_err =
                qa_process.error_reuse_class_v1(process_err)
            if reuse_class == nil then
                error("QA provider returned an invalid process error topology: "
                    .. tostring(topology_err), 0)
            end
            return pending_error(
                reuse_class == "clean_prestart" and "consumed" or "quarantined",
                process_err.code,
                process_err.class,
                process_err.stage,
                process_err,
                true
            )
        end
    )

    if not pending then
        local finished, finish_err = repository_capability.finish_qa_source(
            repository_registry,
            source_lease,
            source_disposition(
                plan,
                "quarantined",
                "candidate_transaction_callback_failed"
            )
        )
        if not finished then
            error("QA candidate transaction cleanup failed: "
                .. tostring(finish_err), 0)
        end
        error("QA candidate transaction callback failed: "
            .. tostring(callback_err), 0)
    end

    local finish_reason = pending.disposition == "quarantined"
        and (pending.code or "candidate_transaction_ambiguous") or nil
    local finished, finish_err = repository_capability.finish_qa_source(
        repository_registry,
        source_lease,
        source_disposition(plan, pending.disposition, finish_reason)
    )
    if not finished then
        error("QA candidate transaction source finality failed: "
            .. tostring(finish_err), 0)
    end
    if pending.loud then
        error("QA candidate transaction trusted contradiction after finality: "
            .. tostring(pending.detail or pending.code), 0)
    end
    return copy_value(pending)
end

return transaction
