# Second QA Hand Hostile Campaign Notes

Status:

```text
layer: CHAOS
date: 2026-07-28
chapter: 8.5.5E hostile/fault/resource/leak campaign
reasoning tier: Ultra
runtime implementation authorized by this note: no
Packet QA authority: forbidden
body check/verdict authority: forbidden
current expected-red frontier: QN17-QN20
```

Primary inherited evidence:

```text
docs/00_chaos/second_qa_hand_threat_model_2026-07-23.md
docs/00_chaos/second_qa_hand_provider_witness_results_2026-07-26.md
docs/00_chaos/autonomous_plan_build_false_acceptance_qa_handoff_2026-07-27.md
docs/01_table/yellowprints/qa_provider_candidate_transaction_yellowprint.v0.md
docs/02_crystall/blueprints/qa_provider_candidate_transaction.v0.md
```

## 0. Mission

Step D proved that one exact sealed source can enter the production supervisor,
execute one silent clean or Lua-error fixture and return a detached provider
witness without changing Packet physics.

Step E asks a narrower question than body QA:

```text
Can that provider boundary classify hostile candidate behavior, trusted
transport failure, cleanup ambiguity and repeated-run residue without ever
turning lost proof into candidate rejection or acceptance?
```

The campaign owns exactly four expected-red controls:

```text
QN17 hostile candidate fixtures remain contained
QN18 trusted crashes and pipe faults remain infrastructure
QN19 cleanup ambiguity never becomes candidate rejection
QN20 repeated transactions leave no named host residue
```

It does not implement `runtime.qa_execution`, `runtime.qa_evidence`,
`runtime.qa_verdict`, a Packet writer or a router reader.

## 1. Cold Baseline

Observed on 2026-07-27/28 before this document:

```text
lua tests/run.lua
  -> all tests ok

lua tests/smoke_mortality_battery.lua
  -> 8/8

lua tests/test_qa_provider_witness.lua
  -> 3 green / 0 red / 0 skip

lua tests/test_qa_native_supervisor.lua
  -> QN01-QN16 green
  -> QN17-QN20 explicit deferred skips

lua tests/red_qa_hand.lua
  -> expected exit 1
  -> exact matrix 40 green / 44 red / 0 skip
  -> QN17-QN20 red because their Make targets do not exist
```

The red controls are not known bad classifications. They are absent exercised
classifications. No implementation may turn them green by adding empty targets
or replaying QN16.

## 2. Existing Physical Surface

The current wire already names candidate reasons:

```text
expected_exit
unexpected_exit
signal
wall_timeout
cpu_limit
memory_limit
output_limit
scratch_limit
sandbox_policy_violation
```

But the exercised implementation accepts only:

```text
exit 0  -> expected_exit
exit 70 -> unexpected_exit
```

The launcher currently rejects any RUN result that is not one of those two
exit forms. The supervisor also collapses most namespace/candidate outcomes
into one outer exit status and emits zero stream/scratch measurements.

Therefore the enum is not evidence. Step E must grow named witnesses before a
reason can become runtime-confirmed.

## 3. Governing Separation

The campaign uses this three-way law:

```text
candidate outcome
  candidate started;
  exact source staging is proven;
  exact terminal cause is observed;
  complete output/scratch observation is available;
  the whole process tree is reaped;
  sandbox cleanup is proven complete;
  higher provider pre/post source evidence remains exact.

infrastructure failure
  the trusted world cannot complete one or more of those proofs;
  the failure is represented by a closed typed error;
  no accepted/rejected candidate witness exists.

trusted invariant failure
  malformed or contradictory trusted state crosses a boundary that should be
  impossible after validation;
  source authority is terminalized or quarantined first where possible;
  the harness fails loudly;
  no honest Packet death or candidate verdict is manufactured.
```

Candidate blame requires positive proof. Missing evidence never means false,
clean or rejected.

## 4. One Result Needs Several Finality Witnesses

The scalar `cleanup_complete` is too coarse for Step E. A definitive candidate
observation requires all of these independently named facts:

```text
source_staging_complete
candidate_start_state = started
candidate_terminal_observed
process_tree_reaped
stdout_eof_observed
stderr_eof_observed
scratch_observation_complete
namespace_cleanup_complete
```

Infrastructure errors need tri-state facts rather than lying booleans:

```text
candidate_start_state = not_started | started | unknown
cleanup_state         = complete | incomplete | unknown
source_stability      = stable | drifted | unknown
```

No final candidate report may contain `unknown`.

## 5. Resource Witness Law

### 5.1 CPU

`cpu_limit` requires a kernel-owned termination/rusage witness that is
distinguishable from the supervisor wall timer. Exit text and elapsed time are
not sufficient.

