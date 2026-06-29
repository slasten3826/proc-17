# Operator Runtime Hints Yellowprint v0

This yellowprint compiles raw pressure from:

```text
docs/00_chaos/operator_runtime_hints_notes.md
docs/00_chaos/encode_code_only_boundary.md
docs/00_chaos/cognitive_battery_codex_results.md
docs/00_chaos/cognitive_battery_user_results.md
```

It defines a narrow hint layer for proc-17 organs.

It does not make proc-17 a human-prose interpreter.

## Core Table

Operator hints are:

```text
small local pressure
operator-scoped
runtime-visible
optional module
not truth
not philosophy parser
```

They should help the body and substrate keep operator shape while doing code/runtime work.

## Non-Goal

The hint layer must not:

```text
parse arbitrary human prose
promote semantic text to runtime truth
replace runtime evidence
make ☵ a general language interpreter
make ☳ a semantic judge
hide trace behavior
```

## Module Shape

The hint layer should be a separate module:

```text
operator_runtime_hints
```

It should be possible to enable/disable it without changing the organs themselves.

Default intended behavior:

```text
enabled by default
explicitly disable by CLI/settings
```

Why default-on:

```text
like truck brakes
safe pressure is present unless deliberately released
```

Disable use cases:

```text
baseline substrate tests
comparison runs
debugging prompt influence
minimal trace mode
```

## Addressable Map

Hints should compile into an addressable map:

```text
operator -> role -> hints -> behavioral_pressure -> trace_expectation
```

Minimum fields:

```text
operator
role
hints
pseudocode
trace_pressure
```

Optional fields:

```text
mode
target
density
version
```

## Injection Points

Hints can be used in three different places.

### Substrate Prompt

Purpose:

```text
bias substrate before it responds
```

Rules:

```text
short only
operator-local only
no long prose
no decorative text
```

### Packet Trace

Purpose:

```text
make active pressure visible
```

Rules:

```text
emit hint_pressure event or payload
record enabled/disabled state
record operator and hint count
```

### Organ Config

Purpose:

```text
let deterministic modules inspect their own pressure
```

Rules:

```text
organ may read hints
organ must still prefer runtime evidence
organ must not upgrade truth from hints
```

## Control Surface

Settings-level control:

```text
hints.enabled = true | false
```

CLI-level control:

```text
--hints
--no-hints
```

Default:

```text
hints.enabled = true
```

CLI override should win over settings.

## Hint Density

First density:

```text
short
```

Allowed:

```text
1-4 hints per active operator
```

Rejected:

```text
long quotes
full slop fragments
multi-paragraph explanations
```

Future densities may exist:

```text
none
short
debug
```

But v0 should only require:

```text
enabled / disabled
```

## Operator Hint Table

### `▽ FLOW`

Role:

```text
task enters body as pressure before form
```

Hints:

```text
Flow is input pressure before form.
Do not solve before the packet is born.
Record the task as received before transforming it.
```

Trace expectation:

```text
raw task visible
mode explicit
first transformation traceable
```

### `☰ CONNECT`

Role:

```text
bind sources and relations without fusion
```

Hints:

```text
Connection is not fusion.
Bind source to field item.
Keep relation evidence visible.
```

Trace expectation:

```text
source identity preserved
relation evidence visible
relation type explicit when possible
```

### `☷ DISSOLVE`

Role:

```text
remove false solidity and preserve residue
```

Hints:

```text
Dissolve removes false form, not evidence.
Unsupported form should leave residue.
Weakening is not deletion.
```

Trace expectation:

```text
unsupported material leaves reasoned residue
false runtime claims are weakened
runtime evidence is not destroyed
```

### `☵ ENCODE`

Role:

```text
form addressable field from inspectable/runtime-shaped material
```

Hints:

```text
Encoding is not copying.
Structure has cost.
Show what was omitted, compressed, or made addressable.
Do not promote prose into runtime truth.
```

Trace expectation:

```text
field shape explicit
loss visible
source truth status preserved
prose remains semantic unless engineering pressure is explicit
```

### `☳ CHOOSE`

Role:

```text
irreversible collapse of alternatives
```

Hints:

```text
Choice kills alternatives.
A choice without killed alternatives is only confirmation.
Record what was not chosen.
Do not invent criteria after collapse.
```

Trace expectation:

```text
selected visible
killed visible or counted
collapse level explicit
criteria visible before or during collapse
```

### `☴ OBSERVE`

Role:

```text
read evidence without mutation
```

Hints:

```text
Observe reads without mutating.
Observation is not confirmation.
Raw evidence should enter before interpretation.
```

Trace expectation:

```text
target explicit
raw evidence preserved
observed status not promoted to validated truth
```

### `☲ CYCLE`

Role:

```text
bounded continuation decision
```

Hints:

```text
Continuation must be paid.
Cycle is not immortality.
Stop when pressure is exhausted or repetition becomes false life.
```

Trace expectation:

```text
continuation reason visible
repetition detectable
budget pressure considered
stop accepted as valid output
```

### `☶ LOGIC`

Role:

```text
cheap rule boundary
```

Hints:

```text
Rule does not create truth.
Rule rejects unsupported form.
Semantic proposal remains semantic until runtime confirms it.
```

Trace expectation:

```text
rejection reason explicit
runtime truth not invented by wording
rules remain inspectable
```

### `☱ RUNTIME`

Role:

```text
read body state, budgets, pressure, residue, manifest readiness
```

Hints:

```text
Runtime reads the body, not the idea.
Pressure is current state, not interpretation.
Memory is re-decoding available trace.
```

Trace expectation:

```text
budget visible
last events visible
residue visible
readiness based on body state
```

### `△ MANIFEST`

Role:

```text
output boundary and form death
```

Hints:

```text
Manifest is form death.
Output must not hide residue.
Completion kills the packet.
```

Trace expectation:

```text
external output separate from internal trace
death cause explicit
residue remains after completion
```

## Runtime Truth Boundary

Hints must never change:

```text
source_truth_status
content_truth_status
runtime evidence
validation result
```

Hints may change:

```text
prompt pressure
trace visibility
operator self-description
selection criteria visibility
loss reporting discipline
```

## Test Pressure

Future manifestation should be testable without real provider calls:

```text
hints_default_enabled
hints_cli_disable
hints_cli_enable
hints_emit_trace_pressure
hints_included_in_fake_substrate_call_when_enabled
hints_absent_from_fake_substrate_call_when_disabled
hints_do_not_promote_truth
```

## Current Table Conclusion

Operator hints are useful only if they remain small, local, switchable, and trace-visible.

They are not a new interpretation layer.

They are a brake/pressure module for keeping organs in their operator form.
