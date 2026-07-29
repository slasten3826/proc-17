local candidate_seal = require("runtime.candidate_seal")
local carrier = require("runtime.carrier")
local completion = require("runtime.completion")
local corpse = require("runtime.corpse")
local lineage = require("runtime.lineage")
local network_ingress = require("runtime.network_ingress")
local packet = require("core.packet")
local qa_capability = require("runtime.qa_capability")
local qa_contract = require("runtime.qa_contract")
local qa_environment = require("runtime.qa_environment")
local qa_request = require("runtime.qa_request")
local qa_schema = require("core.qa_schema")
local fixture = require("tests.support.qa_hand")

local profile = qa_schema.profile()
assert(qa_schema.verify_profile(profile))
profile.shell = "allowed"
assert(qa_schema.verify_profile(profile) == nil)
assert(qa_schema.profile().shell == "forbidden")

local environment_v1_input = fixture.environment_input("schema-v1")
local environment_v1 = assert(qa_schema.normalize_environment_v1(
    environment_v1_input))
assert(qa_schema.verify_environment_v1(environment_v1))
assert(qa_schema.verify_environment(environment_v1))
local historical_v0 = fixture.copy(environment_v1_input)
historical_v0.protocol_version = qa_schema.environment_v0_protocol
historical_v0.runtime_heap_limit_bytes = nil
assert(qa_schema.normalize_environment(historical_v0) == nil)
local normalized_historical_v0 = assert(
    qa_schema.normalize_environment_v0(historical_v0))
assert(normalized_historical_v0.environment_id ~= environment_v1.environment_id)
local historical_adapter = fixture.native_adapter({
    environment = normalized_historical_v0,
})
local historical_registry = assert(qa_environment.new(
    "session-qa-historical-v0", historical_adapter))
local unavailable_old, unavailable_old_err = qa_environment.probe(
    historical_registry)
assert(unavailable_old == nil)
assert(unavailable_old_err.code == "environment_probe_invalid")
local wrong_heap = fixture.copy(environment_v1_input)
wrong_heap.runtime_heap_limit_bytes = wrong_heap.runtime_heap_limit_bytes + 1
assert(qa_schema.normalize_environment_v1(wrong_heap) == nil)
assert(qa_schema.runtime_heap_limit_bytes == 67108864)

local excessive = fixture.hard_limits()
excessive.stdout_bytes = excessive.stdout_bytes + 1
assert(qa_schema.normalize_limits(excessive) == nil)
local cyclic = fixture.hard_limits()
cyclic.self = cyclic
assert(qa_schema.normalize_limits(cyclic) == nil)

local adapter, adapter_state = fixture.native_adapter()
local environment_registry = assert(qa_environment.new(
    "session-qa-foundation",
    adapter
))
local environment = assert(qa_environment.probe(environment_registry))
assert(adapter_state.probes == 1)
local environment_lease = assert(qa_environment.resolve(
    environment_registry,
    environment.environment_id,
    environment.profile_id
))
assert(environment_lease.environment_id == environment.environment_id)
local validated_environment = assert(qa_environment.validate_lease(
    environment_registry, environment_lease))
assert(qa_schema.same(validated_environment, environment))
local callback_projection = assert(qa_environment.with_environment(
    environment_registry,
    environment_lease,
    function(exact_adapter, measured)
        assert(exact_adapter == adapter)
        return {
            environment_id = measured.environment_id,
            provider_id = exact_adapter.provider_id,
        }
    end
))
assert(callback_projection.environment_id == environment.environment_id)
assert(callback_projection.provider_id == environment.provider_id)
callback_projection.environment_id = "mutated"
assert(qa_environment.validate_lease(
    environment_registry, environment_lease).environment_id
    == environment.environment_id)
local leaked_environment, leaked_environment_err =
    qa_environment.with_environment(
        environment_registry,
        environment_lease,
        function(exact_adapter)
            return {borrowed = exact_adapter}
        end
    )
assert(leaked_environment == nil)
assert(tostring(leaked_environment_err):find("private authority", 1, true))
assert(qa_environment.resolve(
    environment,
    environment.environment_id,
    environment.profile_id
) == nil)

