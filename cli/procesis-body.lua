package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local json = require("core.json")
local fake = require("substrates.fake")
local deepseek = require("substrates.deepseek")
local fake_tool = require("tools.fake")
local encode = require("logic.encode")
local choose = require("logic.choose")
local cycle = require("logic.cycle")
local manifest = require("logic.manifest")
local repo_selection = require("logic.repo_selection")
local trace_store = require("runtime.trace_store")
local runtime_pressure = require("runtime.pressure_snapshot")
local operator_hints = require("runtime.operator_hints")
local system_prompt = require("runtime.system_prompt")
local repo_context = require("organs.repo_context")
local repo_listing = require("organs.repo_listing")

local function usage()
    io.stderr:write("usage: procesis-body run --task <text> (--fake | --deepseek) --jsonl [--mode chaos|table|crystall|manifest] [--work-mode plan|build] [--deepseek-model <name>] [--repo-list [prefix]] [--repo-context <paths>] [--hints|--no-hints] [--no-choose] [--no-logic] [--no-cycle] [--no-runtime-snapshot] [--trace-file <path>]\n")
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
    local parsed = {command = argv[1], choose = true, logic = true, cycle = true, runtime_snapshot = true}
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
        elseif arg == "--deepseek-model" then
            parsed.deepseek_model = argv[index + 1]
            index = index + 2
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
        elseif arg == "--runtime-snapshot" then
            parsed.runtime_snapshot = true
            index = index + 1
        elseif arg == "--no-runtime-snapshot" then
            parsed.runtime_snapshot = false
            index = index + 1
        elseif arg == "--hints" then
            parsed.hints = true
            parsed.hints_flag = parsed.hints_flag and "conflict" or "enabled"
            index = index + 1
        elseif arg == "--no-hints" then
            parsed.hints = false
            parsed.hints_flag = parsed.hints_flag and "conflict" or "disabled"
            index = index + 1
        elseif arg == "--choose" then
            parsed.choose = true
            index = index + 1
        elseif arg == "--no-choose" then
            parsed.choose = false
            index = index + 1
        elseif arg == "--logic" then
            parsed.logic = true
            index = index + 1
        elseif arg == "--no-logic" then
            parsed.logic = false
            index = index + 1
        elseif arg == "--cycle" then
            parsed.cycle = true
            index = index + 1
        elseif arg == "--no-cycle" then
            parsed.cycle = false
            index = index + 1
        elseif arg == "--mode" then
            parsed.mode = argv[index + 1]
            index = index + 2
        elseif arg == "--work-mode" then
            parsed.work_mode = argv[index + 1]
            parsed.work_mode_flag = parsed.work_mode_flag and "conflict" or "set"
            index = index + 2
        else
            parsed.unknown = arg
            index = index + 1
        end
    end
    return parsed
end

local function derive_work_mode(args)
    local work_mode = args.work_mode or "build"
    if work_mode ~= "plan" and work_mode ~= "build" then
        return nil, "invalid work mode: " .. tostring(work_mode)
    end
    if args.work_mode_flag == "conflict" then
        return nil, "choose only one work mode"
    end
    return work_mode
end

local function derive_hints(args, work_mode)
    if args.hints_flag == "enabled" then
        return true, "cli_override"
    end
    if args.hints_flag == "disabled" then
        return false, "cli_override"
    end
    if work_mode == "plan" then
        return false, "work_mode_plan"
    end
    return true, "work_mode_build"
end

local function build_encode_pressure(repo_listing_payload)
    local pressure = {
        operator_pressure = "cli_default_encode",
    }
    if repo_listing_payload then
        pressure.operator_pressure = "repo_listing_field"
        pressure.context_limit_pressure = "repo_listing_entries"
    else
        pressure.operator_pressure = "substrate_response_field"
    end
    return pressure
end

