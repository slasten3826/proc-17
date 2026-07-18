# Body Integrity Gate Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/body_integrity_gate_yellowprint.v0.md
implementation target for roadmap step 2
```

## Scope

Close four existing bypasses without changing topology, router authority, L1/L2
integration, operator pressure weights, hands, CLI, or TUI.

## Files

Primary implementation:

```text
core/packet.lua
runtime/body.lua
runtime/field.lua
runtime/foundation.lua
runtime/freshness.lua
runtime/budget.lua
runtime/loss.lua
runtime/grave.lua
runtime/packet_memory.lua
runtime/session_memory.lua
runtime/tension_runner.lua
organs/encode.lua
organs/choose.lua
organs/logic.lua
```

Tests:

```text
tests/test_body_integrity.lua        NEW: ownership + actor/tick gate
tests/test_budget.lua                invalid/atomic charges
tests/test_freshness.lua             derived fingerprint
tests/test_foundation.lua            earned stale -> debt -> recast
tests/test_field.lua                 current-visit source event
tests/test_packet.lua                returned event/corpse isolation
tests/run.lua                        register gate suite
```

## 1. Core Packet Contract

Add exported read-only helpers:

```lua
packet.assert_actor_tick(instance, actor, operation)
    -> lease_event_copy | nil, error

packet.event_in_current_tick(instance, actor, event_id)
    -> event_copy | nil, error
```

The first verifies position and derives the current visit from trace. The second
also proves source-event membership. `▽` before the first route uses `birth`.

The exported `packet.append_trace` calls `assert_actor_tick` for `event.operator`.
Private core writes keep using local `append_trace`.

All local trace appends store a deep copy and return another deep copy. All core
write boundaries listed in the yellowprint deep-copy before storing. Separate
Packet projections receive separate copies.

`packet.crystallize` becomes the sole owner of its CALM projection, including
`work_units` when present in `calm_delta`. `organs/encode.lua` must stop assigning
`instance.calm.*` directly after crystallization.

## 2. Body and Field Contract

Before mutation:

```text
record_observation -> assert glyph of selected eye
record_choice      -> assert ☳
record_validation  -> assert ☶
record_cycle       -> assert ☲
foundation         -> assert ☶
append_chaos       -> assert supplied/current actor
crystallize        -> assert ☵
```

Field writes call the same actor guard. Writes carrying event refs additionally
call `event_in_current_tick`. FLOW creation accepts only its own birth event.

Boundary records and returned records are independent copies. Work units are
deep-copied. `organs/choose` applies activation to its returned choice payload;
the immutable recorded choice retains the planned state and field versions carry
the applied effect.

## 3. Budget Contract

Add:

```lua
budget.validate_cost(cost, options) -> normalized_cost | nil, error
```

It rejects unknown axes and malformed amounts before `ensure()` or any mutation.
`budget.init` validates configured limits. `budget.from_usage` returns
`normalized_cost` or `nil, error`.

Budget and loss ledger writers store and return independent records. `loss.apply`
also rejects negative and non-finite amounts before mutating identity state.

`tension_runner` propagates validation/charge errors as harness errors. Invalid
external usage is not converted into Packet death or ignored.

## 4. Truth Rent Contract

Extend `freshness.read` with:

```text
current_referent_hash
referent_present
```

No stored evidence is changed.

`freshness.evidence_fingerprint(instance, opts)` reads current tick, derives each
record's current tuple from the yellowprint and hashes it deterministically.
Current file content changes the fingerprint even when both old and new states
are already `cold`.

The existing LOGIC stamp and pressure reader keep comparing fingerprints; their
behavior changes causally without a second stale flag.

`organs/logic.lua` copies each spell input before adding `tick`, so caller-owned
spell configuration is not mutated.

## 5. Red Baseline

Before treatment, the new tests must reproduce at least:

```text
caller alias mutates CHAOS/corpse
wrong-position choice succeeds
negative budget creates remaining budget
changed file leaves evidence fingerprint unchanged
```

Capture this as expected red output. Do not weaken tests to accommodate current
behavior.

## 6. Verification Order

```text
1. tests/test_body_integrity.lua (red -> green)
2. tests/test_budget.lua
3. tests/test_freshness.lua + tests/test_foundation.lua
4. tests/test_field.lua + organ tests
5. lua tests/run.lua
6. lua tests/smoke_mortality_battery.lua
7. lua tests/smoke_runtime_camera_treatment.lua
8. luac -p all Lua sources
```

## 7. Acceptance

Step 2 is complete only when:

```text
I01-I13 are green
all pre-existing suites are green
normal route/economics/mortality evidence remains unchanged
F4 remains explicitly deferred, not silently declared fixed
working tree contains a treatment record describing any contract deviation
```
