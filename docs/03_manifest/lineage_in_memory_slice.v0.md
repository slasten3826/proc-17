# In-Memory Lineage Slice Manifest v0

Status:

```text
manifest
implemented and locally verified 2026-07-19
source chaos: docs/00_chaos/lineage_in_memory_reconciliation_notes_2026-07-19.md
source table: docs/01_table/yellowprints/lineage_in_memory_slice_yellowprint.v0.md
source crystall: docs/02_crystall/blueprints/lineage_in_memory_slice.v0.md
scope: linear in-memory ancestry and exact plan.v0 completion
decision truth status: document_decision
```

## Result

proc-17 now owns two different forms of recurrence without confusing them:

```text
☲ CYCLE
  another paid impulse inside one living Packet identity

lineage runner
  another Packet identity born from one terminal corpse
```

One Packet remains one mortal Tree life. The outer lineage is the task ancestry
that can survive that local death.

The implemented boundary is:

```text
shared L1
-> Packet birth
-> one complete tension_runner life
-> dead Packet
-> immutable hashed corpse
-> exact completion assessment
-> complete, suspend, exhaust, or one recovery carrier
-> NETWORK@▽
-> clean descendant Packet
```

No twenty-third operator or topology edge was introduced. NETWORK is the name
of a boundary transformation; it never appears in Packet route or tick trace.

## Owned Records

The slice adds:

```text
core/digest.lua
  pure Lua 5.4 SHA-256 and canonical JSON record identity

runtime/lineage.lua
  ancestry state, one pending birth transaction, generation entries,
  one-child-per-corpse law and append-only lineage ledger

runtime/lineage_budget.lua
  cumulative task economics across every local Packet budget plus
  generations and carrier bytes

runtime/corpse.lua
  bounded terminal projection with no live field, CALM, route or runtime alias

runtime/completion.lua
  exact plan.v0 terminal reader and typed unfinished/blocked/unsafe/unknown states

runtime/carrier.lua
  deterministic bounded recovery payload with explicit applicability status

runtime/network_ingress.lua
  hash, ancestry, generation and byte-bound validation before child birth

runtime/lineage_runner.lua
  outer linear state machine over one shared flow_domain and session scope
```

`runtime/tension_runner.lua` exposes one guarded `on_packet_birth` hook after
Packet budget/loss initialization and before FLOW. The hook can commit external
lineage identity but cannot mutate the Packet; before/after canonical hashes
enforce that boundary.

`runtime/session_memory.lua` indexes lineages and copies their events. It is a
reader/index, not a second authority over active lineage state.

## Death And Rebirth

The corpse projection carries bounded ancestry, terminal/death facts, manifest,
residue, final economics, terminal evidence and a trace tail. It explicitly
does not carry the live field, CALM, relations, operator position or mutable
runtime stores.

The first recovery carrier contains:

```text
original task
prior manifest when one exists
bounded residue
remaining-work summary
source generation
```

Its payload is canonical JSON. Oversize is `carrier_too_large`; nothing is
silently truncated and no LLM is asked to summarize it. Semantic payload enters
the newborn through normal FLOW. Hash, ancestry, generation and byte bounds
remain body-owned envelope facts.

The child receives:

```text
new Packet id
same lineage id
generation + 1
exact parent Packet id
exact parent corpse id
exact carrier id
birth_kind = recovery
```

It does not receive parent CALM, active relations, operator state, local loss or
runtime ledgers.

## Completion Boundary

`plan.v0` completion does not mark plan work units as executed. A plan describes
future work, so its CALM items correctly remain pending semantic content.

The lineage finishes only when the corpse contains the exact qualified terminal
chain:

```text
manifest terminal and death_cause=complete
manifest.mode=plan_delivery
output.type/status=plan/complete
output.structured.protocol_version=plan.result.v0
assembly.rule/input_provenance=plan_delivery.v0/packet_state
runtime-confirmed plan completion assessment named by the manifest
```

Body assembly and death are runtime-confirmed. Plan item content remains
`semantic_proposal` or its inherited content status.

Local `budget_exhausted`, `identity_loss` and `stalled` deaths may be recoverable
when policy and cumulative economics permit. Unknown completion contracts do
not become implicit success.

## Economics

Rebirth resets Packet-local identity loss because the descendant is a new
identity. It does not reset task economics.

The lineage budget reconciles actual spending from every corpse and also
charges:

```text
one generation after each committed birth
canonical carrier payload bytes after carrier acceptance
```

Charge keys are deduplicated. Reusing one key with a different cost is an
invariant failure. Actual Packet overspend is still recorded as fact and makes
the lineage exhausted; it is not erased because a declared allocation was too
small.

## Grown Evidence

The permanent corpus includes:

```text
L0 exact plan completes in generation 1; no child exists

L1 generation 1 executes real body ticks and dies budget_exhausted at step 2
   one corpse and one recovery carrier are produced
   generation 2 is born through NETWORK@▽ and completes the exact plan

L2-L6 ancestry, clean birth, absent NETWORK trace, immutable generation,
      and cumulative economics are checked

L8 tiny carrier bound suspends visibly and births no child

L9 delivered semantic content remains semantic_proposal

L10 injected packet-runner failure stays loud and creates no synthetic grave

L11 history on/off changes newborn grave attachment, not lineage ancestry

L12 the source dead Packet rejects mutation after its descendant completes
```

Primitive tests also cover SHA-256 known vectors, canonical map order, corpse
alias isolation, tampered hashes, wrong carrier ancestry, duplicate birth
transactions, duplicate child attempts and cumulative charge deduplication.

Verification:

```text
lua tests/run.lua                              76 suites passed
tests/test_digest.lua                          passed
tests/test_lineage_budget.lua                  passed
tests/test_lineage.lua                         passed
tests/test_lineage_birth_hook.lua              passed
tests/test_corpse.lua                          passed
tests/test_lineage_completion.lua              passed
tests/test_carrier.lua                         passed
tests/test_network_ingress.lua                 passed
tests/test_lineage_runner.lua                  passed
lua tests/smoke_mortality_battery.lua          8/8 passed
lua tests/smoke_runtime_camera_treatment.lua   passed
lua tests/smoke_pressure_ablation.lua          passed
luac -p over all Lua sources                   passed
git diff --check                               passed
```

## Failure Boundary

Typed Packet death belongs to body physics and can become a corpse.

These remain broken-world failures instead:

```text
Lua exception
malformed packet-runner return
live Packet returned as a completed life
birth hook mutation or identity mismatch
corpse/carrier hash mismatch
duplicate generation transaction or duplicate child
```

They terminate the outer attempt loudly and do not fabricate mortality,
residue or graves.

## Deliberate Limits

This manifest does not claim:

```text
persistent lineage or crash recovery
automatic resume
branching descendants
provider-owned substrate conversation continuity
semantic carrier compaction
build.v0 completion
repository hands
CLI or TUI integration
default Tree router promotion
```

The first slice proves that proc-17 can own a task across mortal Packet
generations in memory. The next product-bearing pressure is capability-safe
repository work, not a larger claim about immortality.
