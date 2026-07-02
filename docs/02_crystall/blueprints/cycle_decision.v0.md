# Cycle Decision Blueprint v0

This blueprint defines the first `☲ CYCLE` contract.

## Primary Rule

CYCLE decides whether a packet may continue for one more bounded turn.

CYCLE must not become an immortal loop.

## Module

```text
logic/cycle.lua
```

Operator:

```text
☲ CYCLE
```

## Scope

CYCLE may decide continuation.

CYCLE must not:

```text
call substrate
run tools
read files
write files
validate selected paths
rank semantic options
manifest final output
```

Those belong to other operators.

## Netzach Invariant

`☲ CYCLE` is the near-zero-loss continuation valve.

It must not become the workflow engine.

It consumes already-counted pressure:

```text
needed = N
done = M
remaining = N - M
```

And answers:

```text
remaining > 0 -> again
remaining == 0 -> stop_complete
```

`☱ RUNTIME` counts progress.

`☶ LOGIC` validates the count.

`☲ CYCLE` only decides whether the counted unfinished form gets one more turn.

## Required Function

```text
decide(input) -> cycle_decision_payload | nil, error
```

Input:

```text
cycle_key
turn_count
max_turns
accepted_count
new_input_count
budget
required_budget
state_fingerprint
previous_fingerprints
manifest_ready
unsafe
needs_user_input
progress
```

Optional progress input:

```text
progress = {
  goal = string | nil,
  needed_count = number,
  done_count = number,
  remaining_count = number,
  logic_status = "accepted" | "rejected" | "invalid" | nil
}
```

## Required Payload Fields

```text
kind = cycle_decision_payload
decision
reason
cycle_key
turn_count
max_turns
truth_status = runtime_confirmed
semantic_loss = near_zero
runtime_cost = one_turn
```

Allowed decisions:

```text
continue
again
stop_complete
stop_no_progress
stop_repetition
stop_budget
stop_unsafe
stop_invalid
needs_user_input
```

## Decision Priority

Decision priority must be deterministic:

```text
unsafe
needs_user_input
manifest_ready
budget
max_turns
repetition
invalid progress
progress complete
progress remaining
accepted_count
new_input_count
continue
```

Mapping:

```text
unsafe == true
  -> stop_unsafe

needs_user_input == true
  -> needs_user_input

manifest_ready == true
  -> stop_complete

budget cannot pay required_budget
  -> stop_budget

turn_count >= max_turns
  -> stop_repetition

state_fingerprint exists in previous_fingerprints
  -> stop_repetition

progress.logic_status is rejected or invalid
  -> stop_invalid

progress.remaining_count <= 0
  -> stop_complete

progress.remaining_count > 0
  -> again

accepted_count <= 0
  -> stop_no_progress

new_input_count <= 0
  -> stop_no_progress

otherwise
  -> continue
```

## Budget Contract

Budget check must be simple:

```text
for each required_budget[key]:
  budget[key] >= required_budget[key]
```

Missing budget key is treated as zero.

## Repetition Contract

`previous_fingerprints` is a list or map of already-seen state fingerprints.

If current `state_fingerprint` is present, CYCLE stops.

No fuzzy matching in v0.

## Test Obligations

```text
unit_test: continues with accepted input, new input, and budget
unit_test: stops unsafe before other reasons
unit_test: stops when user input is needed
unit_test: stops when manifest is ready
unit_test: stops when budget cannot pay required budget
unit_test: stops when max_turns reached
unit_test: stops when fingerprint repeats
unit_test: returns again when progress has remaining work
unit_test: stops complete when progress remaining_count is zero
unit_test: stops invalid when progress logic_status is rejected
unit_test: preserves near-zero semantic loss marker
unit_test: stops with zero accepted_count
unit_test: stops with zero new_input_count
```

## Not In Scope

```text
automatic repo loop orchestration
state fingerprint computation
packet event append
substrate calls
tool calls
death handling
```

## First Consumer

Expected first consumer:

```text
repo listing -> selection -> validation -> cycle decision -> repo context
```

The automatic loop is not implemented by this module.

## Manual Check Result

Live trace:

```text
/tmp/proc-17-cycle-live.jsonl
```

Manual chain:

```text
repo_listing_eye
DeepSeek selection proposal
repo_selection_validator
cycle.decide
```

Observed selection:

```text
accepted:
  logic/cycle.lua
  tests/test_cycle.lua

rejected:
  missing/cycle_ghost.lua = absent_from_listing
  docs/02_crystall = directory_not_allowed
```

Cycle decision:

```text
decision = continue
reason = continuation_payable
truth_status = runtime_confirmed
```

Manual check status:

```text
manual_check: cycle continues after accepted selection with payable budget
```

Next missing integration:

```text
automatic handoff from continue decision to repo_context_organ
```

## Manifest v0 Status

Current implementation:

```text
logic/cycle.lua
tests/test_cycle.lua
```

Implemented:

```text
decide
decision validation helper
budget can-pay check
fingerprint repetition check
deterministic priority order
runtime_confirmed decision payload
```

Still absent:

```text
automatic repo loop orchestration
state fingerprint computation
packet event append integration
death handling integration
CLI integration
automatic repo_context handoff
```
