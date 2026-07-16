# Packet Body Physics Yellowprint v0

Status:

```text
table
source: docs/00_chaos/full_packet_tree_physics_notes.md
scope: one living Packet body
consumers: Operator Tree Physics, Lineage Mechanics
crystall: docs/02_crystall/blueprints/packet_body_physics.v0.md
```

## 0. Purpose

This table gives every later operator and lineage contract one physical body to
refer to.

It answers:

```text
what is physically inside one living Packet?
```

It does not freeze the final Lua schema. Names below are conceptual addresses.
The crystall may merge or split concrete tables if ownership, lifetime,
provenance, and invalidation remain equivalent.

## 1. Authority Columns

Rows use these source classes:

```text
CANON     ProcessLang operator identity/topology
DECISION  current proc-17 architecture decision
ANCESTOR  mechanism preserved from slop.raw, UPM Packet, or Zig Packet
RUNTIME   behavior already demonstrated in current proc-17 code/tests
DERIVED   assembled consequence requiring crystall and experiment
OPEN      unresolved; must not enter code as an invisible assumption
```

## 2. Scope Boundary

This yellowprint describes:

```text
one packet_id
one generation
one mortal life
one local loss capacity
one local relation momentum field
one append-only life trace
```

It references but does not own:

```text
session grave/compost
substrate session history
lineage budget
parent corpse
NETWORK@▽ birth machinery
```

Those belong to the Lineage Mechanics table.

## 3. Conceptual Body Equation

```text
P_t = <I, Z, E_raw, E, M, C, S, O, Q, H, L, B, Tau, T, X>
```

| Symbol | Conceptual address | Meaning | Storage class |
|---|---|---|---|
| `I` | identity/header | Packet and generation identity, status, current position | stored, mostly immutable |
| `Z` | potential field | Task-shaped units that can still become several forms | stored, mutable |
| `E_raw` | transient relations | What ☰ recognized in the current field view | stored snapshot, short-lived |
| `E` | active relations | Current relation view used by living operators | stored/derived, mutable |
| `M` | relation momentum | Inertia of recurring relations, sole owner ☱ | stored, mutable, current life only |
| `C` | CALM structures | Encoded, addressable, potentially executable form | stored, mutable by bounded operations |
| `S` | scalars | Operator regime, thresholds, recurrence phase, environmental controls | stored, mutable |
| `O` | observations | Bounded readings from ☴ and ☱ | append-only records plus derived freshness |
| `Q` | constraints/evidence | Rules, verdicts, tool effects, and runtime confirmations | append-only evidence plus active views |
| `H` | attached history view | Bounded immutable projection from lineage/session storage | stored projection, read-only |
| `L` | loss ledger | Irreversible identity cost paid by this Packet | append-only ledger plus derived totals |
| `B` | local budget ledger | Runtime fuel limit, spending, and remaining capacity | append-only costs plus derived totals |
| `Tau` | pressure snapshot | Per-edge gradient derived for one tick | derived cache, immediately stale |
| `T` | life trace | Events and topology transitions of this Packet | append-only |
| `X` | terminal boundary | Manifest, death, corpse source, and residue | write-once terminal state |

Source:

```text
Z/E_raw/E/M/S/L: ANCESTOR, adapted from Packet mathematics
C and coexisting CHAOS/CALM: ANCESTOR, adapted from Zig Packet
O split into two eyes: DECISION
H and lineage refs: DECISION/RUNTIME
Tau derived rather than authoritative: DERIVED
```

## 4. Identity And Header Table

