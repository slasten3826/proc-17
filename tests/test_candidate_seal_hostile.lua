package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local digest = require("core.digest")
local json = require("core.json")
local fixture = require("tests.support.repository_hands")
local logic = require("organs.logic")
local capabilities = require("runtime.repository_capability")
local candidate_seal = require("runtime.candidate_seal")
local repository_action = require("runtime.repository_action")
local repository_intent = require("runtime.repository_intent")
local work_completion = require("runtime.work_completion")
local substrate_contract = require("substrates.contract")
local suite = H.new("candidate-seal-hostile")

local function reidentify_request(request)
    request.request_id = nil
    request.request_id = "candidate-seal-request:" .. assert(digest.record(request))
    return request
end

local function reidentify_closure(closure)
    closure.closure_id = nil
    closure.closure_id = "candidate-closure:" .. assert(digest.record(closure))
    return closure
end

local function reidentify_seal(seal)
    seal.candidate_seal_id = nil
    seal.candidate_seal_id = "candidate-seal:" .. assert(digest.record(seal))
    return seal
end

local function error_code(value)
    return type(value) == "table" and value.code or tostring(value)
end

local function completed(label, provider_options)
    local instance = fixture.packet({{
        path = "src/main.lua",
        content = "return 'candidate-hostile'\n",
    }}, {label = label})
    local registry, grant, _, state = fixture.new_registry(capabilities, {
        provider_options = provider_options,
    })
    local intent = assert(repository_intent.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local action = assert(repository_action.authorize(instance, intent, registry, {
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        repository_id = instance.repository_id,
        work_mode = "build",
    }))
    fixture.move_to(instance, "☶")
    local _, validation = assert(logic.run(instance, {
        work_mode = "build",
        repository_effect = {action = action},
    }, {repository_capabilities = registry}))
    fixture.move_to(instance, "☱")
    assert(work_completion.record(instance, assert(work_completion.derive(instance, {
        action = action,
        attempt_ref = validation.attempt_ref,
        receipt_ref = validation.receipt_ref,
        verification_ref = validation.verification_ref,
        validation_ref = validation.trace_event_id,
    }))))
    return {
        instance = instance,
        registry = registry,
        grant = grant,
        state = state,
        action = action,
        services = {repository_capabilities = registry},
    }
end

local function exact_inventory(bounds, state)
    local paths = {"src", "src/main.lua"}
    local entries = {}
    local total = 0
    for index, path in ipairs(paths) do
        local content = path == "src/main.lua" and state.files[path] or nil
        local identity = {device = 17, inode = 3000 + index}
        entries[index] = {
            relative_path = path,
            kind = content and "regular_file" or "directory",
            identity_before = fixture.copy(identity),
            identity_after = fixture.copy(identity),
            bytes = content and #content or nil,
            content = content,
        }
        total = total + (content and #content or 0)
    end
    return {
        protocol_version = "repository.provider_inventory_result.v0",
        operation = "inventory_tree",
        outcome = "observed",
        root_before = fixture.copy(state.root_identity),
        root_after = fixture.copy(state.root_identity),
        stable = true,
        entries = entries,
        bounds_observed = {
            max_entries = bounds.max_entries,
            max_depth = bounds.max_depth,
            max_path_bytes = bounds.max_path_bytes,
            max_component_bytes = bounds.max_component_bytes,
            max_file_bytes = bounds.max_file_bytes,
            max_total_bytes = bounds.max_total_bytes,
            observed_entries = #entries,
            observed_total_bytes = total,
        },
        mutation_primitive_entered = false,
        published = false,
        cost = {tool_calls = 1, file_writes = 0, time_ms = 0},
    }
end

suite:check("PRE detached request mutation never enters pending", function()
    local grown = completed("candidate-hostile-stale")
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    request.expected_files[1].expected_sha256 = string.rep("0", 64)
    fixture.move_to(grown.instance, "☶")
    local result = candidate_seal.execute(grown.instance, request, grown.services)
    H.assert_nil(result, "caller mutation cannot seal")
    H.assert_eq(grown.state.calls.inventory, 0, "stale request reaches no provider")
    local root = assert(capabilities.root_authority(grown.registry, {
        grant_id = grown.grant.grant_id,
    }))
    H.assert_eq(root.state, "materializing", "readiness failure changes no authority")
end)

suite:check("ST01 caller cannot omit a body-derived artifact", function()
    local grown = completed("candidate-hostile-omitted-artifact")
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    request.expected_files = {}
    request.expected_directories = {}
    reidentify_request(request)
    fixture.move_to(grown.instance, "☶")
    local result, err = candidate_seal.execute(
        grown.instance, request, grown.services)
    H.assert_nil(result, "rehashing cannot authorize an omitted artifact")
    H.assert_contains(err, "stale or foreign", "body equality rejects omission")
    H.assert_eq(grown.state.calls.inventory, 0, "omission enters no provider")
    local root = assert(capabilities.root_authority(grown.registry, {
        grant_id = grown.grant.grant_id,
    }))
    H.assert_eq(root.state, "materializing", "omission enters no pending state")
end)

suite:check("ST02 caller cannot rewrite a body-derived work version", function()
    local grown = completed("candidate-hostile-stale-version")
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    request.expected_files[1].work_unit_version =
        request.expected_files[1].work_unit_version + 1
    reidentify_request(request)
    fixture.move_to(grown.instance, "☶")
    local result, err = candidate_seal.execute(
        grown.instance, request, grown.services)
    H.assert_nil(result, "rehashing cannot refresh stale work evidence")
    H.assert_contains(err, "stale or foreign", "body equality rejects version")
    H.assert_eq(grown.state.calls.inventory, 0, "stale version enters no provider")
end)

suite:check("ST03 incomplete artifact set never enters pending", function()
    local instance = fixture.packet({{
        path = "src/incomplete.lua",
        content = "return 'not materialized'\n",
    }}, {label = "candidate-hostile-incomplete"})
    local registry, grant, _, state = fixture.new_registry(capabilities)
    local request, err = candidate_seal.prepare(instance, {
        repository_capabilities = registry,
    })
    H.assert_nil(request, "unmaterialized artifact set cannot be sealed")
    H.assert_eq(type(err) == "table" and err.code or nil,
        "artifact_set_incomplete", "incomplete state is typed")
    H.assert_eq(state.calls.inventory, 0, "incomplete set enters no provider")
    local root = assert(capabilities.root_authority(registry, {
        grant_id = grant.grant_id,
    }))
    H.assert_eq(root.state, "unclaimed", "incomplete set claims no root")
end)

suite:check("ST06 caller cannot launder body truth or provenance", function()
    local grown = completed("candidate-hostile-truth-laundering")
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    table.remove(request.source_refs, 1)
    request.content_truth_status = request.content_truth_status == "mixed"
        and "semantic_proposal" or "mixed"
    reidentify_request(request)
    fixture.move_to(grown.instance, "☶")
    local result, err = candidate_seal.execute(
        grown.instance, request, grown.services)
    H.assert_nil(result, "new digest cannot promote a caller-authored truth status")
    H.assert_contains(err, "stale or foreign", "body-owned refs remain exact")
    H.assert_eq(grown.state.calls.inventory, 0, "truth claim enters no provider")
end)

suite:check("ST04 multiple active grants block prepare", function()
    local grown = completed("candidate-hostile-ambiguous-grant")
    assert(capabilities.mint(grown.registry, fixture.grant_input()))
    local request = candidate_seal.prepare(grown.instance, grown.services)
    H.assert_nil(request, "ambiguous authority cannot produce seal request")
    H.assert_eq(grown.state.calls.inventory, 0, "ambiguity enters no provider")
end)

suite:check("ST05 active provider dispatch blocks seal preparation", function()
    local probe = {}
    local grown
    grown = completed("candidate-hostile-in-flight", {
        create_override = function(_, request, state)
            if state.files[request.relative_path] ~= nil then
                return nil, {
                    protocol_version = "repository.provider_error.v0",
                    class = "world",
                    code = "target_exists",
                    stage = "rename_noreplace",
                    errno = nil,
                    mutation_primitive_entered = true,
                    published = false,
                    cost = {tool_calls = 1, file_writes = 1, time_ms = 0},
                }
            end
            state.files[request.relative_path] = request.content
            if request.relative_path == "later.lua" then
                probe.request, probe.err = candidate_seal.prepare(
                    grown.instance, grown.services)
                probe.root = assert(capabilities.root_authority(grown.registry, {
                    grant_id = grown.grant.grant_id,
                }))
            end
            return {
                protocol_version = "repository.provider_result.v0",
                operation = "create_text_file",
                outcome = "created",
                bytes = #request.content,
                root = fixture.copy(state.root_identity),
                mutation_primitive_entered = true,
                published = true,
                cost = {tool_calls = 1, file_writes = 1, time_ms = 0},
            }
        end,
    })
    assert(candidate_seal.prepare(grown.instance, grown.services))

    local other = fixture.packet({{
        path = "later.lua",
        content = "return 'in-flight'\n",
    }}, {label = "candidate-hostile-in-flight-writer"})
    local intent = assert(repository_intent.derive(other, {
        max_items = other.regime.encoding.bounds.max_output_units,
    }))
    local action = assert(repository_action.authorize(other, intent, grown.registry, {
        session_id = other.session_id,
        lineage_id = other.lineage_id,
        generation = other.generation,
        repository_id = other.repository_id,
        work_mode = "build",
    }))
    local request = assert(repository_action.materialize(
        other, action, grown.registry))
    local lease = assert(capabilities.begin_effect(grown.registry, action, other))
    assert(capabilities.effect_create(grown.registry, lease, request))

    H.assert_nil(probe.request, "seal request cannot cross provider entry")
    H.assert_eq(error_code(probe.err), "candidate_lifecycle_not_ready",
        "in-flight authority is a typed readiness failure")
    H.assert_eq(probe.root.active_dispatch_count, 1,
        "failure was observed while one exact call was in flight")
    local root = assert(capabilities.root_authority(grown.registry, {
        grant_id = grown.grant.grant_id,
    }))
    H.assert_eq(root.state, "materializing", "in-flight probe enters no pending state")
    H.assert_eq(root.active_dispatch_count, 0, "provider return clears in-flight truth")
end)

suite:check("ST08/ST09 seal_pending closes every source-write entrance", function()
    local grown = completed("candidate-hostile-pending-authority")
    local seal_request = assert(candidate_seal.prepare(
        grown.instance, grown.services))
    local seal_lease = assert(capabilities.begin_candidate_seal(
        grown.registry, seal_request))
    local calls_before = grown.state.calls.create

    local other = fixture.packet({{
        path = "pending.lua",
        content = "return 'denied'\n",
    }}, {label = "candidate-hostile-pending-writer"})
    local intent = assert(repository_intent.derive(other, {
        max_items = other.regime.encoding.bounds.max_output_units,
    }))
    local action, action_err = repository_action.authorize(
        other, intent, grown.registry, {
            session_id = other.session_id,
            lineage_id = other.lineage_id,
            generation = other.generation,
            repository_id = other.repository_id,
            work_mode = "build",
        })
    H.assert_nil(action, "new action cannot be authorized while seal is pending")
    H.assert_eq(error_code(action_err), "repository_root_seal_pending",
        "action denial names pending root")

    local minted, mint_err = capabilities.mint(
        grown.registry, fixture.grant_input())
    H.assert_nil(minted, "new grant cannot reopen a pending root")
    H.assert_eq(error_code(mint_err), "repository_root_seal_pending",
        "mint denial names pending root")
    local resolved, resolve_err = capabilities.resolve(grown.registry, {
        session_id = grown.instance.session_id,
        lineage_id = grown.instance.lineage_id,
        generation = grown.instance.generation,
        repository_id = grown.instance.repository_id,
        operation = "create_text_file",
    })
    H.assert_nil(resolved, "pending grant cannot resolve")
    H.assert_eq(error_code(resolve_err), "repository_root_seal_pending",
        "resolve denial names pending root")
    H.assert_eq(grown.state.calls.create, calls_before,
        "pending denials enter no provider")

    assert(capabilities.quarantine_candidate_seal(
        grown.registry,
        seal_lease,
        {code = "test_pending_cleanup", phase = "test"}
    ))
end)

suite:check("ST07 consumed lease has no mass but dies at seal boundary", function()
    local grown = completed("candidate-hostile-old-lease")
    local other = fixture.packet({{
        path = "later.lua",
        content = "return 'never materialized'\n",
    }}, {
        label = "candidate-hostile-old-lease-other",
        packet_options = {generation = grown.instance.generation},
    })
    local intent = assert(repository_intent.derive(other, {
        max_items = other.regime.encoding.bounds.max_output_units,
    }))
    local action = assert(repository_action.authorize(other, intent, grown.registry, {
        session_id = other.session_id,
        lineage_id = other.lineage_id,
        generation = other.generation,
        repository_id = other.repository_id,
        work_mode = "build",
    }))
    local effect_request = assert(repository_action.materialize(
        other, action, grown.registry))
    local old_lease = assert(capabilities.begin_effect(
        grown.registry, action, other))

    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")
    assert(candidate_seal.execute(grown.instance, request, grown.services))
    local result, err = capabilities.effect_create(
        grown.registry, old_lease, effect_request)
    H.assert_nil(result, "pre-seal effect lease cannot write after closure")
    H.assert_eq(type(err) == "table" and err.code or nil,
        "repository_root_sealed", "old lease sees terminal root")
    H.assert_nil(grown.state.files["later.lua"], "old lease changes no world")
end)

suite:check("ST10 terminal root denies same and descendant generations", function()
    local grown = completed("candidate-hostile-terminal-authority")
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")
    assert(candidate_seal.execute(grown.instance, request, grown.services))
    local inventory_calls = grown.state.calls.inventory
    local create_calls = grown.state.calls.create

    local minted, mint_err = capabilities.mint(
        grown.registry, fixture.grant_input())
    H.assert_nil(minted, "sealed root cannot mint fresh source authority")
    H.assert_eq(error_code(mint_err), "repository_root_sealed",
        "mint denial names terminal root")

    local resolved, resolve_err = capabilities.resolve(grown.registry, {
        session_id = grown.instance.session_id,
        lineage_id = grown.instance.lineage_id,
        generation = grown.instance.generation,
        repository_id = grown.instance.repository_id,
        operation = "create_text_file",
    })
    H.assert_nil(resolved, "sealed root cannot resolve old source authority")
    H.assert_eq(error_code(resolve_err), "repository_root_sealed",
        "resolve denial names terminal root")

    local descendant, descendant_err = capabilities.resolve(grown.registry, {
        session_id = grown.instance.session_id,
        lineage_id = grown.instance.lineage_id,
        generation = grown.instance.generation + 1,
        repository_id = grown.instance.repository_id,
        operation = "create_text_file",
    })
    H.assert_nil(descendant, "descendant cannot reopen ancestor root")
    H.assert_eq(error_code(descendant_err), "repository_root_sealed",
        "descendant sees the terminal root lock")

    local other = fixture.packet({{
        path = "src/after-seal.lua",
        content = "return 'denied'\n",
    }}, {label = "candidate-hostile-after-seal"})
    local intent = assert(repository_intent.derive(other, {
        max_items = other.regime.encoding.bounds.max_output_units,
    }))
    local action = repository_action.authorize(other, intent, grown.registry, {
        session_id = other.session_id,
        lineage_id = other.lineage_id,
        generation = other.generation,
        repository_id = other.repository_id,
        work_mode = "build",
    })
    H.assert_nil(action, "new action cannot cross sealed authority")
    H.assert_eq(grown.state.calls.create, create_calls,
        "terminal denials enter no create provider")
    H.assert_eq(grown.state.calls.inventory, inventory_calls,
        "terminal denials enter no inventory provider")
end)

suite:check("ST27-ST29 post-commit append failure stays sealed and loud", function()
    local grown = completed("candidate-hostile-split-brain")
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")

    local real_body = require("runtime.body")
    local failing_body = setmetatable({
        record_candidate_seal = function()
            return nil, "forced candidate seal append failure"
        end,
    }, {__index = real_body})
    package.loaded["runtime.body"] = failing_body
    local called, result, err, loud = pcall(
        candidate_seal.execute,
        grown.instance,
        request,
        grown.services
    )
    package.loaded["runtime.body"] = real_body
    H.assert_true(called, "injected writer returns through the public contract")
    H.assert_nil(result, "private commit is not reported as public success")
    H.assert_contains(err, "forced", "append failure remains exact")
    H.assert_true(loud, "post-commit append failure is harness-red")

    local root = assert(capabilities.root_authority(grown.registry, {
        root_authority_id = request.root_authority_id,
    }))
    H.assert_eq(root.state, "sealed", "private terminal truth is never rolled back")
    local seal, _, seal_err = candidate_seal.current(grown.instance)
    H.assert_nil(seal, "failed append leaves no public half")
    H.assert_eq(seal_err, "candidate_seal_absent", "public absence is exact")

    local repeated, repeated_err, repeated_loud = candidate_seal.execute(
        grown.instance, request, grown.services)
    H.assert_nil(repeated, "split brain cannot become idempotent success")
    H.assert_contains(repeated_err, "no matching body event",
        "retry names the missing public half")
    H.assert_true(repeated_loud, "split brain remains harness-red")
    H.assert_eq(grown.state.calls.inventory, 1,
        "retry performs no second provider observation")
end)

suite:check("ST25 changed request cannot replay a sealed root", function()
    local grown = completed("candidate-hostile-changed-replay")
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")
    assert(candidate_seal.execute(grown.instance, request, grown.services))
    local calls_before = grown.state.calls.inventory
    local trace_before = #grown.instance.trace

    request.inventory_bounds.max_entries = request.inventory_bounds.max_entries + 1
    reidentify_request(request)
    local repeated, err, loud = candidate_seal.execute(
        grown.instance, request, grown.services)
    H.assert_nil(repeated, "changed request cannot reuse old closure")
    H.assert_true(loud, "changed request against terminal truth is harness-red")
    H.assert_contains(err, "no private closure",
        "body/private disagreement is named")
    H.assert_eq(grown.state.calls.inventory, calls_before,
        "changed replay enters no provider")
    H.assert_eq(#grown.instance.trace, trace_before,
        "changed replay appends no body fact")
end)

suite:check("ST26 closure receipt must match private sealed state", function()
    local body = require("runtime.body")
    local grown = completed("candidate-hostile-closure-contradiction")
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")
    local result = assert(candidate_seal.execute(
        grown.instance, request, grown.services))
    local trace_before = #grown.instance.trace
    local old_closure_id = result.closure.closure_id
    local forged_closure = fixture.copy(result.closure)
    forged_closure.inventory_digest = string.rep("0", 64)
    reidentify_closure(forged_closure)
    local forged_seal = fixture.copy(result.seal)
    forged_seal.inventory_digest = forged_closure.inventory_digest
    forged_seal.authority_closure_ref = forged_closure.closure_id
    for index, ref in ipairs(forged_seal.source_refs) do
        if ref == old_closure_id then
            forged_seal.source_refs[index] = forged_closure.closure_id
        end
    end
    table.sort(forged_seal.source_refs)
    reidentify_seal(forged_seal)

    local stored, err = body.record_candidate_seal(
        grown.instance,
        forged_seal,
        grown.registry,
        forged_closure
    )
    H.assert_nil(stored, "schema-valid forged closure cannot become body truth")
    H.assert_contains(err, "private registry",
        "writer checks the independent private surface")
    H.assert_eq(#grown.instance.trace, trace_before,
        "closure contradiction appends no event")
    local observed = assert(capabilities.observe_candidate_closure(
        grown.registry,
        {
            root_authority_id = request.root_authority_id,
            lifecycle_id = request.lifecycle_id,
            request_id = request.request_id,
        }
    ))
    H.assert_true(observed.inventory_digest ~= forged_closure.inventory_digest,
        "forged return values cannot rewrite private closure")
end)

suite:check("ST32 malformed trusted inventory quarantines loudly", function()
    local grown
    grown = completed("candidate-hostile-malformed", {
        inventory_override = function(_, bounds, state)
            local result = exact_inventory(bounds, state)
            result.forged_authority = true
            return result
        end,
    })
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")
    local result, err, loud = candidate_seal.execute(
        grown.instance, request, grown.services)
    H.assert_nil(result, "malformed trusted result cannot seal")
    H.assert_true(loud, "trusted schema corruption remains harness-red")
    H.assert_contains(err, "unknown", "unknown authority field is named")
    H.assert_eq(grown.instance.status, "running", "corruption is not pretty mortality")
    local root = assert(capabilities.root_authority(grown.registry, {
        root_authority_id = request.root_authority_id,
    }))
    H.assert_eq(root.state, "quarantined", "defensive root closure survives loud error")
end)

suite:check("RACE-CLASS unstable observation quarantines", function()
    local grown = completed("candidate-hostile-unstable", {
        inventory_override = function(_, bounds, state)
            local result = exact_inventory(bounds, state)
            result.stable = false
            return result
        end,
    })
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")
    local result, err, loud = candidate_seal.execute(
        grown.instance, request, grown.services)
    H.assert_nil(result, "unstable tree cannot seal")
    H.assert_true(substrate_contract.is_effect_failure(err),
        "schema-valid world ambiguity is typed")
    H.assert_false(loud, "world ambiguity is not harness corruption")
    local root = assert(capabilities.root_authority(grown.registry, {
        root_authority_id = request.root_authority_id,
    }))
    H.assert_eq(root.state, "quarantined", "unstable observation closes authority")
end)

suite:check("ST21 aggregate byte bound permits only two-proof abort", function()
    local grown = completed("candidate-hostile-bound", {
        files = {['zz-extra.bin'] = string.rep("x", 64)},
    })
    local expected_bytes = #grown.state.files["src/main.lua"]
    local request = assert(candidate_seal.prepare(grown.instance, grown.services, {
        inventory_bounds = {
            protocol_version = "repository.inventory_bounds.v0",
            max_entries = 16,
            max_depth = 8,
            max_path_bytes = 128,
            max_component_bytes = 64,
            max_file_bytes = 128,
            max_total_bytes = expected_bytes + 1,
        },
    }))
    fixture.move_to(grown.instance, "☶")
    local result, err, loud = candidate_seal.execute(
        grown.instance, request, grown.services)
    H.assert_nil(result, "bounded incomplete observation cannot seal")
    H.assert_eq(err.code, "candidate_inventory_bound_exceeded",
        "bound outcome is typed")
    H.assert_false(loud, "bounded root-continuous outcome proves no closure")
    local root = assert(capabilities.root_authority(grown.registry, {
        root_authority_id = request.root_authority_id,
    }))
    H.assert_eq(root.state, "materializing", "two-proof bounded abort reopens owner")
end)

suite:check("ST14 stable extra empty directory cannot seal", function()
    local grown = completed("candidate-hostile-extra-directory", {
        inventory_override = function(_, bounds, state)
            local result = exact_inventory(bounds, state)
            local identity = {device = 17, inode = 3999}
            result.entries[#result.entries + 1] = {
                relative_path = "zz-empty",
                kind = "directory",
                identity_before = fixture.copy(identity),
                identity_after = fixture.copy(identity),
            }
            table.sort(result.entries, function(left, right)
                return left.relative_path < right.relative_path
            end)
            result.bounds_observed.observed_entries = #result.entries
            return result
        end,
    })
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")
    local result, err, loud = candidate_seal.execute(
        grown.instance, request, grown.services)
    H.assert_nil(result, "undeclared empty directory cannot seal")
    H.assert_eq(error_code(err), "candidate_inventory_mismatch",
        "extra directory is an exact mismatch")
    H.assert_false(loud, "stable extra directory is body pressure, not corruption")
    local root = assert(capabilities.root_authority(grown.registry, {
        root_authority_id = request.root_authority_id,
    }))
    H.assert_eq(root.state, "materializing", "stable mismatch proves safe abort")
end)

suite:check("ST15 stable missing declared file cannot seal", function()
    local grown = completed("candidate-hostile-missing-file", {
        inventory_override = function(_, bounds, state)
            local result = exact_inventory(bounds, state)
            result.entries = {result.entries[1]}
            result.bounds_observed.observed_entries = 1
            result.bounds_observed.observed_total_bytes = 0
            return result
        end,
    })
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")
    local result, err, loud = candidate_seal.execute(
        grown.instance, request, grown.services)
    H.assert_nil(result, "missing expected file cannot seal")
    H.assert_eq(error_code(err), "candidate_inventory_mismatch",
        "missing file is an exact mismatch")
    H.assert_false(loud, "stable missing file is body pressure, not corruption")
end)

suite:check("ST16/ST17 native inventory never follows symlink or special", function()
    local native_build = require("tests.support.repository_native_build")
    local roots = require("tests.support.owned_temp_root")
    assert(native_build.ensure_loader_fixtures())
    package.loaded["runtime.repository_provider"] = nil
    local provider = require("runtime.repository_provider")
    local function quote(value)
        return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
    end
    assert(roots.with_root(function(root)
        local outside = root.path .. "/outside-secret"
        local file = assert(io.open(outside, "wb"))
        assert(file:write("must-not-cross-inventory-boundary\n"))
        assert(file:close())
        assert(os.execute("ln -s " .. quote(outside) .. " "
            .. quote(root.repository .. "/src/link")))
        assert(os.execute("mkfifo " .. quote(root.repository .. "/src/fifo")))
        local handle = assert(provider.open_repository({
            project_base = root.project_base,
            repository_path = "repo",
        }))
        local observed = assert(provider.inventory_tree(handle,
            candidate_seal.default_inventory_bounds))
        local kinds = {}
        for _, entry in ipairs(observed.entries) do
            kinds[entry.relative_path] = entry.kind
            if entry.kind ~= "regular_file" then
                H.assert_nil(entry.content, "non-file is never opened for bytes")
            end
        end
        H.assert_eq(kinds["src/link"], "symlink", "final symlink is visible")
        H.assert_eq(kinds["src/fifo"], "special", "fifo is visible as special")
        H.assert_true(observed.stable, "static hostile tree has stable evidence")
        assert(provider.close(handle))
        return true
    end))
end)

suite:check("ST18 native inventory order and repeated projection are canonical", function()
    local native_build = require("tests.support.repository_native_build")
    local roots = require("tests.support.owned_temp_root")
    assert(native_build.ensure_loader_fixtures())
    package.loaded["runtime.repository_provider"] = nil
    local provider = require("runtime.repository_provider")
    assert(roots.with_root(function(root)
        local handle = assert(provider.open_repository({
            project_base = root.project_base,
            repository_path = "repo",
        }))
        for _, path in ipairs({"src/z.lua", "src/a.lua", "src/m.lua"}) do
            local content = "return " .. string.format("%q", path) .. "\n"
            assert(provider.create_text_file(handle, {
                protocol_version = "repository.create_text_file.request.v0",
                relative_path = path,
                content = content,
                content_bytes = #content,
                precondition = "absent",
                file_mode = 384,
            }))
        end
        local first = assert(provider.inventory_tree(
            handle, candidate_seal.default_inventory_bounds))
        local second = assert(provider.inventory_tree(
            handle, candidate_seal.default_inventory_bounds))
        local paths = {}
        for index, entry in ipairs(first.entries) do
            paths[index] = entry.relative_path
        end
        H.assert_eq(table.concat(paths, ","),
            "src,src/a.lua,src/m.lua,src/z.lua",
            "native output is path-byte ordered, not readdir ordered")
        H.assert_eq(json.encode(first.entries), json.encode(second.entries),
            "unchanged tree has one deterministic inventory projection")
        assert(provider.close(handle))
        return true
    end))
end)

suite:check("ST21b native inventory stops before aggregate allocation", function()
    local native_build = require("tests.support.repository_native_build")
    local roots = require("tests.support.owned_temp_root")
    assert(native_build.ensure_loader_fixtures())
    package.loaded["runtime.repository_provider"] = nil
    local provider = require("runtime.repository_provider")
    assert(roots.with_root(function(root)
        local handle = assert(provider.open_repository({
            project_base = root.project_base,
            repository_path = "repo",
        }))
        assert(provider.create_text_file(handle, {
            protocol_version = "repository.create_text_file.request.v0",
            relative_path = "src/large.lua",
            content = "return 'larger-than-bound'\n",
            content_bytes = #"return 'larger-than-bound'\n",
            precondition = "absent",
            file_mode = 384,
        }))
        local bounds = fixture.copy(candidate_seal.default_inventory_bounds)
        bounds.max_total_bytes = 4
        local observed = assert(provider.inventory_tree(handle, bounds))
        H.assert_eq(observed.outcome, "bound_exceeded", "native bound is typed")
        H.assert_eq(observed.bounds_observed.observed_total_bytes, 0,
            "over-bound file bytes were never allocated")
        H.assert_true(observed.stable, "root continuity survives bounded stop")
        assert(provider.close(handle))
        return true
    end))
end)

suite:finish()
print("test_candidate_seal_hostile ok")
