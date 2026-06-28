# Sandbox Policy Blueprint v0

Sandbox policy is the central permission layer for host interaction.

## Primary Rule

```text
default deny
```

No host mutation should happen without explicit policy allow.

## Placement

```text
packet -> tool facade -> sandbox policy -> host
```

The substrate must not call host.

Tools must ask sandbox before host access.

## Resource Policy v0

```text
filesystem_read
  allow relative workspace paths
  deny absolute paths
  deny parent traversal

filesystem_write
  allow relative workspace paths
  deny absolute paths
  deny parent traversal
  require body mode path policy

shell_command
  deny

network
  deny as general tool
  substrate adapters are separate explicit network surface

git
  deny as general tool

delete
  deny
```

## Required Module

```text
core/sandbox.lua
```

Required functions:

```text
check_path(path) -> ok, reason
can_read_file(context, path) -> ok, reason
can_write_file(context, path) -> ok, reason
can_run_command(context, command) -> ok, reason
```

Context must include:

```text
mode
```

## Test Obligations

```text
unit_test: sandbox denies absolute path
unit_test: sandbox denies parent traversal
unit_test: sandbox allows relative read
unit_test: sandbox denies write outside mode policy
unit_test: sandbox allows write inside mode policy
unit_test: sandbox denies shell command
unit_test: fs tool uses sandbox for read/write decisions
```