| Field | Meaning | Writer | Readers | Lifetime | Mutation law | Current mapping | Source |
|---|---|---|---|---|---|---|---|
| `protocol_version` | Body contract version | Packet constructor | all body modules, storage | Packet life and corpse | immutable | `packet.protocol_version` | RUNTIME |
| `packet_id` | Identity of one mortal body | Packet constructor | trace, grave, lineage, UI | forever in records | immutable | `packet.id` | RUNTIME |
| `lineage_id` | Identity of the continuing task process | lineage ingress | trace, budget, grave, lineage runner | lineage | immutable in Packet | missing | DECISION |
| `generation` | Ordinal life within lineage | lineage ingress | trace, carrier, audits | Packet life and corpse | immutable | missing | DECISION |
| `parent_packet_id` | Direct parent body | lineage ingress | audit, grave, carrier | Packet life and corpse | immutable | `parent_id` is partial ancestor | DECISION |
| `parent_corpse_id` | Exact corpse that produced birth carrier | lineage ingress | lineage audit | Packet life and corpse | immutable | missing | DECISION |
| `substrate_session_id` | Declared substrate continuity carrier | session/substrate adapter | observation, lineage experiments | Packet life | immutable reference | missing | DECISION |
| `status` | `born/running/dying/dead` plus manifest boundary state | Packet lifecycle only | every mutator, UI, lineage | Packet life | monotonic; dead is final | `packet.status` | RUNTIME |
| `current_operator` | Actual current Tree position | Packet runner before each tick | operator, router, trace, death | current tick | changes only by validated transition | `packet.operator`, not advanced correctly yet | RUNTIME GAP |
| `current_tick` | Body clock | Packet runner | observations, freshness, budget, trace | Packet life | monotonic | `physis.clock.ticks` | RUNTIME |
| `topology_version` | Canon used to validate walk | Packet constructor | router, trace validator, audits | Packet life | immutable | `packet.topology` | RUNTIME |
| `work_mode` | Plan/build behavior policy | ingress/session | substrate prompt, logic, manifest | Packet life or explicit change | policy-controlled | metadata/options | RUNTIME |

Identity invariants:

```text
packet_id never changes
generation never changes inside one Packet
current_operator must match the tick being executed
status never moves out of dead
parent identity is a reference, never a copied body
```

## 5. Potential Unit Table

`Z` is not a hash, string, or mandatory tensor. It is a task-shaped collection
of addressable potential units.

### 5.1 Minimum unit axes

| Axis | Meaning | Required in v0 crystall? | Writer | Reader | Source |
|---|---|---:|---|---|---|
| `id` | Identity local to Packet generation | yes | ▽ or ☵ remap | every relation/form operator | DERIVED |
| `carrier` or `carrier_ref` | Packet-native material or external reference | yes | ▽, ☴ sensor append, ☷ residue release, ☵ | organ selected by `kind` | DERIVED |
| `kind` | Prompt fragment, file, symbol, requirement, hypothesis, diagnostic, patch, test, residue, etc. | yes | creating operator | organ/capability registry | DERIVED |
| `phase` | `chaos`, `calm`, or `residue` view | yes | ▽/☵/☷ | pressure derivation and organs | DERIVED |
| `activation` | Remaining potential/weight | yes | ▽ initializes, ☳ modulates | ☰, ☵, ☳, pressure derivation | ANCESTOR/DERIVED |
| `state` | live, consumed, suppressed, dissolved, invalidated | yes | ☵/☳/☷/☶ | every reader | DERIVED |
| `source_refs` | Provenance into prompt, observation, artifact, parent carrier, or prior unit | yes | creating/mutating operator | trace, truth, loss, manifest | RUNTIME/DERIVED |
| `content_truth_status` | Epistemic status of represented content | yes | source boundary/body evidence | readers and manifest | RUNTIME |
| `event_truth_status` | Status of the event that produced the unit | yes | body event writer | audits/readers | DERIVED |
| `generation` | Identity scope | yes | birth/remap | lineage and trace | DECISION |
| `version` | Referent version used for freshness/invalidation | likely | body mutation layer | eyes, evidence, relations | DERIVED |

### 5.2 Legal unit writers

| Writer | Legal mutation | Illegal mutation |
|---|---|---|
| `▽ FLOW` | Create newborn potential units from ingress | Reuse parent living units |
| `☴ OBSERVE` | Append a sensor/substrate proposal as a new unit | Rewrite inspected units or promote proposal truth |
| `☵ ENCODE` | Aggregate/remap bounded units into formed identities | Remap without source map and loss |
| `☳ CHOOSE` | Modulate activation and mark suppressed potential | Reindex units or invent alternatives |
| `☷ DISSOLVE` | Release recoverable residue units from rigid form | Create unrelated semantic content |
| `☶ LOGIC` | Mark a unit rejected/invalid under a declared rule | Generate replacement semantics |

### 5.3 Unit identity law

```text
same id means same referent within one generation
new semantic identity requires a new id
☵ remap emits old_id -> new_id map
cross-generation similarity never implies identity equality
```

## 6. Relation System Table

### 6.1 Three relation timescales

