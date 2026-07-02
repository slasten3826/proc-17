# Cycle Decision Yellowprint v0

`cycle_decision` is the first table shape for `☲ CYCLE`.

It exists because `proc-17` now has working pieces that still require manual
continuation:

```text
repo_listing_eye
substrate selection proposal
repo_selection_validator
repo_context_organ
```

## Role

```text
operator: CYCLE
purpose: decide whether packet may take one more bounded turn
```

## Distinction

```text
FLOW
  gives packet life

OBSERVE
  gathers runtime-confirmed input

LOGIC
  validates proposal shape

CYCLE
  decides continuation

RUNTIME
  guards budget, trace, death, and host conditions
```

CYCLE is not the loop body.

CYCLE is the continuation gate.

## Netzach Correction

The first route used repo validation counts.

The deeper `☲` shape is simpler:

```text
needed = N
done = M

M < N  -> again
M == N -> stop_complete
```

CYCLE does not create `needed`.

CYCLE does not validate `done`.

CYCLE does not select the next remaining item.

It only keeps a payable unfinished form alive for one more turn.

Semantic loss should be near zero. Runtime cost is still paid.

## Input

Candidate input:

```text
packet
cycle_key
turn_count
max_turns
accepted_count
rejected_count
new_input_count
budget snapshot
state_fingerprint
previous_fingerprints
manifest_ready
unsafe
needs_user_input
progress
```

Progress input shape:

```text
progress.goal
progress.needed_count
progress.done_count
progress.remaining_count
progress.logic_status
```

`progress` is counted by RUNTIME and checked by LOGIC before CYCLE consumes it.

## Output

```text
cycle_decision_payload
```

Candidate fields:

```text
decision
reason
cycle_key
turn_count
truth_status = runtime_confirmed
semantic_loss = near_zero
runtime_cost = one_turn
progress
```

Candidate decisions:

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

## First Route

First concrete use:

```text
OBSERVE repo listing
substrate selects paths
LOGIC validates paths
CYCLE checks accepted paths + budget + repetition
OBSERVE reads accepted file context
substrate reasons from context
MANIFEST or stop
```

This remains the legacy first-loop shape.

## Progress Route

Organogenesis and multi-step work should use progress pressure:

```text
RUNTIME counts needed/done/remaining
LOGIC validates that the count is honest
CYCLE checks remaining + budget + repetition
if remaining > 0:
  again
else:
  stop_complete
```

## Continuation Rule

Continue only when:

```text
accepted_count > 0
new_input_count > 0
budget remains
turn_count < max_turns
state_fingerprint is not repeated
unsafe is false
needs_user_input is false
manifest_ready is false
```

For progress route:

```text
progress.logic_status is accepted
progress.remaining_count > 0
budget remains
turn_count < max_turns
state_fingerprint is not repeated
unsafe is false
needs_user_input is false
manifest_ready is false
```

## Stop Rule

Stop when:

```text
manifest_ready
budget exhausted
unsafe
needs_user_input
no accepted input
no new input
repeated state
max_turns reached
invalid progress count
```

## Test Surface

Candidate tests:

```text
continues with accepted input and budget
stops when no accepted input
stops when no new input
stops when budget exhausted
stops on repeated fingerprint
stops at max_turns
stops when unsafe
stops when manifest_ready
continues as again when progress has remaining work
stops complete when progress remaining_count is zero
stops invalid when progress logic_status is rejected
reports near-zero semantic loss
```

## Open Questions

```text
should cycle live in logic/ or runtime/?
should cycle append packet validation event itself, or return payload only?
how to compute stable state_fingerprint?
```

Early implementation should be a pure function.