### 5.2 Wall

`wall_timeout` requires the trusted monotonic timer to fire first, followed by
whole-tree kill and successful reap. A generic SIGKILL is insufficient.

### 5.3 Memory

The restricted Lua runtime already uses a trusted bounded allocator, but its
64 MiB ceiling is not part of the public QA limit contract and it does not
currently export a denial witness.

Step E must either:

```text
bind the runtime heap ceiling into environment/profile identity and export a
trusted allocator-denial fact;
```

or refuse to call allocator failure `memory_limit`.

RLIMIT_AS plus exit 70 does not prove why Lua failed.

### 5.4 Output

stdout and stderr require independent nonblocking drains. The supervisor owns:

```text
total observed byte count
bounded hashed byte count and digest
limit crossing fact
EOF fact
which stream crossed first, if relevant
```

The parent may kill after a limit crossing, but it must continue bounded drain
and reap before returning `output_limit`. Raw bytes never cross the provider
firewall.

### 5.5 Scratch

The current normalizer assumes a scratch limit flag implies observed stored
bytes greater than the hard bound. A correctly enforced tmpfs cannot satisfy
that equation.

Step E must separate:

```text
stored regular bytes and entries
filesystem capacity/denial witness
configured byte and inode bounds
final inventory completeness
```

`scratch_limit` requires a trusted kernel/filesystem denial or exhaustion
witness. Merely seeing a Lua assertion after many writes is insufficient.

## 6. Hostile Candidate Matrix

Fixture names are pressures, not truth. The campaign requires the following
minimum interpretation under the exact fixed Lua profile:

| Fixture | Required physical result |
|---|---|
| CPU loop | contained rejection with exact CPU-limit witness |
| allocator exhaustion | contained memory-limit only with allocator denial; otherwise ordinary unexpected exit |
| stdout flood | contained output-limit with stdout crossing and complete drain/reap |
| stderr flood | contained output-limit with stderr crossing and complete drain/reap |
| scratch exhaustion | contained scratch-limit only with trusted capacity/denial witness |
| source mutation attempts | expected exit only if every mutation is denied and pre/post source remains exact |
| host/sibling path probes | expected exit only if every path remains absent |
| socket/fork/exec/native-module/fd probes | expected exit only if the prohibited surface remains absent/denied |
| SIGSYS fixture | no SIGSYS claim from API absence alone; actual seccomp syscall denial remains QN13 evidence |

The existing `candidate_wall_loop.fixture` does not currently prove wall
blocking. With stdin closed, `pcall(io.read, 0)` can spin and consume CPU. It
must not be used as evidence for `wall_timeout` merely because of its filename.
It may terminate as `cpu_limit`, or it must be replaced by a lawful fixture
whose blocking mechanism does not widen the production candidate API.

Similarly, `candidate_sigsys.fixture` checks that Lua command APIs are absent.
It does not issue a forbidden syscall and cannot by itself prove SIGSYS
classification.

QN17 turns green only when every executed fixture has an explicit expected
classification and all source/cleanup/residue postconditions hold. It does not
require every currently declared reason enum to appear.

## 7. Trusted Fault Matrix

Trusted faults are test-owned injections, never candidate-controlled fields.

| Fault | Required result |
|---|---|
| wrong launcher ABI | production loader rejection; no candidate start |
| wrong supervisor identity | fail before candidate start; no fallback binary |
| malformed request frame | receiver rejects before candidate start |
| malformed result frame | quarantine/finality first, then loud trusted invariant failure |
| crash before start attestation | infrastructure error; start state not_started or unknown, never guessed |
| crash after start attestation | infrastructure error; started preserved, never candidate rejection |
| lost result pipe | infrastructure ambiguous unless terminal/reap/EOF facts remain independently complete |
| wait/reap ambiguity | infrastructure ambiguous and source quarantine |
| postflight source drift | infrastructure ambiguous/source_drift and source quarantine |

Production request, result, Lua API and shared-library symbols must contain no
fault-injection selector. Test fault builds have distinct identities and are
rejected by the production loader.

## 8. Start Attestation

Absence of a final result frame cannot prove that candidate execution never
started. Step E needs an independently framed, trusted start attestation or an
equivalent positive witness.

The attestation must bind:

```text
transaction id
witness id
profile/environment identity
exact source staging identity
candidate process identity local to the supervisor
monotonic phase ordinal
```

It carries no outcome. A start frame without a terminal frame yields
infrastructure failure, not candidate rejection.

## 9. Cleanup Ambiguity

QN19 is not satisfied by killing a process and assuming cleanup.

The campaign must distinguish:

