# Human TUI / Machine CLI Yellowprint v0

Status:

```text
table
yellowprint
planning contract
no implementation yet
```

## Pressure

proc-17 needs two external surfaces:

```text
machine-facing surface
human-facing surface
```

They should not be the same interface.

Machines need stable contracts.

Humans need body visibility.

## Split

```text
Lua body
  owns packet
  owns operators
  owns topology
  owns routing
  owns validation
  owns loss/budget/runtime state

Lua CLI
  machine interface
  stable commands
  json/jsonl output
  exit codes
  smoke/test surface

Go TUI
  human cockpit
  visual body state
  keyboard input
  panels
  trace view
  event view
```

## CLI Contract

CLI is for other machines and scripts.

Expected traits:

```text
boring
stable
parseable
testable
non-decorative
```

Possible command classes:

```text
run packet
validate trace
read packet memory
list packets
show snapshot
emit events
run smoke test
```

Output should prefer:

```text
json
jsonl
plain errors
exit codes
```

## TUI Contract

TUI is for the human operator.

Expected traits:

```text
informative
visual
keyboard-driven
body-first
chat-second
```

Core panels:

```text
header
trace
chat
current operator
body
pressure
events
input
free slot
```

The TUI should show what the body already knows.

It should not ask substrate to explain body state.

## Go Choice

Go is selected for TUI planning because:

```text
single binary
good terminal UI ecosystem
lower dependency pressure than Python Textual
less terminal-state risk than C
less ceremony than Rust for first cockpit
good json/jsonl handling
good concurrency for body events and input
```

Lua remains the body language.

Go is only the face.

## Hard Boundaries

Go TUI must not:

```text
route packets
validate ProcessLang topology
decide next operator
promote semantic proposals to runtime truth
rewrite packet state directly
hide body evidence behind prose
```

Go TUI may:

```text
display snapshots
display events
send user input
send explicit commands
switch focus/panels
request packet actions through CLI/protocol
```

## Bridge Pressure

Before TUI code, proc-17 needs a clean bridge:

```text
body snapshot
event stream
command input
manifest output
error format
```

Probable bridge:

```text
Lua body -> JSONL events -> Go TUI
Go TUI -> JSON/CLI command -> Lua body
```

The bridge is more important than the visual layout.

If the bridge is clean, the TUI can be replaced later.

If the bridge is dirty, the TUI becomes another body.

## Acceptance Shape

First useful TUI should be able to show:

```text
current packet id
mode
memory state
current trace
current operator
loss
budget
body counts
latest events
chat/output text
multiline input
```

It does not need:

```text
perfect colors
full mouse support
plugin panels
final layout
beautiful animations
```

## Next Step

Do not write Go TUI first.

First define the body snapshot and event protocol that TUI will consume.