| Region | Meaning | Sole writer/owner | Additional legal mutators | Readers | Expiry/invalidation | Current mapping | Source |
|---|---|---|---|---|---|---|---|
| `E_raw` | Transient recognition snapshot | ☰ CONNECT | none; replaced by newer ☰ snapshot | ☵, ☱, ☴, pressure derivation | source unit version changes; next snapshot may replace | missing | ANCESTOR |
| `E` | Active relation view | ☱ derives from raw/momentum | ☷ and ☶ may only weaken/remove/lock | ☵, ☳, ☷, ☶, ☱, △ guidance, eyes | remap of endpoints; rule/dissolution event | no canonical mapping | ANCESTOR/DERIVED |
| `M` / `E_momentum` | Inertia of recurrent relations | ☱ RUNTIME only | none; ☵ emits an invalidation set that ☱ must apply | ☱ and bounded eye metrics | Packet death; scoped endpoint remap applied by ☱; runtime decay | `runtime.foundation` is not equivalent | ANCESTOR/DECISION |

### 6.2 Minimum relation axes

| Axis | Meaning |
|---|---|
| `source_id` | Existing unit endpoint |
| `target_id` | Existing unit endpoint |
| `relation_kind` | Recognition, dependency, contradiction, evidence-for, implements, validates, residue-of, inherited-analogy, etc. |
| `strength` | Current relation intensity |
| `reciprocity` | Directional or mutual quality |
| `boundary_fluidity` | How easily endpoints can separate/rebind |
| `origin_event_id` | Event that detected or activated relation |
| `source_truth_status` | Truth of endpoint/source material |
| `relation_truth_status` | Truth of body-confirmed relation detection |
| `observed_at_tick` | Snapshot age basis |
| `endpoint_versions` | Invalidation basis |
| `state` | raw, active, habit, weakened, locked, dissolved, invalidated |

### 6.3 Relation laws

```text
☰ recognizes; it does not preserve
☱ preserves; it does not invent semantic relation
☷ and ☶ are subtractive-only over active relations
☵ is the only identity remap and emits the affected relation/momentum invalidation set
☱ remains the only writer that applies that set to E_momentum
M is current-life inertia, not grave history
```

## 7. CALM Structure Table

CALM is addressable form produced from potential. It may coexist with unresolved
CHAOS.

| Field/axis | Meaning | Writer | Readers | Invalidation | Current mapping | Source |
|---|---|---|---|---|---|---|
| `structure_id` | Identity of one encoded form | ☵ | ☳, ☱, ☲, ☶, △ | source remap/dissolution | implicit in `calm.structures` | DERIVED |
| `encoding_type` | hierarchy, sequence, category, network, teaching, language, spatial, narrative, etc. | ☵ | readers and loss | immutable for structure version | current `logic.encode` | RUNTIME/ANCESTOR |
| `source_unit_refs` | Potential consumed/projected into form | ☵ | loss, trace, dissolve, manifest | immutable provenance | partial current refs | RUNTIME |
| `identity_map` | old unit ids to new ids | ☵ | relation invalidator, trace, audits | immutable | missing canonical map | ANCESTOR |
| `omitted_refs` | Detail not represented | ☵ | loss, residue, observation | immutable | partial loss log | RUNTIME |
| `work_units` | Executable/addressable units exposed by form | ☵ | ☳, ☱, ☲, ☶ | status/evidence changes | `calm.work_units` | RUNTIME |
| `constraints` | Active constraints over form | ☶ | ☳, ☲, ☱, △ | rule/freshness changes | `calm.constraints` partial | ANCESTOR/RUNTIME |
| `status` | proposed, accepted, rejected, stale, dissolved, complete | body/runtime | router, organs, manifest | derived from current evidence | `calm.status` | RUNTIME/DERIVED |

CALM laws:

```text
encoded does not mean true
encoded does not mean selected
selected does not mean validated
validated does not mean currently fresh
CALM never crosses Packet death as living state
```

## 8. Scalar Regime Table

`S` controls physical regimes without carrying semantic content.

| Scalar family | Examples | Initial writer | Legal updater | Readers | Content memory? |
|---|---|---|---|---|---:|
| flow | engagement, resistance, emergence seed | ▽ | ☲ within clamps | ▽, ☷, pressure derivation | no |
| connect | depth, field of view, threshold, metric | body policy | ☲ within clamps | ☰ | no |
| dissolve | rigidity sensitivity, prune threshold | body policy | ☲ within clamps | ☷ | no |
| encode | representation target, region bound, loss policy | body/field policy | ☲ may schedule regime change | ☵ | no |
| choose | pressure, temperature, separation threshold | body policy | ☲ within clamps | ☳ | no |
| observe | scope/distance/fidelity policy | body policy | runtime policy | ☴/☱ | no |
| logic | rule id, strength, capability policy | body/sandbox | runtime policy | ☶ | no |
| runtime | momentum rate, decay, habit threshold | body policy | ☱ | ☱ | no |
| cycle | phase, mode, intensity | body policy | ☲ | ☲ and pressure derivation | no |
| manifest | output contract, carrier bound | ingress/lineage policy | none after entry | △ | no |

