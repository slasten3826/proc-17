# QA E10 / QN20 TABLE Cross-Audit

Status:

```text
layer: CHAOS audit
date: 2026-07-29
chapter: 8.5.5E10.2
subject: repeated private-provider residue campaign
source table:
  docs/01_table/yellowprints/qa_repeated_residue_campaign_yellowprint.v0.md
source chaos:
  docs/00_chaos/qa_e10_qn20_repeated_residue_notes_2026-07-29.md
audit base: b74c1f5 plus the uncommitted QN20 document drafts
cross-table audit: satisfied after the amendments recorded here
crystallization authorized: yes
runtime implementation authorized: no; crystall cross-audit remains required
Packet/body QA authority: forbidden
```

Subsequent gate amendment 2026-07-29:

```text
the required cross-crystall audit was completed at:
  docs/00_chaos/qa_e10_qn20_crystall_cross_audit_2026-07-29.md
implementation authority now comes only from:
  docs/02_crystall/blueprints/qa_repeated_residue_campaign.v0.md
This TABLE audit's original no-authority decision remains historical and was
not retroactively rewritten.
```

## 0. Question

The TABLE claims that one long-lived Lua process can execute 32 fresh production
QA transactions and prove that every named transient authority channel returns
to its admitted baseline after each transaction.

This audit asks a narrower implementation question:

```text
Does every requested QN20 fact have a current writer, a non-mutating reader and
an implementation path that does not invent a second source of production truth?
```

The audit does not claim that the machine has no possible leak. It decides
whether the bounded QN20 vector is precise enough to crystallize.

## 1. Cold Baseline

The current body was exercised before the TABLE was authorized:

```text
lua tests/run.lua                         -> all 107 suites ok
lua tests/smoke_mortality_battery.lua     -> 8/8
lua tests/test_qa_native_supervisor.lua   -> green=19 red=0 skip=1
lua tests/red_qa_hand.lua                 -> green=43 red=41 skip=0
```

The red battery exits nonzero by design because Packet QA request/check/verdict
authority is still absent. Its control matrix is exact and confirms QN20 as the
only deferred native campaign.

The test run generated a native test binary. Generated binaries are not audit
sources and do not authorize a contract.

Unrelated local CLI edits and self-ingestion archaeology were excluded from the
audit. No production code was changed during this TABLE round.

## 2. Read Set

The audit compared the QN20 documents with these current owners:

```text
core/qa_schema.lua
runtime/qa_provider.lua
runtime/qa_process.lua
runtime/qa_provider_witness.lua
runtime/repository_capability.lua
runtime/repository_provider.lua
native/proc17_qa_supervisor.c
native/proc17_qa_launcher.c
native/proc17_qa_launcher_v1.c
native/proc17_qa_report.c
native/proc17_qa_allocator.c
native/proc17_qa_wire.h
native/Makefile
native/tests/proc17_fixture_guard.c
tests/support/owned_temp_root.lua
tests/support/qa_provider_witness.lua
tests/support/qa_hostile_fixtures.lua
tests/run_qa_hostile_candidate_campaign.lua
tests/test_qa_native_supervisor.lua
tests/red_qa_hand.lua
```

The audit also inspected the production supervisor mount choreography: the
verified repository source is self-bound before it is moved into the private
`/qa/source` tree. This matters to host-mount observation.

## 3. Findings And Disposition

### F1 - `waitable` was stronger than the observer's fact

Class: observer overclaim.

The draft named `waitable_child_count`. A read-only observer can prove a direct
zombie from `/proc/<pid>/stat` using `ppid == campaign_pid` and `state == Z`.
Calling `wait`, `waitpid` or `waitid` would consume child state and make the
observer a cleanup actor.

Disposition:

```text
waitable_child_count -> direct_zombie_count
waitable_children    -> direct_zombies
```

The TABLE now states that the observer never waits or reaps. QN20 still joins
this host fact with the production terminal report's own reap evidence.

Status: corrected; no blocker.

### F2 - fixed `/qa` mountpoints were not the complete host surface

Class: false-green host observation.

The production supervisor first self-binds the real source path and only then
moves the cloned mount into `/qa/source` inside the child namespace. If private
mount propagation failed, the host-visible residue could remain at the real
temporary source path rather than at `/qa/source`.

Disposition:

```text
baseline/final:
  count exact /qa, /qa/source and /qa/scratch host mountpoints

post-transaction:
  additionally count the fixture-guard-verified current root and repository
  source host mountpoints
```

The current source identity is accepted only from the owned fixture token. The
observer does not accept an arbitrary path selector.

