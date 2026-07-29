package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local capability = require("runtime.qa_capability")
local evidence = require("runtime.qa_evidence")
local qa_environment = require("runtime.qa_environment")
local qa_request = require("runtime.qa_request")
local repository_capability = require("runtime.repository_capability")
local fixture = require("tests.support.qa_hand")

local suite = H.new("qa-capability-body")

local function request_event(grown)
    local request = assert(qa_request.prepare(grown.instance, {
        qa_environment = grown.qa_environment,
    }))
    local stored, event = assert(evidence.record_request(
        grown.instance,
        request
    ))
    return stored, event
end

local function mint(grown)
    local request, event = request_event(grown)
    local grant = assert(capability.mint(
        grown.qa_registry,
        grown.instance,
        request,
        event.id
    ))
    return grant, request, event
end

suite:check("M2.2 mint binds one grown request without execution", function()
    local grown = fixture.grow_body({label = "qa-grant-mint"})
    local grant, request, event = mint(grown)
    H.assert_eq(grant.protocol_version, "qa.execution_grant.v1",
        "exact grant protocol")
    H.assert_eq(grant.request_id, request.request_id, "grant binds request")
    H.assert_eq(grant.request_ref, event.id, "grant binds body event")
    H.assert_eq(grant.state, "active", "mint creates active authority")
    H.assert_eq(grown.qa_adapter_state.runs, 0, "mint launches nothing")
    local replay = assert(capability.mint(
        grown.qa_registry,
        grown.instance,
        request,
        event.id
    ))
    H.assert_eq(replay.grant_id, grant.grant_id, "mint replay reuses grant")
    H.assert_eq(replay.revision, grant.revision, "mint replay writes no revision")
    grant.state = "forged"
    H.assert_eq(capability.mint(
        grown.qa_registry,
        grown.instance,
        request,
        event.id
    ).state, "active", "detached grant has no authority")
end)

suite:check("M2.2 mint requires exact request event", function()
    local grown = fixture.grow_body({label = "qa-grant-no-event"})
    local request = assert(qa_request.prepare(grown.instance, {
        qa_environment = grown.qa_environment,
    }))
    local grant = capability.mint(
        grown.qa_registry,
        grown.instance,
        request,
        "event:missing"
    )
    H.assert_nil(grant, "proposal without body fact grants nothing")
    local _, event = assert(evidence.record_request(grown.instance, request))
    grant = capability.mint(
        grown.qa_registry,
        grown.instance,
        request,
        "event:wrong"
    )
    H.assert_nil(grant, "wrong event reference grants nothing")
    H.assert_true(event.id ~= "event:wrong", "fixture event is distinct")
    H.assert_eq(grown.qa_adapter_state.runs, 0, "denials launch nothing")
end)

suite:check("M2.2 begin is sticky before every provider boundary", function()
    local grown = fixture.grow_body({label = "qa-grant-begin"})
    local grant = mint(grown)
    local lease, state = assert(capability.begin(
        grown.qa_registry,
        grant.request_id,
        grant.request_ref
    ))
    H.assert_true(type(lease) == "table", "begin returns opaque lease")
    H.assert_eq(state.state, "running", "begin consumes active authority")
    H.assert_eq(state.physical_transaction_id:sub(1, 24),
        "qa-provider-transaction:", "begin derives native correlation")
    local second, denial = capability.begin(
        grown.qa_registry,
        grant.request_id,
        grant.request_ref
    )
    H.assert_nil(second, "second begin denied")
    H.assert_eq(denial.code, "grant_not_active", "denial names sticky state")
    H.assert_eq(grown.qa_adapter_state.runs, 0, "begin enters no provider")
    H.assert_nil(capability.begin(grant, grant.request_id, grant.request_ref),
        "detached grant cannot impersonate registry")
end)

suite:check("M2.2 stale environment leaves grant active", function()
    local grown = fixture.grow_body({label = "qa-grant-stale-environment"})
    local grant, request, event = mint(grown)
    assert(qa_environment.quarantine(
        grown.qa_environment_registry,
        grown.qa_environment.environment_id,
        "fixture environment retired"
    ))
    local lease, denial = capability.begin(
        grown.qa_registry,
        grant.request_id,
        grant.request_ref
    )
    H.assert_nil(lease, "stale environment prevents begin")
    H.assert_eq(denial.code, "environment_lease_stale",
        "denial names measured lease")
    local replay = assert(capability.mint(
        grown.qa_registry,
        grown.instance,
        request,
        event.id
    ))
    H.assert_eq(replay.state, "active", "begin denial does not consume grant")
    H.assert_eq(replay.revision, grant.revision,
        "begin denial writes no grant revision")
    H.assert_eq(grown.qa_adapter_state.runs, 0, "stale lease launches nothing")
end)

suite:check("M2.2 execution callback is one-use and carries exact context", function()
    local grown = fixture.grow_body({label = "qa-execution-context"})
    local grant = mint(grown)
    local lease = assert(capability.begin(
        grown.qa_registry,
        grant.request_id,
        grant.request_ref
    ))
    local observed
    local result = assert(capability.with_execution(
        grown.qa_registry,
        lease,
        function(context, environment_lease, environment_registry,
                repository_registry)
            observed = fixture.copy(context)
            H.assert_true(type(environment_lease) == "table",
                "callback receives opaque measured lease")
            H.assert_true(environment_registry == grown.qa_environment_registry,
                "callback receives exact environment registry")
            H.assert_true(repository_registry == grown.repository_registry,
                "callback receives exact repository registry")
            return {
                protocol_version = "fixture.qa_pending.v0",
                transaction_id = context.physical_transaction_id,
            }
        end
    ))
    H.assert_eq(result.transaction_id, observed.physical_transaction_id,
        "detached pending data keeps physical identity")
    H.assert_eq(observed.source_binding.qa_request_id, grant.request_id,
        "source binding carries body request")
    H.assert_eq(observed.native_request.witness_id:sub(1, 20),
        "qa-provider-witness:", "native witness identity is derived")
    local forged_binding = fixture.copy(observed.source_binding)
    forged_binding.transaction_id = "qa-provider-transaction:"
        .. string.rep("0", 64)
    H.assert_nil(repository_capability.reserve_qa_source(
        grown.repository_registry,
        forged_binding
    ), "repository registry independently rejects forged body digest")
    H.assert_nil(capability.with_execution(
        grown.qa_registry,
        lease,
        function() return {} end
    ), "execution callback cannot run twice")
    H.assert_eq(grown.qa_adapter_state.runs, 0,
        "registry callback alone runs no candidate")
end)

suite:check("M2.2 private authority cannot escape callback", function()
    local grown = fixture.grow_body({label = "qa-execution-leak"})
    local grant = mint(grown)
    local lease = assert(capability.begin(
        grown.qa_registry,
        grant.request_id,
        grant.request_ref
    ))
    local result, err = capability.with_execution(
        grown.qa_registry,
        lease,
        function(_, _, _, repository_registry)
            return {repository_registry = repository_registry}
        end
    )
    H.assert_nil(result, "private registry leak denied")
    H.assert_true(err ~= nil, "leak denial is loud")
    H.assert_nil(capability.begin(
        grown.qa_registry,
        grant.request_id,
        grant.request_ref
    ), "failed callback does not reactivate grant")
    H.assert_eq(grown.qa_adapter_state.runs, 0, "leak attempt launches nothing")
end)

suite:finish()
print("test_qa_capability_body ok")