local contract = assert(qa_schema.normalize_contract(
    fixture.contract_input(environment, {
        lineage_id = "lineage-qa-foundation",
        stage_id = "stage:lineage-qa-foundation:1:build",
    })
))
local rebound = assert(qa_contract.bind_for_birth({
    work_mode = "build",
    lineage_id = contract.lineage_id,
    process_contract_id = contract.process_contract_id,
    context = contract.context,
    stage_id = contract.stage_id,
}, contract, environment))
assert(qa_schema.same(rebound, contract))
assert(not pcall(packet.new, "plan cannot inherit QA", {
    work_mode = "plan",
    qa_contract = contract,
}))
local grown = fixture.grow_sealed({
    label = "qa-foundation",
    lineage_id = contract.lineage_id,
    stage_id = contract.stage_id,
    qa_contract = contract,
})
assert(qa_contract.verify_birth(grown.instance))
assert(grown.instance.qa_contract ~= grown.instance.trace[1].payload.qa_contract)

local eligibility = assert(qa_contract.inspect_candidate(
    grown.instance,
    grown.seal,
    nil,
    environment
))
assert(eligibility.state == "ready")

local before = fixture.snapshot(grown.instance)
local request = assert(qa_request.prepare(grown.instance, {
    environment = environment,
}))
assert(qa_request.verify(grown.instance, request))
local after = fixture.snapshot(grown.instance)
assert(before.trace_count == after.trace_count)
assert(before.loss_remaining == after.loss_remaining)
assert(adapter_state.runs == 0)
assert(request.command == nil and request.executable == nil)
assert(request.argv == nil and request.environment == nil and request.cwd == nil)

local public_registry = {
    protocol_version = qa_capability.protocol_version,
}
assert(qa_capability.begin(public_registry, request.request_id, "trace:none") == nil)
local qa_registry = assert(qa_capability.new(
    "session-qa-foundation",
    environment_registry,
    grown.repository_registry
))
assert(qa_capability.mint(
    qa_registry,
    grown.instance,
    request,
    "trace:missing"
) == nil)
assert(adapter_state.runs == 0)

assert(packet.die(grown.instance, "budget_exhausted", {
    remaining_work = {"run exact QA"},
}))
local dead = assert(corpse.capture(grown.instance, {
    corpse_id = "corpse-qa-foundation-1",
}))
assert(corpse.verify(dead))
assert(dead.qa_contract_id == contract.qa_contract_id)
assert(qa_schema.same(dead.qa_contract, contract))

local family = assert(lineage.create("build and verify software", {
    lineage_id = dead.lineage_id,
    session_id = "session-qa-foundation",
    work_mode = "build",
    carrier = {max_bytes = 65536},
    budget = {steps = 100, generations = 4, carrier_bytes = 65536},
}))
family.status = "evaluating_terminal"
family.current_generation = dead.generation
family.current_packet_id = dead.packet_id
family.current_corpse_id = dead.corpse_id
local assessment = assert(completion.evaluate(family, dead))
assert(assessment.task_state == "unfinished")
assert(assessment.terminal_recoverable == true)
local recovery = assert(carrier.build_recovery(family, dead, assessment, {
    carrier_id = "carrier-qa-foundation-2",
}))
assert(carrier.verify(recovery))
assert(lineage.mark_continued(family, dead, recovery))
local ingress = assert(network_ingress.prepare(family, recovery))
local child = packet.new(ingress.prompt, ingress.packet_options)
assert(child.generation == 2)
assert(child.stage_id == grown.instance.stage_id)
assert(child.qa_contract_id == grown.instance.qa_contract_id)
assert(qa_contract.verify_birth(child))

local mutated = fixture.copy(child.qa_contract)
mutated.required_checks[1].resource_limits.stdout_bytes = 1
child.qa_contract = mutated
assert(qa_contract.verify_birth(child) == nil)

assert(qa_environment.quarantine(
    environment_registry,
    environment.environment_id,
    "fixture quarantine"
))
assert(qa_environment.resolve(
    environment_registry,
    environment.environment_id,
    environment.profile_id
) == nil)

local seal, seal_event = candidate_seal.current(grown.instance)
assert(seal and seal_event)

print("test_qa_foundation ok")
