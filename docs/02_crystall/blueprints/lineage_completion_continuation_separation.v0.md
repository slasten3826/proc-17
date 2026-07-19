# Lineage Completion / Continuation Separation Blueprint v0

Status: accepted treatment contract

Source table:
[`../../01_table/yellowprints/lineage_completion_continuation_separation_yellowprint.v0.md`](../../01_table/yellowprints/lineage_completion_continuation_separation_yellowprint.v0.md)

## 1. Objective

Make completion assessment invariant under changes to lineage affordability and
automatic-recovery policy, while preserving the runner's authority to stop an
unaffordable or unauthorized lineage.

## 2. Files

Modify:

```text
runtime/completion.lua
runtime/carrier.lua
runtime/lineage_runner.lua
tests/test_lineage_completion.lua
tests/test_lineage_runner.lua
tests/run.lua
```

Add:

```text
tests/test_lineage_completion_separation.lua
```

Amend the existing lineage table/crystall/manifest documents with explicit
links to this treatment. Do not silently leave the old combined semantics as a
second valid contract.

## 3. Completion Assessment Contract

`runtime/completion.lua` remains:

```lua
completion.evaluate(lineage, corpse) -> assessment | nil, err
```

It may read from `lineage` only:

```text
lineage identity
current Packet/corpse identity
completion_contract_id
```

It must not read:

```text
lineage.policy.allow_recovery
lineage.budget limits/spent/remaining/exhausted
carrier bounds
future generation capacity
```

Assessment v0 becomes:

```lua
{
  kind = "lineage_completion_assessment",
  protocol_version = "lineage.completion.v0",
  assessment_id = "lineage-assessment:" .. sha256(canonical_record),
  contract_id = string,
  task_state = "complete" | "unfinished" | "blocked"
             | "unsafe" | "unknown",
  terminal_recoverable = boolean,
  terminal_recovery_basis = string | nil,
  progress = table,
  remaining_work = table,
  evidence_refs = string[],
  manifest_refs = string[],
  missing_requirements = string[],
  event_truth_status = "runtime_confirmed",
  basis_truth_statuses = string[],
}
```

The `recoverable` key is absent.

## 4. Intrinsic Terminal Classification

Define one local immutable map:

```lua
local RECOVERABLE_TERMINALS = {
    budget_exhausted = true,
    identity_loss = true,
    stalled = true,
}
```

After unsafe, exact-complete and unknown-contract handling:

```lua
local terminal_recoverable = RECOVERABLE_TERMINALS[corpse.death_cause] == true

task_state = terminal_recoverable and "unfinished" or "blocked"
terminal_recovery_basis = terminal_recoverable and corpse.death_cause or nil
missing_requirements = terminal_recoverable
    and {}
    or {"recoverable terminal state"}
```

For complete, unsafe and unknown assessments:

```text
terminal_recoverable = false
terminal_recovery_basis = nil
```

## 5. Runner Decision Order

After corpse budget reconciliation and assessment append, the runner applies:

```text
1 task_state == complete
    -> finish complete / completion_contract_satisfied

2 task_state == unsafe
    -> finish terminated / unsafe_terminal

3 task_state == unknown
    -> finish suspended / unknown_completion_contract

4 task_state ~= unfinished OR terminal_recoverable ~= true
    -> finish suspended / terminal_not_recoverable

5 lineage.budget.exhausted == true
    -> finish exhausted / lineage_budget_exhausted

6 lineage.policy.allow_recovery ~= true
    -> finish suspended / recovery_disabled_by_policy

7 otherwise
    -> attempt recovery carrier
```

The order is deliberate:

- completion on the final paid action remains completion;
- unsafe, unknown and intrinsically blocked evidence cannot be hidden by an
  empty wallet;
- budget and policy decide only whether an unfinished recoverable task may
  continue.

## 6. Carrier Preconditions

`runtime/carrier.lua` replaces its ambiguous guard with:

```lua
assessment.task_state == "unfinished"
assessment.terminal_recoverable == true
type(assessment.terminal_recovery_basis) == "string"
```

It continues to verify current lineage/corpse ancestry and byte bounds.

The error becomes:

```text
terminal assessment cannot produce a recovery carrier
```

Carrier construction does not inspect lineage budget or policy. The runner is
the named reader and must call it only after steps 1-6 above.

## 7. Ledger And Report

The existing `completion_evaluated` event stores the revised assessment. Its
hash/id must be identical for matched states that differ only in wallet or
recovery policy.

Existing lineage terminal events remain the selected continuation evidence:

```text
lineage_completed
lineage_exhausted
lineage_suspended
lineage_terminated
continuation_decided (successful child only in this bounded slice)
```

This treatment does not claim the full general
`lineage_continuation_decision` candidate/exclusion ledger. That remains an
explicit future extension.

## 8. Regression Test Contract

### 8.1 Grown same-corpse test

Grow one Packet using the real tension runner fixture until it dies from local
`budget_exhausted`, then capture and verify one corpse.

Create three current lineage states with the same identity/current corpse:

```text
funded + recovery enabled
exhausted + recovery enabled
funded + recovery disabled
```

Reconcile the same corpse into each budget and evaluate completion.

Required assertions:

```text
all task_state == unfinished
all terminal_recoverable == true
all terminal_recovery_basis == budget_exhausted
all missing_requirements are empty
all assessment_id are identical
all records omit recoverable
```

### 8.2 Runner economic outcome

Grow a lineage whose first Packet dies from local budget and consumes the
lineage step limit exactly.

```text
lineage.status == exhausted
terminal.cause == lineage_budget_exhausted
assessment.task_state == unfinished
assessment.terminal_recoverable == true
no carrier
no child
```

### 8.3 Runner policy outcome

Grow the same local death with funded lineage budget and
`allow_recovery=false`.

```text
lineage.status == suspended
terminal.cause == recovery_disabled_by_policy
assessment.task_state == unfinished
assessment.terminal_recoverable == true
no carrier
no child
```

### 8.4 Existing cases

Retain green evidence for:

```text
one-generation exact completion
two-generation recovery completion
unknown contract
intrinsically blocked terminal
oversized carrier
loud world failure
```

## 9. Acceptance

```text
A1 same corpse assessment invariant across wallet
A2 same corpse assessment invariant across recovery policy
A3 exhausted lineage cannot create a carrier or child
A4 disabled recovery cannot create a carrier or child
A5 exact economic/policy stop causes are visible
A6 carrier accepts only unfinished intrinsically recoverable assessment
A7 existing two-generation lineage remains green
A8 full suite, mortality, camera, pressure ablation, Lua syntax and diff check pass
```

## 10. Rollback

If A1-A7 fail, do not restore the old combined boolean. Mark this treatment
rejected in the source table/crystall and keep the grown reproduction as a red
boundary test. A different continuation contract must still preserve task-state
invariance under wallet and policy changes.
