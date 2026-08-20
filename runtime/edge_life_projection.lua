local corpse_module = require("runtime.corpse")
local digest = require("core.digest")
local json = require("core.json")

local projection = {
    protocol_version = "edge-life-projection.v0",
}

local default_max_projection_bytes = 16 * 1024 * 1024
local excluded_host_time = "host_wall_time_excluded.v0"

local component_names = {
    "identity_and_work_contract",
    "operator_status_and_walk",
    "committed_routes",
    "budget_and_loss",
    "substrate_and_tool_calls",
    "chaos_calm_field_revisions_effects",
    "repository_results",
    "qa_results",
    "manifest_death_residue_terminal",
    "packet_trace",
    "corpse",
}

local required_component_names = {}
for _, name in ipairs(component_names) do
    if name ~= "corpse" then
        required_component_names[name] = true
    end
end

local packet_keys = {
    protocol_version = true,
    id = true,
    session_id = true,
    lineage_id = true,
    generation = true,
    parent_id = true,
    parent_corpse_id = true,
    birth_kind = true,
    carrier_id = true,
    substrate_session_id = true,
    status = true,
    operator = true,
    topology = true,
    revisions = true,
    physis = true,
    substrate = true,
    chaos = true,
    field = true,
    boundary = true,
    calm = true,
    regime = true,
    process_contract_id = true,
    work_context = true,
    stage_id = true,
    repository_id = true,
    qa_contract_id = true,
    qa_contract = true,
    tension = true,
    runtime = true,
    trace = true,
    residue = true,
    death = true,
    manifest = true,
    terminal = true,
    metadata = true,
    ingress = true,
}

local runner_physical_keys = {
    kind = true,
    packet_id = true,
    router_mode = true,
    birth = true,
    ticks = true,
    routes = true,
    entry_route = true,
    stop_reason = true,
    final_status = true,
    flow = true,
    flow_readiness = true,
    grave = true,
    entry_derivation = true,
    no_viable_edge = true,
    effect_failure = true,
    runtime_frame_ref = true,
    failure = true,
    payload = true,
    readiness = true,
    status = true,
}

local runner_instrumentation_keys = {
    shadow_routes = true,
    legacy_shadow = true,
    edge_stats = true,
    edge_evidence = true,
    edge_stats_errors = true,
    edge_stats_v3 = true,
    edge_evidence_v3 = true,
    edge_credit = true,
    authority_epoch = true,
    authority_epoch_diagnostics = true,
    authority_epoch_error = true,
    authority_instrument = true,
    authority_instrument_errors = true,
    work_layer_observer = true,
    work_layer_observations = true,
    work_layer_observer_errors = true,
    dissolve_pressure_relief_reader = true,
    dissolve_pressure_relief_measurements = true,
}

local function instrument_error(code, extra)
    local value = {
        class = "instrument_contract",
        code = code,
        stage = "edge_life_projection",
    }
    for key, child in pairs(extra or {}) do
        value[key] = child
    end
    return value
end

local function non_empty(value)
    return type(value) == "string" and value ~= ""
end

local function non_negative_integer(value)
    return type(value) == "number"
        and value >= 0
        and value % 1 == 0
        and value < math.huge
end

local function positive_integer(value)
    return non_negative_integer(value) and value > 0
end

local function tagged_hash(value)
    return type(value) == "string"
        and #value == 71
        and value:sub(1, 7) == "sha256:"
        and value:sub(8):match("^[0-9a-f]+$") ~= nil
end

local function tagged_digest(value)
    local value_digest, value_err = digest.record(value)
    if not value_digest then
        return nil, instrument_error("projection_digest_failed", {
            detail = tostring(value_err),
        })
    end
    return "sha256:" .. value_digest
end

local function same_value(left, right)
    local left_ok, left_encoded = pcall(json.encode, left)
    local right_ok, right_encoded = pcall(json.encode, right)
    return left_ok and right_ok and left_encoded == right_encoded
end

