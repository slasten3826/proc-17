local roots = require("tests.support.owned_temp_root")
local native_build = require("tests.support.repository_native_build")
local fixture = require("tests.support.repository_hands")
local digest = require("core.digest")
local qa_schema = require("core.qa_schema")

local support = {}
local serial = 0
local campaign_states = setmetatable({}, {__mode = "k"})

local function must(value, err, label)
    if value == nil or value == false then
        if type(err) == "table" then
            err = tostring(err.code or "table_error") .. "/"
                .. tostring(err.detail or err.stage or "no_detail")
        end
        error(tostring(label) .. ": " .. tostring(err), 0)
    end
    return value
end

local function command_ok(command)
    local ok, _, code = os.execute(command)
    return ok == true and (code == nil or code == 0)
end

local function freeze_surface(value, label)
    local frozen = {}
    for key, child in pairs(value) do
        local kind = type(child)
        if kind == "function" or kind == "userdata" or kind == "thread" then
            frozen[key] = {kind = kind, identity = child}
        elseif kind == "table" then
            frozen[key] = {
                kind = kind,
                digest = assert(digest.record(child), label .. "." .. tostring(key)),
            }
        else
            frozen[key] = {kind = kind, value = child}
        end
    end
    return frozen
end

local function verify_surface(value, frozen, label)
    local count = 0
    for key, child in pairs(value) do
        count = count + 1
        local expected = frozen[key]
        if not expected or type(child) ~= expected.kind then
            return nil, label .. " surface changed at " .. tostring(key)
        end
        if expected.identity ~= nil and child ~= expected.identity then
            return nil, label .. " callable identity changed at " .. tostring(key)
        end
        if expected.digest ~= nil
            and digest.record(child) ~= expected.digest then
            return nil, label .. " value changed at " .. tostring(key)
        end
        if expected.value ~= nil and child ~= expected.value then
            return nil, label .. " scalar changed at " .. tostring(key)
        end
    end
    local expected_count = 0
    for _ in pairs(frozen) do expected_count = expected_count + 1 end
    if count ~= expected_count then
        return nil, label .. " surface key set changed"
    end
    return true
end

function support.ensure_artifacts()
    local ready, ready_err = native_build.ensure_loader_fixtures()
    if not ready then return nil, ready_err end
    if not command_ok("make -C native qa-provider-shell fixture-helper") then
        return nil, "QA campaign artifacts failed to build"
    end
    return true
end

function support.open_campaign()
    if package.loaded["runtime.repository_provider"] ~= nil
        or package.loaded["runtime.qa_provider"] ~= nil then
        return nil, "campaign providers must be absent before one-load opening"
    end
    local helper_ready, helper_err = roots.use_prebuilt_helper()
    if not helper_ready then return nil, helper_err end
    local repository_provider = require("runtime.repository_provider")
    local qa_provider = require("runtime.qa_provider")
    local environment, environment_err = qa_provider.probe()
    if not environment then return nil, environment_err end
    local environment_ok, normalized_err = qa_schema.verify_environment(environment)
    if not environment_ok then return nil, normalized_err end
    local context = setmetatable({}, {__metatable = false})
    campaign_states[context] = {
        repository_provider = repository_provider,
        qa_provider = qa_provider,
        environment = environment,
        environment_digest = assert(digest.record(environment)),
        repository_surface = freeze_surface(
            repository_provider, "repository provider"),
        qa_surface = freeze_surface(qa_provider, "QA provider"),
    }
    return context
end

function support.verify_campaign(context)
    local state = campaign_states[context]
    if not state then return nil, "private one-load campaign context required" end
    if package.loaded["runtime.repository_provider"] ~= state.repository_provider
        or package.loaded["runtime.qa_provider"] ~= state.qa_provider then
        return nil, "campaign provider table identity changed"
    end
    local repository_ok, repository_err = verify_surface(
        state.repository_provider, state.repository_surface, "repository provider")
    if not repository_ok then return nil, repository_err end
    local qa_ok, qa_err = verify_surface(
        state.qa_provider, state.qa_surface, "QA provider")
    if not qa_ok then return nil, qa_err end
    if digest.record(state.environment) ~= state.environment_digest then
        return nil, "campaign environment value changed"
    end
    return true
end

