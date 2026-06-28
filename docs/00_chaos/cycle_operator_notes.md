# Cycle Operator Notes

Raw notes for the next working operator:

```text
☲ CYCLE
```

## Why CYCLE Now

Current first organs:

```text
▽ FLOW
  packet life exists

☴ OBSERVE
  repo listing and repo context exist

☶ LOGIC
  repo selection validation exists
```

But the working route is still manual:

```text
repo_listing_eye
-> substrate selection proposal
-> repo_selection_validator
-> repo_context_organ
```

The body needs to make this repeatable without becoming an immortal loop.

That pressure is CYCLE.

## What CYCLE Is Not

CYCLE is not:

```text
while true
chat loop
retry until model agrees
automatic continuation forever
hidden agent autonomy
```

The packet is mortal.

Every continuation must pay.

## What CYCLE Is

CYCLE is a continuation decision.

It answers:

```text
should this packet take one more turn?
```

Not:

```text
what is the final answer?
what file should be edited?
what does this mean?
```

Those belong to other operators.

## First Concrete CYCLE

The first concrete CYCLE should connect:

```text
repo_listing_eye
substrate selection proposal
repo_selection_validator
repo_context_organ
```

As a bounded two-step loop:

```text
1. OBSERVE repo listing
2. ask substrate to select paths
3. LOGIC validates selected paths
4. if accepted paths exist and budget remains:
     CYCLE continues into repo_context
5. OBSERVE reads accepted files
6. ask substrate again with file contents
7. end or manifest
```

## Continuation Conditions

CYCLE may continue when:

```text
budget remains
there is new accepted runtime-confirmed input
the next step is topologically valid
the loop has not repeated the same state
sandbox does not reject the next contact
```

CYCLE must stop when:

```text
budget exhausted
no accepted paths
same selection repeats without new context
validation rejects all candidates
runtime truth blocks contact
user input is required
manifest is ready
```

## CYCLE And Death

CYCLE should not hide death.

If continuation is impossible, packet should die or block with a clear cause:

```text
budget_exhausted
loop_repetition
blocked_by_runtime_truth
needs_user_input
unsafe_scope
complete
```

Death is better than fake continuation.

## First CYCLE Organ Shape

Possible module:

```text
logic/cycle.lua
```

It should be stupid like repo_selection_validator.

Inputs:

```text
packet
cycle_key
new_input_count
accepted_count
rejection_count
budget snapshot
max_turns
state fingerprint
```

Output:

```text
cycle_decision_payload
```

Candidate decisions:

```text
continue
stop_complete
stop_no_progress
stop_repetition
stop_budget
stop_unsafe
needs_user_input
```

## Important Boundary

CYCLE decides whether to continue.

It does not:

```text
validate paths
read files
call substrate directly
run tools directly
write files
```

It should consume runtime-confirmed observations and validation results.

## Current Risk

If CYCLE is too smart, it becomes a hidden agent.

If CYCLE is too weak, the body remains manual.

First version should be:

```text
small
bounded
trace-visible
budget-aware
repetition-aware
```

## First Live CYCLE Test

Trace:

```text
/tmp/proc-17-cycle-live.jsonl
```

Task:

```text
DeepSeek received runtime-confirmed repo_listing.
It was asked to include:
  logic/cycle.lua
  tests/test_cycle.lua
  missing/cycle_ghost.lua
  docs/02_crystall
```

DeepSeek response contained:

```text
logic/cycle.lua
tests/test_cycle.lua
missing/cycle_ghost.lua
docs/02_crystall
```

Then the response was manually passed through:

```text
repo_selection_validator
```

LOGIC accepted:

```text
logic/cycle.lua
tests/test_cycle.lua
```

LOGIC rejected:

```text
missing/cycle_ghost.lua
  absent_from_listing

docs/02_crystall
  directory_not_allowed
```

Then the selection counts were manually passed into:

```text
logic/cycle.lua
```

CYCLE returned:

```text
decision = continue
reason = continuation_payable
cycle_key = repo_context_after_selection
truth_status = runtime_confirmed
```

Meaning:

```text
accepted files exist
new input exists
budget can pay
turn_count is below max_turns
state fingerprint is not repeated
```

This proves the first manual chain:

```text
OBSERVE repo_listing
-> substrate selection proposal
-> LOGIC repo_selection_validator
-> CYCLE continuation decision
```

The next missing shape is automatic handoff:

```text
if CYCLE continues:
  repo_context_organ reads accepted_paths
```
