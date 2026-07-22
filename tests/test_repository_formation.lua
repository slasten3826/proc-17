package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local packet_core = require("core.packet")
local fixture = require("tests.support.repository_hands")
local formation = require("runtime.repository_formation")
local suite = H.new("repository-formation")

local function code(value)
    return type(value) == "table" and (value.code or value.kind) or tostring(value)
end

local function one(label)
    return fixture.packet({{
        path = "src/main.lua",
        content = "return true\n",
    }}, {label = label})
end

suite:check("RF01 one exact live unit", function()
    local instance = one("formation-live")
    local unit = fixture.repository_units(instance)[1]
    local basis = assert(formation.for_unit(instance, unit.id, unit.version))
    H.assert_eq(basis.activation, "live", "live activation retained")
    H.assert_eq(basis.unit_created_event_ref, unit.created_event_id,
        "creation event is named")
    H.assert_true(type(basis.formation_event_ref) == "string",
        "formation event is named")
    H.assert_nil(basis.choice_event_ref, "required artifact set needs no choice")
end)

suite:check("RF02 selected unit requires grown CHOOSE", function()
    local instance = fixture.packet({
        {path = "src/a.lua", content = "return 'a'\n"},
        {path = "src/b.lua", content = "return 'b'\n"},
    }, {label = "formation-selected", shape = "alternative_set", max_ticks = 4})
    local units = fixture.repository_units(instance)
    local selected
    for _, unit in ipairs(units) do
        if unit.activation == "selected" then
            selected = unit
        end
    end
    local basis = assert(formation.for_unit(instance, selected.id, selected.version))
    H.assert_eq(basis.activation, "selected", "selected activation retained")
    H.assert_true(type(basis.choice_event_ref) == "string",
        "grown choice event is required")
    local set = assert(formation.current_set(instance))
    H.assert_eq(#set.units, 1, "suppressed peer is excluded")
    H.assert_eq(set.units[1].unit_id, selected.id, "selected unit is the set")
end)

suite:check("RF03 unresolved alternative set has no artifact authority", function()
    local instance = fixture.packet({
        {path = "src/a.lua", content = "return 'a'\n"},
        {path = "src/b.lua", content = "return 'b'\n"},
    }, {label = "formation-choice-missing", shape = "alternative_set", max_ticks = 2})
    local value, diagnostic = formation.current_set(instance)
    H.assert_nil(value, "unresolved alternatives do not become artifacts")
    H.assert_eq(code(diagnostic), "repository_choice_missing",
        "missing CHOOSE is typed")
end)

suite:check("RF04 suppressed peer cannot be read as current", function()
    local instance = fixture.packet({
        {path = "src/a.lua", content = "return 'a'\n"},
        {path = "src/b.lua", content = "return 'b'\n"},
    }, {label = "formation-suppressed", shape = "alternative_set", max_ticks = 4})
    local suppressed
    for _, unit in ipairs(fixture.repository_units(instance)) do
        if unit.activation == "suppressed" then
            suppressed = unit
        end
    end
    local value, diagnostic = formation.for_unit(
        instance,
        suppressed.id,
        suppressed.version
    )
    H.assert_nil(value, "suppressed unit is excluded")
    H.assert_eq(code(diagnostic), "repository_artifact_set_absent",
        "suppression is typed")
end)

suite:check("RF05 duplicate matching formations are ambiguous", function()
    local instance = one("formation-ambiguous")
    local unit = fixture.repository_units(instance)[1]
    local original
    for _, event in ipairs(instance.trace) do
        if event.type == "structure_formation" then
            original = event
        end
    end
    fixture.move_to(instance, "☵")
    assert(packet_core.append_event(instance, {
        type = "structure_formation",
        operator = "☵",
        truth_status = "runtime_confirmed",
        payload = H.copy(original.payload),
        cost = {},
    }))
    local value, diagnostic = formation.for_unit(instance, unit.id, unit.version)
    H.assert_nil(value, "two formation witnesses are not selected arbitrarily")
    H.assert_eq(code(diagnostic), "repository_formation_ambiguous",
        "ambiguity is typed")
end)

suite:check("RF06 stale requested version is rejected", function()
    local instance = one("formation-stale")
    local unit = fixture.repository_units(instance)[1]
    instance.field.units[unit.id].version = unit.version + 1
    local value, diagnostic = formation.for_unit(instance, unit.id, unit.version)
    H.assert_nil(value, "stale unit version is not read")
    H.assert_eq(code(diagnostic), "repository_artifact_stale", "stale is typed")
end)

suite:check("RF07 returned basis and set are detached", function()
    local instance = one("formation-detached")
    local unit = fixture.repository_units(instance)[1]
    local basis = assert(formation.for_unit(instance, unit.id, unit.version))
    local set = assert(formation.current_set(instance))
    basis.provenance_refs[1] = "caller-mutated"
    set.units[1].unit_id = "caller-mutated"
    local again = assert(formation.for_unit(instance, unit.id, unit.version))
    local set_again = assert(formation.current_set(instance))
    H.assert_false(again.provenance_refs[1] == "caller-mutated",
        "basis mutation does not alias body")
    H.assert_eq(set_again.units[1].unit_id, unit.id,
        "set mutation does not alias body")
end)

suite:finish()
print("test_repository_formation ok")
