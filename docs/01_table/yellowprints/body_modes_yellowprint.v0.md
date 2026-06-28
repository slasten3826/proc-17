# Body Modes Yellowprint v0

Body modes map the four procesis layers into process permissions.

This is more than conversation style.
It is how the body prevents premature manifestation.

## Mode Set

```text
chaos
table
crystall
manifest
```

## Mode Map

```text
chaos
  layer: 00_chaos
  purpose: raw thought, exploration, origin pressure
  writes: docs/00_chaos
  code: denied
  hallucination tolerance: high

table
  layer: 01_table
  purpose: maps, relations, inventories, candidate routes
  writes: docs/01_table
  code: denied
  hallucination handling: tag unsupported / unknown

crystall
  layer: 02_crystall
  purpose: contracts, blueprints, specs, test obligations
  writes: docs/02_crystall
  code: denied
  hallucination handling: strict validation

manifest
  layer: 03_manifest + implementation
  purpose: code, tests, commands, artifacts, verified output
  writes: code, tests, docs/03_manifest
  code: allowed
  requirement: must follow crystall contract
```

## Main Law

```text
code writes only in manifest mode
```

## Packet Impact

Candidate packet field:

```text
mode = chaos | table | crystall | manifest
```

Candidate trace event:

```text
mode_enter
```

Mode should affect:

```text
allowed write paths
allowed event types
truth strictness
substrate prompt shape
whether tool calls may mutate runtime
whether code writes are allowed
```

## CLI Impact

Possible future flag:

```text
--mode chaos|table|crystall|manifest
```

Default is not decided.

Likely early defaults:

```text
docs-only commands default to chaos/table/crystall by target layer
code-writing commands require explicit manifest
```

## Permission Shape

Draft:

```text
chaos:
  allow docs/00_chaos
  deny implementation writes

table:
  allow docs/01_table
  deny implementation writes

crystall:
  allow docs/02_crystall
  allow test obligation declarations
  deny implementation writes

manifest:
  allow implementation writes
  allow tests
  allow docs/03_manifest
  require linked crystall blueprint
```

## Why It Belongs In Table

This idea creates a testable distinction:

```text
same packet + different mode -> different permissions
```

So it should not remain only chaos.

