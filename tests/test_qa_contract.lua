package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local catalog = require("tests.support.qa_control_catalog").contract
local fixture = require("tests.support.qa_hand")
local packet = require("core.packet")
local schema, schema_err = H.optional_require("core.qa_schema")
local environments, environments_err = H.optional_require("runtime.qa_environment")
local contracts, contracts_err = H.optional_require("runtime.qa_contract")
local verdicts, verdicts_err = H.optional_require("runtime.qa_verdict")
local suite = H.new("qa-contract")

local function need(value, err, name, functions)
    value = suite:require_module(value, err, name)
    for _, function_name in ipairs(functions or {}) do
        H.assert_true(type(value[function_name]) == "function",
            name .. "." .. function_name .. " required")
    end
    return value
end

local function normalized_environment(label)
    local qa_schema = need(schema, schema_err, "core.qa_schema", {
        "normalize_environment",
    })
    return assert(qa_schema.normalize_environment(
        fixture.environment_input(label)))
end

local function normalized_contract(environment, options)
    local qa_schema = need(schema, schema_err, "core.qa_schema", {
        "normalize_contract",
    })
    return assert(qa_schema.normalize_contract(
        fixture.contract_input(environment, options)))
end

local probes = {}

probes.QC01 = function()
    local instance = packet.new("plan without executable QA", {
        work_mode = "plan",
        process_contract_id = "plan.only.v0",
    })
    H.assert_nil(instance.qa_contract, "plan birth has no QA contract")
    H.assert_nil(instance.qa_contract_id, "plan birth has no QA contract id")
end

probes.QC02 = function()
    local qa_schema = need(schema, schema_err, "core.qa_schema", {
        "profile", "hard_limits", "verify_profile",
    })
    local profile = qa_schema.profile()
    assert(qa_schema.verify_profile(profile))
    H.assert_eq(profile.profile_id, "qa.profile.lua54_test_suite.v0", "profile id")
    H.assert_eq(profile.shell, "forbidden", "shell forbidden")
    H.assert_eq(profile.network, "forbidden", "network forbidden")
    H.assert_eq(profile.child_processes, "forbidden", "children forbidden")
    H.assert_eq(profile.source_writes, "forbidden", "source writes forbidden")
    H.assert_eq(profile.hard_limits.cpu_time_ms % 1000, 0,
        "RLIMIT_CPU precision is honest")
end

