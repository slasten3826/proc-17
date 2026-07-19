# Qualified ENCODE And CHOOSE Pressure Yellowprint v0

Status:

```text
table
bounded ☵/☳ treatment
feeds crystall, not runtime authority
date: 2026-07-19
```

Source chaos:

```text
docs/00_chaos/qualified_encode_choose_pressure_notes_2026-07-19.md
```

Parent physical contracts:

```text
docs/02_crystall/blueprints/operator_tree_physics.v0.md
docs/02_crystall/blueprints/pressure_need_and_action_composition.v0.md
docs/03_manifest/pressure_need_and_action_composition_treatment.v0.md
```

## 0. Selected Decisions

```text
D1 relation-guided ENCODE remains the qualified specialized ENCODE path
D2 generic semantic-text ENCODE remains compatibility-only
D3 production generic ENCODE reads an exact current field scope, never
   concatenated unbounded CHAOS
D4 source existence alone creates no encoding need
D5 the first generic receiver is calm.work_structure.v0
D6 the receiver accepts only a strict packet.structure.proposal.v0 envelope
   from a semantically observed substrate_response field unit
D7 the envelope may be transported as a table in fixtures or strict JSON in
   substrate text; prose/keyword inference does not qualify
D7a the proposal may request a registered receiver and declare mutually
    exclusive alternatives, but only Packet.regime enables the receiver,
    collapse consumer, cardinality, policy, and bounds
D8 exact formation evidence is one immutable structure_formation event plus
   one linked identity map and complete loss record
D9 a choice set exists only when that formation explicitly declares one
D10 the first collapse consumer is calm.singular_focus.v0 with max_selected=1
D11 the first body selection policy is formation_order.v0
D12 formation order is frozen by ☵; caller semantic_ranking after route commit
    is forbidden
D13 pressure derivation names the exact set and policy but does not preselect
    the winner
D14 choice pressure requires current observation coverage of the possibility set
D15 confirmation is not a need, not a ☳ execution, and creates no choice loss
D16 exact referent changes re-arm; unrelated global revision changes do not
D17 missing/released formation output is typed formation_repair_pressure and
    remains deferred rather than silently replaying the same ENCODE action
D18 count-based CHOOSE loss remains an explicit provisional proxy
D19 shadow route/economics isolation remains mandatory
D20 full-tree authority promotion and the 38-direction corpus remain deferred
```

## 1. Contract Precedence And Archaeology

| Prior claim | v0 disposition | Reason |
|---|---|---|
| `☵` creates form and records loss | retained | Core ENCODE law |
| `☳` collapses explicit alternatives | retained | Core CHOOSE law |
| bad choice usually means bad field | retained | Pair causality |
| `☵` reads CHAOS material under substrate constraints | compatibility projection only | Canonical production operand is now a bounded field view |
| `☵` chooses hierarchy/sequence/category/teaching/language from prose | compatibility-only | Keyword inference cannot qualify body pressure |
| fallback to language | not production evidence | Coding body needs a named machine receiver |
| semantic ranking may be passed to `☳` | compatibility-only | Qualified action scope and policy must be committed by the body |
| one item returns confirmation | retained for direct compatibility calls | Qualified router emits no CHOOSE need/action/loss |
| killed alternatives remain visible | retained and strengthened | Exact ids, versions, full suppressed id set, bounded detail sample |
| count ratio is choice loss | provisional proxy | Potential mass and separation remain unimplemented |

The older pair documents remain useful archaeology. This table amends their
production-pressure interpretation; it does not delete their tests or
compatibility code.

## 2. Five-Layer Boundary For The Pair

| Layer | ENCODE question | CHOOSE question | Authority |
|---|---|---|---|
| Fact | Which exact observed source/version and strict envelope exist? | Which exact formation and current alternative versions exist? | Field plus immutable trace |
| Coverage | Was the source observed with a compatible class? | Was the current possibility set observed after formation? | Upper object coverage |
| Need | Does a registered receiver still lack its required form? | Does a registered consumer require fewer live alternatives? | Pure qualifier plus static contract registry |
| Action | Which exact source/form policy may ☵ execute? | Which exact set/cardinality/policy may ☳ execute? | Derived `pressure.action_plan` carried by route |
| Effect | Did form, map, loss, and optional choice contract appear? | Did one event select/suppress the exact operands and record loss? | Organ plus field/body APIs |

