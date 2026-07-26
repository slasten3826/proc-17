# QA TABLE Cross-Audit

Status:

```text
layer: chaos / cross-table evidence
date: 2026-07-23
chapter: 8.5 second QA hand
step: 8.5.2
audit kind: internal contract audit before crystallization
runtime authority: none
QA execution authority: none
crystallization disposition: authorized for the exact audited v0 surface
implementation disposition: forbidden until CRYSTALL and hostile red gates
next-stage record: docs/00_chaos/qa_crystall_cross_audit_2026-07-23.md
```

## 0. Audited Surface

Primary source:

```text
docs/00_chaos/second_qa_hand_threat_model_2026-07-23.md
```

New TABLE contracts:

```text
docs/01_table/yellowprints/qa_contract_profile_yellowprint.v0.md
docs/01_table/yellowprints/qa_execution_capability_yellowprint.v0.md
docs/01_table/yellowprints/qa_check_verdict_yellowprint.v0.md
```

Amended readers/boundaries:

```text
docs/01_table/yellowprints/completion_scope_candidate_seal_yellowprint.v0.md
docs/01_table/yellowprints/nested_work_layer_derivation_yellowprint.v0.md
docs/01_table/yellowprints/stage_transition_generation_recovery_yellowprint.v0.md
```

Lower authority checked as dependency:

```text
candidate seal remains terminal
repository source-write grants remain closed after seal
tree effect_failure remains typed Packet mortality
Packet/corpse subject ceiling remains below lineage software acceptance
△ remains the only terminal manifest writer
```

This is not an independent implementation audit. It is the named TABLE gate
that checks whether the contracts are internally implementable without asking
CRYSTALL or code to invent policy.

## 1. Result

```text
TABLE chain: closed
unowned records: none found after amendments
unnamed readers: none found after amendments
command-shaped public authority: absent
accepted/rejected asymmetry: removed
candidate/infrastructure/invariant conflation: removed
private/body split-brain law: present
cross-generation reuse path: denied
runtime implementation: still unauthorized
```

The three new TABLE contracts are ready to crystallize as one dependency
cluster. None is safe to crystallize in isolation because their boundaries are
defined by the joins between them.

## 2. Findings Produced By This Audit

The audit was not a ceremonial pass. It found and repaired these contract
defects before crystallization.

### A1. Accepted checks skipped final verdict assembly

Old reader behavior:

```text
accepted check -> qa_accepted / build ▲
rejected check -> build ◈ -> final verdict -> build ▲
```

This gave success a shorter evidence path than failure and let one observation
stand in for a deterministic candidate verdict.

Disposition:

```text
accepted check -> qa_acceptance_observed / build ◈ -> ☱ verdict -> build ▲
rejected check -> qa_rejection_observed / build ◈ -> ☱ verdict -> build ▲
```

Both branches now use the same body law.

### A2. Provider infrastructure error lacked request identity

The first `qa.provider_error.v0` sketch had class/stage/cost but no request,
profile or environment coordinates. It could not be joined safely to a body
attempt.

Disposition:

```text
provider errors bind operation + request_id + profile_id + environment_id
foreign/mismatched error -> strict rejection/quarantine
```

### A3. Private execution receipt was named but unspecified

Body evidence referred to a private receipt whose identity and contents had no
contract. CRYSTALL would have had to invent the authority join.

Disposition:

```text
qa.execution_receipt.v0 defined
binds request event, grant, all candidate coordinates, result digest,
transaction disposition and actual cost
private authority remains private; body sees a detached audit id only
```

### A4. QA request was pure data without an exact body event

A detached request could have been supplied to the private resolver without a
body-owned causal point.

Disposition:

```text
prepare request purely
append one qa_check_request event under ☶
only then consume a private lease against request_id + request_ref
append failure -> no process
```

### A5. Stage contract persistence conflicted with environment replacement

Two valid laws were initially incompatible:

```text
same-stage recovery preserves qa_contract_id
environment/toolchain change creates a new qa_contract_id
```

Disposition:

```text
an active stage never silently changes environment
same-stage recovery preserves old contract/environment identity
if that environment disappears, QA is typed not_ready
new environment requires explicit future stage/lineage policy revision
```

### A6. Infrastructure error code was free prose

`code=string` would have created an unbounded command/interpretation channel in
the body and forced readers to classify error text.

Disposition:

```text
closed qa_provider_error_code_v0 vocabulary
unknown code = malformed trusted output = loud invariant
```

### A7. Exact environment omitted parts of the execution closure

Adapter and Lua identities alone did not bind the native supervisor, dependency
closure, machine/kernel identity or actual isolation feature set.

Disposition:

```text
environment_id now binds provider, supervisor, runtime closure, architecture,
kernel identity, isolation features/policy and hard limits
```

### A8. Older work-layer schema and row references had drifted

The schema named `crystallizing_failure` while the live row used
`crystallizing_verdict`; insertion of new rows also made one explanatory
sentence point at the wrong priorities.

Disposition: normalized to `crystallizing_verdict` and corrected row refs.

## 3. One Causal Chain

| Phase | Record/state | Writer | First reader | Authority ceiling |
|---|---|---|---|---|
| policy | `qa.contract.v0` | trusted host birth or accepted lineage stage transition | Packet birth/eligibility | names required bounded check; cannot execute |
| environment | `qa.environment.v0` projection | trusted private registry projector | contract binder/grant resolver | describes exact registered world; id grants nothing |
| request | `qa.check_request.v0` event | ☶ body request writer | private grant/dispatch resolver | asks one committed question; no process authority |
| grant | `qa.execution_grant.v0` | private capability registry | exact request resolver | one Packet/seal/check/environment only |
| transaction | private one-use lease | grant begin operation | trusted provider adapter | one candidate process transaction |
| physical result | provider report/error | trusted supervisor + strict adapter | receipt writer/body evidence writer | reports execution/world fact only |
| private commit | `qa.execution_receipt.v0` | private registry | idempotence + ☶ body writer | proves one private transaction disposition |
| body observation | `qa.check.v0` | ☶ strict body writer | ☱ verdict assembler | accepted/rejected check only |
| body world failure | `qa.execution_failure.v0` | ☶ strict body writer | tree effect-failure path | no candidate classification |
| body verdict | `qa.candidate_verdict.v0` | ☱ deterministic assembler | completion/work-layer/△ | current contract satisfaction only |
| terminal projection | Packet manifest | △ | corpse/lineage/corpus | preserves exact boundary; no lineage decision |
| software decision | lineage assessment | lineage body | corpus/delivery | may write software acceptance |

No substrate actor appears in an authority-writer column.

## 4. Identity Join Matrix

Every execution/check/verdict join must agree on:

```text
Packet id
lineage id
generation
process contract id
semantic context
stage id
repository id
candidate seal id and event ref
current artifact-alignment id
QA contract id
required check id
profile id
environment id
request id and body request ref
private execution receipt id where applicable
```

Additional identity laws:

```text
public ids carry no private authority
every canonical id hashes every content field except itself
ordered sets are normalized before hashing
same-stage recovery preserves contract identity
new generation never reuses ancestor repository/seal/check authority
historical checks remain history but cannot advance a descendant
detached return mutation cannot alter stored body/private state
```

## 5. Outcome Separation

| Outcome | Positive evidence | Body record | Verdict? | Terminal behavior |
|---|---|---|---|---|
| denied/not ready | seal/contract/profile/alignment gate absent | none | no | no provider call/death/cost |
| candidate accepted | clean contained exit 0 and exact postconditions | accepted `qa.check.v0` | yes, after ☱ | accepted boundary after verdict |
| candidate rejected | clean contained non-success/limit/policy consequence | rejected `qa.check.v0` | yes, after ☱ | rejected-generation boundary after verdict |
| infrastructure failure | trusted error with incomplete world/supervision proof | `qa.execution_failure.v0` | never | existing `effect_failure` Packet death |
| trusted invariant failure | impossible/malformed trusted identities or measurements | none | never | harness loud; no honest Packet outcome |

