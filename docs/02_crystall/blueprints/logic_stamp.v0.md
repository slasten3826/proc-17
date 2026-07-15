# Logic Stamp Blueprint v0

Status:

```text
crystall
author: claude (Mythos/Fable)
from docs/01_table/yellowprints/logic_stamp_yellowprint.v0.md
implementation target
```

## Files

```text
runtime/freshness.lua        evidence_fingerprint helper
runtime/tension_runner.lua   logic stamps in build mode
runtime/router.lua           stamp read before ☶ routing
tests/test_freshness.lua     fingerprint determinism/change
tests/test_router.lua        stamp blocks/opens the court
tests/test_tension_runner.lua  loop collapses to manifest
```

## runtime/freshness.lua

```lua
function freshness.evidence_fingerprint(instance)
    local evidence = instance and instance.runtime
        and instance.runtime.evidence or {}
    local parts = {tostring(#evidence)}
    for _, item in ipairs(evidence) do
        parts[#parts + 1] = tostring(item.intention_hash) .. ":"
            .. tostring(item.cast_tick) .. ":" .. tostring(item.success)
    end
    return spells.hash(table.concat(parts, "|"))
end
```

## runtime/tension_runner.lua

In `logic_placeholder`, build-mode branches (both no_spell and
spell-run paths), before `body.record_validation`:

```lua
instance.runtime.logic_stamp = {
    kind = "logic_stamp",
    verdict = payload.status,
    evidence_fingerprint = freshness.evidence_fingerprint(instance),
    stamped_at_tick = instance.physis and instance.physis.clock
        and instance.physis.clock.ticks or nil,
    truth_status = "runtime_confirmed",
}
```

## runtime/router.lua

`pressure_snapshot` gains:

```lua
logic_stamp = runtime.logic_stamp,
evidence_fingerprint = freshness.evidence_fingerprint(instance),
```

`route_runtime`, replace the missing_build_evidence rule:

```lua
if build_mode and pressure.progress.remaining_count > 0
    and pressure.evidence_count <= 0 then
    local stamp = pressure.logic_stamp
    if stamp and stamp.evidence_fingerprint == pressure.evidence_fingerprint then
        return "△", "logic_stamp_no_new_evidence"
    end
    return "☶", "missing_build_evidence"
end
```

## Tests

test_freshness:

```text
fingerprint is deterministic for same evidence
fingerprint changes when evidence appended
empty evidence has a stable fingerprint
```

test_router:

```text
build + remaining work + no evidence + no stamp -> ☶
same but fresh stamp -> △ logic_stamp_no_new_evidence
same but stamp with different fingerprint -> ☶ (court reopens)
```

test_tension_runner:

```text
build mode, fake substrate, no spells configured:
stop_reason == "manifested" (not tick_limit)
trace contains exactly one ☶
manifest payload exists
```

## Acceptance

```text
lua5.4 tests/run.lua              all green
lua5.4 tests/smoke_deepseek_coding_battery.lua
                                  verdicts flip to reality_confirmed
```
