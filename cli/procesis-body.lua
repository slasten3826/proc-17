package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local json = require("core.json")
local fake = require("substrates.fake")
local deepseek = require("substrates.deepseek")
local fake_tool = require("tools.fake")
local trace_store = require("runtime.trace_store")

local function usage()
    io.stderr:write("usage: procesis-body run --task <text> (--fake | --deepseek) --jsonl [--trace-file <path>]\n")
end

local function emit(event)
    print(json.encode(event))
end

local function event_envelope(instance, event)
    return {
        packet_id = instance.id,
        event_id = event.id,
        type = event.type,
        operator = event.operator,
        truth_status = event.truth_status,
        payload = event.payload,
    }
end

local function emit_new_events(instance, from_index)
    for index = from_index, #instance.trace do
        emit(event_envelope(instance, instance.trace[index]))
    end
    return #instance.trace + 1
end

local function parse_args(argv)
    local parsed = {command = argv[1]}
    local index = 2
    while index <= #argv do
        local arg = argv[index]
        if arg == "--task" then
            parsed.task = argv[index + 1]
            index = index + 2
        elseif arg == "--fake" then
            parsed.fake = true
            index = index + 1
        elseif arg == "--deepseek" then
            parsed.deepseek = true
            index = index + 1
        elseif arg == "--jsonl" then
            parsed.jsonl = true
            index = index + 1
        elseif arg == "--trace-file" then
            parsed.trace_file = argv[index + 1]
            index = index + 2
        else
            parsed.unknown = arg
            index = index + 1
        end
    end
    return parsed
end

local function run(argv)
    local args = parse_args(argv)
    if args.command ~= "run" then
        usage()
        return 5
    end
    if args.unknown then
        io.stderr:write("unsupported argument: " .. args.unknown .. "\n")
        return 5
    end
    if not args.task or args.task == "" then
        io.stderr:write("--task is required\n")
        return 2
    end
    if args.fake and args.deepseek then
        io.stderr:write("choose only one substrate\n")
        return 2
    end
    if not args.fake and not args.deepseek then
        io.stderr:write("substrate is required: --fake or --deepseek\n")
        return 5
    end
    if not args.jsonl then
        io.stderr:write("first CLI requires --jsonl\n")
        return 5
    end

    local p = packet.new(args.task)
    local next_event = 1
    next_event = emit_new_events(p, next_event)

    packet.enter(p, "☰")
    next_event = emit_new_events(p, next_event)

    packet.enter(p, "☴")
    next_event = emit_new_events(p, next_event)

    packet.append(p, {
        type = "substrate_call",
        operator = "☴",
        truth_status = "runtime_confirmed",
        payload = {
            mode = "mixed",
            operator = "☴",
            prompt_payload = args.task,
            expected_shape = "semantic_proposal",
        },
        cost = {substrate_calls = 1},
    })
    next_event = emit_new_events(p, next_event)

    local response, substrate_err
    if args.deepseek then
        response, substrate_err = deepseek.ask({
            mode = "mixed",
            operator = "☴",
            prompt_payload = args.task,
            expected_shape = "semantic_proposal",
        })
    else
        response = fake.ask({mode = "mixed", operator = "☴", task = args.task})
    end

    if not response then
        packet.append(p, {
            type = "substrate_result",
            operator = "☴",
            truth_status = "unknown",
            payload = {error = substrate_err or "substrate failed"},
            cost = {},
        })
        emit_new_events(p, next_event)
        packet.die(p, "blocked_by_runtime_truth")
        emit(event_envelope(p, p.trace[#p.trace]))
        if args.trace_file then
            trace_store.write_jsonl(args.trace_file, p)
        end
        emit({
            packet_id = p.id,
            type = "final",
            status = p.status,
            residue = p.residue,
        })
        return 3
    end

    packet.append(p, {
        type = "substrate_result",
        operator = "☴",
        truth_status = "semantic_proposal",
        payload = response,
        cost = {},
    })
    next_event = emit_new_events(p, next_event)

    packet.enter(p, "☱")
    packet.spend(p, {steps = 1, substrate_calls = 1})
    next_event = emit_new_events(p, next_event)

    packet.append(p, {
        type = "tool_call",
        operator = "☱",
        truth_status = "runtime_confirmed",
        payload = {
            tool = "fake",
            action = "inspect_task",
            input = {task = args.task},
        },
        cost = {tool_calls = 1},
    })
    next_event = emit_new_events(p, next_event)

    local tool_result = fake_tool.run({
        action = "inspect_task",
        input = {task = args.task},
    })
    packet.append(p, {
        type = "tool_result",
        operator = "☱",
        truth_status = tool_result.ok and "runtime_confirmed" or "rejected",
        payload = tool_result,
        cost = {},
    })
    packet.spend(p, {tool_calls = 1})
    next_event = emit_new_events(p, next_event)

    packet.enter(p, "△")
    packet.manifest(p, {truth_status = "runtime_confirmed", result = "substrate loop complete"})
    packet.die(p, "complete")
    next_event = emit_new_events(p, next_event)

    if args.trace_file then
        local ok_write, write_err = trace_store.write_jsonl(args.trace_file, p)
        if not ok_write then
            io.stderr:write("failed to write trace: " .. tostring(write_err) .. "\n")
            return 1
        end
    end

    emit({
        packet_id = p.id,
        type = "final",
        status = p.status,
        residue = p.residue,
    })

    return 0
end

os.exit(run(arg))
