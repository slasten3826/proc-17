# QA Body Transaction M2 Body Join Manifest v0

Status:

```text
layer: manifest
date: 2026-07-29
slice: M2.3 body adapter + M2.4 strict receipt/body join
Packet check/failure authority: implemented
runner QA tick/economics: closed
deterministic candidate verdict: closed
QA control matrix: 67 green / 17 red / 0 skip
```

## 1. Manifested Boundary

One sealed build Packet at the current LOGIC tick can now execute this exact
causal chain:

```text
sealed and aligned candidate
  -> exact qa.check_request.v0 in Packet trace
  -> private grant and sticky begin
  -> request-causal source reservation
  -> shared RUN v1 candidate transaction
  -> private normalized report or provider error
  -> immutable qa.execution_receipt.v1
  -> strict receipt/result/current-Packet join
  -> exactly one qa.check.v0 OR qa.execution_failure.v0
```

The production path is `runtime/qa_execution.lua`. It accepts only the private
QA registry plus the detached measured-environment projection. Repository and
environment registries, providers, source handles and leases remain reachable
only inside private callbacks.

## 2. Sole Body Writers

`core/qa_evidence_schema.lua` now owns exact normalization and identities for:

```text
qa.check_request.v0
qa.check.v0
qa.execution_failure.v0
```

`qa.check.v0` is revalidated through the existing strict RUN v1 process schema;
it does not accept a weaker cleanup alias, v0 witness, command-shaped request or
physical provider identity. All eight finality facts must be true.

The only legal append paths are:

```text
qa_evidence.record_request
  -> body.record_qa_request
  -> packet.append_qa_event

qa_evidence.commit_execution
  -> body.record_qa_check | body.record_qa_execution_failure
  -> packet.append_qa_event
```

Every writer normalizes before copy, deep-copies, revalidates after copy and
lets the Packet gate advance `revisions.evidence` exactly once. Generic trace
append remains denied.

## 3. Strict Receipt Join

The body never accepts a caller-supplied report, error or detached receipt as
truth. `qa_evidence.commit_execution` enters through
`qa_capability.with_receipt` and proves together:

```text
receipt identity and committed state
private normalized-result digest
current request event and request re-derivation
Packet, lineage, generation, process, context, stage and repository
seal, alignment, QA contract, check, profile and environment
result/source/transaction disposition
absence of a contradictory current body outcome
```

Candidate reports become accepted or rejected checks. Provider/source/finality
failures become one execution-failure event plus the existing typed
`effect_failure` projection. Trusted contradictions remain loud and invent no
Packet death or honest failure record.

Receipt commit intentionally precedes body append. If append fails, the next
attempt observes `receipt + no body outcome` and fails loudly without running
the candidate again. Exact replay returns the stored body outcome and receipt
without append, provider entry or cost.

## 4. Physical Distinctions Preserved

The grown corpus confirms:

```text
expected exit 0        -> accepted qa.check
contained nonzero      -> rejected qa.check
contained wall timeout -> rejected qa.check
supervisor unavailable -> qa.execution_failure
source drift           -> quarantined qa.execution_failure
cleanup ambiguity      -> ambiguous qa.execution_failure
malformed trusted result -> loud, no body outcome
alignment drift after receipt -> loud, no body outcome
```

Contained candidate failure is therefore not infrastructure failure. Source or
cleanup uncertainty is not candidate truth.

## 5. Economics Boundary

The check/failure event records the admitted physical projection:

```text
tool_calls
test_runs
time_ms
```

This slice does not debit the Packet. Receipt, evidence append and replay never
charge. M2.5 must add one runner-owned `qa_execution` tick that validates and
debits the projection once; typed execution failure then enters the existing
runner `effect_failure` death path. Until that slice, direct grown execution is
an integration surface, not routed body physics.

## 6. Verification

```text
qa-request-body        8 green / 0 red
qa-capability-body     6 green / 0 red
qa-capability-receipt  4 green / 0 red
qa-body-join           9 green / 0 red
QA expected-red matrix 67 green / 17 red / 0 skip
ordinary suite         all tests ok
mortality              8/8
QN20 residue campaign  32/32 matched
QN20 residue axes      all zero
git diff --check       clean
```

The expected-red movement is:

```text
before M2.3/M2.4: 45 green / 39 red
after M2.3/M2.4:  67 green / 17 red
```

No verdict, terminal QA projection, descendant QA history or router promotion
became green by implication.

## 7. Next Slice

```text
M2.5 one runner-owned QA execution action and one-time budget debit
M3   deterministic candidate verdict and work-layer projection
M4   terminal rejected-generation projection, corpse and lineage transport
```

M2.5 must reuse this exact adapter and strict join. It must not add a second
provider engine, direct command surface, alternate evidence writer or hidden
charge path.
