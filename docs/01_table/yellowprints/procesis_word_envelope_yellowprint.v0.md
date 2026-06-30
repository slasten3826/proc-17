# Procesis Word Envelope Yellowprint v0

Source chaos:

```text
docs/00_chaos/procesis_word_and_organ_routing.md
```

## Pressure

The substrate needs stronger placement before decoding user tasks.

Old shape:

```text
user task

[operator runtime hints]
...
```

Problems:

```text
operator block looks optional
plan/build may be decoded through generic internet meanings
substrate may treat operator text as runtime context
```

## New Shape

Two layers:

```text
system_prompt = proc-17 envelope
prompt_payload = user task + optional procesis word
```

## System Prompt Responsibilities

The system prompt should:

```text
place substrate inside proc-17
state that body owns runtime truth
state that substrate returns semantic proposal only
define work_mode using proc-17 meanings
reject external plan/build meanings
tell substrate to preserve contradictions, missing evidence, unsupported forms as residue
state that procesis word is canonical orientation, not observed evidence
```

## Procesis Word Responsibilities

The operator block should be labeled:

```text
[procesis word]
```

It should say:

```text
canonical operator orientation
not observed runtime evidence
must not be promoted into runtime truth
```

## Trace

Keep existing `hint_pressure` event for compatibility.

Trace should still expose:

```text
enabled
reason
work_mode
operators
hint_count
```

The internal name may remain `operator_hints` in v0.
The substrate-facing name should be `procesis word`.

## Deferred Pressure

The fixed organ route remains scaffold.

Future body needs an organ router:

```text
body reads pressure
body chooses next organ
substrate may suggest but must not own routing authority
```