Invalid collapses:

```text
source exists == encoding_need
strict envelope parsed == content truth
CALM exists == current exact formation
two units exist == choice_need
formation order == runtime truth about semantic quality
organ visit == discharge
route selection == semantic CHOOSE
```

## 3. Existing And New Runtime Surfaces

| Surface | Current state | v0 use |
|---|---|---|
| `field.units` | Deterministic ids, versions, activation, provenance | Sole current operand state |
| upper object coverage | Exact id/version/class coverage | Gates source formation and set collapse |
| `field.identity_maps` | Exact ids, but generic maps lack source versions and are shadow-only | Linked remap proof; version proof lives in formation event |
| trace crystallization | Immutable accepted form/loss boundary | Part of formation effect bundle |
| trace relation formation | Exact specialized ☵ proof | Preserved unchanged |
| `calm.current` | Mutable compatibility projection | Reader output, never sole qualified witness |
| `regime.encoding` | Existing policy/bounds slot, mostly unused | Enables receiver, selects registered adapter policy and body-owned bounds |
| `regime.choice` | Existing policy/bounds slot, mostly unused | Enables collapse consumer, selects policy/cardinality/sample bounds |
| boundary choices | Append-only projected choice records | Choice consequence/history, not live-set authority |
| action/witness trace | Immutable route evidence | Carries exact invocation into target organ |

No mutable `choice_sets` store is introduced. A current possibility set is
derived from:

```text
immutable structure_formation event
+ current field units/versions/activations
+ current exact upper coverage
```

## 4. First Registered Receiver Contract

Selected v0 receiver:

```lua
{
  contract_id = "calm.work_structure.v0",
  accepted_source_kinds = {substrate_response = true},
  required_source_observation_class = "semantic",
  accepted_envelope_protocol = "packet.structure.proposal.v0",
  accepted_shapes = {
    work_sequence = true,
    work_hierarchy = true,
    alternative_set = true,
    artifact_set = true,
  },
  output_reader = "calm work and structure readers",
}
```

This is a registered body contract. The substrate may name it in a proposal,
but an unknown contract id creates a typed diagnostic, not pressure.

`regime.encoding.policy_id` selects the strict adapter. Its default treatment
value is predicted as:

```text
encode.packet_structure.v0
```

The body-owned per-Packet selection is predicted as:

```lua
regime.encoding = {
  policy_id = "encode.packet_structure.v0",
  receiver_contract_id = "calm.work_structure.v0",
  bounds = {...},
}
```

An envelope can request this receiver, but cannot enable it. A requested
receiver must equal the enabled regime contract or remain a typed unsupported
proposal.

`regime.encoding.bounds` owns `max_source_units`, `max_output_units`, and
loss-log bounds. Caller options may narrow a run only before birth/configuration;
they cannot replace a committed action scope.

## 5. Strict Structure Proposal Envelope