Critical matched pair:

```text
watchdog timeout + complete containment/reap/postflight
  -> candidate rejected check

watchdog/supervision timeout + cleanup or postflight ambiguity
  -> infrastructure failure, no check
```

The classification follows evidence, not error text.

## 6. Work-Layer And Scope Consistency

| Exact current body evidence | Candidate state | Glyph | Boundary candidate |
|---|---|---|---|
| seal, no QA result | `sealed` | `⊞` | none |
| accepted check, no verdict | `qa_acceptance_observed` | `◈` | none |
| rejected check, no verdict | `qa_rejection_observed` | `◈` | none |
| infrastructure failure | `qa_infrastructure_incomplete` | `⊞` before effect death | none |
| final accepted verdict | `qa_accepted` | `▲` | `software_acceptance_ready` |
| final rejected verdict | `qa_rejected` | `▲` | `rejected_generation_recovery_ready` |
| post-seal body divergence | historical seal + diverged alignment | `⊞` | none |

`▲` remains a Packet-local terminal candidate, never `software_accepted`.
Lineage acceptance still requires △, corpse and a lineage-owned assessment.

## 7. QB1-QB12 Disposition

| Blocker | Disposition | Contract location |
|---|---|---|
| QB1 QA contract provenance | closed: trusted birth/lineage writer, stage immutable | contract/profile §§2-4, 11 |
| QB2 sandbox primitive set | closed as mandatory Linux property set, no fallback | execution §§8-12 |
| QB3 legacy command path | closed by exclusion; `io.popen` path cannot be provider | execution §2 |
| QB4 supervisor/toolchain identity | closed by exact private loader and environment closure | contract/profile §§6-7; execution §§3-4 |
| QB5 source view | closed by exact no-follow preflight + direct read-only namespace + postflight | execution §8 |
| QB6 scratch/cache | closed by private bounded tmpfs and fixed redirects | contract/profile §9; execution §9 |
| QB7 process/resource enforcement | closed as mandatory namespaces/seccomp/rlimits/watchdog/reap | execution §§10-12 |
| QB8 result taxonomy | closed with three body/trusted classes | check/verdict §§5-7, 18 |
| QB9 check/verdict schemas | closed for one-check v0 | check/verdict §§4, 6, 10 |
| QB10 environment identity | closed by full closure identity | contract/profile §7 |
| QB11 pre/post source evidence | closed; source drift never candidate result | execution §8 |
| QB12 hostile harness | controls specified; implementation remains gate 8.5.4 | execution §19; check/verdict §19 |

QB12 is contractually treated, not yet experimentally satisfied. That is why
QA execution remains unauthorized.

## 8. Chaos Q1-Q16 Disposition

| Question | Decision |
|---|---|
| Q1 writer | explicit trusted host for build-only; accepted lineage stage policy for software.create |
| Q2 immutable point | target build Packet birth; stage-level across recovery |
| Q3 first profile | exact `qa.profile.lua54_test_suite.v0` under registered Linux environment |
| Q4 isolation | user/mount/PID/net/IPC/UTS isolation, no_new_privs, syscall policy, rlimits, watchdog, no fallback |
| Q5 source | direct exact sealed root, read-only, exact pre/post inventory |
| Q6 scratch | private bounded noexec tmpfs; fixed HOME/TMPDIR; no source cache |
| Q7 request | ids, exact entrypoint artifact and fixed limits only; no command fields |
| Q8 measurements | clean candidate report vs provider error vs loud invariant |
| Q9 timeout/signal/OOM/policy | rejection only with proved containment/postflight; otherwise infrastructure |
| Q10 scheduling | exactly one required aggregate check; no skipped tail |
| Q11 output | counts/digests/limit flags only; no raw bytes in v0 body |
| Q12 identity/idempotence | request event + one-use lease + private receipt + canonical body ids |
| Q13 verdict | exact complete current seal/alignment/contract/check/profile/environment join |
| Q14 economics | one actual QA effect charge; no automatic identity loss; replay free of duplicate effect cost |
| Q15 private lifecycle | environment/grant/lease/receipt states and readers named |
| Q16 hostile controls | native, malicious-process, fault, split-brain and environment cases enumerated |

