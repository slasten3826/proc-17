package.path = "./?.lua;./?/init.lua;" .. package.path

local deepseek = require("substrates.deepseek")
local flow_domain = require("runtime.flow_domain")
local tension_runner = require("runtime.tension_runner")

local function fail(message)
    io.stderr:write("smoke_deepseek_qualified_encode_choose failed: "
        .. tostring(message) .. "\n")
    os.exit(1)
end

local function assert_eq(left, right, message)
    if left ~= right then
        fail((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right))
    end
end

local function operator_text(result)
    local operators = {}
    for _, tick in ipairs(result.ticks or {}) do
        operators[#operators + 1] = tick.operator
    end
    return table.concat(operators)
end

local function last_substrate_text(instance)
    local fragments = instance.chaos and instance.chaos.fragments or {}
    for index = #fragments, 1, -1 do
        if fragments[index].kind == "substrate_response" then
            return fragments[index].text
        end
    end
    return nil
end

local prompts = {
    sequence = table.concat({
        "Return exactly one JSON object and nothing else.",
        "Do not use Markdown or a code fence.",
        "Plan three ordered steps for checking and fixing one Lua defect.",
        "Use exactly these top-level keys:",
        "protocol_version, receiver_contract_id, shape, items, edges.",
        "Set protocol_version to packet.structure.proposal.v0.",
        "Set receiver_contract_id to calm.work_structure.v0.",
        "Set shape to work_sequence.",
        "Each item must have exactly key, kind, value, source_keys.",
        "Use kind work_item and an empty source_keys array.",
        "Use an empty edges array. Do not add a choice key.",
    }, "\n"),
    alternatives = table.concat({
        "Return exactly one JSON object and nothing else.",
        "Do not use Markdown or a code fence.",
        "Describe exactly two mutually exclusive choices for storing tiny notes:",
        "one JSON file or one SQLite database.",
        "Use exactly these top-level keys:",
        "protocol_version, receiver_contract_id, shape, items, edges, choice.",
        "Set protocol_version to packet.structure.proposal.v0.",
        "Set receiver_contract_id to calm.work_structure.v0.",
        "Set shape to alternative_set.",
        "Each item must have exactly key, kind, value, source_keys.",
        "Use kind work_item and an empty source_keys array.",
        "Use an empty edges array.",
        "Set choice to an object whose only key is kind and value is mutually_exclusive.",
    }, "\n"),
}

local cases = {
    {
        name = "sequence",
        expected_trace = "☴☵☴",
        expected_choices = 0,
    },
    {
        name = "alternatives",
        expected_trace = "☴☵☴☳☴",
        expected_choices = 1,
    },
}

if not os.getenv("DEEPSEEK_API_KEY") then
    fail("DEEPSEEK_API_KEY is not set")
end

for index, case in ipairs(cases) do
    local domain, domain_err = flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = "deepseek-qualified-" .. case.name,
        source_ref = "smoke:deepseek-qualified:" .. case.name,
    })
    if not domain then
        fail(domain_err)
    end

    local instance, result = tension_runner.run(prompts[case.name], deepseek, {
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        ablate_relation_consumer = true,
        work_mode = "plan",
        max_ticks = 6,
        legacy_shadow = false,
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = domain,
            projection_adapter = "vertical_single.v0",
        },
        substrate_options = {
            model = os.getenv("DEEPSEEK_MODEL") or "deepseek-chat",
            temperature = 0,
        },
    })
    if not instance then
        fail(case.name .. ": " .. tostring(result))
    end

    local trace = operator_text(result)
    if trace ~= case.expected_trace then
        fail(table.concat({
            case.name .. " unexpected trace",
            "expected=" .. case.expected_trace,
            "actual=" .. trace,
            "stop_reason=" .. tostring(result.stop_reason),
            "no_viable_cause=" .. tostring(
                result.no_viable_edge and result.no_viable_edge.cause
            ),
            "substrate=" .. tostring(last_substrate_text(instance)),
        }, " | "))
    end
    assert_eq(#(instance.boundary.choices or {}), case.expected_choices,
        case.name .. " boundary choice count")
    assert_eq(result.stop_reason, "stalled", case.name .. " stop reason")
    assert_eq(result.no_viable_edge and result.no_viable_edge.cause,
        "no_qualified_need", case.name .. " terminal pressure boundary")

    print(table.concat({
        "deepseek-qualified",
        case.name,
        "trace=" .. trace,
        "choices=" .. tostring(#(instance.boundary.choices or {})),
        "loss=" .. string.format("%.3f", instance.tension.loss or 0),
        "stop=" .. tostring(result.stop_reason),
    }, " "))

    if index < #cases then
        print("---")
    end
end

print("smoke_deepseek_qualified_encode_choose ok")
