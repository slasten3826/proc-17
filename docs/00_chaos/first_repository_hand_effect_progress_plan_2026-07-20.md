# First Repository Hand: Effect And Progress Plan

status: CHAOS implementation plan for roadmap step 7.7
date: 2026-07-20
previous: `first_repository_hand_independent_read_results_2026-07-20.md`
authority: engineering hypothesis until the tests below produce runtime evidence

## 1. Purpose

Step 7.7 joins the already proven pieces without granting route authority:

```text
authorized repository action
  -> immutable effect attempt
  -> one private effect lease
  -> exact create provider call
  -> bounded receipt
  -> independent exact-target read-back
  -> bounded verification
  -> accepted LOGIC validation
  -> exact RUNTIME work completion
  -> derived body progress
```

The provider primitives from 7.5 and 7.6 can touch one granted repository. This
step proves that the body can use them once, preserve causality in trace, and
mark only the exact evidenced work version done.

It does not teach the router to choose this path. `repository_route` must remain
red after this step.

## 2. Laws

### 2.1 Deny by default

The private registry is the only owner of provider handles. A public action is
not authority. `begin_effect` must revalidate its exact grant identity and
atomically consume one generation-scoped dispatch slot before returning an
opaque one-use lease.

The lease permits exactly:

```text
one create_text_file call for the action target
one read_text_file call for that same target with max_bytes=expected+1
```

No command, shell, absolute path, arbitrary read or second dispatch exists.

### 2.2 Attempt before mutation

The body must append `repository_effect_attempt` before acquiring the private
lease and before calling the writer. Position at ☶ alone changes no external
state.

### 2.3 Trace is the canonical ledger

Attempt, receipt, verification, LOGIC validation and work completion are
immutable trace events with actor rights. No mutable parallel `action.status`,
effect ledger or completion map becomes another source of truth.

### 2.4 Evidence is narrower than bytes

Raw intended and observed content is transient. Public events may contain:

```text
relative target
byte length
SHA-256
identity and causal refs
bounded economics
```

They must not contain raw content, host paths, provider handles or commands.

### 2.5 Receipt is not completion

A writer receipt only confirms that the body accepted a well-formed writer
report. The exact file predicate is accepted only after a separate read-back.
Even accepted verification is not work completion until ☶ records an accepted
LOGIC validation and a later ☱ reconciles the entire chain.

### 2.6 Failure classes stay separate

```text
well-formed external denial or ambiguity -> typed effect_failure
well-formed read-back mismatch           -> rejected verification
malformed trusted provider data          -> loud invariant error
```

Malformed body/provider contracts must never be disguised as packet death.

### 2.7 Economics and identity are separate

The hand returns actual provider cost. It spends no identity loss. Direct 7.7
execution reports cost but does not charge it itself; centralized runner
charging belongs to the later routed integration.

## 3. One-Use Lease

`runtime.repository_capability.begin_effect(registry, action)` must:

1. resolve the private grant by the action grant id;
2. distinguish revoked/quarantined/missing authority;
3. validate session, lineage, generation, repository, provider, root, policy,
   operation and grant revision against the action;
4. reject a repeated action and an exhausted generation limit;
5. consume the dispatch slot before any provider call;
6. return only opaque closures for exact create and exact read-back;
7. quarantine the grant after an ambiguous provider result.

A consumed slot is never refunded.

## 4. Effect Events

`runtime.repository_effect.execute(instance, action, registry)` requires the
current ☶ actor lease and performs:

```text
materialize current action bytes
append attempt
acquire one-use lease
create exact file
strictly validate writer result
append receipt
read exact same path under expected+1 bound
strictly validate reader result
hash transient bytes
append accepted/rejected verification
return a detached repository.effect_result.v0
```

Repository event writers in `runtime.body` validate closed schemas, use actor
rights in `core.packet`, deep-copy into trace, and increment only the named
revision axes:

```text
repository_verification -> revisions.evidence
work_completion         -> revisions.history
```

## 5. Exact Completion

`runtime.work_completion` derives from trace rather than accepting a caller's
claim. On a current ☱ visit it must prove:

```text
the field unit still exists at the action's exact version
the action still matches that work identity
attempt < receipt < verification < accepted validation
all four events name the same action and causal refs
verification verdict is accepted
validation status is accepted
no later conflicting attempt, verification or validation exists
no exact completion already exists
```

Only then may it append one `runtime.work_completion.v0` event. For repository
work, `body.progress` derives done/pending from these exact events and ignores
the legacy mutable work-unit status.

## 6. Falsifiers

Step 7.7 fails if any of the following is observed:

```text
position at ☶ writes a file
one action reaches the provider twice
revocation or quarantine still permits a provider call
an attempt is absent before a provider denial
a malformed provider record enters trace or becomes honest death
missing/mismatched read-back completes work
raw bytes, host paths or handles enter public repository events
verification alone changes body progress
evidence for work A completes work B
stale evidence completes a newer unit version
reconciliation writes duplicate completion events
returned projections can mutate stored trace
effect/progress implementation changes any route
```

## 7. Test Order

```text
1. tests/test_repository_effect.lua
2. tests/test_repository_progress.lua
3. tests/red_repository_hands.lua
   expected after 7.7: effect/progress green, route red
4. lua tests/run.lua
5. native provider and fault-injection corpus
6. compiler warnings and ASan/UBSan checks
```

The implementation is accepted only if the old full suite stays green and the
remaining red is attributable solely to route authority that this step forbids.

## 8. Expected Result

At the end of 7.7 proc-17 has a deliberately callable first hand:

```text
the body can create one exact file and prove it
the body can derive one exact completed work predicate
the body still cannot decide by itself to route through that hand
```

That separation is the evidence required before adversarial audit (7.8) and
router promotion (7.9).
