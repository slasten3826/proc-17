local artifact_set = require("runtime.artifact_set")
local capabilities = require("runtime.repository_capability")
local digest = require("core.digest")
local json = require("core.json")
local packet_core = require("core.packet")
local repository_intent = require("runtime.repository_intent")
local substrate_contract = require("substrates.contract")

local default_inventory_bounds = {
    protocol_version = "repository.inventory_bounds.v0",
    max_entries = 256,
    max_depth = 64,
    max_path_bytes = 1024,
    max_component_bytes = 255,
    max_file_bytes = 1048576,
    max_total_bytes = 8388608,
}

local validation_inventory_ceiling = {
    protocol_version = "repository.inventory_bounds.v0",
    max_entries = 4096,
    max_depth = 64,
    max_path_bytes = 1024,
    max_component_bytes = 255,
    max_file_bytes = 1048576,
    max_total_bytes = 67108864,
}

local candidate_seal = {
    request_protocol = "repository.candidate_seal_request.v0",
    inventory_protocol = "repository.seal_inventory.v0",
    seal_protocol = "repository.candidate_seal.v0",
    result_protocol = "repository.candidate_seal_result.v0",
    -- Public projection only; callers cannot mutate the body's trusted defaults.
    default_inventory_bounds = {
        protocol_version = "repository.inventory_bounds.v0",
        max_entries = 256,
        max_depth = 64,
        max_path_bytes = 1024,
        max_component_bytes = 255,
        max_file_bytes = 1048576,
        max_total_bytes = 8388608,
    },
}