Logical schema to crystallize:

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
      source_keys = string[] | nil,
    },
  },
  edges = {
    {from_key = string, to_key = string, relation = string},
  } | nil,
  choice = {
    kind = "mutually_exclusive",
  } | nil,
}
```

Envelope rules:

```text
keys are unique within the envelope
every edge endpoint resolves to an item key
choice.kind=mutually_exclusive is legal only for shape=alternative_set
alternative_set requires at least one item
non-alternative shapes must not declare choice metadata
unknown fields/protocols/contracts are typed unsupported input
body creates canonical ids and source refs; proposal keys are not field ids
content remains semantic_proposal unless stronger source truth already exists
parsing/validation act is runtime_confirmed
proposal choice metadata does not select consumer, cardinality, or policy
```

Transport is not semantics:

```text
fixture may carry the envelope as a Lua table
live substrate may carry strict JSON text
both normalize to the same validated logical envelope
ordinary prose does not fall through to heuristic structure in qualified mode
```

## 6. ENCODE Need Derivation

### 6.1 Source candidate

A source candidate is one current-generation field unit satisfying all rows:

| Gate | Required state |
|---|---|
| Kind | `substrate_response` |
| Activation | `live` or `selected` |
| Content | strict decodable envelope |
| Receiver | known `calm.work_structure.v0`, enabled by `regime.encoding` |
| Coverage | semantic coverage at exact current unit version |
| Bounds | complete source scope, no truncation |
| Existing proof | no current non-shadow formation for same source version, receiver, and shape |

The first treatment uses one source unit per structure formation. Multi-source
formation remains a later extension; relation-guided ENCODE keeps its existing
multi-relation mode.

### 6.2 Need state table

| State | Qualified result | Other result |
|---|---|---|
| No source unit | no `encoding_need` | none |
| User prompt exists, no semantic observation | no `encoding_need` | upper observation need |
| `substrate_response` exists but current version lacks semantic coverage | no `encoding_need` | upper observation need |
| Covered response contains ordinary prose | no `encoding_need` | `unsupported_structure_proposal` diagnostic |
| Covered response names unknown protocol/receiver/shape | no `encoding_need` | typed unsupported diagnostic |
| Covered strict envelope, no exact production formation | one `encoding_need` | none |
| Only coarse/shadow identity map exists | one `encoding_need` | compatibility map ignored |
| Exact production formation exists | no `encoding_need` | discharged |
| Unrelated field unit changes | no re-arm | prior discharge remains |
| Exact source unit version changes | one new `encoding_need` | old proof remains historical |
| Formation output missing/released | no replay in v0 | `formation_repair_pressure`, promotion blocker |

### 6.3 Qualified ENCODE witness

```lua
{
  kind = "encoding_need",
  target_operator = "☵",
  causal_class = "causal_affordance",
  source_domain = "packet_structure_proposal",
  consumer_contract = "calm.work_structure.v0",
  source_unit_ids = {source_id},
  source_versions = {[source_id] = source_version},
  requested_shape = envelope.shape,
  envelope_fingerprint = string,
  scope_refs = {exact_source_ref},
  provenance_refs = {
    source_creation_event,
    exact_semantic_observation_event,
    "consumer:calm.work_structure.v0",
  },
}
```

Witness identity includes the receiver contract, shape, envelope fingerprint,
exact source refs, and provenance refs. The body must not multiply pressure by
the number of envelope items.

## 7. Structure Formation Action

Predicted new action mode:

```text
structure_formation -> ☵
```

Body-owned options:

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

The envelope itself is not copied into route options. ENCODE re-reads it from
the exact source unit after precondition validation and verifies the frozen
fingerprint.

Required preconditions:

```text
Packet id and generation match
source unit exists at exact version
source activation remains live/selected
semantic observation coverage still matches that version
receiver and adapter contracts remain registered
envelope fingerprint remains identical
action bounds equal the committed body-owned bounds
```

Caller overrides of `structure_input`, limits, receiver, shape, source, or
adapter are invariant failures under qualified execution.

## 8. Structure Formation Effect And Discharge

Predicted immutable event:

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
    crystallization_event_ref = string,
    loss_record_ref = string,
    choice_contract = {
      consumer_contract_id = "calm.singular_focus.v0",
      ordered_alternative_ids = string[],
      max_selected = 1,
      selection_policy_id = "formation_order.v0",
      selection_basis_truth_status = string,
    } | nil,
  },
}
```

Formation effect bundle:

| Required effect | Proof |
|---|---|
| Accepted CALM crystallization | crystallization event ref |
| Canonical output units | exact ids, version 1, created by ☵ in same tick |
| Exact remap | identity map links source id to all output ids |
| Source version | formation event freezes source id/version |
| Receiver suitability | registered receiver id and requested shape |
| Visible loss | linked loss record including omissions |
| Optional choice set | choice contract plus ordered alternative output ids |
| Same operand scope | payload `effect_scope_refs` equals action source refs |

Discharge predicate:

```text
all required effects exist in the same ☵ tick
AND all references resolve
AND identity map is non-shadow
AND source version/receiver/shape/fingerprint equal the witness
```

A CALM write, a shadow map, a standalone loss record, or an organ visit cannot
discharge `encoding_need` by itself.

## 9. Formation Re-arm And Repair Boundary

