package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local support = require("tests.support.qa_provider_witness")
local witness = require("runtime.qa_provider_witness")

local suite = H.new("qa-provider-witness")

suite:check("WA01/WA04 clean sealed root executes exactly once", function()
    assert(support.with_candidate("return true\n", function(grown)
        local calls = 0
        local adapter = {
            run = function(handle, request)
                calls = calls + 1
                return grown.qa_provider.run(handle, request)
            end,
        }
        local services = {
            repository_capabilities = grown.registry,
            repository_provider = grown.repository_provider,
            qa_provider = adapter,
            qa_environment = grown.environment,
        }
        local trace_before = #grown.instance.trace
        local plan = assert(witness.prepare(grown.instance, services))
        H.assert_eq(#grown.instance.trace, trace_before, "prepare is massless")
        local report = assert(witness.execute(grown.instance, services, plan))
        H.assert_eq(calls, 1, "provider RUN is entered once")
        H.assert_eq(report.protocol_version, "qa.provider_witness_report.v1")
        H.assert_eq(report.outcome, "accepted")
        H.assert_eq(report.reason, "expected_exit")
        H.assert_true(report.source.stable, "pre/post source is exact")
        H.assert_eq(report.source.disposition, "consumed")
        H.assert_eq(report.source.pre_inventory_id,
            report.source.post_inventory_id)
        H.assert_true(report.cause.monotonic_sequence >= 1,
            "first cause survives the witness join")
        H.assert_true(report.finality.namespace_cleanup_complete,
            "candidate finality survives the witness join")
        H.assert_true(report.resources.max_rss_bytes > 0,
            "native wait4 reports exact resident-set use")
        H.assert_true(report.cost.wall_time_ms >= 0,
            "native monotonic clock reports transaction duration")
        H.assert_eq(#grown.instance.trace, trace_before,
            "witness transaction does not enter Packet trace")
        return true
    end))
end)

suite:check("WA09 runtime error is candidate rejection", function()
    assert(support.with_candidate("error('fixture failure')\n", function(grown)
        local plan = assert(witness.prepare(grown.instance, grown.services))
        local report = assert(witness.execute(
            grown.instance, grown.services, plan))
        H.assert_eq(report.outcome, "rejected")
        H.assert_eq(report.reason, "unexpected_exit")
        H.assert_eq(report.termination.exit_code, 70)
        H.assert_true(report.source.stable)
        return true
    end))
end)

suite:check("WA05/WA07 report exists only after source finality", function()
    assert(support.with_candidate("return true\n", function(grown)
        local plan = assert(witness.prepare(grown.instance, grown.services))
        local report = assert(witness.execute(
            grown.instance, grown.services, plan))
        local capabilities = require("runtime.repository_capability")
        local root = assert(capabilities.root_authority(grown.registry, {
            root_authority_id = plan.witness.root_authority_id,
        }))
        H.assert_eq(root.state, "sealed")
        H.assert_eq(report.source.disposition, "consumed")
        H.assert_nil(report.cleanup,
            "v1 has one finality record rather than a cleanup alias")
        H.assert_nil(report.repository_handle)
        H.assert_nil(report.pre_inventory)
        return true
    end))
end)

suite:check("C7 returned mutation has no body or root authority", function()
    assert(support.with_candidate("return true\n", function(grown)
        local schema = require("core.qa_schema")
        local capabilities = require("runtime.repository_capability")
        local plan = assert(witness.prepare(grown.instance, grown.services))
        local trace_before = H.copy(grown.instance.trace)
        local revisions_before = H.copy(grown.instance.revisions)
        local budget_before = H.copy(grown.instance.runtime.budget)
        local root_before = assert(capabilities.root_authority(grown.registry, {
            root_authority_id = plan.witness.root_authority_id,
        }))
        local report = assert(witness.execute(
            grown.instance, grown.services, plan))
        report.source.disposition = "quarantined"
        report.cost.qa_executions = 999
        H.assert_true(schema.same(grown.instance.trace, trace_before))
        H.assert_true(schema.same(grown.instance.revisions, revisions_before))
        H.assert_true(schema.same(grown.instance.runtime.budget, budget_before))
        H.assert_true(schema.same(assert(capabilities.root_authority(
            grown.registry, {
                root_authority_id = plan.witness.root_authority_id,
            })), root_before))
        return true
    end))
end)

suite:finish()
print("test_qa_provider_witness ok")
