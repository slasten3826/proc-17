# Grave Classifier Yellowprint v0

Status:

```text
table
from Mythos/Fable Entry 003
step 1 only
amended 2026-07-21: QA rejection remains lineage generation evidence, not grave authority
```

## Goal

Classify a dead packet residue into a grave kind.

Do not attach graves at birth yet.

Do not change router yet.

## Core Split

Death fact:

```text
runtime_confirmed
```

Applicability to a future packet:

```text
grave_pressure / inherited proposal
```

So grave classification must preserve the fact of death while refusing to make
future applicability absolute.

## Grave Kinds

```text
warning
  death without useful progress
  tells descendants what not to repeat

bequest
  death with useful progress
  tells descendants where continuation may begin

neutral
  death/completion that should not pressure descendants yet
```

## First Classification Rules

Budget death:

```text
budget_exhausted + remaining_work_count > 0 + progress evidence -> bequest
budget_exhausted + do_not_repeat present + no progress evidence -> warning
budget_exhausted + remaining_work_count only -> warning by default in v0
```

Identity loss:

```text
identity_loss -> warning
```

Complete:

```text
complete -> neutral
```

Cancelled/host guard:

```text
cancelled -> neutral unless explicit do_not_repeat exists
```

## QA Rejection Boundary

`qa_rejected` is not a death cause and does not select a grave kind. It is an
exact generation fact consumed by the lineage recovery path. Grave
classification continues to read only death, progress and residue evidence.

Therefore:

```text
complete Packet carrying a rejected-generation terminal candidate -> neutral grave
independent identity_loss or budget death -> normal warning/bequest rules
QA metadata alone -> zero grave-kind delta
grave record -> no authority to approve or deny generation recovery
```

This prevents grave/karma memory from duplicating or overriding the exact
lineage rejected-generation terminal projection and recovery contracts.

## Progress Evidence

Progress evidence can be:

```text
residue.done_count > 0
residue.progress.done_count > 0
residue.completed_work_count > 0
residue.bequest == true
```

`remaining_work_count > 0` alone is not progress.

It only says work remains.

## Warning Payload

```lua
{
  kind = "grave",
  grave_kind = "warning",
  source_packet_id = string,
  death_cause = string,
  do_not_repeat = string,
  pattern = table,
  applicability_truth_status = "grave_pressure",
  death_truth_status = "runtime_confirmed",
}
```

## Bequest Payload

```lua
{
  kind = "grave",
  grave_kind = "bequest",
  source_packet_id = string,
  death_cause = string,
  remaining_work_count = number,
  progress = table,
  trace_tail = table,
  applicability_truth_status = "grave_pressure",
  death_truth_status = "runtime_confirmed",
}
```

## Pattern v0

Minimum pattern:

```lua
{
  last_operator = residue.last_operator,
  do_not_repeat = residue.do_not_repeat,
  death_cause = death.cause,
}
```

Later router can turn this into mechanical penalty.

## API

```lua
grave.classify(input) -> grave_record | nil, err
```

Input can be:

```lua
packet instance
packet memory capsule
inherited_packet_residue
raw {packet_id, death, residue, trace_tail}
```

V0 can normalize these shapes internally.

## Tests

```text
identity_loss -> warning
budget_exhausted with do_not_repeat and no progress -> warning
budget_exhausted with progress done_count > 0 -> bequest
complete -> neutral
same complete death with/without qa_rejected metadata -> same neutral grave
cancelled without do_not_repeat -> neutral
classification preserves runtime death truth and grave pressure applicability
```

## Non-Goals

```text
runner attach
router penalty
cemetery storage
compost
generation curve
LLM semantic retrieval
```