local function copy_plain(value, path, state)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "string" then
        return value
    end
    if kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return nil, instrument_error("projection_non_plain_value", {path = path})
        end
        return value
    end
    if kind ~= "table" then
        return nil, instrument_error("projection_non_plain_value", {
            path = path,
            value_type = kind,
        })
    end
    if getmetatable(value) ~= nil then
        return nil, instrument_error("projection_metatable_rejected", {path = path})
    end
    if value.protocol_version == "packet.next.v1"
        and type(value.trace) == "table"
        and type(value.physis) == "table" then
        return nil, instrument_error("projection_live_packet_rejected", {path = path})
    end

    state = state or {active = {}, copies = {}}
    if state.active[value] then
        return nil, instrument_error("projection_cycle_rejected", {path = path})
    end
    if state.copies[value] then
        return state.copies[value]
    end
    local result = {}
    state.active[value] = true
    state.copies[value] = result
    for key, child in pairs(value) do
        local key_kind = type(key)
        if key_kind ~= "string"
            and not (key_kind == "number" and positive_integer(key)) then
            state.active[value] = nil
            return nil, instrument_error("projection_non_plain_key", {
                path = path,
                key_type = key_kind,
            })
        end
        local copied, copied_err = copy_plain(
            child,
            path .. "." .. tostring(key),
            state
        )
        if copied_err then
            state.active[value] = nil
            return nil, copied_err
        end
        result[key] = copied
    end
    state.active[value] = nil
    return result
end

local function sorted_unique(values)
    local result = {}
    local seen = {}
    for _, value in ipairs(values or {}) do
        if not non_empty(value) then
            return nil, instrument_error("observer_ref_invalid")
        end
        if not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function exact_keys(value, required, optional)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return false
    end
    optional = optional or {}
    for key in pairs(value) do
        if not required[key] and not optional[key] then
            return false
        end
    end
    for key in pairs(required) do
        if value[key] == nil then
            return false
        end
    end
    return true
end

local function validate_inputs(instance, runner_result)
    if type(instance) ~= "table"
        or instance.protocol_version ~= "packet.next.v1"
        or not non_empty(instance.id)
        or type(instance.trace) ~= "table" then
        return nil, instrument_error("projection_packet_required")
    end
    for key in pairs(instance) do
        if not packet_keys[key] then
            return nil, instrument_error("projection_packet_surface_unknown", {
                path = "packet." .. tostring(key),
            })
        end
    end
    if instance.substrate ~= instance.physis then
        return nil, instrument_error("projection_physis_alias_diverged")
    end
    if type(runner_result) ~= "table"
        or runner_result.kind ~= "tension_runner_result"
        or runner_result.packet_id ~= instance.id then
        return nil, instrument_error("projection_runner_result_required")
    end
    for key in pairs(runner_result) do
        if not runner_physical_keys[key] and not runner_instrumentation_keys[key] then
            return nil, instrument_error("projection_runner_surface_unknown", {
                path = "runner_result." .. tostring(key),
            })
        end
    end
    return true
end

local function trace_index(instance)
    local by_id = {}
    for index, event in ipairs(instance.trace or {}) do
        if type(event) ~= "table" or not non_empty(event.id) then
            return nil, instrument_error("packet_trace_event_invalid", {index = index})
        end
        if by_id[event.id] then
            return nil, instrument_error("packet_trace_ref_ambiguous", {ref = event.id})
        end
        by_id[event.id] = event
    end
    return by_id
end

local observer_pairs = {
    legacy = "tree",
    tree = "legacy_control",
}

local pressure_kinds = {
    edge_pressure_snapshot = true,
    qualified_pressure_snapshot = true,
}

