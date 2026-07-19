# Lineage Completion / Continuation Separation Yellowprint v0

Status: treatment table

Source chaos:
[`../../00_chaos/lineage_completion_economy_separation_notes_2026-07-19.md`](../../00_chaos/lineage_completion_economy_separation_notes_2026-07-19.md)

## 1. Purpose

Prevent lineage economics and recovery policy from rewriting the observed state
of one task and one verified corpse.

This table separates three products:

| Product | Question | Owner |
|---|---|---|
| task assessment | What does the current corpse prove about completion? | `runtime/completion.lua` |
| terminal recoverability | Can this terminal class produce recovery material in principle? | `runtime/completion.lua` |
| continuation outcome | May this lineage authorize and pay for another generation now? | `runtime/lineage_runner.lua` |

## 2. Fact Ownership

| Fact | Source | Truth status | Permitted readers | Must not change |
|---|---|---|---|---|
| corpse identity/hash | immutable corpse | runtime-confirmed | completion, carrier, runner | from policy or wallet |
| terminal kind/cause | immutable corpse | runtime-confirmed | completion, grave, runner | from lineage affordability |
| task completion evidence | corpse manifest/trace refs | statuses preserved | completion contract | from recovery preference |
| task state | completion derivation | runtime-confirmed act | runner, report, persistence | from current budget |
| terminal recoverability | completion derivation | runtime-confirmed act | runner, carrier | from current budget or policy |
| recovery permission | lineage policy | document/runtime configuration | runner | task state |
| lineage affordability | cumulative budget | runtime-confirmed | runner, economics | corpse classification |
| carrier viability | projected carrier and bounds | runtime-confirmed check | runner, NETWORK ingress | task completion evidence |

## 3. Revised Assessment Shape

Old ambiguous field:

```lua
recoverable = boolean
```

Replacement:

```lua
{
  kind = "lineage_completion_assessment",
  protocol_version = "lineage.completion.v0",
  assessment_id = string,
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

`recoverable` is removed rather than retained as an alias. Its old meaning mixed
three domains, so compatibility would preserve the defect.

## 4. Completion Classification Table

Budget and `policy.allow_recovery` are deliberately absent from this table.

| Completion contract result | Terminal cause | `task_state` | `terminal_recoverable` | basis | missing requirement |
|---|---|---|---:|---|---|
| exact contract satisfied | `complete` manifest | `complete` | false | nil | none |
| any | `unsafe_scope` / `cancelled` | `unsafe` | false | nil | safe continuation |
| contract unknown | any verified corpse | `unknown` | false | nil | known completion contract |
| contract not satisfied | `budget_exhausted` | `unfinished` | true | `budget_exhausted` | none |
| contract not satisfied | `identity_loss` | `unfinished` | true | `identity_loss` | none |
| contract not satisfied | `stalled` | `unfinished` | true | `stalled` | none |
| contract not satisfied | every other terminal cause | `blocked` | false | nil | recoverable terminal state |

For this v0, intrinsic terminal recoverability is an explicit bounded allowlist.
It does not claim that every future task contract should recover these causes in
the same way.

## 5. Continuation Table

The runner consumes the immutable assessment plus live lineage state.

| Task assessment | Terminal recoverable | Policy allows | Lineage budget | Runner outcome | Child |
|---|---:|---:|---|---|---:|
| `complete` | false | any | any | lineage `complete` | no |
| `unsafe` | false | any | any | lineage `terminated`, `unsafe_terminal` | no |
| `unknown` | false | any | any | lineage `suspended`, `unknown_completion_contract` | no |
| `blocked` | false | any | any | lineage `suspended`, `terminal_not_recoverable` | no |
| `unfinished` | true | any | exhausted | lineage `exhausted`, `lineage_budget_exhausted` | no |
| `unfinished` | true | false | available | lineage `suspended`, `recovery_disabled_by_policy` | no |
| `unfinished` | true | true | available | attempt bounded carrier | only after carrier succeeds |

Task-state outcomes precede economic and policy gates. This prevents an empty
wallet from hiding unsafe, unknown, or intrinsically blocked evidence.

## 6. Same-Corpse Matched Pairs

### Pair A: wallet

| Input | Funded | Exhausted |
|---|---|---|
| corpse/hash | same | same |
| terminal cause | `budget_exhausted` | `budget_exhausted` |
| assessment task state | `unfinished` | `unfinished` |
| terminal recoverable | true | true |
| assessment id | same | same |
| runner continuation | carrier candidate | lineage exhausted |

### Pair B: policy

| Input | Recovery enabled | Recovery disabled |
|---|---|---|
| corpse/hash | same | same |
| assessment task state | `unfinished` | `unfinished` |
| terminal recoverable | true | true |
| assessment id | same | same |
| runner continuation | carrier candidate | suspended by policy |

The assessment id is expected to remain identical because no assessment input
changed. Wallet and policy belong to the next decision boundary.

## 7. Reader / Writer Table

| Record/field | Writer | Named reader | Effect |
|---|---|---|---|
| `task_state` | completion | runner, report, future resume | completion branch only |
| `terminal_recoverable` | completion | runner, carrier | permits consideration of recovery material |
| `terminal_recovery_basis` | completion | carrier, audit | explains intrinsic recovery classification |
| `lineage.budget.exhausted` | economics | runner | blocks automatic child, never changes assessment |
| `lineage.policy.allow_recovery` | lineage creation/policy | runner | blocks automatic child, never changes assessment |
| carrier bounds/result | carrier builder/verifier | runner, NETWORK ingress | permits or blocks one exact re-entry artifact |
| lineage terminal event | runner through lineage body | session/report/resume | records selected continuation outcome |

## 8. Ordering

```text
capture and verify corpse
reconcile corpse spending into lineage budget
derive task/terminal assessment without reading policy or affordability
append completion_evaluated

