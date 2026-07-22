local json = require("core.json")
local flow_domain = require("runtime.flow_domain")
local tension_runner = require("runtime.tension_runner")
local packet_core = require("core.packet")
local topology = require("core.topology")

local fixture = {}
local counter = 0

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

function fixture.proposal(items, shape)
    shape = shape or "artifact_set"
    local normalized = {}
    for index, item in ipairs(items or {}) do
        normalized[index] = {
            key = item.key or ("artifact-" .. tostring(index)),
            kind = item.kind or "repository.create_text_file.v0",
            value = copy_value(item.value or {
                path = item.path,
                content = item.content,
            }),
            source_keys = copy_value(item.source_keys or {}),
        }
    end
    local proposal = {
        protocol_version = "packet.structure.proposal.v0",
        receiver_contract_id = "calm.work_structure.v0",
        shape = shape,
        items = normalized,
        edges = {},
    }
    if shape == "alternative_set" then
        proposal.choice = {kind = "mutually_exclusive"}
    end
    return proposal
end

function fixture.substrate(proposal)
    local encoded = type(proposal) == "string" and proposal or json.encode(proposal)
    return {
        ask = function()
            return {
                text = encoded,
                usage = {prompt_tokens = 1, completion_tokens = 1, total_tokens = 2},
            }
        end,
    }
end

function fixture.packet(items, options)
    options = options or {}
    counter = counter + 1
    local id = options.label or ("repository-hands-" .. tostring(counter))
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = id,
        source_ref = "fixture:" .. id,
    }))
    local packet_options = copy_value(options.packet_options or {})
    packet_options.session_id = options.session_id or "session-repository-hands"
    packet_options.lineage_id = options.lineage_id or "lineage-repository-hands"
    packet_options.work_mode = options.work_mode or "build"
    packet_options.repository_id = options.repository_id or "repo-a"
    local run_options = {
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        ablate_relation_consumer = true,
        work_mode = options.work_mode or "build",
        max_ticks = options.max_ticks or 2,
        legacy_shadow = false,
        packet_options = packet_options,
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = domain,
            projection_adapter = "vertical_single.v0",
        },
    }
    for key, value in pairs(options.runner_options or {}) do
        run_options[key] = value
    end
    local instance, result = assert(tension_runner.run(
        options.prompt or "create one exact repository file",
        fixture.substrate(fixture.proposal(items, options.shape)),
        run_options
    ))
    return instance, result
end

