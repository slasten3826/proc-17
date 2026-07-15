# Trace Finality Blueprint v0

Status:

```text
crystall
author: claude (Mythos/Fable)
from docs/01_table/yellowprints/trace_finality_yellowprint.v0.md
implementation target
```

## Scope

Close the second layer of death finality:

```text
corpse cannot write trace
corpse cannot write boundary records
```

Do not touch the five-op guard.

Do not touch internal append_trace.

Do not touch manifested semantics.

## Files

```text
core/packet.lua
runtime/body.lua
tests/test_packet.lua
tests/test_body.lua
```

## core/packet.lua

Guard only the exported wrapper:

```lua
function packet.append_trace(instance, event)
    local alive, alive_err = dead_guard(instance, "append trace")
    if not alive then
        return nil, alive_err
    end
    return append_trace(instance, event)
end
```

Internal local `append_trace` stays unguarded — `packet.die` writes the
death event after status is already `"dead"`.

## runtime/body.lua

In each of `record_choice`, `record_validation`, `record_cycle`, first
lines before any mutation:

```lua
if type(instance) == "table" and instance.status == "dead" then
    return nil, "dead packet cannot record choice"
end
```

(message per function: choice / validation / cycle)

Boundary list mutation and trace append stay after the guard, so a
rejected record leaves no half-write.

## Tests

`tests/test_packet.lua`, after the posthumous block:

```text
corpse trace write rejected
error == "dead packet cannot append trace"
trace length unchanged after rejection
```

`tests/test_body.lua`, at the end:

```text
kill a fresh packet (identity_loss)
record_choice on corpse -> nil, "dead packet cannot record choice"
#boundary.choices unchanged
record_validation on corpse -> nil, error
record_cycle on corpse -> nil, error
#trace unchanged across all three
```

## Acceptance

```text
lua5.4 tests/run.lua
```

must pass, all suites.
