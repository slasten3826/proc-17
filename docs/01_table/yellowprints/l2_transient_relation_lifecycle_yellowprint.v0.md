# L2 Transient Relation Lifecycle Yellowprint v0

Status:

```text
table / L2 CONNECT four-road lifecycle decision
date: 2026-07-18
sources:
  docs/00_chaos/l1_flow_marks_and_l2_relation_lifecycle_notes_2026-07-18.md
  docs/00_chaos/promotion_tables_materialization_and_witness_audit_2026-07-17.md
  docs/00_chaos/versioned_witness_table_observation_2026-07-17.md
  docs/01_table/yellowprints/relation_consumer_causality_yellowprint.v0.md
  docs/01_table/yellowprints/pressure_witness_versioned_coverage_yellowprint.v0.md
  docs/01_table/yellowprints/operator_tree_physics_yellowprint.v0.md
  docs/01_table/yellowprints/processlang_lua_four_layer_assembly_audit_yellowprint.v0.md
  /home/slasten/work/packet-slop/docs/60_PROCESSLANG_LUA_MACHINE_BLUEPRINT_RU.md
layer: L2 TABLE / formation
production code change authorized: no
field schema migration authorized: no
router/pressure authority authorized: no
corpus construction authorized: no
```

## 0. Decision

L2 CONNECT is a transient relation sensor, not a persistent graph owner.

```text
☰ detects bounded possible relation in the current field domain
☰ writes one replaceable raw epoch
the next lawful phase may expose, release, or encode that relation
only ☵ may turn the transient relation into retained form
☱ may preserve/reinforce formed structure; it may not originate it
```

The four incident roads have different rights:

```text
▽ -> ☰  relation emerges from distinguished flow
☰ -> ☷  raw relation is released/rejected
☰ -> ☴  raw relation is observed without retention
☰ -> ☵  raw relation is encoded into retained form
```

The edge graph remains symmetric as topology. Same-life lifecycle remains
directed: a living Packet may not return to `▽`.

## 1. Layer Formula And Evidence Status

The final packet-slop blueprint selects:

```text
L2 = CONNECT + DISSOLVE + ENCODE + OBSERVE + CHOOSE
```

This table focuses on the four-road relation phase around CONNECT. CHOOSE acts
after candidate forms/alternatives exist and is not the writer of raw relation.

| Claim | Evidence status |
|---|---|
| CONNECT writes a bounded replaceable raw epoch | `GREEN_LOCAL` current code |
| Raw candidates contain endpoint versions and truth separation | `GREEN_LOCAL` current code |
| OBSERVE reads exact raw epoch | `RED_MISSING` |
| DISSOLVE can release exact raw candidate | `RED_MISSING` |
| ENCODE forms from exact raw candidate | `RED_MISSING` |
| RUNTIME creates active relation in live body | Registry/API declaration only; no production caller |
| Four-road lifecycle is selected | `DOCUMENT_DECISION` |
| One living L1-to-L2 relation life exists | `RED_MISSING` |

## 2. The Relation Is A Phase, Not A Permanent Object

The museum contract is:

```text
CONNECT = resonance snapshot
detects structure, does not preserve it
state = none
writes E_edges_raw
```

In proc-17, this maps to a replaceable field projection rather than stateless
code:

```text
transient does not mean unrecorded
transient means no right to survive as formed structure by itself
```

The raw snapshot may remain inspectable for audit until replaced or Packet
death. Its current availability is derived from its epoch, object versions,
and disposition events. Storage duration does not grant semantic or structural
persistence.

## 3. Required Raw Epoch Contract

Current `runtime/field.lua` already supplies most of the physical record.
The surviving table contract is:

```lua
raw_relation_epoch = {
  protocol_version = "field.raw_relations.v1",
  epoch = 7,
  source_potential_revision = 12,
  source_event_refs = {...},
  coverage = {
    unit_versions = { ["unit:1"] = 3, ["unit:2"] = 1 },
    candidates_detected = 1,
    relations_recorded = 1,
    omitted_relations = 0,
    truncated = false,
  },
  relations = {
    {
      id = "relation:9",
      from = "unit:1",
      to = "unit:2",
      endpoint_versions = { ["unit:1"] = 3, ["unit:2"] = 1 },
      kind = "shared_parent",
      structural_confidence = 1.0,
      event_truth_status = "runtime_confirmed",
      content_truth_status = "unknown",
    },
  },
}
```

