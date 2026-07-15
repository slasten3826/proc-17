# Build Evidence Loop Coding Battery Notes

Status:

```text
chaos
author: claude (Mythos/Fable)
from live DeepSeek coding battery, 2026-07-15
first end-to-end worker measurement of the body
```

## The Experiment

Five coding tasks through the live body (deepseek-chat substrate,
build mode, max_ticks 14, budget steps=32 / substrate_calls=4):

```text
py_add_assert     trivial function + asserts
py_fizzbuzz       function returning list, asserts with traps
py_error_count    log parsing with a poisoned line
                  ('WARNING: ERROR later' must not count)
py_fix_bug        off-by-one repair (range(n) -> range(1, n+1))
lua_stack_module  small Lua module + asserts
```

Verdict is stamped by execution, not opinion: extracted code must
run and pass its own asserts via the body's spell engine.

## The Two Numbers

```text
substrate capability:  5/5  every proposal ran, exit 0,
                            all asserts passed, both traps handled
body delivery:         0/5  not a single manifest produced
```

The gap is 100% plumbing, 0% DeepSeek.

## The Loop

Every trace identical:

```text
☴☵☴☳☴☱ ☶☱☶☱☶☱☶☱   -> tick_limit
route tail: missing_build_evidence / mandatory_eye_tick, repeating
```

Mechanism:

```text
build mode: ☱ routes to ☶ (missing_build_evidence)
☶ finds no spells: they are configured by the host BEFORE birth
  (options.logic.spells); the body has no way to mint a spell
  from its own work mid-life
no_spell != rejected, so validation_rejected_semantic_repair
  never fires
☶ -> ☱ -> ☶ until the host kills the run
```

The substrate answered three times per run. Its proposals sat in
observe payloads, unused. The body starved holding perfectly good
food: rigor without hands.

## Reincarnation Notice

This is Entry 001's death pattern reborn: then ☱↔☲ remaining_work,
now ☱↔☶ missing_build_evidence. The karma warning fix (b3b50fa)
covers ☲/☱ loop graves; it does not cover ☱☶ loops, and these
packets had no ancestors anyway.

With a larger max_ticks this loop dies honestly by budget
(steps are charged every tick) — but it dies having done the work
and delivered nothing.

## Plumbing Debt, Named

```text
1. no hands   the body cannot write its manifest to disk
              (harness did it via fs; tools/fs.lua exists unused)
2. no minting the evidence channel is static and one-way;
              the body cannot cast a NEW spell born from the work
              it is currently doing
3. no repair  no_spell does not trigger semantic repair;
              the loop carries no new information per revolution
4. no memory  the loop detector / karma warnings do not
              generalize to ☱☶
```

## Candidate Directions (not decided; machinist chooses)

```text
A. body-side spell minting: ☳ selects a work unit ->
   fs tool writes proposal to sandbox -> body casts
   execution spell on it -> evidence born mid-life
   (this is the full worker loop: task -> code -> test -> manifest)
B. no_spell counts as rejected after N attempts ->
   semantic repair re-engages the substrate instead of looping
C. generalize loop karma: repeated ☱☶ with no new evidence
   -> manifest pressure (die with residue, not tick_limit)
```

## Meaning For The Machinist

«DeepSeek кодит плохо» is unmeasured in pi/opencode terms here,
but inside proc-17 at simple-task level the substrate was fine
and the body was the bottleneck. The religion worked — the body
refused to bless unverified work. It just has no hands to verify,
so it starved at a full table.