```text
terminal candidate + complete reap + both EOFs + final scratch observation
  -> candidate outcome may exist

terminal candidate but missing EOF/scratch/namespace finality
  -> infrastructure ambiguity

unknown terminal state or failed reap
  -> infrastructure ambiguity

postflight source drift
  -> infrastructure ambiguity
```

At the repository boundary:

```text
complete definitive report/error -> source lease consumed
drift/cleanup/receipt ambiguity   -> source lease quarantined
trusted contradiction            -> quarantine then loud failure
```

No ambiguous path returns `rejected`.

## 10. Repeated-Run Residue

QN20 must name the channels it measures. It cannot prove universal absence of
all leaks from a stable RSS sample.

The v0 repeated campaign owns at least:

```text
parent launcher/provider descriptor count
unreaped child/process count
host mount table digest for the harness namespace
harness-owned temporary root identities
repository source lease terminal state
candidate scratch/root path absence after cleanup
Packet/root/economics ablation
```

The loop runs a bounded mixed sequence over fresh roots, including accepted,
ordinary rejected and resource-terminated candidates. It records a baseline,
checks after every iteration and checks again after Lua GC/handle closure.

If a channel cannot be observed exactly, it is excluded from the claim rather
than declared leak-free.

## 11. Fixture Activation Safety

The 26 hostile files remain inert data in the ordinary runner.

Before any candidate fixture becomes code:

```text
the fixture guard validates marker, id, class, filename and byte ceiling;
trusted test code materializes bytes into a disposable identity-owned root;
the root is sealed through the real first hand;
the production source lease is one-use;
execution occurs only after the execveat/static-supervisor boundary;
sentinel host paths remain outside every granted view;
cleanup uses identity, never a caller path string.
```

Trusted fault fixtures are parsed as closed test instructions. They are never
loaded by the production provider and never copied into candidate source.

## 12. Wire And Protocol Consequence

Step E changes the meaning and shape of native RUN evidence. It therefore
requires an explicit version revision, not silent reinterpretation of
`qa.native_run_result.v0`.

At minimum the revised protocol must carry:

```text
separate start and terminal phase evidence
decomposed finality/cleanup fields
independent stdout/stderr measurements
trusted allocator/limit witnesses where claimed
scratch stored-use plus capacity/denial evidence
closed infrastructure error taxonomy
the same transaction/witness/profile/environment joins
```

Changing supervisor policy or runtime heap law rotates:

```text
supervisor build id
policy digest where policy changed
environment id
```

Old QA contracts become unavailable. They do not silently upgrade.

## 13. Expected Control Delta

Before Step E implementation:

```text
red battery: 40 green / 44 red
native:      16 green / 4 red
```

After a complete Step E implementation:

```text
red battery: 44 green / 40 red
native:      20 green / 0 red
```

Only these controls change:

```text
QN17
QN18
QN19
QN20
```

`QE08-QE20`, all body `QV` controls and all completion/tree promotion remain
red. Any other delta is authority leakage or an accidental overclaim.

## 14. Falsifiers

Step E fails if any of the following occurs:

```text
a fixture filename determines outcome without physical evidence;
exit 70 is called memory/scratch limit without a trusted denial witness;
generic SIGKILL is called timeout or CPU limit without source attribution;
stdout and stderr are merged but projected as independent measurements;
output is truncated but its digest is described as full-stream truth;
cleanup_complete is inferred from successful kill alone;
missing start attestation becomes candidate_started=false;
malformed trusted result becomes candidate rejection;
fault injection appears in production ABI, wire or Lua surface;
test-only supervisor identity is accepted by production loader;
hostile fixture executes in the ordinary Lua test process;
an ambiguous source lease is consumed instead of quarantined;
QN17-QN20 turn green through no-op Make targets;
Packet trace, budget, loss, field or public root projection changes;
any body execution/check/verdict control turns green.
```

## 15. Required TABLE Answers

The next layer must close:

```text
T1 exact native phase/result/error protocols and versioning
T2 exact witness owner for every candidate reason
T3 exact hostile fixture outcome matrix
T4 trusted fault injection boundary and production exclusion
T5 start attestation and finality decomposition
T6 output count/hash/truncation semantics
T7 memory allocator ceiling and denial semantics
T8 scratch stored-use/capacity/denial semantics
T9 consumed versus quarantined source disposition
T10 exact repeated-run residue channels and iteration bound
T11 exact QN17-QN20 target/harness topology
T12 exact expected-red delta and rollback condition
```

## 16. Exit Boundary

This CHAOS round authorizes TABLE only.

It does not authorize:

```text
native code changes
fixture execution
new Make targets
protocol migration
Packet QA authority
body records or verdicts
router/completion promotion
```

The implementation campaign may begin only after TABLE and CRYSTALL each name
the writers, readers, error taxonomy, hostile harness and exact control delta.
