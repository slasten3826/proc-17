package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local fixture = require("tests.support.repository_hands")
local capabilities, capabilities_err = H.optional_require("runtime.repository_capability")
local suite = H.new("repository-capability")

local function require_capabilities()
    return suite:require_module(
        capabilities,
        capabilities_err,
        "runtime.repository_capability"
    )
end

local function code(value)
    return type(value) == "table" and value.code or tostring(value)
end

local function resolve(registry, overrides)
    local context = {
        session_id = "session-repository-hands",
        lineage_id = "lineage-repository-hands",
        generation = 1,
        repository_id = "repo-a",
        operation = "create_text_file",
    }
    for key, value in pairs(overrides or {}) do
        context[key] = value
    end
    return capabilities.resolve(registry, context)
end

suite:check("G0 no grant cannot authorize", function()
    local cap = require_capabilities()
    local provider = fixture.fake_provider()
    local registry = assert(cap.new({
        session_id = "session-repository-hands",
        providers = {[provider.provider_id] = provider},
    }))
    local match, err = resolve(registry)
    H.assert_nil(match, "empty registry must not resolve")
    H.assert_eq(code(err), "missing_capability", "absence is typed")
end)

suite:check("G1 semantic grant name has no authority", function()
    local cap = require_capabilities()
    local provider = fixture.fake_provider()
    local registry = assert(cap.new({
        session_id = "session-repository-hands",
        providers = {[provider.provider_id] = provider},
    }))
    local match, err = resolve(registry, {
        semantic_grant_id = "repository-grant:plausible",
    })
    H.assert_nil(match, "semantic text cannot create registry state")
    H.assert_eq(code(err), "missing_capability", "semantic id changes nothing")

    local active = fixture.new_registry(cap)
    local resolved = assert(resolve(active, {
        semantic_grant_id = "repository-grant:forged",
    }))
    H.assert_eq(resolved.repository_id, "repo-a",
        "semantic id cannot redirect an existing exact grant")
end)

suite:check("G2 exact active grant resolves without leaking authority", function()
    local cap = require_capabilities()
    local registry, projection = fixture.new_registry(cap)
    local match = assert(resolve(registry))
    H.assert_eq(match.grant_id, projection.grant_id, "exact grant resolves")
    H.assert_eq(match.repository_id, "repo-a", "repository identity is public")
    H.assert_nil(match.provider, "provider object stays private")
    H.assert_nil(match.repository_handle, "native handle stays private")
    H.assert_nil(match.host_path, "absolute path stays private")
end)

suite:check("G3 wrong session does not match", function()
    local cap = require_capabilities()
    local registry = fixture.new_registry(cap)
    local match, err = resolve(registry, {session_id = "session-other"})
    H.assert_nil(match, "wrong session denied")
    H.assert_eq(code(err), "missing_capability", "wrong session reveals no grant")
end)

suite:check("G4 wrong lineage and foreign descendant do not match", function()
    local cap = require_capabilities()
    local registry = fixture.new_registry(cap)
    local wrong = resolve(registry, {lineage_id = "lineage-other"})
    H.assert_nil(wrong, "foreign lineage denied")
    local descendant = resolve(registry, {
        lineage_id = "lineage-other",
        generation = 2,
    })
    H.assert_nil(descendant, "foreign descendant denied")
end)

suite:check("G5 same lineage next generation re-resolves", function()
    local cap = require_capabilities()
    local registry, projection = fixture.new_registry(cap)
    local match = assert(resolve(registry, {generation = 2}))
    H.assert_eq(match.grant_id, projection.grant_id, "grant survives Packet death")
    H.assert_eq(match.lineage_id, "lineage-repository-hands", "lineage remains exact")
end)

suite:check("G6 revoked grant is excluded", function()
    local cap = require_capabilities()
    local registry, projection = fixture.new_registry(cap)
    local revoked = assert(cap.revoke(registry, projection.grant_id))
    H.assert_eq(revoked.state, "revoked", "revocation is visible")
    local match, err = resolve(registry)
    H.assert_nil(match, "revoked grant cannot resolve")
    H.assert_eq(code(err), "revoked_capability", "revocation is typed")
end)

suite:check("G8 two exact grants are ambiguous", function()
    local cap = require_capabilities()
    local registry = fixture.new_registry(cap)
    assert(cap.mint(registry, fixture.grant_input()))
    local match, err = resolve(registry)
    H.assert_nil(match, "body cannot choose between grants")
    H.assert_eq(code(err), "ambiguous_capability", "ambiguity is typed")
end)

suite:check("G9 removed create operation removes match", function()
    local cap = require_capabilities()
    local provider = fixture.fake_provider()
    local registry = assert(cap.new({
        session_id = "session-repository-hands",
        providers = {[provider.provider_id] = provider},
    }))
    assert(cap.mint(registry, fixture.grant_input({
        operations = {create_text_file = false},
    })))
    local match, err = resolve(registry)
    H.assert_nil(match, "disabled operation cannot authorize")
    H.assert_eq(code(err), "missing_capability", "operation mismatch is typed")
end)

suite:check("G10 returned projection cannot mutate private grant", function()
    local cap = require_capabilities()
    local registry, projection = fixture.new_registry(cap)
    projection.bounds.max_content_bytes = 1
    projection.operations[1] = "delete_repository"
    projection.root_fingerprint = "forged"
    local match = assert(resolve(registry))
    H.assert_eq(match.bounds.max_content_bytes, 4096, "private bound survives alias attack")
    H.assert_eq(match.operations[1], "create_text_file", "operation survives alias attack")
    H.assert_false(match.root_fingerprint == "forged", "root fingerprint survives alias attack")
end)

suite:check("G11 repository substitution is denied", function()
    local cap = require_capabilities()
    local registry = fixture.new_registry(cap)
    local match = resolve(registry, {repository_id = "repo-b"})
    H.assert_nil(match, "repo-A grant cannot authorize repo-B")
end)

suite:check("grant bounds and policy are strict", function()
    local cap = require_capabilities()
    local provider = fixture.fake_provider()
    local registry = assert(cap.new({
        session_id = "session-repository-hands",
        providers = {[provider.provider_id] = provider},
    }))
    local bad, err = cap.mint(registry, fixture.grant_input({
        bounds = {
            max_relative_path_bytes = 0,
            max_content_bytes = 64,
            max_effects_per_generation = 1,
        },
    }))
    H.assert_nil(bad, "zero path bound rejected")
    H.assert_contains(err, "positive", "bound error is explicit")

    local unknown = cap.mint(registry, fixture.grant_input({
        policy = {file_mode = 384, shell = true},
    }))
    H.assert_nil(unknown, "unknown host policy rejected")
end)

suite:finish()
print("test_repository_capability ok")
