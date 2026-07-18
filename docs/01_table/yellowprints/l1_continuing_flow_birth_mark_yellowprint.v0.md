# L1 Continuing Flow And Packet Birth Mark Yellowprint v0

Status:

```text
table / L1 production-boundary decision
date: 2026-07-18
sources:
  docs/00_chaos/l1_flow_marks_and_l2_relation_lifecycle_notes_2026-07-18.md
  docs/00_chaos/l1_true_chaos_calm_body_notes_2026-07-18.md
  docs/01_table/yellowprints/l1_body_boundary_yellowprint.v0.md
  docs/01_table/yellowprints/processlang_lua_four_layer_assembly_audit_yellowprint.v0.md
  docs/02_crystall/blueprints/l1_standalone.v0.md
  /home/slasten/work/packet-slop/docs/59_RESEARCH_RETROSPECTIVE_RU.md
  /home/slasten/work/packet-slop/docs/60_PROCESSLANG_LUA_MACHINE_BLUEPRINT_RU.md
selected L1 law: canonical variant C
standalone parity: runtime-confirmed by current tests
production integration authorized: no
Packet schema change authorized: no
router/pressure authority authorized: no
```

## 0. Decision

L1 is a continuing body-owned flow, not a field owned by one mortal Packet.

```text
one L1 flow domain survives multiple Packet lives
each accepted Packet birth advances that domain once in v0
the newborn receives an immutable mark of the resulting flow moment
Packet death freezes the carried mark, not the source flow domain
```

For the first production integration, one proc-17 session owns one L1 flow
domain.

```text
selected v0 scope: session
rejected v0 scope: one unrelated host-global stream across all sessions
rejected interpretation: initialize and destroy canonical L1 for every Packet
```

"Continuing" is a lifetime law. It does not require an unbounded CPU loop.
The implementation is event-driven and advances only on named body events.

## 1. Why The Scope Is Session

| Candidate scope | Benefit | Failure mode | v0 decision |
|---|---|---|---|
| Packet | Simple ownership and freeze | L1 dies with the form it is supposed to precede | Rejected as the continuing source |
| Lineage | Direct ancestral continuity | Unrelated new tasks have no common flow; branching becomes ambiguous | Deferred specialization |
| Session | Survives Packet deaths while preserving user/runtime isolation | Session restart needs an explicit new epoch or persisted state | Selected |
| Process-global | One apparent eternal machine | Concurrent sessions perturb each other; replay and privacy become implicit | Rejected for v0 |
| Host-global persistent | Strongest literal eternity | Hidden universal mutable state and deployment coupling | Rejected until independently justified |

The canonical abstraction is `flow_domain`, not "session" itself. A later host
may bind a domain to a lineage, worker, or explicit shared universe, but that is
a deployment revision with new concurrency and replay evidence.

## 2. Four Identities That Must Not Collapse

| Identity | Meaning | Created by | Lifetime |
|---|---|---|---|
| `packet_id` | Administrative identity of one mortal Packet | Packet birth factory | One Packet life plus corpse record |
| `lineage_id` + `generation` | Ancestral position across Packet deaths/re-entry | Lineage runner | One task lineage |
| `l1_stream_id` + `stream_epoch` | Administrative identity of one continuing flow domain | Session/L1 owner | One recoverable L1 domain epoch |
| `flow_mark` | Physical measurement and event envelope for one birth moment | L1 birth transition | Immutable inside newborn and corpse |

The bounded L1 fingerprint is not any of the first three identities.

```text
flow fingerprint != packet id
flow fingerprint != lineage id
flow fingerprint != cryptographic signature
flow fingerprint != globally unique number
```

## 3. Museum Proof, Current Proof, New Decision

| Claim | Evidence status |
|---|---|
| Variant C has deterministic stateful tick physics | `GREEN_PARITY` in `l1/field.lua` |
| Full museum checkpoints reproduce in Lua 5.4 | `GREEN_PARITY` |
| The field exposes bounded temporal measurements | `GREEN_LOCAL` for registered baseline |
| The museum ran one process-global eternal L1 | Not proved |
| L1 should outlive one Packet in proc-17 | `DOCUMENT_DECISION` |
| Session is the correct first flow domain | `DOCUMENT_DECISION` |
| A flow mark improves routing or coding | Not claimed; `RED_MISSING` |

The new lifetime law uses museum physics. It must not be backdated as a museum
result.

## 4. Selected Runtime Ownership

The future ownership boundary is:

```text
session runtime
  owns one mutable canonical L1 state
  owns stream id, epoch, birth sequence, and serialization lock

Packet
  owns one immutable copied flow_mark envelope
  does not own or mutate canonical L1

standalone fixture
  may still own and freeze one isolated L1 state
```

The existing standalone `l1.freeze()` contract remains correct. It freezes the
specific state passed to it. Production session shutdown may freeze its L1
state; ordinary Packet death must not call freeze on the session-owned source.