Exact field names belong to crystallization. Required facts do not:

| Required fact | Why |
|---|---|
| Monotonic epoch | Separates replacement snapshots |
| Exact endpoint IDs and versions | Prevents stale relation use |
| Bounded coverage | Makes omission and unsupported scope visible |
| Producer event refs | Connects disposition to the actual CONNECT tick |
| Detection/content truth split | Body confirms detection without confirming semantic meaning |
| Stable relation IDs inside one epoch | Lets neighboring phases name the same candidate |

Global `revisions.potential` may remain telemetry. It is not sufficient as the
sole freshness law; current endpoint versions are authoritative.

## 4. One Causal Chain, Phase Witnesses

No second mutable relation lifecycle ledger is introduced.

```text
raw epoch in canonical field
+ immutable trace events referring to epoch/relation/object versions
-> derive current phase on demand
```

Possible derived phases per raw relation:

| Phase | Derivation |
|---|---|
| `available` | Current epoch, current endpoints, no terminal disposition |
| `observed` | A current observation event names the exact epoch/relation |
| `encoded` | A retained-form event consumes exact epoch/relation |
| `released` | A raw-release event consumes exact epoch/relation |
| `stale` | One covered endpoint version no longer matches |
| `replaced` | A later raw epoch became current |
| `expired` | Packet became terminal without retained form |

`observed` is non-terminal. `encoded` and `released` are terminal dispositions
for that raw relation identity. A later CONNECT epoch may discover a new
relation between the same units.

## 5. Direction-Specific Edge Contract

Topology answers "may these glyphs touch?" Lifecycle answers "what does this
direction mean?"

| Edge direction | L2 meaning | Retained relation created? |
|---|---|---:|
| `▽ -> ☰` | Distinguished material becomes eligible for relation recognition | No |
| `☰ -> ▽` | Forbidden for one living Packet by boundary law | No transition |
| `☰ -> ☷` | Current raw candidate is released/rejected | No |
| `☷ -> ☰` | Survivors/residue changed the domain; reconnect current versions | No, new raw epoch only |
| `☰ -> ☴` | Current raw candidate becomes visible/auditable | No |
| `☴ -> ☰` | Observation added/changed distinguished material; reconnect | No, new raw epoch only |
| `☰ -> ☵` | Current raw motif is transformed into retained form | Yes, with remap/provenance/loss |
| `☵ -> ☰` | Encoding created/remapped units; reconnect the new domain | No, new raw epoch only |

The canonical topology may stay undirected. The same-life FLOW ingress law is
a lifecycle constraint above adjacency, as it already is in `core/packet.lua`.

"Return to flow" after an unretained relation means loss of the raw candidate
back into continuing/unformed material, not an illegal `☰ -> ▽` trace step.

## 6. Road 1: FLOW To CONNECT

Selected contract:

```text
FLOW/L1 projection or other distinguished units exist
-> CONNECT inspects one exact versioned domain
-> CONNECT emits a bounded raw epoch, including an honest empty epoch
```

CONNECT may recognize only materially supported structural candidates in v0:

```text
shared carrier parent
explicit common source/provenance
declared endpoint relation candidate
other crystallized body-native predicates
```

It may not invent a semantic relationship merely because two units exist.

If no candidate is found, CONNECT records an empty/unsupported probe stamp for
the exact covered object versions. Repeating CONNECT against the unchanged
domain is not ready. The probe re-arms only when one covered object is added,
removed, or changes version, or an explicit bounded probe policy changes.

```text
per-object re-arm, never global potential-axis re-arm
```

## 7. Road 2: CONNECT To OBSERVE

OBSERVE receives a bounded view of the exact raw epoch.

Required read contract:

```lua
relation_observation_input = {
  raw_epoch = 7,
  relation_ids = {"relation:9"},
  endpoint_versions = {...},
  source_event_refs = {...},
}
```

OBSERVE has two possible sensors under one body right:

| Sensor | Purpose | Substrate required? |
|---|---|---:|
| Body-native relation view | Record endpoints, versions, kind, coverage, and state | No |
| Semantic substrate view | Ask for bounded interpretation when content is unresolved | Yes |

The body-native sensor must exist even when no LLM is attached. OBSERVE is
larger than a substrate call.

Observation writes an immutable event referencing the same epoch/relation. It
does not:

```text
activate relation
create retained form
upgrade semantic truth
consume the raw candidate terminally
```

