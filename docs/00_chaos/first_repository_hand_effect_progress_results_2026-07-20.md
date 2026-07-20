# First Repository Hand: Effect And Progress Results

date: 2026-07-20
status: roadmap step 7.7 complete
plan: `first_repository_hand_effect_progress_plan_2026-07-20.md`
previous: `first_repository_hand_independent_read_results_2026-07-20.md`
next: roadmap step 7.8, adversarial and fault-injection audit

## 1. Result

The previously separate capability, action, atomic create and independent read
boundaries now form one deliberately callable body transaction:

```text
repository.action.v0
  -> ☶ repository_effect_attempt
  -> private one-use effect lease
  -> native create_text_file
  -> ☶ repository_effect_receipt
  -> native read_text_file of the same action target
  -> ☶ repository_verification
  -> ☶ LOGIC validation
  -> ☱ work_completion
  -> body.progress done=1 remaining=0
```

This chain works through both the strict fake provider and the real Linux C
provider. It is not yet selected by pressure or router authority. The remaining
route suite is intentionally red.

## 2. Implemented Boundaries

### 2.1 Actor-owned trace

`core/packet.lua` now recognizes:

```text
repository_effect_attempt  -> ☶ only
repository_effect_receipt  -> ☶ only
repository_verification    -> ☶ only
work_completion            -> ☱ only
```

`runtime/body.lua` provides closed-schema writers. It validates before and
after detachment, stores deep copies, increments `revisions.evidence` only for
verification and `revisions.history` only for completion. Trace remains the
only completion ledger.

### 2.2 One-use private authority

`runtime/repository_capability.lua` now consumes one generation-scoped dispatch
slot in `begin_effect`. The returned lease contains no public path, provider,
root handle or grant record. Trusted closures permit only:

```text
one create for the action target
one read-back for the same target at expected_bytes + 1
```

The slot is consumed before provider entry and is never refunded. The same
action cannot acquire another lease. Ambiguous mutation residue quarantines and
closes the grant before another call can enter the provider.

### 2.3 Exact effect transaction

`runtime/repository_effect.lua`:

```text
revalidates and materializes the current action
writes attempt before external mutation
validates exact provider records and economics
writes receipt without claiming completion
consumes read bytes transiently into length/SHA-256
writes accepted/rejected bounded verification
returns detached cost and causal refs
```

Unknown trusted keys, impossible identities and malformed records are loud
errors. Well-formed world denials are `effect_failure`. A well-formed observed
mismatch is rejected evidence rather than failure or success.

### 2.4 LOGIC and RUNTIME ownership

`organs/logic.lua` has an explicit direct repository branch. It ignores legacy
spells, invokes the trusted transaction from an exact action plus host registry,
and records the accepted/rejected LOGIC validation.

`runtime/work_completion.lua` requires a current ☱ lease and derives completion
from the immutable chain:

```text
current unit/version and formation
attempt < receipt < verification < accepted validation
same action/grant/work identities
accepted exact verification
no later conflicting effect record
no prior exact completion
```

`body.progress` ignores legacy mutable status for repository work and reads only
an exact current-version completion event.

## 3. Measured Evidence

### 3.1 Focused Lua contracts

```text
repository-effect:  14 green / 0 red
repository-progress: 9 green / 0 red
```

The progress set includes two controls added after implementation self-audit:

```text
derive/record TOCTOU: a later effect attempt invalidates an old candidate
selected alternative: formation version 1 remains history for selected version 2
```

### 3.2 Real provider integration

`tests/test_repository_effect_linux.lua` grows an identity-owned repository
under `/tmp`, then runs the complete direct chain through the production loader
and C provider:

```text
REAL0 native provider grows exact effect and completion: green
verification status: accepted
effect cost: tool_calls=2, file_writes=1
body progress: needed=1, done=1, remaining=0
fixture cleanup: identity-guarded and successful
```

No project file or arbitrary host path is used as a test target.

### 3.3 Staged hand corpus

```text
lua tests/red_repository_hands.lua
green=11 red=1 total=12
```

The sole red suite is `tests.test_repository_route`:

```text
route controls inside that suite: 5 green / 5 red
```

Its red cases require automatic `☵ -> ☱ -> ☶ -> ☱` or
`☵ -> ☳ -> ☶ -> ☱` lives. Step 7.7 explicitly forbids that authority, so this
is the intended frontier rather than an implementation failure.

### 3.4 Regression and native checks

```text
lua tests/run.lua: 80/80 registered suites, all tests ok
native full create/read/fault battery: green
strict -Wall -Wextra -Werror builds: green
GCC -fanalyzer production source: green
GCC -fanalyzer native test build: green
ASan + UBSan complete native battery: green with leak detection disabled
```

LeakSanitizer remains outside the accepted claim because the surrounding ptrace
boundary was already shown to prevent it. Descriptor and close/GC controls stay
green.

## 4. Security Properties Observed

```text
position at ☶ alone causes no write
attempt exists before every entered writer call
revoked capability calls the provider zero times
one action reaches create/read at most once
ambiguous cleanup quarantines the grant before retry
read-back path and bound come only from the same action
public effect events contain no raw content or absolute host path
returned outcome/completion mutation cannot alter stored trace
provider denial preserves actual cost
effect execution creates no identity loss
verification without ☱ remains pending
work A or an old version cannot complete work B/current version
reconciliation cannot duplicate completion
malformed trusted data remains a harness error, not honest packet death
```

## 5. Correction Found During Implementation

The B6 leakage control uses a fake provider that deliberately returns foreign
bytes longer than the action expectation. The first effect implementation
treated this as a second upper-layer hard-bound violation and failed loudly.

The corrected separation is:

```text
native provider/adapter owns the hard read and allocation bound
LOGIC owns exact expected length and digest comparison
```

Production provider tests already prove `expected+1` enforcement. The effect
layer now treats any well-formed observed bytes delivered by its trusted
provider as transient evidence, rejects the mismatch and proves that no raw
bytes enter trace. Unknown fields and malformed shapes remain loud.

## 6. What Is Still Absent

```text
qualified repository pressure readers
RUNTIME action-review dispatch
automatic LOGIC effect dispatch from a committed route
automatic RUNTIME reconcile dispatch
central runner charging of returned effect cost
route/ablation promotion
manifest projection of the first hand
multi-file scheduling, overwrite, patch, mkdir, commands and tests
```

The direct LOGIC and completion APIs are physical mechanisms, not hidden router
authority. The normal body still cannot decide to use them.

## 7. Next Gate

Roadmap 7.8 attacks the demonstrated boundary rather than widening it. At
minimum it must audit:

```text
lease replay and cross-registry substitution
grant exhaustion/quarantine/revocation transitions
provider exceptions and malformed error records
root replacement between action, create and read
all native fault stages and ambiguous residues
event schema aliasing and cyclic/metatable inputs
candidate staleness and conflicting evidence order
public trace leakage under hostile returned bytes
resource/descriptor cleanup over repeated lives
```

Only a green hostile audit may authorize promotion of effect/progress suites and
later route integration.
