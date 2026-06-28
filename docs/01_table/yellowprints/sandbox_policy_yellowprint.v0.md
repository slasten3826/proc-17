# Sandbox Policy Yellowprint v0

Sandbox policy is the central permission layer for host interaction.

It sits between tool facade and host.

```text
packet -> tool facade -> sandbox policy -> host
```

## Default Stance

```text
default deny
explicit allow only
```

## Resource Classes

```text
filesystem_read
filesystem_write
shell_command
network
git
delete
```

## Current v0 Allow/Deny

```text
filesystem_read
  allow workspace-relative paths
  deny absolute paths
  deny parent traversal

filesystem_write
  allow workspace-relative paths
  deny absolute paths
  deny parent traversal
  require mode path policy

shell_command
  deny

network
  deny except substrate adapters

git
  deny as tool action

delete
  deny
```

## Decision Inputs

```text
mode
action
path
resource
operation
workspace_root
approval_state
```

## Decision Output

```text
allowed
reason
risk
```

## First Implementation Target

```text
core/sandbox.lua
```

Candidate functions:

```text
check_path(path) -> ok, reason
can_read_file(context, path) -> ok, reason
can_write_file(context, path) -> ok, reason
can_run_command(context, command) -> ok, reason
```

The fs tool should call sandbox policy instead of holding all path logic itself.