Immediate repeated observation of the same relation versions is suppressed by
the existing versioned-coverage family. It re-arms when the relation, endpoint,
or explicitly observed evidence changes.

After observation, a legal later step may encode or release the same still
current raw relation.

## 8. Road 3: CONNECT To DISSOLVE

L2 DISSOLVE must support two distinct contracts.

| Contract | Input | Effect | Identity loss |
|---|---|---|---:|
| Raw release | Current raw candidate plus typed reason | Terminal `released` disposition; optional bounded residue | No formed-identity loss |
| Formed dissolution | Retained/active structure plus typed reason | Weakens/removes form and emits residue | Explicit loss proportional to formed structure |

The raw-release road must not activate a relation first merely to give DISSOLVE
an object. That would create the form it is trying to reject.

Accepted raw-release reasons are body-visible and typed, for example:

```text
stale endpoints
contradictory current evidence
unsupported structural candidate
explicit release policy
bounded snapshot replacement
```

The reason event must name the exact raw epoch/relation/object versions. A
semantic model may propose a reason; the body confirms only a supported typed
disposition.

After raw release changes or returns units/residue, `☷ -> ☰` may create a new
epoch over the surviving current domain.

## 9. Road 4: CONNECT To ENCODE

This is the only road that may retain the detected relation as form.

Required ENCODE input:

```lua
relation_formation_input = {
  raw_epoch = 7,
  relation_ids = {"relation:9"},
  endpoint_versions = {...},
  source_event_refs = {...},
  requested_shape = "group", -- example only
}
```

Required body effect:

```text
consume exact current raw relation(s)
create/remap retained unit/form/relationship state
record raw-to-formed provenance
record omitted alternatives and explicit ENCODE loss
preserve content truth status
emit terminal `encoded` disposition for consumed raw identities
```

The retained object may receive a new identity. Raw relation identity is an
observation address, not an immortal graph edge.

```text
raw relation: relation:9
formed relation/form: form:3 or a new retained relation id
provenance: formed_from = {raw_epoch=7, relation_ids={"relation:9"}}
```

If ENCODE ignores the raw relation, it may still run its ordinary text/form
path, but it must not claim `relation_guided` formation.

## 10. ENCODE And RUNTIME Ownership

The selected ownership split is:

| Surface | Writer/owner | Right |
|---|---|---|
| Raw relation epoch | `☰ CONNECT` | Detect/replace transient snapshot |
| Relation observation | `☴ OBSERVE` | Record bounded visibility |
| Raw release | `☷ DISSOLVE` | Reject/release transient candidate |
| Retained relation/form | `☵ ENCODE` | Create form from exact raw provenance |
| Momentum/habit | `☱ RUNTIME` | Reinforce, decay, or reconcile already formed state |
| Formed dissolution | `☷ DISSOLVE` | Weaken/release retained state with loss |

Therefore the older candidate contract:

```text
☱ RUNTIME activates raw relations directly
```

is rejected for this L2 lifecycle. It confuses formation with persistence.

Current `field.activate_relations()` and the registry declarations are not
deleted by this table. Their migration must be selected in crystallization:

```text
option A: transfer retained-relation creation right to ENCODE and preserve the
          existing `relations.active` storage name temporarily
option B: introduce an explicit `relations.formed` surface and migrate readers
```

Whichever option survives, RUNTIME cannot manufacture retained relation from
raw CONNECT output.

## 11. Current Code Mismatch Audit

| Surface | Current code | Selected table law | Required future action |
|---|---|---|---|
| `relations.raw` writer | CONNECT only | Correct | Preserve |
| Raw epoch replacement | Implemented | Correct, add lifecycle refs/readers | Extend carefully |
| ENCODE raw read | Absent | Required on `☰ -> ☵` | Add behind isolated contract |
| OBSERVE raw read | Absent despite registry declaration | Required on `☰ -> ☴` | Add body-native view |
| DISSOLVE raw read | Absent; active only | Required on `☰ -> ☷` | Add separate raw-release mode |
| RUNTIME raw activation | Field API permits; organ never calls | Rejected ownership | Migrate after crystall |
| RUNTIME momentum | Registry declares; organ does not write | Valid only for formed state | Implement only with named formed reader |
| Registry OBSERVE reads relations | Over-declared | Must match actual mode after implementation | Keep declaration from pretending evidence |
| Registry RUNTIME writes active/momentum | Over-declared | Activation ownership changes | Amend with code, not before |

