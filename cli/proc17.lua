local json = require("core.json")
local digest = require("core.digest")
local budget = require("runtime.budget")

local cli = {
    protocol_version = "proc17.cli.result.v0",
}

local VALUE_OPTIONS = {
    ["--session"] = "session_id",
    ["--label"] = "label",
    ["--model"] = "model",
    ["--max-steps"] = "max_steps",
    ["--max-calls"] = "max_calls",
    ["--max-tokens"] = "max_tokens",
    ["--max-loss"] = "max_loss",
    ["--project-base"] = "project_base",
    ["--repository"] = "repository_path",
    ["--task-file"] = "task_file",
}

local NUMBER_OPTIONS = {
    max_steps = "integer",
    max_calls = "integer",
    max_tokens = "integer",
    max_loss = "number",
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

local function finite_number(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function error_record(class, stage, message)
    return {
        class = class,
        stage = stage,
        message = tostring(message),
    }
end

local function result_error(config, class, stage, message)
    return {
        protocol_version = cli.protocol_version,
        ok = false,
        mode = config and config.mode or nil,
        session_id = config and config.session_id or nil,
        error = error_record(class, stage, message),
    }
end

local function parse_number(name, value, kind)
    local number = tonumber(value)
    if not finite_number(number) or number <= 0 then
        return nil, name .. " must be a positive number"
    end
    if kind == "integer" and number ~= math.floor(number) then
        return nil, name .. " must be a positive integer"
    end
    return number
end

local function validate_repository_path(path)
    if type(path) ~= "string" or path == "" or path:sub(1, 1) == "/"
        or path:find("%z") or path:find("//", 1, true) then
        return nil, "--repository must be a non-empty relative path"
    end
    for component in path:gmatch("[^/]+") do
        if component == "." or component == ".." then
            return nil, "--repository cannot contain dot components"
        end
    end
    return path
end

function cli.parse(argv)
    argv = argv or {}
    local mode = argv[1]
    if mode == "help" or mode == "--help" or mode == "-h" then
        if #argv ~= 1 then
            return nil, "help accepts no options"
        end
        return {help = true}
    end
    if mode ~= "plan" and mode ~= "build" then
        return nil, "first argument must be plan, build, or help"
    end

    local config = {
        mode = mode,
        model = os.getenv("DEEPSEEK_MODEL") or "deepseek-chat",
        max_steps = 64,
        max_calls = 4,
        max_tokens = 65536,
        max_loss = 10,
    }
    local seen = {}
    local index = 2
    while index <= #argv do
        local token = argv[index]
        local field = VALUE_OPTIONS[token]
        if field then
            if seen[field] then
                return nil, "duplicate option: " .. token
            end
            local value = argv[index + 1]
            if value == nil or value == "" or value:sub(1, 2) == "--" then
                return nil, "missing value for " .. token
            end
            seen[field] = true
            config[field] = value
            index = index + 2
        elseif type(token) == "string" and token:sub(1, 1) == "-" then
            return nil, "unknown option: " .. token
        else
            if config.task_argument ~= nil then
                return nil, "only one positional task argument is allowed"
            end
            config.task_argument = token
            index = index + 1
        end
    end

    if config.task_argument ~= nil and config.task_file ~= nil then
        return nil, "task argument and --task-file are mutually exclusive"
    end
    if type(config.model) ~= "string" or config.model == "" then
        return nil, "--model must be non-empty"
    end
    for field, kind in pairs(NUMBER_OPTIONS) do
        local normalized, normalize_err = parse_number("--" .. field:gsub("_", "-"), config[field], kind)
        if not normalized then
            return nil, normalize_err
        end
        config[field] = normalized
    end

    if mode == "plan" then
        if config.project_base ~= nil or config.repository_path ~= nil then
            return nil, "repository options are valid only in build mode"
        end
    else
        if type(config.project_base) ~= "string" or config.project_base:sub(1, 1) ~= "/" then
            return nil, "build requires absolute --project-base"
        end
        local repository_path, repository_err = validate_repository_path(config.repository_path)
        if not repository_path then
            return nil, repository_err
        end
        config.repository_path = repository_path
    end
    return config
end

local function default_io(io_context)
    io_context = io_context or {}
    return {
        read_stdin = io_context.read_stdin or function()
            return io.read("*a")
        end,
        read_file = io_context.read_file or function(path)
            local file, err = io.open(path, "rb")
            if not file then
                return nil, err
            end
            local content = file:read("*a")
            file:close()
            return content
        end,
        write_stdout = io_context.write_stdout or function(text)
            io.stdout:write(text)
        end,
        write_stderr = io_context.write_stderr or function(text)
            io.stderr:write(text)
        end,
    }
end

local function resolve_task(config, io_context)
    local task
    if config.task_argument ~= nil then
        task = config.task_argument
    elseif config.task_file ~= nil then
        local err
        task, err = io_context.read_file(config.task_file)
        if task == nil then
            return nil, "cannot read task file: " .. tostring(err)
        end
    else
        task = io_context.read_stdin()
    end
    if type(task) ~= "string" or task:match("^%s*$") then
        return nil, "task input must be non-empty"
    end
    if #task > 1048576 then
        return nil, "task input exceeds 1048576 bytes"
    end
    return task
end

local function prompt_contract(mode, task)
    local lines = {
        task,
        "",
        "Return exactly one JSON object and nothing else.",
        "Do not use Markdown or code fences.",
        "Use exactly these top-level keys: protocol_version, receiver_contract_id, shape, items, edges.",
        "Set protocol_version to packet.structure.proposal.v0.",
        "Set receiver_contract_id to calm.work_structure.v0.",
        "Set edges to an empty array.",
    }
    if mode == "plan" then
        lines[#lines + 1] = "Set shape to work_sequence."
        lines[#lines + 1] = "Every ordered item has exactly key, kind, value, source_keys."
        lines[#lines + 1] = "Use kind work_item, a precise step string as value, and an empty source_keys array."
    else
        lines[#lines + 1] = "Set shape to artifact_set."
        lines[#lines + 1] = "Set items to exactly one object with exactly key, kind, value, source_keys."
        lines[#lines + 1] = "Set kind to repository.create_text_file.v0 and source_keys to an empty array."
        lines[#lines + 1] = "Set value to an object with exactly path and content."
        lines[#lines + 1] = "Choose one new relative file path and provide its complete UTF-8 content."
    end
    return table.concat(lines, "\n")
end

local function task_source(task, hash)
    local source = {}
    local count = math.min(#task, 4096)
    for index = 1, count do
        source[#source + 1] = task:byte(index)
    end
    while #source < 3 do
        source[#source + 1] = (#source + 1) * 17
    end
    return source, "cli-task:" .. hash
end

local function fresh_lineage_id(session_id, task_hash, deps)
    local now = deps.now and deps.now() or os.time()
    local nonce = deps.random and deps.random() or math.random(0, 2147483647)
    local value = assert(digest.record({
        session_id = session_id,
        task_hash = task_hash,
        time = now,
        nonce = nonce,
    }))
    return "lineage-cli:" .. value:sub(1, 24)
end

local function load_dependencies(deps)
    deps = deps or {}
    return {
        substrate = deps.substrate or require("substrates.deepseek"),
        repository_provider = deps.repository_provider,
        capabilities = deps.capabilities or require("runtime.repository_capability"),
        tension_runner = deps.tension_runner or require("runtime.tension_runner"),
        session_memory = deps.session_memory or require("runtime.session_memory"),
        flow_domain = deps.flow_domain or require("runtime.flow_domain"),
        now = deps.now,
        random = deps.random,
        session_options = copy_value(deps.session_options or {}),
        production_substrate = deps.substrate == nil,
    }
end

local function prepare_session(config, dependencies)
    local session
    local err
    if config.session_id then
        session, err = dependencies.session_memory.load(
            config.session_id,
            dependencies.session_options
        )
    else
        session, err = dependencies.session_memory.create(nil, {label = config.label})
    end
    if not session then
        return nil, err
    end
    if config.label ~= nil then
        session.label = config.label
    end
    return session
end

local function repository_setup(config, session_id, lineage_id, dependencies)
    local provider = dependencies.repository_provider
        or require("runtime.repository_provider")
    local registry, registry_err = dependencies.capabilities.new({
        session_id = session_id,
        providers = {[provider.provider_id] = provider},
    })
    if not registry then
        return nil, nil, registry_err
    end
    local repository_hash, hash_err = digest.record({
        project_base = config.project_base,
        repository_path = config.repository_path,
    })
    if not repository_hash then
        return nil, nil, hash_err
    end
    local projection, mint_err = dependencies.capabilities.mint(registry, {
        lineage_id = lineage_id,
        repository_id = "cli-repository:" .. repository_hash:sub(1, 24),
        provider_id = "linux.openat2.renameat2.v0",
        project_base = config.project_base,
        repository_path = config.repository_path,
        operations = {create_text_file = true},
        bounds = {
            max_relative_path_bytes = 1024,
            max_content_bytes = 1048576,
            max_effects_per_generation = 1,
        },
        policy = {file_mode = 384},
    })
    if not projection then
        return nil, nil, mint_err
    end
    return registry, projection
end

local function public_result(config, session, lineage_id, instance, run_result, session_path)
    local complete = instance and instance.death and instance.death.cause == "complete"
    local public_trace = {}
    for _, event in ipairs(instance and instance.trace or {}) do
        public_trace[#public_trace + 1] = {
            id = event.id,
            type = event.type,
            operator = event.operator,
            truth_status = event.truth_status,
            time = event.time,
            cost = copy_value(event.cost or {}),
        }
    end
    local result = {
        protocol_version = cli.protocol_version,
        ok = complete == true,
        mode = config.mode,
        session_id = session and session.session_id,
        lineage_id = lineage_id,
        packet_id = instance and instance.id,
        final_status = instance and instance.status,
        stop_reason = run_result and run_result.stop_reason,
        death = copy_value(instance and instance.death),
        manifest = copy_value(instance and instance.manifest),
        budget = instance and budget.snapshot(instance) or nil,
        trace = public_trace,
        session_path = session_path,
    }
    if not complete then
        result.error = error_record(
            "packet_terminal",
            "packet",
            instance and instance.death and instance.death.cause or "non-complete Packet"
        )
    end
    return result
end

function cli.execute(config, io_context, deps)
    io_context = default_io(io_context)
    local dependencies = load_dependencies(deps)
    local task, task_err = resolve_task(config, io_context)
    if not task then
        return result_error(config, "input", "task", task_err), 2
    end
    if dependencies.production_substrate
        and (not os.getenv("DEEPSEEK_API_KEY") or os.getenv("DEEPSEEK_API_KEY") == "") then
        return result_error(config, "config", "substrate", "DEEPSEEK_API_KEY is required"), 2
    end

    local session, session_err = prepare_session(config, dependencies)
    if not session then
        return result_error(config, "config", "session", session_err), 2
    end

    local task_hash, task_hash_err = digest.sha256(task)
    if not task_hash then
        return result_error(config, "runtime", "task_digest", task_hash_err), 4
    end
    local lineage_id = fresh_lineage_id(session.session_id, task_hash, dependencies)
    local source, source_ref = task_source(task, task_hash)
    local domain, domain_err = dependencies.flow_domain.new(source, {
        stream_id = "cli-flow:" .. lineage_id,
        source_ref = source_ref,
        adapter_id = "cli.task_bytes.v0",
        max_source_units = 4096,
    })
    if not domain then
        return result_error(config, "runtime", "flow_domain", domain_err), 4
    end

    local inherited, inherited_err = dependencies.session_memory.inherit_graves(
        session,
        {enabled = true}
    )
    if not inherited then
        return result_error(config, "runtime", "grave_inheritance", inherited_err), 4
    end

    local registry
    local grant
    if config.mode == "build" then
        local setup_err
        registry, grant, setup_err = repository_setup(
            config,
            session.session_id,
            lineage_id,
            dependencies
        )
        if not registry then
            return result_error(config, "runtime", "repository_setup", setup_err), 4
        end
    end

    local runner_options = {
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        ablate_relation_consumer = true,
        work_mode = config.mode,
        legacy_shadow = false,
        packet_options = {
            session_id = session.session_id,
            lineage_id = lineage_id,
            generation = 1,
            work_mode = config.mode,
            budget = {
                steps = config.max_steps,
                substrate_calls = config.max_calls,
                total_tokens = config.max_tokens,
                loss = config.max_loss,
            },
        },
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = domain,
            projection_adapter = "vertical_single.v0",
        },
        inherited_graves = inherited,
        substrate_options = {
            model = config.model,
            temperature = 0,
        },
    }
    if registry then
        local repository_hash = assert(digest.record({
            project_base = config.project_base,
            repository_path = config.repository_path,
        }))
        runner_options.repository_hands = {
            protocol_version = "repository.hands.config.v0",
            enabled = true,
            repository_id = "cli-repository:" .. repository_hash:sub(1, 24),
        }
        runner_options.host_services = {repository_capabilities = registry}
    end

    local called, instance, run_result = pcall(
        dependencies.tension_runner.run,
        prompt_contract(config.mode, task),
        dependencies.substrate,
        runner_options
    )

    local revoke_err
    if registry and grant then
        local revoked
        revoked, revoke_err = dependencies.capabilities.revoke(registry, grant.grant_id)
        if not revoked and revoke_err == nil then
            revoke_err = "repository grant revoke failed"
        end
    end
    if not called or not instance or revoke_err then
        local message = not called and instance
            or not instance and run_result
            or revoke_err
        return result_error(config, "runtime", revoke_err and "repository_cleanup" or "runner", message), 4
    end
    if type(instance) ~= "table" or instance.status ~= "dead" then
        return result_error(config, "runtime", "runner", "runner returned non-terminal Packet"), 4
    end

    local indexed, index_err = dependencies.session_memory.append_lineage(session, lineage_id)
    if not indexed then
        return result_error(config, "runtime", "session_lineage", index_err), 4
    end
    local packet_indexed, packet_index_err = dependencies.session_memory.append_packet(session, instance.id)
    if not packet_indexed then
        return result_error(config, "runtime", "session_packet", packet_index_err), 4
    end
    local grave_record, grave_err = dependencies.session_memory.add_grave(session, instance)
    if not grave_record then
        return result_error(config, "runtime", "session_grave", grave_err), 4
    end
    local saved, session_path = dependencies.session_memory.save(
        session,
        dependencies.session_options
    )
    if not saved then
        return result_error(config, "runtime", "session_save", session_path), 4
    end

    local result = public_result(config, session, lineage_id, instance, run_result, session_path)
    return result, result.ok and 0 or 3
end

local function help_result()
    return {
        protocol_version = "proc17.cli.help.v0",
        ok = true,
        usage = {
            "lua proc17.lua plan [TASK | --task-file FILE] [options]",
            "lua proc17.lua build [TASK | --task-file FILE] --project-base ABS --repository REL [options]",
            "lua proc17.lua help",
        },
    }
end

local function emit(io_context, value)
    local encoded, encode_err
    local ok, produced = pcall(json.encode, value)
    if ok then
        encoded = produced
    else
        encode_err = produced
        encoded = '{"error":{"class":"runtime","message":"JSON encoding failed","stage":"render"},"ok":false,"protocol_version":"proc17.cli.result.v0"}'
    end
    io_context.write_stdout(encoded .. "\n")
    if encode_err then
        io_context.write_stderr(tostring(encode_err) .. "\n")
        return 4
    end
end

function cli.main(argv, io_context, deps)
    io_context = default_io(io_context)
    local config, parse_err = cli.parse(argv)
    if not config then
        local value = result_error(nil, "input", "arguments", parse_err)
        return emit(io_context, value) or 2
    end
    if config.help then
        return emit(io_context, help_result()) or 0
    end
    local value, code = cli.execute(config, io_context, deps)
    local render_code = emit(io_context, value)
    return render_code or code
end

return cli