function fixture.repository_units(instance)
    local result = {}
    for _, id in ipairs(instance.field and instance.field.unit_order or {}) do
        local unit = instance.field.units[id]
        if unit and unit.kind == "structured_item"
            and unit.carrier
            and unit.carrier.kind == "repository.create_text_file.v0" then
            result[#result + 1] = copy_value(unit)
        end
    end
    return result
end

local function provider_error(code, stage, cost, class)
    return {
        protocol_version = "repository.provider_error.v0",
        class = class or "world",
        code = code,
        stage = stage,
        errno = nil,
        mutation_primitive_entered = (cost and cost.file_writes or 0) > 0,
        published = false,
        cost = copy_value(cost or {tool_calls = 1, file_writes = 0, time_ms = 0}),
    }
end

function fixture.fake_provider(options)
    options = options or {}
    local state = {
        files = copy_value(options.files or {}),
        calls = {
            open_repository = 0,
            revalidate = 0,
            create = 0,
            read = 0,
            inventory = 0,
        },
        root_identity = copy_value(options.root_identity or {
            device = 17,
            inode = 1701,
        }),
        create_override = options.create_override,
        read_override = options.read_override,
        revalidate_override = options.revalidate_override,
        inventory_override = options.inventory_override,
    }
    local provider = {
        provider_id = "linux.openat2.renameat2.v0",
        contract_id = "repository.provider.create_readback.v0",
        limits = {
            max_relative_path_bytes = 1024,
            max_component_bytes = 255,
            max_components = 64,
            max_content_bytes = 1048576,
            file_mode = 384,
        },
    }

    function provider.available()
        return true, {
            provider_id = provider.provider_id,
            contract_id = provider.contract_id,
        }
    end

    function provider.open_repository(input)
        state.calls.open_repository = state.calls.open_repository + 1
        local handle = {kind = "fake_repository_handle", token = {}}
        local identity = {
            project_base = {device = 17, inode = 1700},
            root = copy_value(state.root_identity),
            repository_path = input.repository_path,
            host_path = input.project_base .. "/" .. input.repository_path,
        }
        return handle, identity
    end

    function provider.revalidate(handle)
        state.calls.revalidate = state.calls.revalidate + 1
        if state.revalidate_override then
            return state.revalidate_override(handle, state)
        end
        return {
            protocol_version = "repository.provider_result.v0",
            operation = "revalidate",
            outcome = "valid",
            root = copy_value(state.root_identity),
            mutation_primitive_entered = false,
            published = false,
            cost = {tool_calls = 0, file_writes = 0, time_ms = 0},
        }
    end

    function provider.create_text_file(handle, request)
        state.calls.create = state.calls.create + 1
        if state.create_override then
            return state.create_override(handle, request, state)
        end
        if state.files[request.relative_path] ~= nil then
            return nil, provider_error("target_exists", "rename_noreplace", {
                tool_calls = 1,
                file_writes = 1,
                time_ms = 0,
            })
        end
        state.files[request.relative_path] = request.content
        return {
            protocol_version = "repository.provider_result.v0",
            operation = "create_text_file",
            outcome = "created",
            bytes = #request.content,
            root = copy_value(state.root_identity),
            mutation_primitive_entered = true,
            published = true,
            cost = {tool_calls = 1, file_writes = 1, time_ms = 0},
        }
    end

    function provider.read_text_file(handle, request)
        state.calls.read = state.calls.read + 1
        if state.read_override then
            return state.read_override(handle, request, state)
        end
        local content = state.files[request.relative_path]
        if content == nil then
            return {
                protocol_version = "repository.provider_result.v0",
                operation = "read_text_file",
                outcome = "observed",
                target_kind = "missing",
                bytes = nil,
                content = nil,
                root = copy_value(state.root_identity),
                mutation_primitive_entered = false,
                published = false,
                cost = {tool_calls = 1, file_writes = 0, time_ms = 0},
            }
        end
        return {
            protocol_version = "repository.provider_result.v0",
            operation = "read_text_file",
            outcome = "observed",
            target_kind = "regular_file",
            bytes = #content,
            content = content,
            root = copy_value(state.root_identity),
            mutation_primitive_entered = false,
            published = false,
            cost = {tool_calls = 1, file_writes = 0, time_ms = 0},
        }
    end

    function provider.inventory_tree(handle, bounds)
        state.calls.inventory = state.calls.inventory + 1
        if state.inventory_override then
            return state.inventory_override(handle, bounds, state)
        end

        local paths = {}
        local kinds = {}
        for path in pairs(state.files) do
            kinds[path] = "regular_file"
            paths[#paths + 1] = path
            local prefix = ""
            local components = {}
            for component in path:gmatch("[^/]+") do
                components[#components + 1] = component
            end
            for index = 1, #components - 1 do
                prefix = prefix == "" and components[index]
                    or (prefix .. "/" .. components[index])
                if not kinds[prefix] then
                    kinds[prefix] = "directory"
                    paths[#paths + 1] = prefix
                end
            end
        end
        table.sort(paths)

        local entries = {}
        local total_bytes = 0
        local outcome = "observed"
        for index, path in ipairs(paths) do
            local kind = kinds[path]
            local content = kind == "regular_file" and state.files[path] or nil
            local bytes = content and #content or nil
            local depth = 0
            local max_component = 0
            for component in path:gmatch("[^/]+") do
                depth = depth + 1
                max_component = math.max(max_component, #component)
            end
            local next_total = total_bytes + (bytes or 0)
            if index > bounds.max_entries or depth > bounds.max_depth
                or #path > bounds.max_path_bytes
                or max_component > bounds.max_component_bytes
                or (bytes and bytes > bounds.max_file_bytes)
                or next_total > bounds.max_total_bytes then
                outcome = "bound_exceeded"
                break
            end
            total_bytes = next_total
            local identity = {device = 17, inode = 2000 + index}
            entries[#entries + 1] = {
                relative_path = path,
                kind = kind,
                identity_before = copy_value(identity),
                identity_after = copy_value(identity),
                bytes = bytes,
                content = content,
            }
        end
        return {
            protocol_version = "repository.provider_inventory_result.v0",
            operation = "inventory_tree",
            outcome = outcome,
            root_before = copy_value(state.root_identity),
            root_after = copy_value(state.root_identity),
            stable = true,
            entries = entries,
            bounds_observed = {
                max_entries = bounds.max_entries,
                max_depth = bounds.max_depth,
                max_path_bytes = bounds.max_path_bytes,
                max_component_bytes = bounds.max_component_bytes,
                max_file_bytes = bounds.max_file_bytes,
                max_total_bytes = bounds.max_total_bytes,
                observed_entries = #entries,
                observed_total_bytes = total_bytes,
            },
            mutation_primitive_entered = false,
            published = false,
            cost = {tool_calls = 1, file_writes = 0, time_ms = 0},
        }
    end

    function provider.close()
        return true
    end

    return provider, state
end

local function last_trace_type(instance)
    local event = instance.trace and instance.trace[#instance.trace]
    return event and event.type
end

function fixture.ensure_tick(instance)
    if last_trace_type(instance) == "route" or last_trace_type(instance) == "birth" then
        return assert(packet_core.begin_tick(instance, instance.operator, {}))
    end
    return true
end

local function path_between(from, target)
    local queue = {{from}}
    local seen = {[from] = true}
    while #queue > 0 do
        local path = table.remove(queue, 1)
        local current = path[#path]
        if current == target then
            return path
        end
        for _, next_glyph in ipairs(topology.operators[current].adjacent or {}) do
            if next_glyph ~= "▽" and next_glyph ~= "△" and not seen[next_glyph] then
                seen[next_glyph] = true
                local next_path = copy_value(path)
                next_path[#next_path + 1] = next_glyph
                queue[#queue + 1] = next_path
            end
        end
    end
    return nil
end

function fixture.move_to(instance, target)
    fixture.ensure_tick(instance)
    if instance.operator == target then
        return instance
    end
    local path = assert(path_between(instance.operator, target), "no fixture route")
    for index = 2, #path do
        assert(packet_core.commit_transition(instance, {
            from = instance.operator,
            to = path[index],
            reason = "repository_hands_fixture_spacing",
            authority = "harness_override",
        }))
        assert(packet_core.begin_tick(instance, path[index], {}))
    end
    return instance
end

function fixture.grant_input(overrides)
    local value = {
        lineage_id = "lineage-repository-hands",
        repository_id = "repo-a",
        provider_id = "linux.openat2.renameat2.v0",
        project_base = "/trusted/proc17-test-projects",
        repository_path = "repo-a",
        operations = {create_text_file = true},
        bounds = {
            max_relative_path_bytes = 128,
            max_content_bytes = 4096,
            max_effects_per_generation = 4,
        },
        policy = {file_mode = 384},
    }
    for key, child in pairs(overrides or {}) do
        value[key] = copy_value(child)
    end
    return value
end

function fixture.new_registry(capabilities, options)
    options = options or {}
    local provider, state = fixture.fake_provider(options.provider_options)
    local registry = assert(capabilities.new({
        session_id = options.session_id or "session-repository-hands",
        providers = {[provider.provider_id] = provider},
        id_source = options.id_source,
    }))
    local projection = assert(capabilities.mint(
        registry,
        fixture.grant_input(options.grant)
    ))
    return registry, projection, provider, state
end

function fixture.route_pairs(instance)
    local result = {}
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "route" and type(event.payload) == "table" then
            result[#result + 1] = tostring(event.payload.from) .. "->"
                .. tostring(event.payload.to)
        end
    end
    return result
end

function fixture.contains_subsequence(values, wanted)
    local cursor = 1
    for _, value in ipairs(values or {}) do
        if value == wanted[cursor] then
            cursor = cursor + 1
            if cursor > #wanted then
                return true
            end
        end
    end
    return false
end

fixture.copy = copy_value
fixture.provider_error = provider_error

return fixture
