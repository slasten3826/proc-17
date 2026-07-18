local packet = require("core.packet")
local packet_birth = require("runtime.packet_birth")
local registry = require("runtime.operator_registry")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local body = require("runtime.body")
local camera = require("runtime.camera")
local freshness = require("runtime.freshness")

local vertical_life = {}
local methods = {}
methods.__index = methods

local function event_refs(instance, first_index)
    local refs = {}
    for index = first_index, #instance.trace do
        refs[#refs + 1] = instance.trace[index].id
    end
    return refs
end

local function ledger_refs(prefix, first_index, last_index)
    local refs = {}
    for index = first_index, last_index do
        refs[#refs + 1] = prefix .. tostring(index)
    end
    return refs
end

function vertical_life.new(domain, prompt, adapter, options)
    options = options or {}
    local instance, birth_or_err = packet_birth.create(domain, prompt, {
        projection_adapter = adapter,
        packet_options = options.packet_options,
        inherited_graves = options.inherited_graves,
    })
    if not instance then
        return nil, birth_or_err
    end
    local budget_ready, budget_err = budget.init(instance)
    if not budget_ready then
        return nil, budget_err
    end
    local loss_ready, loss_err = loss.init(instance, options.loss or {})
    if not loss_ready then
        return nil, loss_err
    end

    local self = setmetatable({
        instance = instance,
        domain = domain,
        substrate = options.substrate,
        result = {
            kind = "vertical_fixture_life",
            packet_id = instance.id,
            ticks = {},
            routes = {},
            authority = "harness_override",
            promotion_eligible = false,
        },
        birth = birth_or_err,
    }, methods)
    local payload, flow_err = registry.run("▽", instance, {
        substrate = self.substrate,
        options = options,
        result = self.result,
    })
    if not payload then
        return nil, flow_err
    end
    self.result.flow = payload
    return self
end

function methods:transition(target, reason)
    local decision = {
        kind = "route_decision",
        from = self.instance.operator,
        to = target,
        reason = reason or "vertical_fixture_route",
        authority = "harness_override",
        truth_status = "runtime_confirmed",
    }
    local event, err = packet.commit_transition(self.instance, decision)
    if not event then
        return nil, err
    end
    decision.trace_event_id = event.id
    self.result.routes[#self.result.routes + 1] = decision
    return decision
end

function methods:tick(options)
    options = options or {}
    local instance = self.instance
    local operator = instance.operator
    local revisions_before, revisions_err = camera.revision_snapshot(instance)
    if not revisions_before then
        return nil, revisions_err
    end
    local budget_before = budget.snapshot(instance)
    local loss_before = loss.snapshot(instance)
    local progress_before = body.progress(instance)
    local fingerprint_before = freshness.evidence_fingerprint(instance)
    local trace_start = #instance.trace + 1
    local budget_start = #(instance.runtime.budget.events or {}) + 1
    local loss_start = #(instance.tension.loss_events or {}) + 1

    local tick_event, tick_err = packet.begin_tick(instance, operator, {})
    if not tick_event then
        return nil, tick_err
    end
    local execution, execution_err = registry.execute(operator, instance, {
        substrate = self.substrate,
        options = options,
        result = self.result,
    })
    if not execution then
        return nil, execution_err
    end
    if execution.status ~= "applied" then
        return nil, execution.readiness and execution.readiness.reason
            or execution.status
    end
    local payload = execution.payload

    instance.physis.clock.ticks = instance.physis.clock.ticks + 1
    local charged, charge_err = budget.charge(instance, {
        operator = operator,
        event_id = payload.trace_event_id,
        cost = {steps = 1},
        source = "body_tick",
        truth_status = "runtime_confirmed",
    })
    if not charged then
        return nil, charge_err
    end
    if operator == "☵" and type(payload.loss) == "table" then
        local applied, apply_err = loss.apply(instance, {
            operator = "☵",
            event_id = payload.trace_event_id,
            amount = loss.from_encode_loss(payload.loss),
            kind = payload.loss.kind,
            source = "encode_loss",
            detail = payload.loss,
            truth_status = "runtime_confirmed",
        })
        if not applied then
            return nil, apply_err
        end
    elseif operator == "☴" and payload.substrate_called == true then
        return nil, "vertical fixture harness does not fake substrate economics"
    end

    local effects = event_refs(instance, trace_start)
    local frame, frame_err = camera.capture(instance, {
        operator = operator,
        revisions_before = revisions_before,
        source_event_refs = effects,
        effect_refs = effects,
        budget_event_refs = ledger_refs(
            "budget:event:",
            budget_start,
            #(instance.runtime.budget.events or {})
        ),
        loss_event_refs = ledger_refs(
            "loss:event:",
            loss_start,
            #(instance.tension.loss_events or {})
        ),
        budget_before = budget_before,
        loss_before = loss_before,
        progress_before = progress_before,
        evidence_fingerprint_before = fingerprint_before,
    })
    if not frame then
        return nil, frame_err
    end

    self.result.ticks[#self.result.ticks + 1] = {
        index = #self.result.ticks + 1,
        operator = operator,
        payload = payload,
        trace_event_id = tick_event.id,
        runtime_frame_ref = frame.trace_event_id,
        readiness = execution.readiness,
    }
    if operator == "△" then
        local manifested, manifest_err = packet.manifest_packet(instance, payload)
        if not manifested then
            return nil, manifest_err
        end
        self.result.stop_reason = "manifested"
        self.result.final_status = instance.status
    end
    return payload
end

return vertical_life
