local json = require("core.json")
local topology = require("core.topology")
local field = require("runtime.field")
local choice_inspection = require("runtime.choice_inspection")
local plan_completion = require("runtime.plan_completion")
local pressure_action = require("runtime.pressure_action")
local reconciliation = require("runtime.reconciliation")
local relation_inspection = require("runtime.relation_inspection")
local structure_inspection = require("runtime.structure_inspection")
local upper_coverage = require("runtime.upper_coverage")

local qualified = {
    derivation_version = "pressure.qualified_need.v0",
    calibration_status = "unmeasured_qualified",
}

local canonical_index = {}
for index, glyph in ipairs(topology.order) do
    canonical_index[glyph] = index
end

local relation_consumer = {
    id = "encode.relation_formation.v0",
    causal_class = "causal_affordance",
    accepted_candidate_predicates = {
        ["connect.parent_carrier.v0"] = true,
        ["connect.l1_registered_projection.v0"] = true,
    },
}

local structure_consumer = {
    id = structure_inspection.receiver_contract_id,
    causal_class = "causal_affordance",
}

local choice_consumer = {
    id = choice_inspection.consumer_contract_id,
    causal_class = "blocking_demand",
}

local plan_review_consumer = {
    id = plan_completion.review_consumer_id,
    causal_class = "blocking_demand",
}

local plan_delivery_consumer = {
    id = plan_completion.delivery_consumer_id,
    causal_class = "terminal_boundary",
}