task_state=complete -> complete lineage
task_state=unsafe -> terminate unsafe
task_state=unknown -> suspend unknown
task_state=blocked or terminal_recoverable=false -> suspend terminal_not_recoverable
lineage budget exhausted -> exhaust lineage
recovery policy disabled -> suspend recovery_disabled_by_policy
otherwise -> build and verify one bounded carrier
```

Completion remains before budget so a task that finishes on its last paid action
is complete rather than economically relabelled. Unsafe/unknown/blocked facts
also remain visible instead of being hidden by a simultaneous empty wallet.

## 9. Carrier Boundary

Carrier construction may require:

```text
assessment.task_state = unfinished
assessment.terminal_recoverable = true
assessment.terminal_recovery_basis is a known intrinsic cause
corpse and lineage ancestry match
```

Carrier construction does not decide:

```text
whether recovery policy is enabled
whether cumulative lineage budget permits another generation
whether a child should actually be committed
```

Those are runner/lineage powers. The bounded in-memory v0 still relies on the
runner to apply them before carrier construction. A future general continuation
decision record may make that authorization an explicit carrier input.

## 10. Failure Classification

| Failure | Classification | Lineage consequence |
|---|---|---|
| malformed/unverified corpse | world/invariant error | loud; no assessment or grave fabrication |
| unknown completion contract | known epistemic outcome | suspend unknown |
| terminal cause outside recovery allowlist | task/terminal outcome | suspend terminal not recoverable |
| cumulative budget exhausted | economics | exhaust lineage |
| recovery policy disabled | policy | suspend with exact cause |
| carrier too large | materialization boundary | suspend `carrier_too_large` |
| Lua error or malformed trusted record | world failure | loud; never convert to mortality |

## 11. Acceptance Matrix

| ID | Grown evidence | Expected |
|---|---|---|
| S1 | same budget-dead corpse, funded lineage | unfinished + terminal recoverable |
| S2 | same corpse, exhausted lineage | identical assessment id and fields |
| S3 | same corpse, recovery-disabled lineage | identical assessment id and fields |
| S4 | exhausted lineage runner life | no carrier/child; status exhausted; assessment unfinished |
| S5 | recovery-disabled runner life | no carrier/child; suspended by policy; assessment unfinished |
| S6 | funded two-generation life | one carrier; descendant completes |
| S7 | exact complete first generation at budget boundary | complete remains complete |
| S8 | malformed corpse | loud error, no assessment |

## 12. Non-Goals

This treatment does not implement:

```text
persistent resume
the full candidate/exclusion continuation ledger
branching descendants
new terminal recovery causes
carrier semantic compaction
repository hands
```

It repairs the information boundary required before those readers exist.
