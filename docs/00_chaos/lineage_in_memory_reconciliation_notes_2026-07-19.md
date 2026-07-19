# In-Memory Lineage Reconciliation Notes

Status:

```text
chaos
date: 2026-07-19
reconciles: docs/02_crystall/blueprints/lineage_mechanics.v0.md
with current Packet/L1/plan-delivery runtime
code not authorized by this document alone
```

Follow-up 2026-07-19: the bounded implementation collapsed intrinsic terminal
recoverability, policy and lineage economics into one boolean. The grown defect
and treatment begin at
[`lineage_completion_economy_separation_notes_2026-07-19.md`](lineage_completion_economy_separation_notes_2026-07-19.md).
This document remains the historical source of that first-slice decision.

## Why This Is Next

Repository hands are the next product-bearing absence, but they are not the
next lawful body layer.

The existing architecture order is:

```text
one mortal Packet life
-> outer lineage owns task continuation across corpses
-> capability sandbox owns external mutation rights
-> hands mutate repository reality
```

Skipping lineage would leave generation, carrier, cumulative economics and
history under the harness. A hand would then work for one Packet, but proc-17
would still not own the life of one unfinished task.

The lineage runner is therefore core mechanics, not CLI/TUI convenience.

## What The Old Crystall Predicted Correctly

The old lineage blueprint correctly froze these laws:

```text
one Packet = one mortal body
one lineage = one task ancestry
identity never crosses terminal death
NETWORK@▽ is boundary ingress, not a twenty-third edge
☲ recurrence stays inside one identity
lineage continuation births a new identity
one living Packet and at most one automatic child per corpse in v0
reincarnation cannot reset task economics
carrier, grave history and substrate continuity are separate channels
lineage decisions require their own append-only ledger
```

None should be weakened.

## What Now Already Exists

The current body has implementations that were only predictions when the old
crystall was written:

```text
runtime/flow_domain.lua
  continuing L1 owner outside a Packet

runtime/packet_birth.lua
  atomic L1 tick plus newborn Packet construction

core/packet.lua
  lineage_id, generation, parent_corpse_id, birth_kind, carrier_id,
  substrate_session_id, terminal finality and immutable work regime

runtime/tension_runner.lua
  one complete mortal Tree life with internal death

runtime/grave.lua + runtime/session_memory.lua
  classification, session-scoped storage, attachment and compost

runtime/plan_completion.lua
  exact plan candidate, ☱ assessment and Packet-local △ projection
```

The first lineage implementation must reuse these records rather than create a
second birth, completion, grave or route ontology.

## Completion Correction

The old `plan.v0` completion text expected:

```text
body progress has no declared remaining structural work
```

That is now wrong for a delivered plan.

Plan items are descriptions of future work. They remain semantic content and
their CALM work-unit status remains `pending`. Marking them `done` merely to let
lineage finish would convert “the plan is completely assembled” into “the plan
has been executed”.

The current exact plan completion fact is instead:

```text
corpse came from manifest terminal
manifest.mode == plan_delivery
manifest.output.type/status == plan/complete
manifest.output.structured.protocol_version == plan.result.v0
manifest.assembly.input_provenance == packet_state
manifest references one current runtime-confirmed plan completion assessment
content truth status remains semantic_proposal or inherited status
```

This can complete a plan lineage without relabelling any proposed work as
executed.

Build completion remains stricter and is not part of this slice.

## First Implementation Slice

Implement one bounded in-memory lineage before persistence or hands.

Included:

```text
lineage state and append-only ledger
cumulative lineage budget
canonical bounded corpse projection and digest
deterministic recovery carrier and digest
NETWORK@▽ validation and birth input
plan.v0 completion evaluation
recoverable local budget/stall evaluation
outer runner over one shared flow_domain
session packet/grave attachment in memory
one or more linear generations until complete/suspended/exhausted
```

Deferred:

```text
disk persistence and crash recovery
session-owned substrate conversation adapter
build.v0 completion
repository hands
semantic carrier compaction
branching lineages
cross-lineage NETWORK
automatic external resume
full bequest/compost readers
```

Persistence is deferred because current sandbox storage is not yet symlink-safe
or atomic. The active in-memory lineage must still be fully auditable.

## Digest Boundary

Corpse and carrier identity require a canonical digest even before disk save.

Add pure Lua SHA-256:

```text
core/digest.lua
digest.sha256(text)
digest.record(table)
```

