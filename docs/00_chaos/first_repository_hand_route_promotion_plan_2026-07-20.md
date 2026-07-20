# First Repository Hand: Route Promotion Plan

status: chaos / implementation gate
date: 2026-07-20
roadmap: chapter 7, step 7.9
inherits:
- `docs/01_table/yellowprints/capability_safe_repository_hands_yellowprint.v0.md`
- `docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md`
- `docs/00_chaos/first_repository_hand_hostile_audit_results_2026-07-20.md`

## Purpose

Steps 7.1-7.8 built and attacked one bounded physical hand. The body can already
authorize one exact `create_text_file` action, execute it through LOGIC, read it
back independently, validate the evidence and let RUNTIME record exact work
completion. Those mechanisms are deliberately callable only through direct test
boundaries today.

Step 7.9 connects them to qualified Tree routing without adding an operator,
granting the substrate authority, or hardcoding a complete trace.

## Current Red Boundary

The staged route suite has five intentional failures:

```text
R2  one uncontested action never reaches review/effect/reconcile
R3  a selected real alternative never reaches effect/reconcile
R6  reconcile ablation cannot yet distinguish evidence from completion
R7  rejected read-back cannot yet demonstrate pending work in a routed life
R8  the exact accepted routed chain does not yet exist
```

The effect, progress, security and hostile boundaries underneath these routes
are already green. Route failures must be repaired by named pressure readers,
not by calling the effect from the fixture or forcing a glyph sequence.

## Causal Chain

No mutable repository action state is added. Every phase is rederived from the
current field, immutable trace and the private host capability registry.

### One uncontested work item

```text
☵ formed exact work
  -> repository_review_need
☱ records repository_action_review
  -> repository_effect_need
☶ executes exact action and records attempt/receipt/verification/validation
  -> repository_reconcile_need
☱ rereads the exact accepted chain and records work_completion
```

Required subpath:

```text
☵ -> ☱ -> ☶ -> ☱
```

The first RUNTIME visit is a real action review. It is not an empty topology
bridge and must not mark work complete.

### Real mutually exclusive alternatives

```text
☵ formed alternatives
  -> existing choice_need
☳ selects exactly one work item and suppresses the others
  -> repository_effect_need for the selected action
☶ executes and validates it
  -> repository_reconcile_need
☱ records exact completion
```

Required subpath:

```text
☵ -> ☳ -> ☶ -> ☱
```

One item must never pay choice loss merely to reach the hand.

## Named Readers And Writers

| Phase | Reader | Immutable input | Writer/effect | First next reader |
|---|---|---|---|---|
| review | qualified repository inspection | current uncontested intent + exact live grant + no review/attempt/completion | ☱ `repository_action_review` | effect pressure |
| effect after review | qualified repository inspection | exact current actionable review + same action/grant/work version | ☶ repository transaction | reconcile pressure |
| effect after choice | qualified repository inspection | exact selected alternative + same live grant + no attempt/completion | ☶ repository transaction | reconcile pressure |
| reconcile | qualified repository inspection | accepted verification + accepted LOGIC validation over same action and refs | ☱ `work_completion` | progress/CYCLE/MANIFEST |

The trace remains the only action-phase ledger. The private registry is an
external affordance reader, not Packet memory and not route payload.

## Host Boundary

`host_services.repository_capabilities` must cross runner and operator registry
by reference. It must not be deep-copied into qualified action options,
serialized into pressure evidence, put in trace, corpse, carrier or manifest.

The committed action plan carries only the public immutable action projection.
RUNTIME and LOGIC receive the private registry as a separate trusted argument.

## Effect Economics

The organ reports actual effect cost; only the runner charges it:

```text
ordinary ☶ tick                         steps += 1
accepted/rejected repository effect     tool_calls/file_writes/time_ms += actual
typed external effect failure           existing failure path charges actual cost
identity loss                           unchanged
```

The success/rejection cost must be charged exactly once after the applied ☶
tick. Direct body tests continue to report cost without silently charging it.

## Failure Classes

```text
no grant / no affordable exact action before route
  -> no qualified witness, no provider call

grant revoked or external world changes after committed route
  -> typed effect_failure and honest Packet death through the existing path

accepted write receipt but rejected independent verification
  -> applied LOGIC result, no completion

malformed trusted action/provider/evidence or Lua/native invariant failure
  -> loud harness error, never a decorative Packet death
```

## Ablations

The existing controls remain causal:

```text
ablate_repository_review     removes only the single-action ☱ review proposal
ablate_repository_effect     removes ☶ effect pressure
ablate_repository_reconcile  permits evidence but forbids completion
```

An ablation may remove a witness. It may not suppress a direct call hidden in
an organ or fixture, because no such hidden call is allowed.

## Implementation Order

1. Add a pure repository phase inspector and exact trace lookup helpers.
2. Add actor-guarded `repository_action_review` schema/writer.
3. Add qualified review/effect/reconcile witness producers.
4. Add RUNTIME review mode with ordinary camera work retained.
5. Add RUNTIME reconcile mode that derives and records exact completion.
6. Pass private host services separately through runner/registry.
7. Charge successful/rejected repository effect economics once in runner.
8. Turn R2/R3/R6/R7/R8 and their ablations green.
9. Register demonstrated suites in the default corpus and rerun hostile/native
   audits.

## Falsifiers

Step 7.9 fails if any of these occur:

```text
a fixed full trace is introduced
one item is sent through fake CHOOSE
☶ executes without a committed exact action plan
provider state appears in Packet or trace
receipt alone creates completion
rejected verification creates completion
completion is written outside ☱
an effect cost is absent, duplicated or charged by the organ
an ablated reader still produces its downstream effect
disabled hands alter legacy/shadow lives
a trusted invariant error is converted into Packet death
```

## Acceptance

Step 7.9 is accepted only when:

```text
R0-R10 route controls are green
staged repository boundary is fully green
default Lua suite is green
mortality remains 8/8
native hostile/sanitizer checks remain green
disabled-hand ablation is physically identical
the exact accepted life contains one attempt, receipt, verification and completion
the rejected life contains receipt/verification but no completion
repository effect cost is charged once and loss is unchanged
```

This plan authorizes wiring already demonstrated mechanisms. It does not
authorize overwrite, patch, delete, mkdir, shell, tests, git, multiple file
scheduling, manifest widening or router-authority changes.

## Observation During Implementation

The first grown alternative route falsified the abbreviated `☵ -> ☳` edge in
this plan. Structure formation creates fresh field versions and the existing
CHOOSE contract correctly requires their field-native observation. The accepted
alternative chain is therefore:

```text
☵ -> ☴ -> ☳ -> ☶ -> ☱
```

The earlier abbreviation remains above as archaeology. The test and current
CRYSTALL contract use the observed chain; no OBSERVE or CHOOSE guard was removed
to make the route green.
