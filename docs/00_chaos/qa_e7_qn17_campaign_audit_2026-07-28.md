# QA E7 QN17 Campaign Audit

date: 2026-07-28
status: runtime-confirmed E7 audit
scope: C8 / QN17 only

## 1. Runtime Result

The dedicated campaign executed all 17 candidate fixtures through fresh
first-hand repositories, candidate seal, production RUN v1 and provider witness
v1:

```text
declared=17
executed=17
matched=17
source_drifts=0
cleanup_ambiguities=0
```

Observed classes matched the closed TABLE matrix:

```text
expected exit and API-closure probes      accepted
Lua/nonzero/scratch-capacity failures     unexpected_exit
both spin fixtures                        cpu_limit
allocator exhaustion                      memory_limit + allocator denial
stdout/stderr floods                       output_limit + named stream crossing
```

Every row carried the exact fixture byte count and SHA-256 into the sealed
entrypoint, complete cause/finality records, identical seal/pre/post inventory
ids and terminal `consumed` source disposition.

## 2. False-Green Audit

The campaign has no selector, CLI input, alternate provider, direct load
primitive or QN16 alias. Its expectation matrix does not read fixture
`pressure`. It executes only `class=candidate`; all nine trusted-fault records
remain inert for QN18/QN19.

The report gate rejects unknown fields, retained raw output, content/path/fd/
handle/process-token keys, protocol drift, identity drift, incomplete finality,
wrong truth status, non-v1 measurements and execution cost other than exactly
one QA run.

Static and post-run audits found:

```text
production fault selectors        absent
live QA supervisor/controller     absent
host /qa mount residue            absent
identity-owned temporary roots    absent
direct campaign execution API     absent
```

These observations do not claim QN20 repeated-run residue freedom.

## 3. Defect Found During Promotion

The first red-battery run reported `42 green / 43 red`, not the authorized
`41/43`. QN17 itself was the correct new green. The extra green came from
adding campaign topology as a new QF06 control, which changed the total control
population from 84 to 85.

The repair did not change the expected matrix. QF06 was folded into existing
QF04, strengthening the fixture-reader gate without creating a new counted
institution. The physical matrix then became exactly `41 green / 43 red`.

The red-battery ledger baseline was advanced from `40/44` to `41/43` only after
this exact delta was observed. QN18-QN20 and all body QE/QV controls remain red.

## 4. Promotion Consequence

QN17 is no longer a deferred native control. The ordinary native suite must run
it; only QN18-QN20 retain explicit skips. This makes hostile-candidate
containment part of normal regression rather than an expected-red-only event.

## 5. Non-Claims

E7 does not prove trusted-runtime fault classification, cleanup ambiguity,
32-generation residue freedom, arbitrary-language containment, body QA
evidence/verdict or software acceptance. It introduces no production fault
hook and no Packet authority.

The next boundary is E8/C9 QN18: test-only trusted fault injection with a
distinct build identity and a production-loader rejection proof.
