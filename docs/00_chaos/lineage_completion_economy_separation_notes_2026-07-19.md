# Lineage Completion And Economy Separation Notes - 2026-07-19

```text
layer:          CHAOS (⋯)
status:         reproduced defect / treatment pressure
source:         external cold audit followed by local reproduction
scope:          runtime/completion.lua and lineage continuation boundary
authority:      mixed; reproduction is runtime-confirmed, treatment is proposed
```

## Incoming Defect

An external cold audit grew one real Packet death and evaluated the same corpse
under two lineage-budget states. The audit claimed that the completion
assessment changed its verdict about the task when only the lineage wallet
changed.

Local reproduction confirmed the claim:

```text
same corpse_id
same corpse_hash
same death_cause = budget_exhausted
same completion contract = plan.v0

funded lineage:
  task_state = unfinished
  recoverable = true
  missing_requirements = {}

exhausted lineage:
  task_state = blocked
  recoverable = false
  missing_requirements = {"recoverable terminal state"}
```

The only changed fact was `lineage.budget.exhausted`.

## Why This Is A Defect

Three different questions were collapsed into one boolean:

```text
Q1 task state:
   did the task complete, remain unfinished, become unsafe, or become unknown?

Q2 terminal recoverability:
   can this kind of corpse lawfully produce a recovery carrier in principle?

Q3 continuation eligibility:
   may this particular lineage pay for and authorize another generation now?
```

`runtime/completion.lua` currently computes all three through:

```lua
local recoverable = lineage.policy.allow_recovery == true
    and recoverable_causes[corpse.death_cause] == true
    and not lineage.budget.exhausted
```

It then derives both `task_state` and `missing_requirements` from that combined
boolean. A wallet fact can therefore rewrite a task fact.

The statement `"recoverable terminal state"` is also false in the exhausted
case. `budget_exhausted` is explicitly a locally recoverable terminal cause.
What is absent is not a recoverable corpse; what is absent is lineage
affordability.

## Existing Architecture Already Contains The Separation

The broader lineage documents did not require this collapse:

```text
completion.evaluate(...)             -> task/corpse assessment
lineage continuation evaluation      -> policy/economy/carrier decision
```

The general lineage table names lineage budget as one input to the continuation
decision, not as evidence that changes the completed or unfinished state of the
task. The in-memory v0 implementation compressed those two phases for speed and
reintroduced the ambiguity.

This is therefore a boundary regression in the bounded slice, not evidence that
the lineage architecture itself is wrong.

## Current Runtime Consequence

The outer behavior is presently correct by a second reader:

```text
completion writes blocked/recoverable=false
lineage_runner separately sees state.budget.exhausted
lineage_runner finishes status=exhausted, cause=lineage_budget_exhausted
```

The task assessment is false, but the runner's final lineage status is correct.
This limits the current defect to a misleading immutable assessment and report.

The defect becomes materially dangerous when assessments are persisted or used
for resume. A future reader could inherit:

```text
task blocked because terminal state is unrecoverable
```

when the true history was:

```text
task unfinished; terminal recoverable; this lineage could not pay for a child
```

## Proposed Separation

Completion assessment should answer Q1 and Q2 only:

```lua
{
  task_state = "complete" | "unfinished" | "blocked"
             | "unsafe" | "unknown",
  terminal_recoverable = boolean,
  terminal_recovery_basis = string | nil,
  missing_requirements = string[],
  ...
}
```

Continuation authority should answer Q3 from separate inputs:

```text
assessment.task_state
assessment.terminal_recoverable
lineage.policy.allow_recovery
lineage.budget.exhausted / exhausted_keys
carrier viability
```

For the reproduced corpse:

```text
completion assessment:
  task_state = unfinished
  terminal_recoverable = true
  terminal_recovery_basis = budget_exhausted

funded lineage continuation:
  eligible to build a carrier

exhausted lineage continuation:
  no child
  lineage status = exhausted
  cause = lineage_budget_exhausted
```

The word `recoverable` must not remain as an ambiguous compatibility alias. A
stale reader should fail loudly or be updated to the explicit field rather than
silently preserve the conflation.

## Policy Is Also Not Task State

The audit exposed budget, but `policy.allow_recovery` has the same category
error. Disabling automatic recovery does not complete or intrinsically block an
unfinished task. It means this lineage is not authorized to create a child.

Therefore:

```text
recoverable corpse + allow_recovery=false
  task_state = unfinished
  terminal_recoverable = true
  lineage outcome = suspended / recovery disabled
```

Policy and economy must both be removed from completion classification.

## Laws To Preserve

1. Completion never reads lineage affordability to classify task state.
2. Terminal recoverability is derived from the terminal cause and exact task
   contract, not from current money or operator preference.
3. The lineage runner remains the named reader of policy and cumulative budget.
4. No child may be built after lineage budget exhaustion even when the corpse is
   intrinsically recoverable.
5. Disabling recovery must not relabel an unfinished task as blocked.
6. Unsafe and unknown task states cannot be laundered into recovery eligibility.
7. Carrier construction consumes an explicitly recoverable terminal assessment;
   it does not decide whether the lineage can afford or authorize birth.
8. Lua/invariant failures remain outside Packet and lineage mortality.

## Falsifiers

The treatment is false if any of these remain possible:

```text
same verified corpse + same contract + different wallet -> different task_state
same verified corpse + same contract + different policy -> different task_state
exhausted lineage builds or charges a recovery carrier
recovery-disabled lineage creates a child
unrecoverable terminal state reaches carrier construction
runner reports no_recovery_path when the exact blocker is lineage budget
assessment says recoverable terminal state is missing for budget_exhausted corpse
```

## Required Grown Evidence

Do not test this only with hand-built records.

```text
C1 grow one exact plan Packet that dies budget_exhausted
C2 capture and verify its corpse
C3 reconcile the same corpse into funded and exhausted lineage budgets
C4 prove task_state and terminal_recoverable remain identical
C5 prove continuation outcomes differ by the exact economic blocker
C6 run a recovery-disabled lineage and prove no child is born while the task
   remains unfinished
C7 retain the existing two-generation success and complete-plan cases
```

## Expected Documentation Path

```text
this CHAOS observation
  -> table: orthogonal states and reader ownership
  -> crystall: exact assessment schema and runner order
  -> code: completion purity plus explicit continuation guards
  -> manifest: grown regression evidence and remaining limits
```