Scalar law:

```text
changing a scalar can change future behavior
it does not itself rewrite Z/E/M/C
☲ owns recurrence phase, not semantic progress
```

## 9. Observation Table

### 9.1 Shared eye record

| Field | Meaning |
|---|---|
| `eye` | `☴` upper or `☱` lower |
| `scope_refs` | Exact bounded areas/referents read |
| `referent_versions` | Versions used for freshness |
| `tick` | Observation time |
| `metrics` | Body-computed summary |
| `missing_scope` | What the eye could not inspect |
| `sensor_output_refs` | New proposal/evidence records produced by the read |
| `event_truth_status` | Body confirmation that observation occurred |
| `content_truth_status` | Truth of observed/proposed content |
| `fidelity` | Declared coarseness or distance |

### 9.2 Eye ownership

| Eye | Primary view | Writes | Named readers | Cannot own |
|---|---|---|---|---|
| `☴` | CHAOS, potential, ingress, semantic uncertainty, relation emergence | upper observation and substrate proposal records | pressure derivation, ☰, ☵, ☳, ☱ | routing, truth promotion, momentum |
| `☱` | CALM, execution, evidence, counters, budget, loss, foundation, attached history | lower observation, active relation/momentum updates, runtime snapshots | pressure derivation, ☶, ☲, △, lineage boundary | semantic rewrite, LLM route authority |

### 9.3 Observation freshness law

```text
observation is fresh only for the recorded referent versions
mutation of a referenced area makes applicability stale
historical observation event never disappears
freshness is derived when read
```

## 10. Constraint And Evidence Table

| Region | Contents | Writer | Owner | Readers | Freshness | Current mapping |
|---|---|---|---|---|---|---|
| constraints | rule masks, forbids, capability limits, validation requirements | ☶ and sandbox policy | Packet/body policy | ☳, ☲, ☱, △, router admissibility | rule/referent version | `calm.constraints`, sandbox |
| verdicts | accepted/rejected/no-evidence plus violation refs | ☶ | trace/runtime view | ☱, ☲, △, router | evidence fingerprint | `boundary.validations`, logic stamp |
| effect evidence | tool/test/fs result and `reality_changed` | ☶ through capabilities | runtime evidence store | ☱, freshness, △, lineage carrier | referent fingerprint/tick | `runtime.evidence` and spell results |
| semantic proposals | LLM claims and tool intents not executed | ☴ | potential field | ☰, ☵, ☳, ☶ | proposal age and source context | `chaos.fragments` |

Constraint laws:

```text
rule does not create truth
execution intent is not effect evidence
reality_changed requires body-owned observation of an effect
stale evidence returns to applicability uncertainty, not historical falsehood
```

## 11. Attached History View

`H` is a bounded projection attached to the newborn Packet. It is not session
storage and not mutable karma.

| History slice | Storage owner outside Packet | Attachment writer | Packet readers | Direct route authority? |
|---|---|---|---|---:|
| warning graves | session grave | lineage/runtime birth boundary | ☱ derivation; ☰ relation formation | no |
| bequest graves | session grave | lineage/runtime birth boundary | ☱ derivation; ☰ relation formation | no |
| neutral graves | session grave | lineage/runtime birth boundary | audit/context readers | no |
| compost patterns | session compost | lineage/runtime birth boundary | ☱ derivation/foundation bridge | no |
| manifest carrier | parent corpse/lineage | NETWORK@▽ | ▽ creates potential from it | no |

History laws:

```text
attachment is read-only
applicability is derived against current state
warning may resist; bequest may assist
same record may have different effect in another Packet
router never opens storage directly
```

## 12. Loss Ledger Table

### 12.1 Loss record

| Field | Meaning |
|---|---|
| `operator` | Operator whose completed mutation paid loss |
| `event_id` | Exact mutation event |
| `source_refs` | Units/relations/forms affected |
| `kind` | encoding detail, suppressed potential, dissolution, constraint, materialization, etc. |
| `before_measure` | Potential/detail/degree-of-freedom basis before |
| `after_measure` | Basis after |
| `amount` | Normalized current-life identity damage |
| `method` | Measured, estimated, or policy floor |
| `truth_status` | Status of the calculation, separate from source content |