Green tests around direct `field.activate_relations()` prove a local API. They
do not prove a live L2 relation lifecycle.

## 12. Cost And Loss Table

| Operation | Body step/budget | LLM tokens | Packet identity loss |
|---|---:|---:|---:|
| CONNECT structural snapshot | Paid body step | Zero | Zero |
| Empty CONNECT probe | Paid body step once per current domain | Zero | Zero |
| Body-native relation OBSERVE | Paid body step | Zero | Zero |
| Semantic relation OBSERVE | Paid body step | Actual substrate usage | Observation does not itself create form loss |
| Raw DISSOLVE release | Paid body step | Usually zero | Zero formed-identity loss; projection/discard count visible |
| ENCODE relation formation | Paid body step | Usage depends on path | Explicit structure/identity loss |
| RUNTIME momentum update | Paid body step | Zero unless separately justified | No new formation loss |
| Formed DISSOLVE | Paid body step | Usually zero | Explicit loss from removed formed structure |

Potentiality can disappear without pretending that a stable identity was
destroyed. ENCODE and dissolution of formed state are the identity-changing
operations.

## 13. Readiness And Discharge

Each phase contribution requires an exact live witness.

| Candidate | Ready only when | Discharged when |
|---|---|---|
| CONNECT | Eligible domain versions lack a current probe, or domain changed | Current raw/empty epoch covers exact versions |
| OBSERVE | Current raw candidate/evidence version has not been observed and visibility is needed | Observation event covers exact refs |
| DISSOLVE raw | Current raw candidate has a typed release reason | Release event consumes exact raw identity |
| ENCODE relation | Current raw candidate plus formation demand is supported | Form event consumes exact raw identity |
| RUNTIME momentum | Retained formed state has an unresolved runtime delta | Momentum/reconciliation event covers current formed version |

An empty or unsupported CONNECT result suppresses immediate repetition against
the same object versions. Its named reader is CONNECT readiness/pressure itself.

No global revision bump may re-arm a discharged witness when all covered object
versions are unchanged.

## 14. Named Writer/Reader Matrix

| Record | Writer | Named reader | Read moment |
|---|---|---|---|
| Distinguished units | FLOW/OBSERVE/DISSOLVE/ENCODE | CONNECT | Relation probe readiness/run |
| Raw relation epoch | CONNECT | OBSERVE, raw DISSOLVE, relation ENCODE | Exact legal phase |
| Empty/unsupported probe | CONNECT | CONNECT readiness/pressure | Before another CONNECT candidate |
| Relation observation | OBSERVE | Later OBSERVE readiness; ENCODE/LOGIC only if explicitly referenced | Derivation |
| Raw release event | DISSOLVE | Lifecycle derivation and reconnect readiness | After release |
| Encoded-form provenance | ENCODE | RUNTIME, LOGIC, formed DISSOLVE, MANIFEST as needed | Form lifecycle |
| Momentum record | RUNTIME | RUNTIME/LOGIC/pressure with current formed refs | Lower-body derivation |

No record is accepted merely because it is useful for debugging. Every writer
has a named body reader and read moment.

## 15. Matched Road Controls

All controls use the same units, versions, truth statuses, bounds, and route
authority unless the named variable changes.

| ID | Life fragment | Required observation |
|---|---|---|
| C0 | CONNECT only | Raw epoch exists; no retained form exists |
| C1 | `▽ -> ☰` | Current distinguished units produce one exact raw/empty epoch |
| C2 | `☰ -> ☴` | Observation names same epoch; no retained/active relation appears |
| C3 | C2 then legal ENCODE | Same current raw relation may be formed once with observation provenance |
| C4 | `☰ -> ☷` | Exact raw candidate is released without prior activation |
| C5 | `☰ -> ☵` | Exact raw candidate becomes retained form with remap, provenance, and loss |
| C6 | C5 with raw relation removed | ENCODE cannot claim relation-guided form |
| C7 | C5 then RUNTIME | Momentum applies only to formed identity; origin remains ENCODE |
| C8 | C7 then formed DISSOLVE | Form weakens/releases with explicit identity loss |
| C9 | Empty CONNECT then unchanged domain | CONNECT is not immediately ready again |
| C10 | C9 plus one covered endpoint version change | Probe re-arms exactly once |

## 16. Reverse-Road Controls

