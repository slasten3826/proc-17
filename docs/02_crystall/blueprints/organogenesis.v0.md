# Organogenesis Blueprint v0

This is not first implementation scope yet.

It is a stable future contract for how the body may grow organs.

## Primary Rule

The body may create phantoms.

The body must not create independent immortal agents.

## Pressure Contract

Organ pressure must be trace-visible.

Required pressure fields:

```text
source
operator
substrate
human_task_shape
unsupported_form_key
runtime_evidence
```

Allowed pressure sources:

```text
human_task_shape
human_operator_style
processlang_operator
substrate_behavior
unsupported_form
runtime_constraint
repeated_residue
```

Test status:

```text
not_testable_yet_with_reason: organogenesis not implemented in first skeleton
```

## Phantom Organ Contract

A phantom organ must be:

```text
parent-linked
operator-bound
substrate-aware
budgeted
trace-visible
dead after return
```

It must leave residue.

Test status:

```text
not_testable_yet_with_reason: phantom execution not implemented yet
```

## Crystallization Contract

A phantom organ may become a real module only after:

```text
recurrence
architectural fit
useful result
bounded cost
testable contract
```

Promotion path:

```text
chaos -> table -> crystall -> tests -> module
```

No direct promotion from hallucination to code.

Test status:

```text
manual_check: future organ promotion must pass through docs and tests
```