function support.inspect_campaign(context)
    local state = campaign_states[context]
    if not state then return nil, "private one-load campaign context required" end
    local exact, exact_err = support.verify_campaign(context)
    if not exact then return nil, exact_err end
    return {
        protocol_version = "qa.provider_campaign_context.v0",
        repository_provider_id = state.repository_provider.provider_id,
        qa_provider_id = state.qa_provider.provider_id,
        qa_provider_protocol = state.qa_provider.protocol_version,
        environment_id = state.environment.environment_id,
        environment_digest = "sha256:" .. state.environment_digest,
        event_truth_status = "runtime_confirmed",
    }
end

function support.with_root_bound_inventory(grown, replacement, callback)
    if type(grown) ~= "table" or type(grown.repository_provider) ~= "table"
        or type(replacement) ~= "function" or type(callback) ~= "function" then
        return nil, "root-bound inventory override arguments are invalid"
    end
    local provider = grown.repository_provider
    local original = provider.inventory_tree
    if type(original) ~= "function" then
        return nil, "root-bound inventory provider is absent"
    end
    provider.inventory_tree = replacement
    local returned = table.pack(pcall(callback))
    provider.inventory_tree = original
    if returned[1] ~= true then
        error(returned[2], 0)
    end
    return table.unpack(returned, 2, returned.n)
end

local function body_qa_contract(environment, lineage_id, stage_id)
    return assert(qa_schema.normalize_contract({
        protocol_version = "qa.contract.v0",
        lineage_id = lineage_id,
        process_contract_id = "build.only.v0",
        context = "software_task.v0",
        stage_id = stage_id,
        execution_policy = "single_required_check.v0",
        required_checks = {{
            ordinal = 1,
            required = true,
            kind = "lua54_test_suite.v0",
            profile_id = qa_schema.profile_id,
            environment_id = environment.environment_id,
            entrypoint = {
                relative_path = "tests/run.lua",
                expected_kind = "regular_file",
            },
            invocation = {
                stdin = "closed",
                arguments = {},
                expected_exit_codes = {0},
            },
            resource_limits = qa_schema.hard_limits(),
            output_policy = {
                authority = "exit_status_only",
                retain_raw_output = false,
            },
        }},
        source_refs = {"campaign:qa-policy", environment.environment_id},
        event_truth_status = "runtime_confirmed",
        content_truth_status = "runtime_confirmed",
    }))
end

local function grow_candidate(state, content, options)
    options = options or {}
    serial = serial + 1
    return function(root)
        local repository_provider = state.repository_provider
        local qa_provider = state.qa_provider
        local capabilities = require("runtime.repository_capability")
        local intents = require("runtime.repository_intent")
        local actions = require("runtime.repository_action")
        local completions = require("runtime.work_completion")
        local candidate_seal = require("runtime.candidate_seal")
        local logic = require("organs.logic")
        local lineage_id = "lineage-qa-provider-witness-" .. tostring(serial)
        local stage_id = "stage:" .. lineage_id .. ":1:build"
        local packet_options = nil
        if options.body_qa == true then
            packet_options = {
                process_contract_id = "build.only.v0",
                stage_id = stage_id,
                qa_contract = body_qa_contract(
                    state.environment,
                    lineage_id,
                    stage_id
                ),
            }
        end
        local instance = fixture.packet({{
            path = "tests/run.lua",
            content = content,
        }}, {
            label = "qa-provider-witness-" .. tostring(serial),
            session_id = "session-qa-provider-witness",
            lineage_id = lineage_id,
            repository_id = "repo-a",
            packet_options = packet_options,
        })
        local registry = must(capabilities.new({
            session_id = instance.session_id,
            providers = {[repository_provider.provider_id] = repository_provider},
        }), "registry", "registry")
        must(capabilities.mint(registry, fixture.grant_input({
            lineage_id = instance.lineage_id,
            repository_id = instance.repository_id,
            project_base = root.project_base,
            repository_path = "candidate",
            bounds = {
                max_relative_path_bytes = 128,
                max_content_bytes = 4096,
                max_effects_per_generation = 8,
            },
        })), "mint", "mint")
        local intent = must(intents.derive(instance, {
            max_items = instance.regime.encoding.bounds.max_output_units,
        }), "intent", "intent")
        local action = must(actions.authorize(instance, intent, registry, {
            session_id = instance.session_id,
            lineage_id = instance.lineage_id,
            generation = instance.generation,
            repository_id = instance.repository_id,
            work_mode = "build",
        }), "action", "action")
        fixture.move_to(instance, "☶")
        local _, validation = logic.run(instance, {
            work_mode = "build",
            repository_effect = {action = action},
        }, {repository_capabilities = registry})
        must(validation, _, "effect")
        fixture.move_to(instance, "☱")
        local completion, completion_err = completions.derive(instance, {
            action = action,
            attempt_ref = validation.attempt_ref,
            receipt_ref = validation.receipt_ref,
            verification_ref = validation.verification_ref,
            validation_ref = validation.trace_event_id,
        })
        must(completion, completion_err, "completion derive")
        must(completions.record(instance, completion), "record", "completion record")
        local services = {
            repository_capabilities = registry,
            repository_provider = repository_provider,
            qa_provider = qa_provider,
        }
        local seal_request, seal_request_err = candidate_seal.prepare(instance, services)
        must(seal_request, seal_request_err, "seal prepare")
        fixture.move_to(instance, "☶")
        local sealed, sealed_err = candidate_seal.execute(instance, seal_request, services)
        must(sealed, sealed_err, "seal execute")
        services.qa_environment = state.environment
        local grown = {
            instance = instance,
            registry = registry,
            repository_provider = repository_provider,
            qa_provider = qa_provider,
            services = services,
            environment = state.environment,
            sealed = sealed,
            root = root,
        }
        if options.body_qa == true then
            local qa_environment = require("runtime.qa_environment")
            local qa_capability = require("runtime.qa_capability")
            local environment_registry = must(qa_environment.new(
                instance.session_id,
                qa_provider
            ), "environment registry", "environment registry")
            local environment = must(qa_environment.probe(
                environment_registry
            ), "environment probe", "environment probe")
            assert(environment.environment_id == state.environment.environment_id,
                "body campaign environment identity drift")
            local qa_registry = must(qa_capability.new(
                instance.session_id,
                environment_registry,
                registry
            ), "QA registry", "QA registry")
            grown.qa_environment_registry = environment_registry
            grown.qa_registry = qa_registry
            grown.body_services = {
                qa_enabled = true,
                qa_capabilities = qa_registry,
                qa_environment = environment,
            }
        end
        return grown
    end
