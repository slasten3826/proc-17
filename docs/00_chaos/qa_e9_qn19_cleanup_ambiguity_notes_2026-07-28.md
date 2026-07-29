# QA E9 QN19 Cleanup Ambiguity Notes

date: 2026-07-28
status: E9.0 runtime diagnosis and E9.1 document decision
scope: C9 / QN19 cleanup ambiguity and source disposition only
checkpoint: `98bc8c5` (`Promote QA RUN v1 through QN18`)

## 1. The Question

QN18 proved that nine trusted-runtime faults do not become candidate outcomes.
QN19 asks the next question:

```text
after a started execution loses one finality witness,
what may the machine still claim, and may that source run again?
```

The governing law is conservative but not vague:

```text
absence of failure evidence is not cleanup evidence;
unknown cleanup is not failed cleanup;
both unknown and failed cleanup forbid source reuse.
```

QN19 is not leak-loop proof. QN20 will inspect repeated process, descriptor,
mount, pidfd, lease and temporary-root residue.

## 2. Current Runtime Evidence

A matched diagnostic grew five exact process-error shapes through
`qa_process.normalize_error_v1`, one fresh sealed source each, and the real
provider-witness source transaction:

```text
terminal_frame_missing          unknown    complete complete -> quarantined
reap_ambiguous                  unknown    unknown  complete -> quarantined
output_observation_incomplete   incomplete complete complete -> quarantined
scratch_observation_incomplete  incomplete complete complete -> quarantined
namespace_cleanup_incomplete    incomplete complete complete -> quarantined
```

Every replay was denied and every process provider was called exactly once.
This proves that the existing disposition policy is conservative for honest
started-error shapes.

It does not prove that the native machine can produce every shape or that an
impossible shape is rejected.

## 3. Runtime-Confirmed Defect: Ambiguity Laundering

`runtime/qa_process.lua` currently validates each error field independently but
does not validate their causal combination. The following impossible record is
accepted:

```text
class                 world
code                  reap_ambiguous
stage                 preflight
candidate_start_state not_started
cleanup_state         complete
launcher_reaped       complete
result_eof            complete
```

The real provider-witness then applies its clean-prestart predicate and writes:

```text
source_disposition = consumed
```

The diagnostic result was:

```text
QN19_IMPOSSIBLE_ACCEPTED|reap_ambiguous|not_started|complete|consumed
```

This is a real contract defect. A cleanup-ambiguity code can be laundered into
a reusable source by pairing it with individually legal but causally impossible
fields. Production currently emits no such tuple, but the trusted adapter
accepts it, so the safety law rests on producer politeness.

## 4. Writer Gap Behind Three Error Codes

The public vocabulary already contains:

```text
output_observation_incomplete
scratch_observation_incomplete
namespace_cleanup_incomplete
```

No production path writes them.

The namespace controller has one success-only 572-byte private report. A stream
drain error, missing stream EOF, incomplete scratch walk, malformed private
measurement or controller failure goes through `goto cleanup`, emits no private
record and exits dirty. The top-level supervisor cannot recover the exact
source-stage or missing witness, so it exits without a terminal frame. The
launcher can then report only `supervisor_crashed`.

`namespace_cleanup_complete` is currently passed as literal `1` after the
top-level collector observed the complete private report and reaped the
controller. The inference is defensible, but it is implicit and cannot be
negated or audited as a named predicate.

Therefore three names exist without a production writer. Making QN19 green by
hand-constructing their Lua tables would repeat the project's writer-without-
reader defect in reverse: readers and tests would agree about facts the body
never emits.

## 5. Named Fact Owners

| Fact | Writer | First reader |
|---|---|---|
| candidate STARTED and source stage | candidate prelude | launcher v1 machine |
| stdout/stderr EOF or observation failure | namespace controller stream observers | private controller terminal assembler |
| scratch observation complete/incomplete | namespace controller scratch observer | private controller terminal assembler |
| candidate/process-tree finality | namespace controller | private controller terminal assembler |
| namespace-controller reap and private-record EOF | top-level supervisor | controller terminal finalizer |
| namespace cleanup derivation | top-level supervisor exact predicate | public ERROR/RESULT assembler |
| top-supervisor reap | launcher | native Lua error projection |
| public result EOF | launcher | native Lua error projection |
| postflight source stability | repository provider witness | source disposition policy |
| source consumed/quarantined | repository capability registry | witness assembler and replay gate |

No actor may write another actor's fact. In particular, the controller cannot
claim namespace cleanup, and the supervisor cannot claim its own later reap or
public result EOF.

## 6. One Private Terminal Record

The success-only controller report must become one mutually exclusive private
terminal record, not a second side-channel:

```text
proc17.qa.controller_terminal.v2
exact bytes: 572
kind: result | error
```

Common fields bind:

```text
identity join
private process token
source-stage summary
controller-owned finality witnesses
```

`result` retains the current reason, termination, cause, measurements and seven
complete internal finality facts.

`error` carries no candidate reason. It contains one controller-owned
infrastructure code, its exact missing finality witness and zeroed fields for
facts it cannot prove. Only these QN19 errors are authorized in v2:

```text
output_observation_incomplete
scratch_observation_incomplete
```

