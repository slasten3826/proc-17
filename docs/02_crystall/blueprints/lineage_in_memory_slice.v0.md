# In-Memory Lineage Slice Blueprint v0

Status:

```text
crystall
source chaos: docs/00_chaos/lineage_in_memory_reconciliation_notes_2026-07-19.md
source table: docs/01_table/yellowprints/lineage_in_memory_slice_yellowprint.v0.md
amends: docs/02_crystall/blueprints/lineage_mechanics.v0.md
implementation authority: first linear in-memory lineage only
```

## 1. Manifested Boundary

This slice adds one outer state machine around the existing one-life body:

```text
shared L1
  -> Packet birth
  -> one complete tension_runner life
  -> immutable corpse
  -> completion assessment
  -> complete, suspend, exhaust, or one deterministic recovery carrier
  -> NETWORK@▽
  -> a new Packet identity
```

It does not add an operator, an edge, a second Packet constructor, a second
router, or a second completion ontology.

Hard laws:

```text
one Packet is one mortal Tree life
one lineage is one continuing task ancestry
☲ never crosses Packet identity
NETWORK@▽ never appears in Packet topology or trace
terminal Packet state is read-only
one corpse can produce at most one automatic child
lineage economics never reset at rebirth
harness/invariant failure is never converted into a corpse
```

## 2. Target Surface

```text
core/digest.lua                 NEW pure Lua SHA-256 and canonical record hash
runtime/lineage.lua             NEW lineage state, transactions, append-only ledger
runtime/lineage_budget.lua      NEW cumulative allocation and reconciliation
runtime/corpse.lua              NEW bounded terminal Packet projection
runtime/carrier.lua             NEW deterministic recovery carrier
runtime/network_ingress.lua     NEW carrier validation and child birth input
runtime/completion.lua          NEW body-owned plan.v0 terminal evaluation
runtime/lineage_runner.lua      NEW outer generational runner
runtime/tension_runner.lua      ADD trusted post-construction birth hook
runtime/session_memory.lua      ADD in-memory lineage index and ledger reader
tests/test_digest.lua           NEW
tests/test_lineage.lua          NEW
tests/test_lineage_budget.lua   NEW
tests/test_corpse.lua           NEW
tests/test_carrier.lua          NEW
tests/test_network_ingress.lua  NEW
tests/test_lineage_runner.lua   NEW
tests/run.lua                   register suites
```

Persistence, substrate-session ownership, build completion, hands and
branching are explicitly outside this change.

## 3. Canonical Digest

Module:

```lua
local digest = require("core.digest")

digest.sha256(text) -> lowercase_hex | nil, err
digest.record(value) -> lowercase_hex | nil, err
```

Implementation requirements:

```text
Lua 5.4 bitwise operators only
no shell and no external library
standard SHA-256 known vectors pass
digest.record uses core/json.lua canonical key ordering
non-JSON values fail loudly
the caller supplies an identity projection without its digest field
```

The digest proves byte identity only. It does not upgrade semantic truth.

## 4. Lineage State

Module:

```lua
local lineage = require("runtime.lineage")

lineage.create(task, options) -> state | nil, err
lineage.begin_generation(state, allocation) -> transaction | nil, err
lineage.commit_birth(state, transaction, instance, birth_receipt) -> entry | nil, err
lineage.register_corpse(state, corpse) -> entry | nil, err
lineage.mark_continued(state, corpse, carrier) -> true | nil, err
lineage.set_status(state, status, input) -> state | nil, err
lineage.finish(state, terminal) -> state | nil, err
lineage.append_event(state, event) -> stored | nil, err
lineage.validate(state) -> true | nil, err
```

### 4.1 Root

