# Packet Death Finality Bug Notes

Status:

```text
chaos
from Claude/Mythos cold review
runtime defect
```

## Bug

Packet status was written but not enforced.

After:

```text
packet.status = "dead"
```

the core packet API still allowed:

```text
second death
posthumous manifest
chaos append to corpse
posthumous crystallization
posthumous tension measurement
```

This means death finality depended on caller discipline.

The runner usually stops after death, so normal live routes did not trigger it.

But packet physics must reject corpse mutation directly.

## Class

This is the same family as:

```text
written record without named reader
```

but in status form:

```text
status field written without status guard
```

## Rule

Dead packet does not mutate.

Second death is rejected.

Posthumous manifest is rejected.

Posthumous chaos/crystallize/tension mutation is rejected.

Trace may still contain the original death event.

The stored first death must not be overwritten.

## Test Shape

```text
create packet
die once
try die again -> reject
try manifest -> reject
try append_chaos -> reject
try crystallize -> reject
try measure_tension -> reject
assert original death/residue preserved
```