| Change | Result |
|---|---|
| Same exact source/contract/shape remains | no need |
| Unrelated object changes | no need |
| Exact source version changes | fresh `encoding_need` |
| Receiver or requested shape changes through a new strict envelope version | fresh `encoding_need` |
| New source unit arrives | independently qualified candidate |
| Output unit is selected/suppressed but still exists | formation remains valid |
| Output unit is dissolved/missing | `formation_repair_pressure`, deferred |
| Formation event/map is malformed | invariant diagnostic, no silent re-encode |

The repair boundary prevents an automatic `☵ -> ☷ -> ☵` replay from hiding a
structural conflict. A later repair treatment may target ☵ with residue and a
new contract, but it is not this initial encoding need.

## 10. Choice Contract And Live Set

Selected first collapse consumer:

```lua
{
  contract_id = "calm.singular_focus.v0",
  accepted_formation_protocol = "field.structure_formation.v0",
  accepted_shape = "alternative_set",
  max_selected = 1,
  selection_policy_id = "formation_order.v0",
}
```

The corresponding body-owned regime selection is predicted as:

```lua
regime.choice = {
  policy_id = "formation_order.v0",
  consumer_contract_id = "calm.singular_focus.v0",
  bounds = {
    max_selected = 1,
    max_killed_sample = integer,
  },
}
```

The strict proposal only declares `choice.kind=mutually_exclusive`. ☵ may
materialize the choice contract above only when the Packet regime enables the
matching registered consumer. The substrate does not choose cardinality or
policy.

The formation event freezes:

```text
ordered alternative ids
consumer contract
max selected cardinality
selection policy id
selection basis truth status
```

The source may propose order, but the semantic quality of that order retains
its source truth status. ☵ runtime-confirms only that it formed and froze the
declared order.

Current live set derivation:

```text
start from ordered ids in the immutable formation
resolve every id in runtime.field
require current generation
read exact current versions
eligible = activation live or selected
suppressed/dissolved members remain history, not current alternatives
require exact field-native observation coverage for every eligible version
```

Incomplete resolution or coverage produces a typed diagnostic/observation
need, not partial choice pressure.

## 11. CHOOSE Need State Table

| State | Qualified result | Reason |
|---|---|---|
| Several unrelated units, no formation set | no `choice_need` | No common possibility provenance |
| Formation shape is sequence/hierarchy/artifact set | no `choice_need` | No collapse contract |
| Alternative set has zero current eligible members | no `choice_need` | Invalid/repair diagnostic |
| Alternative set has one eligible member | no `choice_need` | Confirmation only |
| Alternative set has two members but contract allows two | no `choice_need` | No required collapse |
| Alternative set has two or more eligible members, current versions unobserved | no `choice_need` | Upper observation need first |
| Observed set exceeds `max_selected=1` | one `choice_need` | Named consumer is blocked |
| Set resolution is truncated/incomplete | no `choice_need` | Incomplete-scope diagnostic |
| Prior collapse leaves one selected and others suppressed | no `choice_need` | Discharged |
| Unrelated field unit changes | no re-arm | Set referent unchanged |
| New formation version adds a live alternative | fresh `choice_need` after observation | Set membership changed |

## 12. Qualified CHOOSE Witness And Action

Witness:

```lua
{
  kind = "choice_need",
  target_operator = "☳",
  causal_class = "blocking_demand",
  source_domain = "formation_choice_set",
  consumer_contract = "calm.singular_focus.v0",
  choice_set_ref = structure_formation_event_id,
  alternative_ids = ordered_current_eligible_ids,
  alternative_versions = {[id] = current_version},
  required_max_selected = 1,
  selection_policy_id = "formation_order.v0",
  scope_refs = exact_alternative_refs,
  provenance_refs = {
    structure_formation_event_id,
    choice_consumer_ref,
    exact_field_observation_refs,
  },
}
```

Predicted action mode:

```text
alternative_collapse -> ☳
```

Body-owned options:

```lua
{
  choose = {
    choice_input = {
      choice_set_ref = string,
      alternative_ids = string[],
      alternative_versions = {[id] = integer},
      max_selected = 1,
      selection_policy_id = "formation_order.v0",
      max_killed_sample = integer,
    },
  },
}
```