```lua
{
  kind = "proc17_lineage",
  protocol_version = "lineage.in_memory.v0",
  lineage_id = string,
  session_id = string,
  status = "created" | "running" | "evaluating_terminal"
        | "continuing" | "suspended" | "complete"
        | "exhausted" | "terminated",
  work_mode = "plan" | "build",
  completion_contract_id = "plan.v0" | string,
  task = {
    task_id = string,
    payload = string,
    input_hash = sha256,
    payload_bytes = integer,
    media_type = "text/plain",
    content_truth_status = string,
  },
  current_generation = integer,
  current_packet_id = string | nil,
  current_corpse_id = string | nil,
  current_carrier_id = string | nil,
  substrate_session_id = string | nil,
  generations = generation_entry[],
  ledger = lineage_event[],
  budget = lineage_budget,
  policy = table,
  continued_corpses = {[corpse_id] = carrier_id},
  terminal = table | nil,
}
```

`lineage.create` accepts injected `id_source` and `clock` for deterministic
tests. Production defaults allocate process-local ids and use `os.time`.

### 4.2 Generation Transaction

`begin_generation` is side-effect free except for one
`generation_allocated` ledger event. It returns:

```lua
{
  kind = "lineage_generation_transaction",
  transaction_key = string,
  lineage_id = string,
  generation = current_generation + 1,
  allocation = table,
  parent_packet_id = string | nil,
  parent_corpse_id = string | nil,
  ingress_carrier_id = string | nil,
  committed = false,
}
```

`commit_birth` validates all Packet identity fields against the transaction,
charges the generation once, appends one generation entry and one
`generation_born` event, then sets `status=running`. Repeating the same commit
fails; it is not idempotent mutation disguised as success.

Only `register_corpse` may fill the terminal fields of that generation entry,
and it may do so exactly once.

## 5. Birth Hook

`runtime/tension_runner.lua` gains:

```lua
options.on_packet_birth(instance, birth_receipt) -> true | nil, err
```

Order:

```text
Packet construction
budget.init
loss.init
on_packet_birth
grave attachment
▽ FLOW
```

The hook is a trusted harness boundary. It may register identity outside the
Packet; it may not mutate Packet state or choose a route. The runner snapshots
Packet body/trace/revisions before and after the hook and rejects mutation.
Hook throw/rejection is returned as `birth_hook:<error>` and no fake death or
grave is created.

## 6. Cumulative Budget

Module:

```lua
local lineage_budget = require("runtime.lineage_budget")

lineage_budget.new(limits) -> budget | nil, err
lineage_budget.can_allocate(budget, allocation) -> true | nil, err
lineage_budget.charge(budget, key, cost, source_refs) -> event | nil, err
lineage_budget.reconcile_packet(budget, corpse) -> event | nil, err
lineage_budget.snapshot(budget) -> table
```

Axes:

```text
steps substrate_calls prompt_tokens completion_tokens total_tokens
estimated_tokens tool_calls file_writes test_runs time_ms money_units
generations carrier_bytes
```

Rules:

```text
each configured limit is finite non-negative or "unlimited"
unknown axes fail
discrete axes remain integer
local Packet allocation cannot exceed lineage remaining
generation is charged after committed birth, not after preparation
Packet runtime spending is reconciled once by packet id
carrier bytes are charged once by carrier id
identity loss is local physics and never a lineage budget axis
```

`spent`, `remaining`, `events`, `charged_keys`, `exhausted` and
`exhausted_keys` remain body-owned data, not model claims.

## 7. Corpse Projection

Module:

```lua
local corpse = require("runtime.corpse")

corpse.capture(instance, options) -> corpse_record | nil, err
corpse.verify(record) -> true | nil, err
```

Capture requires `instance.status == "dead"`, one terminal record and one
death record. It copies only:

```text
identity and ancestry
terminal/death cause
manifest and residue
final loss and budget snapshots
terminal trace ref
bounded trace tail
completion evidence refs
frozen_at from terminal/death evidence
```

It excludes `field`, `calm`, active relations, route position, live runtime
stores and every mutable Packet alias.

Identity projection includes allocated `corpse_id` and excludes
`corpse_hash`. `corpse.verify` reconstructs that projection and rehashes it.

## 8. Completion

Amendment 2026-07-19: the decision order originally written below is rejected
because it lets lineage economics relabel task state. The active replacement is
[`lineage_completion_continuation_separation.v0.md`](lineage_completion_continuation_separation.v0.md).
The old order remains visible only to preserve the path by which the defect was
found.

