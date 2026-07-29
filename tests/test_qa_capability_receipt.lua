package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local candidate_transaction = require("runtime.qa_candidate_transaction")
local capability = require("runtime.qa_capability")
local evidence = require("runtime.qa_evidence")
local qa_environment = require("runtime.qa_environment")
local private_result = require("runtime.qa_private_result")
local qa_request = require("runtime.qa_request")
local repository_capability = require("runtime.repository_capability")
local fixture = require("tests.support.qa_hand")

local suite = H.new("qa-capability-receipt")

local function run_private(options)
    local grown = fixture.grow_body(options)
    local request = assert(qa_request.prepare(grown.instance, {
        qa_environment = grown.qa_environment,
    }))
    local _, request_event = assert(evidence.record_request(
        grown.instance,
        request
    ))
    local grant = assert(capability.mint(
        grown.qa_registry,
        grown.instance,
        request,
        request_event.id
    ))
    local lease = assert(capability.begin(
        grown.qa_registry,
        request.request_id,
        request_event.id
    ))
    local exact_result = assert(capability.with_execution(
        grown.qa_registry,
        lease,
        function(context, environment_lease, environment_registry,
                repository_registry)
            local source_lease = assert(repository_capability.reserve_qa_source(
                repository_registry,
                context.source_binding
            ))
            local function with_environment(consumer)
                return qa_environment.with_environment(
                    environment_registry,
                    environment_lease,
                    consumer
                )
            end
            local pending = assert(candidate_transaction.execute(
                repository_registry,
                source_lease,
                context.candidate_transaction_plan,
                with_environment
            ))
            return assert(private_result.from_pending({
                request = context.request,
                physical_transaction_id = context.physical_transaction_id,
                physical_witness_id = context.physical_witness_id,
                inventory_id = context.seal.inventory_id,
            }, pending))
        end
    ))
    local receipt = assert(capability.commit(
        grown.qa_registry,
        lease,
        exact_result
    ))
    return grown, grant, lease, exact_result, receipt
end

suite:check("M2.2 accepted physical result commits one private receipt", function()
    local grown, grant, lease, exact_result, receipt = run_private({
        label = "qa-private-receipt-accepted",
    })
    H.assert_eq(grown.qa_adapter_state.runs, 1, "candidate ran once")
    H.assert_eq(exact_result.protocol_version,
        "qa.provider_candidate_report.v1", "private report protocol")
    H.assert_eq(exact_result.outcome, "accepted", "expected exit is accepted")
    H.assert_eq(receipt.result_kind, "candidate_report", "receipt names report")
    H.assert_eq(receipt.transaction_disposition, "completed",
        "candidate report completes transaction")
    H.assert_eq(receipt.source_acquisition, "acquired", "source was acquired")
    H.assert_eq(receipt.source_disposition, "consumed", "source is terminal")
    H.assert_eq(receipt.request_id, grant.request_id, "receipt binds grant request")
    H.assert_eq(#fixture.events(grown.instance, "qa_check"), 0,
        "private receipt is not yet Packet truth")
    local replay = assert(capability.commit(
        grown.qa_registry,
        lease,
        exact_result
    ))
    H.assert_eq(replay.execution_receipt_id, receipt.execution_receipt_id,
        "exact commit replay is idempotent")
    H.assert_eq(grown.qa_adapter_state.runs, 1, "commit replay never reruns")
end)

suite:check("M2.2 candidate rejection remains report, not infrastructure", function()
    local grown, _, _, result_value, receipt = run_private({
        label = "qa-private-receipt-rejected",
        adapter_options = {reason = "unexpected_exit", exit_code = 70},
    })
    H.assert_eq(grown.qa_adapter_state.runs, 1, "rejected candidate ran once")
    H.assert_eq(result_value.protocol_version,
        "qa.provider_candidate_report.v1", "rejection remains candidate report")
    H.assert_eq(result_value.outcome, "rejected", "nonzero exit is rejected")
    H.assert_eq(receipt.transaction_disposition, "completed",
        "contained rejection completes physical transaction")
end)

suite:check("M2.2 infrastructure result commits consumed failure", function()
    local grown, _, _, result_value, receipt = run_private({
        label = "qa-private-receipt-infrastructure",
        adapter_options = {error_code = "supervisor_unavailable"},
    })
    H.assert_eq(grown.qa_adapter_state.runs, 1, "provider entered once")
    H.assert_eq(result_value.protocol_version, "qa.provider_error.v1",
        "infrastructure uses private error protocol")
    H.assert_eq(result_value.code, "supervisor_unavailable",
        "exact provider code survives")
    H.assert_eq(receipt.result_kind, "provider_error", "receipt names error")
    H.assert_eq(receipt.transaction_disposition, "consumed_failed",
        "clean prestart error consumes transaction")
end)

suite:check("M2.2 receipt reader is private and detached", function()
    local grown, _, _, _, receipt = run_private({
        label = "qa-private-receipt-reader",
    })
    local public = assert(capability.find_receipt(
        grown.qa_registry,
        receipt.request_id
    ))
    H.assert_eq(public.execution_receipt_id, receipt.execution_receipt_id,
        "public lookup returns exact receipt")
    H.assert_nil(public.result, "public lookup exposes no private result")
    local joined = assert(capability.with_receipt(
        grown.qa_registry,
        receipt.execution_receipt_id,
        function(exact_receipt, exact_result)
            return {
                receipt_id = exact_receipt.execution_receipt_id,
                result_protocol = exact_result.protocol_version,
            }
        end
    ))
    H.assert_eq(joined.receipt_id, receipt.execution_receipt_id,
        "private reader joins exact receipt")
    H.assert_eq(joined.result_protocol, "qa.provider_candidate_report.v1",
        "private reader sees exact stored result")
    public.execution_receipt_id = "mutated"
    H.assert_eq(capability.find_receipt(
        grown.qa_registry,
        receipt.request_id
    ).execution_receipt_id, receipt.execution_receipt_id,
        "detached mutation changes no receipt")
    H.assert_nil(capability.with_receipt(
        grown.qa_registry,
        receipt.execution_receipt_id,
        function() return {registry = grown.qa_registry} end
    ), "receipt callback cannot export authority")
end)

suite:finish()
print("test_qa_capability_receipt ok")
