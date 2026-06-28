# Crystallization Cycle Blueprint v0

This is the current working contract for growing `procesis-body`.

## Build Rule

Implementation must not be built directly from chaos.

Required path:

```text
chaos -> table -> crystall -> implementation -> manifest
```

Chaos may inspire.
Crystall constrains.
Manifest records.

## Cycle Contract

Each build pass must do:

```text
1. read current chaos
2. update table maps if new stable shapes appeared
3. update crystall contracts if table has testable contracts
4. implement only crystallized scope
5. run available tests
6. update manifest with what exists
7. write new chaos for failures, gaps, and new pressure
```

## Glyph Pipeline Contract

The working shorthand is:

```text
⋯☴⊞☴◈☴
```

Meaning:

```text
⋯
  preserve raw chaos pressure

☴
  observe/read chaos without pretending it is stable

⊞
  table/yellowprint: arrange stable shapes, routes, inventories

☴
  observe/read table and identify testable contracts

◈
  crystall/blueprint: write stable contract and test obligations

☴
  observe manifest/test result and feed new pressure back to chaos
```

This is a documentation/build route first.

It is not yet an automated proc-17 pipeline.

Future implementation may expose it as a body-owned command after CYCLE can
make bounded continuation decisions.

## Test Contract

Every new crystall contract must include one test status:

```text
unit_test
integration_test
manual_check
not_testable_yet_with_reason
```

Untested behavior may exist in chaos or table.
It must not be treated as stable body law.

## First Implementation Scope

The first executable pass should be Lua and should include only:

```text
packet data model
topology/router
runtime budget/death model
unsupported form protocol
fake substrate adapter
fake tool facade
single-task CLI loop
trace/residue writer
tests
```

Real LLM providers come after fake substrate tests pass.

## Current Test Obligations

```text
packet_birth_unit
packet_budget_spend_unit
packet_death_unit
topology_valid_route_unit
topology_invalid_route_unit
unsupported_form_capture_unit
unsupported_form_dissolve_unit
unsupported_form_promote_unit
fake_substrate_loop_integration
```
