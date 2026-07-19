local digest = require("core.digest")
local lineage_budget = require("runtime.lineage_budget")

local lineage = {
    protocol_version = "lineage.in_memory.v0",
}

local lineage_counter = 0

local TERMINAL_STATUSES = {
    suspended = true,
    complete = true,
    exhausted = true,
    terminated = true,
}

local STATUS_EVENTS = {
    suspended = "lineage_suspended",
    complete = "lineage_completed",
    exhausted = "lineage_exhausted",
    terminated = "lineage_terminated",
}

local function copy_value(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function next_lineage_id()
    lineage_counter = lineage_counter + 1
    return "lineage-" .. tostring(os.time()) .. "-" .. tostring(lineage_counter)
end

local function valid_id(value)
    return type(value) == "string" and value ~= ""
        and value:match("^[%w%._:%-]+$") ~= nil
end

local function now(input)
    return input and input.time or os.time()
end

local function validate_state(state)
    if type(state) ~= "table" or state.kind ~= "proc17_lineage"
        or state.protocol_version ~= lineage.protocol_version then
        return nil, "invalid lineage state"
    end
    return true
end

function lineage.append_event(state, input)
    local valid, valid_err = validate_state(state)
    if not valid then
        return nil, valid_err
    end
    input = input or {}
    if type(input.kind) ~= "string" or input.kind == "" then
        return nil, "lineage event kind is required"
    end
    local event = {
        id = "lineage-event:" .. tostring(#state.ledger + 1),
        kind = input.kind,
        lineage_id = state.lineage_id,
        generation = input.generation,
        packet_id = input.packet_id,
        corpse_id = input.corpse_id,
        carrier_id = input.carrier_id,
        transaction_key = input.transaction_key,
        payload = copy_value(input.payload or {}),
        source_refs = copy_value(input.source_refs or {}),
        event_truth_status = "runtime_confirmed",
        content_truth_statuses = copy_value(input.content_truth_statuses or {}),
        time = now(input),
    }
    state.ledger[#state.ledger + 1] = event
    return copy_value(event)
end

function lineage.create(task, options)
    options = options or {}
    if type(task) ~= "string" or task == "" then
        return nil, "lineage task must be non-empty string"
    end
    local work_mode = options.work_mode or "plan"
    if work_mode ~= "plan" and work_mode ~= "build" then
        return nil, "lineage work mode must be plan or build"
    end
    local lineage_id = options.lineage_id
    if lineage_id == nil and type(options.id_source) == "function" then
        lineage_id = options.id_source("lineage")
    end
    lineage_id = lineage_id or next_lineage_id()
    local session_id = options.session_id or "session-default"
    if not valid_id(lineage_id) or not valid_id(session_id) then
        return nil, "lineage and session ids must be safe non-empty strings"
    end
    local task_hash, hash_err = digest.sha256(task)
    if not task_hash then
        return nil, hash_err
    end
    local cumulative, budget_err = lineage_budget.new(options.budget or {})
    if not cumulative then
        return nil, budget_err
    end
    local carrier_policy = copy_value(options.carrier or {})
    if type(carrier_policy.max_bytes) ~= "number" or carrier_policy.max_bytes < 1
        or carrier_policy.max_bytes ~= math.floor(carrier_policy.max_bytes) then
        return nil, "lineage carrier.max_bytes must be integer >= 1"
    end

    local state = {
        kind = "proc17_lineage",
        protocol_version = lineage.protocol_version,
        lineage_id = lineage_id,
        session_id = session_id,
        status = "created",
        work_mode = work_mode,
        completion_contract_id = options.completion_contract_id or "plan.v0",
        task = {
            task_id = options.task_id or ("task:" .. task_hash:sub(1, 16)),
            payload = task,
            input_hash = task_hash,
            payload_bytes = #task,
            media_type = "text/plain",
            content_truth_status = options.content_truth_status or "semantic_proposal",
        },
        current_generation = 0,
        current_packet_id = nil,
        current_corpse_id = nil,
        current_carrier_id = nil,
        substrate_session_id = options.substrate_session_id,
        generations = {},
        ledger = {},
        budget = cumulative,
        policy = {
            history_enabled = options.history_enabled == true,
            allow_recovery = options.allow_recovery ~= false,
            carrier = carrier_policy,
            emergency_max_generations = options.emergency_max_generations,
        },
        continued_corpses = {},
        pending_generation = nil,
        terminal = nil,
    }
    local created, created_err = lineage.append_event(state, {
        kind = "lineage_created",
        payload = {
            work_mode = work_mode,
            completion_contract_id = state.completion_contract_id,
            task_id = state.task.task_id,
            input_hash = task_hash,
        },
        content_truth_statuses = {state.task.content_truth_status},
        time = options.time,
    })
    if not created then
        return nil, created_err
    end
    return state
end

function lineage.begin_generation(state, allocation, input)
    local valid, valid_err = validate_state(state)
    if not valid then
        return nil, valid_err
    end
    if state.status ~= "created" and state.status ~= "continuing" then
        return nil, "lineage is not ready to allocate a generation"
    end
    if state.pending_generation ~= nil then
        return nil, "lineage generation transaction is already pending"
    end
    local allocatable, allocation_err = lineage_budget.can_allocate(
        state.budget,
        allocation or {}
    )
    if not allocatable then
        return nil, allocation_err
    end
    local generation = state.current_generation + 1
    local transaction = {
        kind = "lineage_generation_transaction",
        protocol_version = "lineage.generation_transaction.v0",
        transaction_key = state.lineage_id .. ":generation:" .. tostring(generation),
        lineage_id = state.lineage_id,
        generation = generation,
        allocation = copy_value(allocation or {}),
        packet_budget = copy_value(input and input.packet_budget or allocation or {}),
        parent_packet_id = generation > 1 and state.current_packet_id or nil,
        parent_corpse_id = generation > 1 and state.current_corpse_id or nil,
        ingress_carrier_id = generation > 1 and state.current_carrier_id or nil,
        committed = false,
    }
    local event, event_err = lineage.append_event(state, {
        kind = "generation_allocated",
        generation = generation,
        transaction_key = transaction.transaction_key,
        payload = {allocation = transaction.allocation},
        source_refs = generation > 1 and {
            transaction.parent_corpse_id,
            transaction.ingress_carrier_id,
        } or {},
        time = input and input.time,
    })
    if not event then
        return nil, event_err
    end
    transaction.allocation_event_id = event.id
    state.pending_generation = transaction.transaction_key
    return transaction
end

function lineage.commit_birth(state, transaction, instance, birth_receipt, input)
    local valid, valid_err = validate_state(state)
    if not valid then
        return nil, valid_err
    end
    if type(transaction) ~= "table" or transaction.kind ~= "lineage_generation_transaction"
        or transaction.lineage_id ~= state.lineage_id then
        return nil, "invalid lineage generation transaction"
    end
    if transaction.committed == true then
        return nil, "generation transaction already committed"
    end
    if state.status ~= "created" and state.status ~= "continuing" then
        return nil, "lineage is not ready to commit a generation birth"
    end
    if state.pending_generation ~= transaction.transaction_key then
        return nil, "generation transaction is not current"
    end
    if type(instance) ~= "table" or not valid_id(instance.id)
        or instance.status ~= "born" or instance.operator ~= "▽" then
        return nil, "birth commit requires Packet"
    end
    if instance.lineage_id ~= state.lineage_id
        or instance.generation ~= transaction.generation
        or instance.parent_id ~= transaction.parent_packet_id
        or instance.parent_corpse_id ~= transaction.parent_corpse_id
        or instance.carrier_id ~= transaction.ingress_carrier_id then
        return nil, "Packet identity does not match generation transaction"
    end
    if type(birth_receipt) ~= "table"
        or birth_receipt.kind ~= "l1_packet_birth_receipt"
        or birth_receipt.protocol_version ~= "l1.packet_birth.v0"
        or birth_receipt.packet_id ~= instance.id
        or type(birth_receipt.domain_event_ref) ~= "string"
        or type(birth_receipt.flow_ref) ~= "table" then
        return nil, "birth receipt does not match Packet"
    end
    local charged, charge_err = lineage_budget.charge(
        state.budget,
        "generation:" .. tostring(transaction.generation),
        {generations = 1},
        {transaction.transaction_key, birth_receipt.domain_event_ref}
    )
    if not charged then
        return nil, charge_err
    end
    local budget_event, budget_event_err = lineage.append_event(state, {
        kind = "lineage_budget_spent",
        generation = transaction.generation,
        transaction_key = transaction.transaction_key,
        payload = charged,
        source_refs = {transaction.transaction_key, birth_receipt.domain_event_ref},
        time = input and input.time,
    })
    if not budget_event then
        return nil, budget_event_err
    end

    local entry = {
        generation = transaction.generation,
        packet_id = instance.id,
        parent_packet_id = transaction.parent_packet_id,
        parent_corpse_id = transaction.parent_corpse_id,
        ingress_carrier_id = transaction.ingress_carrier_id,
        corpse_id = nil,
        terminal_kind = nil,
        substrate_session_id = instance.substrate_session_id,
        local_budget_allocation = copy_value(transaction.packet_budget),
        born_event_id = nil,
        terminal_event_id = nil,
    }
    local event, event_err = lineage.append_event(state, {
        kind = "generation_born",
        generation = transaction.generation,
        packet_id = instance.id,
        carrier_id = transaction.ingress_carrier_id,
        transaction_key = transaction.transaction_key,
        payload = {
            birth_kind = instance.birth_kind,
            flow_ref = copy_value(birth_receipt.flow_ref),
            allocation = transaction.allocation,
        },
        source_refs = {
            transaction.allocation_event_id,
            budget_event.id,
            birth_receipt.domain_event_ref,
        },
        time = input and input.time,
    })
    if not event then
        return nil, event_err
    end
    entry.born_event_id = event.id
    state.generations[#state.generations + 1] = entry
    state.current_generation = transaction.generation
    state.current_packet_id = instance.id
    state.current_corpse_id = nil
    state.status = "running"
    state.pending_generation = nil
    transaction.committed = true
    return copy_value(entry)
end

function lineage.register_corpse(state, corpse, input)
    local valid, valid_err = validate_state(state)
    if not valid then
        return nil, valid_err
    end
    if state.status ~= "running" or type(corpse) ~= "table" then
        return nil, "lineage is not ready to register a corpse"
    end
    local entry = state.generations[#state.generations]
    if not entry or entry.packet_id ~= corpse.packet_id
        or entry.generation ~= corpse.generation
        or corpse.lineage_id ~= state.lineage_id then
        return nil, "corpse ancestry does not match current generation"
    end
    if entry.corpse_id ~= nil then
        return nil, "generation corpse already registered"
    end
    local terminal_event, terminal_err = lineage.append_event(state, {
        kind = "packet_terminal",
        generation = corpse.generation,
        packet_id = corpse.packet_id,
        corpse_id = corpse.corpse_id,
        payload = {
            terminal_kind = corpse.terminal_kind,
            death_cause = corpse.death_cause,
        },
        source_refs = {corpse.terminal_trace_ref},
        time = input and input.time,
    })
    if not terminal_event then
        return nil, terminal_err
    end
    local registered, registered_err = lineage.append_event(state, {
        kind = "corpse_registered",
        generation = corpse.generation,
        packet_id = corpse.packet_id,
        corpse_id = corpse.corpse_id,
        payload = {corpse_hash = corpse.corpse_hash},
        source_refs = {terminal_event.id, corpse.terminal_trace_ref},
        time = input and input.time,
    })
    if not registered then
        return nil, registered_err
    end
    entry.corpse_id = corpse.corpse_id
    entry.terminal_kind = corpse.terminal_kind
    entry.terminal_event_id = terminal_event.id
    state.current_corpse_id = corpse.corpse_id
    state.status = "evaluating_terminal"
    return copy_value(entry)
end

function lineage.mark_continued(state, corpse, carrier, input)
    local valid, valid_err = validate_state(state)
    if not valid then
        return nil, valid_err
    end
    if state.status ~= "evaluating_terminal" or type(corpse) ~= "table"
        or type(carrier) ~= "table" then
        return nil, "lineage is not ready for continuation"
    end
    if corpse.corpse_id ~= state.current_corpse_id
        or carrier.source_corpse_id ~= corpse.corpse_id then
        return nil, "continuation ancestry mismatch"
    end
    if state.continued_corpses[corpse.corpse_id] ~= nil then
        return nil, "source corpse already produced a child"
    end
    local event, event_err = lineage.append_event(state, {
        kind = "continuation_decided",
        generation = corpse.generation,
        packet_id = corpse.packet_id,
        corpse_id = corpse.corpse_id,
        carrier_id = carrier.carrier_id,
        payload = {decision = "continue", target_generation = carrier.target_generation},
        source_refs = {corpse.corpse_id, carrier.carrier_id},
        time = input and input.time,
    })
    if not event then
        return nil, event_err
    end
    state.continued_corpses[corpse.corpse_id] = carrier.carrier_id
    state.current_carrier_id = carrier.carrier_id
    state.status = "continuing"
    return true
end

function lineage.set_status(state, status, input)
    local valid, valid_err = validate_state(state)
    if not valid then
        return nil, valid_err
    end
    if status ~= "evaluating_terminal" and status ~= "continuing"
        and not TERMINAL_STATUSES[status] then
        return nil, "invalid lineage status transition target"
    end
    local event_kind = input and input.event_kind or STATUS_EVENTS[status]
    if type(event_kind) ~= "string" then
        return nil, "lineage status transition requires event kind"
    end
    local event, event_err = lineage.append_event(state, {
        kind = event_kind,
        generation = state.current_generation,
        packet_id = state.current_packet_id,
        corpse_id = state.current_corpse_id,
        carrier_id = state.current_carrier_id,
        payload = copy_value(input and input.payload or {}),
        source_refs = copy_value(input and input.source_refs or {}),
        time = input and input.time,
    })
    if not event then
        return nil, event_err
    end
    state.status = status
    return state, event
end

function lineage.finish(state, terminal)
    terminal = terminal or {}
    local status = terminal.status
    if not TERMINAL_STATUSES[status] then
        return nil, "lineage finish requires terminal status"
    end
    if TERMINAL_STATUSES[state.status] then
        return nil, "lineage is already terminal"
    end
    local updated, event_or_err = lineage.set_status(state, status, {
        payload = terminal,
        source_refs = terminal.source_refs,
        time = terminal.time,
    })
    if not updated then
        return nil, event_or_err
    end
    state.terminal = copy_value(terminal)
    state.terminal.event_id = event_or_err.id
    return state
end

function lineage.validate(state)
    local valid, valid_err = validate_state(state)
    if not valid then
        return nil, valid_err
    end
    if not valid_id(state.lineage_id) or not valid_id(state.session_id) then
        return nil, "invalid lineage identity"
    end
    if state.current_generation ~= #state.generations then
        return nil, "lineage generation count mismatch"
    end
    if state.pending_generation ~= nil and type(state.pending_generation) ~= "string" then
        return nil, "invalid pending generation transaction"
    end
    local packet_ids = {}
    local corpse_ids = {}
    for index, entry in ipairs(state.generations) do
        if entry.generation ~= index or not valid_id(entry.packet_id) then
            return nil, "invalid lineage generation entry"
        end
        if packet_ids[entry.packet_id] then
            return nil, "lineage Packet identity was reused"
        end
        packet_ids[entry.packet_id] = true
        if entry.corpse_id ~= nil then
            if corpse_ids[entry.corpse_id] then
                return nil, "lineage corpse identity was reused"
            end
            corpse_ids[entry.corpse_id] = true
        end
        if index > 1 and (not valid_id(entry.parent_packet_id)
            or not valid_id(entry.parent_corpse_id)
            or not valid_id(entry.ingress_carrier_id)) then
            return nil, "descendant generation ancestry is incomplete"
        end
    end
    local budget_snapshot, budget_err = lineage_budget.snapshot(state.budget)
    if not budget_snapshot then
        return nil, budget_err
    end
    return true
end

function lineage.snapshot(state)
    local valid, valid_err = lineage.validate(state)
    if not valid then
        return nil, valid_err
    end
    return copy_value(state)
end

return lineage
