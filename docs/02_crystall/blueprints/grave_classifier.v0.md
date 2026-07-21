# Grave Classifier Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/grave_classifier_yellowprint.v0.md
implementation target
amended 2026-07-21: QA rejection remains lineage generation evidence, not grave authority;
  F4 uses the lineage rejected-generation terminal projection and no separate failure crystal
```

## Scope

Implement:

```text
runtime/grave.lua
tests/test_grave.lua
```

Do not connect to tension runner or router yet.

## Module

```text
runtime/grave.lua
```

API:

```lua
grave.classify(input) -> grave_record | nil, err
```

## Input Normalization

Accept:

```text
packet instance
packet_memory capsule
inherited_packet_residue
raw grave-like table
```

Normalize to:

```lua
{
  packet_id = string | nil,
  death = table | nil,
  residue = table,
  trace_tail = table,
  status = string | nil,
}
```

## Classification

Rules:

```text
identity_loss -> warning
budget_exhausted + progress evidence -> bequest
budget_exhausted + do_not_repeat -> warning
budget_exhausted otherwise -> warning
complete -> neutral
cancelled + do_not_repeat -> warning
cancelled otherwise -> neutral
missing death -> nil, "grave classification requires death"
```

QA rejection law:

```text
qa_rejected is generation evidence owned by lineage
grave.classify does not read QA verdicts to choose warning/bequest/neutral
complete rejected-generation terminal candidate remains neutral unless independent residue/death rules apply
grave output cannot authorize or block recovery
```

Progress evidence:

```text
residue.bequest == true
residue.done_count > 0
residue.completed_work_count > 0
residue.progress.done_count > 0
```

## Output Shape

All non-error outputs:

```lua
{
  kind = "grave",
  grave_kind = "warning" | "bequest" | "neutral",
  source_packet_id = string | nil,
  source_status = string | nil,
  death_cause = string,
  death = table,
  residue = table,
  trace_tail = table,
  death_truth_status = "runtime_confirmed",
  applicability_truth_status = "grave_pressure",
}
```

Warning adds:

```lua
warning = {
  do_not_repeat = string | nil,
  pattern = {
    last_operator = residue.last_operator,
    do_not_repeat = residue.do_not_repeat,
    death_cause = death.cause,
  },
}
```

Bequest adds:

```lua
bequest = {
  remaining_work_count = residue.remaining_work_count,
  progress = residue.progress,
  trace_tail = trace_tail,
}
```

Neutral should not include warning/bequest payload.

## Tests

Add:

```text
tests/test_grave.lua
```

Cases:

```text
missing death returns error
identity_loss becomes warning
budget_exhausted with do_not_repeat and no progress becomes warning
budget_exhausted with done_count > 0 becomes bequest
budget_exhausted with progress.done_count > 0 becomes bequest
complete becomes neutral
same complete death with/without qa_rejected metadata remains neutral
cancelled without do_not_repeat becomes neutral
cancelled with do_not_repeat becomes warning
inherited_packet_residue input normalizes
packet instance input normalizes
truth statuses preserved
```

Register in:

```text
tests/run.lua
```

## Acceptance

```text
lua tests/run.lua
```

must pass.
