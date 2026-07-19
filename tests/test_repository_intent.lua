package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local fixture = require("tests.support.repository_hands")
local intent_module, intent_err = H.optional_require("runtime.repository_intent")
local suite = H.new("repository-intent")

local function require_intent()
    return suite:require_module(intent_module, intent_err, "runtime.repository_intent")
end

local function one(path, content, options)
    local instance = fixture.packet({{path = path, content = content}}, options)
    return instance
end

local function derive(instance)
    return intent_module.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    })
end

local function diagnostic_code(value)
    return type(value) == "table" and (value.code or value.kind) or tostring(value)
end

suite:check("A0 exact single artifact creates one stable intent", function()
    local intent = require_intent()
    local instance = one("src/main.lua", "return true\n")
    local first = assert(derive(instance))
    local second = assert(derive(instance))
    H.assert_eq(first.protocol_version, "repository.action_intent.v0", "intent protocol")
    H.assert_eq(first.intent_id, second.intent_id, "same exact state has stable identity")
    H.assert_eq(first.relative_path, "src/main.lua", "exact path retained")
    H.assert_eq(first.content_bytes, 12, "exact byte length computed")
    H.assert_nil(first.capability_id, "intent has no capability")
    H.assert_nil(first.repository_root, "intent has no root")
end)

suite:check("A1 required artifact set is not implicit choice", function()
    local intent = require_intent()
    local instance = fixture.packet({
        {path = "src/a.lua", content = "return 'a'\n"},
        {path = "src/b.lua", content = "return 'b'\n"},
    })
    local value, diagnostic = derive(instance)
    H.assert_nil(value, "v0 scheduler cannot silently pick one required file")
    H.assert_eq(diagnostic_code(diagnostic), "multi_item_scheduling_deferred",
        "deferral is typed")
    H.assert_eq(#(instance.boundary.choices or {}), 0, "no CHOOSE event is fabricated")
end)

suite:check("A2 real alternative set exposes only selected intent", function()
    local intent = require_intent()
    local instance = fixture.packet({
        {path = "src/a.lua", content = "return 'a'\n"},
        {path = "src/b.lua", content = "return 'b'\n"},
    }, {shape = "alternative_set", max_ticks = 4})
    local value = assert(derive(instance))
    local units = fixture.repository_units(instance)
    local selected = 0
    local suppressed = 0
    for _, unit in ipairs(units) do
        selected = selected + (unit.activation == "selected" and 1 or 0)
        suppressed = suppressed + (unit.activation == "suppressed" and 1 or 0)
    end
    H.assert_eq(selected, 1, "one real alternative selected")
    H.assert_eq(suppressed, 1, "one real alternative suppressed")
    H.assert_eq(value.source_unit_id, units[1].activation == "selected"
        and units[1].id or units[2].id, "intent names selected unit only")
end)

local invalid_paths = {
    P1 = "/tmp/outside.lua",
    P2 = "src/../outside.lua",
    P3 = "src//main.lua",
    P4 = ".hidden.lua",
    P5 = "src/bad\nname.lua",
}

for id, path in pairs(invalid_paths) do
    suite:check(id .. " invalid path is semantic diagnostic", function()
        local intent = require_intent()
        local instance = one(path, "return true\n")
        local value, diagnostic = derive(instance)
        H.assert_nil(value, "invalid path creates no intent")
        H.assert_eq(diagnostic_code(diagnostic), "invalid_relative_path",
            "invalid path is typed before authority")
    end)
end

suite:check("P5 invalid UTF-8 path and P7 invalid content reject", function()
    local intent = require_intent()
    local path_packet = one("src/bad\255.lua", "return true\n")
    local path_value, path_diagnostic = derive(path_packet)
    H.assert_nil(path_value, "invalid UTF-8 path rejected")
    H.assert_eq(diagnostic_code(path_diagnostic), "invalid_relative_path",
        "invalid path UTF-8 is typed")

    local content_packet = one("src/main.lua", "bad\0content")
    local content_value, content_diagnostic = derive(content_packet)
    H.assert_nil(content_value, "NUL content rejected")
    H.assert_eq(diagnostic_code(content_diagnostic), "invalid_text_content",
        "invalid content is typed")

    local utf8_packet = one("src/main.lua", "bad\255content")
    local utf8_value = derive(utf8_packet)
    H.assert_nil(utf8_value, "invalid UTF-8 content rejected")
end)

suite:check("A3-A5 path and content participate in intent identity", function()
    local intent = require_intent()
    local base = assert(derive(one("src/main.lua", "one\n")))
    local same = assert(derive(one("src/main.lua", "one\n")))
    local changed_path = assert(derive(one("src/other.lua", "one\n")))
    local changed_content = assert(derive(one("src/main.lua", "two\n")))
    H.assert_eq(base.content_sha256, same.content_sha256, "same content digest")
    H.assert_false(base.intent_id == changed_path.intent_id, "path changes intent")
    H.assert_false(base.intent_id == changed_content.intent_id, "content changes intent")
    H.assert_false(base.content_sha256 == changed_content.content_sha256,
        "content changes digest")
end)

suite:check("A0 empty text remains an exact file intent", function()
    local intent = require_intent()
    local value = assert(derive(one("src/empty.lua", "")))
    H.assert_eq(value.content_bytes, 0, "empty content has exact zero length")
    H.assert_eq(#value.content_sha256, 64, "empty content is still digested")
end)

suite:check("unsupported item kind creates no repository intent", function()
    local intent = require_intent()
    local instance = fixture.packet({{
        kind = "repository.delete_tree.v0",
        value = {path = "src/main.lua", content = "ignored"},
    }})
    local value, diagnostic = derive(instance)
    H.assert_nil(value, "unsupported operation creates no intent")
    H.assert_eq(diagnostic_code(diagnostic), "unsupported_repository_item",
        "unsupported kind is visible")
end)

suite:finish()
print("test_repository_intent ok")
