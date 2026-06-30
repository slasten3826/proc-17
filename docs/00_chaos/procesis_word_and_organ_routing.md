# Procesis Word And Organ Routing

Date: 2026-06-30

This note records a correction after the first plan/build probe battery.

The old substrate prompt shape was too weak:

```text
user question

[operator runtime hints]
...
```

This makes the operator block look like optional assistant hints.
That is the wrong pressure.

For proc-17, this block is closer to `word`:

```text
procesis word
canonical operator orientation
```

It is not runtime truth.
It is not observed evidence.
It is not a user instruction to roleplay all operators.

But it is also not a casual hint.
It is the canonical orientation that keeps the substrate current aligned with the body.

## System Envelope

The substrate should receive a real system envelope before the user task.

The system envelope should say:

```text
You are substrate current inside proc-17.
proc-17 owns runtime truth, trace, permissions, and manifestation.
You return semantic proposal only.
work_mode has proc-17 meanings, not external meanings.
plan = structure pressure, no implementation manifestation.
build = manifestation from available structure or clear residue.
The user task is input pressure.
Preserve contradictions, missing evidence, and unsupported forms as residue.
If procesis word is provided, treat it as canonical orientation, not observed runtime evidence.
```

The point is not to make the substrate obey more words.
The point is to put the substrate in the right body before it starts decoding the task.

## Why This Matters

The probe battery showed that without a strong envelope, the substrate may decode phrases such as:

```text
build mode
plan mode
runtime truth
blueprint
```

through generic internet meanings.

That creates drift.

proc-17 needs those words decoded through proc-17 first.

## Word Is Not Runtime Truth

`procesis word` must not be promoted to runtime-confirmed evidence.

Bad:

```text
The operator word says X, therefore X happened.
```

Good:

```text
The operator word orients the substrate toward X.
The body still needs observation, encoding, choice, logic, runtime, or manifest events to confirm what happened.
```

This keeps the difference between canon and trace.

Canon orients.
Trace confirms.

## Fixed Route Problem

Current v0 route forces the substrate result through most organs:

```text
▽ -> ☰ -> ☴ -> ☱ -> ☵ -> ☳ -> ☶ -> ☱ -> ☲ -> ☱ -> △
```

This is useful for early testing.
It proves organs work.
It creates comparable traces.
It makes failures visible.

But it is not the final body behavior.

The final body should not always run every organ.
The body should choose which organ to call from pressure.

Examples:

```text
missing runtime evidence -> ☴ / ☱
too much prose -> ☵
real alternatives -> ☳
unsupported form -> ☶ / ☷
repetition pressure -> ☲
ready output -> △
new raw uncertainty -> back to ⋯
```

## Organ Router Pressure

Future proc-17 needs an organ router.

The router is not an LLM agent.
It is body logic.

It reads:

```text
task pressure
current work_mode
last trace events
runtime snapshot
field shape
logic result
cycle result
budget
residue
```

Then it selects the next organ or stops.

This means DeepSeek should not decide which organs exist.
DeepSeek may propose semantic pressure.
The body chooses organs.

## Important Boundary

Autonomous organ choice should not be implemented by asking the substrate:

```text
Which organ should I call next?
```

That would move body authority back into the substrate.

The substrate can suggest.
The body routes.

## Current Implementation Direction

Immediate correction:

```text
add proc-17 system envelope
rename substrate-facing operator block from runtime hints to procesis word
keep trace-visible hint_pressure for compatibility
```

Deferred correction:

```text
replace fixed organ route with body-owned organ router
```

The fixed route remains acceptable while building and testing organs.
It becomes wrong only when treated as final architecture.

