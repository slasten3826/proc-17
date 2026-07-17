package.path = "./?.lua;./?/init.lua;" .. package.path

-- Step 4.2 permanent gate: runtime-confirmed rejection survives manifestation.

local tension_runner = require("runtime.tension_runner")
local reconciliation = require("runtime.reconciliation")
local fake = require("substrates.fake")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local instance, result = assert(tension_runner.run(
    "build artifact whose validation is rejected",
    fake,
    {
        router_mode = "tree",
        work_mode = "build",
        max_ticks = 64,
        packet_options = {
            budget = {
                steps = 64,
                substrate_calls = 16,
                tool_calls = 8,
                encode_items = 16,
                loss = 10,
            },
        },
        choose = {
            limits = {max_selected = 1, max_killed_sample = 8},
        },
        logic = {
            spells = {
                {
                    kind = "check_file_exists",
                    name = "missing manifest honesty fixture",
                    intention = "grow runtime-confirmed rejected validation",
                    path = "sandbox/tree_manifest_honesty_missing.py",
                },
            },
        },
    }
))

local validation = instance.boundary.validations[#instance.boundary.validations]
local inspection = assert(reconciliation.inspect(instance))

local cases = {}
local function case(name, run)
    cases[#cases + 1] = {name = name, run = run}
end

case("rejection_and_blocked_runtime_are_confirmed", function()
    assert_eq(validation and validation.status, "rejected",
        "fixture grows rejected validation")
    assert_eq(inspection.completion_state, "blocked",
        "runtime classifies rejected work as blocked")
    assert_true(instance.manifest ~= nil and instance.terminal ~= nil,
        "fixture reaches the manifest boundary")
end)

case("legacy_observer_records_repair_dissent", function()
    local dissent
    for _, shadow in ipairs(result.shadow_routes or {}) do
        if shadow.observer == "legacy"
            and shadow.current_operator == "☱"
            and shadow.live_to == "△"
        then
            dissent = shadow
            break
        end
    end
    assert_true(dissent ~= nil, "legacy observer sees the rejected runtime edge")
    assert_eq(dissent.predicted_to, "☴", "historical policy predicts semantic repair")
    assert_eq(dissent.predicted_reason, "validation_rejected_semantic_repair",
        "dissent preserves its reason")
end)

case("rejection_reaches_internal_manifest_residue", function()
    local residue = instance.manifest and instance.manifest.residue or {}
    local residue_validation = residue.validation or {}
    assert_eq(residue_validation.rejected_count, 1,
        "manifest input already carries the rejected witness")
    assert_true(#(residue_validation.rejection_reasons or {}) > 0,
        "rejection reason survives internally")
end)

local honest_outcomes = {
    blocked = true,
    rejected = true,
    validation_rejected = true,
}

local function outward_outcome(manifest, terminal)
    manifest = manifest or {}
    local output = manifest.output or {}
    local summary = manifest.summary or {}
    local assembly = manifest.assembly or {}
    local function honest(value)
        return honest_outcomes[value] and value or nil
    end
    return honest(output.outcome)
        or honest(output.status)
        or honest(summary.outcome)
        or honest(summary.status)
        or honest(assembly.outcome)
        or honest(assembly.status)
        or honest(assembly.validation_status)
        or honest(terminal and terminal.cause)
end

case("blocked_runtime_is_outwardly_classified", function()
    local outcome = outward_outcome(instance.manifest, instance.terminal)
    assert_eq(outcome, "blocked", "outward result names blocked runtime")
    assert_eq(instance.manifest.output.status, "blocked", "primary output is blocked")
    assert_eq(instance.manifest.summary.status, "blocked", "summary is blocked")
    assert_eq(instance.manifest.assembly.outcome, "blocked", "assembly is blocked")
    assert_eq(instance.manifest.terminal_cause, "blocked", "payload terminal cause is blocked")
    assert_eq(instance.terminal.cause, "blocked", "Packet terminal cause is blocked")
    assert_eq(instance.death.cause, "blocked", "Packet death cause is blocked")
    assert_eq(instance.residue.cause, "blocked", "corpse residue cause is blocked")
    assert_eq(instance.manifest.output.text, "fake substrate response",
        "honest classification preserves substrate text")
end)

local green = 0
local red = 0
for _, value in ipairs(cases) do
    local ok, err = xpcall(value.run, debug.traceback)
    if ok then
        green = green + 1
        print("manifest-honesty gate GREEN " .. value.name)
    else
        red = red + 1
        local first_line = tostring(err):match("^[^\n]+") or tostring(err)
        print("manifest-honesty gate RED   " .. value.name .. " :: " .. first_line)
    end
end

print(string.format("manifest-honesty gate summary: green=%d red=%d", green, red))
if red > 0 then
    error("manifest honesty gate remains red: " .. tostring(red) .. " case(s)")
end

print("test_tree_manifest_honesty ok")
