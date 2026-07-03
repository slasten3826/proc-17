package.path = "./?.lua;./?/init.lua;" .. package.path

local choose = require("logic.choose")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": " .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function collapse(input)
    local payload, err = choose.choose(input)
    if not payload then
        error("choose failed: " .. tostring(err))
    end
    return payload
end

local field = {
    truth_status = "runtime_confirmed",
    items = {
        {id = "a", kind = "file", value = "a.lua", truth_status = "runtime_confirmed"},
        {id = "b", kind = "file", value = "b.lua", truth_status = "runtime_confirmed"},
        {id = "c", kind = "file", value = "c.lua", truth_status = "runtime_confirmed"},
        {id = "d", kind = "file", value = "d.lua", truth_status = "runtime_confirmed"},
    },
}

local payload = collapse({
    field = field,
    limits = {max_selected = 2, max_killed_sample = 1},
    pressure = {
        budget_pressure = "bounded",
        attention_pressure = "high",
    },
    semantic_ranking = {
        truth_status = "semantic_proposal",
        items = {
            {id = "c", reason = "substrate ranked c"},
            {id = "missing", reason = "unknown reference"},
            {id = "a", reason = "substrate ranked a"},
        },
    },
})

assert_eq(payload.kind, "choose_collapse_payload", "payload kind")
assert_eq(payload.truth_status, "runtime_confirmed", "truth status")
assert_eq(#payload.selected, 2, "selected count")
assert_eq(payload.selected[1].id, "c", "semantic ranking order first")
assert_eq(payload.selected[2].id, "a", "semantic ranking order second")
assert_eq(payload.selected[1].selection_truth_status, "runtime_confirmed", "selection truth")
assert_eq(payload.selected[1].source_truth_status, "runtime_confirmed", "source truth")
assert_eq(payload.selected[1].reason.truth_status, "semantic_proposal", "semantic reason stays semantic")
assert_eq(payload.selected[1].reason.text, "substrate ranked c", "semantic reason text")
assert_eq(payload.chosen.id, "c", "chosen alias first selected")

assert_eq(payload.not_chosen_count, 2, "not chosen count")
assert_eq(payload.loss.kind, "attention_collapse", "loss kind")
assert_eq(payload.loss.not_chosen_count, 2, "loss count")
assert_eq(payload.loss.truncated, true, "killed sample truncated")
assert_eq(payload.choice_loss.before_count, 4, "choice loss before count")
assert_eq(payload.choice_loss.after_count, 2, "choice loss after count")
assert_eq(#payload.killed_alternatives, 1, "bounded killed alternatives")
assert_eq(payload.choice_pressure.attention_pressure, "high", "choice pressure copied")
assert_eq(payload.choice_basis.order, "semantic_ranking_then_field_order", "choice basis")
assert_eq(payload.loss.collapse_level, "item", "default collapse level")

payload.choice_pressure.attention_pressure = "mutated"
local payload_again = collapse({
    field = field,
    limits = {max_selected = 2, max_killed_sample = 1},
    pressure = {
        budget_pressure = "bounded",
        attention_pressure = "high",
    },
    semantic_ranking = {
        truth_status = "semantic_proposal",
        items = {
            {id = "c", reason = "substrate ranked c"},
            {id = "missing", reason = "unknown reference"},
            {id = "a", reason = "substrate ranked a"},
        },
    },
})

assert_eq(payload_again.choice_pressure.attention_pressure, "high", "choice should copy pressure")
assert_eq(payload_again.selected[1].id, "c", "deterministic selected item")
assert_eq(payload_again.not_chosen_count, 2, "deterministic loss")

local field_order = collapse({
    field = field,
    limits = {max_selected = 1, max_killed_sample = 8},
})

assert_eq(field_order.selected[1].id, "a", "field order fallback")
assert_eq(field_order.selected[1].reason.truth_status, "unknown", "field order reason unknown")
assert_eq(field_order.loss.truncated, false, "untruncated killed sample")
assert_eq(#field_order.killed_alternatives, 3, "full killed sample when small")

assert_eq(field_order.can_continue, nil, "choose must not decide continuation")
assert_eq(field_order.next_action, nil, "choose must not choose next action")
assert_eq(field_order.accepted_paths, nil, "choose must not validate paths")
assert_eq(field_order.final_answer, nil, "choose must not manifest")

local value_ranked = collapse({
    field = field,
    limits = {max_selected = 1},
    semantic_ranking = {
        truth_status = "semantic_proposal",
        items = {
            {id = "line:1", value = "b.lua", reason = "ranked by value"},
        },
    },
})

assert_eq(value_ranked.selected[1].id, "b", "semantic ranking should prefer value over line id")
assert_eq(value_ranked.selected[1].reason.truth_status, "semantic_proposal", "value rank reason stays semantic")

local structured_field = {
    shape = "structured_reflection_field",
    intent = "preserve_reflection",
    truth_status = "semantic_proposal",
    items = {
        {id = "section:1", kind = "section", value = "3 strongest next pressures", role = "container", truth_status = "semantic_proposal"},
        {id = "line:1", kind = "section_child", value = "pressure A", role = "alternative", parent_id = "section:1", truth_status = "semantic_proposal"},
        {id = "line:2", kind = "section_child", value = "pressure B", role = "alternative", parent_id = "section:1", truth_status = "semantic_proposal"},
        {id = "section:2", kind = "section", value = "3 things not to implement yet", role = "container", truth_status = "semantic_proposal"},
        {id = "line:3", kind = "section_child", value = "router", role = "alternative", parent_id = "section:2", truth_status = "semantic_proposal"},
    },
}

local structured = collapse({
    field = structured_field,
    limits = {max_selected = 2, max_killed_sample = 8},
    pressure = {
        field_shape = "structured_reflection_field",
        field_intent = "preserve_reflection",
        collapse_level = "child",
    },
})

assert_eq(structured.loss.collapse_level, "child", "structured collapse level")
assert_eq(#structured.selected, 2, "structured selected count")
assert_eq(structured.selected[1].id, "line:1", "structured skips section header")
assert_eq(structured.selected[2].id, "line:2", "structured selects children")
assert_eq(structured.killed_alternatives[1].id, "line:3", "structured kills only child alternative")
assert_eq(structured.not_chosen_count, 1, "structured not chosen counts eligible alternatives")

local sequence_field = {
    truth_status = "semantic_proposal",
    structure = {
        kind = "sequence",
        steps = {
            {id = "s1", order = 1},
            {id = "s2", order = 2},
        },
    },
    items = {
        {id = "s1", kind = "semantic_line", value = "first step", role = "alternative", truth_status = "semantic_proposal"},
        {id = "s2", kind = "semantic_line", value = "second step", role = "alternative", truth_status = "semantic_proposal"},
    },
}

local sequence_choice = collapse({
    field = sequence_field,
    limits = {max_selected = 1, max_killed_sample = 8},
})

assert_eq(sequence_choice.loss.collapse_level, "step", "sequence collapses by step")
assert_eq(sequence_choice.collapse_type, "next_step", "sequence collapse type")
assert_eq(sequence_choice.chosen.id, "s1", "sequence chooses first step")
assert_eq(sequence_choice.killed_alternatives[1].id, "s2", "sequence kills later step")

local single_choice = collapse({
    field = {
        truth_status = "runtime_confirmed",
        structure = {kind = "language"},
        items = {
            {id = "only", kind = "semantic_line", value = "only option", truth_status = "runtime_confirmed"},
        },
    },
    limits = {max_selected = 1, max_killed_sample = 8},
})

assert_eq(single_choice.collapse_type, "confirmation", "single item is confirmation")
assert_eq(single_choice.not_chosen_count, 0, "confirmation kills nothing")
assert_eq(#single_choice.killed_alternatives, 0, "confirmation killed empty")

local missing, missing_err = choose.choose({})
assert_true(not missing, "missing field should fail")
assert_eq(missing_err, "missing_field", "missing field error")

local invalid_items, invalid_items_err = choose.choose({field = {items = {"bad"}}})
assert_true(not invalid_items, "invalid field items should fail")
assert_eq(invalid_items_err, "invalid_field_items", "invalid field items error")

local empty, empty_err = choose.choose({field = {items = {}}})
assert_true(not empty, "empty field should fail")
assert_eq(empty_err, "empty_field", "empty field error")

local invalid_limits, invalid_limits_err = choose.choose({
    field = field,
    limits = {max_selected = 0},
})
assert_true(not invalid_limits, "invalid limits should fail")
assert_eq(invalid_limits_err, "invalid_limits", "invalid limits error")

print("test_choose ok")
