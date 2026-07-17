# Manifest Honesty Treatment Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/manifest_honesty_treatment_yellowprint.v0.md
implementation target: transition step 4.2
implemented and confirmed: 2026-07-17
```

## 1. Outcome Derivation

`logic/manifest.lua` derives exactly one boundary outcome:

```lua
if input.runtime_context.completion_state == "blocked"
    or input.logic_context.rejected_count > 0
then
    outcome = "blocked"
else
    outcome = "complete"
end
```

This is deterministic body logic. Substrate text cannot choose or override the
outcome.

## 2. Manifest Input

`organs/manifest.lua` adds:

```lua
sources.runtime_reconciliation_event

runtime_context = {
  completion_state = "blocked" | "complete" | "usable_partial" | "incomplete",
  reconciliation_event = event_id | nil,
  event_truth_status = "runtime_confirmed",
}
```

The latest `runtime_reconciliation` trace event is the named reader source.
The existing validation context remains the independent second witness.

## 3. Manifest Payload

```lua
{
  output = {
    type = string,
    text = string,
    language = string | nil,
    status = "complete" | "blocked",
  },
  summary = {
    status = "complete" | "blocked",
    -- existing summary fields
  },
  assembly = {
    outcome = "complete" | "blocked",
    runtime_completion_state = string | nil,
    -- existing assembly fields
  },
  terminal_cause = "complete" | "blocked",
  residue = {
    cause = "complete" | "blocked",
    runtime = runtime_context projection,
    -- existing choice/validation/cycle records
  },
  truth_status = "runtime_confirmed",
}
```

`truth_status` confirms deterministic assembly and outcome classification. It
does not promote `output.text` beyond its recorded substrate truth status.

## 4. Packet Finality

`core/packet.lua` registers `blocked` as a terminal death cause.

Before any manifest mutation, `packet.manifest_packet` normalizes a copied death
residue and enforces:

```text
residue.cause absent       -> set to payload terminal cause
residue.cause equal        -> accept
residue.cause different    -> invariant error, no mutation
```

The runner passes the assembled manifest residue rather than recreating a
second cause by hand.

## 5. Tests

Permanent tests prove:

```text
logic assembler projects blocked consistently
Packet accepts blocked manifestation and freezes with matching causes
Packet rejects a manifest residue cause mismatch before mutation
grown rejected tree life preserves text but reports blocked everywhere
grown accepted tree life remains complete
legacy observer still records dissent without authority
```

The former `pending_tree_manifest_honesty_gate.lua` was renamed to
`test_tree_manifest_honesty.lua` after all assertions became green.

## 6. Non-Goals

```text
no tree route change
no legacy repair loop restoration
no pressure weight calibration
no default authority flip
no grave policy for blocked lives
no retry policy
```

## 7. Manifested Result

```text
blocked validation is visible in output, summary and assembly
terminal, death and corpse residue agree on blocked
semantic text survives unchanged
accepted control remains complete
tests/test_tree_manifest_honesty.lua is permanent: 4/4 green
45 main suites and 8/8 mortality green
```

The blueprint is implemented. It authorizes rejected-validation cases for the
promotion corpus; it does not authorize default tree promotion.
