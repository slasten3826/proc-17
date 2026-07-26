package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local digest = require("core.digest")
local fixture = require("tests.support.repository_hands")
local capabilities = require("runtime.repository_capability")
local candidate_seal = require("runtime.candidate_seal")
local logic = require("organs.logic")
local repository_action = require("runtime.repository_action")
local repository_intent = require("runtime.repository_intent")
local work_completion = require("runtime.work_completion")
local suite = H.new("qa-source-bridge")

local function grown_candidate(label)
    local instance = fixture.packet({{
        path = "src/main.lua",
        content = "return 'sealed source'\n",
    }}, {label = label})
    local intent = assert(repository_intent.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local registry, grant, provider, state = fixture.new_registry(capabilities)
    local action = assert(repository_action.authorize(instance, intent, registry, {
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        repository_id = instance.repository_id,
        work_mode = "build",
    }))
    fixture.move_to(instance, "☶")
    local _, validation = assert(logic.run(instance, {
        work_mode = "build",
        repository_effect = {action = action},
    }, {repository_capabilities = registry}))
    fixture.move_to(instance, "☱")
    local completion = assert(work_completion.derive(instance, {
        action = action,
        attempt_ref = validation.attempt_ref,
        receipt_ref = validation.receipt_ref,
        verification_ref = validation.verification_ref,
        validation_ref = validation.trace_event_id,
    }))
    assert(work_completion.record(instance, completion))
    local result = {
        instance = instance,
        registry = registry,
        grant = grant,
        provider = provider,
        state = state,
        services = {repository_capabilities = registry},
    }
    return result
end

local function seal(grown)
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")
    local result = assert(candidate_seal.execute(
        grown.instance,
        request,
        grown.services
    ))
    return result
end

local function identify_provider_binding(value)
    local seed = H.copy(value)
    seed.transaction_id = nil
    seed.event_truth_status = nil
    seed.qa_request_id = nil
    seed.protocol_version = "qa.provider_source_transaction_seed.v0"
    return "qa-provider-transaction:" .. assert(digest.record(seed))
end

local function binding(grown, sealed)
    local value = sealed.seal
    local closure = sealed.closure
    local result = {
        protocol_version = "repository.qa_source_binding.v1",
        transaction_kind = "provider_witness",
        session_id = grown.instance.session_id,
        lineage_id = value.lineage_id,
        generation = value.generation,
        repository_id = value.repository_id,
        root_authority_id = value.root_authority_id,
        lifecycle_id = value.lifecycle_id,
        root_fingerprint = value.root_fingerprint,
        closure_id = closure.closure_id,
        candidate_seal_id = value.candidate_seal_id,
        candidate_seal_event_ref = sealed.seal_event_ref,
        closure_request_id = value.request_id,
        inventory_id = value.inventory_id,
        inventory_digest = value.inventory_digest,
        inventory_bounds = H.copy(value.inventory_bounds),
        transaction_id = nil,
        event_truth_status = "runtime_confirmed",
    }
    result.transaction_id = identify_provider_binding(result)
    return result
end

local function disposition(transaction_id, state, reason)
    return {
        protocol_version = "repository.qa_source_disposition.v0",
        transaction_id = transaction_id,
        state = state,
        reason = reason,
        event_truth_status = "runtime_confirmed",
    }
end

suite:check("QA-R01 source authority does not exist before terminal seal", function()
    local grown = grown_candidate("qa-source-before-seal")
    local root = assert(capabilities.root_authority(grown.registry, {
        grant_id = grown.grant.grant_id,
    }))
    local value = {
        protocol_version = "repository.qa_source_binding.v1",
        transaction_kind = "provider_witness",
        session_id = grown.instance.session_id,
        lineage_id = grown.instance.lineage_id,
        generation = grown.instance.generation,
        repository_id = grown.instance.repository_id,
        root_authority_id = root.root_authority_id,
        lifecycle_id = root.lifecycle_id,
        root_fingerprint = root.root_fingerprint,
        closure_id = "candidate-closure:absent",
        candidate_seal_id = "candidate-seal:absent",
        candidate_seal_event_ref = "trace:absent",
        closure_request_id = "candidate-seal-request:absent",
        inventory_id = "candidate-inventory:absent",
        inventory_digest = "sha256:absent",
        inventory_bounds = H.copy(candidate_seal.default_inventory_bounds),
        transaction_id = nil,
        event_truth_status = "runtime_confirmed",
    }
    value.transaction_id = identify_provider_binding(value)
    local lease, err = capabilities.reserve_qa_source(grown.registry, value)
    H.assert_nil(lease, "unsealed root grants no QA source")
    H.assert_eq(err.code, "repository_candidate_not_sealed",
        "denial names terminal seal requirement")
end)

suite:check("QA-R02 exact sealed identities reserve one opaque lease", function()
    local grown = grown_candidate("qa-source-exact")
    local sealed = seal(grown)
    local exact = binding(grown, sealed)
    local foreign = H.copy(exact)
    foreign.generation = foreign.generation + 1
    foreign.transaction_id = identify_provider_binding(foreign)
    local denied, denied_err = capabilities.reserve_qa_source(
        grown.registry,
        foreign
    )
    H.assert_nil(denied, "foreign generation is denied")
    H.assert_eq(denied_err.code, "repository_qa_source_binding_mismatch",
        "denial is typed")

    local lease = assert(capabilities.reserve_qa_source(grown.registry, exact))
    H.assert_true(type(lease) == "table", "private lease is opaque table")
    H.assert_nil(next(lease), "lease carries no public fields")
    H.assert_eq(getmetatable(lease), "repository.qa_source_lease.v0",
        "lease metatable is protected")

    local replay, replay_err = capabilities.reserve_qa_source(
        grown.registry,
        binding(grown, sealed)
    )
    H.assert_nil(replay, "second transaction cannot reserve sealed source")
    H.assert_eq(replay_err.code, "repository_qa_source_already_reserved",
        "foreign transaction is denied by sticky reservation")
end)

suite:check("SB02-SB08 source binding v1 rejects ambiguous identities", function()
    local grown = grown_candidate("qa-source-binding-v1")
    local sealed = seal(grown)
    local exact = binding(grown, sealed)

    local old = H.copy(exact)
    old.protocol_version = "repository.qa_source_binding.v0"
    local old_lease, old_err = capabilities.reserve_qa_source(grown.registry, old)
    H.assert_nil(old_lease, "v0 source binding is not a compatibility input")
    H.assert_contains(old_err, "protocol", "v0 denial names protocol")

    local polluted = H.copy(exact)
    polluted.qa_request_id = "qa-check-request:foreign"
    local polluted_lease, polluted_err = capabilities.reserve_qa_source(
        grown.registry, polluted)
    H.assert_nil(polluted_lease, "provider witness cannot carry QA request")
    H.assert_contains(polluted_err, "cannot carry", "mode mismatch is explicit")

    local body = H.copy(exact)
    body.transaction_kind = "body_execution"
    body.transaction_id = "qa-execution-transaction:exact"
    local body_lease, body_err = capabilities.reserve_qa_source(
        grown.registry, body)
    H.assert_nil(body_lease, "body execution requires a body request identity")
    H.assert_contains(body_err, "qa_request_id", "missing body request is explicit")

    local swapped = H.copy(exact)
    swapped.closure_request_id = "qa-check-request:not-a-closure-request"
    swapped.transaction_id = identify_provider_binding(swapped)
    local swapped_lease, swapped_err = capabilities.reserve_qa_source(
        grown.registry, swapped)
    H.assert_nil(swapped_lease, "QA request cannot replace closure request")
    H.assert_eq(swapped_err.code, "repository_qa_source_binding_mismatch",
        "private closure detects request vocabulary substitution")

    local aliased = H.copy(exact)
    aliased.transaction_id = aliased.closure_request_id
    local aliased_lease, aliased_err = capabilities.reserve_qa_source(
        grown.registry, aliased)
    H.assert_nil(aliased_lease, "request identity cannot be transaction identity")
    H.assert_contains(aliased_err, "transaction identity mismatch",
        "transaction alias is rejected before reservation")

    local changed_bounds = H.copy(exact)
    changed_bounds.inventory_bounds.max_entries =
        changed_bounds.inventory_bounds.max_entries + 1
    changed_bounds.transaction_id = identify_provider_binding(changed_bounds)
    local bounds_lease, bounds_err = capabilities.reserve_qa_source(
        grown.registry, changed_bounds)
    H.assert_nil(bounds_lease, "bounds-only substitution cannot reserve source")
    H.assert_eq(bounds_err.code, "repository_qa_source_binding_mismatch",
        "private closure commits exact inventory bounds")
end)

suite:check("QA-R03/R04 callback is one-use and returns detached data only", function()
    local grown = grown_candidate("qa-source-detached")
    local close_calls = 0
    local close = grown.provider.close
    grown.provider.close = function(handle)
        close_calls = close_calls + 1
        return close(handle)
    end
    local sealed = seal(grown)
    local exact = binding(grown, sealed)
    local transaction_id = exact.transaction_id
    local lease = assert(capabilities.reserve_qa_source(
        grown.registry,
        exact
    ))
    H.assert_eq(close_calls, 0,
        "seal retains one private read-only source handle")

    local callback_calls = 0
    local result = assert(capabilities.with_qa_source(
        grown.registry,
        lease,
        function(handle)
            callback_calls = callback_calls + 1
            H.assert_true(handle ~= nil, "trusted callback receives private handle")
            return {
                protocol_version = "qa.source_probe.v0",
                status = "observed",
            }
        end
    ))
    H.assert_eq(callback_calls, 1, "consumer runs once")
    H.assert_eq(result.status, "observed", "detached result crosses boundary")
    result.status = "caller-mutated"

    local repeated, repeated_err = capabilities.with_qa_source(
        grown.registry,
        lease,
        function() return {status = "replayed"} end
    )
    H.assert_nil(repeated, "consumed lease never invokes a second callback")
    H.assert_contains(repeated_err, "already consumed", "replay is explicit")

    assert(capabilities.finish_qa_source(
        grown.registry,
        lease,
        disposition(transaction_id, "consumed")
    ))
    H.assert_eq(close_calls, 1, "finish closes the retained source exactly once")
    assert(capabilities.finish_qa_source(
        grown.registry,
        lease,
        disposition(transaction_id, "consumed")
    ))
    H.assert_eq(close_calls, 1, "exact finish replay is idempotent")

    local root = assert(capabilities.root_authority(grown.registry, {
        root_authority_id = sealed.seal.root_authority_id,
    }))
    H.assert_eq(root.state, "sealed", "QA consumption cannot reopen source root")
    H.assert_eq(root.active_grant_count, 0, "write grants stay closed")
end)

suite:check("QA-R03/R04 private handle leak fails sticky and leaves seal final", function()
    local grown = grown_candidate("qa-source-leak")
    local sealed = seal(grown)
    local exact = binding(grown, sealed)
    local transaction_id = exact.transaction_id
    local lease = assert(capabilities.reserve_qa_source(
        grown.registry,
        exact
    ))
    local leaked, leak_err = capabilities.with_qa_source(
        grown.registry,
        lease,
        function(handle) return handle end
    )
    H.assert_nil(leaked, "private repository handle never crosses callback")
    H.assert_contains(leak_err, "private authority", "leak denial is explicit")

    local replay, replay_err = capabilities.with_qa_source(
        grown.registry,
        lease,
        function() return {status = "replayed"} end
    )
    H.assert_nil(replay, "failed first result remains consumed")
    H.assert_contains(replay_err, "already consumed", "failure is sticky")
    assert(capabilities.finish_qa_source(
        grown.registry,
        lease,
        disposition(transaction_id, "quarantined", "private_result_rejected")
    ))

    local root = assert(capabilities.root_authority(grown.registry, {
        root_authority_id = sealed.seal.root_authority_id,
    }))
    H.assert_eq(root.state, "sealed", "leak attempt cannot rewrite final root")
    H.assert_eq(root.active_grant_count, 0, "leak attempt restores no write grant")
end)

suite:finish()
print("test_qa_source_bridge ok")
