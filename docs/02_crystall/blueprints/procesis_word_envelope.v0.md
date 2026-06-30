# Procesis Word Envelope Blueprint v0

Status: implemented

Source:

```text
docs/01_table/yellowprints/procesis_word_envelope_yellowprint.v0.md
```

## Modules

```text
runtime/system_prompt.lua
runtime/operator_hints.lua
cli/procesis-body.lua
substrates/openai_compatible.lua
tests/test_cli.lua
tests/test_operator_hints.lua
```

## System Prompt

`runtime/system_prompt.lua` owns the proc-17 substrate envelope.

Required lines:

```text
You are substrate current inside proc-17.
proc-17 is a ProcessLang body; the body owns runtime truth, trace, permissions, and final manifestation.
You return semantic proposal only.
Do not use external meanings of 'plan mode' or 'build mode'.
If procesis word is provided, treat it as canonical orientation, not observed runtime evidence.
```

Work mode branch:

```text
plan:
  prepare structure
  no implementation manifestation

build:
  manifest from available structure
  produce usable form or clear residue
```

Unknown work mode:

```text
preserve uncertainty
do not invent mode semantics
```

## Substrate Call Contract

`cli/procesis-body.lua` must attach:

```lua
system_prompt = system_prompt.format({work_mode = work_mode})
```

to:

```text
substrate_call payload
deepseek.ask call
```

`substrates/openai_compatible.lua` must use:

```lua
call.system_prompt
```

as the `system` role content when present.

Fallback system prompt remains available for older callers.

## Procesis Word Contract

`runtime/operator_hints.lua` may keep internal names in v0.

Substrate-facing formatted text must start with:

```text
[procesis word]
Canonical operator orientation for proc-17 substrate work.
This is not observed runtime evidence and must not be promoted into runtime truth.
```

Then list active operators:

```text
<glyph> <role>:
- <operator word line>
```

## Truth Boundary

The substrate may use procesis word to shape semantic proposal.

The substrate must not treat procesis word as:

```text
runtime-confirmed observation
tool result
file evidence
permission grant
manifested output
```

## Tests

Required test pressure:

```text
system prompt appears in substrate_call payload
system prompt places substrate inside proc-17
system prompt binds plan/build meanings
formatted operator block uses [procesis word]
formatted operator block preserves not-runtime-evidence boundary
disabled word does not enter prompt payload
enabled word still includes operator pressure lines
```

## Deferred Blueprint

This blueprint does not implement autonomous organ routing.

Organ routing needs a separate blueprint.

Required boundary for that future blueprint:

```text
body chooses next organ
substrate does not own routing authority
fixed route remains testing scaffold until router exists
```