Module:

```lua
local completion = require("runtime.completion")

completion.evaluate(lineage, corpse) -> assessment | nil, err
```

Decision order:

```text
unsafe/cancelled                         -> unsafe, not recoverable
exact plan.v0 manifest                   -> complete
unknown completion contract              -> unknown, not recoverable
lineage budget exhausted                 -> blocked/exhausted
budget_exhausted|identity_loss|stalled
  and policy allows recovery             -> unfinished, recoverable
everything else                          -> blocked, not recoverable
```

Active law:

```text
completion classifies task state and intrinsic terminal recoverability
lineage runner separately applies task state, policy and cumulative economics
```

Exact `plan.v0` requires all of:

```text
corpse terminal_kind=manifest and death_cause=complete
manifest.mode=plan_delivery
manifest.output.type=plan and status=complete
manifest.output.structured.protocol_version=plan.result.v0
manifest.assembly.rule=plan_delivery.v0
manifest.assembly.input_provenance=packet_state
manifest assessment ref names a current runtime-confirmed
  plan_completion_assessment in the corpse trace tail/evidence refs
```

CALM plan work units stay pending. Their semantic content is not promoted by
lineage completion.

## 9. Recovery Carrier

Module:

```lua
local carrier = require("runtime.carrier")

carrier.build_recovery(lineage, corpse, assessment, options) -> record | nil, err
carrier.verify(record, context) -> true | nil, err
```

The payload is deterministic and bounded:

```lua
payload = {
  original_task = lineage.task.payload,
  prior_manifest = corpse.manifest,
  residue = corpse.residue,
  remaining_work = assessment.remaining_work,
  source_generation = corpse.generation,
}
```

No model summarizes it. `payload_bytes` is the byte length of canonical JSON.
An oversize payload returns `carrier_too_large`; truncation is forbidden.

The carrier hash covers identity, ancestry, payload, truth statuses, loss and
source refs, but excludes `carrier_hash` itself.

## 10. NETWORK@▽ Ingress

Module:

```lua
local network_ingress = require("runtime.network_ingress")

network_ingress.prepare(lineage, carrier, options) -> ingress | nil, err
```

Validation checks:

```text
carrier hash
same lineage id
source corpse is lineage.current_corpse_id
source generation is current_generation
target generation is current_generation + 1
source corpse has not already produced a child
payload byte bound
```

Output:

```lua
{
  prompt = json.encode(carrier.payload),
  packet_options = {
    lineage_id = lineage.lineage_id,
    generation = carrier.target_generation,
    parent_id = carrier.source_packet_id,
    parent_corpse_id = carrier.source_corpse_id,
    birth_kind = "recovery",
    carrier_id = carrier.carrier_id,
    substrate_session_id = carrier.substrate_session_id,
    work_mode = lineage.work_mode,
    metadata = {work_mode = lineage.work_mode},
  },
  source_refs = {carrier.carrier_id, carrier.source_corpse_id},
}
```

The payload enters CHAOS normally through ▽. NETWORK is a boundary label only.

## 11. Session Integration

`session_memory.create/load` must ensure:

```lua
lineage_ids = {}
current_lineage_id = nil
lineage_ledger = {}
```

Add:

```lua
session_memory.append_lineage(session, lineage_id) -> session | nil, err
session_memory.append_lineage_event(session, event) -> session | nil, err
```

The session is an index/reader, not a second owner. Stored events are copied;
lineage state remains authoritative during the in-memory run.

When history is enabled, the runner obtains graves with
`session_memory.inherit_graves(..., {enabled=true})` before each birth and adds
the newly classified grave after corpse capture. When disabled, only these
attachments disappear; ancestry and cumulative cost must remain identical.

## 12. Outer Runner

Module:

```lua
local lineage_runner = require("runtime.lineage_runner")

lineage_runner.run(task, substrate, options) -> lineage, report | nil, err
```

