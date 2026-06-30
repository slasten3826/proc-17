# Tic Tac Toe AI Speed Test Results

Date: 2026-06-30

This note records a live proc-17 plan/build/code/runtime test.

## Task

Build a Python CLI tic-tac-toe game against a computer player.

Requirements:

```text
3x3 board
human player = X
computer player = O
input positions 1-9
reject occupied cells
reject non-numeric input
reject out-of-range input
win detection across rows, columns, diagonals
draw detection
computer AI:
  first winning move
  then block human win
  then center
  then corner
  then any free cell
no replay needed
```

## Pipeline

The run used the proc-17 work-mode split:

```text
plan mode  -> blueprint
build mode -> Python code
△          -> manifest code/python
runtime    -> py_compile + scripted smoke + AI checks
```

Logs:

```text
logs/tictactoe_ai/2026-06-30/
```

## Time Observation

From user prompt to working checked code, the loop took less than two minutes.

This includes:

```text
DeepSeek plan call
DeepSeek build call
manifest classification
code extraction
Python compile check
interactive smoke scenarios
direct AI behavior checks
```

This matters more than raw generation speed.
The entire production loop was fast:

```text
prompt -> blueprint -> code -> manifest -> runtime evidence
```

## Manifest Result

The new `△` manifest assembler correctly detected the build output as code:

```json
{
  "type": "code",
  "language": "python"
}
```

This confirms that `△` is no longer only closing the packet.
It is starting to expose the correct outer form.

## Runtime Checks

Compilation:

```text
python3 -m py_compile /tmp/proc17_tictactoe.py
ok
```

Scripted game checks covered:

```text
normal human/computer turn flow
occupied cell rejection
non-numeric input rejection
out-of-range input rejection
computer win
computer block
computer center preference
computer corner preference
```

Direct AI checks:

```text
AI should win at 3 got=3 expected=3
AI should block at 3 got=3 expected=3
AI should take center got=5 expected=5
AI should take first free corner got=3 expected=3
ai behavior ok
```

## Meaning

This is stronger than the ATM emulator test.

The ATM task was mostly educational CRUD-like flow.
The tic-tac-toe task had:

```text
state
rules
turn alternation
input validation
game termination
simple AI strategy
runtime-checkable behavior
```

proc-17 handled it quickly because the body reduced uncertainty:

```text
plan mode narrowed structure
build mode manifested code
manifest marked the output as Python code
runtime checks confirmed behavior
```

## Current Interpretation

proc-17 is showing a latency-to-working-code advantage on small self-contained coding tasks.

The important result is not that the substrate can write tic-tac-toe.

The important result is:

```text
the body can push from task pressure to checked code in under two minutes
```

This is a real signal that plan/build/manifest is not just a conceptual split.
It is an acceleration path.

## Remaining Boundary

This test did not require repo modification.

Next stronger class:

```text
repo context -> choose target file -> write file -> run tests
```

That will test agency more directly than single-file stdout code generation.