local request_keys = {
    protocol_version = true, request_id = true, packet_id = true,
    lineage_id = true, generation = true, process_contract_id = true,
    context = true, stage_id = true, repository_id = true,
    root_authority_id = true, lifecycle_id = true,
    lifecycle_revision = true, root_fingerprint = true,
    grant_id = true, grant_revision = true, artifact_set_id = true,
    artifact_set_inspection_id = true, expected_files = true,
    expected_directories = true, inventory_bounds = true, source_refs = true,
    event_truth_status = true, content_truth_status = true,
}
local expected_file_keys = {
    relative_path = true, expected_kind = true, work_unit_id = true,
    work_unit_version = true, expected_bytes = true, expected_sha256 = true,
    completion_ref = true, verification_ref = true,
}
local bounds_keys = {
    protocol_version = true, max_entries = true, max_depth = true,
    max_path_bytes = true, max_component_bytes = true,
    max_file_bytes = true, max_total_bytes = true,
}
local provider_inventory_keys = {
    protocol_version = true, operation = true, outcome = true,
    root_before = true, root_after = true, stable = true, entries = true,
    bounds_observed = true, mutation_primitive_entered = true,
    published = true, cost = true,
}
local provider_entry_keys = {
    relative_path = true, kind = true, identity_before = true,
    identity_after = true, bytes = true, content = true,
}
local provider_entry_required = {
    relative_path = true, kind = true, identity_before = true,
    identity_after = true,
}
local observed_bounds_keys = {
    max_entries = true, max_depth = true, max_path_bytes = true,
    max_component_bytes = true, max_file_bytes = true,
    max_total_bytes = true, observed_entries = true,
    observed_total_bytes = true,
}
local identity_keys = {device = true, inode = true}
local cost_keys = {tool_calls = true, file_writes = true, time_ms = true}
local provider_error_keys = {
    protocol_version = true, class = true, code = true, stage = true,
    errno = true, mutation_primitive_entered = true, published = true,
    cost = true, residue = true,
}
local provider_error_required = {
    protocol_version = true, class = true, code = true, stage = true,
    mutation_primitive_entered = true, published = true, cost = true,
}
local inventory_keys = {
    protocol_version = true, inventory_id = true, request_id = true,
    root_fingerprint = true, root_continuity = true, entries = true,
    observed_entry_count = true, observed_total_bytes = true,
    inventory_digest = true, source_refs = true, event_truth_status = true,
}
local inventory_entry_keys = {
    relative_path = true, kind = true, bytes = true, sha256 = true,
    stable_identity_ref = true,
}
local seal_keys = {
    protocol_version = true, candidate_seal_id = true, packet_id = true,
    lineage_id = true, generation = true, process_contract_id = true,
    context = true, stage_id = true, repository_id = true,
    root_authority_id = true, lifecycle_id = true, root_fingerprint = true,
    artifact_set_id = true, request_id = true, inventory_id = true,
    inventory_digest = true, authority_closure_ref = true, artifacts = true,
    source_refs = true, event_truth_status = true, content_truth_status = true,
}
local seal_artifact_keys = {
    relative_path = true, work_unit_id = true, work_unit_version = true,
    bytes = true, sha256 = true, completion_ref = true,
    verification_ref = true,
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

local function required_without(allowed, omitted)
    local result = {}
    for key in pairs(allowed) do
        if key ~= omitted then
            result[key] = true
        end
    end
    return result
end

local request_required_without_id = required_without(request_keys, "request_id")
local seal_required_without_id = required_without(seal_keys, "candidate_seal_id")

local function exact_keys(value, allowed, required, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, name .. " must be a plain table"
    end
    for key in pairs(value) do
        if not allowed[key] then
            return nil, name .. " contains unknown key: " .. tostring(key)
        end
    end
    for key in pairs(required or allowed) do
        if value[key] == nil then
            return nil, name .. " is missing key: " .. key
        end
    end
    return true
end

local function non_empty(value)
    return type(value) == "string" and value ~= ""
end

local function positive_integer(value)
    return type(value) == "number" and value >= 1 and value == math.floor(value)
end

local function non_negative_integer(value)
    return type(value) == "number" and value >= 0 and value == math.floor(value)
end

local function non_negative_number(value)
    return type(value) == "number" and value >= 0
        and value == value and value < math.huge
end

local function strict_array(value, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, name .. " must be an array"
    end
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            return nil, name .. " must be an array"
        end
        count = count + 1
    end
    if count ~= #value then
        return nil, name .. " must be a dense array"
    end
    return true
end

local function sorted_unique(values)
    local result, seen = {}, {}
    for _, value in ipairs(values or {}) do
        if non_empty(value) and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function same(left, right)
    return json.encode(left) == json.encode(right)
end

local function diagnostic(code, detail, refs)
    return {
        protocol_version = "repository.candidate_seal_diagnostic.v0",
        code = code,
        detail = detail,
        source_refs = sorted_unique(refs),
        event_truth_status = "runtime_confirmed",
    }
end

local function trace_event(instance, id)
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.id == id then
            return event
        end
    end
    return nil
end

local function normalize_bounds(value)
    value = value or default_inventory_bounds
    local ok, err = exact_keys(value, bounds_keys, bounds_keys,
        "candidate inventory bounds")
    if not ok then
        return nil, err
    end
    if value.protocol_version ~= "repository.inventory_bounds.v0" then
        return nil, "unsupported candidate inventory bounds"
    end
    for _, key in ipairs({
        "max_entries", "max_depth", "max_path_bytes", "max_component_bytes",
        "max_file_bytes", "max_total_bytes",
    }) do
        if not positive_integer(value[key]) then
            return nil, "candidate inventory bound is invalid: " .. key
        end
    end
    if value.max_entries > 4096 or value.max_depth > 64
        or value.max_path_bytes > 1024 or value.max_component_bytes > 255
        or value.max_file_bytes > 1048576 or value.max_total_bytes > 67108864 then
        return nil, "candidate inventory bounds exceed trusted ceiling"
    end
    return copy_value(value)
end

local function expected_directories(files)
    local result = {}
    for _, file in ipairs(files) do
        local prefix = ""
        local parts = {}
        for component in file.relative_path:gmatch("[^/]+") do
            parts[#parts + 1] = component
        end
        for index = 1, #parts - 1 do
            prefix = prefix == "" and parts[index] or (prefix .. "/" .. parts[index])
            result[#result + 1] = prefix
        end
    end
    return sorted_unique(result)
end

local function derive_body_evidence(instance, bounds)
    local declaration, declaration_err = artifact_set.derive(instance)
    if not declaration then
        return nil, declaration_err
    end
    local inspection, inspection_err = artifact_set.inspect(instance, declaration)
    if not inspection then
        return nil, inspection_err
    end
    if inspection.state ~= "complete" or inspection.remaining_count ~= 0
        or inspection.done_count ~= inspection.needed_count then
        return nil, diagnostic("artifact_set_incomplete", nil, inspection.source_refs)
    end
    if inspection.inventory_compatible ~= true
        or #(inspection.undeclared_artifacts or {}) ~= 0 then
        return nil, diagnostic("artifact_set_not_inventory_compatible", nil,
            inspection.conflicting_refs)
    end

    local files = {}
    local expected_total_bytes = 0
    for _, artifact in ipairs(inspection.artifacts) do
        if artifact.state ~= "complete" or not non_empty(artifact.completion_ref)
            or not non_empty(artifact.verification_ref) then
            return nil, diagnostic("artifact_completion_missing", artifact.work_unit_id)
        end
        local completion = trace_event(instance, artifact.completion_ref)
        local verification = trace_event(instance, artifact.verification_ref)
        local verification_payload = verification and verification.payload or nil
        if not completion or completion.type ~= "work_completion"
            or completion.truth_status ~= "runtime_confirmed"
            or not verification or verification.type ~= "repository_verification"
            or verification.truth_status ~= "runtime_confirmed"
            or type(verification_payload) ~= "table"
            or verification_payload.verdict ~= "accepted"
            or type(verification_payload.target) ~= "table"
            or verification_payload.target.relative_path ~= artifact.relative_path
            or verification_payload.target.kind ~= "regular_file"
            or type(verification_payload.expected) ~= "table"
            or type(verification_payload.observed) ~= "table"
            or verification_payload.observed.bytes ~= verification_payload.expected.bytes
            or verification_payload.observed.sha256
                ~= verification_payload.expected.sha256
            or not non_negative_integer(verification_payload.expected.bytes)
            or type(verification_payload.expected.sha256) ~= "string"
            or #verification_payload.expected.sha256 ~= 64 then
            return nil, "candidate seal completion evidence is not accepted exact evidence"
        end
        if verification_payload.expected.bytes > bounds.max_file_bytes then
            return nil, diagnostic("candidate_file_exceeds_inventory_bound",
                artifact.relative_path, {verification.id})
        end
        files[#files + 1] = {
            relative_path = artifact.relative_path,
            expected_kind = "regular_file",
            work_unit_id = artifact.work_unit_id,
            work_unit_version = artifact.work_unit_version,
            expected_bytes = verification_payload.expected.bytes,
            expected_sha256 = verification_payload.expected.sha256,
            completion_ref = completion.id,
            verification_ref = verification.id,
        }
        expected_total_bytes = expected_total_bytes
            + verification_payload.expected.bytes
    end
    table.sort(files, function(left, right)
        if left.relative_path ~= right.relative_path then
            return left.relative_path < right.relative_path
        end
        return left.work_unit_id < right.work_unit_id
    end)
    local directories = expected_directories(files)
    if #files + #directories > bounds.max_entries then
        return nil, diagnostic("candidate_tree_exceeds_entry_bound")
    end
    if expected_total_bytes > bounds.max_total_bytes then
        return nil, diagnostic("candidate_tree_exceeds_total_byte_bound")
    end
    return {
        declaration = declaration,
        inspection = inspection,
        expected_files = files,
        expected_directories = directories,
    }
end

local function normalize_expected_files(value)
    local array_ok, array_err = strict_array(value, "candidate expected_files")
    if not array_ok then
        return nil, array_err
    end
    local result, seen_paths, seen_units = {}, {}, {}
    for index, file in ipairs(value) do
        local file_ok, file_err = exact_keys(file, expected_file_keys,
            expected_file_keys, "candidate expected file")
        if not file_ok then
            return nil, file_err
        end
        local path, path_err = repository_intent.validate_relative_path(
            file.relative_path)
        if not path then
            return nil, path_err
        end
        if file.expected_kind ~= "regular_file"
            or not non_empty(file.work_unit_id)
            or not positive_integer(file.work_unit_version)
            or not non_negative_integer(file.expected_bytes)
            or type(file.expected_sha256) ~= "string"
            or #file.expected_sha256 ~= 64
            or not non_empty(file.completion_ref)
            or not non_empty(file.verification_ref) then
            return nil, "candidate expected file is invalid"
        end
        if seen_paths[path] or seen_units[file.work_unit_id] then
            return nil, "candidate expected files contain duplicate identity"
        end
        seen_paths[path], seen_units[file.work_unit_id] = true, true
        result[index] = copy_value(file)
        result[index].relative_path = path
    end
    table.sort(result, function(left, right)
        if left.relative_path ~= right.relative_path then
            return left.relative_path < right.relative_path
        end
        return left.work_unit_id < right.work_unit_id
    end)
    return result
end

local function normalize_string_array(value, name)
    local array_ok, array_err = strict_array(value, name)
    if not array_ok then
        return nil, array_err
    end
    local result, seen = {}, {}
    for _, item in ipairs(value) do
        if not non_empty(item) or seen[item] then
            return nil, name .. " contains invalid or duplicate identity"
        end
        seen[item] = true
        result[#result + 1] = item
    end
    table.sort(result)
    return result
end

local function normalize_request(value, require_identity)
    local request_ok, request_err = exact_keys(value, request_keys,
        request_required_without_id,
        "candidate seal request")
    if not request_ok then
        return nil, request_err
    end
    if value.protocol_version ~= candidate_seal.request_protocol
        or value.context ~= "software_task.v0"
        or value.event_truth_status ~= "runtime_confirmed"
        or (value.content_truth_status ~= "semantic_proposal"
            and value.content_truth_status ~= "mixed") then
        return nil, "candidate seal request protocol is invalid"
    end
    for _, key in ipairs({
        "packet_id", "lineage_id", "process_contract_id", "stage_id",
        "repository_id", "root_authority_id", "lifecycle_id",
        "root_fingerprint", "grant_id", "artifact_set_id",
        "artifact_set_inspection_id",
    }) do
        if not non_empty(value[key]) then
            return nil, "candidate seal request field is invalid: " .. key
        end
    end
    if not positive_integer(value.generation)
        or not positive_integer(value.lifecycle_revision)
        or not positive_integer(value.grant_revision) then
        return nil, "candidate seal request revisions are invalid"
    end
    local files, files_err = normalize_expected_files(value.expected_files)
    if not files then
        return nil, files_err
    end
    local directories, directories_err = normalize_string_array(
        value.expected_directories, "candidate expected_directories")
    if not directories then
        return nil, directories_err
    end
    local refs, refs_err = normalize_string_array(value.source_refs,
        "candidate seal source_refs")
    if not refs then
        return nil, refs_err
    end
    local bounds, bounds_err = normalize_bounds(value.inventory_bounds)
    if not bounds then
        return nil, bounds_err
    end
    local normalized = copy_value(value)
    normalized.request_id = nil
    normalized.expected_files = files
    normalized.expected_directories = directories
    normalized.inventory_bounds = bounds
    normalized.source_refs = refs
    local request_digest, digest_err = digest.record(normalized)
    if not request_digest then
        return nil, digest_err
    end
    normalized.request_id = "candidate-seal-request:" .. request_digest
    if require_identity and (not non_empty(value.request_id)
        or value.request_id ~= normalized.request_id) then
        return nil, "candidate seal request identity mismatch"
    end
    return normalized
end

local function registry_from_services(services)
    local registry = type(services) == "table"
        and services.repository_capabilities or nil
    if type(registry) ~= "table" then
        return nil, "candidate seal requires repository capability registry"
    end
    return registry
end

function candidate_seal.prepare(instance, services, options)
    options = options or {}
    local options_ok, options_err = exact_keys(options, {inventory_bounds = true},
        {}, "candidate seal options")
    if not options_ok then
        return nil, options_err
    end
    local bounds, bounds_err = normalize_bounds(options.inventory_bounds)
    if not bounds then
        return nil, bounds_err
    end
    local evidence, evidence_err = derive_body_evidence(instance, bounds)
    if not evidence then
        return nil, evidence_err
    end
    local registry, registry_err = registry_from_services(services)
    if not registry then
        return nil, registry_err
    end
    local grant, grant_err = capabilities.resolve(registry, {
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        repository_id = instance.repository_id,
        operation = "create_text_file",
    })
    if not grant then
        return nil, grant_err
    end
    local lifecycle, lifecycle_err = capabilities.candidate_lifecycle(registry, {
        grant_id = grant.grant_id,
    })
    if not lifecycle then
        return nil, lifecycle_err
    end
    if lifecycle.state ~= "materializing"
        or lifecycle.generation ~= instance.generation
        or lifecycle.lineage_id ~= instance.lineage_id
        or lifecycle.repository_id ~= instance.repository_id
        or lifecycle.active_grant_count ~= 1
        or lifecycle.active_dispatch_count ~= 0 then
        return nil, diagnostic("candidate_lifecycle_not_ready", lifecycle.state)
    end
    local source_refs = copy_value(evidence.inspection.source_refs)
    source_refs[#source_refs + 1] = evidence.declaration.artifact_set_id
    source_refs[#source_refs + 1] = evidence.inspection.inspection_id
    local request, request_err = normalize_request({
        protocol_version = candidate_seal.request_protocol,
        request_id = nil,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        process_contract_id = evidence.declaration.process_contract_id,
        context = evidence.declaration.context,
        stage_id = evidence.declaration.stage_id,
        repository_id = evidence.declaration.repository_id,
        root_authority_id = lifecycle.root_authority_id,
        lifecycle_id = lifecycle.lifecycle_id,
        lifecycle_revision = lifecycle.revision,
        root_fingerprint = lifecycle.root_fingerprint,
        grant_id = grant.grant_id,
        grant_revision = grant.revision,
        artifact_set_id = evidence.declaration.artifact_set_id,
        artifact_set_inspection_id = evidence.inspection.inspection_id,
        expected_files = evidence.expected_files,
        expected_directories = evidence.expected_directories,
        inventory_bounds = bounds,
        source_refs = sorted_unique(source_refs),
        event_truth_status = "runtime_confirmed",
        content_truth_status = evidence.inspection.content_truth_status,
    }, false)
    if not request then
        return nil, request_err
    end
    return copy_value(request)
end

function candidate_seal.validate_request(instance, value)
    local normalized, normalized_err = normalize_request(value, true)
    if not normalized then
        return nil, normalized_err
    end
    if type(instance) ~= "table" or instance.status == "dead"
        or instance.status == "manifested" then
        return nil, "candidate seal request requires living Packet"
    end
    local evidence, evidence_err = derive_body_evidence(
        instance, normalized.inventory_bounds)
    if not evidence then
        return nil, evidence_err
    end
    local expected_source_refs = copy_value(evidence.inspection.source_refs)
    expected_source_refs[#expected_source_refs + 1] =
        evidence.declaration.artifact_set_id
    expected_source_refs[#expected_source_refs + 1] =
        evidence.inspection.inspection_id
    expected_source_refs = sorted_unique(expected_source_refs)
    if normalized.packet_id ~= instance.id
        or normalized.lineage_id ~= instance.lineage_id
        or normalized.generation ~= instance.generation
        or normalized.process_contract_id ~= instance.process_contract_id
        or normalized.context ~= instance.work_context
        or normalized.stage_id ~= instance.stage_id
        or normalized.repository_id ~= instance.repository_id
        or normalized.artifact_set_id ~= evidence.declaration.artifact_set_id
        or normalized.artifact_set_inspection_id ~= evidence.inspection.inspection_id
        or not same(normalized.expected_files, evidence.expected_files)
        or not same(normalized.expected_directories, evidence.expected_directories)
        or not same(normalized.source_refs, expected_source_refs)
        or normalized.content_truth_status
            ~= evidence.inspection.content_truth_status then
        return nil, "candidate seal request is stale or foreign to Packet body"
    end
    return true
end

local function validate_identity(value, name)
    local ok, err = exact_keys(value, identity_keys, identity_keys, name)
    if not ok then
        return nil, err
    end
    if not non_negative_integer(value.device)
        or not non_negative_integer(value.inode) then
        return nil, name .. " is invalid"
    end
    return true
end

local function identity_ref(value)
    local value_digest, value_err = digest.record(value)
    if not value_digest then
        return nil, value_err
    end
    return "filesystem-identity:" .. value_digest
end

local function path_depth_and_component(path)
    local depth, component_max = 0, 0
    for component in path:gmatch("[^/]+") do
        depth = depth + 1
        component_max = math.max(component_max, #component)
    end
    return depth, component_max
end

local function normalize_provider_inventory(registry, lease, request, raw)
    local raw_ok, raw_err = exact_keys(raw, provider_inventory_keys,
        provider_inventory_keys, "repository provider inventory")
    if not raw_ok then
        return nil, raw_err, "malformed"
    end
    if raw.protocol_version ~= "repository.provider_inventory_result.v0"
        or raw.operation ~= "inventory_tree"
        or (raw.outcome ~= "observed" and raw.outcome ~= "bound_exceeded")
        or type(raw.stable) ~= "boolean"
        or raw.mutation_primitive_entered ~= false
        or raw.published ~= false then
        return nil, "repository provider inventory envelope is contradictory",
            "malformed"
    end
    local before_ok, before_err = validate_identity(raw.root_before,
        "inventory root_before")
    if not before_ok then
        return nil, before_err, "malformed"
    end
    local after_ok, after_err = validate_identity(raw.root_after,
        "inventory root_after")
    if not after_ok then
        return nil, after_err, "malformed"
    end
    local root_match, root_match_err = capabilities.candidate_inventory_root_matches(
        registry, lease, raw.root_before, raw.root_after)
    if root_match == nil then
        return nil, root_match_err, "malformed"
    end
    if root_match ~= true then
        return nil, "repository provider inventory contradicts trusted root",
            "identity"
    end
    local cost_ok, cost_err = exact_keys(raw.cost, cost_keys, cost_keys,
        "repository inventory cost")
    if not cost_ok then
        return nil, cost_err, "malformed"
    end
    if raw.cost.tool_calls ~= 1 or raw.cost.file_writes ~= 0
        or not non_negative_number(raw.cost.time_ms) then
        return nil, "repository inventory economics are impossible", "malformed"
    end
    local observed_ok, observed_err = exact_keys(raw.bounds_observed,
        observed_bounds_keys, observed_bounds_keys, "repository observed bounds")
    if not observed_ok then
        return nil, observed_err, "malformed"
    end
    for key in pairs(bounds_keys) do
        if key ~= "protocol_version"
            and raw.bounds_observed[key] ~= request.inventory_bounds[key] then
            return nil, "repository provider changed inventory bound: " .. key,
                "malformed"
        end
    end
    if not non_negative_integer(raw.bounds_observed.observed_entries)
        or not non_negative_integer(raw.bounds_observed.observed_total_bytes) then
        return nil, "repository observed bounds contain invalid counts", "malformed"
    end
    local array_ok, array_err = strict_array(raw.entries,
        "repository provider inventory entries")
    if not array_ok then
        return nil, array_err, "malformed"
    end

    local entries, seen = {}, {}
    local total_bytes = 0
    local previous_path
    local stable = raw.stable and same(raw.root_before, raw.root_after)
    for index, entry in ipairs(raw.entries) do
        local entry_ok, entry_err = exact_keys(entry, provider_entry_keys,
            provider_entry_required, "repository provider inventory entry")
        if not entry_ok then
            return nil, entry_err, "malformed"
        end
        local path, path_err = repository_intent.validate_relative_path(
            entry.relative_path)
        if not path then
            return nil, path_err, "malformed"
        end
        if seen[path] or (previous_path and path <= previous_path) then
            return nil, "repository provider inventory order is not canonical",
                "malformed"
        end
        seen[path], previous_path = true, path
        if entry.kind ~= "directory" and entry.kind ~= "regular_file"
            and entry.kind ~= "symlink" and entry.kind ~= "special" then
            return nil, "repository provider inventory kind is invalid", "malformed"
        end
        local first_ok, first_err = validate_identity(entry.identity_before,
            "inventory entry identity_before")
        if not first_ok then
            return nil, first_err, "malformed"
        end
        local last_ok, last_err = validate_identity(entry.identity_after,
            "inventory entry identity_after")
        if not last_ok then
            return nil, last_err, "malformed"
        end
        stable = stable and same(entry.identity_before, entry.identity_after)
        local depth, component_max = path_depth_and_component(path)
        if index > request.inventory_bounds.max_entries
            or depth > request.inventory_bounds.max_depth
            or #path > request.inventory_bounds.max_path_bytes
            or component_max > request.inventory_bounds.max_component_bytes then
            return nil, "repository provider exceeded path inventory bounds",
                "malformed"
        end
        local bytes, sha256
        if entry.kind == "regular_file" then
            if not non_negative_integer(entry.bytes)
                or type(entry.content) ~= "string"
                or #entry.content ~= entry.bytes
                or entry.bytes > request.inventory_bounds.max_file_bytes then
                return nil, "repository provider returned invalid bounded file",
                    "malformed"
            end
            total_bytes = total_bytes + entry.bytes
            if total_bytes > request.inventory_bounds.max_total_bytes then
                return nil, "repository provider exceeded aggregate byte bound",
                    "malformed"
            end
            sha256 = digest.sha256(entry.content)
            if not sha256 then
                return nil, "repository file digest failed", "malformed"
            end
            bytes = entry.bytes
        elseif entry.bytes ~= nil or entry.content ~= nil then
            return nil, "repository non-file entry exposed content", "malformed"
        end
        local stable_ref, stable_ref_err = identity_ref({
            before = entry.identity_before,
            after = entry.identity_after,
        })
        if not stable_ref then
            return nil, stable_ref_err, "malformed"
        end
        entries[#entries + 1] = {
            relative_path = path,
            kind = entry.kind,
            bytes = bytes,
            sha256 = sha256,
            stable_identity_ref = stable_ref,
        }
    end
    if raw.bounds_observed.observed_entries ~= #entries
        or raw.bounds_observed.observed_total_bytes ~= total_bytes then
        return nil, "repository provider observed bounds disagree with entries",
            "malformed"
    end
    local before_ref = assert(identity_ref(raw.root_before))
    local after_ref = assert(identity_ref(raw.root_after))
    if not stable then
        return {
            status = "unstable",
            root_before_ref = before_ref,
            root_after_ref = after_ref,
        }
    end
    if raw.outcome == "bound_exceeded" then
        return {
            status = "bound_exceeded",
            root_before_ref = before_ref,
            root_after_ref = after_ref,
        }
    end

    local inventory_seed = {
        request_id = request.request_id,
        root_fingerprint = request.root_fingerprint,
        entries = entries,
        observed_entry_count = #entries,
        observed_total_bytes = total_bytes,
    }
    local inventory_digest, inventory_digest_err = digest.record(inventory_seed)
    if not inventory_digest then
        return nil, inventory_digest_err, "malformed"
    end
    local inventory = {
        protocol_version = candidate_seal.inventory_protocol,
        inventory_id = nil,
        request_id = request.request_id,
        root_fingerprint = request.root_fingerprint,
        root_continuity = "proven",
        entries = entries,
        observed_entry_count = #entries,
        observed_total_bytes = total_bytes,
        inventory_digest = inventory_digest,
        source_refs = sorted_unique({request.request_id, before_ref, after_ref}),
        event_truth_status = "runtime_confirmed",
    }
    local inventory_id, inventory_id_err = digest.record(inventory)
    if not inventory_id then
        return nil, inventory_id_err, "malformed"
    end
    inventory.inventory_id = "repository-seal-inventory:" .. inventory_id
    return {
        status = "observed",
        inventory = inventory,
        root_before_ref = before_ref,
        root_after_ref = after_ref,
    }
end

local function compare_inventory(request, inventory)
    local expected = {}
    for _, file in ipairs(request.expected_files) do
        expected[file.relative_path] = {
            kind = "regular_file",
            bytes = file.expected_bytes,
            sha256 = file.expected_sha256,
        }
    end
    for _, path in ipairs(request.expected_directories) do
        expected[path] = {kind = "directory"}
    end
    local observed = {}
    for _, entry in ipairs(inventory.entries) do
        observed[entry.relative_path] = entry
    end
    local mismatches = {}
    for path, wanted in pairs(expected) do
        local got = observed[path]
        if not got then
            mismatches[#mismatches + 1] = "missing:" .. path
        elseif got.kind ~= wanted.kind then
            mismatches[#mismatches + 1] = "kind:" .. path
        elseif wanted.kind == "regular_file"
            and (got.bytes ~= wanted.bytes or got.sha256 ~= wanted.sha256) then
            mismatches[#mismatches + 1] = "content:" .. path
        end
    end
    for path in pairs(observed) do
        if not expected[path] then
            mismatches[#mismatches + 1] = "extra:" .. path
        end
    end
    table.sort(mismatches)
    return #mismatches == 0, mismatches
end

local function abort_proof(request, transaction_id, observation, postcondition)
    return {
        protocol_version = "repository.candidate_seal_abort_proof.v0",
        request_id = request.request_id,
        transaction_id = transaction_id,
        provider = {
            root_continuity = "proven",
            observation_postcondition = postcondition,
            root_before_ref = observation.root_before_ref,
            root_after_ref = observation.root_after_ref,
        },
        source_refs = sorted_unique({
            request.request_id,
            observation.root_before_ref,
            observation.root_after_ref,
        }),
        event_truth_status = "runtime_confirmed",
    }
end

local function provider_error(value)
    local ok, err = exact_keys(value, provider_error_keys,
        provider_error_required, "candidate inventory provider error")
    if not ok then
        return nil, err
    end
    local cost_ok, cost_err = exact_keys(value.cost, cost_keys, cost_keys,
        "candidate inventory provider error cost")
    if not cost_ok then
        return nil, cost_err
    end
    if value.protocol_version ~= "repository.provider_error.v0"
        or (value.class ~= "world" and value.class ~= "ambiguous")
        or not non_empty(value.code) or not non_empty(value.stage)
        or value.mutation_primitive_entered ~= false
        or value.published ~= false
        or value.cost.file_writes ~= 0
        or not non_negative_integer(value.cost.tool_calls)
        or not non_negative_number(value.cost.time_ms)
        or value.residue ~= nil then
        return nil, "candidate inventory provider error is malformed"
    end
    return substrate_contract.effect_failure({
        source = "sandbox",
        code = value.code,
        message = value.stage .. "/" .. value.code,
        retryability = "terminal",
        cost = copy_value(value.cost),
        detail = copy_value(value),
    })
end

local function quarantine(registry, lease, reason)
    return capabilities.quarantine_candidate_seal(registry, lease, {
        code = reason.code,
        phase = reason.phase,
        detail = reason.detail,
    })
end

local function seal_from(request, inventory, closure)
    local artifacts = {}
    for index, file in ipairs(request.expected_files) do
        artifacts[index] = {
            relative_path = file.relative_path,
            work_unit_id = file.work_unit_id,
            work_unit_version = file.work_unit_version,
            bytes = file.expected_bytes,
            sha256 = file.expected_sha256,
            completion_ref = file.completion_ref,
            verification_ref = file.verification_ref,
        }
    end
    local value = {
        protocol_version = candidate_seal.seal_protocol,
        candidate_seal_id = nil,
        packet_id = request.packet_id,
        lineage_id = request.lineage_id,
        generation = request.generation,
        process_contract_id = request.process_contract_id,
        context = request.context,
        stage_id = request.stage_id,
        repository_id = request.repository_id,
        root_authority_id = request.root_authority_id,
        lifecycle_id = request.lifecycle_id,
        root_fingerprint = request.root_fingerprint,
        artifact_set_id = request.artifact_set_id,
        request_id = request.request_id,
        inventory_id = inventory.inventory_id,
        inventory_digest = inventory.inventory_digest,
        authority_closure_ref = closure.closure_id,
        artifacts = artifacts,
        source_refs = sorted_unique({
            request.request_id,
            request.artifact_set_id,
            request.artifact_set_inspection_id,
            inventory.inventory_id,
            closure.closure_id,
        }),
        event_truth_status = "runtime_confirmed",
        content_truth_status = "mixed",
    }
    local identity, identity_err = digest.record(value)
    if not identity then
        return nil, identity_err
    end
    value.candidate_seal_id = "candidate-seal:" .. identity
    return value
end

local function normalize_seal(value, require_identity)
    local seal_ok, seal_err = exact_keys(value, seal_keys,
        seal_required_without_id,
        "candidate seal")
    if not seal_ok then
        return nil, seal_err
    end
    if value.protocol_version ~= candidate_seal.seal_protocol
        or value.context ~= "software_task.v0"
        or value.event_truth_status ~= "runtime_confirmed"
        or value.content_truth_status ~= "mixed"
        or not positive_integer(value.generation) then
        return nil, "candidate seal envelope is invalid"
    end
    for _, key in ipairs({
        "packet_id", "lineage_id", "process_contract_id", "stage_id",
        "repository_id", "root_authority_id", "lifecycle_id",
        "root_fingerprint", "artifact_set_id", "request_id", "inventory_id",
        "inventory_digest", "authority_closure_ref",
    }) do
        if not non_empty(value[key]) then
            return nil, "candidate seal field is invalid: " .. key
        end
    end
    local array_ok, array_err = strict_array(value.artifacts,
        "candidate seal artifacts")
    if not array_ok then
        return nil, array_err
    end
    local artifacts = {}
    for index, artifact in ipairs(value.artifacts) do
        local item_ok, item_err = exact_keys(artifact, seal_artifact_keys,
            seal_artifact_keys, "candidate seal artifact")
        if not item_ok then
            return nil, item_err
        end
        local path = repository_intent.validate_relative_path(artifact.relative_path)
        if not path or not non_empty(artifact.work_unit_id)
            or not positive_integer(artifact.work_unit_version)
            or not non_negative_integer(artifact.bytes)
            or type(artifact.sha256) ~= "string" or #artifact.sha256 ~= 64
            or not non_empty(artifact.completion_ref)
            or not non_empty(artifact.verification_ref) then
            return nil, "candidate seal artifact is invalid"
        end
        artifacts[index] = copy_value(artifact)
    end
    table.sort(artifacts, function(left, right)
        return left.relative_path < right.relative_path
    end)
    local refs, refs_err = normalize_string_array(value.source_refs,
        "candidate seal source_refs")
    if not refs then
        return nil, refs_err
    end
    local normalized = copy_value(value)
    normalized.candidate_seal_id = nil
    normalized.artifacts = artifacts
    normalized.source_refs = refs
    local seal_digest, digest_err = digest.record(normalized)
    if not seal_digest then
        return nil, digest_err
    end
    normalized.candidate_seal_id = "candidate-seal:" .. seal_digest
    if require_identity and (not non_empty(value.candidate_seal_id)
        or value.candidate_seal_id ~= normalized.candidate_seal_id) then
        return nil, "candidate seal identity mismatch"
    end
    return normalized
end

function candidate_seal.validate_seal(instance, value)
    local normalized, normalized_err = normalize_seal(value, true)
    if not normalized then
        return nil, normalized_err
    end
    if type(instance) ~= "table"
        or normalized.packet_id ~= instance.id
        or normalized.lineage_id ~= instance.lineage_id
        or normalized.generation ~= instance.generation
        or normalized.process_contract_id ~= instance.process_contract_id
        or normalized.context ~= instance.work_context
        or normalized.stage_id ~= instance.stage_id
        or normalized.repository_id ~= instance.repository_id then
        return nil, "candidate seal is foreign to Packet"
    end
    local evidence, evidence_err = derive_body_evidence(
        instance, validation_inventory_ceiling)
    if not evidence then
        return nil, evidence_err
    end
    local expected = {}
    for index, file in ipairs(evidence.expected_files) do
        expected[index] = {
            relative_path = file.relative_path,
            work_unit_id = file.work_unit_id,
            work_unit_version = file.work_unit_version,
            bytes = file.expected_bytes,
            sha256 = file.expected_sha256,
            completion_ref = file.completion_ref,
            verification_ref = file.verification_ref,
        }
    end
    local expected_source_refs = sorted_unique({
        normalized.request_id,
        normalized.artifact_set_id,
        evidence.inspection.inspection_id,
        normalized.inventory_id,
        normalized.authority_closure_ref,
    })
    if normalized.artifact_set_id ~= evidence.declaration.artifact_set_id
        or not same(normalized.artifacts, expected)
        or not same(normalized.source_refs, expected_source_refs) then
        return nil, "candidate seal no longer matches body evidence"
    end
    return true
end

function candidate_seal.find(instance, candidate_seal_id)
    if not non_empty(candidate_seal_id) then
        return nil, nil, "candidate_seal_id_required"
    end
    local found, found_event
    for _, event in ipairs(instance and instance.trace or {}) do
        local payload = event and event.payload or nil
        if event.type == "candidate_seal" and type(payload) == "table"
            and payload.candidate_seal_id == candidate_seal_id then
            local valid, valid_err = candidate_seal.validate_seal(instance, payload)
            if not valid then
                return nil, nil, valid_err
            end
            if found then
                return nil, nil, "candidate_seal_ambiguous"
            end
            found, found_event = copy_value(payload), copy_value(event)
        end
    end
    if not found then
        return nil, nil, "candidate_seal_absent"
    end
    return found, found_event
end

function candidate_seal.current(instance)
    local found, found_event
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.type == "candidate_seal" then
            local valid, valid_err = candidate_seal.validate_seal(instance, event.payload)
            if not valid then
                return nil, nil, valid_err
            end
            if found and found.candidate_seal_id ~= event.payload.candidate_seal_id then
                return nil, nil, "candidate_seal_contradiction"
            end
            found, found_event = copy_value(event.payload), copy_value(event)
        end
    end
    if not found then
        return nil, nil, "candidate_seal_absent"
    end
    return found, found_event
end

function candidate_seal.execute(instance, request, services)
    local actor, actor_err = packet_core.assert_actor_tick(instance, "☶",
        "execute candidate seal")
    if not actor then
        return nil, actor_err, false
    end
    local normalized, normalize_err = normalize_request(request, true)
    if not normalized then
        return nil, normalize_err, false
    end
    local registry, registry_err = registry_from_services(services)
    if not registry then
        return nil, registry_err, false
    end

    local existing, existing_event, existing_err = candidate_seal.current(instance)
    local closure, closure_err = capabilities.observe_candidate_closure(registry, {
        root_authority_id = normalized.root_authority_id,
        lifecycle_id = normalized.lifecycle_id,
        request_id = normalized.request_id,
    })
    if not closure and closure_err ~= nil and type(closure_err) ~= "table" then
        return nil, closure_err, true
    end
    if closure then
        if not existing or existing.request_id ~= normalized.request_id
            or existing.authority_closure_ref ~= closure.closure_id then
            return nil, "private candidate closure has no matching body event", true
        end
        return {
            protocol_version = candidate_seal.result_protocol,
            status = "sealed",
            idempotent = true,
            seal = existing,
            seal_event_ref = existing_event.id,
            closure = closure,
            inventory = nil,
            event_truth_status = "runtime_confirmed",
        }
    end
    if existing then
        return nil, "candidate seal body event has no private closure", true
    end
    if existing_err ~= "candidate_seal_absent" then
        return nil, existing_err, true
    end

    local request_ok, request_err = candidate_seal.validate_request(instance, normalized)
    if not request_ok then
        return nil, request_err, false
    end

    local lease, lease_err = capabilities.begin_candidate_seal(registry, normalized)
    if not lease then
        return nil, lease_err, false
    end
    local transaction_digest, transaction_err = digest.record({
        root_authority_id = normalized.root_authority_id,
        lifecycle_id = normalized.lifecycle_id,
        request_id = normalized.request_id,
        revision_before = normalized.lifecycle_revision,
    })
    if not transaction_digest then
        quarantine(registry, lease, {
            code = "candidate_transaction_identity_failed",
            phase = "before_inventory",
            detail = transaction_err,
        })
        return nil, transaction_err, true
    end
    local transaction_id = "candidate-seal-transaction:" .. transaction_digest
    local inventory_request = {
        protocol_version = "repository.candidate_inventory_request.v0",
        request_id = normalized.request_id,
        transaction_id = transaction_id,
        inventory_bounds = copy_value(normalized.inventory_bounds),
    }

    local called = table.pack(pcall(
        capabilities.inventory_candidate,
        registry,
        lease,
        inventory_request
    ))
    if called[1] ~= true then
        return nil, tostring(called[2]), true
    end
    local raw, inventory_err = called[2], called[3]
    if not raw then
        local typed, typed_err = provider_error(inventory_err)
        if not typed then
            quarantine(registry, lease, {
                code = "malformed_candidate_inventory_error",
                phase = "inventory_tree",
                detail = typed_err,
            })
            return nil, typed_err, true
        end
        local quarantined, quarantine_err = quarantine(registry, lease, {
            code = "candidate_inventory_ambiguous",
            phase = "inventory_tree",
            detail = typed.code,
        })
        if not quarantined then
            return nil, quarantine_err, true
        end
        return nil, typed, false
    end

    local observation, observation_err, observation_class =
        normalize_provider_inventory(registry, lease, normalized, raw)
    if not observation then
        quarantine(registry, lease, {
            code = observation_class == "identity"
                and "candidate_inventory_root_contradiction"
                or "malformed_candidate_inventory_result",
            phase = "inventory_tree",
            detail = observation_err,
        })
        return nil, observation_err, true
    end
    if observation.status == "unstable" then
        local quarantined, quarantine_err = quarantine(registry, lease, {
            code = "candidate_inventory_unstable",
            phase = "inventory_tree",
        })
        if not quarantined then
            return nil, quarantine_err, true
        end
        return nil, substrate_contract.effect_failure({
            source = "sandbox",
            code = "candidate_inventory_unstable",
            message = "inventory_tree/candidate_inventory_unstable",
            retryability = "terminal",
            cost = copy_value(raw.cost),
        }), false
    end

    if observation.status == "bound_exceeded" then
        local proof = abort_proof(normalized, transaction_id,
            observation, "bounded_no_closure")
        local aborted, abort_err = capabilities.abort_candidate_seal(
            registry, lease, proof)
        if not aborted then
            quarantine(registry, lease, {
                code = "candidate_seal_abort_failed",
                phase = "bound_exceeded",
                detail = abort_err,
            })
            return nil, abort_err, true
        end
        return nil, diagnostic("candidate_inventory_bound_exceeded"), false
    end

    local exact, mismatches = compare_inventory(normalized, observation.inventory)
    if not exact then
        local proof = abort_proof(normalized, transaction_id,
            observation, "stable_mismatch")
        local aborted, abort_err = capabilities.abort_candidate_seal(
            registry, lease, proof)
        if not aborted then
            quarantine(registry, lease, {
                code = "candidate_seal_abort_failed",
                phase = "stable_mismatch",
                detail = abort_err,
            })
            return nil, abort_err, true
        end
        return nil, diagnostic("candidate_inventory_mismatch",
            table.concat(mismatches, ","), observation.inventory.source_refs), false
    end

    local commit = {
        protocol_version = "repository.candidate_seal_commit.v0",
        request_id = normalized.request_id,
        transaction_id = transaction_id,
        inventory_id = observation.inventory.inventory_id,
        inventory_digest = observation.inventory.inventory_digest,
        root_fingerprint = normalized.root_fingerprint,
        comparison = "exact",
        source_refs = sorted_unique({
            normalized.request_id,
            observation.inventory.inventory_id,
        }),
    }
    local committed, commit_err = capabilities.commit_candidate_seal(
        registry, lease, commit)
    if not committed then
        quarantine(registry, lease, {
            code = "candidate_seal_commit_failed",
            phase = "commit",
            detail = commit_err,
        })
        return nil, commit_err, true
    end
    local observed_closure, closure_err = capabilities.observe_candidate_closure(
        registry,
        {
            root_authority_id = normalized.root_authority_id,
            lifecycle_id = normalized.lifecycle_id,
            request_id = normalized.request_id,
        }
    )
    if not observed_closure or not same(observed_closure, committed) then
        return nil, closure_err or "candidate closure projection contradiction", true
    end
    local seal, seal_err = seal_from(normalized, observation.inventory, committed)
    if not seal then
        return nil, seal_err, true
    end
    local seal_ok, seal_validation_err = candidate_seal.validate_seal(instance, seal)
    if not seal_ok then
        return nil, seal_validation_err, true
    end
    local body = require("runtime.body")
    local stored, event = body.record_candidate_seal(
        instance,
        seal,
        registry,
        committed
    )
    if not stored then
        return nil, event, true
    end
    return {
        protocol_version = candidate_seal.result_protocol,
        status = "sealed",
        idempotent = false,
        seal = stored,
        seal_event_ref = event.id,
        closure = committed,
        inventory = copy_value(observation.inventory),
        event_truth_status = "runtime_confirmed",
    }
end

return candidate_seal
