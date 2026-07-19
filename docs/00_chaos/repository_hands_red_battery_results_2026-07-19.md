# Repository Hands Red Battery Results

Amendment 2026-07-19:

```text
This document preserves the step-5 red baseline. Step 6 subsequently made the
capability, intent and authorized-action suites green without granting a
filesystem effect. Current boundary evidence is recorded in
docs/03_manifest/repository_capability_boundary.v0.md.
```

layer: CHAOS / observed test pressure
date: 2026-07-19
roadmap_step: 5 of 10
status: red baseline established; implementation not started
authority: test observation, not product capability

## Why This Battery Exists

The repository hand must not be implemented first and justified afterward.
This battery states what would falsify the hand before the body receives any
new authority over the host filesystem.

The battery is intentionally separate from `tests/run.lua`. The established
body remains green while the unimplemented repository-hand contract remains
visibly red. A red suite joins the main runner only after its named production
boundary exists and the suite passes for the intended reason.

## Observed Baseline

Command:

```text
lua tests/red_repository_hands.lua
```

Observed:

```text
repository-hands red baseline: green=0 red=7 total=7
process exit: 1
```

Across those seven suites there are 70 executable controls:

```text
69 RED
1 GREEN
1 explicit SKIP outside the executable-control count
```

The one green control is `R0/R9 disabled hands are physically inert`. It proves
that merely supplying absent/disabled repository-hand configuration does not
change route, step cost, identity loss or effect trace. The skip is P15, whose
cross-device bind-mount fixture requires explicit host opt-in through
`PROC17_TEST_BIND_MOUNT=1`.

All 69 red controls currently fail at named absent contract modules:

```text
runtime.repository_capability
runtime.repository_intent
runtime.repository_action
runtime.repository_effect
runtime.repository_provider
runtime.work_completion
```

No red control reached a provider mutation primitive. No test in this baseline
wrote into a repository through proc-17.

## Suite Map

| Suite | Controls now | Named pressure |
|---|---:|---|
| repository-capability | 12 red | grant absence, ambiguity, revocation, lineage/session/repository scope, projection aliasing |
| repository-intent | 11 red | exact structured artifact, path/content grammar, real choice, no implicit scheduling |
| repository-action | 10 red | plan/build authority, grant bounds, stable identity, generation and field-version staleness |
| repository-effect | 10 red | attempt/receipt/read-back chain, typed world failure, loud malformed trusted data, actual cost |
| repository-provider-linux | 10 red + 1 skip | containment, symlinks, no-replace, root identity, atomicity and command rejection |
| repository-progress | 7 red | exact completion predicate, idempotence, work/version isolation and body progress |
| repository-route | 1 green + 9 red | opt-in inertness, review/effect/reconcile path, ablations and no implicit Tree promotion |

## Native Build Gate

Command:

```text
make -C native test
```

Observed:

```text
Lua 5.4 development headers are required
process exit: 2
```

The host has Lua 5.4 runtime libraries but no Lua 5.4 development headers or
pkg-config metadata. The native provider and its private fault-injection ABI do
not exist yet. This is a named build prerequisite for step 7, not a fallback
authorization. The implementation must not silently replace `openat2` /
`renameat2` with weaker path checks.

## Regression Control

Command:

```text
lua tests/run.lua
```

Observed:

```text
all tests ok
process exit: 0
```

The pre-existing body, Tree authority gates, mortality, lineage and manifest
honesty remain green. The red battery is not registered there, so a known future
contract cannot turn the current repository permanently red.

## Corrections Discovered While Writing Tests

The battery found one test defect before it could become a false red: the
disabled-hands route control initially read budget from the run report instead
of `instance.runtime.budget`. It was corrected and now passes without any hand
implementation.

It also forced three CRYSTALL clarifications:

1. pure intent validates grammar and records byte lengths; live grant-specific
   limits belong to action authorization because intent owns no authority;
2. an exact missing read-back is a valid observation with
   `target_kind=missing`, then a rejected verification, not a malformed tool
   result;
3. `repository_effect.execute` returns a detached
   `repository.effect_result.v0` projection whose mutation cannot rewrite trace.

These are contract corrections, not implementation concessions.

## Promotion Law

The suites must become green in dependency order:

```text
step 6: capability, intent and authorized-action boundary
step 7: native provider and exact create/read-back transaction
step 8: actor rights, LOGIC/RUNTIME completion and qualified routing
```

Turning a suite green by weakening a path rule, accepting a synthetic receipt,
using caller shell commands, suppressing a malformed trusted record, or adding
a broad fallback is a false green.

Step 5 is complete when this baseline is reproducible, the legacy suite remains
green, Lua syntax and diff checks pass, and the battery remains outside the main
runner until implementation exists.