| ID | Life fragment | Required observation |
|---|---|---|
| R1 | `☷ -> ☰` | Reconnects current survivors and produces a new epoch |
| R2 | `☴ -> ☰` | Only newly changed/added observed units re-arm relation probe |
| R3 | `☵ -> ☰` | Remapped/new units produce relation epoch against current IDs |
| R4 | Attempt `☰ -> ▽` in one life | Rejected by lifecycle boundary; no mutation |

These controls prove direction-specific semantics without editing canonical
adjacency.

## 17. Truth-Preservation Controls

| ID | Input status | Required result |
|---|---|---|
| T1 | Structurally detected, semantic content unknown | Detection event confirmed; content remains unknown |
| T2 | Content is `semantic_proposal` | OBSERVE/ENCODE preserve proposal status |
| T3 | Runtime-confirmed endpoint existence | Does not confirm semantic relation meaning |
| T4 | DISSOLVE release is runtime-confirmed | Release fact confirmed; proposed reason content is not laundered |

Body structure may confirm that an operation occurred. It may not confirm the
semantic proposition merely by moving it through an organ.

## 18. Vertical Slice Gate

The first meaningful integration fixture is:

```text
named L1 source/state
-> Packet birth with flow mark
-> bounded projection creates at least two distinguished TABLE units
-> CONNECT derives one body-supported raw relation
-> OBSERVE sees that exact epoch without retaining it
-> ENCODE consumes that exact relation into form
-> RUNTIME/LOGIC/CYCLE operate on the formed identity
-> MANIFEST emits typed result and Packet dies
```

Required ablations:

```text
raw relation removed
relation reader disabled
observation omitted
ENCODE relation mode disabled
RUNTIME momentum disabled
```

The fixture fails if a harness injects the expected encoded form or if a prompt
merely tells the substrate what relation to claim.

## 19. Pressure And Router Gate

This table creates no live route authority.

Relation pressure may enter the promoted router only after:

```text
one named road has a varying current witness
readiness consumes the same refs
successful work discharges the witness
negative and ablation controls pass
another live neighbor remains available in the competition test
```

Weights and age/fairness remain downstream questions. First prove that the
candidate facts vary and cause work.

## 20. False-Green Matrix

| False green | Rejecting assertion |
|---|---|
| Raw snapshot called persistent connection | C0 has no retained form |
| OBSERVE called activation | C2 creates no retained/active relation |
| DISSOLVE activates then deletes raw candidate | C4 forbids prior activation |
| RUNTIME creates relation from raw | Section 10 rejects ownership |
| ENCODE claims relation use but ignores epoch | C5/C6 matched pair |
| Registry declaration called implementation | Section 11 requires concrete read/write evidence |
| Empty CONNECT immediately repeats | C9 suppression |
| Global potential bump re-arms probe | C10 requires covered object change |
| Same relation ID survives encoding by default | Form identity and provenance are separate |
| Semantic proposal becomes runtime fact | T2/T3 |
| Direct `☰ -> ▽` used as return-to-flow | R4 rejects same-life transition |
| Direct organ calls called a living chain | Vertical fixture must use committed edges |
| Canonical tie-break called relation pressure | Section 19 requires live competition |

## 21. Amendment To Relation Consumer Causality v0

This table preserves from `relation_consumer_causality_yellowprint.v0.md`:

```text
versioned object coverage
same-ref pressure/readiness/consumer law
matched ablation controls
truth preservation
boundedness
no invented consumers for corpus completion
```

It replaces the candidate ownership model:

```text
old R1: ENCODE may consume relation motif             -> retained and expanded
old R2: RUNTIME may activate raw relation directly    -> rejected
old R3: DISSOLVE consumes only active relation        -> split into raw and formed modes
```

The older document remains archaeology for how the consumer question was
found. Its RUNTIME activation decision must not govern crystallization after
this amendment.

## 22. Table Acceptance And Next Step

This table is accepted when review agrees that it:

```text
treats CONNECT as transient recognition rather than graph persistence
assigns a distinct right to every incident road
keeps same-life FLOW ingress terminally directed
lets OBSERVE see without retaining
lets DISSOLVE release raw candidates without first creating them
makes ENCODE the sole origin of retained relation form
limits RUNTIME to persistence/momentum of formed state
uses per-object epochs/versions and named readers
preserves truth, budget, loss, and topology boundaries
```

Acceptance authorizes a crystall for raw-relation phase derivation and the
three missing readers. It does not authorize code, schema migration, router
promotion, or corpus claims.