local function build_choice_input(encoded_payload, repo_listing_payload, response)
    local ranking_items = encode.response_line_items(response and response.text or "")
    local max_selected = 4
    if repo_listing_payload and #ranking_items > 0 then
        max_selected = math.min(max_selected, #ranking_items)
    end
    local field = encoded_payload and encoded_payload.field
    local field_shape = field and field.shape
    local field_intent = field and field.intent
    local collapse_level = "item"
    if field_shape == "repo_path_field" then
        collapse_level = "path"
    elseif field_shape == "structured_reflection_field" then
        collapse_level = field_intent == "preserve_reflection" and "child" or "section"
    elseif field_shape == "residue_field" then
        collapse_level = "residue"
    end

    return {
        field = field,
        limits = {
            max_selected = max_selected,
            max_killed_sample = 4,
        },
        pressure = {
            operator_pressure = repo_listing_payload and "repo_listing_focus" or "substrate_response_lines",
            context_limit_pressure = repo_listing_payload and "repo_listing_entries" or nil,
            encoded_field_kind = encoded_payload and encoded_payload.kind,
            field_shape = field_shape,
            field_intent = field_intent,
            collapse_level = collapse_level,
        },
        semantic_ranking = {
            truth_status = "semantic_proposal",
            items = ranking_items,
        },
    }
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
    if args.deepseek_model and not args.deepseek then
        io.stderr:write("--deepseek-model requires --deepseek\n")
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
    if args.hints_flag == "conflict" then
        io.stderr:write("choose only one hints mode\n")
        return 2
    end

    local mode = args.mode or "manifest"
    if not packet.validate_mode(mode) then
        io.stderr:write("invalid mode: " .. tostring(mode) .. "\n")
        return 2
    end

    local work_mode, work_mode_err = derive_work_mode(args)
    if not work_mode then
        io.stderr:write(work_mode_err .. "\n")
        return 2
    end
    local hints_enabled, hints_reason = derive_hints(args, work_mode)

    local p = packet.new(args.task, {mode = mode})
    local next_event = 1
    local source_events = {}
    next_event = emit_new_events(p, next_event)

    packet.enter_mode(p, mode, "cli", {work_mode = work_mode})
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

    local hints_payload = operator_hints.payload({enabled = hints_enabled})
    packet.append(p, {
        type = "hint_pressure",
        operator = "☴",
        truth_status = "runtime_confirmed",
        payload = operator_hints.trace_payload(hints_payload, hints_reason, work_mode),
        cost = {},
    })
    next_event = emit_new_events(p, next_event)

    local formatted_hints = operator_hints.format_for_substrate(hints_payload)
    if formatted_hints then
        prompt_parts[#prompt_parts + 1] = ""
        prompt_parts[#prompt_parts + 1] = formatted_hints
    end

    if #prompt_parts > 1 then
        prompt_payload = table.concat(prompt_parts, "\n")
    end
    local substrate_system_prompt = system_prompt.format({work_mode = work_mode})

    packet.append(p, {
        type = "substrate_call",
        operator = "☴",
        truth_status = "runtime_confirmed",
        payload = {
            mode = "mixed",
            operator = "☴",
            system_prompt = substrate_system_prompt,
            prompt_payload = prompt_payload,
            repo_listing = repo_listing_payload,
            repo_context = repo_context_payload,
            operator_hints = hints_payload,
            work_mode = work_mode,
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
            model = args.deepseek_model,
            system_prompt = substrate_system_prompt,
            prompt_payload = prompt_payload,
            repo_listing = repo_listing_payload,
            repo_context = repo_context_payload,
            operator_hints = hints_payload,
            work_mode = work_mode,
            expected_shape = "semantic_proposal",
        }, {
            model = args.deepseek_model,
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
    source_events.substrate_result_event = p.trace[#p.trace].id
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

    local choose_context
    if args.choose then
        packet.enter(p, "☵")
        next_event = emit_new_events(p, next_event)

        local encoded_payload, encoded_err = encode.encode({
            repo_listing = repo_listing_payload,
            repo_context = repo_context_payload,
            substrate_result = response,
            limits = {
                max_items = 128,
            },
            pressure = build_encode_pressure(repo_listing_payload),
        })
        if not encoded_payload then
            packet.append(p, {
                type = "observation",
                operator = "☵",
                truth_status = "rejected",
                payload = {
                    kind = "encoded_field",
                    error = encoded_err,
                },
                cost = {},
            })
            next_event = emit_new_events(p, next_event)
        else
            packet.append(p, {
                type = "observation",
                operator = "☵",
                truth_status = "runtime_confirmed",
                payload = {
                    kind = "encoded_field",
                    encoded_field = encoded_payload,
                },
                cost = {},
            })
            source_events.encoded_field_event = p.trace[#p.trace].id
            next_event = emit_new_events(p, next_event)
        end

        packet.enter(p, "☳")
        next_event = emit_new_events(p, next_event)

        local choose_payload, choose_err = choose.choose(build_choice_input(encoded_payload, repo_listing_payload, response))
        if not choose_payload then
            packet.append(p, {
                type = "choice",
                operator = "☳",
                truth_status = "rejected",
                payload = {
                    kind = "choose_collapse",
                    error = choose_err,
                },
                cost = {},
            })
            choose_context = {
                selected_count = 0,
                not_chosen_count = 0,
                loss_kind = "none",
                error = choose_err,
            }
        else
            packet.append(p, {
                type = "choice",
                operator = "☳",
                truth_status = "runtime_confirmed",
                payload = {
                    kind = "choose_collapse",
                    choose_collapse = choose_payload,
                },
                cost = {},
            })
            choose_context = {
                selected_count = #choose_payload.selected,
                not_chosen_count = choose_payload.not_chosen_count,
                loss_kind = choose_payload.loss and choose_payload.loss.kind,
                last_choice_event = nil,
            }
        end
        choose_context.last_choice_event = p.trace[#p.trace].id
        source_events.choice_event = p.trace[#p.trace].id
        next_event = emit_new_events(p, next_event)
    end

    local logic_context
    if args.logic then
        packet.enter(p, "☶")
        next_event = emit_new_events(p, next_event)

        if repo_listing_payload then
            local selection_payload, selection_err = repo_selection.validate({
                listing = repo_listing_payload,
                text = response.text or "",
                allow_directories = false,
                max_paths = 8,
            })
            if not selection_payload then
                packet.append(p, {
                    type = "validation",
                    operator = "☶",
                    truth_status = "rejected",
                    payload = {
                        kind = "repo_selection",
                        error = selection_err,
                    },
                    cost = {},
                })
                logic_context = {
                    accepted_count = 0,
                    rejected_count = 1,
                    rejection_reasons = {selection_err or "repo_selection_failed"},
                }
            else
                packet.append(p, {
                    type = "validation",
                    operator = "☶",
                    truth_status = "runtime_confirmed",
                    payload = {
                        kind = "repo_selection",
                        repo_selection = selection_payload,
                    },
                    cost = {},
                })
                logic_context = {
                    accepted_count = #selection_payload.accepted_paths,
                    rejected_count = #selection_payload.rejected_paths,
                    rejection_reasons = {},
                }
                for _, rejected in ipairs(selection_payload.rejected_paths) do
                    logic_context.rejection_reasons[#logic_context.rejection_reasons + 1] = rejected.reason
                end
            end
        else
            packet.append(p, {
                type = "validation",
                operator = "☶",
                truth_status = "runtime_confirmed",
                payload = {
                    kind = "substrate_result_boundary",
                    substrate_result_truth_status = "semantic_proposal",
                    substrate_text_present = type(response.text) == "string" and response.text ~= "",
                    rule = "substrate_result_remains_semantic_proposal",
                },
                cost = {},
            })
            logic_context = {
                accepted_count = 1,
                rejected_count = 0,
                rejection_reasons = {},
            }
        end
        logic_context.last_validation_event = p.trace[#p.trace].id
        source_events.validation_event = p.trace[#p.trace].id
        next_event = emit_new_events(p, next_event)
    end

    local cycle_context
    if args.cycle then
        if p.operator == "☳" then
            packet.enter(p, "☱")
            next_event = emit_new_events(p, next_event)
        end
        packet.enter(p, "☲")
        next_event = emit_new_events(p, next_event)

        local accepted_count = logic_context and logic_context.accepted_count or 1
        local rejected_count = logic_context and logic_context.rejected_count or 0
        local cycle_payload, cycle_err = cycle.decide({
            cycle_key = "cli_single_run",
            turn_count = 0,
            max_turns = 1,
            accepted_count = accepted_count > 0 and accepted_count or (rejected_count == 0 and 1 or 0),
            new_input_count = response and response.text and response.text ~= "" and 1 or 0,
            budget = p.budget,
            required_budget = {steps = 1},
            manifest_ready = false,
            unsafe = false,
            needs_user_input = false,
            previous_fingerprints = {},
            state_fingerprint = nil,
        })
        if not cycle_payload then
            packet.append(p, {
                type = "choice",
                operator = "☲",
                truth_status = "rejected",
                payload = {
                    kind = "cycle_decision",
                    error = cycle_err,
                },
                cost = {},
            })
            cycle_context = {
                last_cycle_decision = "cycle_error",
                last_cycle_reasons = {cycle_err or "cycle_failed"},
                repeated_fingerprint = false,
                turn_budget_pressure = "unknown",
            }
        else
            packet.append(p, {
                type = "choice",
                operator = "☲",
                truth_status = "runtime_confirmed",
                payload = {
                    kind = "cycle_decision",
                    cycle_decision = cycle_payload,
                },
                cost = {},
            })
            cycle_context = {
                last_cycle_decision = cycle_payload.decision,
                last_cycle_reasons = {cycle_payload.reason},
                repeated_fingerprint = cycle_payload.reason == "state_fingerprint",
                turn_budget_pressure = cycle_payload.decision == "stop_budget" and "cannot_pay" or "payable",
            }
        end
        source_events.cycle_event = p.trace[#p.trace].id
        next_event = emit_new_events(p, next_event)
    end

    if args.runtime_snapshot then
        if p.operator ~= "☱" then
            packet.enter(p, "☱")
            next_event = emit_new_events(p, next_event)
        end
        local snapshot_payload, snapshot_err = runtime_pressure.snapshot({
            packet = p,
            limits = {
                trace_tail_count = 6,
                include_residue = true,
                include_budget = true,
                include_pressure_sections = true,
            },
            logic_context = logic_context,
            cycle_context = cycle_context,
            manifest_context = {
                pending_output_shape = "manifest_payload",
                output_pressure = "ready",
            },
        })
        if not snapshot_payload then
            packet.append(p, {
                type = "observation",
                operator = "☱",
                truth_status = "rejected",
                payload = {
                    kind = "runtime_pressure_snapshot",
                    error = snapshot_err,
                },
                cost = {},
            })
        else
            packet.append(p, {
                type = "observation",
                operator = "☱",
                truth_status = "runtime_confirmed",
                payload = {
                    kind = "runtime_pressure_snapshot",
                    runtime_pressure_snapshot = snapshot_payload,
                },
                cost = {},
            })
            source_events.runtime_snapshot_event = p.trace[#p.trace].id
        end
        next_event = emit_new_events(p, next_event)
    end

    packet.enter(p, "△")
    local manifest_payload, manifest_err = manifest.assemble({
        work_mode = work_mode,
        substrate_result = response,
        sources = source_events,
        choose_context = choose_context,
        logic_context = logic_context,
        cycle_context = cycle_context,
    })
    if not manifest_payload then
        manifest_payload = {
            kind = "manifest_payload",
            truth_status = "runtime_confirmed",
            output = {
                type = "residue",
                text = "manifest assembly failed: " .. tostring(manifest_err),
            },
            sources = source_events,
            assembly = {
                rule = "deterministic_v0",
                work_mode = work_mode,
                error = manifest_err,
            },
            residue = {
                missing = {"manifest_payload"},
                unsupported = {},
                assumptions = {},
            },
            summary = {
                type = "residue",
                text_preview = "manifest assembly failed: " .. tostring(manifest_err),
                source_event = source_events.substrate_result_event,
            },
        }
    end
    packet.manifest(p, manifest_payload)
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
        manifest = manifest_payload.summary,
        residue = p.residue,
    })

    return 0
end

os.exit(run(arg))