end

function support.with_candidate_in_campaign(
        context, content, body_callback, after_cleanup_callback)
    local state = campaign_states[context]
    if not state then return nil, "private one-load campaign context required" end
    if type(content) ~= "string" or type(body_callback) ~= "function"
        or (after_cleanup_callback ~= nil
            and type(after_cleanup_callback) ~= "function") then
        return nil, "campaign candidate arguments are invalid"
    end
    local exact, exact_err = support.verify_campaign(context)
    if not exact then return nil, exact_err end
    local grow = grow_candidate(state, content)
    return roots.with_root_phases(function(root)
        local still_exact, still_err = support.verify_campaign(context)
        if not still_exact then error(still_err, 0) end
        return body_callback(grow(root))
    end, function(prior_identity)
        local still_exact, still_err = support.verify_campaign(context)
        if not still_exact then error(still_err, 0) end
        if after_cleanup_callback then
            return after_cleanup_callback(prior_identity)
        end
        return true
    end)
end

function support.with_body_candidate_in_campaign(
        context, content, body_callback, after_cleanup_callback)
    local state = campaign_states[context]
    if not state then return nil, "private one-load campaign context required" end
    if type(content) ~= "string" or type(body_callback) ~= "function"
        or (after_cleanup_callback ~= nil
            and type(after_cleanup_callback) ~= "function") then
        return nil, "body campaign candidate arguments are invalid"
    end
    local exact, exact_err = support.verify_campaign(context)
    if not exact then return nil, exact_err end
    local grow = grow_candidate(state, content, {body_qa = true})
    return roots.with_root_phases(function(root)
        local still_exact, still_err = support.verify_campaign(context)
        if not still_exact then error(still_err, 0) end
        return body_callback(grow(root))
    end, function(prior_identity)
        local still_exact, still_err = support.verify_campaign(context)
        if not still_exact then error(still_err, 0) end
        if after_cleanup_callback then
            return after_cleanup_callback(prior_identity)
        end
        return true
    end)
end

function support.with_candidate(content, callback)
    assert(support.ensure_artifacts())
    package.loaded["runtime.repository_provider"] = nil
    package.loaded["runtime.qa_provider"] = nil
    local context = assert(support.open_campaign())
    return support.with_candidate_in_campaign(context, content, callback)
end

return support