After validating and reaping the controller, the top-level supervisor projects
that private error to public ERROR. It independently derives namespace cleanup.
If that derivation is unavailable, it writes
`namespace_cleanup_incomplete`. A malformed record, identity/token split or
impossible combination remains a loud trusted invariant; it is not converted
to a typed error.

One controller execution writes at most one terminal record. There is no
success record plus error supplement and no mutable private ledger beside it.

## 7. Exact Native Error Topology

One validator owns the causal matrix. The native adapter and provider witness
must both use it; they may not maintain separate lists that can drift.

Clean source reuse is possible only for the exact pre-start family:

```text
supervisor_unavailable | source_staging_failed
candidate_start_state = not_started
cleanup/reap/result EOF = complete
```

Every other closed code is non-reusable regardless of caller-supplied cleanup
words. QN19 requires these exact rows:

| Case | class / code / stage | start | cleanup | reap | EOF | source |
|---|---|---|---|---|---|---|
| terminal missing after STARTED | ambiguous / terminal_frame_missing / postflight | started | unknown | complete | complete | quarantined |
| reap ownership lost after STARTED | ambiguous / reap_ambiguous / cleanup | started | unknown | unknown | complete | quarantined |
| one stream EOF unavailable | ambiguous / output_observation_incomplete / postflight | started | incomplete | complete | complete | quarantined |
| scratch observation unavailable | ambiguous / scratch_observation_incomplete / postflight | started | incomplete | complete | complete | quarantined |
| namespace cleanup unavailable | ambiguous / namespace_cleanup_incomplete / cleanup | started | incomplete | complete | complete | quarantined |
| stable RUN followed by source drift | ambiguous / source_drift / postflight | started | process-derived | process-derived | process-derived | quarantined |

The stream row has two required variants, stdout and stderr. A dirty supervisor
without a typed private terminal remains `supervisor_crashed`; QN19 does not
rename an unknown internal cause.

## 8. Source Disposition Is A Derived Safety Decision

Provider witness must not infer reuse from
`not_started && cleanup_state == complete` alone. It asks the shared topology
validator for one of:

```text
clean_prestart  -> consumed
non_reusable    -> quarantined
invalid         -> quarantine attempt, then loud
```

Source drift always yields `non_reusable` even if the process result itself was
complete. A trusted contradiction attempts quarantine before raising. Once a
source has entered terminal disposition, exact replay launches no second
provider process.

If closing the private source handle fails after the registry has written a
terminal disposition, no witness is emitted and the failure is loud. The
terminal registry state is not rolled back to reusable.

## 9. QN19 Campaign Shape

One parameterless target owns a closed six-case matrix:

```make
qa-supervisor-cleanup-ambiguity-test
```

The campaign joins three layers without pretending they have one writer:

```text
native driver
  -> production collector and private-terminal codecs grow exact host facts

strict Lua normalizer
  -> binds each fact to the current request and rejects impossible tuples

real provider-witness source transaction
  -> writes quarantined, denies replay, emits no candidate witness
```

The join key is a closed driver-owned case id. It is not a production request,
environment variable, candidate source field or public fault API. The existing
fault build remains a distinct identity rejected by production.

Acceptance:

```text
declared=6
executed=6
matched=6
stream_variants=2
candidate_outcomes=0
source_quarantines=6
replays=0
```

## 10. Falsifiers

```text
CA01 an ambiguity code normalizes as clean pre-start
CA02 provider witness consumes any non-reusable topology
CA03 invalid topology returns before quarantine attempt
CA04 output and scratch error names have no production writer
CA05 controller writes both result and error
CA06 controller error claims namespace cleanup
CA07 supervisor error claims its own later reap or result EOF
CA08 missing stream EOF becomes candidate rejection
CA09 scratch ambiguity becomes candidate rejection
CA10 namespace ambiguity becomes candidate rejection
CA11 one quarantined source launches twice
CA12 fault selection enters wire, environment, candidate bytes or production API
CA13 QN19 aliases QN18 or accepts fewer than six cases/two stream variants
CA14 any control other than QN19 changes color
```

## 11. Ordered Implementation

```text
E9.0 runtime diagnosis and laundering reproduction             complete
E9.1 this CHAOS decision                                      complete
E9.2 TABLE/CRYSTALL topology and private-terminal amendment    complete
E9.3 red six-case parameterless campaign                      complete
E9.4 shared topology validator + controller terminal v2 + campaign complete
E9.5 production exclusion, replay and residue audit           complete
E9.6 manifest and exact 42/42 -> 43/41 promotion              complete
```

Red witness captured before E9.4:

```text
QN19_IMPOSSIBLE_ACCEPTED|reap_ambiguous|not_started|complete|consumed
```

At the red stage, the QN19 control required causal-topology rejection before it
attempted the then-absent parameterless native campaign. Thus one red control
named two successive missing layers without entering the ordinary green suite.

Final runtime result:

```text
declared=6 executed=6 matched=6 stream_variants=2
candidate_outcomes=0 source_quarantines=6 replays=0
QA matrix: 43 green / 41 red / 0 skip
```

## 12. Non-Claims

QN19 does not prove repeated residue freedom, universal host cleanup, zero heap
leaks, body-owned QA execution, check evidence, verdict, retry/resume or
software acceptance. QN20 remains the named repeated-run residue campaign.
