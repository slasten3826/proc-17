local field = require("runtime.field")

local upper_coverage = {
    protocol_version = "upper.coverage_view.v0",
}

local sensor_classes = {
    semantic = {semantic = true, material = true},
    field_native = {material = true},
    relation_native = {relation = true, material = true},
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

local function positive_integer(value, fallback, name)
    value = value or fallback
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, name .. " must be a positive integer"
    end
    return value
end

local function exact_ref(unit)
    return table.concat({
        "coverage",
        "field_unit",
        unit.id,
        tostring(unit.version),
    }, ":")
end

local function inferred_sensor(record)
    if sensor_classes[record.sensor] then
        return record.sensor
    end
    local payload = record.payload or {}
    if sensor_classes[payload.sensor] then
        return payload.sensor
    end
    if payload.kind == "field_native_observation" then
        return "field_native"
    elseif payload.kind == "relation_native_observation" then
        return "relation_native"
    end
    return "semantic"
end

local function inferred_classes(record, sensor)
    if type(record.observation_classes) == "table"
        and #record.observation_classes > 0 then
        return record.observation_classes
    end
    if sensor == "field_native" then
        return {"material"}
    elseif sensor == "relation_native" then
        return {"relation"}
    end
    return {"semantic"}
end

local function validate_view(view)
    if type(view) ~= "table" or view.protocol_version ~= upper_coverage.protocol_version
        or type(view.entries) ~= "table"
        or type(view.observation_count) ~= "number"
        or type(view.omitted_observation_count) ~= "number"
        or type(view.object_count) ~= "number"
        or type(view.omitted_object_count) ~= "number"
        or type(view.truncated) ~= "boolean"
        or view.event_truth_status ~= "runtime_confirmed" then
        return nil, "invalid upper coverage view"
    end
    for _, entry in ipairs(view.entries) do
        if type(entry) ~= "table" or type(entry.object_id) ~= "string"
            or type(entry.version) ~= "number"
            or not sensor_classes[entry.sensor]
            or not sensor_classes[entry.sensor][entry.observation_class]
            or type(entry.observation_event_ref) ~= "string" then
            return nil, "invalid upper coverage entry"
        end
    end
    return true
end

function upper_coverage.compatible(sensor, observation_class)
    return sensor_classes[sensor] ~= nil
        and sensor_classes[sensor][observation_class] == true
end

function upper_coverage.derive(instance, options)
    options = options or {}
    local max_observations, observation_err = positive_integer(
        options.max_observations,
        256,
        "upper max_observations"
    )
    if not max_observations then
        return nil, observation_err
    end
    local max_objects, object_err = positive_integer(
        options.max_objects,
        256,
        "upper max_objects"
    )
    if not max_objects then
        return nil, object_err
    end
    local generation = options.generation or instance.generation
    if type(generation) ~= "number" or generation < 1
        or generation ~= math.floor(generation) then
        return nil, "upper coverage generation must be a positive integer"
    end

    local records = instance.boundary and instance.boundary.observations
        and instance.boundary.observations.upper or {}
    local first_index = math.max(1, #records - max_observations + 1)
    local latest = {}
    for index = first_index, #records do
        local record = records[index]
        local sensor = inferred_sensor(record)
        local classes = inferred_classes(record, sensor)
        for _, class in ipairs(classes) do
            if not upper_coverage.compatible(sensor, class) then
                return nil, "upper observation sensor/class mismatch"
            end
            for _, covered in ipairs(record.read_units and record.read_units.entries or {}) do
                local key = covered.object_id .. "\0" .. class
                latest[key] = {
                    object_id = covered.object_id,
                    version = covered.version,
                    observation_class = class,
                    sensor = sensor,
                    observation_event_ref = record.trace_event_id or record.id,
                }
            end
        end
    end

    local keys = {}
    for key in pairs(latest) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    local entries = {}
    local omitted_entries = 0
    for _, key in ipairs(keys) do
        if #entries < max_objects then
            entries[#entries + 1] = latest[key]
        else
            omitted_entries = omitted_entries + 1
        end
    end

    local object_view = field.view(instance, {
        activation = {
            live = true,
            selected = true,
            suppressed = true,
            dissolved = true,
        },
        generation = generation,
        limit = max_objects,
    }) or {total_count = 0, units = {}, truncated = false}
    return {
        protocol_version = upper_coverage.protocol_version,
        generation = generation,
        entries = copy_value(entries),
        observation_count = #records - first_index + 1,
        omitted_observation_count = first_index - 1,
        object_count = object_view.total_count,
        omitted_object_count = math.max(0, object_view.total_count - #object_view.units),
        omitted_coverage_entry_count = omitted_entries,
        truncated = first_index > 1 or object_view.truncated == true or omitted_entries > 0,
        event_truth_status = "runtime_confirmed",
    }
end

local function classify(unit)
    local activation_actor = unit.activation_source and unit.activation_source.actor
    if activation_actor == "☳" or activation_actor == "☷" then
        return "material", "field_native", "activation_version_changed"
    end
    if unit.kind == "user_prompt" or unit.kind == "network_carrier" then
        return "semantic", "semantic", "semantic_ingress_unobserved"
    end
    if unit.kind == "l1_physical_sample"
        or unit.kind == "grave_warning"
        or unit.kind == "grave_bequest" then
        return nil
    end
    if unit.created_by == "☵" or unit.created_by == "☷"
        or unit.created_by == "☴" then
        return "material", "field_native", "field_consequence_unobserved"
    end
    return false, nil, "unclassified_upper_mutation"
end

function upper_coverage.needs(instance, view, options)
    options = options or {}
    local valid, view_err = validate_view(view)
    if not valid then
        return nil, view_err
    end
    if view.generation ~= instance.generation then
        return nil, "upper coverage view generation is stale"
    end
    local max_objects, object_err = positive_integer(
        options.max_objects,
        256,
        "upper need max_objects"
    )
    if not max_objects then
        return nil, object_err
    end

    local covered = {}
    for _, entry in ipairs(view.entries) do
        covered[entry.object_id .. "\0" .. entry.observation_class] = entry
    end
    local current = field.view(instance, {
        activation = {
            live = true,
            selected = true,
            suppressed = true,
            dissolved = true,
        },
        generation = instance.generation,
        limit = max_objects,
    }) or {units = {}, total_count = 0, truncated = false}

    local items = {}
    local diagnostics = {}
    for _, unit in ipairs(current.units) do
        local class, sensor, reason = classify(unit)
        if class == false then
            diagnostics[#diagnostics + 1] = {
                kind = "unclassified_upper_mutation",
                object_id = unit.id,
                version = unit.version,
                scope_refs = {exact_ref(unit)},
                provenance_refs = {unit.created_event_id},
                event_truth_status = "runtime_confirmed",
            }
        elseif class ~= nil then
            local prior = covered[unit.id .. "\0" .. class]
            if not prior or prior.version ~= unit.version then
                items[#items + 1] = {
                    kind = "upper_object_need",
                    object_id = unit.id,
                    version = unit.version,
                    observation_class = class,
                    sensor = sensor,
                    reason = reason,
                    scope_refs = {exact_ref(unit)},
                    provenance_refs = {unit.created_event_id},
                    covered_version = prior and prior.version,
                    event_truth_status = "runtime_confirmed",
                }
            end
        end
    end
    table.sort(items, function(left, right)
        if left.sensor ~= right.sensor then
            return left.sensor < right.sensor
        end
        if left.object_id ~= right.object_id then
            return left.object_id < right.object_id
        end
        return left.observation_class < right.observation_class
    end)

    local truncated = view.truncated or current.truncated == true
    local qualification_status = "qualified"
    if #diagnostics > 0 then
        qualification_status = "unclassified_upper_mutation"
    elseif truncated then
        qualification_status = "incomplete_scope"
    end
    return {
        protocol_version = "upper.need_set.v0",
        generation = instance.generation,
        items = copy_value(items),
        diagnostics = copy_value(diagnostics),
        object_count = current.total_count,
        truncated = truncated,
        qualification_status = qualification_status,
        event_truth_status = "runtime_confirmed",
    }
end

return upper_coverage
