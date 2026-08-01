local digest = require("core.digest")
local json = require("core.json")
local topology = require("core.topology")
local edge_catalog = require("runtime.edge_catalog")
local operator_registry = require("runtime.operator_registry")
local pressure = require("runtime.pressure")
local router = require("runtime.router")
local tree_router = require("runtime.tree_router")

local epoch = {
    protocol_version = "authority_epoch.v0",
}

local instrument_bounds_protocol = "authority-instrument-bounds.v0"
local edge_stats_protocol = "edge-stats.v3"
local observer_protocol = "edge-observer.v0"

local bound_keys = {
    "max_source_records",
    "max_single_source_bytes",
    "max_source_bytes_per_life",
    "max_projection_bytes",
    "max_error_records",
}

local default_bounds = {
    max_source_records = 4096,
    max_single_source_bytes = 2 * 1024 * 1024,
    max_source_bytes_per_life = 32 * 1024 * 1024,
    max_projection_bytes = 16 * 1024 * 1024,
    max_error_records = 256,
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

local function instrument_error(code, extra)
    local err = {
        class = "instrument_contract",
        code = code,
        stage = "authority_epoch",
    }
    for key, value in pairs(extra or {}) do
        err[key] = copy_value(value)
    end
    return err
end

local function invalid(path)
    return instrument_error("authority_epoch_invalid", {path = path})
end

local function exact_keys(value, allowed)
    if type(value) ~= "table" then
        return false
    end
    for key in pairs(value) do
        if not allowed[key] then
            return false
        end
    end
    for key in pairs(allowed) do
        if value[key] == nil then
            return false
        end
    end
    return true
end

local function sorted_unique(values)
    local seen = {}
    local result = {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function append_all(target, values)
    for _, value in ipairs(values or {}) do
        target[#target + 1] = value
    end
end

local function same_value(left, right)
    local left_ok, left_encoded = pcall(json.encode, left)
    local right_ok, right_encoded = pcall(json.encode, right)
    return left_ok and right_ok and left_encoded == right_encoded
end

local function positive_integer(value)
    return type(value) == "number"
        and value > 0
        and value % 1 == 0
        and value < math.huge
end

local function tagged_hash(value)
    return type(value) == "string"
        and #value == 71
        and value:sub(1, 7) == "sha256:"
        and value:sub(8):match("^[0-9a-f]+$") ~= nil
end

local function tagged_digest(value)
    local value_digest, digest_err = digest.record(value)
    if not value_digest then
        return nil, digest_err
    end
    return "sha256:" .. value_digest
end

local function normalize_bounds(configured)
    if configured ~= nil and type(configured) ~= "table" then
        return nil, instrument_error("invalid_authority_instrument_bounds")
    end
    configured = configured or {}
    local allowed = {}
    for _, key in ipairs(bound_keys) do
        allowed[key] = true
    end
    for key in pairs(configured) do
        if not allowed[key] then
            return nil, instrument_error("invalid_authority_instrument_bounds", {
                option = key,
            })
        end
    end

    local result = {
        kind = "authority_instrument_bounds",
        protocol_version = instrument_bounds_protocol,
        calibration_status = "unmeasured_safety_control",
    }
    for _, key in ipairs(bound_keys) do
        local value = configured[key]
        if value == nil then
            value = default_bounds[key]
        end
        if not positive_integer(value) then
            return nil, instrument_error("invalid_authority_instrument_bounds", {
                option = key,
            })
        end
        result[key] = value
    end
    return result
end

local function verify_bounds(value)
    local allowed = {
        kind = true,
        protocol_version = true,
        calibration_status = true,
    }
    for _, key in ipairs(bound_keys) do
        allowed[key] = true
    end
    if not exact_keys(value, allowed)
        or value.kind ~= "authority_instrument_bounds"
        or value.protocol_version ~= instrument_bounds_protocol
        or value.calibration_status ~= "unmeasured_safety_control"
    then
        return nil, invalid("instrumentation.bounds")
    end
    for _, key in ipairs(bound_keys) do
        if not positive_integer(value[key]) then
            return nil, invalid("instrumentation.bounds." .. key)
        end
    end
    return true
end

local function verify_legacy_descriptor(value)
    if not exact_keys(value, {
        kind = true,
        protocol_version = true,
        routing_policy = true,
        routing_policy_status = true,
        event_truth_status = true,
    }) or not same_value(value, router.legacy_descriptor()) then
        return nil, invalid("policy.legacy")
    end
    return true
end

local function verify_policy_descriptor(value, expected_kind)
    if expected_kind == "legacy" then
        return verify_legacy_descriptor(value)
    end
    local ok, err = tree_router.verify_descriptor(value)
    if not ok then
        return nil, err
    end
    return true
end

local function epoch_ids(record)
    local physics_id, physics_err = tagged_digest({
        protocol_version = epoch.protocol_version,
        physics = copy_value(record.physics),
    })
    if not physics_id then
        return nil, physics_err
    end
    local evidence_id, evidence_err = tagged_digest({
        protocol_version = epoch.protocol_version,
        physics_epoch_id = physics_id,
        configured = copy_value(record.configured),
        instrumentation = copy_value(record.instrumentation),
    })
    if not evidence_id then
        return nil, evidence_err
    end
    return physics_id, evidence_id
end

local function expected_assertion(expected, record)
    if expected == nil then
        return true
    end
    if type(expected) ~= "table" then
        return nil, instrument_error("invalid_authority_epoch_expectation")
    end
    for key, value in pairs(expected) do
        if key ~= "physics_epoch_id" and key ~= "evidence_epoch_id" then
            return nil, instrument_error("invalid_authority_epoch_expectation", {
                option = key,
            })
        end
        if value ~= nil and not tagged_hash(value) then
            return nil, instrument_error("invalid_authority_epoch_expectation", {
                option = key,
            })
        end
    end
    for _, key in ipairs({"physics_epoch_id", "evidence_epoch_id"}) do
        if expected[key] ~= nil and expected[key] ~= record[key] then
            return nil, instrument_error("authority_epoch_expectation_mismatch", {
                fatal_to_harness = true,
                identity = key,
                expected = expected[key],
                actual = record[key],
            })
        end
    end
    return true
end

local function tree_descriptor(options)
    local pressure_descriptor, pressure_diagnostics = pressure.describe(options)
    if not pressure_descriptor then
        return nil, pressure_diagnostics
    end
    local descriptor, descriptor_err = tree_router.describe(
        pressure_descriptor,
        options.tree_router
    )
    if not descriptor then
        return nil, descriptor_err
    end
    return descriptor, pressure_diagnostics
end

local function scan_unknown_ablation(options)
    for key in pairs(options) do
        if type(key) == "string" and key:match("^ablate_")
            and not pressure.is_known_ablation_option(key)
        then
            return nil, instrument_error("unknown_policy_affecting_option", {
                option = key,
            })
        end
    end
    return true
end

local function legacy_unused_options(options)
    local unused = {}
    if options.pressure_policy ~= nil then
        unused[#unused + 1] = "pressure_policy"
    end
    for _, name in ipairs(pressure.ablation_option_names()) do
        if options[name] ~= nil then
            unused[#unused + 1] = name
        end
    end
    if options.tree_router ~= nil then
        if type(options.tree_router) == "table" then
            local count = 0
            for key in pairs(options.tree_router) do
                unused[#unused + 1] = "tree_router." .. tostring(key)
                count = count + 1
            end
            if count == 0 then
                unused[#unused + 1] = "tree_router"
            end
        else
            unused[#unused + 1] = "tree_router"
        end
    end
    if options.legacy_shadow ~= nil then
        unused[#unused + 1] = "legacy_shadow"
    end
    return unused
end

function epoch.resolve(options)
    if options ~= nil and type(options) ~= "table" then
        return nil, instrument_error("invalid_authority_epoch_options")
    end
    options = options or {}
    local known, known_err = scan_unknown_ablation(options)
    if not known then
        return nil, known_err
    end

    local mode = options.router_mode or "shadow"
    if mode ~= "legacy" and mode ~= "shadow" and mode ~= "tree" then
        return nil, instrument_error("invalid_router_mode")
    end
    local surface, surface_err = edge_catalog.authority_surface()
    if not surface then
        return nil, surface_err
    end
    local bounds, bounds_err = normalize_bounds(options.authority_instrument_bounds)
    if not bounds then
        return nil, bounds_err
    end

    local diagnostics_unused = {}
    local legacy = router.legacy_descriptor()
    local configured_owner = mode == "tree" and "tree" or "legacy_control"
    local live_policy = legacy
    local observer_mode = "none"
    local observer_policy = "none"
    local observer_enabled = false

    if mode == "legacy" then
        append_all(diagnostics_unused, legacy_unused_options(options))
    else
        local tree, tree_diagnostics = tree_descriptor(options)
        if not tree then
            return nil, tree_diagnostics
        end
        append_all(diagnostics_unused, tree_diagnostics.unused_options)
        if mode == "shadow" then
            observer_mode = "tree_shadow"
            observer_policy = tree
            observer_enabled = true
            if options.legacy_shadow ~= nil then
                diagnostics_unused[#diagnostics_unused + 1] = "legacy_shadow"
            end
        else
            live_policy = tree
            if options.legacy_shadow ~= false then
                observer_mode = "legacy_shadow"
                observer_policy = legacy
                observer_enabled = true
            end
        end
    end

    local record = {
        kind = "authority_epoch",
        protocol_version = epoch.protocol_version,
        configured = {
            router_mode = mode,
            configured_movement_owner = configured_owner,
        },
        physics = {
            topology_version = topology.version,
            authority_surface_id = surface.surface_id,
            operator_registry_version = operator_registry.protocol_version,
            movement_owner = configured_owner,
            live_policy = copy_value(live_policy),
        },
        instrumentation = {
            router_mode = mode,
            observer_mode = observer_mode,
            observer_enabled = observer_enabled,
            observer_policy = copy_value(observer_policy),
            observer_protocol = observer_enabled and observer_protocol or "none",
            edge_stats_protocol = edge_stats_protocol,
            bounds = bounds,
        },
        event_truth_status = "runtime_confirmed",
    }
    local physics_id, evidence_id_or_err = epoch_ids(record)
    if not physics_id then
        return nil, instrument_error("authority_epoch_digest_failure", {
            detail = evidence_id_or_err,
        })
    end
    record.physics_epoch_id = physics_id
    record.evidence_epoch_id = evidence_id_or_err

    local verified, verify_err = epoch.verify(record)
    if not verified then
        return nil, verify_err
    end
    local expected_ok, expected_err = expected_assertion(
        options.expected_authority_epoch,
        record
    )
    if not expected_ok then
        return nil, expected_err
    end
    return copy_value(record), {
        kind = "authority_epoch_diagnostics",
        unused_options = sorted_unique(diagnostics_unused),
        event_truth_status = "runtime_confirmed",
    }
end

function epoch.verify(record)
    if not exact_keys(record, {
        kind = true,
        protocol_version = true,
        configured = true,
        physics = true,
        instrumentation = true,
        physics_epoch_id = true,
        evidence_epoch_id = true,
        event_truth_status = true,
    }) or record.kind ~= "authority_epoch"
        or record.protocol_version ~= epoch.protocol_version
        or record.event_truth_status ~= "runtime_confirmed"
        or not tagged_hash(record.physics_epoch_id)
        or not tagged_hash(record.evidence_epoch_id)
    then
        return nil, invalid("record")
    end

    if not exact_keys(record.configured, {
        router_mode = true,
        configured_movement_owner = true,
    }) then
        return nil, invalid("configured")
    end
    local mode = record.configured.router_mode
    if mode ~= "legacy" and mode ~= "shadow" and mode ~= "tree" then
        return nil, invalid("configured.router_mode")
    end
    local expected_owner = mode == "tree" and "tree" or "legacy_control"
    if record.configured.configured_movement_owner ~= expected_owner then
        return nil, invalid("configured.configured_movement_owner")
    end

    if not exact_keys(record.physics, {
        topology_version = true,
        authority_surface_id = true,
        operator_registry_version = true,
        movement_owner = true,
        live_policy = true,
    }) or record.physics.topology_version ~= topology.version
        or record.physics.operator_registry_version ~= operator_registry.protocol_version
        or record.physics.movement_owner ~= expected_owner
    then
        return nil, invalid("physics")
    end
    local surface, surface_err = edge_catalog.authority_surface()
    if not surface then
        return nil, surface_err
    end
    if record.physics.authority_surface_id ~= surface.surface_id then
        return nil, {
            class = "instrument_contract",
            code = "authority_surface_mismatch",
            stage = "authority_epoch",
        }
    end
    local live_ok, live_err = verify_policy_descriptor(
        record.physics.live_policy,
        expected_owner == "tree" and "tree" or "legacy"
    )
    if not live_ok then
        return nil, live_err
    end

    if not exact_keys(record.instrumentation, {
        router_mode = true,
        observer_mode = true,
        observer_enabled = true,
        observer_policy = true,
        observer_protocol = true,
        edge_stats_protocol = true,
        bounds = true,
    }) or record.instrumentation.router_mode ~= mode
        or record.instrumentation.edge_stats_protocol ~= edge_stats_protocol
        or type(record.instrumentation.observer_enabled) ~= "boolean"
    then
        return nil, invalid("instrumentation")
    end
    local bounds_ok, bounds_err = verify_bounds(record.instrumentation.bounds)
    if not bounds_ok then
        return nil, bounds_err
    end

    local expected_observer_mode = "none"
    local expected_observer_kind = "none"
    if mode == "shadow" then
        expected_observer_mode = "tree_shadow"
        expected_observer_kind = "tree"
    elseif mode == "tree" and record.instrumentation.observer_enabled then
        expected_observer_mode = "legacy_shadow"
        expected_observer_kind = "legacy"
    end
    local expected_enabled = expected_observer_mode ~= "none"
    if record.instrumentation.observer_enabled ~= expected_enabled
        or record.instrumentation.observer_mode ~= expected_observer_mode
        or record.instrumentation.observer_protocol
            ~= (expected_enabled and observer_protocol or "none")
    then
        return nil, invalid("instrumentation.observer")
    end
    if expected_observer_kind == "none" then
        if record.instrumentation.observer_policy ~= "none" then
            return nil, invalid("instrumentation.observer_policy")
        end
    else
        local observer_ok, observer_err = verify_policy_descriptor(
            record.instrumentation.observer_policy,
            expected_observer_kind
        )
        if not observer_ok then
            return nil, observer_err
        end
    end

    local physics_id, evidence_id_or_err = epoch_ids(record)
    if not physics_id then
        return nil, invalid("identity")
    end
    if record.physics_epoch_id ~= physics_id
        or record.evidence_epoch_id ~= evidence_id_or_err
    then
        return nil, invalid("identity")
    end
    return true
end

function epoch.same_physics(left, right)
    local left_ok, left_err = epoch.verify(left)
    if not left_ok then
        return nil, left_err
    end
    local right_ok, right_err = epoch.verify(right)
    if not right_ok then
        return nil, right_err
    end
    return left.physics_epoch_id == right.physics_epoch_id
end

function epoch.same_evidence(left, right)
    local left_ok, left_err = epoch.verify(left)
    if not left_ok then
        return nil, left_err
    end
    local right_ok, right_err = epoch.verify(right)
    if not right_ok then
        return nil, right_err
    end
    return left.evidence_epoch_id == right.evidence_epoch_id
end

function epoch.snapshot(record)
    local ok, err = epoch.verify(record)
    if not ok then
        return nil, err
    end
    return copy_value(record)
end

return epoch
