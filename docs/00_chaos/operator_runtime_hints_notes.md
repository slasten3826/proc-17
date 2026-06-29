# Operator Runtime Hints Notes

Status: candidate pressure for table/crystall pass.

This document replaces the broader idea of feeding human-text interpretation snippets into proc-17.

The narrowed idea:

proc-17 should not learn to interpret arbitrary human prose.

But each organ may receive small local operator hints that keep it in shape during work.

These hints are not scripture quotes for understanding.

They are runtime pressure.

## Purpose

Operator hints should help the substrate and body remember what each organ is doing.

They should bias behavior toward proc-17/processlang invariants without turning the body into a philosophy parser.

Good hint:

```text
☳ CHOOSE:
Choice kills alternatives.
Record what was not chosen.
```

Bad hint:

```text
☳ CHOOSE:
A long poetic explanation of will, fate, destiny, and human decision.
```

## Rules

1. Hints must be short.
2. Hints must be local to one operator.
3. Hints must affect code, trace, validation, selection, or output behavior.
4. Hints are pressure, not truth.
5. Hints must not promote semantic prose to runtime truth.
6. Hints may be plain text, pseudocode, or glyph-form.
7. If a hint cannot change a trace, it is probably decorative.
8. Human-language beauty is not a goal.
9. Runtime usefulness is the goal.
10. The body may ignore hints when runtime evidence contradicts them.

## Candidate Hints By Operator

### `▽ FLOW`

Role:

Start pressure. Task enters the body.

Candidate hints:

```text
Flow is input pressure before form.
Do not solve before the packet is born.
Record the task as received before transforming it.
```

Pseudocode:

```text
on_birth(task):
  preserve_original_task
  mark_pressure_source = user_input
  do_not_choose_yet
```

Trace pressure:

- raw task must be visible
- mode must be explicit
- first transformation must be traceable

### `☰ CONNECT`

Role:

Bind sources, context, and relations without claiming they are identical.

Candidate hints:

```text
Connection is not fusion.
Bind source to field item.
Keep relation evidence visible.
```

Pseudocode:

```text
connect(a, b):
  relation = observed_or_declared_link(a, b)
  preserve_source_identity(a, b)
  emit_relation_evidence
```

Trace pressure:

- every field item should know where it came from
- relation type should be explicit when possible
- source identity should not disappear into summary

### `☷ DISSOLVE`

Role:

Remove false solidity. Weaken unsupported status. Preserve residue.

Candidate hints:

```text
Dissolve removes false form, not evidence.
Unsupported form should leave residue.
Weakening is not deletion.
```

Pseudocode:

```text
dissolve(form):
  if unsupported(form):
    lower_status(form)
    record_residue(form, reason)
  do_not_destroy_runtime_evidence
```

Trace pressure:

- rejected/unsupported material should leave reasoned residue
- false runtime claims should be weakened
- evidence should not be erased with the unsupported claim

### `☵ ENCODE`

Role:

Create addressable field from inspectable/runtime-shaped material.

Candidate hints:

```text
Encoding is not copying.
Structure has cost.
Show what was omitted, compressed, or made addressable.
Do not promote prose into runtime truth.
```

Pseudocode:

```text
encode(input):
  if inspectable_or_executable(input):
    field = make_addressable(input)
    record_loss(input, field)
  else:
    keep_as_semantic_raw_text(input)
```

Trace pressure:

- field shape must be explicit
- loss must be visible
- source truth status must survive encoding
- prose stays semantic unless it contains explicit engineering pressure

### `☳ CHOOSE`

Role:

Irreversible collapse of alternatives.

Candidate hints:

```text
Choice kills alternatives.
A choice without killed alternatives is only confirmation.
Record what was not chosen.
Do not invent criteria after collapse.
```

Pseudocode:

```text
choose(field, criteria):
  selected = collapse(field, criteria)
  killed = field - selected
  record_loss(killed)
  do_not_rewrite_reason_after_selection
```

Trace pressure:

- selected items must be visible
- killed alternatives must be visible or counted
- collapse level must be explicit
- criteria must exist before or during collapse, not after

### `☴ OBSERVE`

Role:

Look upward/outward into chaos, repo, prompt, and available evidence.

Candidate hints:

```text
Observe reads without mutating.
Observation is not confirmation.
Raw evidence should enter before interpretation.
```

Pseudocode:

```text
observe(target):
  read(target)
  emit_evidence(status = observed)
  do_not_change_target
  do_not_claim meaning yet
```

Trace pressure:

- observation target must be explicit
- raw evidence should be preserved
- observed does not mean true, selected, or valid

### `☲ CYCLE`

Role:

Bounded continuation. Decide whether another pass is payable.

Candidate hints:

```text
Continuation must be paid.
Cycle is not immortality.
Stop when pressure is exhausted or repetition becomes false life.
```

Pseudocode:

```text
cycle(state):
  if budget_exhausted or repeated_without_gain:
    stop_with_residue
  else:
    continue_with_reason
```

Trace pressure:

- continuation reason must be visible
- repetition should be detectable
- budget pressure must matter
- stop is valid output

### `☶ LOGIC`

Role:

Rule boundary and cheap validator.

Candidate hints:

```text
Rule does not create truth.
Rule rejects unsupported form.
Semantic proposal remains semantic until runtime confirms it.
```

Pseudocode:

```text
validate(item):
  if violates_rule(item):
    reject_or_weaken(item)
  if semantic_only(item):
    keep_semantic_status
  never_upgrade_without_runtime_evidence
```

Trace pressure:

- rejection reason must be explicit
- runtime truth cannot be invented by wording
- rules should stay simple and inspectable

### `☱ RUNTIME`

Role:

Lower eye. Read body state, budgets, pressure, residue, and manifest readiness.

Candidate hints:

```text
Runtime reads the body, not the idea.
Pressure is current state, not interpretation.
Memory is re-decoding available trace.
```

Pseudocode:

```text
runtime_snapshot(packet):
  read_budget
  read_trace
  read_residue
  read_manifest_pressure
  do_not_mutate_packet
```

Trace pressure:

- budget must be visible
- last events must be visible
- residue must be visible
- readiness must be based on body state

### `△ MANIFEST`

Role:

Output boundary. Form appears and packet dies or continues by explicit reason.

Candidate hints:

```text
Manifest is form death.
Output must not hide residue.
Completion kills the packet.
```

Pseudocode:

```text
manifest(packet):
  emit_output
  preserve_residue
  if complete:
    die(cause = complete)
```

Trace pressure:

- external output should be separate from internal trace
- death cause should be explicit
- residue should remain after completion

## Open Questions

Should hints be embedded in:

- substrate prompt only
- packet trace only
- organ config
- all of the above with different density

Should hints be always-on or mode-specific:

- chaos/table/crystall/manifest mode
- code vs reflection task
- repo-context vs no-context task

Should hints be human-readable strings, glyph compressed forms, or Lua data:

```lua
return {
  ["☵"] = {
    "Encoding is not copying.",
    "Structure has cost.",
    "Do not promote prose into runtime truth.",
  },
}
```

## Working Direction

For now, treat hints as a small always-available organ-local pressure layer.

They should be compiled from chaos into table as an addressable map:

```text
operator -> role -> hints -> behavioral pressure -> trace expectation
```

Then crystall can decide exact schema and runtime loading rules.
