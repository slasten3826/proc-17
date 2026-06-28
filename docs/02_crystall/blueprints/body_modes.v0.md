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
unit_test: packet mode validation
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
unit_test: mode write path policy
unit_test: fake write tool denies implementation write outside manifest
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

## Write Path Policy

Current implementation:

```text
core/modes.lua
  can_write_path(mode, path)

tools/fake.lua
  write_file checks mode/path but does not write to disk
```

Allowed dry-run write paths:

```text
chaos    -> docs/00_chaos/
table    -> docs/01_table/
crystall -> docs/02_crystall/
manifest -> any implementation/test/manifest path
```

Real file writes are not implemented yet.
The current layer validates permission behavior before host mutation exists.

## Packet Contract

Packet protocol includes:

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

Trace event:

```text
mode_enter
```

Test status:

```text
unit_test: packet mode validation
unit_test: mode_enter trace event
```

## CLI Contract

CLI supports:

```text
--mode chaos|table|crystall|manifest
```

Implementation-writing commands must require:

```text
--mode manifest
```

Test status:

```text
integration_test: CLI accepts valid mode
integration_test: CLI rejects invalid mode
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
