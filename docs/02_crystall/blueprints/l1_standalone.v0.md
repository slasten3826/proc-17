# L1 Standalone Blueprint v0

Status:

```text
crystall / exact standalone port
date: 2026-07-18
table: docs/01_table/yellowprints/l1_body_boundary_yellowprint.v0.md
target interpreter: Lua 5.4
target module: l1/field.lua
Packet integration: forbidden
pressure/router integration: forbidden
```

## 0. Scope

Manifest exactly four operations:

```text
initialize
tick
snapshot
freeze
```

The module has no dependency on `core.packet`, operator registry, topology,
budget, loss, camera, substrate, or router.

## 1. Public Contract

```lua
local l1 = require("l1.field")

local state, err = l1.initialize(source, options)
local same_state, err = l1.tick(state)
local view, err = l1.snapshot(state)
local frozen, err = l1.freeze(state)
```

`source` is an ordered Lua array of at least three Lua 5.4 integers.

Options:

```lua
{
  variant = "C",                 -- only accepted variant in v0
  source_ref = string,            -- immutable provenance label
  max_source_units = integer,     -- default 16384
}
```

The module normalizes source integers with `% 59049`. It does not retain the
full source sequence after initialization.

## 2. State Shape

```lua
{
  protocol_version = "l1.field.v0",
  interpreter_contract = "lua-5.4",
  variant = "C",
  modulus = 59049,
  ring_size = integer,
  core = integer[],
  l1_trace = integer[],
  phase = integer[],
  carry = integer,
  position = integer,
  ticks = integer,
  frozen = boolean,
  source = {
    ref = string,
    count = integer,
  },
}
```

The state is standalone mutable research state. It is not a Packet event and
must never be appended wholesale to `packet.trace`.

## 3. Exact Physics

Constants:

```text
MOD = 59049
crazy trit width = 10
crazy lookup rows =
  {1,0,0}
  {1,0,2}
  {2,2,1}
```

Initialization for every source index `i`:

```text
core[i]     = source[i] % MOD
phase[i]    = (i - 1) % 3
l1_trace[i] = crazy(core[i], phase[i])

carry   = source[1] % MOD
position = 1
ticks    = 0
```

One variant-C tick:

```text
p       = position
q       = (p % ring_size) + 1
bias    = crazy(phase[p], (p - 1) % MOD)
operand = crazy(crazy(core[p], l1_trace[p]), bias)
res     = crazy(carry, operand)

carry       = res
core[p]     = crazy(res, l1_trace[p])
l1_trace[p] = crazy(l1_trace[p], bias)
position    = q
ticks       = ticks + 1
```

No optimization may alter operation order before parity passes.

## 4. Snapshot

Return a newly allocated table:

```lua
{
  protocol_version = "l1.snapshot.v0",
  variant = "C",
  tick = state.ticks,
  position = state.position,
  carry = state.carry,
  fingerprint = integer,
  trace_density = integer,
  distinct_core = integer,
  distinct_l1_trace = integer,
  ring_size = integer,
  source_ref = string,
  event_truth_status = "runtime_confirmed",
  content_truth_status = "non_semantic_measurement",
}
```

Fingerprint law:

```text
h = carry % MOD
h = crazy(h, core[position])
h = crazy(h, l1_trace[position])
h = crazy(h, position - 1)
```

Repeated snapshots without a tick are exactly equal by value and do not mutate
the state.

## 5. Freeze And Errors

`freeze` is idempotent and sets only `frozen=true`.

After freeze:

```text
tick -> nil, "L1 state is frozen"
snapshot -> remains legal
freeze -> same state, no additional mutation
```

Invalid caller input returns `nil, message`. Lua/infrastructure errors are not
converted into L1 death because standalone L1 does not own Packet lifecycle.

## 6. Bounds

```text
minimum source count = 3
default maximum = 16384
caller may choose a smaller positive maximum >= 3
caller may not raise v0 above 16384
all source entries must be Lua 5.4 integers
```

The parity fixture count `7965` fits inside the default bound.

## 7. Exact Parity Tests

Full museum fixture:

```text
tests/fixtures/l1_processlang_bootstrap_machine_ru_v2.lua
```

Expected snapshots:

```text
t=1      pos=2 carry=29525 fp=6887  density=7955 dcore=1168 dtrace=794
t=7965   pos=1 carry=29861 fp=0     density=7964 dcore=1642 dtrace=4444
t=15930  pos=1 carry=338   fp=29188 density=7964 dcore=2715 dtrace=1140
```

Small full-trajectory fixture:

```text
source = {1,2,3,4,5,6,7,8}
ticks = 16
every fingerprint from t=0 through t=16 is hardcoded from an independent
museum-law probe before the test consumes the new module
```

## 8. Pre-registered Baselines

V7 static hash:

```text
h0 = 0
for each source value:
  h = (h * 131 + value) % 59049
output remains h at every checkpoint
```

V8 seeded PRNG:

```text
seed0 = 0
for each source value:
  seed = (seed * 131 + value) % 2147483648
per tick:
  seed = (1103515245 * seed + 12345) % 2147483648
  output = seed % 59049
```

Pre-registered comparison over S1/S2 and ticks 0..16:

```text
distinct output/fingerprint count
repeated output count
first S1/S2 divergence tick
```

Field-only metrics (`distinct_core`, `distinct_l1_trace`, density) may establish
L1 state behavior but may not be presented as a fair advantage over baselines
that do not claim a field.

## 9. Test Matrix

| ID | Assertion |
|---|---|
| P1a | Full fixture matches all three museum checkpoints |
| P1b | Small fixture matches every registered tick |
| P1c | Lua contract reports 5.4 and test runner uses Lua 5.4 |
| S1 | Same source produces identical states/snapshots |
| S2 | Snapshot is observational only |
| S3 | Exactly one ring position advances per tick |
| S4 | Freeze is idempotent and terminal for mutation |
| S5 | Bounds, variant, and integer validation reject invalid inputs |
| V1-V9 | Only pre-registered metrics/checkpoints are reported |

## 10. Explicit Non-Integration

The module must not:

```text
write packet.chaos
write packet.field
append packet.trace
charge budget or loss
create pressure
register an operator
choose a route
call an LLM
read a repository
```

Passing this crystall proves only standalone P1 and supplies measurements for
P2. P3 remains red by construction.
