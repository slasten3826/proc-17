# Qualified ENCODE And CHOOSE Pressure Blueprint v0

Status:

```text
crystall
implementation authorized in bounded steps 5-8
default authority promotion forbidden
date: 2026-07-19
```

Source table:

```text
docs/01_table/yellowprints/qualified_encode_choose_pressure_yellowprint.v0.md
```

Parent executable contract:

```text
docs/02_crystall/blueprints/pressure_need_and_action_composition.v0.md
```

## 1. Purpose

Extend `pressure.qualified_need.v0` with two exact causal chains:

```text
strict observed structure proposal
  -> encoding_need
  -> pressure.action_plan mode=structure_formation
  -> ☵ exact form/map/loss effect

observed declared alternative set
  -> choice_need
  -> pressure.action_plan mode=alternative_collapse
  -> ☳ exact selection/suppression/loss effect
```

This blueprint does not authorize:

```text
natural-language heuristic ENCODE as qualified evidence
caller-owned action scope or ranking
automatic ☳ after every ☵
numeric pressure weights
default tree authority
```

## 2. Implementation Boundary

Predicted modules:

```text
runtime/structure_inspection.lua     strict proposal and formation proof reader
runtime/qualified_pressure.lua       encoding/choice witness producers
runtime/pressure_action.lua          two new exact action modes
core/packet.lua                      event right and regime defaults
runtime/field.lua                    exact formation metadata on identity map
organs/encode.lua                    structure_formation readiness/effect
organs/choose.lua                    alternative_collapse readiness/effect
runtime/operator_registry.lua        exact readiness dispatch
runtime/tension_runner.lua           effect verifier receives Packet state
```

The first implementation packet is intentionally split:

```text
steps 5-6 implement structure formation and ENCODE controls
steps 7-8 implement alternative collapse and CHOOSE controls
```

Relation-guided ENCODE remains a separate existing mode. Generic semantic-text
ENCODE and current CHOOSE remain compatibility paths until their exact modes
are explicitly selected.

## 3. Static Contract Identities

Required ids:

```text
proposal protocol       packet.structure.proposal.v0
adapter policy          encode.packet_structure.v0
receiver contract       calm.work_structure.v0
formation protocol      field.structure_formation.v0
choice consumer         calm.singular_focus.v0
choice policy           formation_order.v0
```

The ids are body registry values, not arbitrary caller strings.

Predicted Packet defaults:

```lua
regime.encoding = {
  policy_id = "encode.packet_structure.v0",
  receiver_contract_id = "calm.work_structure.v0",
  bounds = {
    max_source_units = 1,
    max_output_units = 128,
    max_loss_log_entries = 32,
  },
}

regime.choice = {
  policy_id = "formation_order.v0",
  consumer_contract_id = "calm.singular_focus.v0",
  bounds = {
    max_selected = 1,
    max_killed_sample = 8,
  },
}
```

Tests may ablate a registered contract before life begins. Runtime action
options cannot enable or replace a contract.

## 4. Strict Proposal Normalization

`runtime/structure_inspection.lua` owns one pure normalizer:

```lua
structure_inspection.normalize(value)
  -> normalized_envelope, nil
  -> nil, typed_reason
```

Accepted transports:

```text
direct Lua table with protocol_version
carrier.structured table with protocol_version
strict JSON in carrier.text
```

No markdown extraction, section heuristics, keyword guessing, or fallback to
`logic.encode` is allowed in this mode.

Normalized envelope:

```lua
{
  protocol_version = "packet.structure.proposal.v0",
  receiver_contract_id = "calm.work_structure.v0",
  shape = "work_sequence" | "work_hierarchy"
        | "alternative_set" | "artifact_set",
  items = {
    {
      key = string,
      kind = string,
      value = string | number | boolean | table,
      source_keys = string[],
    },
  },
  edges = {
    {from_key = string, to_key = string, relation = string},
  },
  choice = {kind = "mutually_exclusive"} | nil,
}
```

Normalization requirements:

```text
unknown top-level/item/edge/choice keys reject
item keys are unique and non-empty
item kind is non-empty
edge endpoints resolve
choice is legal only for alternative_set
alternative_set requires choice.kind=mutually_exclusive
other shapes reject choice metadata
empty item arrays reject
normalized JSON is deterministic
```

Fingerprint:

```text
structure-proposal:<canonical normalized JSON>
```

## 5. Pure Structure Inspection

```lua
structure_inspection.derive(instance, options)
  -> {
       protocol_version = "structure.inspection.v0",
       candidates = {},
       missing = {},
       current = {},
       diagnostics = {},
       qualification_status = string,
       event_truth_status = "runtime_confirmed",
     }
```

Candidate scope:

```text
current generation
kind=substrate_response
activation live or selected
strict valid normalized proposal
receiver equals enabled Packet regime receiver
semantic upper coverage exists at exact current version
one source unit maximum in v0
```

Candidate record:

```lua
{
  source_unit_id = string,
  source_version = integer,
  source_creation_event_ref = string,
  source_observation_event_ref = string,
  source_content_truth_status = string,
  exact_ref = "coverage:field_unit:<id>:<version>",
  envelope = normalized_envelope,
  envelope_fingerprint = string,
  receiver_contract_id = "calm.work_structure.v0",
  requested_shape = string,
  formation_status = "missing" | "current" | "repair",
  formation_event_ref = string | nil,
}
```

Diagnostics include:

```text
unsupported_structure_proposal
receiver_not_enabled
source_semantic_observation_missing
incomplete_structure_scope
malformed_structure_formation
formation_repair_pressure
```

Ordinary prose is diagnostic, not an exception and not a pressure witness.

## 6. Exact Formation Proof

One exact current proof requires the composite:

```text
structure_formation trace event
+ linked non-shadow identity map
+ linked crystallization/loss event
+ every formed field unit at a resolvable current id
```

The formation event schema is:

```lua
{
  type = "structure_formation",
  operator = "☵",
  truth_status = "runtime_confirmed",
  payload = {
    protocol_version = "field.structure_formation.v0",
    source = {
      unit_id = string,
      version = integer,
      observation_event_ref = string,
      content_truth_status = string,
    },
    receiver_contract_id = "calm.work_structure.v0",
    requested_shape = string,
    envelope_fingerprint = string,
    formed_unit_ids = string[],
    formed_unit_versions = {[id] = 1},
    identity_map_ref = string,
    identity_map_event_ref = string,
    crystallization_event_ref = string,
    loss_record_ref = string,
    choice_contract = {
      consumer_contract_id = "calm.singular_focus.v0",
      ordered_alternative_ids = string[],
      max_selected = 1,
      selection_policy_id = "formation_order.v0",
      selection_basis_truth_status = string,
    } | nil,
    event_truth_status = "runtime_confirmed",
    content_truth_status = string,
  },
}
```

`truth_status=runtime_confirmed` confirms formation mechanics. It does not
promote source content beyond `content_truth_status`.

## 7. `encoding_need` Witness

`runtime/qualified_pressure.lua` adds a pure producer after relation and upper
inspection:

```lua
qualified.structure_witnesses(instance, context, options)
```

It emits one witness per missing v0 candidate only when ☵ is adjacent:

```lua
{
  protocol_version = "pressure.witness.v1",
  kind = "encoding_need",
  target_operator = "☵",
  causal_class = "causal_affordance",
  source_domain = "packet_structure_proposal",
  scope_refs = {candidate.exact_ref},
  provenance_refs = {
    candidate.source_creation_event_ref,
    candidate.source_observation_event_ref,
    "consumer:calm.work_structure.v0",
  },
  consumer_contract = "calm.work_structure.v0",
  requested_shape = candidate.requested_shape,
  envelope_fingerprint = candidate.envelope_fingerprint,
  action_plan = structure_formation_action,
}
```

Unsupported, unobserved, current, repair, or truncated candidates emit no
encoding witness.

## 8. `structure_formation` Action Plan

Add mode:

```text
mode=structure_formation
target=☵
option root=encode
effect type=encode_organ_payload
mergeable=false in v0
```

Canonical options:

```lua
{
  encode = {
    structure_input = {
      source_unit_id = string,
      source_version = integer,
      envelope_fingerprint = string,
      receiver_contract_id = "calm.work_structure.v0",
      requested_shape = string,
      adapter_policy_id = "encode.packet_structure.v0",
      bounds = {
        max_output_units = integer,
        max_loss_log_entries = integer,
      },
    },
  },
}
```

Canonical precondition:

```lua
object_versions = {[source_unit_id] = source_version}
```

Canonical scope:

```text
coverage:field_unit:<source_unit_id>:<source_version>
```

`pressure_action.build/validate` must cross-check source id/version, exact
scope, receiver, shape, adapter, and positive integer bounds.

The mode is not mergeable. Two independent missing structure proposals create
typed `ambiguous_action` until multi-source policy is designed.

## 9. ENCODE Readiness

`organs.encode.readiness(instance, options)` dispatch order:

```text
relation_input  -> existing relation-guided readiness
structure_input -> exact structure readiness
otherwise       -> compatibility semantic-text readiness
```

Exact readiness re-runs pure inspection/resolve and requires:

```text
source id/version current
activation live or selected
strict envelope fingerprint unchanged
receiver/shape/policy/bounds equal action
semantic coverage exact
formation status missing
```

Output:

```lua
{
  operator = "☵",
  ready = boolean,
  reason = "structure_formation_ready" | typed_reason,
  source_refs = {exact_source_ref},
  event_truth_status = "runtime_confirmed",
}
```

## 10. ENCODE Effect

Exact ENCODE performs in one actor tick:

```text
re-read and fingerprint source envelope
plan deterministic output ids and identity map id
project bounded items/edges without semantic heuristics
crystallize CALM with visible loss
add canonical output units
record non-shadow identity map
append structure_formation event
return one encode_organ_payload
```

Required payload fields:

```lua
{
  kind = "encode_organ_payload",
  mode = "structure_formation",
  formation_basis = "packet_structure",
  structure_formation = formation_payload,
  identity_map = identity_map_record,
  loss = complete_loss,
  work_units = table,
  trace_event_id = crystallization_event_id,
  formation_event_id = structure_formation_event_id,
  effect_scope_refs = {exact_source_ref},
  truth_status = "runtime_confirmed",
  content_truth_status = source_content_truth_status,
}
```

`pressure_action.verify_effect(plan, payload, instance)` must additionally
prove for this mode:

```text
payload contract equals action contract
formation event resolves and equals payload
crystallization/loss ref resolves
identity map resolves, is non-shadow, and maps exact source to every output
all output units resolve at declared versions and were created by ☵
choice contract, when present, names only output ids in frozen order
```

Malformed effect remains a loud harness invariant.

## 11. ENCODE Loss

Treatment loss remains visible and provisional:

```text
kind=structure_projection_loss
policy_id=encode.packet_structure.v0
calculation_status=estimated_policy
input_count=envelope item count
output_count=formed unit count
omitted_count=bounded omissions
loss_log=bounded addressable omitted item records
loss_percentage=declared shape policy plus omission ratio, clamped 0..1
```

Shape policy v0 may preserve existing CHESED estimates:

```text
work_sequence   0.25
work_hierarchy  0.30
alternative_set 0.40
artifact_set    0.15
```

The Packet runtime-confirms applying this declared estimate. The estimate is
not measured promotion evidence.

## 12. `choice_need` Witness

Implementation is authorized for steps 7-8, not steps 5-6.

The qualifier derives a set only from a current exact formation with
`choice_contract`, resolves current field versions/activations, and requires
field-native coverage of all eligible members.

Witness/action schemas are exactly those selected in the source table:

```text
kind=choice_need
class=blocking_demand
mode=alternative_collapse
target=☳
scope=all exact current eligible alternative refs
policy=formation_order.v0
max_selected=1
```

Pressure derivation does not include selected ids.

## 13. `alternative_collapse` Action And Effect

Implementation is authorized for steps 7-8, not steps 5-6.

Action options:

```lua
choose.choice_input = {
  choice_set_ref = string,
  alternative_ids = string[],
  alternative_versions = {[id] = integer},
  max_selected = 1,
  selection_policy_id = "formation_order.v0",
  max_killed_sample = integer,
}
```

☳ selects the first current eligible id in frozen formation order, suppresses
all other operands, records pre/post versions and loss, and preserves complete
suppressed ids even when killed detail is sampled.

One or zero eligible members produce no qualified witness or action.

## 14. Exact Scope Law

For both modes:

```text
witness operand refs
== action operand refs
== readiness operand refs
== effect operand refs
```

Post-action object versions are consequences linked to the effect event. They
do not replace pre-action operand refs.

## 15. Shadow And Compatibility Law

```text
pressure_policy not qualified_need_v0 -> no new producer is read
router_mode shadow -> qualified records cannot alter live route or physics
relation_formation mode -> unchanged behavior and tests
no exact structure_input -> old semantic-text ENCODE remains callable
no exact choice_input -> old CHOOSE remains callable
```

Compatibility behavior cannot count as qualified promotion evidence.

## 16. Required ENCODE Controls

Permanent tests for steps 5-6:

```text
plain prose produces diagnostic and no encoding witness
unobserved strict proposal produces upper need, not encoding need
observed strict proposal produces one stable exact encoding action
disabled receiver removes pressure while proposal remains
shadow identity map cannot discharge exact need
exact action reaches ENCODE without caller structure scope
caller override fails loudly
structure formation writes CALM, units, non-shadow map, event, and loss
effect verifier rejects missing map/loss/output/ref
successful effect discharges same source version
unrelated mutation does not re-arm
new exact source version/source unit creates a new witness
relation-guided and semantic-text controls remain green
qualified shadow ablation leaves live physics unchanged
tree treatment trace reaches ▽ -> ☴ -> ☵ -> ☴ without fixture route scope
```

## 17. Required CHOOSE Controls

Permanent tests for steps 7-8 are inherited from C0-C13 and P0-P9 in the
source table. They are not acceptance requirements for steps 5-6.

## 18. Failure Classes

```text
unsupported proposal/disabled receiver -> typed diagnostic, no pressure
missing observation -> upper need, no encoding/choice need
no qualified need -> typed composition result
stale action precondition -> loud invariant before organ mutation
expected organ readiness false -> candidate excluded before commit
malformed effect after execution -> loud harness invariant
external capability failure -> typed Packet effect failure
identity/budget mortality -> Packet death
```

Lua defects, forged route evidence, stale exact actions, and malformed internal
effects must never be converted into graceful Packet death.

## 19. Acceptance

Steps 5-6 are complete only when:

```text
strict inspection is pure and deterministic
encoding witness has one named consumer and exact observed source version
route action owns source, shape, policy, and bounds
ENCODE writes one resolvable composite formation proof
only that proof discharges the need
new formed units create ordinary upper observation need
old ENCODE modes remain unchanged
all matched ENCODE controls and full regression pass
shadow physics remains unchanged
```

Steps 7-8 require a separate observation and acceptance pass for CHOOSE.