### 12.2 Loss ownership

| Action | Writer | Reader | Mutation law |
|---|---|---|---|
| append loss event | body physics after completed operator | ☱, mortality guard, trace, △ | append-only |
| calculate cumulative loss | runtime loss reader | mortality/pressure/UI | derived from ledger |
| calculate remaining identity | runtime loss reader | mortality/pressure | derived from initial capacity minus cumulative loss |
| reduce/reset loss | nobody | nobody | forbidden inside one Packet |

### 12.3 Qualitative source profile

```text
mandatory:   ☵ ☳ △
conditional: ☷ ☶ and possibly ☱ under an explicit persistence contract
zero direct identity loss: ▽ ☰ ☴ ☲
```

Exact conditional formulas remain OPEN.

## 13. Local Budget Table

| Region | Meaning | Writer | Reader | Law | Current mapping |
|---|---|---|---|---|---|
| limits | Maximum local fuel by axis | ingress/lineage allocation | budget runtime, UI | immutable allocation | `physis.budget` |
| cost events | Per-tick/token/tool/write/test/time spending | body and capability runtime | budget accumulator, trace | append-only | `runtime.budget.events` |
| spent | Totals by axis | budget reader | ☱, mortality, UI | derived from events | `runtime.budget.spent` |
| remaining | Limit minus spent | budget reader | ☱, pressure, mortality | derived | `runtime.budget.remaining` |
| exhausted | Axes at or below zero | budget reader | mortality guard | derived | `runtime.budget.exhausted` |

Axes already present or reserved:

```text
steps
substrate_calls
prompt_tokens
completion_tokens
total_tokens
estimated_tokens
tool_calls
file_writes
test_runs
time_ms
money_units
```

Budget laws:

```text
every completed operator tick costs at least one step
☲ is cheap but not free in budget
budget never directly changes identity loss
new Packet gets local budget allocation
lineage spending remains cumulative outside this table
```

## 14. Pressure Snapshot Table

`Tau` is recomputed for the current tick. It is not a body memory.

### 14.1 Pressure contribution

| Field | Meaning |
|---|---|
| `kind` | relation, rigidity, observation, encode, choice, runtime, validation, continuation, manifest, mortality, karma |
| `source_ref` | Exact state/history/evidence source |
| `target_operator` or `target_edge` | Local motion affected |
| `amount` | Signed help/resistance contribution |
| `reason` | Machine-readable reason code |
| `calculation_status` | Runtime-confirmed or estimated derivation |
| `source_truth_status` | Epistemic status of source content |
| `freshness` | Applicability at current tick |
| `derivation_version` | Formula/policy version |

### 14.2 Pressure views

| View | Writer | Reader | Lifetime |
|---|---|---|---|
| raw contributions | named pressure readers, mostly runtime-owned | pressure aggregator, trace | one derivation tick |
| candidate edge totals | pressure aggregator | router, shadow comparison, trace | one route decision |
| selected route reason | router | trace, UI, edge statistics | immutable event |

Pressure laws:

```text
history is stored; karma pressure is derived
records are stored; freshness pressure is derived
Packet state is stored; route tension is derived
semantic source status survives aggregation
old snapshots may be audited but never reused as current truth
```

## 15. Trace Table

### 15.1 Event envelope

| Field | Meaning |
|---|---|
| `event_id` | Unique event in Packet life |
| `packet_id/generation` | Identity scope |
| `tick` | Body clock |
| `event_type` | birth, operator result, cost, loss, route, manifest, death |
| `operator` | Actual operator position |
| `read_refs` | State records read |
| `write_refs` | State records created/mutated |
| `payload` | Bounded operator-specific result |
| `event_truth_status` | Whether body confirms occurrence |
| `content_truth_status` | Status of semantic content |
| `cost_refs/loss_refs` | Economics caused by event |

### 15.2 Route event

```text
from
to
canonical adjacency result
candidate edge totals
selected reason
lifecycle/capability/sandbox exclusions
```

Trace laws:

```text
append-only
topology validated before movement
invalid route is recorded and terminates; never silently repaired
death/manifest stamps actual current operator
trace survives as history but never keeps Packet mutable
```

## 16. Terminal State Table

