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

suite:check("EX23 inventory provider is root-bound, not host-selected", function()
    assert(support.with_candidate("return true\n", function(grown)
        local substituted_calls = 0
        local substituted = {
            provider_id = "linux.openat2.renameat2.v0",
            inventory_tree = function()
                substituted_calls = substituted_calls + 1
                error("substituted inventory provider entered", 0)
            end,
        }
        local services = {
            repository_capabilities = grown.registry,
            repository_provider = substituted,
            qa_provider = grown.qa_provider,
            qa_environment = grown.environment,
        }
        local plan = assert(witness.prepare(grown.instance, services))
        local report = assert(witness.execute(grown.instance, services, plan))
        H.assert_eq(report.outcome, "accepted")
        H.assert_eq(substituted_calls, 0,
            "host-selected inventory provider has zero authority")
        return true
    end))
end)

suite:check("EX18 source callback cannot export handle or provider", function()
    assert(support.with_candidate("return true\n", function(grown)
        local capabilities = require("runtime.repository_capability")
        local plan = assert(witness.prepare(grown.instance, grown.services))
        local lease = assert(capabilities.reserve_qa_source(
            grown.registry, plan.binding))
        local exported, exported_err = capabilities.with_qa_source(
            grown.registry,
            lease,
            function(handle, provider)
                return {borrowed_handle = handle, borrowed_provider = provider}
            end
        )
        H.assert_nil(exported, "private source authority crossed callback")
        H.assert_contains(exported_err, "private authority",
            "identity-based detacher rejected callback export")
        assert(capabilities.finish_qa_source(grown.registry, lease, {
            protocol_version = "repository.qa_source_disposition.v0",
            transaction_id = plan.witness.transaction_id,
            state = "quarantined",
            reason = "fixture_authority_export_denied",
            event_truth_status = "runtime_confirmed",
        }))
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

suite:check("C10.4 one-load context detects table and callable drift", function()
    local denied, denied_err = support.open_campaign()
    H.assert_nil(denied, "one-load context accepted preloaded providers")
    H.assert_contains(denied_err, "absent", "preloaded denial names boundary")

    package.loaded["runtime.repository_provider"] = nil
    package.loaded["runtime.qa_provider"] = nil
    local context = assert(support.open_campaign())
    local projection = assert(support.inspect_campaign(context))
    H.assert_eq(projection.protocol_version, "qa.provider_campaign_context.v0")
    H.assert_eq(projection.event_truth_status, "runtime_confirmed")

    local qa_provider = assert(package.loaded["runtime.qa_provider"])
    local original_run = qa_provider.run
    qa_provider.run = function() error("must not run", 0) end
    local callable_ok, callable_err = support.verify_campaign(context)
    H.assert_nil(callable_ok, "campaign accepted callable drift")
    H.assert_contains(callable_err, "callable identity", "callable drift reason")
    qa_provider.run = original_run
    assert(support.verify_campaign(context))

    package.loaded["runtime.qa_provider"] = {}
    local table_ok, table_err = support.verify_campaign(context)
    H.assert_nil(table_ok, "campaign accepted package.loaded drift")
    H.assert_contains(table_err, "table identity", "table drift reason")
    package.loaded["runtime.qa_provider"] = qa_provider
    assert(support.verify_campaign(context))
end)

suite:finish()
print("test_qa_provider_witness ok")