## 5. Event-Driven Continuation Law

The first integration authorizes only one logical L1 clock event:

```text
event kind: packet_birth
advance count: exactly one canonical L1 tick
capture point: snapshot immediately after that tick
```

Order:

```text
1. validate the birth request and flow-domain ownership
2. reserve the next birth sequence inside one atomic operation
3. advance canonical L1(C) exactly once
4. capture the bounded snapshot
5. create the immutable flow_mark envelope
6. create the Packet and append its birth evidence
7. commit the L1 state and birth sequence together
```

If Packet construction or trace append fails because Lua/harness physics broke,
the operation fails loudly and commits neither the L1 tick nor the birth
sequence. A malformed/rejected request also does not create a ghost birth.

No wall-clock timer and no background `while true` loop are part of v0.

Future event kinds such as `committed_body_tick` or explicit environmental
perturbation require their own matched experiment. They may not appear as a
silent extension of the birth clock.

## 6. Flow Mark Envelope

Minimum immutable envelope:

```lua
flow_mark = {
  protocol_version = "l1.flow_mark.v0",
  l1_protocol_version = "l1.field.v0",
  variant = "C",
  stream_id = "...",
  stream_epoch = 1,
  birth_seq = 17,
  trigger = "packet_birth",
  snapshot = {
    tick = 17,
    position = 2,
    carry = 29525,
    fingerprint = 6887,
    trace_density = 7955,
    distinct_core = 1168,
    distinct_l1_trace = 794,
  },
  source_provenance = {...},
  event_truth_status = "runtime_confirmed",
  semantic_claim_status = "none",
}
```

Exact numbers above are illustrative fields, not a required production state.

### 6.1 Physical and administrative parts

| Part | Class | Meaning |
|---|---|---|
| Snapshot metrics | Physical measurement | Derived from canonical L1 state |
| Variant/protocol | Physical interpretation | Selects the exact law used |
| Stream id/epoch | Administrative identity | Distinguishes flow-domain incarnations |
| Birth sequence | Administrative ordering | Distinguishes repeated bounded measurements |
| Trigger | Causal provenance | Names why this L1 transition happened |
| Source provenance | Reproducibility metadata | Names adapter/config without copying the prompt |

Administrative fields do not make the fingerprint less physical. Physical
metrics do not replace administrative event identity.

## 7. Collision Law

The canonical fingerprint lives under `MOD = 59049`. Collisions are lawful.

```text
same fingerprint at two births = allowed
same full bounded snapshot at two births = allowed
same stream epoch and same birth sequence twice = forbidden
```

Exact birth reference:

```text
(stream_id, stream_epoch, birth_seq)
```

The fingerprint may help compare moments. It may not authorize identity,
lineage, security, relation, or routing.

## 8. Source And Prompt Boundary

The museum proves one stored numeric source. It does not settle production
prompt ingestion.

Selected v0 separation:

```text
session creation initializes L1 from an explicit bounded source adapter
Packet prompts do not reseed canonical L1
Packet prompts enter the newborn through normal FLOW/CHAOS birth material
the flow_mark and user prompt meet inside the Packet as separate provenance
```

This avoids making the supposedly continuing field a per-prompt hash function.

Still open:

```text
production default source adapter
whether later environmental events perturb canonical L1
whether a Packet receives any bounded local L1 projection beyond its birth mark
```

Until an experiment selects otherwise, prompt text has no right to mutate the
session L1 source.

## 9. Death, Manifest, And Re-entry

| Boundary event | Canonical L1 | Packet-carried mark |
|---|---|---|
| Packet running | Continues only on authorized flow-domain events | Immutable |
| Packet death | Survives | Frozen with corpse |
| `△` manifest | Unchanged unless a separate new birth is requested | Included only as provenance if a reader needs it |
| New generation birth | Advances once and emits a new mark | New Packet gets new envelope |
| Session close | Freeze/persist or end the stream epoch explicitly | Existing corpses remain immutable |

The manifest/corpse does not carry living L1 identity through `△`. A descendant
gets its own birth event and mark, even when it inherits grave/carrier material.

```text
identity never crosses △
lineage may cross through explicit carrier/grave records
flow continuity belongs to the domain, not to the corpse
```

## 10. Session Restart And Replay

Two honest restart policies are allowed:

| Policy | Required behavior |
|---|---|
| Persist | Store complete canonical L1 state, protocol, stream id/epoch, birth sequence, and source provenance atomically |
| New epoch | Initialize a new canonical state and increment/change stream epoch; never pretend uninterrupted continuity |

Replay requires:

```text
initial numeric source
canonical protocol/variant/config
ordered accepted L1 events
their deterministic advance counts
```

Wall-clock timing is not replay input in v0.

## 11. Concurrency Law

Births sharing one flow domain are serialized.

