package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local roots = require("tests.support.owned_temp_root")
local native_build = require("tests.support.repository_native_build")
local fixture = require("tests.support.repository_hands")
local suite = H.new("repository-effect-linux")

suite:check("REAL0 native provider grows exact effect and completion", function()
    assert(native_build.ensure_loader_fixtures())
    package.loaded["runtime.repository_provider"] = nil
    local provider = require("runtime.repository_provider")
    local capabilities = require("runtime.repository_capability")
    local intents = require("runtime.repository_intent")
    local actions = require("runtime.repository_action")
    local completions = require("runtime.work_completion")
    local logic = require("organs.logic")
    local body = require("runtime.body")

    assert(roots.with_root(function(root)
        local instance = fixture.packet({{
            path = "first-contact.lua",
            content = "return 'runtime-confirmed'\n",
        }}, {label = "step-7-7-real-effect"})
        local registry = assert(capabilities.new({
            session_id = instance.session_id,
            providers = {[provider.provider_id] = provider},
        }))
        assert(capabilities.mint(registry, fixture.grant_input({
            project_base = root.project_base,
            repository_path = "repo",
        })))
        local intent = assert(intents.derive(instance, {
            max_items = instance.regime.encoding.bounds.max_output_units,
        }))
        local action = assert(actions.authorize(instance, intent, registry, {
            session_id = instance.session_id,
            lineage_id = instance.lineage_id,
            generation = instance.generation,
            repository_id = "repo-a",
            work_mode = "build",
        }))

        fixture.move_to(instance, "☶")
        local _, validation = assert(logic.run(instance, {
            work_mode = "build",
            repository_effect = {action = action},
        }, {repository_capabilities = registry}))
        H.assert_eq(validation.status, "accepted", "native read-back is exact")
        H.assert_eq(validation.effect_cost.tool_calls, 2, "one create plus one read")
        H.assert_eq(validation.effect_cost.file_writes, 1, "one atomic create attempt")

        fixture.move_to(instance, "☱")
        local candidate = assert(completions.derive(instance, {
            action = action,
            attempt_ref = validation.attempt_ref,
            receipt_ref = validation.receipt_ref,
            verification_ref = validation.verification_ref,
            validation_ref = validation.trace_event_id,
        }))
        assert(completions.record(instance, candidate))
        local progress = body.progress(instance)
        H.assert_eq(progress.needed_count, 1, "one exact repository predicate")
        H.assert_eq(progress.done_count, 1, "native evidence completes exact work")
        H.assert_eq(progress.remaining_count, 0, "no repository work remains")
        return true
    end))
end)

suite:check("H-R01 repeated real lives close every repository grant", function()
    assert(native_build.ensure_loader_fixtures())
    package.loaded["runtime.repository_provider"] = nil
    local provider = require("runtime.repository_provider")
    local capabilities = require("runtime.repository_capability")
    local intents = require("runtime.repository_intent")
    local actions = require("runtime.repository_action")
    local logic = require("organs.logic")

    assert(roots.with_root(function(root)
        for index = 1, 16 do
            local relative_path = string.format("life-%02d.lua", index)
            local content = string.format("return %d\n", index)
            local instance = fixture.packet({{
                path = relative_path,
                content = content,
            }}, {label = "step-7-8-real-life-" .. tostring(index)})
            local registry = assert(capabilities.new({
                session_id = instance.session_id,
                providers = {[provider.provider_id] = provider},
            }))
            local projection = assert(capabilities.mint(
                registry,
                fixture.grant_input({
                    project_base = root.project_base,
                    repository_path = "repo",
                })
            ))
            local intent = assert(intents.derive(instance, {
                max_items = instance.regime.encoding.bounds.max_output_units,
            }))
            local action = assert(actions.authorize(instance, intent, registry, {
                session_id = instance.session_id,
                lineage_id = instance.lineage_id,
                generation = instance.generation,
                repository_id = "repo-a",
                work_mode = "build",
            }))

            fixture.move_to(instance, "☶")
            local _, validation = assert(logic.run(instance, {
                work_mode = "build",
                repository_effect = {action = action},
            }, {repository_capabilities = registry}))
            H.assert_eq(validation.status, "accepted",
                "each real life proves its exact file")
            local revoked = assert(capabilities.revoke(
                registry, projection.grant_id))
            H.assert_eq(revoked.state, "revoked",
                "each native repository handle is explicitly closed")
        end
        return true
    end))
end)

suite:check("REAL1 native provider reaches repository manifest through Tree", function()
    assert(native_build.ensure_loader_fixtures())
    package.loaded["runtime.repository_provider"] = nil
    local provider = require("runtime.repository_provider")
    local capabilities = require("runtime.repository_capability")

    assert(roots.with_root(function(root)
        local registry = assert(capabilities.new({
            session_id = "session-repository-hands",
            providers = {[provider.provider_id] = provider},
        }))
        local projection = assert(capabilities.mint(
            registry,
            fixture.grant_input({
                project_base = root.project_base,
                repository_path = "repo",
            })
        ))
        local instance, result = fixture.packet({{
            path = "tree-manifest.lua",
            content = "return 'real-tree-manifest'\n",
        }}, {
            label = "step-7-10-real-tree-manifest",
            max_ticks = 8,
            runner_options = {
                repository_hands = {
                    protocol_version = "repository.hands.config.v0",
                    enabled = true,
                    repository_id = "repo-a",
                },
                host_services = {repository_capabilities = registry},
            },
        })
        H.assert_eq(result.stop_reason, "manifested",
            "real provider life reaches MANIFEST")
        H.assert_eq(instance.status, "dead", "real provider Packet terminates")
        H.assert_eq(instance.death.cause, "complete", "real provider death is complete")
        H.assert_eq(instance.manifest.mode, "repository_delivery",
            "real provider uses exact repository delivery")
        H.assert_eq(instance.manifest.output.structured.artifacts[1].relative_path,
            "tree-manifest.lua", "real artifact path is projected")
        H.assert_eq(instance.manifest.output.structured.artifacts[1].bytes,
            #"return 'real-tree-manifest'\n", "real artifact length is verified")
        local revoked = assert(capabilities.revoke(registry, projection.grant_id))
        H.assert_eq(revoked.state, "revoked", "real route closes its grant")
        return true
    end))
end)

suite:finish()
print("test_repository_effect_linux ok")
