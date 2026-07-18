local l1 = {
    protocol_version = "l1.field.v0",
    snapshot_protocol_version = "l1.snapshot.v0",
    interpreter_contract = "lua-5.4",
}

local MOD = 59049
local MAX_SOURCE_UNITS = 16384
local CRAZY_TABLE = {
    {1, 0, 0},
    {1, 0, 2},
    {2, 2, 1},
}

local function is_integer(value)
    return type(value) == "number" and math.type(value) == "integer"
end

local function crazy(a, d)
    local result = 0
    local power = 1
    local aa = a
    local dd = d

    for _ = 1, 10 do
        local ax = aa % 3
        local dx = dd % 3
        result = result + CRAZY_TABLE[dx + 1][ax + 1] * power
        aa = math.floor(aa / 3)
        dd = math.floor(dd / 3)
        power = power * 3
    end

    return result % MOD
end

local function validate_interpreter()
    if _VERSION ~= "Lua 5.4" then
        return nil, "L1 requires Lua 5.4"
    end
    return true
end

local function validate_state(state)
    if type(state) ~= "table" or state.protocol_version ~= l1.protocol_version then
        return nil, "invalid L1 state"
    end
    if state.interpreter_contract ~= l1.interpreter_contract
        or state.variant ~= "C" or state.modulus ~= MOD then
        return nil, "invalid L1 state contract"
    end
    if not is_integer(state.ring_size) or state.ring_size < 3
        or state.ring_size > MAX_SOURCE_UNITS then
        return nil, "invalid L1 ring size"
    end
    if type(state.core) ~= "table" or #state.core ~= state.ring_size
        or type(state.l1_trace) ~= "table" or #state.l1_trace ~= state.ring_size
        or type(state.phase) ~= "table" or #state.phase ~= state.ring_size then
        return nil, "invalid L1 field arrays"
    end
    if not is_integer(state.carry) or not is_integer(state.position)
        or state.position < 1 or state.position > state.ring_size
        or not is_integer(state.ticks) or state.ticks < 0 then
        return nil, "invalid L1 scalar state"
    end
    if type(state.frozen) ~= "boolean" or type(state.source) ~= "table"
        or type(state.source.ref) ~= "string" or state.source.ref == ""
        or state.source.count ~= state.ring_size then
        return nil, "invalid L1 state provenance"
    end
    return true
end

local function distinct_count(values)
    local seen = {}
    local count = 0
    for index = 1, #values do
        local value = values[index]
        if not seen[value] then
            seen[value] = true
            count = count + 1
        end
    end
    return count
end

local function trace_density(values)
    local active = 0
    for index = 1, #values do
        if values[index] ~= 0 then
            active = active + 1
        end
    end
    return active
end

local function fingerprint(state)
    local h = state.carry % MOD
    h = crazy(h, state.core[state.position])
    h = crazy(h, state.l1_trace[state.position])
    h = crazy(h, state.position - 1)
    return h
end

function l1.initialize(source, options)
    local interpreter_ok, interpreter_err = validate_interpreter()
    if not interpreter_ok then
        return nil, interpreter_err
    end

    options = options or {}
    if type(source) ~= "table" then
        return nil, "L1 source must be an array"
    end
    if options.variant ~= nil and options.variant ~= "C" then
        return nil, "L1 v0 supports only variant C"
    end
    local source_ref = options.source_ref
    if type(source_ref) ~= "string" or source_ref == "" then
        return nil, "L1 source_ref must be a non-empty string"
    end

    local max_source_units = options.max_source_units or MAX_SOURCE_UNITS
    if not is_integer(max_source_units) or max_source_units < 3
        or max_source_units > MAX_SOURCE_UNITS then
        return nil, "L1 max_source_units must be an integer from 3 to 16384"
    end

    local ring_size = #source
    if ring_size < 3 then
        return nil, "L1 source must contain at least 3 integers"
    end
    if ring_size > max_source_units then
        return nil, "L1 source exceeds max_source_units"
    end

    local core = {}
    local l1_trace = {}
    local phase = {}
    for index = 1, ring_size do
        local value = source[index]
        if not is_integer(value) then
            return nil, "L1 source values must be Lua 5.4 integers"
        end
        core[index] = value % MOD
        phase[index] = (index - 1) % 3
        l1_trace[index] = crazy(core[index], phase[index])
    end

    return {
        protocol_version = l1.protocol_version,
        interpreter_contract = l1.interpreter_contract,
        variant = "C",
        modulus = MOD,
        ring_size = ring_size,
        core = core,
        l1_trace = l1_trace,
        phase = phase,
        carry = source[1] % MOD,
        position = 1,
        ticks = 0,
        frozen = false,
        source = {
            ref = source_ref,
            count = ring_size,
        },
    }
end

function l1.tick(state)
    local valid, state_err = validate_state(state)
    if not valid then
        return nil, state_err
    end
    if state.frozen then
        return nil, "L1 state is frozen"
    end

    local p = state.position
    local q = (p % state.ring_size) + 1
    local bias = crazy(state.phase[p], (p - 1) % MOD)
    local operand = crazy(crazy(state.core[p], state.l1_trace[p]), bias)
    local result = crazy(state.carry, operand)

    state.carry = result
    state.core[p] = crazy(result, state.l1_trace[p])
    state.l1_trace[p] = crazy(state.l1_trace[p], bias)
    state.position = q
    state.ticks = state.ticks + 1

    return state
end

function l1.snapshot(state)
    local valid, state_err = validate_state(state)
    if not valid then
        return nil, state_err
    end

    return {
        protocol_version = l1.snapshot_protocol_version,
        variant = state.variant,
        tick = state.ticks,
        position = state.position,
        carry = state.carry,
        fingerprint = fingerprint(state),
        trace_density = trace_density(state.l1_trace),
        distinct_core = distinct_count(state.core),
        distinct_l1_trace = distinct_count(state.l1_trace),
        ring_size = state.ring_size,
        source_ref = state.source.ref,
        event_truth_status = "runtime_confirmed",
        content_truth_status = "non_semantic_measurement",
    }
end

function l1.freeze(state)
    local valid, state_err = validate_state(state)
    if not valid then
        return nil, state_err
    end
    state.frozen = true
    return state
end

return l1