Status: corrected in TABLE before crystallization.

### F3 - one truth status would launder expectation into observation

Class: epistemic schema defect.

The fixed schedule and expected outcome are human decisions. The observed
result and host projection are runtime facts. A single
`event_truth_status = runtime_confirmed` on the joined iteration would falsely
upgrade the schedule.

Disposition:

```text
expectation_truth_status = document_decision
observation_truth_status = runtime_confirmed
```

The same split is present in the campaign summary.

Status: corrected in TABLE before crystallization.

### F4 - one post-cleanup snapshot could erase mount evidence

Class: ordering ambiguity.

The current source path is easiest to identify while the owned root still
exists. Root cleanup must also be proven after it no longer exists. One snapshot
cannot honestly occupy both phases.

Disposition:

```text
post_transaction_host_delta (`scope = iteration`):
  after source finality and replay denial, before root cleanup

post_cleanup_host_delta (`scope = post_cleanup`):
  after exact root cleanup and full Lua collection
```

The iteration record becomes valid only after both observations. The current
verified root is admitted only in the first scope and is excluded from residue;
the second scope admits no root. Neither snapshot authorizes cleanup.

Status: corrected in TABLE before crystallization.

### F5 - descriptor identity observation is implementable without exporting fds

Class: feasibility confirmation.

`/proc/self/fd` permits a bounded scan of the campaign process. The observer can
skip its own directory descriptor, copy only scalar `fstat` identity, flags and
a bounded target digest, close the scanner, normalize/sort the record and retain
the set inside opaque test userdata.

Lua receives only snapshot ids and typed delta counts. No live descriptor,
target path or close operation crosses the observer API.

Status: confirmed.

### F6 - process finality requires exact and fail-closed channels

Class: precision amendment.

The process reader must distinguish:

```text
direct live children of the campaign process;
direct zombies of the campaign process;
any process whose executable dev/inode matches the production supervisor;
same-cgroup, fixed-comm zombies whose executable identity is unreadable.
```

The last channel is deliberately fail closed. It may reject a dirty host; it
cannot certify absence from a process name alone. Namespace destruction remains
a conjunction of production finality, process absence, descriptor restoration
and host mount non-propagation.

Status: confirmed after F1 terminology correction.

### F7 - universal allocator zero was false for forced termination

Class: TABLE contradiction against runtime; high if implemented literally.

The first audit draft treated every definitive RESULT as if candidate execution
had returned through `run_restricted_lua_with_allocator` and therefore through
`lua_close`. The controller code disproves that assumption.

For `output_limit` and `memory_limit`, the namespace controller can establish a
first cause while the candidate is still live and send `SIGKILL` through its
pidfd. It then reaps the process and snapshots the shared allocator telemetry.
Lua destructors did not run, so `current_bytes` may remain nonzero even though
the candidate address space no longer exists. Requiring zero would reject an
honest controller-owned termination and confuse historical allocation-at-death
with live host residue.

Disposition:

```text
remove the proposed universal current-zero production rule;
retain existing stable/bounded/reason-compatible private validation;
derive memory finality by joining that terminal evidence with process-tree reap,
namespace cleanup and zero host process/fd residue;
keep allocator current private and out of the campaign ledger/output.
```

The QN20 schedule deliberately includes both forced rows, so this correction is
not theoretical. The TABLE was amended before crystallization.

Status: corrected; no production allocator change required.

### F8 - the current Lua support reloads providers per candidate

Class: harness mismatch, not a production defect.

`tests/support/qa_provider_witness.lua` currently builds, clears
`package.loaded`, reloads providers and probes the environment inside
`with_candidate`. That helper is correct for isolated tests but cannot witness a
long-lived QN20 host.

CRYSTALL must add a campaign context that builds/loads/probes once and creates a
fresh Packet, registry, root, seal and transaction inside each iteration. The
old one-shot helper remains a compatibility wrapper.

Status: confirmed; implementation slice named.

### F9 - replay denial already has a typed pre-provider boundary

Class: writer/reader confirmation.

`repository_capability.reserve_qa_source` returns
`repository_qa_source_already_reserved` before `with_qa_source` can call the
provider. Existing PT-T08 evidence proves the callback is not entered on this
denial. QN20 does not require a wrapper or a second launch counter inside the
production provider.

Status: confirmed.

### F10 - exact root absence needs a new guard operation, not path trust

Class: missing test helper operation.

The current fixture guard can create, probe and identity-clean a root. After
cleanup the Lua `cleaned` flag is not independent evidence that the exact path
entry is absent.

