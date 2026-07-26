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
        H.assert_eq(report.protocol_version, "qa.provider_witness_report.v0")
        H.assert_eq(report.outcome, "accepted")
        H.assert_eq(report.reason, "expected_exit")
        H.assert_true(report.source.stable, "pre/post source is exact")
        H.assert_eq(report.source.pre_inventory_id,
            report.source.post_inventory_id)
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
        H.assert_eq(report.cleanup, "complete")
        H.assert_nil(report.repository_handle)
        H.assert_nil(report.pre_inventory)
        return true
    end))
end)

suite:finish()
print("test_qa_provider_witness ok")