The action intentionally does not contain `selected_ids`. `☳`, not pressure
derivation, performs selection. Under `formation_order.v0`, it selects the first
currently eligible member in frozen formation order and suppresses the rest.

Qualified execution forbids caller `field`, `semantic_ranking`, pressure,
limits, alternative ids, versions, cardinality, or policy overrides.

## 13. CHOOSE Readiness, Effect And Discharge

Readiness verifies:

```text
formation event and consumer contract resolve
formation is current and non-shadow
all action ids belong to the same declared set
all current versions equal the action versions
all current activations are eligible
current field-native coverage matches every version
eligible count is greater than max_selected
selection policy and bounds are registered
```

Required effect bundle:

```lua
{
  kind = "choose_collapse_payload",
  choice_set_ref = string,
  operand_versions = {[id] = pre_action_version},
  selected_ids = string[],
  suppressed_ids = string[],
  post_versions = {[id] = pre_action_version + 1},
  before_count = integer,
  after_count = 1,
  not_chosen_count = integer,
  killed_alternatives = bounded_sample,
  selection_policy_id = "formation_order.v0",
  selection_basis_truth_status = string,
  loss = table,
  effect_scope_refs = exact_pre_action_refs,
}
```

Discharge requires:

```text
selected + suppressed ids partition the exact operand set
selected count equals 1
suppressed count equals before_count - 1
every activation mutation references the same choice event
every post version is exactly prior version + 1
complete suppressed ids survive killed-detail truncation
choice loss is present and non-zero for real collapse
effect operand refs equal witness/action/readiness refs
```

If any effect is missing, the action is an invariant failure. It must not become
a pretty Packet death or a successful confirmation.

## 14. Confirmation And Choice Loss

| Case | CHOOSE execution | Choice event | Identity loss |
|---|---|---|---|
| 0 eligible alternatives | no | no | 0 |
| 1 eligible alternative | no qualified execution | optional compatibility confirmation only | 0 |
| 2+ alternatives, no collapse consumer | no | no | 0 |
| 2+ alternatives, consumer requires 1 | yes | real collapse | mandatory |

Treatment loss policy:

```text
calculation = not_chosen_count / before_count
calculation_status = provisional_count_proxy
application event = runtime_confirmed
promotion claim = not calibrated to potential mass or separation
```

The event truth status confirms that the body applied the declared proxy. It
does not claim that the proxy is final ProcessLang identity physics.

## 15. Pair Composition And Emergent Eyes

The desired local route is produced by dependencies, not hardcoded rails:

| Current state | Highest qualified need | Target |
|---|---|---|
| Prompt has not been semantically observed | upper observation blocking demand | ☴ |
| Strict observed structure proposal lacks form | encoding causal affordance | ☵ |
| New formed units lack field-native consequence sight | upper observation blocking demand | ☴ |
| Observed declared alternative set blocks singular consumer | choice blocking demand | ☳ |
| Selected/suppressed versions lack consequence sight | upper observation blocking demand | ☴ |

Expected trace for an explicit alternative proposal:

```text
▽ -> ☴ -> ☵ -> ☴ -> ☳ -> ☴
```

Counterexamples:

```text
work_sequence proposal: ▽ -> ☴ -> ☵ -> ☴, no automatic ☳
ordinary prose response: ▽ -> ☴, typed unsupported structure, no ☵
single alternative: ... -> ☵ -> ☴, confirmation/no ☳
already formed exact proposal: no repeated ☵
already collapsed set: no repeated ☳
```

Choice need requires consequence observation. This avoids an equal-class
ambiguity between immediate ☳ and the upper eye after ☵ while preserving the
general topology.

## 16. Scope Equality And Version Transition

ENCODE same-ref law:

```text
witness source refs
== action source refs
== readiness source refs
== effect operand refs
```

CHOOSE same-ref law:

```text
witness pre-action alternative refs
== action alternative refs
== readiness alternative refs
== effect operand refs
```

Post-action refs are separate consequences:

```text
ENCODE outputs new ids at version 1
CHOOSE increments selected/suppressed unit versions by exactly 1
```

They must be linked to the same effect event but must not be substituted for
the original operand scope. This preserves both exact action identity and
honest mutation.