CRYSTALL must extend the guard with an `absent` operation that accepts the same
validated path grammar and prior identity token, then requires `ENOENT` from a
no-follow parent-relative lookup. The prefix census independently proves that
no test-owned root remains.

Status: implementation slice named.

### F11 - weak liveness can stay outside the durable ledger

Class: feasibility confirmation.

Iteration-owned objects can be inserted into a weak-value table and allowed to
leave lexical scope. The durable iteration record retains only detached scalar
and digest projections. Two full collections then test the named object set.

The shared provider modules, environment, schedule, opaque baseline and scalar
root identity token are campaign-owned, not iteration-owned.

Status: confirmed.

### F12 - the observer must have two test surfaces

Class: falsifier isolation requirement.

The live campaign needs a read-only capture/compare API. Falsifiers need to
create a leaked descriptor, child, mount or retained object and then clean their
own fixture after the observer has rejected it. Mixing those powers into one
Lua module would make the observer a repair authority.

Disposition:

```text
test-only observer module: read-only capture and compare
native observer self-test: owns deliberate defects and protected cleanup
production binaries: contain neither surface
```

Status: confirmed; CRYSTALL must name the artifact split.

## 4. Audit Questions

| ID | Verdict | Evidence |
|---|---|---|
| A1 | yes | opaque normalized fd snapshots expose no live descriptor |
| A2 | yes after F1 | direct live/zombie census plus exact executable and fail-closed unresolved channel |
| A3 | yes | namespace absence is a conjunction, never a mountinfo-only claim |
| A3a | yes after F2 | fixed `/qa` plus verified current root/source mountpoints |
| A4 | yes after F7 | forced allocation-at-death is distinguished from live residue by stable terminal evidence plus reap/process absence |
| A5 | yes | weak table is ephemeral; ledger stores scalar/digest records only |
| A6 | yes | typed reserve denial occurs before provider callback; PT-T08 is the reader |
| A7 | yes after F10 | fixture guard prior identity plus no-follow absence and prefix census |
| A8 | yes after F8 | campaign context freezes loaded provider/environment identities once |
| A9 | yes if artifact split is enforced | observer/falsifier artifacts live under native/tests and production scans reject markers |
| A10 | yes | existing witness snapshots Packet/public root; campaign adds exact body digest |
| A11 | no conflict | the four fixtures already have QN17 runtime-confirmed outcomes |
| A12 | yes | TABLE section 18 names the first reader for every written record |

## 5. Writer And Reader Closure

| Fact | Authoritative writer | First named reader | Audit result |
|---|---|---|---|
| fixed schedule | TABLE | campaign enumerator | closed |
| candidate result/finality | production controller/launcher | `runtime/qa_process.lua` | closed |
| allocator/process memory finality | private allocator/report validator + reap owner | campaign comparator | closed after F7 |
| source terminal state | repository capability registry | replay assertion | closed |
| exact root absence | fixture guard | campaign comparator | CRYSTALL operation named |
| fd/process/ns/mount snapshot | read-only test observer | campaign comparator | CRYSTALL artifact named |
| weak object liveness | Lua GC/weak table | campaign comparator | closed |
| sentinel identity | fixture guard | campaign comparator | CRYSTALL operation named |
| body/public-root digest | pure test derivation | campaign comparator | closed |
| iteration record | campaign assembler | summary assembler | closed |
| summary | summary assembler | QN20 matrix reader | closed |

No record is admitted without a named reader.

## 6. Crystallization Decision

The TABLE is coherent after F1-F4 and F7. F5-F6 and F8-F12 identify
implementation boundaries; none requires a new production authority or a
TABLE redesign.

Decision:

```text
cross-table audit: satisfied
crystallization: authorized
runtime implementation: not yet authorized
required next artifact:
  docs/02_crystall/blueprints/qa_repeated_residue_campaign.v0.md
required next gate:
  cold cross-crystall audit before native or Lua implementation
```

The future CRYSTALL may refine file names and private data layouts. It may not:

```text
split the campaign into multiple host processes;
reload production providers inside the loop;
replace exact identity sets with counts;
let the observer wait, reap, kill, unmount or delete;
drop either host observation phase;
publish raw paths, pids or fds;
promote any Packet/body QA authority;
change any control color except QN20.
```

## 7. Non-Claims

This audit does not prove:

```text
universal heap freedom;
stable RSS;
absence of kernel or libc caches;
cleanup after arbitrary host power loss;
production suitability on non-Linux hosts;
QA check/verdict correctness;
software acceptance;
body QA authority.
```

It proves that QN20 now has a bounded, observable and implementation-ready
physics table.
