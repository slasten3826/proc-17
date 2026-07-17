# Tree Authority Opt-In Results - 2026-07-17

Status:

```text
chaos / runtime evidence
transition step: 2 of 5
Gate A: confirmed
default authority: legacy through shadow mode
opt-in authority: tree
```

## What Changed

The old authority was not removed. An explicit life may now be born with:

```lua
router_mode = "tree"
```

In that life, the full-tree router derives the first edge after FLOW and every
later edge from Packet pressure. It does not ask the legacy router for a route
first. The temporary mandatory eye rails therefore have no live authority in
this mode.

Default runs still use `shadow`: legacy moves the Packet and the tree only
observes. The instrumentation flip belongs to transition step 3.

## Gate History

The first independent gate had:

```text
green = 1
red   = 6
```

During treatment it reached `5 green / 2 red`. The remaining failures exposed
two real writer-reader defects rather than bad weights:

```text
ENCODE did not follow OBSERVE legacy refs transitively
relation and upper-eye debts recreated themselves from receiver output
```

After treatment, the expanded permanent gate has:

```text
green = 10
red   = 0
```

It now lives in `tests/test_tree_authority.lua` and is part of `tests/run.lua`.

## First Manifested Tree Life

Command shape:

```text
fake substrate
work_mode = build
router_mode = tree
one passing file-existence spell
```

Observed result:

```text
walk:                ▽ ☰ ☵ ☲ ☶ ☱ △
ticks:               7
stop_reason:         manifested
final_status:        dead
death_cause:         complete
validations:         1
identity_loss:       0.5
manifest provenance: packet_trace
```

This is the first normal life in the current body where neither the harness nor
the legacy router chooses the road after FLOW.

## Confirmed Laws

### Route evidence is binding

Every committed tree route references:

```text
an immutable edge_pressure_snapshot
an immutable route_derivation
the ready, non-excluded selected candidate recorded by that derivation
```

Forged or mismatched refs are invariant failures and cannot move the Packet.

### Candidate refusal is free

An unavailable or unready neighbor is excluded during derivation. It is not
entered, does not receive a tick and does not spend budget or identity.

If no viable edge remains, the coherent body dies `stalled` and residue keeps
the exact stall kind plus candidate-audit refs.

### World failure and broken physics are different

A valid typed external `effect_failure` becomes an `operator_failure` event,
pays the attempted tick and only explicitly confirmed external usage, captures
a runtime frame and ends as an honest Packet death.

A Lua exception, trusted invariant violation or malformed effect-failure object
escapes as a harness failure. It cannot become a corpse, grave or promotion
evidence.

### Manifest material belongs to the Packet

MANIFEST reconstructs bounded input from Packet trace records. Harness result
data remains only a visible compatibility fallback. The successful tree life
used `input_provenance = packet_trace`.

## Treatment Learned From Live Loops

Early opt-in lives did not manifest. Their roads were useful diagnostics:

```text
☴ ☰ ☵ ☰ ☵ ...
☴ ☰ ☵ ☲ ☵ ...
☴ ☰ ☵ ☲ ☶ ☲ ☱ ...
```

The fixes were not pressure-weight tuning:

```text
CONNECT relation debt now names uncovered semantic source units
OBSERVE output does not demand immediate self-observation
ENCODE identity maps include transitive source units
a fresh LOGIC stamp suppresses continuation and creates manifest pressure
```

The sampled policy preserves historical revision-staleness behavior as an
explicit diagnostic control.

## Verification

```text
tests/test_tree_authority.lua          10/10 green
tests/run.lua                          42 suites green
smoke_mortality_battery.lua            8/8 green
smoke_runtime_camera_treatment.lua     green
smoke_pressure_ablation.lua            green
```

## Boundary After Step 2

Done:

```text
explicit tree authority
body-derived FLOW entry
typed no-viable and effect-failure terminals
strict route evidence
Packet-local normal manifest
```

Not done:

```text
legacy-as-shadow instrumentation during tree lives
tree-life promotion corpus
default authority flip
pressure calibration
repository hands
```

The revolution has begun, but the old authority is still the default control.