## 17. Reader And Writer Matrix

| Record/fact | Writer | First named reader | Effect/discharge reader |
|---|---|---|---|
| Strict proposal source unit | semantic ☴ | upper coverage and structure qualifier | ENCODE readiness |
| Receiver registry contract | body code registry | structure qualifier | ENCODE readiness/effect verifier |
| Encoding regime policy/bounds | Packet birth/body configuration | qualifier/action builder | ENCODE readiness |
| Encoding witness/action | pressure derivation | composition/tree router | route commit/registry |
| Structure formation event | ☵ | encoding qualifier and choice-set derivation | ENCODE effect verifier |
| Identity map | ☵ | formation resolver/invalidation readers | ENCODE effect verifier |
| Crystallization/loss | ☵ | CALM/loss/runtime/LOGIC readers | ENCODE effect verifier/mortality |
| Choice contract | ☵ structure formation | choice qualifier | CHOOSE readiness |
| Choice regime policy/bounds | Packet birth/body configuration | choice qualifier/action builder | CHOOSE readiness |
| Choice witness/action | pressure derivation | composition/tree router | route commit/registry |
| Choice event | ☳ | live-set, runtime, manifest, observation readers | CHOOSE effect verifier |
| Activation mutation | ☳ through `runtime.field` | live-set and upper coverage | CHOOSE effect verifier |
| Choice loss | ☳ plus tension runner | runtime/manifest/mortality | loss reader |
| Unsupported proposal diagnostic | strict adapter/qualifier | promotion gate and trace report | user/repair planning later |
| Formation repair pressure | formation resolver | promotion gate | deferred repair treatment |

Every new stored event has a reader. Witnesses/actions remain derived per route
and are persisted only as immutable route evidence.

## 18. Matched ENCODE Controls E0-E12

| ID | One-variable state change | Required result |
|---|---|---|
| E0 | No source unit | No encoding witness |
| E1 | Add unobserved response unit | Upper witness, no encoding witness |
| E2 | Observe same version but response is prose | Unsupported diagnostic, no encoding witness |
| E3 | Replace prose with strict valid envelope at a new exact version | One encoding witness and exact action |
| E4 | Keep envelope but use unknown receiver | Unsupported diagnostic, no witness |
| E5 | Add only a shadow/coarse identity map | Same encoding witness remains |
| E6 | Execute exact structure formation | Witness disappears; form/map/loss all exist |
| E7 | Mutate unrelated unit | Witness remains discharged |
| E8 | Mutate exact source to a new valid envelope version and observe it | New witness with new id/version/fingerprint |
| E9 | Forge caller shape/source override | Loud invariant failure before effect |
| E10 | Remove identity map or loss from otherwise successful effect fixture | Discharge verifier rejects |
| E11 | Run relation-guided ENCODE control | Existing action/effect remains unchanged |
| E12 | Run qualified policy under shadow authority | Live route/economics/loss/revisions equal control |

## 19. Matched CHOOSE Controls C0-C13

| ID | One-variable state change | Required result |
|---|---|---|
| C0 | Two unrelated live units | No choice witness |
| C1 | Work-sequence formation with three units | No choice witness |
| C2 | Alternative formation with one unit | Confirmation state, no witness/loss |
| C3 | Alternative formation with two units but no collapse contract | No choice witness |
| C4 | Add singular-focus contract but leave output versions unobserved | Upper witness, no choice witness |
| C5 | Observe exact set versions | One blocking choice witness/action |
| C6 | Stale one operand version after derivation | Readiness rejects before mutation |
| C7 | Execute exact collapse | One selected, all others suppressed, witness disappears |
| C8 | Truncate killed detail sample | Full suppressed ids/count and exact loss remain |
| C9 | Inject caller semantic ranking | Loud invariant failure |
| C10 | Remove one activation effect from fixture | Discharge verifier rejects |
| C11 | Mutate unrelated unit after collapse | Choice remains discharged |
| C12 | Add a new alternative through a new formation and observe it | Fresh choice witness |
| C13 | Router chooses a neighboring glyph only | No boundary choice and no CHOOSE loss |

## 20. Pair And Composition Controls P0-P9

