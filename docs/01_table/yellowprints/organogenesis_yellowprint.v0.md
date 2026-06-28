# Organogenesis Yellowprint v0

Organogenesis is the process by which `procesis-body` grows bounded organs from
packet pressure.

## Pressure Sources

```text
human_task_shape
human_operator_style
processlang_operator
substrate_behavior
unsupported_form
runtime_constraint
repeated_residue
```

## Organ Classes

```text
fixed organ
  existing module in organs/ or core/

phantom organ
  bounded temporary packet child

candidate organ
  repeated phantom shape with residue

crystallized organ
  tested module promoted into body
```

## Birth Signal

Candidate birth signals:

```text
same unsupported_form recurrence_key repeats
task requires route that does not exist
substrate repeatedly proposes same missing method
human operator style creates stable recurring need
tool/runtime confirms a repeated gap
```

## Phantom Organ Shape

```text
phantom_organ = {
  id,
  parent_packet_id,
  operator,
  substrate,
  birth_reason,
  task_slice,
  budget,
  trace,
  result,
  death,
  residue
}
```

## Crystallization Gate

A phantom organ can move toward crystall only when:

```text
recurs
has architectural fit
produces useful result
has bounded cost
can be tested
does not become independent agent
```

## First Implementation Direction

Do not implement full organogenesis yet.

First implement:

```text
record organ pressure in packet trace
record phantom_spawn / phantom_result event types
record substrate and operator in gap residue
```

