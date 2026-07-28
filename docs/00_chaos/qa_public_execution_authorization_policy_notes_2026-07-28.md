# QA Public Execution Authorization Policy Notes

Status:

```text
layer: CHAOS
date: 2026-07-28
scope: future public/multi-user QA execution authorization
runtime implementation authorized by this note: no
current roadmap blocker: no
activation: deferred until proc-17 crosses a public trust boundary
```

Related current contracts:

```text
docs/02_crystall/blueprints/l1_flow_domain_birth.v0.md
docs/02_crystall/blueprints/candidate_seal_transaction.v0.md
docs/02_crystall/blueprints/qa_execution_capability.v0.md
docs/00_chaos/qa_measurement_e4_topology_audit_2026-07-28.md
```

## 1. Decision

Continue implementing the private QA hand now. Do not add a cryptographic
candidate-signing subsystem to the current personal-tool runtime.

The current deployment has one human owner, one local machine and no public
execution API. Its immediate security boundary is:

```text
exact candidate seal
private one-use QA execution capability
private sealed-source lease
native launcher/supervisor identity
namespaces + seccomp + rlimits + bounded scratch
typed STARTED/cause/finality evidence
```

These controls remain mandatory now because even locally generated candidate
code is untrusted. Only the additional public authorization signature is
deferred.

## 2. Future Trigger

Reopen this policy before any of the following becomes true:

```text
another user can submit code or request QA
proc-17 exposes a network or shared-service API
plugins can originate candidate source
QA jobs persist across process/session restart
jobs move between machines or workers
multiple security principals share one installation
an external artifact store feeds candidate roots
```

At that boundary, an in-process private registry is no longer sufficient by
itself. Authorization must survive transport without becoming a copyable
public bearer string.

## 3. L1 Is Provenance, Not Authority

The existing L1 law remains unchanged:

```text
an L1 flow mark proves that one physical L1 birth event occurred;
it does not authorize identity, routing, CONNECT, source access or execution;
the bounded L1 fingerprint may collide and has no security authority.
```

L1 may contribute provenance coordinates to a future signed authorization:

```text
stream_id
stream_epoch
birth_seq
packet birth event ref
```

It must not own the signing key, mint an execution capability or make a
candidate safe. A Packet receives an L1 mark by being born; birth alone cannot
grant permission to execute arbitrary bytes.

## 4. Future Authorization Chain

The intended public chain is:

```text
L1 birth provenance                         no authority
  -> Packet/lineage/generation identity     body identity
  -> exact artifact set                     declared work
  -> candidate seal                         immutable byte/root boundary
  -> body-owned QA request                  explicit intent
  -> private authorization service          sole signing authority
  -> one-use QA execution capability        local runtime authority
  -> one-use sealed-source lease             exact source authority
  -> native supervisor                       isolated execution
```

The signature supplements the existing capability and lease. It does not
replace either one and does not weaken sandboxing for signed code.

## 5. Candidate Authorization Envelope

The exact schema is deferred to a future TABLE round. Its minimum identity set
will need to bind:

```text
authorization protocol and policy revision
authorization id and unique nonce
issuer/key id
session or deployment trust domain
lineage id, Packet id, generation and stage id
L1 birth provenance coordinates
repository/root authority identity
artifact-set identity and candidate-seal identity
exact source inventory/closure identity
QA contract, check, profile and environment identities
resource-limit profile
issuance epoch and bounded expiry/replay window
```

Changing any bound field must invalidate authorization. The signature covers a
canonical binary/structured encoding, never ad hoc concatenated text.

## 6. Writer And Reader

Future named writer:

```text
private execution-authorization service
```

It may sign only after the body-owned QA request and exact candidate seal both
exist. LLM output, candidate code, L1, CLI arguments and copied public ids are
not writers.

Future named reader:

```text
private QA capability registry/native launcher boundary
```

Verification happens before source-lease reservation and before supervisor
creation. Missing, expired, replayed, revoked, malformed or mismatched
authorization produces zero source lease and zero candidate process. It is an
authorization/world failure, not candidate rejection or Packet mortality.

## 7. Cryptographic Direction

Do not choose an algorithm during the current E4 campaign.

Likely deployment choices:

```text
single-host persistent service  -> keyed MAC with protected local key may suffice
multi-host/offline verification -> asymmetric signatures and explicit key ids
```

The eventual TABLE round must define key generation, storage, rotation,
revocation, algorithm agility, canonical encoding and rollback behavior. A raw
SHA-256 digest is not a signature; collision resistance does not prevent copy,
replay or an unauthorized caller asking the signer to bless malicious bytes.

## 8. Signed Code Remains Hostile

A valid authorization proves only:

```text
the authorized body selected these exact sealed bytes for this exact QA run.
```

It does not prove correctness or safety. Signed code still executes under the
same closed native boundary:

```text
read-only exact source
private bounded scratch
no network/process/native-loader authority
separate bounded output
heap/address/CPU/wall/file limits
complete reap and namespace cleanup
no host path/fd/capability exposure
```

Authorization prevents substitution, replay and confused-deputy launches.
Containment limits damage from code that was correctly authorized but remains
malicious or exploitable.

## 9. Required Future Falsifiers

```text
copied authorization id without private record launches nothing
valid signature over another seal/root/generation launches nothing
L1 fingerprint collision grants no identity or execution authority
replay consumes no second source lease or process
expired/revoked key launches nothing
unknown algorithm/key id fails closed
candidate cannot read signing material or mint an authorization
signature-valid hostile code remains contained by the same sandbox
authorization failure creates no candidate outcome
key rotation never silently upgrades historical authorization
```

## 10. Deferral Boundary

This policy creates no E4/E5 work item and no current QA feature bit. It must
not delay streams, allocator, CPU/wall, scratch, RUN v1 or the hostile campaign.

The next active implementation step remains E4.0a: amend the private C status
descriptor contract, then continue C5 measurements. Public signing is a future
deployment-security chapter, not a condition for completing the personal
proc-17 tool.