probes.QC03 = function()
    local environment = normalized_environment("software-create")
    local contract = normalized_contract(environment, {
        lineage_id = "lineage-software-create",
        process_contract_id = "software.create.v0",
        stage_id = "stage:lineage-software-create:2:build",
    })
    H.assert_eq(contract.process_contract_id, "software.create.v0", "process contract")
    H.assert_eq(contract.stage_id, "stage:lineage-software-create:2:build", "build stage")
    H.assert_eq(#contract.required_checks, 1, "one exact check")
end

probes.QC04 = function()
    local environment = normalized_environment("same-stage")
    local first = normalized_contract(environment)
    local second = normalized_contract(environment)
    H.assert_eq(first.qa_contract_id, second.qa_contract_id,
        "same normalized stage contract identity")
end

probes.QC05 = function()
    local environment = normalized_environment("different-stage")
    local first = normalized_contract(environment, {stage_id = "stage:lineage-qa-hand:1:build"})
    local second = normalized_contract(environment, {stage_id = "stage:lineage-qa-hand:2:build"})
    H.assert_false(first.qa_contract_id == second.qa_contract_id,
        "different stage changes authority identity")
end

probes.QC06 = function()
    local qa_schema = need(schema, schema_err, "core.qa_schema", {"normalize_contract"})
    local environment = normalized_environment("substrate")
    local supplied = fixture.contract_input(environment)
    supplied.substrate_authority = true
    H.assert_nil(qa_schema.normalize_contract(supplied),
        "unknown substrate authority key rejected")
end

probes.QC07 = function()
    local qa_schema = need(schema, schema_err, "core.qa_schema", {"normalize_contract"})
    local environment = normalized_environment("invalid-shapes")
    local zero = fixture.contract_input(environment)
    zero.required_checks = {}
    H.assert_nil(qa_schema.normalize_contract(zero), "zero checks rejected")
    local two = fixture.contract_input(environment)
    two.required_checks[2] = fixture.copy(two.required_checks[1])
    H.assert_nil(qa_schema.normalize_contract(two), "two checks rejected")
    local argv = fixture.contract_input(environment)
    argv.required_checks[1].invocation.arguments = {"--host-controlled"}
    H.assert_nil(qa_schema.normalize_contract(argv), "arguments rejected")
    local stdin = fixture.contract_input(environment)
    stdin.required_checks[1].invocation.stdin = "inherit"
    H.assert_nil(qa_schema.normalize_contract(stdin), "inherited stdin rejected")
end

probes.QC08 = function()
    local environment = normalized_environment("identity")
    local first = normalized_contract(environment)
    local changed = fixture.contract_input(environment)
    changed.required_checks[1].resource_limits.stdout_bytes = 1024
    local second = assert(need(schema, schema_err, "core.qa_schema", {
        "normalize_contract",
    }).normalize_contract(changed))
    H.assert_false(first.qa_contract_id == second.qa_contract_id,
        "changed bound changes identity")
end

probes.QC09 = function()
    local qa_schema = need(schema, schema_err, "core.qa_schema", {"profile"})
    local first = qa_schema.profile()
    first.hard_limits.stdout_bytes = 1
    first.lua_policy.package_path = "host/?.lua"
    local second = qa_schema.profile()
    H.assert_eq(second.hard_limits.stdout_bytes, 1048576, "limits detached")
    H.assert_eq(second.lua_policy.package_path, "./?.lua;./?/init.lua",
        "Lua policy detached")
end

probes.QC10 = function()
    local module = need(environments, environments_err, "runtime.qa_environment", {
        "new", "probe", "resolve", "quarantine",
    })
    local adapter = fixture.native_adapter()
    local registry = assert(module.new("session-qa-contract", adapter))
    local environment = assert(module.probe(registry))
    assert(module.quarantine(registry, environment.environment_id, "fixture-unavailable"))
    H.assert_nil(module.resolve(registry, environment.environment_id,
        "qa.profile.lua54_test_suite.v0"), "quarantined identity cannot upgrade")
end

probes.QC11 = function()
    local module = need(contracts, contracts_err, "runtime.qa_contract", {
        "inspect_candidate",
    })
    local environment = normalized_environment("missing-entrypoint")
    local contract = normalized_contract(environment)
    local grown = fixture.grow_sealed({
        label = "qa-missing-entrypoint",
        lineage_id = contract.lineage_id,
        stage_id = contract.stage_id,
        qa_contract = contract,
        items = {{path = "src/main.lua", content = "return true\n"}},
    })
    local eligibility = assert(module.inspect_candidate(
        grown.instance, grown.seal, nil, environment))
    H.assert_eq(eligibility.state, "not_ready", "missing entrypoint is not ready")
    H.assert_contains(table.concat(eligibility.missing_requirements, ","),
        "entrypoint", "entrypoint absence remains explicit")
end

probes.QC12 = function()
    local module = need(contracts, contracts_err, "runtime.qa_contract", {
        "inspect_candidate",
    })
    local environment = normalized_environment("foreign-seal")
    local contract = normalized_contract(environment)
    local grown = fixture.grow_sealed({
        label = "qa-foreign-seal",
        lineage_id = contract.lineage_id,
        stage_id = contract.stage_id,
        qa_contract = contract,
    })
    local foreign = fixture.copy(grown.seal)
    foreign.candidate_seal_id = "candidate-seal:foreign"
    local eligibility = assert(module.inspect_candidate(
        grown.instance, foreign, nil, environment))
    H.assert_eq(eligibility.state, "conflict", "foreign seal conflicts")
end

probes.QC13 = function()
    local module = need(environments, environments_err, "runtime.qa_environment", {
        "resolve",
    })
    local public = normalized_environment("public-id")
    H.assert_nil(module.resolve(public, public.environment_id,
        "qa.profile.lua54_test_suite.v0"), "projection is not a private registry")
end

probes.QC14 = function()
    local module = need(environments, environments_err, "runtime.qa_environment", {
        "new", "probe",
    })
    local adapter = fixture.native_adapter({
        probe_error = {code = "feature_probe_incomplete", diagnostic = "headers only"},
    })
    local registry = assert(module.new("session-qa-probe", adapter))
    H.assert_nil(module.probe(registry), "diagnostic-only host cannot become available")
end

probes.QC15 = function()
    local module = need(verdicts, verdicts_err, "runtime.qa_verdict", {"current"})
    local instance = packet.new("stdout says ACCEPTED but body has no QA evidence", {
        work_mode = "build",
        metadata = {stdout = "ACCEPTED"},
    })
    H.assert_nil(module.current(instance, "candidate-seal:none", "qa-contract:none"),
        "wording cannot create verdict")
end

for _, control in ipairs(catalog) do
    local id, description = control[1], control[2]
    assert(type(probes[id]) == "function", "missing QA contract probe " .. id)
    suite:check(id .. " " .. description, probes[id])
end

suite:finish()
print("test_qa_contract ok")
