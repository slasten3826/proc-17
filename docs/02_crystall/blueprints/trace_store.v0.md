# Trace Store Blueprint v0

Trace store persists packet life as machine-readable JSONL.

## Current Module

```text
runtime/trace_store.lua
```

## Current Function

```text
write_jsonl(path, packet) -> true | nil, error
```

## Output Contract

The file contains:

```text
one JSON object per packet trace event
one final envelope after trace events
```

Event envelope fields:

```text
packet_id
event_id
type
operator
truth_status
payload
```

Final envelope fields:

```text
packet_id
type = "final"
status
residue
```

## Current CLI Integration

```text
--trace-file <path>
```

Trace persistence is explicit.
The CLI does not write trace files by default.

## Verification

```text
unit_test: trace_store writes birth event
unit_test: trace_store writes final envelope
integration_test: CLI accepts --trace-file
```