It must not shell out. Canonical object ordering comes from `core/json.lua`.
Digest fields exclude their own digest but include allocated ids. Same record
body must reproduce the same digest.

The digest proves record identity, not semantic truth.

## Corpse Boundary

`packet.freeze` already creates terminal finality. `runtime/corpse.lua` should
read that final body and project a bounded immutable external record.

It may carry:

```text
Packet/lineage/generation ancestry
terminal kind and death cause
manifest and residue
final budget and loss snapshots
terminal event ref
bounded trace tail
completion evidence refs
frozen time
```

It must not carry:

```text
live field
CALM object
route position
active relations or momentum
runtime stores
mutable Packet reference
```

Capture never mutates the corpse Packet.

## Recovery Carrier Boundary

The first carrier is deterministic and body-owned:

```text
original task descriptor
prior manifest when present
residue
remaining-work summary
source generation/corpse refs
```

It is canonical JSON with an explicit byte bound. Oversize is
`carrier_too_large`; no silent truncation and no LLM summarization.

Carrier semantic payload enters child CHAOS through FLOW. Envelope identity,
hash, ancestry and bounds remain Packet header/ingress metadata.

## Birth Transaction Gap

`tension_runner.run` currently constructs and runs a Packet inside one call.
The lineage must record a generation as born before that life executes, not
after receiving a corpse.

Minimal treatment:

```text
tension_runner option on_packet_birth(instance, birth_receipt)
called after Packet/budget/loss construction and before FLOW
trusted hook only
hook failure is loud harness failure
```

The hook gives lineage one narrow birth commit boundary. It may not mutate the
Packet or select its first route.

This avoids a second Packet constructor and keeps one-life routing untouched.

## Cumulative Economics

The first lineage budget supports:

```text
Packet axes: steps, substrate_calls, token axes, tool/file/test/time/money
Boundary axes: generations, carrier_bytes
finite non-negative values or explicit "unlimited"
```

Laws:

```text
local Packet allocation cannot exceed lineage remaining
generation is charged only after committed birth
actual Packet spending is reconciled once from the corpse
carrier bytes are charged once when carrier is accepted
deduplication keys prevent double charge
Packet identity loss resets because identity is new
lineage economic spending never resets
```

The host generation ceiling is emergency policy, not normal completion.

## Continuation Evaluation

First deterministic order:

```text
unsafe/cancelled -> terminate or suspend
exact plan completion -> complete
unknown completion contract -> suspend_unknown
lineage budget cannot pay -> exhausted
recoverable local death + recovery allowed + viable carrier -> continue
otherwise -> suspended/no_carrier
```

A Packet death cause named `complete` is insufficient by itself. For plan.v0,
the exact qualified plan manifest is the completion witness.

A local `budget_exhausted`, `identity_loss` or `stalled` corpse may be
recoverable when it has a bounded carrier and policy permits recovery. This is
not proof that repeating will help; grave warnings remain attached to the child.

## Runner Ownership

The outer runner owns:

```text
one shared flow_domain
one lineage state
one session/grave scope
generation allocation and birth commit
one-life packet_runner invocation
corpse capture
grave classification/storage
cumulative cost reconciliation
completion/continuation decision
carrier construction and NETWORK@▽ ingress
lineage terminal state
```

It must not own:

```text
internal operator routes
organ effects
semantic choice
Packet mutation after death
model wording of completion
```

## Required Grown Evidence

```text
L0 one exact plan life -> one corpse -> lineage complete -> no child
L1 first Packet dies from local budget, child is born through recovery carrier,
   child completes exact plan, lineage completes at generation 2
L2 second Packet has new id, generation+1 and exact parent/corpse/carrier refs
L3 child starts with empty CALM/relations/route and only bounded carrier/history
L4 NETWORK never appears in Packet topology trace
L5 ☲ never changes generation
L6 cumulative spent is sum of both corpses plus generation/carrier costs
L7 same corpse cannot produce two automatic children
L8 carrier oversize suspends visibly and births no child
L9 complete plan content remains semantic_proposal
L10 injected runner/hook failure remains loud; it is not buried as a grave
L11 history-off ablation changes attachment only, not ancestry or economics
L12 original Packet corpse rejects mutation after child completes
```

## Decision Pressure

If this slice passes, proc-17 will own both recurrences:

```text
☲    another impulse in one mortal body
lineage runner    another mortal body for one unfinished task
```

Only then can a capability-safe hand be attached without making the harness the
real immortal agent.