local function observer_refs(instance, runner_result)
    local by_id, index_err = trace_index(instance)
    if not by_id then
        return nil, index_err
    end
    local refs = {}
    for index, decision in ipairs(runner_result.shadow_routes or {}) do
        if type(decision) ~= "table"
            or decision.kind ~= "shadow_route_decision"
            or not observer_pairs[decision.observer]
            or decision.live_authority ~= observer_pairs[decision.observer]
            or not non_empty(decision.trace_event_id)
            or decision.trace_event_id:match("^observer%-event%-%d+$") == nil then
            return nil, instrument_error("observer_decision_invalid", {index = index})
        end
        local event = by_id[decision.trace_event_id]
        if not event or event.type ~= "tension_measure"
            or event.truth_status ~= "runtime_confirmed"
            or type(event.payload) ~= "table"
            or event.payload.kind ~= "shadow_route_decision"
            or event.payload.observer ~= decision.observer
            or event.payload.live_authority ~= decision.live_authority
            or event.payload.current_operator ~= decision.current_operator then
            return nil, instrument_error("observer_trace_ref_invalid", {
                ref = decision.trace_event_id,
            })
        end
        refs[#refs + 1] = decision.trace_event_id

        if decision.pressure_snapshot_ref ~= nil then
            if type(decision.pressure_snapshot_ref) ~= "string"
                or decision.pressure_snapshot_ref:match(
                    "^observer%-event%-%d+$"
                ) == nil then
                return nil, instrument_error("observer_pressure_ref_invalid", {
                    ref = decision.pressure_snapshot_ref,
                })
            end
            local pressure = by_id[decision.pressure_snapshot_ref]
            if not pressure or pressure.type ~= "tension_measure"
                or pressure.truth_status ~= "runtime_confirmed"
                or type(pressure.payload) ~= "table"
                or not pressure_kinds[pressure.payload.kind]
                or pressure.payload.current_operator ~= decision.current_operator
                or pressure.operator ~= event.operator then
                return nil, instrument_error("observer_pressure_ref_invalid", {
                    ref = decision.pressure_snapshot_ref,
                })
            end
            refs[#refs + 1] = decision.pressure_snapshot_ref
        end
    end
    return sorted_unique(refs)
end

local function physical_runner_view(result)
    local live_authority = result.router_mode == "tree"
        and "tree" or "legacy_control"
    return {
        identity = {
            kind = result.kind,
            packet_id = result.packet_id,
            live_authority = live_authority,
            birth = result.birth,
        },
        walk = {
            ticks = result.ticks or {},
            final_status = result.final_status,
            stop_reason = result.stop_reason,
            runtime_frame_ref = result.runtime_frame_ref,
        },
        routes = {
            entry_route = result.entry_route,
            routes = result.routes or {},
        },
        flow = {
            flow = result.flow,
            flow_readiness = result.flow_readiness,
            grave = result.grave,
        },
        terminal = {
            entry_derivation = result.entry_derivation,
            no_viable_edge = result.no_viable_edge,
            effect_failure = result.effect_failure,
            failure = result.failure,
            payload = result.payload,
            readiness = result.readiness,
            status = result.status,
        },
    }
end

local function component_map(instance, runner_result, corpse_or_nil)
    local runner = physical_runner_view(runner_result)
    local physis = instance.physis or {}
    local boundary = instance.boundary or {}
    local runtime = instance.runtime or {}
    local raw = {
        identity_and_work_contract = {
            packet = {
                protocol_version = instance.protocol_version,
                id = instance.id,
                session_id = instance.session_id,
                lineage_id = instance.lineage_id,
                generation = instance.generation,
                parent_id = instance.parent_id,
                parent_corpse_id = instance.parent_corpse_id,
                birth_kind = instance.birth_kind,
                carrier_id = instance.carrier_id,
                substrate_session_id = instance.substrate_session_id,
                topology = instance.topology,
                regime = instance.regime,
                process_contract_id = instance.process_contract_id,
                work_context = instance.work_context,
                stage_id = instance.stage_id,
                metadata = instance.metadata,
                ingress = instance.ingress,
            },
            runner = runner.identity,
        },
        operator_status_and_walk = {
            packet = {
                status = instance.status,
                operator = instance.operator,
            },
            runner = runner.walk,
        },
        committed_routes = runner.routes,
        budget_and_loss = {
            budget = physis.budget,
            clock = physis.clock,
            runtime_budget = runtime.budget,
            tension = instance.tension,
            loss_records = boundary.loss_records,
        },
        substrate_and_tool_calls = {
            host = physis.host,
            sandbox = physis.sandbox,
        },
        chaos_calm_field_revisions_effects = {
            chaos = instance.chaos,
            calm = instance.calm,
            field = instance.field,
            revisions = instance.revisions,
            boundary = {
                choices = boundary.choices,
                crystallizations = boundary.crystallizations,
                cycles = boundary.cycles,
                observations = boundary.observations,
                validations = boundary.validations,
            },
            runtime = {
                camera = runtime.camera,
                evidence = runtime.evidence,
                foundation = runtime.foundation,
                karma = runtime.karma,
                memory = runtime.memory,
            },
            runner = runner.flow,
        },
        repository_results = {
            repository_id = instance.repository_id,
        },
        qa_results = {
            qa_contract_id = instance.qa_contract_id,
            qa_contract = instance.qa_contract,
        },
        manifest_death_residue_terminal = {
            manifest = instance.manifest,
            death = instance.death,
            residue = instance.residue,
            terminal = instance.terminal,
            runner = runner.terminal,
        },
        packet_trace = instance.trace,
        corpse = corpse_or_nil,
    }
    return copy_plain(raw, "components")
end

local function remove_trace_refs(trace, removed)
    local result = {}
    local changed = false
    for _, event in ipairs(trace or {}) do
        if removed[event.id] then
            changed = true
        else
            result[#result + 1] = event
        end
    end
    return result, changed
end

local function normalize_trace_times(trace)
    for _, event in ipairs(trace or {}) do
        if type(event) == "table" and event.time ~= nil then
            event.time = excluded_host_time
        end
        if type(event) == "table"
            and (event.type == "death" or event.type == "manifest")
            and type(event.payload) == "table"
            and type(event.payload.residue) == "table"
            and type(event.payload.residue.trace_tail) == "table" then
            normalize_trace_times(event.payload.residue.trace_tail)
        end
    end
end

local function normalize_closed_host_time_paths(neutral)
    normalize_trace_times(neutral.packet_trace)
    local terminal = neutral.manifest_death_residue_terminal or {}
    if type(terminal.death) == "table" and terminal.death.time ~= nil then
        terminal.death.time = excluded_host_time
    end
    if type(terminal.residue) == "table"
        and type(terminal.residue.trace_tail) == "table" then
        normalize_trace_times(terminal.residue.trace_tail)
    end
    if type(neutral.corpse) == "table" then
        normalize_trace_times(neutral.corpse.trace_tail)
        if type(neutral.corpse.residue) == "table"
            and type(neutral.corpse.residue.trace_tail) == "table" then
            normalize_trace_times(neutral.corpse.residue.trace_tail)
        end
        if neutral.corpse.frozen_at ~= nil then
            neutral.corpse.frozen_at = excluded_host_time
        end
        neutral.corpse.corpse_hash = nil
    end
end

local function neutralize(exact, removed_refs)
    local neutral, copy_err = copy_plain(exact, "neutral_components")
    if not neutral then
        return nil, copy_err
    end
    local removed = {}
    for _, ref in ipairs(removed_refs) do
        removed[ref] = true
    end
    neutral.packet_trace = select(1, remove_trace_refs(neutral.packet_trace, removed))
    if neutral.corpse ~= nil then
        local filtered, changed = remove_trace_refs(neutral.corpse.trace_tail, removed)
        neutral.corpse.trace_tail = filtered
        -- Raw identity commits to the raw tail and never enters neutral comparison.
        if changed then neutral.corpse.corpse_hash = nil end
    end
    normalize_closed_host_time_paths(neutral)
    return neutral
end

local function component_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        life_id = record.life_id,
        corpse_status = record.corpse_status,
        exact_components = record.exact_components,
        exact_digest = record.exact_digest,
        observer_neutral_components = record.observer_neutral_components,
        observer_neutral_digest = record.observer_neutral_digest,
        removed_observer_refs = record.removed_observer_refs,
        removed_observer_ref_digest = record.removed_observer_ref_digest,
        event_truth_status = record.event_truth_status,
    }
end

local function identity_seed(record)
    return {
        protocol_version = record.protocol_version,
        life_id = record.life_id,
        corpse_status = record.corpse_status,
        exact_digest = record.exact_digest,
        observer_neutral_digest = record.observer_neutral_digest,
        removed_observer_ref_digest = record.removed_observer_ref_digest,
        encoded_bytes = record.encoded_bytes,
    }
end

local function projection_size(record)
    local ok, encoded = pcall(json.encode, component_seed(record))
    if not ok then
        return nil, instrument_error("projection_encoding_failed", {
            detail = tostring(encoded),
        })
    end
    return #encoded
end

local function verify_component_map(value, path)
    if not exact_keys(value, required_component_names, {corpse = true}) then
        return nil, instrument_error("projection_component_map_invalid", {path = path})
    end
    local copied, copy_err = copy_plain(value, path)
    if not copied then
        return nil, copy_err
    end
    return true
end

function projection.capture(instance, runner_result, corpse_or_nil, options)
    options = options or {}
    local inputs_ok, inputs_err = validate_inputs(instance, runner_result)
    if not inputs_ok then
        return nil, inputs_err
    end
    if not non_empty(options.life_id) then
        return nil, instrument_error("projection_life_id_required")
    end
    local max_bytes = default_max_projection_bytes
    if options.instrument_bounds ~= nil then
        if type(options.instrument_bounds) ~= "table"
            or not positive_integer(options.instrument_bounds.max_projection_bytes) then
            return nil, instrument_error("projection_bounds_invalid")
        end
        max_bytes = options.instrument_bounds.max_projection_bytes
    end
    if corpse_or_nil ~= nil then
        local corpse_ok, corpse_err = corpse_module.verify(corpse_or_nil)
        if not corpse_ok then
            return nil, instrument_error("projection_corpse_invalid", {
                detail = tostring(corpse_err),
            })
        end
        if corpse_or_nil.packet_id ~= instance.id
            or corpse_or_nil.lineage_id ~= instance.lineage_id
            or corpse_or_nil.generation ~= instance.generation then
            return nil, instrument_error("projection_corpse_identity_mismatch")
        end
    end

    local refs, refs_err = observer_refs(instance, runner_result)
    if not refs then
        return nil, refs_err
    end
    local exact, exact_err = component_map(instance, runner_result, corpse_or_nil)
    if not exact then
        return nil, exact_err
    end

    local before, before_err = digest.record(instance)
    if not before then
        return nil, instrument_error("projection_packet_digest_failed", {
            detail = tostring(before_err),
        })
    end
    local neutral, neutral_err = neutralize(exact, refs)
    if not neutral then
        return nil, neutral_err
    end
    local after, after_err = digest.record(instance)
    if not after then
        return nil, instrument_error("projection_packet_digest_failed", {
            detail = tostring(after_err),
        })
    end
    if before ~= after then
        return nil, instrument_error("projection_mutated_packet")
    end

    local exact_digest, exact_digest_err = tagged_digest(exact)
    if not exact_digest then return nil, exact_digest_err end
    local neutral_digest, neutral_digest_err = tagged_digest(neutral)
    if not neutral_digest then return nil, neutral_digest_err end
    local ref_digest, ref_digest_err = tagged_digest(refs)
    if not ref_digest then return nil, ref_digest_err end

    local record = {
        kind = "edge_life_projection",
        protocol_version = projection.protocol_version,
        projection_id = nil,
        life_id = options.life_id,
        corpse_status = corpse_or_nil ~= nil and "present"
            or instance.status ~= "dead" and "absent_alive"
            or "absent_unavailable",
        exact_components = exact,
        exact_digest = exact_digest,
        observer_neutral_components = neutral,
        observer_neutral_digest = neutral_digest,
        removed_observer_refs = refs,
        removed_observer_ref_digest = ref_digest,
        encoded_bytes = 0,
        event_truth_status = "runtime_confirmed",
    }
    local encoded_bytes, encoded_err = projection_size(record)
    if not encoded_bytes then return nil, encoded_err end
    if encoded_bytes > max_bytes then
        return nil, instrument_error("projection_bound_exceeded", {
            encoded_bytes = encoded_bytes,
            max_projection_bytes = max_bytes,
        })
    end
    record.encoded_bytes = encoded_bytes
    local projection_id, id_err = tagged_digest(identity_seed(record))
    if not projection_id then return nil, id_err end
    record.projection_id = projection_id

    local verified, verify_err = projection.verify(record)
    if not verified then
        return nil, verify_err
    end
    return copy_plain(record, "projection")
end

function projection.verify(record)
    if not exact_keys(record, {
        kind = true,
        protocol_version = true,
        projection_id = true,
        life_id = true,
        corpse_status = true,
        exact_components = true,
        exact_digest = true,
        observer_neutral_components = true,
        observer_neutral_digest = true,
        removed_observer_refs = true,
        removed_observer_ref_digest = true,
        encoded_bytes = true,
        event_truth_status = true,
    }) or record.kind ~= "edge_life_projection"
        or record.protocol_version ~= projection.protocol_version
        or not tagged_hash(record.projection_id)
        or not non_empty(record.life_id)
        or (record.corpse_status ~= "present"
            and record.corpse_status ~= "absent_alive"
            and record.corpse_status ~= "absent_unavailable")
        or not tagged_hash(record.exact_digest)
        or not tagged_hash(record.observer_neutral_digest)
        or not tagged_hash(record.removed_observer_ref_digest)
        or not non_negative_integer(record.encoded_bytes)
        or record.event_truth_status ~= "runtime_confirmed" then
        return nil, instrument_error("projection_record_invalid")
    end
    local exact_ok, exact_err = verify_component_map(record.exact_components, "exact_components")
    if not exact_ok then return nil, exact_err end
    local neutral_ok, neutral_err = verify_component_map(
        record.observer_neutral_components,
        "observer_neutral_components"
    )
    if not neutral_ok then return nil, neutral_err end
    if record.corpse_status == "present" then
        if record.exact_components.corpse == nil then
            return nil, instrument_error("projection_corpse_status_mismatch")
        end
        local corpse_ok, corpse_err = corpse_module.verify(record.exact_components.corpse)
        if not corpse_ok then
            return nil, instrument_error("projection_corpse_invalid", {
                detail = tostring(corpse_err),
            })
        end
    elseif record.exact_components.corpse ~= nil
        or record.observer_neutral_components.corpse ~= nil then
        return nil, instrument_error("projection_corpse_status_mismatch")
    end
    local sorted, sorted_err = sorted_unique(record.removed_observer_refs)
    if not sorted then return nil, sorted_err end
    if not same_value(sorted, record.removed_observer_refs) then
        return nil, instrument_error("projection_observer_refs_not_canonical")
    end
    local expected_exact, expected_exact_err = tagged_digest(record.exact_components)
    if not expected_exact then return nil, expected_exact_err end
    local expected_neutral, expected_neutral_err = tagged_digest(
        record.observer_neutral_components
    )
    if not expected_neutral then return nil, expected_neutral_err end
    local expected_refs, expected_refs_err = tagged_digest(record.removed_observer_refs)
    if not expected_refs then return nil, expected_refs_err end
    local expected_size, size_err = projection_size(record)
    if not expected_size then return nil, size_err end
    local expected_id, id_err = tagged_digest(identity_seed(record))
    if not expected_id then return nil, id_err end
    if record.exact_digest ~= expected_exact
        or record.observer_neutral_digest ~= expected_neutral
        or record.removed_observer_ref_digest ~= expected_refs
        or record.encoded_bytes ~= expected_size
        or record.projection_id ~= expected_id then
        return nil, instrument_error("projection_identity_mismatch")
    end
    return true
end

local function compare(left, right, component_key, digest_key)
    local left_ok, left_err = projection.verify(left)
    if not left_ok then return nil, left_err end
    local right_ok, right_err = projection.verify(right)
    if not right_ok then return nil, right_err end
    local differences = {}
    if left.corpse_status ~= right.corpse_status then
        differences[#differences + 1] = "corpse_status"
    end
    for _, name in ipairs(component_names) do
        if not same_value(left[component_key][name], right[component_key][name]) then
            differences[#differences + 1] = name
        end
    end
    if left[digest_key] ~= right[digest_key] and #differences == 0 then
        differences[#differences + 1] = digest_key
    end
    return #differences == 0, differences
end

function projection.same_exact(left, right)
    return compare(left, right, "exact_components", "exact_digest")
end

function projection.same_observer_neutral(left, right)
    return compare(
        left,
        right,
        "observer_neutral_components",
        "observer_neutral_digest"
    )
end

function projection.snapshot(record)
    local ok, err = projection.verify(record)
    if not ok then return nil, err end
    return copy_plain(record, "projection")
end

return projection
