# TUI Body Interface First Draft Notes

Status:

```text
chaos
first draft
do not treat as design contract
```

## Trigger

proc-17 now has enough body that using temporary Lua scripts through Codex is
becoming the wrong interface.

The user should be able to write to proc-17 directly.

But a normal coding-agent chat UI is probably the wrong shape.

proc-17 is not just:

```text
user message -> LLM response
```

proc-17 has:

```text
packet
operator trace
body state
channels
memory
loss
budget
validation
residue
death
```

So the interface should show the body, not only the chat.

## First Law

```text
TUI is not chat.
TUI is body visibility.
Chat is one panel.
```

Most information should come from proc-17 body/runtime, not from the LLM.

The LLM response is only one stream.

The body state is the main screen.

## Rough Screen Idea

Very rough shape:

```text
┌ proc-17 ─────────────────────────────────────────────┐
│ mode: build   layer: ⊞   packet: abc123   memory: on │
├ TRACE ───────────────────────────────────────────────┤
│ ▽ → ☴ → ☵ → ☳ → ☱ → ☶ → ☲ → △                       │
│ current: ☵ ENCODE                                    │
├ CHANNELS ────────────────────────────────────────────┤
│ trace_channel: 2 candidates, 1 valid, 1 invalid       │
│ semantic_channel: substrate response pending          │
│ runtime_channel: loss=0.25, budget=6, residue=1       │
├ BODY ────────────────────────────────────────────────┤
│ chaos: 3 fragments     calm: 5 work_units             │
│ choices: 1            validations: 2                 │
│ cycles: 0             memory: 4 inherited             │
├ LOG ─────────────────────────────────────────────────┤
│ ☴ observed substrate semantic proposal                │
│ ☵ encoded 5 items, loss moderate                      │
│ ☶ validated TRACE t1 valid                            │
├ INPUT ────────────────────────────────────────────────┤
│ > чего в супе не хватает?                             │
└───────────────────────────────────────────────────────┘
```

This is not a final layout.

It is only a pressure sketch.

## Concrete Sketch From User

This later sketch is still not a contract, but it is closer to the desired
shape:

```text
┌ proc-17 ─────────────────────────────────────────────────────────────────────────────┐
│ packet-17   RUNNING   mode: build   layer: ⊞   memory: on   tick: 08/12              │
├ TRACE ────────────────────────────────────────────────────────────────────────────────┤
│ ▽ ─ ☴ ─ ☵ ─ ☴ ─ ☳ ─ ☴ ─ ☱ ─ ☲ ─ [☱]                                                │
├──────────────────────────────────────────────────────────┬────────────────────────────┤
│                                                          │                            │
│                         CHAT                             │       CURRENT OPERATOR       │
│                                                          │                            │
│  USER                                                    │             ☱              │
│  Посмотри репозиторий и подумай, как лучше                │          RUNTIME           │
│  построить интерфейс.                                    │                            │
│                                                          │  came from: ☲ CYCLE        │
│  PROC-17                                                 │  reason: mandatory eye     │
│  Сейчас в теле существует несколько независимых          │  next: ☶ LOGIC             │
│  областей состояния. Их можно вывести в интерфейс        │  pressure: no evidence     │
│  без обращения к substrate...                            │                            │
│                                                          ├────────────────────────────┤
│  PROC-17                                                 │ BODY                       │
│  Сначала я проверю текущее состояние packet core...      │ chaos       3 fragments    │
│                                                          │ calm        5 work units   │
│                                                          │ choices     1              │
│                                                          │ validations 0              │
│                                                          │ cycles      1              │
│                                                          │ residue     0              │
│                                                          ├────────────────────────────┤
│                                                          │ PRESSURE                   │
│                                                          │ budget      56 / 64        │
│                                                          │ loss        25% moderate   │
│                                                          │ foundation  fluid          │
│                                                          │ evidence    0              │
│                                                          ├────────────────────────────┤
│                                                          │                            │
│                                                          │       FREE SLOT            │
│                                                          │                            │
│                                                          │   future organ / map /     │
│                                                          │   memory / tools / files   │
│                                                          │                            │
├──────────────────────────────────────────────────────────┼────────────────────────────┤
│ INPUT                                                    │ EVENTS                     │
│ > Тут многострочный ввод.                                │ 06 ☵ encoded 5 units       │
│   Можно видеть несколько строк перед отправкой.          │ 07 ☳ selected line:1       │
│                                                          │ 08 ☱ requested evidence    │
├──────────────────────────────────────────────────────────┴────────────────────────────┤
│ Tab focus   PgUp/PgDn chat   Enter send   F1 body   F2 trace   F3 slot   Ctrl+C detach │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

Useful pressure from the sketch:

```text
chat is large but not sovereign
trace is always visible
current operator is always visible
body state is visible without asking substrate
pressure is visible without asking substrate
events are separated from chat
input is multiline
there is room for future organ/map/memory/tool panels
```

This is a cockpit, not a messenger.

## Possible Panels

```text
header
operator trace
current operator
channels
packet body
runtime pressure
memory/residue
event log
chat/input
manifest output
```

`chat/input` should not dominate the UI.

The UI should make it obvious what proc-17 is doing without asking the LLM to
explain itself.

## RPG Interface Thought

Maybe the right metaphor is not a coding-agent chat.

Maybe it is closer to:

```text
first-person textual RPG interface
```

Not because proc-17 is a game.

Because a first-person RPG UI naturally separates:

```text
world state
current location
inventory
stats
log
actions
dialogue
```

proc-17 has similar shape:

```text
world/state      -> runtime/body pressure
location         -> current operator
inventory        -> memory/residue/work_units
stats            -> loss/budget/foundation
log              -> trace/events
actions          -> available routes
dialogue         -> user/substrate text
```

This might be a better frame than "chat with agent".

## Hard Design Constraints

This is real UI design, not just code.

Need to consider:

```text
terminal emulator
screen resolution
font size
glyph rendering
Unicode width
keyboard controls
scrolling
panel collapse
small screens
large screens
color/no-color modes
logs that grow forever
```

The glyphs must render correctly:

```text
▽ ☰ ☷ ☵ ☳ ☴ ☲ ☶ ☱ △
⋯ ⊞ ◈ ▲
```

If the terminal renders them badly, the interface breaks.

## Language Question

Lua is preferred for body coherence:

```text
proc-17 body is Lua
same runtime
same mental model
no split brain
```

But TUI in Lua may create friction:

```text
weaker libraries
layout pain
input handling pain
Unicode width pain
terminal quirks
```

Python with Textual might be easier for the face:

```text
better TUI layout
panels
hotkeys
scrolling
colors
faster iteration
```

But it creates a split:

```text
Lua body
Python face
JSON bridge
```

This may be acceptable if the boundary is clean.

Python/Textual was considered, but rejected as first choice for now:

```text
too many dependencies
rich/textual stack may become heavier than the body
packaging pressure
face becomes larger than body
```

Go is now the preferred TUI language:

```text
single compiled binary
good terminal UI ecosystem
simple enough for machines and humans
no Python runtime/dependency pile
safer and faster to build than C for terminal state
less ceremony than Rust for first cockpit
```

The current leaning:

```text
Lua = body
Lua CLI = machine interface
Go TUI = human cockpit
```

## Possible Architecture

Option A:

```text
Lua body + Lua TUI
```

Pros:

```text
one language
less bridge
body and face closer
```

Risks:

```text
TUI complexity
terminal pain
more custom code
```

Option B:

```text
Lua body + Python Textual face
```

Pros:

```text
better UI tools
faster body visibility
clean snapshot protocol
```

Risks:

```text
two runtimes
JSON bridge becomes contract
possible drift between face and body
```

Status:

```text
rejected as first TUI direction
```

Option C:

```text
no TUI yet, only CLI
```

Rejected for now as main direction.

Reason:

```text
CLI gives mouth, not body visibility
```

It may still be useful as a fallback or test runner.

Option D:

```text
Lua body + Go TUI cockpit
```

Pros:

```text
single binary face
good TUI libraries
clean body/face split
stable JSON/JSONL bridge
human interface can be beautiful without bloating Lua body
```

Risks:

```text
second language
bridge becomes real protocol
TUI may drift if it starts interpreting instead of displaying
```

Rule:

```text
Go TUI must not route.
Go TUI must not validate.
Go TUI must not decide.
Go TUI only displays body state and sends user input/commands.
```

## CLI vs TUI Boundary

The interface split is now clearer:

```text
CLI = machine interface
TUI = human cockpit
```

CLI should remain boring and stable:

```text
json/jsonl output
exit codes
trace validation commands
packet/memory commands
test/smoke commands
no decorative rendering required
```

TUI should be informative and readable:

```text
body panels
trace panel
current operator panel
pressure panel
events panel
chat/input panel
future organ/map/tool slots
```

The machine should not parse the TUI.

The human should not need to parse raw JSON.

This preserves both surfaces:

```text
machines get contracts
humans get visibility
body remains sovereign
```

## Snapshot Pressure

Whatever the UI language, proc-17 probably needs a body snapshot.

Possible future shape:

```text
runtime_snapshot.json
```

It should contain:

```text
packet_id
mode
layer
current_operator
operator_trace
channels
chaos_count
calm_work_units
choices_count
validations_count
cycles_count
memory_count
loss
budget
residue
last_events
manifest
```

The TUI should read body state.

It should not ask the LLM:

```text
what are you doing?
```

The body should tell the TUI directly.

## Open Questions

```text
Should TUI be terminal-first forever, or just first interface?
Should it be keyboard-only?
Should it show live ticking or only after each packet step?
Should chat input be always visible?
Should operator trace be horizontal, vertical, or graph-like?
Should channels be top-level panels?
Should memory be visible by default or hidden until needed?
Should manifest output replace chat response or be separate?
Should proc-17 feel like tool, cockpit, or RPG body?
Can Lua handle this without too much UI tech debt?
```

## Current Non-Decision

Do not code TUI yet.

Language direction is chosen enough for planning:

```text
Go for TUI
Lua remains body and CLI
```

Do not design final layout yet.

This document only preserves the first pressure:

```text
proc-17 needs a face that shows the body, not just a chat.
```

Next pressure:

```text
define the snapshot/event protocol before drawing the real Go cockpit
```
