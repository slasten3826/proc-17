# Truth Rent Blueprint v0

Status:

```text
crystall
author: claude (Mythos/Fable)
from docs/01_table/yellowprints/truth_rent_yellowprint.v0.md
implementation target
```

## Scope

```text
run the body clock
stamp spell results with clocks
add the freshness reader
teach foundation.snapshot to read the clock
```

Do not touch: trace events, budget axes, router, foundation
strength arithmetic.

## Files

```text
runtime/tension_runner.lua   (advance clock)
logic/spells.lua             (clock + referent fields)
runtime/freshness.lua        (NEW: the reader)
runtime/foundation.lua       (snapshot reads freshness)
tests/test_freshness.lua     (NEW)
tests/test_foundation.lua    (stale pattern surfacing)
tests/test_spells.lua        (clock fields present)
tests/run.lua                (register test_freshness)
```

## runtime/tension_runner.lua

In the main loop, next to `budget.charge` (one place):

```lua
local clock = instance.physis and instance.physis.clock
if clock then
    clock.ticks = (clock.ticks or 0) + 1
end
```

In `logic_placeholder`, before `spells.run(spell_input)`:

```lua
spell_input.tick = instance.physis and instance.physis.clock
    and instance.physis.clock.ticks or nil
```

## logic/spells.lua

`result(input, fields)` gains:

```lua
cast_tick = input.tick,
referent = fields.referent,
referent_hash = fields.referent_hash,
```

File-based runners (`py_compile`, `validate_json_file`,
`check_file_exists`) pass:

```lua
referent = path,
referent_hash = content and stable_hash(content) or nil,
```

(read content once at cast; for missing file referent_hash = nil,
tick window covers it). Command/loss runners pass no referent —
tick window is their only clock.

Export `spells.referent_hash(path)` -> hash of current file content
or nil (reused by the reader; sandbox-checked).

## runtime/freshness.lua (NEW)

```lua
freshness.read(record, opts) -> {
    zone = "hot" | "warm" | "cold" | "unclocked",
    effective_truth_status = "runtime_confirmed" | "semantic_proposal",
    reason = "referent_verified" | "inside_tick_window"
           | "referent_changed" | "tick_window_expired"
           | "no_clock",
    age = number | nil,
}
```

Rules, in order:

```text
1. record.referent_hash present:
     current = spells.referent_hash(record.referent)
     match    -> hot,  keep confirmed
     mismatch -> cold, semantic_proposal (referent_changed)
2. record.cast_tick present (no referent hash):
     age = opts.tick - record.cast_tick
     age <= warm_window -> warm, keep confirmed
     age >  warm_window -> cold, semantic_proposal
3. neither -> unclocked, semantic_proposal (no_clock)
```

`opts = {tick = current_tick, warm_window = 8 (default, vibed)}`.
The reader never writes to the record.

## runtime/foundation.lua

`foundation.snapshot(instance, opts)`:

- per pattern with `last_result`: run `freshness.read` with current
  tick from `instance.physis.clock.ticks`; snapshot pattern gains
  `freshness`, `effective_truth_status`, `reason`
- aggregate gains `stale_count`, `contains_stale`
- aggregate `truth_status` stays `runtime_confirmed` — it certifies
  the counters and the snapshot act; contents speak for themselves

## Tests

`tests/test_freshness.lua`:

```text
referent hash match          -> hot, confirmed
referent file mutated        -> cold, semantic_proposal
tick-window record fresh     -> warm, confirmed
tick-window record aged      -> cold, semantic_proposal
record without clock         -> unclocked, semantic_proposal
reader does not mutate record
```

`tests/test_spells.lua` additions:

```text
py_compile result carries cast_tick, referent, referent_hash
check_command result carries cast_tick, no referent_hash
```

`tests/test_foundation.lua` additions (integration lesson —
staleness must be EARNED):

```text
cast real py_compile spell on scratch file (with tick)
reinforce; snapshot -> pattern hot, contains_stale = false
mutate the scratch file
snapshot -> pattern cold, effective semantic_proposal,
            contains_stale = true
recast spell (new run, later tick); reinforce
snapshot -> pattern hot again  (☲ recast paid the rent)
```

## Acceptance

```text
lua5.4 tests/run.lua
```

all suites green.
