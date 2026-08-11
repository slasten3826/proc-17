local authority_epoch = require("runtime.authority_epoch")
local case_manifest = require("runtime.edge_case_manifest")
local digest = require("core.digest")
local edge_catalog = require("runtime.edge_catalog")
local edge_corpus = require("runtime.edge_corpus")
local edge_credit = require("runtime.edge_credit")
local json = require("core.json")

local report = {
    protocol_version = "current-authority-evidence.v0",
}

local gate_statuses = {
    green = true,
    missing = true,
    red = true,
}

local case_statuses = {
    green = true,
    missing = true,
    blocked = true,
    red = true,
}

local closure_statuses = {
    diagnostic = true,
    partial = true,
    blocked = true,
    complete = true,
}

local function copy_value(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function same_value(left, right)
    local left_ok, left_encoded = pcall(json.encode, left)
    local right_ok, right_encoded = pcall(json.encode, right)
    return left_ok and right_ok and left_encoded == right_encoded
end

local function exact_keys(value, required)
    if type(value) ~= "table" or getmetatable(value) ~= nil then return false end
    for key in pairs(value) do
        if not required[key] then return false end
    end
    for key in pairs(required) do
        if value[key] == nil then return false end
    end
    return true
end

local function non_empty(value)
    return type(value) == "string" and value ~= ""
end

local function non_negative_integer(value)
    return type(value) == "number" and value >= 0
        and value < math.huge and value % 1 == 0
end

local function tagged_hash(value)
    return type(value) == "string" and #value == 71
        and value:sub(1, 7) == "sha256:"
        and value:sub(8):match("^[0-9a-f]+$") ~= nil
end

local function strict_sorted_strings(values, allow_empty)
    if type(values) ~= "table" or (not allow_empty and #values == 0) then
        return false
    end
    local previous
    for index, value in ipairs(values) do
        if not non_empty(value) or (previous and value <= previous) then
            return false
        end
        previous = value
        if index % 1 ~= 0 then return false end
    end
    for key in pairs(values) do
        if type(key) ~= "number" or key < 1 or key > #values
            or key % 1 ~= 0 then
            return false
        end
    end
    return true
end

local function sorted_keys(values)
    local result = {}
    for key in pairs(values or {}) do result[#result + 1] = key end
    table.sort(result)
    return result
end

local function sorted_set(values)
    local seen = {}
    for _, value in ipairs(values or {}) do
        if non_empty(value) then seen[value] = true end
    end
    return sorted_keys(seen)
end

local function report_error(code, extra)
    local value = {
        class = "instrument_contract",
        code = code,
        stage = "edge_current_report",
    }
    for key, child in pairs(extra or {}) do value[key] = child end
    return value
end

local function tagged_digest(value)
    local hashed, hash_err = digest.record(value)
    if not hashed then
        return nil, report_error("current_report_digest_failed", {
            detail = tostring(hash_err),
        })
    end
    return "sha256:" .. hashed
end

local function direction_vocabulary()
    local result = {}
    for _, definition in ipairs(edge_catalog.list()) do
        for _, direction in ipairs(definition.directions) do
            result[direction] = true
        end
    end
    return result
end

local function instrument_error_count(bucket)
    local count = #(bucket.errors or {})
    if bucket.error_overflow then
        count = count + bucket.error_overflow.overflow_count
    end
    return count
end

local function unclassified_count(bucket)
    local count = 0
    for _, edge in pairs(bucket.edges or {}) do
        for _, directional in pairs(edge.directions or {}) do
            count = count
                + (directional.promotion.unclassified_executed_count or 0)
        end
    end
    return count
end

local function epoch_summary(record, epoch_id, revision)
    local closure, closure_err = edge_corpus.closure(record, {
        target_evidence_epoch_id = epoch_id,
        implementation_revision = revision,
    })
    if not closure then return nil, closure_err end
    if closure.ledger_gate ~= "green" then
        return nil, report_error("current_report_ledger_red", {
            evidence_epoch_id = epoch_id,
        })
    end
    if closure.provenance_gate ~= "green" then
        return nil, report_error("current_report_provenance_red", {
            evidence_epoch_id = epoch_id,
        })
    end

    local bucket = record.buckets[epoch_id]
    if not bucket or not bucket.authority_epoch then
        return nil, report_error("current_report_epoch_missing", {
            evidence_epoch_id = epoch_id,
        })
    end
    local epoch_ok, epoch_err = authority_epoch.verify(bucket.authority_epoch)
    if not epoch_ok then return nil, epoch_err end

    local physical = {}
    local eligible = {}
    local reason_counts = {}
    for direction, value in pairs(closure.directions) do
        if #(value.executed_refs or {}) > 0 then physical[#physical + 1] = direction end
        if #(value.corpus_eligible_executed_refs or {}) > 0 then
            eligible[#eligible + 1] = direction
        end
        for reason, count in pairs(value.rejected_reason_counts or {}) do
            reason_counts[reason] = (reason_counts[reason] or 0) + count
        end
    end
    table.sort(physical)
    table.sort(eligible)

    local rejected = {}
    for _, reason in ipairs(sorted_keys(reason_counts)) do
        rejected[#rejected + 1] = {
            reason = reason,
            observed_count = reason_counts[reason],
        }
    end

    return {
        evidence_epoch_id = epoch_id,
        physics_epoch_id = closure.target_physics_epoch_id,
        authority_epoch = copy_value(bucket.authority_epoch),
        life_ids = sorted_keys(bucket.source_lives),
        ledger_gate = closure.ledger_gate,
        provenance_gate = closure.provenance_gate,
        observer_gate = closure.observer_gate,
        l0_case_gate = closure.l0_case_gate,
        l1_case_gate = closure.l1_case_gate,
        closure_status = closure.closure_status,
        physical_direction_count = #physical,
        eligible_direction_count = #eligible,
        physical_directions = physical,
        eligible_directions = eligible,
        rejected_reasons = rejected,
        unclassified_executed_count = unclassified_count(bucket),
        instrument_error_count = instrument_error_count(bucket),
    }, closure.case_status
end

local function union_records(direction_epochs)
    local result = {}
    for _, direction in ipairs(sorted_keys(direction_epochs)) do
        result[#result + 1] = {
            direction = direction,
            epoch_ids = sorted_keys(direction_epochs[direction]),
        }
    end
    return result
end

local function current_case_rows(epoch_ids, statuses_by_epoch)
    local current = case_manifest.current()
    local result = {}
    for _, layer in ipairs({"L0", "L1"}) do
        local definitions = layer == "L0"
            and current.required_l0 or current.required_l1
        for _, definition in ipairs(definitions) do
            local statuses = {}
            for _, epoch_id in ipairs(epoch_ids) do
                local status = statuses_by_epoch[epoch_id]
                    and statuses_by_epoch[epoch_id][definition.case_id]
                statuses[#statuses + 1] = {
                    evidence_epoch_id = epoch_id,
                    status = status and status.status or "missing",
                }
            end
            result[#result + 1] = {
                case_id = definition.case_id,
                layer = layer,
                statuses = statuses,
            }
        end
    end
    return result
end

local function blockers_for(value)
    local blockers = {
        "diagnostic_report_only",
        "target_epoch_decision_absent",
    }
    if #value.epochs > 1 then
        blockers[#blockers + 1] = "cross_epoch_union_non_promotable"
    end
    if #value.diagnostic_union.physical_directions
        < value.required_direction_count then
        blockers[#blockers + 1] = "physical_direction_coverage_incomplete"
    end
    if #value.diagnostic_union.eligible_directions
        < value.required_direction_count then
        blockers[#blockers + 1] = "eligible_direction_coverage_incomplete"
    end
    local case_incomplete = false
    for _, epoch in ipairs(value.epochs) do
        if epoch.observer_gate ~= "green" then
            blockers[#blockers + 1] = "observer_gate_incomplete"
        end
        if epoch.l0_case_gate ~= "green" then
            blockers[#blockers + 1] = "l0_case_gate_incomplete"
        end
        if epoch.l1_case_gate ~= "green" then
            blockers[#blockers + 1] = "l1_case_gate_incomplete"
        end
        if epoch.unclassified_executed_count > 0 then
            blockers[#blockers + 1] = "unclassified_execution_present"
        end
    end
    for _, case in ipairs(value.case_status) do
        for _, status in ipairs(case.statuses) do
            if status.status ~= "green" then case_incomplete = true end
        end
    end
    if case_incomplete then blockers[#blockers + 1] = "case_manifest_incomplete" end
    return sorted_set(blockers)
end

local function report_seed(value)
    local seed = copy_value(value)
    seed.report_id = nil
    return seed
end

function report.build(record, options)
    local corpus_ok, corpus_err = edge_corpus.verify(record)
    if not corpus_ok then return nil, corpus_err end
    if record.authority_claim ~= "diagnostic" then
        return nil, report_error("current_report_requires_diagnostic_corpus")
    end
    if not exact_keys(options or {}, {implementation_revision = true})
        or not non_empty(options.implementation_revision) then
        return nil, report_error("current_report_options_invalid")
    end

    local surface, surface_err = edge_catalog.authority_surface()
    if not surface then return nil, surface_err end
    local current_cases = case_manifest.current()
    local epoch_ids = sorted_keys(record.buckets)
    if #epoch_ids == 0 then
        return nil, report_error("current_report_has_no_epochs")
    end

    local epochs = {}
    local statuses_by_epoch = {}
    local physical_epochs = {}
    local eligible_epochs = {}
    local reason_totals = {}
    local life_ids = {}
    for _, reason in ipairs(edge_credit.eligibility_reason_ids()) do
        reason_totals[reason] = {count = 0, epochs = {}}
    end

    for _, epoch_id in ipairs(epoch_ids) do
        local summary, case_status_or_err = epoch_summary(
            record,
            epoch_id,
            options.implementation_revision
        )
        if not summary then return nil, case_status_or_err end
        epochs[#epochs + 1] = summary
        statuses_by_epoch[epoch_id] = case_status_or_err
        for _, life_id in ipairs(summary.life_ids) do life_ids[life_id] = true end
        for _, direction in ipairs(summary.physical_directions) do
            physical_epochs[direction] = physical_epochs[direction] or {}
            physical_epochs[direction][epoch_id] = true
        end
        for _, direction in ipairs(summary.eligible_directions) do
            eligible_epochs[direction] = eligible_epochs[direction] or {}
            eligible_epochs[direction][epoch_id] = true
        end
        for _, rejected in ipairs(summary.rejected_reasons) do
            local total = reason_totals[rejected.reason]
            if not total then
                return nil, report_error("current_report_reason_unknown", {
                    reason = rejected.reason,
                })
            end
            total.count = total.count + rejected.observed_count
            total.epochs[epoch_id] = true
        end
    end

    local reason_rows = {}
    for _, reason in ipairs(edge_credit.eligibility_reason_ids()) do
        local total = reason_totals[reason]
        reason_rows[#reason_rows + 1] = {
            reason = reason,
            observed_count = total.count,
            epoch_ids = sorted_keys(total.epochs),
        }
    end

    local value = {
        kind = "current_authority_evidence_report",
        protocol_version = report.protocol_version,
        report_id = nil,
        corpus_id = record.corpus_id,
        source_revision = options.implementation_revision,
        authority_surface_id = surface.surface_id,
        case_manifest_id = current_cases.manifest_id,
        required_direction_count = surface.legal_direction_count,
        observed_life_ids = sorted_keys(life_ids),
        epochs = epochs,
        diagnostic_union = {
            physical_directions = union_records(physical_epochs),
            eligible_directions = union_records(eligible_epochs),
            truth_status = "diagnostic_query",
            promotion_eligible = false,
        },
        eligibility_reasons = reason_rows,
        case_status = current_case_rows(epoch_ids, statuses_by_epoch),
        promotion_authorized = false,
        promotion_blockers = {},
        decision_truth_status = "diagnostic_query",
        event_truth_status = "runtime_confirmed",
    }
    value.promotion_blockers = blockers_for(value)
    local report_id, report_id_err = tagged_digest(report_seed(value))
    if not report_id then return nil, report_id_err end
    value.report_id = report_id
    local verified, verify_err = report.verify(value)
    if not verified then return nil, verify_err end
    return copy_value(value)
end

local function verify_direction_list(values, vocabulary, epoch_ids)
    if type(values) ~= "table" then return false end
    local previous
    for index, value in ipairs(values) do
        if not exact_keys(value, {direction = true, epoch_ids = true})
            or not vocabulary[value.direction]
            or (previous and value.direction <= previous)
            or not strict_sorted_strings(value.epoch_ids)
            or index % 1 ~= 0 then
            return false
        end
        for _, epoch_id in ipairs(value.epoch_ids) do
            if not epoch_ids[epoch_id] then return false end
        end
        previous = value.direction
    end
    for key in pairs(values) do
        if type(key) ~= "number" or key < 1 or key > #values
            or key % 1 ~= 0 then return false end
    end
    return true
end

function report.verify(value)
    if not exact_keys(value, {
        kind = true,
        protocol_version = true,
        report_id = true,
        corpus_id = true,
        source_revision = true,
        authority_surface_id = true,
        case_manifest_id = true,
        required_direction_count = true,
        observed_life_ids = true,
        epochs = true,
        diagnostic_union = true,
        eligibility_reasons = true,
        case_status = true,
        promotion_authorized = true,
        promotion_blockers = true,
        decision_truth_status = true,
        event_truth_status = true,
    }) or value.kind ~= "current_authority_evidence_report"
        or value.protocol_version ~= report.protocol_version
        or not tagged_hash(value.report_id)
        or not non_empty(value.corpus_id)
        or not non_empty(value.source_revision)
        or not tagged_hash(value.authority_surface_id)
        or not tagged_hash(value.case_manifest_id)
        or not non_negative_integer(value.required_direction_count)
        or value.promotion_authorized ~= false
        or value.decision_truth_status ~= "diagnostic_query"
        or value.event_truth_status ~= "runtime_confirmed"
        or not strict_sorted_strings(value.observed_life_ids) then
        return nil, report_error("current_report_invalid")
    end

    local surface = assert(edge_catalog.authority_surface())
    local current_cases = case_manifest.current()
    if value.authority_surface_id ~= surface.surface_id
        or value.required_direction_count ~= surface.legal_direction_count
        or value.case_manifest_id ~= current_cases.manifest_id then
        return nil, report_error("current_report_contract_drift")
    end

    local vocabulary = direction_vocabulary()
    local epoch_ids = {}
    local previous_epoch
    local expected_physical = {}
    local expected_eligible = {}
    local expected_reasons = {}
    for _, reason in ipairs(edge_credit.eligibility_reason_ids()) do
        expected_reasons[reason] = {count = 0, epochs = {}}
    end
    for _, epoch in ipairs(value.epochs or {}) do
        if not exact_keys(epoch, {
            evidence_epoch_id = true,
            physics_epoch_id = true,
            authority_epoch = true,
            life_ids = true,
            ledger_gate = true,
            provenance_gate = true,
            observer_gate = true,
            l0_case_gate = true,
            l1_case_gate = true,
            closure_status = true,
            physical_direction_count = true,
            eligible_direction_count = true,
            physical_directions = true,
            eligible_directions = true,
            rejected_reasons = true,
            unclassified_executed_count = true,
            instrument_error_count = true,
        }) or not tagged_hash(epoch.evidence_epoch_id)
            or not tagged_hash(epoch.physics_epoch_id)
            or (previous_epoch and epoch.evidence_epoch_id <= previous_epoch)
            or not strict_sorted_strings(epoch.life_ids)
            or epoch.ledger_gate ~= "green"
            or epoch.provenance_gate ~= "green"
            or not gate_statuses[epoch.observer_gate]
            or not gate_statuses[epoch.l0_case_gate]
            or not gate_statuses[epoch.l1_case_gate]
            or not closure_statuses[epoch.closure_status]
            or not non_negative_integer(epoch.physical_direction_count)
            or not non_negative_integer(epoch.eligible_direction_count)
            or not strict_sorted_strings(epoch.physical_directions, true)
            or not strict_sorted_strings(epoch.eligible_directions, true)
            or epoch.physical_direction_count ~= #epoch.physical_directions
            or epoch.eligible_direction_count ~= #epoch.eligible_directions
            or not non_negative_integer(epoch.unclassified_executed_count)
            or not non_negative_integer(epoch.instrument_error_count)
            or epoch.instrument_error_count ~= 0 then
            return nil, report_error("current_report_epoch_invalid")
        end
        local epoch_ok = authority_epoch.verify(epoch.authority_epoch)
        if not epoch_ok
            or epoch.authority_epoch.evidence_epoch_id ~= epoch.evidence_epoch_id
            or epoch.authority_epoch.physics_epoch_id ~= epoch.physics_epoch_id then
            return nil, report_error("current_report_epoch_identity_invalid")
        end
        epoch_ids[epoch.evidence_epoch_id] = true
        previous_epoch = epoch.evidence_epoch_id
        local physical_set = {}
        for _, direction in ipairs(epoch.physical_directions) do
            if not vocabulary[direction] then
                return nil, report_error("current_report_direction_unknown")
            end
            physical_set[direction] = true
            expected_physical[direction] = expected_physical[direction] or {}
            expected_physical[direction][epoch.evidence_epoch_id] = true
        end
        for _, direction in ipairs(epoch.eligible_directions) do
            if not physical_set[direction] then
                return nil, report_error("current_report_eligible_without_physical")
            end
            expected_eligible[direction] = expected_eligible[direction] or {}
            expected_eligible[direction][epoch.evidence_epoch_id] = true
        end
        local previous_reason
        for _, rejected in ipairs(epoch.rejected_reasons or {}) do
            if not exact_keys(rejected, {
                reason = true,
                observed_count = true,
            }) or not edge_credit.is_eligibility_reason(rejected.reason)
                or not non_negative_integer(rejected.observed_count)
                or rejected.observed_count == 0
                or (previous_reason and rejected.reason <= previous_reason) then
                return nil, report_error("current_report_rejection_invalid")
            end
            local total = expected_reasons[rejected.reason]
            total.count = total.count + rejected.observed_count
            total.epochs[epoch.evidence_epoch_id] = true
            previous_reason = rejected.reason
        end
    end
    if next(epoch_ids) == nil then
        return nil, report_error("current_report_has_no_epochs")
    end

    if not exact_keys(value.diagnostic_union, {
        physical_directions = true,
        eligible_directions = true,
        truth_status = true,
        promotion_eligible = true,
    }) or value.diagnostic_union.truth_status ~= "diagnostic_query"
        or value.diagnostic_union.promotion_eligible ~= false
        or not verify_direction_list(
            value.diagnostic_union.physical_directions,
            vocabulary,
            epoch_ids
        )
        or not verify_direction_list(
            value.diagnostic_union.eligible_directions,
            vocabulary,
            epoch_ids
        )
        or not same_value(
            value.diagnostic_union.physical_directions,
            union_records(expected_physical)
        )
        or not same_value(
            value.diagnostic_union.eligible_directions,
            union_records(expected_eligible)
        ) then
        return nil, report_error("current_report_union_invalid")
    end

    local expected_reason_rows = {}
    for _, reason in ipairs(edge_credit.eligibility_reason_ids()) do
        local total = expected_reasons[reason]
        expected_reason_rows[#expected_reason_rows + 1] = {
            reason = reason,
            observed_count = total.count,
            epoch_ids = sorted_keys(total.epochs),
        }
    end
    if not same_value(value.eligibility_reasons, expected_reason_rows) then
        return nil, report_error("current_report_reason_coverage_invalid")
    end

    local expected_case_count = #current_cases.required_l0
        + #current_cases.required_l1
    if type(value.case_status) ~= "table"
        or #value.case_status ~= expected_case_count then
        return nil, report_error("current_report_case_status_invalid")
    end
    local definition_index = 0
    for _, layer in ipairs({"L0", "L1"}) do
        local definitions = layer == "L0"
            and current_cases.required_l0 or current_cases.required_l1
        for _, definition in ipairs(definitions) do
            definition_index = definition_index + 1
            local row = value.case_status[definition_index]
            if not exact_keys(row, {
                case_id = true,
                layer = true,
                statuses = true,
            }) or row.case_id ~= definition.case_id or row.layer ~= layer
                or #row.statuses ~= #value.epochs then
                return nil, report_error("current_report_case_status_invalid")
            end
            for index, status in ipairs(row.statuses) do
                local epoch = value.epochs[index]
                if not exact_keys(status, {
                    evidence_epoch_id = true,
                    status = true,
                }) or status.evidence_epoch_id ~= epoch.evidence_epoch_id
                    or not case_statuses[status.status] then
                    return nil, report_error("current_report_case_status_invalid")
                end
            end
        end
    end

    if not strict_sorted_strings(value.promotion_blockers)
        or not same_value(value.promotion_blockers, blockers_for(value)) then
        return nil, report_error("current_report_blockers_invalid")
    end
    local expected_id, id_err = tagged_digest(report_seed(value))
    if not expected_id or expected_id ~= value.report_id then
        return nil, id_err or report_error("current_report_id_invalid")
    end
    return true
end

function report.snapshot(value)
    local ok, err = report.verify(value)
    if not ok then return nil, err end
    return copy_value(value)
end

return report
