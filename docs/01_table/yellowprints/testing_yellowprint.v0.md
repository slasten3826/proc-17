# Testing Yellowprint v0

Tests are mandatory for `procesis-body`.

The body is about runtime truth, so untested contracts should not be treated as
real.

## First Test Surfaces

```text
packet lifecycle
  birth
  trace append
  budget spend
  death
  residue write

topology/router
  valid operator route
  invalid operator route
  two-center split

unsupported form protocol
  nonexistent method is not manifested as fact
  unsupported form is encoded as gap residue
  repeated unsupported form can be promoted
  unsupported form without recurrence decays

substrate adapter
  provider response normalized
  provider error normalized
  raw provider payload preserved

tool facade
  command result captured
  file read/write result captured
  failure does not become semantic truth
```

## Test Levels

```text
unit
  pure Lua modules: packet, topology, unsupported_form

integration
  local CLI loop with fake substrate and fake tools

manual
  real model / real repo / real command behavior
```

## Fake Substrate

The first tests should not require an LLM.

Use fake substrate outputs:

```text
valid observation
invalid factual claim
invented method
provider error
empty response
repeated same unsupported form
```

This keeps the body testable before provider work is complete.

## Test Rule

Every crystall blueprint must declare one of:

```text
unit_test
integration_test
manual_check
not_testable_yet_with_reason
```

No silent untestable law.

