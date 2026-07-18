# Body Integrity Gate Manifest v0

Status:

```text
manifest
roadmap step 2
implemented and locally verified 2026-07-18
source crystall: docs/02_crystall/blueprints/body_integrity_gate.v0.md
```

## Result

The existing body now owns the mutable records that it claims as
`runtime_confirmed`. Public mutation boundaries no longer depend on caller
discipline alone.

The gate closes four pre-existing bypasses:

```text
caller-owned tables cannot rewrite stored body history
an organ write must belong to the current glyph and current visit
invalid economic values cannot create budget or corrupt a ledger
changed referents invalidate the LOGIC evidence fingerprint exactly once
```

This is a repair of existing body physics. It does not promote tree authority,
integrate L1/L2, add hands, or change topology.

## Red Evidence

The permanent gate suite was first run against the untreated body. It reproduced
all targeted bypass classes:

```text
caller fragment changed stored CHAOS
caller/current aliases rewrote crystallization history
caller residue changed the corpse
CHOOSE could write while the Packet was at FLOW
an event from an old visit authorized a current field mutation
body/foundation results shared mutable records with storage
malformed budget cost was accepted
a changed file left the evidence fingerprint unchanged
```

The tests were not weakened after treatment.

## Manifested Contracts

### Owned records

Packet, trace, CALM, boundary, foundation, economic ledgers, grave, session
memory, packet memory, terminal data, and corpse projections copy mutable input
before storage. Publicly returned records are independent copies. Separate body
projections do not share mutable children merely because they came from one
input table.

### Current-visit authority

Mutation rights are derived from the immutable trace:

```text
actor == packet.operator
current visit contains that organ's operator_tick
field source event belongs to that visit
```

FLOW before the first route uses the birth event as its one birth lease. Core
route, cost, loss, and terminal physics retain dedicated body contracts rather
than pretending to be organ writes.

### Honest economics

Budget charge rejects unknown axes, non-numeric values, negative values,
non-finite values, and fractional values on discrete axes before any mutation.
Malformed substrate usage remains a loud harness error. Loss applies the same
non-negative finite law. Zero cost is a no-op and creates no ledger event.

### Causal truth rent

Evidence fingerprints now combine immutable cast identity with the current
referent state. A file changing from A to B creates one validation debt. A new
LOGIC cast and stamp for B discharge that debt; unchanged B does not produce a
recurrent validation loop.

## Runtime Evidence

```text
lua tests/run.lua                              47 suites passed
tree authority Gate A                         10/10 passed
tree instrumentation Gate B                   7/7 passed
tree manifest honesty                         4/4 passed
lua tests/smoke_mortality_battery.lua          8/8 passed
lua tests/smoke_runtime_camera_treatment.lua   passed
lua tests/smoke_pressure_ablation.lua          passed
luac -p over all Lua sources                   passed
git diff --check                              passed
```

The camera treatment smoke retained its prior routes and economics:

```text
plan   steps=8 substrate_calls=3 loss=0.500
build  steps=9 substrate_calls=3 loss=0.500
```

Therefore the integrity treatment changed write authority and record ownership,
not normal route, budget, loss, or mortality behavior in the measured corpus.

## Explicit Limits

```text
Packet remains a trusted mutable Lua object, not an opaque security proxy
one valid current visit may perform multiple declared writes
multi-write organs do not yet have general transaction rollback
per-object relation and upper-eye version coverage remains open
L1/L2 lifecycle and pressure witnesses remain roadmap steps 3-5
```

The last item is not silently declared fixed. It requires the L1/L2 referent
contract and is the next architectural boundary.

## Decision

Roadmap step 2 is complete. The body is sufficiently coherent to crystallize
the already selected L1/L2 tables without granting new organs power over
unowned or unauditable state.
