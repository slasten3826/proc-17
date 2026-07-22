local repository_formation = {
    protocol_version = "runtime.repository_formation.v0",
    unit_basis_protocol = "runtime.repository_unit_formation_basis.v0",
    set_protocol = "runtime.repository_formation_set.v0",
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

local function diagnostic(code, input)
    input = input or {}
    return {
        kind = "repository_formation_diagnostic",
        protocol_version = "runtime.repository_formation_diagnostic.v0",
        code = code,
        object_id = input.object_id,
        version = input.version,
        source_refs = copy_value(input.source_refs or {}),
        event_truth_status = "runtime_confirmed",
    }
end

local function positive_integer(value, name)
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, name .. " must be a positive integer"
    end
    return value
end

local function sorted_unique(values)
    local result = {}
    local seen = {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function event_by_id(instance, id)
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.id == id then
            return event
        end
    end
    return nil
end

local function current_unit(instance, id, version)
    if type(instance) ~= "table" or type(instance.field) ~= "table"
        or type(instance.field.units) ~= "table" then
        return nil, "Packet field is unavailable"
    end
    local unit = instance.field.units[id]
    if type(unit) ~= "table" or unit.id ~= id or unit.kind ~= "structured_item"
        or type(unit.version) ~= "number" or unit.version < 1
        or unit.version ~= math.floor(unit.version) then
        return nil, "repository field unit invariant failed"
    end
    if unit.version ~= version then
        return nil, diagnostic("repository_artifact_stale", {
            object_id = id,
            version = version,
            source_refs = {unit.created_event_id},
        })
    end
    if unit.generation ~= instance.generation then
        return nil, diagnostic("repository_artifact_foreign_generation", {
            object_id = id,
            version = version,
            source_refs = {unit.created_event_id},
        })
    end
    if unit.activation ~= "live" and unit.activation ~= "selected" then
        return nil, diagnostic("repository_artifact_set_absent", {
            object_id = id,
            version = version,
            source_refs = {unit.created_event_id},
        })
    end
    return unit
end

local function names_unit_once(payload, id)
    if type(payload.formed_unit_ids) ~= "table"
        or type(payload.formed_unit_versions) ~= "table" then
        return nil, "structure formation has malformed unit membership"
    end
    local count = 0
    for _, formed_id in ipairs(payload.formed_unit_ids) do
        if formed_id == id then
            count = count + 1
        end
    end
    if count > 1 then
        return nil, "structure formation repeats a formed unit"
    end
    return count == 1
end

local function formation_matches(instance, unit)
    local matches = {}
    for _, event in ipairs(instance.trace or {}) do
        local payload = event.payload
        if event.type == "structure_formation"
            and event.packet_id == instance.id
            and event.generation == instance.generation then
            if event.operator ~= "☵" or event.truth_status ~= "runtime_confirmed"
                or type(payload) ~= "table"
                or payload.protocol_version ~= "field.structure_formation.v0"
                or payload.event_truth_status ~= "runtime_confirmed" then
                return nil, "malformed repository structure formation"
            end
            local names, names_err = names_unit_once(payload, unit.id)
            if names == nil then
                return nil, names_err
            end
            if names then
                local formed_version = payload.formed_unit_versions[unit.id]
                if type(formed_version) ~= "number" or formed_version < 1
                    or formed_version ~= math.floor(formed_version)
                    or formed_version > unit.version then
                    return nil, "repository structure formation version invariant failed"
                end
                if unit.created_by ~= "☵"
                    or unit.created_event_id ~= payload.crystallization_event_ref then
                    return nil, "repository structure formation creation ref mismatch"
                end
                matches[#matches + 1] = event
            end
        end
    end
    if #matches == 0 then
        return nil, diagnostic("repository_formation_missing", {
            object_id = unit.id,
            version = unit.version,
            source_refs = {unit.created_event_id},
        })
    end
    if #matches > 1 then
        local refs = {}
        for _, event in ipairs(matches) do
            refs[#refs + 1] = event.id
        end
        return nil, diagnostic("repository_formation_ambiguous", {
            object_id = unit.id,
            version = unit.version,
            source_refs = refs,
        })
    end
    return matches[1]
end

local function matching_choices(instance, formation_event, unit)
    local matches = {}
    for _, event in ipairs(instance.trace or {}) do
        local payload = event.payload
        if event.type == "choice" and type(payload) == "table"
            and payload.mode == "alternative_collapse"
            and payload.choice_set_ref == formation_event.id then
            if event.packet_id ~= instance.id
                or event.generation ~= instance.generation
                or event.operator ~= "☳"
                or event.truth_status ~= "runtime_confirmed"
                or payload.truth_status ~= "runtime_confirmed"
                or type(payload.selected_ids) ~= "table"
                or type(payload.suppressed_ids) ~= "table"
                or type(payload.operand_versions) ~= "table"
                or type(payload.post_versions) ~= "table" then
                return nil, "malformed repository choice event"
            end
            local selected = false
            for _, id in ipairs(payload.selected_ids) do
                selected = selected or id == unit.id
            end
            if selected then
                if payload.operand_versions[unit.id] == nil
                    or payload.post_versions[unit.id] ~= unit.version then
                    return nil, "repository choice version invariant failed"
                end
                matches[#matches + 1] = event
            end
        end
    end
    if #matches == 0 then
        return nil, diagnostic("repository_choice_missing", {
            object_id = unit.id,
            version = unit.version,
            source_refs = {formation_event.id},
        })
    end
    if #matches > 1 then
        local refs = {}
        for _, event in ipairs(matches) do
            refs[#refs + 1] = event.id
        end
        return nil, diagnostic("repository_choice_ambiguous", {
            object_id = unit.id,
            version = unit.version,
            source_refs = refs,
        })
    end
    return matches[1]
end

local function basis_for(instance, unit)
    local formation, formation_err = formation_matches(instance, unit)
    if not formation then
        return nil, formation_err
    end
    local formation_payload = formation.payload
    local choice_event
    if formation_payload.choice_contract ~= nil or unit.activation == "selected" then
        if unit.activation ~= "selected" then
            return nil, diagnostic("repository_choice_missing", {
                object_id = unit.id,
                version = unit.version,
                source_refs = {formation.id},
            })
        end
        choice_event, formation_err = matching_choices(instance, formation, unit)
        if not choice_event then
            return nil, formation_err
        end
    end
    local refs = {
        formation.id,
        unit.created_event_id,
        formation_payload.crystallization_event_ref,
        formation_payload.identity_map_event_ref,
    }
    for _, ref in ipairs(unit.source_refs or {}) do
        refs[#refs + 1] = ref
    end
    if choice_event then
        refs[#refs + 1] = choice_event.id
    end
    return {
        protocol_version = repository_formation.unit_basis_protocol,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        unit_id = unit.id,
        unit_version = unit.version,
        unit_created_event_ref = unit.created_event_id,
        activation = unit.activation,
        formation_event_ref = formation.id,
        choice_event_ref = choice_event and choice_event.id or nil,
        provenance_refs = sorted_unique(refs),
        event_truth_status = "runtime_confirmed",
        content_truth_status = unit.content_truth_status or "semantic_proposal",
    }
end

function repository_formation.for_unit(instance, unit_id, unit_version)
    if type(unit_id) ~= "string" or unit_id == "" then
        return nil, "repository formation unit id is required"
    end
    local _, version_err = positive_integer(unit_version,
        "repository formation unit version")
    if version_err then
        return nil, version_err
    end
    local unit, unit_err = current_unit(instance, unit_id, unit_version)
    if not unit then
        return nil, unit_err
    end
    local basis, basis_err = basis_for(instance, unit)
    if not basis then
        return nil, basis_err
    end
    return copy_value(basis)
end

function repository_formation.current_set(instance, options)
    options = options or {}
    local max_units = options.max_units or 128
    local _, max_err = positive_integer(max_units, "repository formation max_units")
    if max_err then
        return nil, max_err
    end
    if type(instance) ~= "table" or type(instance.field) ~= "table"
        or type(instance.field.units) ~= "table"
        or type(instance.field.unit_order) ~= "table" then
        return nil, "Packet field invariant failed"
    end

    local units = {}
    for _, id in ipairs(instance.field.unit_order) do
        local unit = instance.field.units[id]
        if type(unit) ~= "table" or unit.id ~= id then
            return nil, "Packet field order invariant failed"
        end
        local carrier = unit.carrier
        if type(carrier) == "table" and type(carrier.kind) == "string"
            and carrier.kind:match("^repository%.")
            and (unit.activation == "live" or unit.activation == "selected") then
            if unit.generation ~= instance.generation then
                return nil, diagnostic("repository_artifact_foreign_generation", {
                    object_id = unit.id,
                    version = unit.version,
                    source_refs = {unit.created_event_id},
                })
            end
            if carrier.kind ~= "repository.create_text_file.v0" then
                return nil, diagnostic("repository_artifact_set_absent", {
                    object_id = unit.id,
                    version = unit.version,
                    source_refs = {unit.created_event_id},
                })
            end
            if #units >= max_units then
                return nil, diagnostic("repository_artifact_limit_exceeded")
            end
            units[#units + 1] = unit
        end
    end
    if #units == 0 then
        return nil, diagnostic("repository_artifact_set_absent")
    end

    local bases = {}
    local formation_ref
    local choice_ref
    local refs = {}
    local content_status
    for _, unit in ipairs(units) do
        local basis, basis_err = basis_for(instance, unit)
        if not basis then
            return nil, basis_err
        end
        if formation_ref and formation_ref ~= basis.formation_event_ref then
            return nil, diagnostic("repository_formation_ambiguous", {
                source_refs = {formation_ref, basis.formation_event_ref},
            })
        end
        if choice_ref and basis.choice_event_ref
            and choice_ref ~= basis.choice_event_ref then
            return nil, diagnostic("repository_choice_ambiguous", {
                source_refs = {choice_ref, basis.choice_event_ref},
            })
        end
        formation_ref = formation_ref or basis.formation_event_ref
        choice_ref = choice_ref or basis.choice_event_ref
        content_status = content_status or basis.content_truth_status
        if content_status ~= basis.content_truth_status then
            content_status = "mixed"
        end
        for _, ref in ipairs(basis.provenance_refs) do
            refs[#refs + 1] = ref
        end
        bases[#bases + 1] = basis
    end
    table.sort(bases, function(left, right)
        return left.unit_id < right.unit_id
    end)
    return copy_value({
        protocol_version = repository_formation.set_protocol,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        formation_event_ref = formation_ref,
        choice_event_ref = choice_ref,
        units = bases,
        source_refs = sorted_unique(refs),
        event_truth_status = "runtime_confirmed",
        content_truth_status = content_status or "semantic_proposal",
    })
end

return repository_formation
