# QA Hostile Execution TABLE Cross-Audit

Status:

```text
layer: chaos (cross-table audit evidence + document decision)
date: 2026-07-28
chapter: 8.5.5E
audited owner: qa_hostile_execution_campaign_yellowprint.v0.md
audit result: accepted after in-place corrections
TABLE gate: satisfied
CRYSTALL authorized: exact E surface only
runtime implementation authorized: no
Packet/body QA authority: forbidden
```

## 0. Audited Corpus

Primary source and table:

```text
docs/00_chaos/second_qa_hand_hostile_campaign_notes_2026-07-28.md
docs/01_table/yellowprints/qa_hostile_execution_campaign_yellowprint.v0.md
```

Dependency owners checked at their joins:

```text
qa_contract_profile_yellowprint.v0.md
qa_execution_capability_yellowprint.v0.md
qa_provider_candidate_transaction_yellowprint.v0.md
qa_check_verdict_yellowprint.v0.md
candidate_seal_transaction_yellowprint.v0.md
capability_safe_repository_hands.v0.md
```

Runtime/schema claims checked against:

```text
core/qa_schema.lua
runtime/qa_contract.lua
runtime/qa_process.lua
runtime/qa_provider.lua
runtime/qa_provider_witness.lua
runtime/repository_capability.lua
native/proc17_qa_wire.h
native/proc17_qa_policy.h
native/proc17_qa_launcher.c
native/proc17_qa_supervisor.c
tests/test_qa_native_supervisor.lua
tests/support/qa_control_catalog.lua
tests/support/qa_hostile_fixtures.lua
native/Makefile
```

## 1. Audit Question

```text
Can CRYSTALL transcribe Step E without inventing a candidate cause, widening
the public QA request, confusing infrastructure failure with rejection or
making the hostile harness a second unsafe execution path?
```

Answer after the corrections below:

```text
yes
```

## 2. Closed Causal Chain

```text
exact historical provider-witness eligibility
  -> native RUN v1 request under exact measured environment
  -> private STARTED attestation
  -> one first-cause slot
  -> terminal/reap/EOF/scratch/namespace finality
  -> candidate result OR infrastructure error
  -> strict adapter normalization
  -> pre/post source join and source disposition
  -> detached provider witness/error
  -> trusted QN harness assertion only
```

No Packet record or reader appears in the chain.

## 3. Finding A: Heap Ceiling Ownership

The first table draft placed the existing 64 MiB Lua allocator ceiling into
caller-visible `resource_limits`. That would have silently changed:

```text
qa.resource_limits schema
profile/check identity
qa_contract identity
public request surface
```

Correction applied in place:

```text
runtime_heap_bytes is fixed measured environment/provider policy;
it is not caller-selectable;
the environment protocol/id and policy/build identities rotate;
the existing command-free profile and request authority remain unchanged.
```

The v1 request binds the new exact environment id. Historical contracts do not
upgrade.

## 4. Finding B: Residue Observation Must Be Owned

The first residue draft proposed:

```text
global waitpid(-1, WNOHANG)
full host /proc/self/mountinfo digest
```

Both can observe unrelated host activity and create false red results. They can
also reap a child not owned by the QA transaction.

Correction applied in place:

```text
the launcher-owned pid/pidfd ledger proves one reap per owned child;
mount inspection matches only the unique harness identity;
unrelated processes and mounts are outside the claim.
```

QN20 now proves named-channel residue freedom, not global host stillness.

## 5. Candidate Cause Audit

Each candidate reason has one positive writer:

| Reason | Writer |
|---|---|
| exit forms | kernel wait state |
| wall timeout | trusted monotonic timer first-cause event |
| CPU limit | kernel CPU-limit event/wait state |
| memory limit | bounded Lua allocator denial under measured environment |
| output limit | trusted independent stream drain crossing |
| scratch limit | trusted filesystem/runtime capacity denial |
| policy violation | SIGSYS under exact active seccomp policy |

The table explicitly rejects filename, message and exit-only inference. This
closes the main false-green risk in QN17.

## 6. Fixture Semantics Audit

Two pre-existing fixture names were stronger than their bytes:

```text
candidate-wall-loop
  closed stdin makes io.read(0) a CPU spin, not a blocking wall witness

candidate-sigsys
  checks missing Lua APIs; it does not issue a syscall
```

The table corrects both without editing archaeology:

```text
wall-loop expects cpu_limit in the present profile;
sigsys fixture expects exit 0 when API closure holds;
real seccomp denial remains QN13 evidence.
```

Therefore QN17 cannot become green by trusting labels.

## 7. Protocol Revision Audit

Adding STARTED plus decomposed finality changes native evidence semantics.
Explicit v1 protocols are required and sufficient:

```text
request v1
started v1
result v1
error v1
environment v1
```

No mixed pair is accepted. The exact profile remains v0 because invocation,
entrypoint, stdin, argv and expected-exit semantics do not change. The measured
environment rotates because provider/supervisor policy does.

