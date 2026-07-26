local roots = require("tests.support.owned_temp_root")
local native_build = require("tests.support.repository_native_build")
local fixture = require("tests.support.repository_hands")

local support = {}
local serial = 0

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

local function load_providers()
    assert(native_build.ensure_loader_fixtures())
    assert(command_ok("make -C native qa-provider-shell"))
    package.loaded["runtime.repository_provider"] = nil
    package.loaded["runtime.qa_provider"] = nil
    return require("runtime.repository_provider"), require("runtime.qa_provider")
end

function support.with_candidate(content, callback)
    serial = serial + 1
    return roots.with_root(function(root)
        assert(command_ok("mkdir -p " .. root.project_base .. "/candidate/tests"))
        local repository_provider, qa_provider = load_providers()
        local capabilities = require("runtime.repository_capability")
        local intents = require("runtime.repository_intent")
        local actions = require("runtime.repository_action")
        local completions = require("runtime.work_completion")
        local candidate_seal = require("runtime.candidate_seal")
        local logic = require("organs.logic")
        local instance = fixture.packet({{
            path = "tests/run.lua",
            content = content,
        }}, {
            label = "qa-provider-witness-" .. tostring(serial),
            session_id = "session-qa-provider-witness",
            lineage_id = "lineage-qa-provider-witness-" .. tostring(serial),
            repository_id = "repo-a",
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
        local environment, environment_err = qa_provider.probe()
        must(environment, environment_err, "QA environment probe")
        services.qa_environment = environment
        return callback({
            instance = instance,
            registry = registry,
            repository_provider = repository_provider,
            qa_provider = qa_provider,
            services = services,
            environment = environment,
            sealed = sealed,
            root = root,
        })
    end)
end

return support
