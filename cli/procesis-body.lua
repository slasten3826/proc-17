package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local json = require("core.json")
local fake = require("substrates.fake")
local deepseek = require("substrates.deepseek")
local fake_tool = require("tools.fake")
local trace_store = require("runtime.trace_store")
local repo_context = require("organs.repo_context")
local repo_listing = require("organs.repo_listing")

local function usage()
    io.stderr:write("usage: procesis-body run --task <text> (--fake | --deepseek) --jsonl [--mode chaos|table|crystall|manifest] [--repo-list [prefix]] [--repo-context <paths>] [--trace-file <path>]\n")
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
        elseif arg == "--repo-context" then
            parsed.repo_context = argv[index + 1]
            index = index + 2
        elseif arg == "--repo-list" then
            parsed.repo_list = true
            if argv[index + 1] and argv[index + 1]:sub(1, 2) ~= "--" then
                parsed.repo_list_prefix = argv[index + 1]
                index = index + 2
            else
                index = index + 1
            end
        elseif arg == "--mode" then
            parsed.mode = argv[index + 1]
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

    local mode = args.mode or "manifest"
    if not packet.validate_mode(mode) then
        io.stderr:write("invalid mode: " .. tostring(mode) .. "\n")
        return 2
    end

    local p = packet.new(args.task, {mode = mode})
    local next_event = 1
    next_event = emit_new_events(p, next_event)

    packet.enter_mode(p, mode, "cli")
    next_event = emit_new_events(p, next_event)

    packet.enter(p, "☰")
    next_event = emit_new_events(p, next_event)

    packet.enter(p, "☴")
    next_event = emit_new_events(p, next_event)

    local repo_listing_payload
    if args.repo_list then
        local listing_err
        repo_listing_payload, listing_err = repo_listing.attach(p, {
            prefix = args.repo_list_prefix or ".",
            mode = mode,
        })
        if not repo_listing_payload then
            packet.append(p, {
                type = "observation",
                operator = "☴",
                truth_status = "rejected",
                payload = {
                    kind = "repo_listing",
                    error = listing_err,
                },
                cost = {},
            })
            emit_new_events(p, next_event)
            packet.die(p, "unsafe_scope")
            emit(event_envelope(p, p.trace[#p.trace]))
            emit({
                packet_id = p.id,
                type = "final",
                status = p.status,
                residue = p.residue,
            })
            return 2
        end
        next_event = emit_new_events(p, next_event)
    end

    local repo_context_payload
    if args.repo_context then
        local context_err
        repo_context_payload, context_err = repo_context.attach(p, {
            files = args.repo_context,
            mode = mode,
        })
        if not repo_context_payload then
            packet.append(p, {
                type = "observation",
                operator = "☴",
                truth_status = "rejected",
                payload = {
                    kind = "repo_context",
                    error = context_err,
                },
                cost = {},
            })
            emit_new_events(p, next_event)
            packet.die(p, "unsafe_scope")
            emit(event_envelope(p, p.trace[#p.trace]))
            emit({
                packet_id = p.id,
                type = "final",
                status = p.status,
                residue = p.residue,
            })
            return 2
        end
        next_event = emit_new_events(p, next_event)
    end

    local prompt_payload = args.task
    local prompt_parts = {args.task}
    if repo_listing_payload then
        prompt_parts[#prompt_parts + 1] = ""
        prompt_parts[#prompt_parts + 1] = repo_listing.format_for_substrate(repo_listing_payload)
    end
    if repo_context_payload then
        prompt_parts[#prompt_parts + 1] = ""
        prompt_parts[#prompt_parts + 1] = repo_context.format_for_substrate(repo_context_payload)
    end
    if #prompt_parts > 1 then
        prompt_payload = table.concat(prompt_parts, "\n")
    end

    packet.append(p, {
        type = "substrate_call",
        operator = "☴",
        truth_status = "runtime_confirmed",
        payload = {
            mode = "mixed",
            operator = "☴",
            prompt_payload = prompt_payload,
            repo_listing = repo_listing_payload,
            repo_context = repo_context_payload,
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
            prompt_payload = prompt_payload,
            repo_listing = repo_listing_payload,
            repo_context = repo_context_payload,
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
