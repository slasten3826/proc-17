package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local support = require("tests.support.qa_provider_witness")
local witness = require("runtime.qa_provider_witness")

local suite = H.new("qa-provider-witness-hostile")

local function services(grown, repository_provider, qa_provider)
    return {
        repository_capabilities = grown.registry,
        repository_provider = repository_provider or grown.repository_provider,
        qa_provider = qa_provider or grown.qa_provider,
        qa_environment = grown.environment,
    }
end

local function corrupt_inventory(raw)
    local changed = H.copy(raw)
    for _, entry in ipairs(changed.entries or {}) do
        if entry.kind == "regular_file" and type(entry.content) == "string" then
            entry.content = string.rep("x", #entry.content)
            return changed
        end
    end
    error("fixture inventory has no regular file")
end

suite:check("WA02 changed plan reserves no source", function()
    assert(support.with_candidate("return true\n", function(grown)
        local exact_services = services(grown)
        local plan = assert(witness.prepare(grown.instance, exact_services))
        local changed = H.copy(plan)
        changed.witness.entrypoint.bytes = changed.witness.entrypoint.bytes + 1
        local result, err = witness.execute(
            grown.instance, exact_services, changed)
        H.assert_nil(result)
        H.assert_eq(err.code, "witness_plan_changed")

        local report = assert(witness.execute(
            grown.instance, exact_services, plan))
        H.assert_eq(report.outcome, "accepted",
            "exact plan can still reserve after rejected detached mutation")
        return true
    end))
end)

suite:check("WA03 pre-inventory mismatch starts no RUN", function()
    assert(support.with_candidate("return true\n", function(grown)
        local inventories = 0
        local runs = 0
        local repository_provider = {
            provider_id = grown.repository_provider.provider_id,
            inventory_tree = function(handle, bounds)
                inventories = inventories + 1
                local raw, err = grown.repository_provider.inventory_tree(
                    handle, bounds)
                if not raw then return nil, err end
                return corrupt_inventory(raw)
            end,
        }
        local qa_provider = {
            run = function(handle, request)
                runs = runs + 1
                return grown.qa_provider.run(handle, request)
            end,
        }
        local hostile_services = services(
            grown, repository_provider, qa_provider)
        local plan = assert(witness.prepare(grown.instance, hostile_services))
        local report, err = witness.execute(
            grown.instance, hostile_services, plan)
        H.assert_nil(report)
        H.assert_eq(err.protocol_version, "qa.provider_witness_error.v1")
        H.assert_eq(err.code, "source_preflight_mismatch")
        H.assert_eq(err.candidate_start_state, "not_started")
        H.assert_eq(err.source_disposition, "consumed")
        H.assert_true(err.source_stable)
        H.assert_eq(err.cleanup_state, "complete")
        H.assert_eq(err.launcher_reaped, "complete")
        H.assert_eq(err.result_eof, "complete")
        H.assert_nil(err.measured_cost,
            "no candidate means no fabricated process cost")
        H.assert_eq(runs, 0, "native RUN never starts")
        H.assert_eq(inventories, 1, "only pre-inventory is needed")
        return true
    end))
end)

suite:check("WA05 post-inventory drift quarantines result", function()
    assert(support.with_candidate("return true\n", function(grown)
        local inventories = 0
        local runs = 0
        local repository_provider = {
            provider_id = grown.repository_provider.provider_id,
            inventory_tree = function(handle, bounds)
                inventories = inventories + 1
                local raw, err = grown.repository_provider.inventory_tree(
                    handle, bounds)
                if not raw then return nil, err end
                if inventories == 2 then
                    raw = corrupt_inventory(raw)
                end
                return raw
            end,
        }
        local qa_provider = {
            run = function(handle, request)
                runs = runs + 1
                return grown.qa_provider.run(handle, request)
            end,
        }
        local hostile_services = services(
            grown, repository_provider, qa_provider)
        local plan = assert(witness.prepare(grown.instance, hostile_services))
        local report, err = witness.execute(
            grown.instance, hostile_services, plan)
        H.assert_nil(report)
        H.assert_eq(err.protocol_version, "qa.provider_witness_error.v1")
        H.assert_eq(err.code, "source_drift")
        H.assert_eq(err.class, "ambiguous")
        H.assert_false(err.source_stable)
        H.assert_eq(err.source_disposition, "quarantined")
        H.assert_eq(err.candidate_start_state, "started")
        H.assert_eq(err.cleanup_state, "complete")
        H.assert_eq(err.launcher_reaped, "complete")
        H.assert_eq(err.result_eof, "complete")
        H.assert_eq(err.measured_cost.protocol_version, "qa.cost.v1")
        H.assert_eq(runs, 1)
        H.assert_eq(inventories, 2)
        return true
    end))
end)

suite:check("C7 process uncertainty is preserved exactly", function()
    assert(support.with_candidate("return true\n", function(grown)
        local qa_provider = {
            run = function(_, request)
                return nil, {
                    protocol_version = "qa.provider_process_error.v1",
                    operation = "run_lua54_test_suite",
                    transaction_id = request.transaction_id,
                    witness_id = request.witness_id,
                    profile_id = request.profile_id,
                    environment_id = request.environment_id,
                    class = "ambiguous",
                    code = "reap_ambiguous",
                    stage = "cleanup",
                    candidate_start_state = "unknown",
                    cleanup_state = "unknown",
                    launcher_reaped = "unknown",
                    result_eof = "unknown",
                    measured_cost = nil,
                    event_truth_status = "runtime_confirmed",
                }
            end,
        }
        local hostile_services = services(grown, nil, qa_provider)
        local plan = assert(witness.prepare(grown.instance, hostile_services))
        local report, err = witness.execute(
            grown.instance, hostile_services, plan)
        H.assert_nil(report)
        H.assert_eq(err.protocol_version, "qa.provider_witness_error.v1")
        H.assert_eq(err.source_disposition, "quarantined")
        H.assert_eq(err.candidate_start_state, "unknown")
        H.assert_eq(err.cleanup_state, "unknown")
        H.assert_eq(err.launcher_reaped, "unknown")
        H.assert_eq(err.result_eof, "unknown")
        H.assert_nil(err.measured_cost)
        return true
    end))
end)

suite:check("C7 impossible process topology quarantines before loud failure", function()
    assert(support.with_candidate("return true\n", function(grown)
        local runs = 0
        local qa_provider = {
            run = function(_, request)
                runs = runs + 1
                return nil, {
                    protocol_version = "qa.provider_process_error.v1",
                    operation = "run_lua54_test_suite",
                    transaction_id = request.transaction_id,
                    witness_id = request.witness_id,
                    profile_id = request.profile_id,
                    environment_id = request.environment_id,
                    class = "ambiguous",
                    code = "reap_ambiguous",
                    stage = "preflight",
                    candidate_start_state = "not_started",
                    cleanup_state = "complete",
                    launcher_reaped = "complete",
                    result_eof = "complete",
                    measured_cost = nil,
                    event_truth_status = "runtime_confirmed",
                }
            end,
        }
        local hostile_services = services(grown, nil, qa_provider)
        local plan = assert(witness.prepare(grown.instance, hostile_services))
        local ok, err = pcall(witness.execute,
            grown.instance, hostile_services, plan)
        H.assert_false(ok, "impossible provider topology returned normally")
        H.assert_contains(err, "callback failed",
            "impossible provider topology is loud after quarantine")
        local replay, replay_err = witness.execute(
            grown.instance, hostile_services, plan)
        H.assert_nil(replay, "quarantined impossible topology replayed")
        H.assert_true(replay_err ~= nil, "topology replay denial is explicit")
        H.assert_eq(runs, 1, "quarantine prevents a second provider call")
        return true
    end))
end)

suite:check("C7 legacy process witness is rejected loudly", function()
    assert(support.with_candidate("return true\n", function(grown)
        local qa_provider = {
            run = function()
                return nil, {
                    protocol_version = "qa.provider_process_error.v0",
                    cleanup_complete = true,
                    candidate_started = false,
                }
            end,
        }
        local hostile_services = services(grown, nil, qa_provider)
        local plan = assert(witness.prepare(grown.instance, hostile_services))
        local ok, err = pcall(witness.execute,
            grown.instance, hostile_services, plan)
        H.assert_false(ok)
        H.assert_contains(err, "callback failed")
        return true
    end))
end)

suite:check("AB04 malformed trusted inventory is loud after finality", function()
    assert(support.with_candidate("return true\n", function(grown)
        local runs = 0
        local repository_provider = {
            provider_id = grown.repository_provider.provider_id,
            inventory_tree = function(handle, bounds)
                local raw, err = grown.repository_provider.inventory_tree(
                    handle, bounds)
                if not raw then return nil, err end
                raw.unknown_trusted_field = true
                return raw
            end,
        }
        local qa_provider = {
            run = function(handle, request)
                runs = runs + 1
                return grown.qa_provider.run(handle, request)
            end,
        }
        local hostile_services = services(
            grown, repository_provider, qa_provider)
        local plan = assert(witness.prepare(grown.instance, hostile_services))
        local ok, err = pcall(witness.execute,
            grown.instance, hostile_services, plan)
        H.assert_false(ok, "trusted malformed result is not normalized")
        H.assert_contains(err, "trusted contradiction after finality")
        H.assert_eq(runs, 0, "trusted preflight contradiction starts no RUN")
        local replay, replay_err = witness.execute(
            grown.instance, hostile_services, plan)
        H.assert_nil(replay, "quarantined source cannot replay")
        H.assert_true(replay_err ~= nil, "replay denial remains explicit")
        H.assert_eq(runs, 0, "replay starts no second callback")
        return true
    end))
end)

suite:check("WA08 witness cannot enter Packet QA writer", function()
    assert(support.with_candidate("return true\n", function(grown)
        local plan = assert(witness.prepare(grown.instance, grown.services))
        local report = assert(witness.execute(
            grown.instance, grown.services, plan))
        local qa_request = require("runtime.qa_request")
        local ok = qa_request.verify(grown.instance, report)
        H.assert_nil(ok, "witness protocol is not a body request")
        local legacy = H.copy(report)
        legacy.protocol_version = "qa.provider_witness_report.v0"
        local legacy_ok = qa_request.verify(grown.instance, legacy)
        H.assert_nil(legacy_ok, "legacy witness is not a body request alias")
        return true
    end))
end)

suite:finish()
print("test_qa_provider_witness_hostile ok")