local normal_plan_absence = {
    plan_mode_absent = true,
    plan_structure_formation_missing = true,
    plan_material_absent = true,
    plan_choice_incomplete = true,
    plan_material_stale = true,
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

local function merge_refs(...)
    local values = {}
    for index = 1, select("#", ...) do
        for _, value in ipairs(select(index, ...) or {}) do
            values[#values + 1] = value
        end
    end
    return sorted_unique(values)
end

local function edge(left, right)
    if canonical_index[left] <= canonical_index[right] then
        return left .. "-" .. right
    end
    return right .. "-" .. left
end

local function exact_ref(id, version)
    return table.concat({"coverage", "field_unit", id, tostring(version)}, ":")
end

local function content_truth(instance, versions)
    local status
    for id in pairs(versions or {}) do
        local unit = field.get_unit(instance, id)
        local current = unit and unit.content_truth_status or "unknown"
        if status == nil then
            status = current
        elseif status ~= current then
            return "mixed"
        end
    end
    return status or "unknown"
end

local function witness_identity(input)
    return "pressure-id:" .. json.encode({
        protocol_version = "pressure.witness.v1",
        kind = input.kind,
        target_operator = input.target_operator,
        causal_class = input.causal_class,
        source_domain = input.source_domain,
        scope_refs = input.scope_refs,
        provenance_refs = input.provenance_refs,
    })
end

local function build_witness(instance, current, input)
    local target = topology.resolve(input.target_operator)
    if not target or not topology.is_adjacent(current, target) then
        return nil, "qualified witness target is not adjacent"
    end
    input.scope_refs = sorted_unique(input.scope_refs)
    input.provenance_refs = sorted_unique(input.provenance_refs)
    if #input.scope_refs == 0 then
        return nil, "qualified witness scope is empty"
    end
    local witness_id = witness_identity(input)
    input.action_input.witness_id = witness_id
    input.action_input.target_operator = target
    input.action_input.scope_refs = copy_value(input.scope_refs)
    input.action_input.provenance_refs = copy_value(input.provenance_refs)
    local plan, plan_err = pressure_action.build(input.action_mode, input.action_input)
    if not plan then
        return nil, plan_err
    end
    local witness = {
        protocol_version = "pressure.witness.v1",
        witness_id = witness_id,
        kind = input.kind,
        current_operator = current,
        target_operator = target,
        target_edge = edge(current, target),
        direction = "help",
        causal_class = input.causal_class,
        source_domain = input.source_domain,
        scope_refs = copy_value(input.scope_refs),
        provenance_refs = copy_value(input.provenance_refs),
        action_plan = plan,
        calculation_status = "runtime_confirmed",
        source_truth_status = input.source_truth_status or "runtime_confirmed",
        derivation_version = qualified.derivation_version,
    }
    for key, value in pairs(input.metadata or {}) do
        witness[key] = copy_value(value)
    end
    return witness
end

local function current_operator(instance, context)
    context = context or {}
    local tick = context.tick_result or context.tick or {}
    return topology.resolve(context.current_operator or tick.operator or instance.operator)
end

local function relation_bounds(options)
    local configured = options.relation_bounds or {}
    return {
        max_units = configured.max_units or 64,
        max_relations = configured.max_relations or 128,
    }
end

local function relation_action_preconditions(instance, versions, raw_epoch)
    return {
        packet_id = instance.id,
        generation = instance.generation,
        object_versions = copy_value(versions),
        raw_epoch = raw_epoch,
        relevant_revisions = {
            relations_raw = instance.revisions.relations_raw,
        },
    }
end

local function recognition_witness(instance, current, candidate, bounds)
    local provenance = merge_refs(candidate.provenance_refs, {
        "consumer:" .. relation_consumer.id,
    })
    local unit_ids = {}
    for id in pairs(candidate.endpoint_versions or {}) do
        unit_ids[#unit_ids + 1] = id
    end
    table.sort(unit_ids)
    return build_witness(instance, current, {
        kind = "relation_recognition_need",
        target_operator = "☰",
        causal_class = relation_consumer.causal_class,
        source_domain = "relation_candidate",
        scope_refs = candidate.scope_refs,
        provenance_refs = provenance,
        source_truth_status = candidate.event_truth_status,
        action_mode = "connect_probe",
        action_input = {
            preconditions = relation_action_preconditions(
                instance,
                candidate.endpoint_versions
            ),
            options = {connect = {
                policy_id = "connect.structural.v1",
                unit_ids = unit_ids,
                unit_versions = candidate.endpoint_versions,
                bounds = bounds,
            }},
            expected_effect = {
                discharge_reader = "relation_recognition_need",
            },
            content_truth_status = candidate.content_truth_status,
        },
        metadata = {
            consumer_contract = relation_consumer.id,
            predicate_id = candidate.predicate_id,
            promotion_source = candidate.promotion_source or "body",
        },
    })
end

local function formation_witness(instance, current, raw, relations)
    local relation_ids = {}
    local endpoint_versions = {}
    local scope_refs = {}
    local provenance_refs = {
        "consumer:" .. relation_consumer.id,
    }
    local content_status
    local promotion_source = "body"
    for _, relation in ipairs(relations) do
        relation_ids[#relation_ids + 1] = relation.id
        scope_refs[#scope_refs + 1] = relation.id
        if relation.origin_event_id then
            provenance_refs[#provenance_refs + 1] = relation.origin_event_id
        end
        if relation.promotion_source == "fixture" then
            promotion_source = "fixture"
        end
        for id, version in pairs(relation.endpoint_versions or {}) do
            endpoint_versions[id] = version
            scope_refs[#scope_refs + 1] = exact_ref(id, version)
        end
        local current = relation.content_truth_status or "unknown"
        if content_status == nil then
            content_status = current
        elseif content_status ~= current then
            content_status = "mixed"
        end
    end
    table.sort(relation_ids)
    provenance_refs = merge_refs(provenance_refs, raw.source_event_refs, {
        raw.trace_event_id,
    })
    return build_witness(instance, current, {
        kind = "relation_formation_need",
        target_operator = "☵",
        causal_class = relation_consumer.causal_class,
        source_domain = "raw_relation",
        scope_refs = scope_refs,
        provenance_refs = provenance_refs,
        action_mode = "relation_formation",
        action_input = {
            preconditions = relation_action_preconditions(
                instance,
                endpoint_versions,
                raw.epoch
            ),
            options = {encode = {relation_input = {
                raw_epoch = raw.epoch,
                relation_ids = relation_ids,
                endpoint_versions = endpoint_versions,
                source_event_refs = provenance_refs,
            }}},
            expected_effect = {
                discharge_reader = "relation_formation_need",
            },
            content_truth_status = content_status or "unknown",
        },
        metadata = {
            consumer_contract = relation_consumer.id,
            raw_epoch = raw.epoch,
            promotion_source = promotion_source,
        },
    })
end

function qualified.relation_witnesses(instance, context, options)
    options = options or {}
    local current = current_operator(instance, context)
    if not current then
        return nil, "invalid current operator"
    end
    if options.ablate_relation_consumer == true then
        return {}, {{
            kind = "qualified_consumer_ablation",
            consumer_contract = relation_consumer.id,
            event_truth_status = "runtime_confirmed",
        }}
    end

    local bounds = relation_bounds(options)
    local inspection, inspection_err = relation_inspection.derive(instance, {
        policy_id = "connect.structural.v1",
        bounds = bounds,
    })
    if not inspection then
        return nil, inspection_err
    end
    local witnesses = {}
    local diagnostics = {}
    if inspection.qualification_status ~= "complete_scope" then
        diagnostics[#diagnostics + 1] = {
            kind = "incomplete_relation_scope",
            inspection_id = inspection.inspection_id,
            event_truth_status = "runtime_confirmed",
        }
    elseif topology.is_adjacent(current, "☰") then
        local candidates = {}
        for _, candidate in ipairs(inspection.candidate_delta.missing or {}) do
            candidates[#candidates + 1] = candidate
        end
        for _, candidate in ipairs(inspection.candidate_delta.stale or {}) do
            candidates[#candidates + 1] = candidate
        end
        for _, candidate in ipairs(candidates) do
            if relation_consumer.accepted_candidate_predicates[candidate.predicate_id] then
                local witness, witness_err = recognition_witness(
                    instance,
                    current,
                    candidate,
                    bounds
                )
                if not witness then
                    return nil, witness_err
                end
                witnesses[#witnesses + 1] = witness
            end
        end
    end

    local raw = instance.field and instance.field.relations
        and instance.field.relations.raw or {}
    if type(raw.epoch) == "number" and raw.epoch > 0
        and topology.is_adjacent(current, "☵") then
        local formable = {}
        for _, relation in ipairs(raw.items or {}) do
            if relation_consumer.accepted_candidate_predicates[relation.predicate_id] then
                local phase, phase_err = field.raw_relation_phase(
                    instance,
                    raw.epoch,
                    relation.id
                )
                if not phase then
                    return nil, phase_err
                end
                if phase.phase == "available" or phase.phase == "observed" then
                    formable[#formable + 1] = relation
                end
            end
        end
        if #formable > 0 then
            local witness, witness_err = formation_witness(instance, current, raw, formable)
            if not witness then
                return nil, witness_err
            end
            witnesses[#witnesses + 1] = witness
        end
    end

    return witnesses, diagnostics
end

local function structure_witness(instance, current, candidate)
    return build_witness(instance, current, {
        kind = "encoding_need",
        target_operator = "☵",
        causal_class = structure_consumer.causal_class,
        source_domain = "packet_structure_proposal",
        scope_refs = {candidate.exact_ref},
        provenance_refs = merge_refs({
            candidate.source_creation_event_ref,
            candidate.source_observation_event_ref,
            "consumer:" .. structure_consumer.id,
        }),
        source_truth_status = candidate.source_content_truth_status,
        action_mode = "structure_formation",
        action_input = {
            preconditions = {
                packet_id = instance.id,
                generation = instance.generation,
                object_versions = {
                    [candidate.source_unit_id] = candidate.source_version,
                },
                relevant_revisions = {},
            },
            options = {encode = {structure_input = {
                source_unit_id = candidate.source_unit_id,
                source_version = candidate.source_version,
                envelope_fingerprint = candidate.envelope_fingerprint,
                receiver_contract_id = candidate.receiver_contract_id,
                requested_shape = candidate.requested_shape,
                adapter_policy_id = structure_inspection.adapter_policy_id,
                bounds = {
                    max_output_units = candidate.bounds.max_output_units,
                    max_loss_log_entries = candidate.bounds.max_loss_log_entries,
                },
            }}},
            expected_effect = {
                discharge_reader = "encoding_need",
            },
            content_truth_status = candidate.source_content_truth_status,
        },
        metadata = {
            consumer_contract = structure_consumer.id,
            requested_shape = candidate.requested_shape,
            envelope_fingerprint = candidate.envelope_fingerprint,
            promotion_source = "body",
        },
    })
end

function qualified.structure_witnesses(instance, context, options)
    options = options or {}
    local current = current_operator(instance, context)
    if not current then
        return nil, "invalid current operator"
    end
    if options.ablate_structure_consumer == true then
        return {}, {{
            kind = "qualified_consumer_ablation",
            consumer_contract = structure_consumer.id,
            event_truth_status = "runtime_confirmed",
        }}
    end

    local result, result_err = structure_inspection.derive(
        instance,
        options.structure_bounds
    )
    if not result then
        return nil, result_err
    end
    local diagnostics = copy_value(result.diagnostics or {})
    if result.qualification_status ~= "qualified" then
        diagnostics[#diagnostics + 1] = {
            kind = "incomplete_structure_scope",
            event_truth_status = "runtime_confirmed",
        }
        return {}, diagnostics
    end
    if not topology.is_adjacent(current, "☵") then
        return {}, diagnostics
    end

    local witnesses = {}
    for _, candidate in ipairs(result.missing or {}) do
        local witness, witness_err = structure_witness(instance, current, candidate)
        if not witness then
            return nil, witness_err
        end
        witnesses[#witnesses + 1] = witness
    end
    return witnesses, diagnostics
end

local function choice_witness(instance, current, set)
    return build_witness(instance, current, {
        kind = "choice_need",
        target_operator = "☳",
        causal_class = choice_consumer.causal_class,
        source_domain = "formation_choice_set",
        scope_refs = set.scope_refs,
        provenance_refs = merge_refs(
            {set.choice_set_ref, "consumer:" .. choice_consumer.id},
            set.observation_event_refs
        ),
        source_truth_status = set.selection_basis_truth_status,
        action_mode = "alternative_collapse",
        action_input = {
            preconditions = {
                packet_id = instance.id,
                generation = instance.generation,
                object_versions = set.alternative_versions,
                relevant_revisions = {},
            },
            options = {choose = {choice_input = {
                choice_set_ref = set.choice_set_ref,
                alternative_ids = set.alternative_ids,
                alternative_versions = set.alternative_versions,
                max_selected = set.max_selected,
                selection_policy_id = set.selection_policy_id,
                max_killed_sample = set.max_killed_sample,
            }}},
            expected_effect = {
                discharge_reader = "choice_need",
            },
            content_truth_status = set.selection_basis_truth_status,
        },
        metadata = {
            consumer_contract = choice_consumer.id,
            choice_set_ref = set.choice_set_ref,
            alternative_ids = set.alternative_ids,
            required_max_selected = set.max_selected,
            selection_policy_id = set.selection_policy_id,
            promotion_source = "body",
        },
    })
end

function qualified.choice_witnesses(instance, context, options)
    options = options or {}
    local current = current_operator(instance, context)
    if not current then
        return nil, "invalid current operator"
    end
    if options.ablate_choice_consumer == true then
        return {}, {{
            kind = "qualified_consumer_ablation",
            consumer_contract = choice_consumer.id,
            event_truth_status = "runtime_confirmed",
        }}
    end
    local result, result_err = choice_inspection.derive(
        instance,
        options.choice_bounds
    )
    if not result then
        return nil, result_err
    end
    local diagnostics = copy_value(result.diagnostics or {})
    if result.qualification_status ~= "qualified" then
        return {}, diagnostics
    end
    if not topology.is_adjacent(current, "☳") then
        return {}, diagnostics
    end

    local witnesses = {}
    for _, set in ipairs(result.missing or {}) do
        local witness, witness_err = choice_witness(instance, current, set)
        if not witness then
            return nil, witness_err
        end
        witnesses[#witnesses + 1] = witness
    end
    return witnesses, diagnostics
end

local function plan_review_witness(instance, current, candidate, runtime_view, scope)
    return build_witness(instance, current, {
        kind = "plan_completion_review_need",
        target_operator = "☱",
        causal_class = plan_review_consumer.causal_class,
        source_domain = "plan_completion_candidate",
        scope_refs = scope.scope_refs,
        provenance_refs = scope.provenance_refs,
        source_truth_status = candidate.source_truth_status,
        action_mode = "plan_completion_review",
        action_input = {
            preconditions = {
                packet_id = instance.id,
                generation = instance.generation,
                object_versions = candidate.formed_unit_versions,
                relevant_revisions = plan_completion.relevant_revisions(instance),
            },
            options = {runtime = {plan_completion_input = {
                candidate_id = candidate.candidate_id,
                formation_event_ref = candidate.formation_event_ref,
                formed_unit_ids = candidate.formed_unit_ids,
                formed_unit_versions = candidate.formed_unit_versions,
                coverage_event_refs = candidate.coverage_event_refs,
                choice_event_ref = candidate.choice_event_ref,
                through_seq = runtime_view.through_seq,
                significant_frame_refs = scope.significant_frame_refs,
            }}},
            expected_effect = {
                discharge_reader = "plan_completion_review_need",
            },
            content_truth_status = candidate.source_truth_status,
        },
        metadata = {
            consumer_contract = plan_review_consumer.id,
            candidate_id = candidate.candidate_id,
            formation_event_ref = candidate.formation_event_ref,
            promotion_source = "body",
        },
    })
end

local function plan_delivery_witness(instance, current, candidate, assessment)
    local scope_refs = merge_refs(
        candidate.scope_refs,
        {assessment.event.id}
    )
    return build_witness(instance, current, {
        kind = "plan_delivery_need",
        target_operator = "△",
        causal_class = plan_delivery_consumer.causal_class,
        source_domain = "plan_completion_assessment",
        scope_refs = scope_refs,
        provenance_refs = merge_refs({
            assessment.event.id,
            assessment.assessment.runtime_reconciliation_ref,
            candidate.formation_event_ref,
            "consumer:" .. plan_delivery_consumer.id,
        }),
        source_truth_status = candidate.source_truth_status,
        action_mode = "plan_delivery",
        action_input = {
            preconditions = {
                packet_id = instance.id,
                generation = instance.generation,
                object_versions = candidate.formed_unit_versions,
                relevant_revisions = plan_completion.relevant_revisions(instance),
            },
            options = {manifest = {plan_input = {
                assessment_event_ref = assessment.event.id,
                assessment_id = assessment.assessment.assessment_id,
                candidate_id = candidate.candidate_id,
                formation_event_ref = candidate.formation_event_ref,
                formed_unit_ids = candidate.formed_unit_ids,
                formed_unit_versions = candidate.formed_unit_versions,
                coverage_event_refs = candidate.coverage_event_refs,
                choice_event_ref = candidate.choice_event_ref,
            }}},
            expected_effect = {
                discharge_reader = "plan_delivery_need",
            },
            content_truth_status = candidate.source_truth_status,
        },
        metadata = {
            consumer_contract = plan_delivery_consumer.id,
            candidate_id = candidate.candidate_id,
            assessment_event_ref = assessment.event.id,
            promotion_source = "body",
        },
    })
end

function qualified.plan_witnesses(instance, context, options)
    options = options or {}
    local current = current_operator(instance, context)
    if not current then
        return nil, "invalid current operator"
    end
    local inspection, inspection_err = plan_completion.inspect(instance, {
        structure_bounds = options.structure_bounds,
        upper_bounds = options.upper_bounds,
        choice_bounds = options.choice_bounds,
    })
    if not inspection then
        return nil, inspection_err
    end
    local diagnostics = copy_value(inspection.diagnostics or {})
    if inspection.state ~= "complete_candidate" then
        local unqualified = {}
        for _, item in ipairs(diagnostics) do
            if not normal_plan_absence[item.kind] then
                unqualified[#unqualified + 1] = item
            end
        end
        return {}, unqualified
    end
    local candidate = inspection.candidate
    local assessment, assessment_err = plan_completion.find_assessment(
        instance,
        candidate
    )
    if not assessment and assessment_err ~= "plan_assessment_absent" then
        if tostring(assessment_err):find("plan_assessment_stale:", 1, true) == 1 then
            diagnostics[#diagnostics + 1] = {
                kind = "plan_assessment_stale",
                reason = assessment_err,
                event_truth_status = "runtime_confirmed",
            }
            return {}, diagnostics
        end
        return nil, assessment_err
    end

    if current == "☴" and assessment == nil then
        if options.ablate_plan_completion_consumer == true then
            diagnostics[#diagnostics + 1] = {
                kind = "qualified_consumer_ablation",
                consumer_contract = plan_review_consumer.id,
                event_truth_status = "runtime_confirmed",
            }
            return {}, diagnostics
        end
        local runtime_view, runtime_err = reconciliation.inspect(instance)
        if not runtime_view then
            return nil, runtime_err
        end
        local scope, scope_err = plan_completion.review_scope(
            instance,
            candidate,
            runtime_view
        )
        if not scope then
            diagnostics[#diagnostics + 1] = {
                kind = "plan_runtime_effect_absent",
                reason = scope_err,
                event_truth_status = "runtime_confirmed",
            }
            return {}, diagnostics
        end
        local witness, witness_err = plan_review_witness(
            instance,
            current,
            candidate,
            runtime_view,
            scope
        )
        if not witness then
            return nil, witness_err
        end
        return {witness}, diagnostics
    end

    if current == "☱" and assessment ~= nil then
        if options.ablate_plan_delivery_consumer == true then
            diagnostics[#diagnostics + 1] = {
                kind = "qualified_consumer_ablation",
                consumer_contract = plan_delivery_consumer.id,
                event_truth_status = "runtime_confirmed",
            }
            return {}, diagnostics
        end
        local witness, witness_err = plan_delivery_witness(
            instance,
            current,
            candidate,
            assessment
        )
        if not witness then
            return nil, witness_err
        end
        return {witness}, diagnostics
    end

    return {}, diagnostics
end

local function upper_sensor(instance, need)
    if need.sensor ~= "field_native" then
        return need.sensor
    end
    if instance.ingress
        and instance.ingress.integration_protocol == "vertical_packet_life.v0" then
        return "field_native"
    end
    return "semantic"
end

local function upper_witness(instance, current, sensor, needs)
    local unit_ids = {}
    local unit_versions = {}
    local scope_refs = {}
    local provenance_refs = {}
    local classes = {}
    for _, need in ipairs(needs) do
        unit_ids[#unit_ids + 1] = need.object_id
        unit_versions[need.object_id] = need.version
        scope_refs = merge_refs(scope_refs, need.scope_refs)
        provenance_refs = merge_refs(provenance_refs, need.provenance_refs)
        classes[need.observation_class] = true
    end
    table.sort(unit_ids)
    local class_names = {}
    for class in pairs(classes) do
        class_names[#class_names + 1] = class
    end
    table.sort(class_names)
    local mode = sensor .. "_observe"
    local source_domain = "upper_observation:" .. table.concat(class_names, "+")
    return build_witness(instance, current, {
        kind = "upper_observation_need",
        target_operator = "☴",
        causal_class = "blocking_demand",
        source_domain = source_domain,
        scope_refs = scope_refs,
        provenance_refs = provenance_refs,
        action_mode = mode,
        action_input = {
            preconditions = {
                packet_id = instance.id,
                generation = instance.generation,
                object_versions = unit_versions,
                relevant_revisions = {},
            },
            options = {observe = {
                sensor = sensor,
                unit_ids = unit_ids,
                unit_versions = unit_versions,
            }},
            expected_effect = {
                discharge_reader = "upper_observation_need",
            },
            content_truth_status = content_truth(instance, unit_versions),
        },
        metadata = {
            observation_classes = class_names,
        },
    })
end

function qualified.upper_witnesses(instance, context, options)
    options = options or {}
    local current = current_operator(instance, context)
    if not current then
        return nil, "invalid current operator"
    end
    local view, view_err = upper_coverage.derive(instance, options.upper_bounds)
    if not view then
        return nil, view_err
    end
    local needs, needs_err = upper_coverage.needs(instance, view, options.upper_bounds)
    if not needs then
        return nil, needs_err
    end
    local diagnostics = copy_value(needs.diagnostics or {})
    if needs.truncated then
        diagnostics[#diagnostics + 1] = {
            kind = "incomplete_upper_scope",
            event_truth_status = "runtime_confirmed",
        }
    end
    if not topology.is_adjacent(current, "☴") then
        return {}, diagnostics
    end

    local grouped = {}
    for _, need in ipairs(needs.items or {}) do
        local sensor = upper_sensor(instance, need)
        grouped[sensor] = grouped[sensor] or {}
        grouped[sensor][#grouped[sensor] + 1] = need
    end
    local sensors = {}
    for sensor in pairs(grouped) do
        sensors[#sensors + 1] = sensor
    end
    table.sort(sensors)
    local witnesses = {}
    for _, sensor in ipairs(sensors) do
        local witness, witness_err = upper_witness(
            instance,
            current,
            sensor,
            grouped[sensor]
        )
        if not witness then
            return nil, witness_err
        end
        witnesses[#witnesses + 1] = witness
    end
    return witnesses, diagnostics
end

function qualified.derive(instance, tick_result, options)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    options = options or {}
    local context = {
        current_operator = options.current_operator,
        tick_result = tick_result or {},
    }
    local current = current_operator(instance, context)
    if not current then
        return nil, "invalid current operator"
    end
    local relation, relation_diagnostics = qualified.relation_witnesses(
        instance,
        context,
        options
    )
    if not relation then
        return nil, relation_diagnostics
    end
    local upper, upper_diagnostics = qualified.upper_witnesses(
        instance,
        context,
        options
    )
    if not upper then
        return nil, upper_diagnostics
    end
    local structure, structure_diagnostics = qualified.structure_witnesses(
        instance,
        context,
        options
    )
    if not structure then
        return nil, structure_diagnostics
    end
    local choice, choice_diagnostics = qualified.choice_witnesses(
        instance,
        context,
        options
    )
    if not choice then
        return nil, choice_diagnostics
    end
    local plan, plan_diagnostics = qualified.plan_witnesses(
        instance,
        context,
        options
    )
    if not plan then
        return nil, plan_diagnostics
    end
    local witnesses = {}
    for _, witness in ipairs(relation) do
        witnesses[#witnesses + 1] = witness
    end
    for _, witness in ipairs(upper) do
        witnesses[#witnesses + 1] = witness
    end
    for _, witness in ipairs(structure) do
        witnesses[#witnesses + 1] = witness
    end
    for _, witness in ipairs(choice) do
        witnesses[#witnesses + 1] = witness
    end
    for _, witness in ipairs(plan) do
        witnesses[#witnesses + 1] = witness
    end
    table.sort(witnesses, function(left, right)
        return left.witness_id < right.witness_id
    end)
    local unqualified = {}
    for _, diagnostic in ipairs(relation_diagnostics or {}) do
        unqualified[#unqualified + 1] = diagnostic
    end
    for _, diagnostic in ipairs(upper_diagnostics or {}) do
        unqualified[#unqualified + 1] = diagnostic
    end
    for _, diagnostic in ipairs(structure_diagnostics or {}) do
        unqualified[#unqualified + 1] = diagnostic
    end
    for _, diagnostic in ipairs(choice_diagnostics or {}) do
        unqualified[#unqualified + 1] = diagnostic
    end
    for _, diagnostic in ipairs(plan_diagnostics or {}) do
        unqualified[#unqualified + 1] = diagnostic
    end
    local clock = instance.physis and instance.physis.clock or {}
    return {
        kind = "qualified_pressure_snapshot",
        packet_id = instance.id,
        generation = instance.generation,
        tick = clock.ticks or 0,
        current_operator = current,
        derivation_version = qualified.derivation_version,
        calibration_status = qualified.calibration_status,
        runtime_policy = "qualified_need_v0",
        witnesses = witnesses,
        unqualified = unqualified,
        source_revisions = copy_value(instance.revisions),
        event_truth_status = "runtime_confirmed",
    }
end

qualified.relation_consumer = copy_value(relation_consumer)
qualified.structure_consumer = copy_value(structure_consumer)
qualified.choice_consumer = copy_value(choice_consumer)
qualified.plan_review_consumer = copy_value(plan_review_consumer)
qualified.plan_delivery_consumer = copy_value(plan_delivery_consumer)

return qualified