## 9. False-Green Controls

The following must never become acceptance:

```text
candidate prints "passed"
substrate says tests pass
exit zero without exact request/receipt/source stability/cleanup
accepted check without final verdict
final verdict for another seal/generation/environment
accepted verdict after body alignment diverged
infrastructure error normalized as rejected check
provider report supplied directly by caller
body check with no private receipt
historical ancestor QA attached to child
```

## 10. False-Red Controls

The following must remain honest candidate evidence rather than harness/world
failure:

```text
nonzero exit under complete containment
candidate crash/signal under complete containment
proved timeout/resource/output/scratch limit
proved sandbox-policy violation
rejected check awaiting deterministic verdict
```

The following may block acceptance without rewriting historical truth:

```text
old stage environment becomes unavailable
Packet dies after an accepted check but before verdict
lineage budget cannot afford recovery after rejected terminal generation
```

## 11. Claim Ceiling And Residual Risk

Accepted v0 limitations:

```text
Linux only
one aggregate Lua 5.4 test-suite profile
one process and no network/native modules
candidate source is read-only; scratch is private and disposable
no raw QA diagnostics enter body, prompt, corpse or carrier
same-authority transient host mutation between observations remains excluded
kernel and trusted supervisor remain in the TCB
candidate-authored tests may be semantically weak
passing proves only the declared QA contract, not universal correctness
environment replacement can block an old stage
no automatic infrastructure retry
```

The absence of raw diagnostics means a rejected descendant initially inherits
mechanical reason/measurements, not a rich failure explanation. That reduces
repair quality but prevents untrusted process output from becoming prompt
authority before a separate ingestion contract exists.

These are explicit v0 ceilings, not hidden implementation gaps.

## 12. Crystallization Readiness

| Crystall | Readiness |
|---|---|
| `qa_contract_profile.v0` | ready |
| `qa_execution_capability.v0` | ready, but native syscall/ABI details must be exact and may not weaken mandatory properties |
| `qa_check_verdict.v0` | ready |
| completion-scope QA amendment | ready |
| work-layer QA amendment | ready |
| stage-transition QA amendment | ready |

CRYSTALL may refine representation and exact syscall ordering. It may not:

```text
add a command-shaped public API
weaken Linux isolation or add a fallback
merge candidate rejection with infrastructure/invariant failure
skip the accepted verdict assembly phase
make private ids sufficient authority
retain raw output in body evidence
resume QA against an ancestor sealed root
grant source writes after seal
let Packet-local evidence write software_accepted
```

## 13. Decision

```text
Step 8.5.2 is complete.

The exact three-contract TABLE cluster and amendments audited here are
authorized to enter CRYSTALL step 8.5.3.

No QA runtime, provider, native supervisor, router pressure or host execution
is authorized by this decision.

Before implementation, step 8.5.4 must first turn the permanent controls into
a hostile red battery whose dangerous fixtures cannot run outside the future
isolated provider.
```

## 14. Next Chapter Position

```text
8.5.1 Chaos threat model                                    complete
8.5.2 TABLE contract/profile/capability/check/verdict        complete
8.5.3 CRYSTALL exact schemas and authority                   next
8.5.4 hostile red battery                                   blocked by 8.5.3
8.5.5 minimal isolated QA hand                              blocked by 8.5.4 red
8.5.6 completion/work-layer/manifest readers                blocked by 8.5.5
8.5.7 grown accepted/rejected/infrastructure-error lives     blocked by 8.5.6
```
