# QA Body Transaction M2 Private Receipt Manifest v0

Status:

```text
layer: manifest
date: 2026-07-29
slice: M2.1 request fact + M2.2 private authority and receipt
Packet outcome authority: closed
router/pressure authority: unchanged
QA control matrix: 45 green / 39 red / 0 skip
```

## 1. Manifested Boundary

One sealed build Packet can now grow this causal prefix:

```text
current candidate + measured environment
  -> exact qa.check_request.v0
  -> dedicated ☶ qa_check_request event
  -> private active grant
  -> sticky running transaction
  -> request-causal physical ids
  -> shared M1 candidate transaction
  -> exact private report or provider error
  -> immutable private execution receipt
```

The prefix ends at the private receipt. No `qa_check`,
`qa_execution_failure`, verdict, terminal projection or descendant QA history
is produced by this slice.

## 2. Sole Request Writer

`core/qa_evidence_schema.lua` is the one pure request schema. Both
`runtime/qa_request.lua` and the dedicated Packet/body gate reuse it.

The only legal body path is:

```text
runtime.qa_evidence.record_request
  -> runtime.body.record_qa_request
  -> core.packet.append_qa_event
```

Generic trace append is denied. The gate fixes actor `☶`, runtime truth and
zero event cost, deep-copies the payload, revalidates it after copy and moves
`revisions.evidence` exactly once. Exact replay returns the existing event.
Foreign coordinates, wrong actor, changed digest, corrupt stored envelope and
a dead Packet all fail without replacement or latest-wins repair.

## 3. Private Authority

`runtime/qa_capability.lua` now owns the body execution state machine:

```text
absent -> active -> running -> completed | consumed_failed | quarantined
```

Mint requires the exact living Packet, current request event, sealed root,
candidate closure and measured-environment lease. It launches and reserves
nothing. Begin validates that lease and consumes replay authority before any
source/provider boundary. There is no running-to-active transition.

The body physical transaction id is independently derived by the QA registry
and verified by the body branch of
`repository.qa_source_binding.v1`. A provider-witness seed, arbitrary id or
detached grant cannot satisfy it.

Private callbacks reject leaked registries, leases, providers, handles,
metatables, cycles and forbidden authority-shaped fields.

## 4. Private Result And Receipt

`runtime/qa_private_result.lua` revalidates candidate reports by reconstructing
their exact RUN v1 evidence and calling the existing `qa_process` normalizer.
Provider errors retain the closed native topology; source preflight/drift and
not-acquired remain separate closed body cases.

The QA registry commits the exact normalized result before any Packet outcome
writer exists. Public lookup exposes only the detached receipt. The result is
available only through `with_receipt`, whose output is detached again.

Runtime-grown tests prove:

```text
expected exit 0       -> private accepted report -> completed receipt
nonzero exit          -> private rejected report -> completed receipt
supervisor unavailable -> private provider error -> consumed_failed receipt
```

Accepted and rejected candidates therefore remain symmetric physical results;
infrastructure remains outside candidate truth.

## 5. Verification

```text
qa-request-body       8 green / 0 red
qa-capability-body    6 green / 0 red
qa-capability-receipt 4 green / 0 red
full ordinary suite   111 test module markers, all tests ok
mortality             8/8
QN20 residue campaign 32/32 matched, every residue axis zero
git diff --check      clean
surviving QA process  none
```

The expected-red movement is exactly one control:

```text
QV05 malformed trusted QA event is rejected by the dedicated Packet gate
before: 44 green / 40 red / 0 skip
after:  45 green / 39 red / 0 skip
```

No execution/check/verdict control became green merely because the private
machine exists.

## 6. Next Slice

The next implementation boundary is not another provider engine. It is the
body adapter and strict reader chain:

```text
M2.3 runtime/qa_execution.lua orchestrates the existing private machine
M2.4 receipt + private result -> exact ☶ check OR execution failure
M2.5 ☶ integration and runner-owned one-time external-cost debit
```

Until M2.4, a private receipt is deliberately not Packet truth. Until M2.5,
the ordinary runner has no QA execution action and no QA budget debit.
