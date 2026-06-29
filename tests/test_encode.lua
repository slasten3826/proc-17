package.path = "./?.lua;./?/init.lua;" .. package.path

local encode = require("logic.encode")

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

local function encode_ok(input)
    local payload, err = encode.encode(input)
    if not payload then
        error("encode failed: " .. tostring(err))
    end
    return payload
end

local repo_payload = encode_ok({
    repo_listing = {
        kind = "repo_listing_payload",
        truth_status = "runtime_confirmed",
        entries = {
            {kind = "directory", path = "logic", truth_status = "runtime_confirmed"},
            {kind = "file", path = "logic/encode.lua", truth_status = "runtime_confirmed"},
            {kind = "file", path = "logic/choose.lua", truth_status = "runtime_confirmed"},
        },
    },
    limits = {max_items = 8},
})

assert_eq(repo_payload.kind, "encoded_field_payload", "payload kind")
assert_eq(repo_payload.truth_status, "runtime_confirmed", "payload truth")
assert_eq(repo_payload.field.truth_status, "runtime_confirmed", "repo field truth")
assert_eq(#repo_payload.field.items, 2, "repo items count")
assert_eq(repo_payload.field.items[1].kind, "repo_path", "repo item kind")
assert_eq(repo_payload.field.items[1].value, "logic/encode.lua", "repo item value")
assert_eq(repo_payload.field.items[1].source_kind, "repo_listing_entry", "repo source kind")
assert_eq(repo_payload.field.items[1].source_truth_status, "runtime_confirmed", "repo source truth")
assert_eq(repo_payload.field.items[1].content_truth_status, "runtime_confirmed", "repo content truth")
assert_eq(repo_payload.field.items[1].encoding_truth_status, "runtime_confirmed", "repo encoding truth")
assert_true(#repo_payload.connections >= 2, "repo connections should be carried")
assert_eq(repo_payload.connections[1].relation_kind, "repo_path_to_listing", "repo relation kind")
assert_eq(repo_payload.loss.kind, "source_projection", "repo loss kind")
assert_eq(repo_payload.loss.input_count, 2, "repo input count")
assert_eq(repo_payload.loss.output_count, 2, "repo output count")
assert_eq(repo_payload.loss.omitted_count, 0, "repo omitted count")
assert_eq(repo_payload.loss.truncated, false, "repo truncated")

local semantic_payload = encode_ok({
    substrate_result = {
        text = "1. alpha\n2. beta\n- alpha\n",
    },
    limits = {max_items = 8},
})

assert_eq(semantic_payload.field.truth_status, "semantic_proposal", "semantic field truth")
assert_eq(#semantic_payload.field.items, 2, "deduped semantic line count")
assert_eq(semantic_payload.field.items[1].id, "line:1", "semantic line id")
assert_eq(semantic_payload.field.items[1].kind, "semantic_line", "semantic item kind")
assert_eq(semantic_payload.field.items[1].value, "alpha", "semantic item value")
assert_eq(semantic_payload.field.items[1].source_truth_status, "semantic_proposal", "semantic source truth")
assert_eq(semantic_payload.field.items[1].encoding_truth_status, "runtime_confirmed", "semantic encoding truth")
assert_eq(semantic_payload.loss.kind, "field_compression", "semantic loss kind")
assert_eq(semantic_payload.field.shape, "semantic_line_field", "semantic field shape")
assert_eq(semantic_payload.field.intent, "rank_candidates", "semantic field intent")

local structured_payload = encode_ok({
    substrate_result = {
        text = table.concat({
            "3 strongest next pressures:",
            "Automatic handoff is missing.",
            "ENCODE needs section shape.",
            "",
            "3 things not to implement yet:",
            "substrate_router",
            "real shell tool",
            "",
            "2 concrete next tests:",
            "test encode sections",
            "test choose sections",
        }, "\n"),
    },
    limits = {max_items = 16},
})

assert_eq(structured_payload.field.shape, "structured_reflection_field", "structured field shape")
assert_eq(structured_payload.field.intent, "preserve_reflection", "structured field intent")
assert_eq(structured_payload.field.items[1].kind, "section", "first structured item kind")
assert_eq(structured_payload.field.items[1].role, "container", "section role")
assert_eq(structured_payload.field.items[2].kind, "section_child", "child item kind")
assert_eq(structured_payload.field.items[2].role, "alternative", "child role")
assert_eq(structured_payload.field.items[2].parent_id, structured_payload.field.items[1].id, "child parent")
assert_eq(structured_payload.field.items[4].kind, "section", "second section kind")
assert_eq(structured_payload.loss.hierarchy_loss, false, "structured hierarchy preserved")

local limited_payload = encode_ok({
    substrate_result = {
        text = "a\nb\nc\n",
    },
    limits = {max_items = 2},
})

assert_eq(#limited_payload.field.items, 2, "limited output count")
assert_eq(limited_payload.loss.omitted_count, 1, "limited omitted count")
assert_eq(limited_payload.loss.truncated, true, "limited truncated")
assert_eq(limited_payload.field.shape, "semantic_line_field", "limited field shape")

local dissolved_payload = encode_ok({
    dissolved_records = {
        {
            target = "packet.promote_gap",
            old_status = "semantic_proposal",
            new_status = "unsupported_residue",
            dissolve_reason = "method_missing",
            residue = "substrate wants gap-promotion route",
            pressure_before = "formed_claim",
            pressure_after = "residue",
        },
    },
})

assert_eq(dissolved_payload.field.items[1].kind, "dissolved_residue", "dissolved item kind")
assert_eq(dissolved_payload.field.items[1].source_kind, "dissolved_record", "dissolved source kind")
assert_eq(dissolved_payload.field.items[1].content_truth_status, "unsupported_residue", "dissolved content truth")
assert_eq(dissolved_payload.loss.kind, "field_compression", "dissolved loss kind")
assert_eq(dissolved_payload.field.shape, "residue_field", "dissolved field shape")
assert_eq(dissolved_payload.field.intent, "carry_residue", "dissolved field intent")

local ranking_items = encode.response_line_items("1. x\n- y\n")
assert_eq(#ranking_items, 2, "ranking items count")
assert_eq(ranking_items[1].value, "x", "ranking strips numbering")
assert_eq(ranking_items[2].value, "y", "ranking strips bullet")

local empty, empty_err = encode.encode({})
assert_true(not empty, "empty sources should fail")
assert_eq(empty_err, "empty_sources", "empty error")

local invalid_limits, invalid_limits_err = encode.encode({
    substrate_result = {text = "x"},
    limits = {max_items = 0},
})
assert_true(not invalid_limits, "invalid limits should fail")
assert_eq(invalid_limits_err, "invalid_limits", "invalid limits error")

local invalid_connection, invalid_connection_err = encode.encode({
    substrate_result = {text = "x"},
    connections = {"bad"},
})
assert_true(not invalid_connection, "invalid connection should fail")
assert_eq(invalid_connection_err, "invalid_connection", "invalid connection error")

local invalid_dissolved, invalid_dissolved_err = encode.encode({
    dissolved_records = {{target = "x"}},
})
assert_true(not invalid_dissolved, "invalid dissolved record should fail")
assert_eq(invalid_dissolved_err, "invalid_dissolved_record", "invalid dissolved error")

print("test_encode ok")