| Terminal record | Writer | Readers | Mutability | Crosses generation? |
|---|---|---|---|---:|
| manifest output | △ | user/machine boundary, carrier builder | write-once | only projected carrier |
| death cause | mortality or △ completion | grave classifier, lineage ledger | write-once | reference/projection only |
| residue | dying body | grave, carrier builder, audit | immutable after death | bounded projection |
| corpse identity | lifecycle boundary | lineage runner, grave | immutable | reference only |
| living Z/E/M/C | nobody after death | corpse audit may read | immutable | no |

Terminal laws:

```text
dead Packet rejects every mutating entry point
death cause cannot be overwritten
posthumous manifest is forbidden
manifest completion also ends Packet identity
lineage continuation requires a new Packet
```

## 17. Mutation And Invalidation Matrix

| Mutation | Must invalidate or stale | Must preserve |
|---|---|---|
| append new potential unit | upper observation coverage, relation completeness | prior unit identity and trace |
| change unit activation by ☳ | choice-dependent observations and route pressure | unit identity and suppressed residue |
| ☵ remap unit identities | affected `E_raw`, `E`, `M`, observations, evidence referents | identity map, source refs, loss record |
| ☷ weaken/dissolve relation/form | active relation view, dependent CALM status | dissolution event and recoverable residue |
| ☶ reject/lock relation/form | dependent choice/runtime/manifest readiness | rule, violation, and evidence records |
| new tool/test effect | prior evidence fingerprint and logic stamp applicability | historical evidence event |
| ☱ momentum update | lower observation/runtime snapshot | raw relation provenance |
| new cycle phase | continuation snapshot | semantic field |
| death | every future mutation capability | all historical records |

## 18. Named Reader Registry

| Written record | Required reader | Read moment | If unread |
|---|---|---|---|
| potential units | field organs/eyes | relevant operator tick | body cannot transform task |
| `E_raw` | ☵ and/or ☱ pressure/runtime | before snapshot expires | ☰ is decorative |
| active `E` | ☷/☵/☳/☶/☱ | operator and pressure ticks | relation physics is inert |
| `E_momentum` | ☱ derivation | lower-eye/runtime tick | persistence is inert storage |
| CALM structures | ☳/☱/☲/☶/△ | after encode | encode is writer without consumer |
| observation record | pressure derivation and field organs | next route/read | eye has no causal role |
| constraint/verdict | ☱/router/△ | after logic | logic is decorative |
| effect evidence | freshness/☱/△ | runtime and manifest | spell result cannot govern truth |
| history attachment | ☱ karma derivation and optionally ☰ | birth/route ticks | grave/compost cannot teach |
| loss event | mortality/pressure/△ | after every operator | loss is non-lethal bookkeeping |
| budget cost | budget/mortality | after every operator | existence becomes free |
| pressure contribution | router and trace | same tick | pressure cannot move body |
| manifest carrier source | lineage runner | after death | lineage cannot continue |

## 19. Current Lua Mapping Summary

| Concept | Current state |
|---|---|
| identity/header | partial and working; generation/lineage fields missing |
| task-shaped `Z` units | represented indirectly by chaos fragments and encoded field items |
| `E_raw` | missing |
| active `E` | partial ad hoc connections inside encode; no canonical body region |
| `E_momentum` | missing; foundation is adjacent but not equivalent |
| CALM | present and useful |
| scalars | distributed across options/budget; no canonical `S` region |
| two eye observations | upper organ and lower runtime snapshot present, shared envelope incomplete |
| constraints/evidence | present across validations, spells, runtime evidence, sandbox |
| attached history | grave attachment present; compost reader missing |
| loss | working for ☵/☳ mortality; other profiles and △ loss missing |
| budget | working local economics and death |
| pressure snapshot | present as mixed router snapshot; not per-edge/provenance-complete |
| trace | present; current operator advancement defect remains |
| terminal state | finality guards substantially present; carrier/lineage refs missing |

## 20. Open Rows Before Crystall

```text
exact Lua containers for Z/E/C without duplicating current chaos/calm areas
minimum stable potential-unit envelope
relation kind registry versus open string kinds
scoped versus whole-field remap invalidation
runtime persistence loss contract
normalization of identity loss across different carrier kinds
pressure amount normalization
no-viable-edge state representation
manifest materialization loss measurement
```

## 21. T1 Acceptance

This table is ready to feed T2 when:

```text
every region has one owner or an explicit body-owned append path
every writer has a named reader
stored history is separated from derived pressure
loss is separated from budget
E_momentum is separated from grave/foundation/trace
semantic proposals cannot become runtime truth through structure alone
death makes every living region immutable
current Lua mappings are descriptive, not treated as final schema
```