| ID | Corpus life | Required result |
|---|---|---|
| P0 | Strict `work_sequence` proposal | `☴ -> ☵ -> ☴`, no ☳ |
| P1 | Strict observed two-option proposal | `☴ -> ☵ -> ☴ -> ☳ -> ☴` |
| P2 | Same proposal with choice consumer ablated | Stops before ☳ with no choice witness |
| P3 | Same proposal with structure receiver ablated | No ☵ and therefore no ☳ |
| P4 | Same facts, qualified policy shadow on/off | Identical live route and physics |
| P5 | Same facts derived twice without mutation | Stable witness/action ids |
| P6 | After ☵, bypass upper coverage manually | Choice remains unqualified |
| P7 | After ☳, bypass consequence observation | Upper need remains visible |
| P8 | Compatibility semantic-text route | May run under legacy control, never counts as qualified evidence |
| P9 | Action executes target but wrong scope effect is returned | Loud harness invariant |

## 21. False-Green Matrix

| False green | Rejecting control |
|---|---|
| Any unencoded unit votes for ☵ | E0-E2 |
| Prose keyword parser called exact structure | E2/E3 |
| Shadow identity map discharges production need | E5 |
| CALM write alone called ENCODE success | E10 |
| Number of envelope items multiplies pressure | stable single witness assertion E3 |
| Every multi-unit formation becomes a choice set | C1/C3 |
| One alternative invokes ☳ | C2 |
| Unobserved formed units are collapsed | C4/P6 |
| Pressure derivation already chooses selected id | action schema assertion |
| Caller semantic ranking owns collapse | C9 |
| Choice event exists but activations disagree | C10 |
| Killed sample truncation hides actual count | C8 |
| Count proxy called calibrated loss | explicit policy-status assertion |
| Router target selection creates choice loss | C13 |
| Qualified observation changes live shadow physics | E12/P4 |
| Compatibility run counted toward promotion | P8 corpus classification |

## 22. Implementation Sequence Predicted By The Table

This table predicts the next crystall and code sequence:

```text
1. crystallize strict proposal, receiver registry, and formation proof schemas
2. crystallize structure_formation action/readiness/effect verification
3. crystallize choice contract, live-set derivation, and alternative_collapse action
4. extend field identity/formation evidence without changing relation-guided ENCODE
5. implement exact encoding qualifier behind qualified_need_v0
6. implement exact structure formation and E controls
7. implement exact choice qualifier/action and C controls
8. implement P pair corpus and shadow ablation
9. run full regression, mortality, camera, and historical pressure controls
10. manifest treatment and decide the next bounded pressure family
```

No default-authority change appears in this sequence.

## 23. Explicit Deferrals

```text
heuristic natural-language understanding inside ENCODE
qualification of teaching/language compatibility forms
multi-source generic structure formation
numeric pressure weights
potential-mass and separation-calibrated CHOOSE loss
random/stochastic selection policy
LLM-selected routing or caller-selected action scope
formation repair after output dissolution
reopening suppressed alternatives
repository hands and work-unit completion
qualified DISSOLVE and lower-triangle actions
body-owned MANIFEST action
live DeepSeek promotion corpus
full 38-direction corpus
default tree authority
```

## 24. Table Acceptance

This table may feed crystall when all statements remain coherent together:

```text
source fact, observation coverage, encoding need, action, and effect are separate
generic production ENCODE has one named receiver and strict machine envelope
relation-guided ENCODE remains unchanged
formation proof is immutable and has named readers
not every form is a choice set
choice need derives from one exact formation and current unit versions
pressure derivation does not preselect the winner
confirmation cannot create qualified CHOOSE loss
pre-action refs and post-action versions are both preserved
all new records have named readers
matched controls can falsify each claimed discharge/re-arm law
shadow physics remains unchanged
promotion remains explicitly forbidden
```

## Table Decision

The bounded ☵/☳ treatment is coherent enough to crystallize.

Its central equation is:

```text
strict observed proposal + named receiver + missing exact form
  -> encoding_need -> structure_formation

observed declared possibility set + singular consumer + >1 live alternative
  -> choice_need -> alternative_collapse
```

Everything outside those causal chains remains compatibility behavior,
telemetry, typed diagnostic, or deferred pressure.