The report contains copied generation reports, corpses, carriers,
assessments and final cumulative economics. It never contains a live Packet
alias.

Algorithm:

```text
validate options; create/reuse session and shared flow_domain
create lineage and register it in session
set ingress = original user task

while lineage can continue:
  derive local allocation and validate against cumulative remaining
  begin generation transaction
  run tension_runner with shared L1 and trusted commit_birth hook
  require a dead Packet; tick_limit/live return is an invariant failure
  capture and verify corpse
  register corpse and append Packet/grave to session
  reconcile Packet cost exactly once
  evaluate exact completion

  complete:
    finish lineage complete and return

  unsafe/unknown/nonrecoverable:
    finish terminated/suspended and return

  recoverable:
    build and verify one carrier
    charge carrier bytes
    mark source corpse continued exactly once
    prepare NETWORK@▽ ingress
    continue with generation + 1

  cumulative exhaustion:
    finish lineage exhausted and return
```

`emergency_max_generations` yields `suspended`, never `complete`.

### 12.1 Local allocation

First-slice options accept either:

```lua
packet_budget = table
packet_budget_for_generation = function(generation, lineage_snapshot) -> table
```

The callback is trusted harness policy and used mainly to grow a real
two-generation witness. Its output is validated and copied before Packet
birth. It cannot inspect or mutate a live Packet.

## 13. Failure Taxonomy

```text
Packet terminal caused by body physics
  -> normal corpse and completion evaluation

typed carrier/budget inability
  -> lineage suspended/exhausted, no child

unknown completion contract
  -> lineage suspended, never implicit completion

Lua exception, malformed runner return, live Packet return, hook mutation,
hash mismatch, ancestry mismatch, duplicate child
  -> loud error, lineage terminated, no synthetic corpse/grave
```

The last class is broken world machinery. It is not meaningful Packet death.

## 14. Required Evidence

Primitive suites:

```text
D0 SHA-256 empty/abc/long known vectors
D1 canonical object key order hashes equally; array order does not
C0 dead Packet gives stable verified corpse
C1 live Packet rejected
C2 corpse has no live field/CALM/runtime aliases
R0 recovery carrier hash and byte count stable
R1 oversize and tampered carrier rejected
N0 carrier yields exact generation-2 ingress
N1 wrong lineage/source/generation/hash rejected
B0 local allocation cannot exceed cumulative remaining
B1 Packet spending reconciles once
B2 generation/carrier boundary charges deduplicate
```

Grown lineage suites:

```text
L0 exact plan completes generation 1 and births no child
L1 generation 1 dies from real local budget; generation 2 completes
L2 child identity/parent/corpse/carrier refs are exact
L3 child has no parent CALM, field relations, operator or local loss
L4 no NETWORK operator/event exists in either Packet trace
L5 ☲ never changes generation
L6 cumulative spending spans both lives and carrier boundary
L7 source corpse cannot produce a second child
L8 oversize carrier suspends without child
L9 delivered plan content remains semantic_proposal
L10 injected runner/hook errors stay loud and grave-free
L11 history ablation changes grave attachment only
L12 ancestor Packet remains final and immutable after descendant completion
```

The L1 witness must grow its first corpse by running the real body. Synthetic
death fixtures cannot prove lineage continuation.

## 15. Implementation Order

```text
1  digest + tests
2  lineage state/ledger + tests
3  cumulative budget + tests
4  trusted birth hook + mutation guard + tests
5  corpse projection + tests
6  completion evaluator + tests
7  carrier + NETWORK ingress + tests
8  session index integration + tests
9  outer runner + one-generation witness
10 real two-generation recovery witness and full regression
```

No later step may compensate for a failed earlier invariant.

## 16. Promotion Boundary

Passing this blueprint proves only:

```text
proc-17 owns one linear task ancestry in memory
local Packet mortality and cross-Packet continuation are distinct
one real local death can produce one lawful descendant
one exact plan manifest can end the ancestry
```

It does not promote persistence, build work, repository mutation, substrate
memory, branching, CLI/TUI, or the Tree router beyond its existing policy.