Provider witness schemas may be revised privately in CRYSTALL where their exact
field set changes. Such a revision remains unavailable to body APIs.

## 8. Start/Finality Audit

The table does not infer `candidate_started=false` from a missing final frame.
It requires positive STARTED evidence and uses tri-state infrastructure facts.

The STARTED writer must sit after:

```text
source staging
environment setup
resource limits
capability drop
seccomp installation
candidate process creation
```

and before candidate chunk execution.

CRYSTALL must provide a private relay from the isolated candidate boundary to
the launcher. Candidate code cannot write, suppress or forge this frame.

## 9. Output And Scratch Audit

The table repairs the current impossible scratch implication:

```text
old: limit_reached -> stored bytes > enforced bound
new: stored bytes <= bound; final capacity state is measured separately
```

A post-terminal full filesystem does not prove which write ended the candidate.
The table therefore keeps the scratch fixture as `unexpected_exit` and reserves
`scratch_limit` until a trusted pre-terminal write-denial hook exists. This is
less expressive and more honest than deriving cause from final fullness.

It also separates stdout and stderr. `hashed_bytes` names the exact prefix
covered by digest; no truncated digest is described as full-stream truth.

These schemas are implementable from the existing trusted namespace parent,
which already owns candidate wait, scratch mount and output pipes, but they are
not yet implemented.

## 10. Trusted Fault Audit

Fault selection is authorized only in distinct test builds. The production
closure must contain no fault key, environment switch, Lua function or exported
symbol.

The test build has a different digest/build identity and must fail the
production loader identity check. This preserves the rule that the harness may
test failure without adding failure authority to candidate data.

Malformed trusted result remains loud. Crashes, lost pipes and incomplete reap
are typed infrastructure only when the launcher has enough trustworthy facts
to describe them. Neither path writes candidate rejection.

## 11. Source-Disposition Join

The Step E table agrees with source-binding v1:

```text
definitive report/error with complete proof -> consumed
source drift or cleanup ambiguity           -> quarantined
trusted contradiction                       -> quarantine/finality attempt, then loud
```

It does not create `qa.execution_receipt.v0`. Repository source finality is not
a body receipt and cannot satisfy QE controls.

## 12. QA Contract Join

No public command surface changes:

```text
one check
tests/run.lua
stdin closed
argv empty
expected exit 0
fixed profile
exact environment id
```

Environment rotation makes old contracts unavailable through the existing
identity law. It does not mutate an old contract or grant a fallback profile.

## 13. Candidate Seal And First-Hand Join

Step E reads but never writes:

```text
candidate seal
root closure
artifact inventory
Packet trace/field/budget/loss
public root projection
```

Every QN17/QN20 candidate uses a fresh disposable root. A sealed source is
never patched or reused for a second transaction.

## 14. Harness Audit

The required topology has one execution path:

```text
fixture bytes -> first hand -> sealed root -> source lease
             -> production launcher/supervisor
```

Ordinary Lua reads inert fixture metadata and invokes fixed targets; it never
loads fixture chunks. Trusted fault instructions enter only test binaries and
never candidate source.

The four Make targets must emit exact exercised counts. A target alias to QN16
or an empty recipe fails HE20.

## 15. Control Coverage

| Chaos pressure | TABLE controls |
|---|---|
| false cause from label/exit | HE05-HE07, HE12-HE13 |
| missing phase/finality | HE01-HE04, HE09 |
| merged/truncated output | HE08-HE09 |
| impossible scratch truth | HE10-HE11 |
| unsafe fault hooks | HE15 |
| infrastructure laundering | HE16-HE18 |
| residue overclaim | HE19 |
| authority/color leakage | HE20-HE22 |

Every CHAOS falsifier has a named TABLE reader.

## 16. Exact Color Delta

Accepted delta:

```text
QN17 red -> green
QN18 red -> green
QN19 red -> green
QN20 red -> green
```

Expected matrix:

```text
before 40 green / 44 red
after  44 green / 40 red
```

No QE/QV/body/completion/tree control changes. QN01-QN16 remain green.

## 17. Required CRYSTALL Owners

CRYSTALL must close these implementation surfaces:

```text
C1 v1 wire frame kinds, sizes and exact codecs
C2 v1 Lua schemas and strict normalizers
C3 measured environment/runtime heap identity rotation
C4 supervisor private start/cause/finality state machine
C5 independent output drains and scratch final observation
C6 launcher multi-frame/reap/EOF state machine
C7 provider witness/error migration and source disposition
C8 production hostile candidate harness
C9 test-only trusted fault and ambiguity harness
C10 repeated residue ledger and exact promotion matrix
```

Representation is a CRYSTALL choice. Authority and cause ownership are not.

## 18. Decision

```text
document_decision:
  qa_hostile_execution_campaign_yellowprint.v0 is accepted after corrections;
  CRYSTALL is authorized for C1-C10 only;
  implementation remains forbidden until the corresponding crystall audit;
  Packet QA/body verdict authority remains forbidden.
```
