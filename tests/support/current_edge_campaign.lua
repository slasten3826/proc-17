local digest = require("core.digest")
local edge_corpus = require("runtime.edge_corpus")
local edge_life_projection = require("runtime.edge_life_projection")
local edge_report = require("runtime.edge_current_report")
local flow_domain = require("runtime.flow_domain")
local tension_runner = require("runtime.tension_runner")
local fake = require("substrates.fake")

local campaign = {}

local function copy_value(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function tagged(value)
    return "sha256:" .. assert(digest.record(value))
end

local function one_life_id(ledger)
    local result
    for life_id in pairs(ledger.source_lives or {}) do
        assert(result == nil, "campaign life ledger contains multiple lives")
        result = life_id
    end
    return assert(result, "campaign life ledger contains no life")
end

local function packet_options(label)
    return {
        id = "packet:i10:" .. label,
        lineage_id = "lineage:i10:" .. label,
        session_id = "session:i10",
        budget = {
            steps = 12,
            substrate_calls = 12,
            tool_calls = 8,
            encode_items = 16,
            loss = 8,
        },
    }
end

local function evidence(label, case_id)
    return {
        case_id = case_id,
        corpus_layer = "L0",
        evidence_run_id = "run:i10:" .. label,
    }
end

local function vertical_life(label)
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = "stream:i10:" .. label,
        source_ref = "fixture:i10:" .. label,
    }))
    return {
        protocol_version = "vertical_packet_life.v0",
        flow_domain = domain,
        projection_adapter = "vertical_pair.v0",
    }
end

local function ordinary_options(label, case_id, overrides)
    local options = {
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        legacy_shadow = false,
        work_mode = "plan",
        max_ticks = 2,
        packet_options = packet_options(label),
        edge_evidence = evidence(label, case_id),
    }
    for key, value in pairs(overrides or {}) do options[key] = value end
    return options
end

local failing_substrate = {
    ask = function()
        return nil, {
            kind = "effect_failure",
            source = "substrate",
            code = "connection_lost",
            message = "i10 injected typed failure",
            source_refs = {},
            retryability = "retryable",
            cost = {substrate_calls = 1},
            event_truth_status = "runtime_confirmed",
        }
    end,
}

local definitions = {
    {
        label = "tree-qualified",
        prompt = "i10 qualified tree life",
        case_id = "P01",
        substrate = fake,
        options = ordinary_options("tree-qualified", "P01", {
            legacy_shadow = true,
        }),
    },
    {
        label = "tree-observer-off",
        prompt = "i10 observer ablation life",
        case_id = "P08",
        substrate = fake,
        options = ordinary_options("tree-observer-off", "P08"),
    },
    {
        label = "tree-relation-ablation",
        prompt = "i10 relation consumer ablation life",
        case_id = "P10",
        substrate = nil,
        options = ordinary_options("tree-relation-ablation", "P10", {
            max_ticks = 2,
            ablate_relation_consumer = true,
            packet_life = vertical_life("tree-relation-ablation"),
        }),
    },
    {
        label = "tree-binary-control",
        prompt = "i10 binary policy control life",
        case_id = "P09",
        substrate = fake,
        options = ordinary_options("tree-binary-control", "P09", {
            pressure_policy = "sampled",
        }),
    },
    {
        label = "legacy-control",
        prompt = "i10 legacy control life",
        case_id = "P02",
        substrate = fake,
        options = ordinary_options("legacy-control", "P02", {
            router_mode = "legacy",
            pressure_policy = nil,
            max_ticks = 2,
        }),
    },
    {
        label = "tree-harness-taint",
        prompt = "i10 harness movement taint life",
        case_id = "P04",
        substrate = fake,
        options = ordinary_options("tree-harness-taint", "P04", {
            max_ticks = 2,
            tree_test_override = true,
        }),
    },
    {
        label = "tree-effect-failure",
        prompt = "i10 typed substrate failure life",
        case_id = "P05",
        substrate = failing_substrate,
        options = ordinary_options("tree-effect-failure", "P05", {
            max_ticks = 2,
        }),
    },
}

local function provenance(revision, label)
    return {
        source_revision = revision,
        worktree_state = "clean",
        artifact_digest = tagged({
            campaign = edge_report.protocol_version,
            revision = revision,
            label = label,
        }),
        event_truth_status = "runtime_confirmed",
        content_truth_status = "runtime_confirmed",
        verifier_ref = "tests.support.current_edge_campaign:" .. label,
    }
end

local function grow_life(definition, revision)
    local instance, result = assert(tension_runner.run(
        definition.prompt,
        definition.substrate,
        copy_value(definition.options)
    ))
    assert(result.authority_instrument == "v3",
        "campaign must exercise the canonical default instrument")
    assert(result.edge_stats and result.edge_stats.protocol_version == "edge-stats.v3",
        "campaign must produce a canonical v3 ledger")
    local life_id = one_life_id(result.edge_stats)
    local projected = assert(edge_life_projection.capture(
        instance,
        result,
        nil,
        {life_id = life_id}
    ))
    return {
        label = definition.label,
        case_id = definition.case_id,
        life_id = life_id,
        instance = instance,
        result = result,
        projection = projected,
        provenance = provenance(revision, definition.label),
    }
end

function campaign.build(revision)
    assert(type(revision) == "string" and revision ~= "",
        "campaign revision is required")
    local corpus = assert(edge_corpus.new({
        corpus_id = "corpus:i10:current-authority-evidence:" .. revision,
        authority_claim = "diagnostic",
    }))
    local lives = {}
    for _, definition in ipairs(definitions) do
        local life = grow_life(definition, revision)
        assert(edge_corpus.add_life(
            corpus,
            life.result,
            life.projection,
            life.provenance
        ))
        lives[#lives + 1] = life
    end
    local current_report = assert(edge_report.build(corpus, {
        implementation_revision = revision,
    }))
    return {
        corpus = corpus,
        lives = lives,
        report = current_report,
    }
end

function campaign.definitions()
    local result = {}
    for _, definition in ipairs(definitions) do
        result[#result + 1] = {
            label = definition.label,
            case_id = definition.case_id,
        }
    end
    return result
end

return campaign