```text
one accepted birth -> one sequence -> one L1 tick -> one mark
```

Concurrent scheduling must not decide which mark a Packet receives silently.
The domain owner commits an explicit order. Separate sessions use separate L1
domains in v0 and therefore cannot perturb each other's marks.

## 12. Truth And Authority

| Claim | Truth/authority |
|---|---|
| L1 tick and measured snapshot occurred | `runtime_confirmed` |
| Snapshot semantically describes the prompt/task | No claim |
| This mark should change the route | No authority in v0 |
| Two marks imply related Packets | Forbidden inference |
| A descendant inherited a corpse/carrier | Lineage/grave evidence, not flow mark |

The first reader of `flow_mark` is audit/replay and the vertical-slice fixture.
There is deliberately no pressure reader in v0.

## 13. Cost Law

Canonical L1 movement has host/runtime cost but no Packet identity loss.

```text
L1 tick cost     -> measurable host compute/accounting
Packet loss      -> zero from birth mark itself
Packet LLM budget -> zero; no substrate call occurred
Packet step budget -> unchanged unless a later explicit policy buys L1 events
```

An implementation may record L1 compute in a separate domain ledger. It may
not hide that cost inside the Packet's ENCODE/CHOOSE loss.

## 14. Named Readers

| Record | Writer | First named reader | Read moment |
|---|---|---|---|
| Canonical L1 state | L1 domain owner | Next L1 event | Atomic advance |
| Flow mark envelope | Packet birth factory | Packet trace/audit | Birth commit |
| Flow mark envelope | Packet birth factory | Deterministic vertical-slice test | Before L2 projection |
| Persisted L1 state | Session persistence | Session restart loader | Domain recovery |

No router, CONNECT rule, semantic prompt builder, grave classifier, or lineage
matcher is an authorized v0 reader.

## 15. Matched Experiments

| ID | Setup | Required observation |
|---|---|---|
| F1 | Same source/config and same ordered births | Every mark envelope except external Packet ids reproduces |
| F2 | Same domain, two consecutive births | Birth sequence/tick differ lawfully; marks remain separately addressable |
| F3 | Search until bounded fingerprint repeats | Event envelopes remain distinct and ordered |
| F4 | Packet dies between two births | Source L1 continues; corpse mark stays unchanged |
| F5 | Two isolated sessions with same source/schedule | Each trajectory reproduces; one session's births do not advance the other |
| F6 | Birth transaction fails after tentative tick | No tick/sequence is committed |
| F7 | Remove flow mark from otherwise matched Packet | No route, semantic claim, loss, or budget changes in v0 |
| F8 | Persist/reload or explicitly start new epoch | Continuity is exact or discontinuity is named; never ambiguous |
| F9 | Two concurrent birth requests | Serialized order is explicit; no duplicate birth key |

F7 is the authority guard. A mark may be physically real and still have no
right to govern yet.

## 16. False-Green Matrix

| False green | Rejecting assertion |
|---|---|
| Global UUID called the L1 signature | Mark metrics must come from canonical L1 state |
| Fingerprint called globally unique | F3 requires lawful collision handling |
| Prompt hash substituted for flow | Prompt does not reseed v0 L1 |
| One L1 per Packet called continuing flow | Domain survives F4 |
| One hidden global L1 shared by all users | F5 isolation |
| Background spin called eternity | Only named events advance v0 |
| Packet death freezes session L1 | F4 source continues |
| Failed birth consumes a mark | F6 atomicity |
| Flow mark used as CONNECT whitelist | Section 12 forbids inference |
| Flow mark changes route before evidence | F7 must remain equal |
| Restart silently resets stream | Section 10 requires new epoch |
| Full mutable L1 copied into Packet | Envelope is bounded and immutable |

## 17. Amendment To The Previous L1 Boundary

This table partially supersedes Section 10 of
`l1_body_boundary_yellowprint.v0.md` for future production ownership.

Previous provisional law:

```text
L1 advances at most once per committed Packet body tick
L1 freezes on Packet terminal state
```

Selected replacement for the first integration:

```text
session-owned L1 advances once per accepted Packet birth
Packet terminal state freezes only its carried flow_mark
standalone L1 freeze remains valid for isolated states/session shutdown
body-tick advancement is not authorized
```

The parity law, standalone API, source separation, and negative controls in the
older table remain active.

## 18. Table Acceptance

This table is accepted when review agrees that it:

```text
preserves exact L1(C) physics
makes L1 older than one Packet without making it a hidden global
separates physical measurements from administrative uniqueness
defines one atomic and replayable birth clock
keeps prompt, lineage, CONNECT, routing, and identity distinct
does not charge false Packet loss or LLM budget
names readers for every new persistent record
```

Acceptance authorizes a crystall for the L1 domain/birth-mark boundary. It does
not authorize implementation, pressure, routing, or semantic claims.
