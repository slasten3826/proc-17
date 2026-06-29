local hints = {}

hints.density = "short"

local definitions = {
    ["▽"] = {
        operator = "▽",
        role = "task enters body as pressure before form",
        hints = {
            "Flow is input pressure before form.",
            "Do not solve before the packet is born.",
            "Record the task as received before transforming it.",
        },
        trace_pressure = {
            "raw task visible",
            "mode explicit",
            "first transformation traceable",
        },
    },
    ["☰"] = {
        operator = "☰",
        role = "bind sources and relations without fusion",
        hints = {
            "Connection is not fusion.",
            "Bind source to field item.",
            "Keep relation evidence visible.",
        },
        trace_pressure = {
            "source identity preserved",
            "relation evidence visible",
            "relation type explicit when possible",
        },
    },
    ["☷"] = {
        operator = "☷",
        role = "remove false solidity and preserve residue",
        hints = {
            "Dissolve removes false form, not evidence.",
            "Unsupported form should leave residue.",
            "Weakening is not deletion.",
        },
        trace_pressure = {
            "unsupported material leaves reasoned residue",
            "false runtime claims are weakened",
            "runtime evidence is not destroyed",
        },
    },
    ["☵"] = {
        operator = "☵",
        role = "form addressable field from inspectable/runtime-shaped material",
        hints = {
            "Encoding is not copying.",
            "Structure has cost.",
            "Show what was omitted, compressed, or made addressable.",
            "Do not promote prose into runtime truth.",
        },
        trace_pressure = {
            "field shape explicit",
            "loss visible",
            "source truth status preserved",
            "prose remains semantic unless engineering pressure is explicit",
        },
    },
    ["☳"] = {
        operator = "☳",
        role = "irreversible collapse of alternatives",
        hints = {
            "Choice kills alternatives.",
            "A choice without killed alternatives is only confirmation.",
            "Record what was not chosen.",
            "Do not invent criteria after collapse.",
        },
        trace_pressure = {
            "selected visible",
            "killed visible or counted",
            "collapse level explicit",
            "criteria visible before or during collapse",
        },
    },
    ["☴"] = {
        operator = "☴",
        role = "read evidence without mutation",
        hints = {
            "Observe reads without mutating.",
            "Observation is not confirmation.",
            "Raw evidence should enter before interpretation.",
        },
        trace_pressure = {
            "target explicit",
            "raw evidence preserved",
            "observed status not promoted to validated truth",
        },
    },
    ["☲"] = {
        operator = "☲",
        role = "bounded continuation decision",
        hints = {
            "Continuation must be paid.",
            "Cycle is not immortality.",
            "Stop when pressure is exhausted or repetition becomes false life.",
        },
        trace_pressure = {
            "continuation reason visible",
            "repetition detectable",
            "budget pressure considered",
            "stop accepted as valid output",
        },
    },
    ["☶"] = {
        operator = "☶",
        role = "cheap rule boundary",
        hints = {
            "Rule does not create truth.",
            "Rule rejects unsupported form.",
            "Semantic proposal remains semantic until runtime confirms it.",
        },
        trace_pressure = {
            "rejection reason explicit",
            "runtime truth not invented by wording",
            "rules remain inspectable",
        },
    },
    ["☱"] = {
        operator = "☱",
        role = "read body state, budgets, pressure, residue, manifest readiness",
        hints = {
            "Runtime reads the body, not the idea.",
            "Pressure is current state, not interpretation.",
            "Memory is re-decoding available trace.",
        },
        trace_pressure = {
            "budget visible",
            "last events visible",
            "residue visible",
            "readiness based on body state",
        },
    },
    ["△"] = {
        operator = "△",
        role = "output boundary and form death",
        hints = {
            "Manifest is form death.",
            "Output must not hide residue.",
            "Completion kills the packet.",
        },
        trace_pressure = {
            "external output separate from internal trace",
            "death cause explicit",
            "residue remains after completion",
        },
    },
}

local order = {"▽", "☰", "☷", "☵", "☳", "☴", "☲", "☶", "☱", "△"}

local function copy_list(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = value
    end
    return result
end

local function copy_definition(definition)
    return {
        operator = definition.operator,
        role = definition.role,
        hints = copy_list(definition.hints),
        trace_pressure = copy_list(definition.trace_pressure),
    }
end

function hints.all()
    local active = {}
    for _, operator in ipairs(order) do
        active[#active + 1] = copy_definition(definitions[operator])
    end
    return active
end

function hints.payload(options)
    options = options or {}
    local enabled = options.enabled ~= false
    if not enabled then
        return {
            enabled = false,
            density = hints.density,
            active = {},
        }
    end

    return {
        enabled = true,
        density = hints.density,
        active = hints.all(),
    }
end

function hints.count(payload)
    local count = 0
    for _, item in ipairs(payload and payload.active or {}) do
        count = count + #(item.hints or {})
    end
    return count
end

function hints.trace_payload(payload, reason)
    payload = payload or hints.payload({enabled = false})
    local operators = {}
    for _, item in ipairs(payload.active or {}) do
        operators[#operators + 1] = item.operator
    end

    return {
        enabled = payload.enabled == true,
        density = payload.density or hints.density,
        reason = reason or "default",
        operators = operators,
        hint_count = hints.count(payload),
    }
end

function hints.format_for_substrate(payload)
    if not payload or payload.enabled ~= true then
        return nil
    end

    local lines = {
        "[operator runtime hints]",
        "These are local pressure hints, not runtime truth.",
    }
    for _, item in ipairs(payload.active or {}) do
        lines[#lines + 1] = string.format("%s %s:", item.operator, item.role)
        for _, hint in ipairs(item.hints or {}) do
            lines[#lines + 1] = "- " .. hint
        end
    end
    return table.concat(lines, "\n")
end

return hints
