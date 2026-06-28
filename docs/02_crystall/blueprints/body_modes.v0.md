# Body Modes Blueprint v0

Body modes are process permission modes.

They are not only UI modes.

## Allowed Modes

```text
chaos
table
crystall
manifest
```

Test status:

```text
unit_test: future packet mode validation
```

## Mode Law

```text
code writes only in manifest mode
```

No implementation file may be written from:

```text
chaos
table
crystall
```

Test status:

```text
not_testable_yet_with_reason: write permission layer not implemented yet
```

## Mode Permissions

```text
chaos
  may write docs/00_chaos
  may keep unsupported forms as raw pressure
  must not claim crystall authority
  must not write implementation code

table
  may write docs/01_table
  may map relations and candidate routes
  must mark unsupported forms as unknown
  must not write implementation code

crystall
  may write docs/02_crystall
  may define contracts and test obligations
  must require test status for stable claims
  must not write implementation code

manifest
  may write implementation code
  may write tests
  may update docs/03_manifest
  must follow a crystall contract
  must run relevant tests or record why not
```

## Packet Contract Extension

Future packet protocol should include:

```text
mode
```

Allowed values:

```text
chaos
table
crystall
manifest
```

Future trace event:

```text
mode_enter
```

Test status:

```text
not_testable_yet_with_reason: packet mode not implemented yet
```

## CLI Contract Extension

Future CLI should support:

```text
--mode chaos|table|crystall|manifest
```

Implementation-writing commands must require:

```text
--mode manifest
```

Test status:

```text
not_testable_yet_with_reason: CLI mode gate not implemented yet
```

## Crystallization Rule

Mode promotion follows:

```text
chaos -> table -> crystall -> manifest
```

Skipping directly from chaos to manifest is invalid unless the user explicitly
overrides the process and the trace records that override.

Test status:

```text
manual_check: future implementation must preserve layer discipline
```

