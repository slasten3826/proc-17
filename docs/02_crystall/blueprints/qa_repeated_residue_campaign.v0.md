# QA Repeated Residue Campaign Blueprint v0

Status:

```text
layer: CRYSTALL
date: 2026-07-29
chapter: 8.5.5E10.2
sources:
  docs/00_chaos/qa_e10_qn20_repeated_residue_notes_2026-07-29.md
  docs/01_table/yellowprints/qa_repeated_residue_campaign_yellowprint.v0.md
  docs/00_chaos/qa_e10_qn20_table_cross_audit_2026-07-29.md
scope: C10/QN20 repeated private-provider residue only
cross-table audit: satisfied
cross-crystall audit:
  satisfied by docs/00_chaos/qa_e10_qn20_crystall_cross_audit_2026-07-29.md
implementation authorized: yes, C10.1-C10.7 in exact order
Packet/body QA authority: forbidden
```

## 0. Promotion Boundary

This blueprint replaces only the provisional C10/QN20 section in
`qa_hostile_execution_campaign.v0.md`. It does not change QN01-QN19, RUN v1,
source finality, candidate outcome classification or any Packet/body QA
contract.

Input:

```text
ordinary native QA: 19 green / 0 red / 1 deferred
expected-red QA matrix: 43 green / 41 red
QN20: deferred/red
```

Required output:

```text
ordinary native QA: 20 green / 0 red / 0 deferred
expected-red QA matrix: 44 green / 40 red
QN20: green
all QN01-QN19 unchanged
all QE/QV/body/completion/router controls unchanged
```

The cold cross-crystall audit has verified and precision-amended this file
against the current native, Lua and Make boundaries. Implementation authority
is limited to C10.1-C10.7 in section 2; it grants no Packet/body QA authority.

## 1. Authority Model

QN20 adds one test instrument. It does not change production result semantics.

Production allocator/finality code remains the observed subject:

```text
private allocator snapshots stay stable, bounded and reason-compatible;
controller-owned forced termination may retain nonzero allocation-at-death;
process-tree reap, namespace cleanup and host absence prove that memory is no
longer live.
```

Test-only change:

```text
one read-only observer records exact host residue channels around 32 existing
production QA transactions
```

The observer may read:

```text
/proc/self/fd
/proc/<pid>/stat, comm, cgroup and exe identity
/proc/self/ns/*
/proc/self/mountinfo
the fixed test-owned root prefix
one fixture-guard-verified current root/source identity
```

The observer may not:

```text
execute candidate code
wait or reap a child
kill a process
unmount a mount
close a descriptor it did not open
remove a root
finish a source lease
write Packet state
accept arbitrary path, pid, fd or executable selectors
join a production binary or production Lua API
```

Detected residue is evidence. The observer never repairs it.

## 2. Implementation Slices

Implement in this order after audit authorization:

| Slice | Owner | Result |
|---|---|---|
| C10.1 | test-only native observer | opaque exact host snapshots and deltas |
| C10.2 | observer native self-test | every named host-channel falsifier is detected |
| C10.3 | fixture/root support | exact absence, sentinel and after-cleanup phase |
| C10.4 | shared-provider Lua support | build/load/probe once, fresh candidate state per iteration |
| C10.5 | Lua campaign | fixed 32-transaction schedule and joined records |
| C10.6 | control wiring | QN20 color, exact matrices and production exclusion |
| C10.7 | verification | focused, full, sanitizer, analyzer and diff gates |

Each slice runs its focused tests before the next slice starts. A failed slice
does not authorize weakening the TABLE.

## 3. Artifact Map

Expected file placement:

```text
native/tests/proc17_qa_residue_observer.c
native/tests/proc17_qa_residue_observer.h
native/tests/proc17_qa_residue_observer_lua.c
native/tests/test_proc17_qa_residue_observer.c
native/tests/proc17_qa_residue_observer.so          generated
native/tests/test_proc17_qa_residue_observer        generated
native/tests/proc17_fixture_guard.c
native/Makefile
tests/support/owned_temp_root.lua
tests/support/qa_provider_witness.lua
tests/support/qa_repeated_residue.lua               optional pure helpers
tests/test_qa_repeated_residue_observer.lua
tests/run_qa_repeated_residue_campaign.lua
tests/test_qa_native_supervisor.lua
tests/red_qa_hand.lua
```

CRYSTALL permits merging the observer C files if the read-only Lua API and the
native falsifier surface remain materially separate. It does not permit placing
observer symbols in `proc17_qa_supervisor`, `proc17_qa_launcher.so`,
`proc17_repository_fs.so` or runtime Lua modules.

Generated observer artifacts must be removed by `make -C native clean`.

## 4. Test-Only Observer API

The Lua binding exports one closed table:

```lua
observer = {
  protocol_version = "qa.residue_observer.lua54.v0",
  open = function() -> opaque_session | nil, typed_error,
  bind_owned_root = function(session, root_identity) -> opaque_subject | nil, typed_error,
  capture = function(session, scope, subject_or_nil)
      -> opaque_snapshot, qa_residue_host_projection_v0 | nil, typed_error,
  compare = function(baseline_snapshot, observed_snapshot)
      -> qa_residue_host_delta_v0 | nil, typed_error,
}
```

Closed scopes:

```text
baseline       subject forbidden
iteration      current verified subject required
post_cleanup   prior verified subject required; current entry must be absent
final          subject forbidden
```

`open()` accepts no caller configuration. It binds fixed implementation facts:

```text
production supervisor path: ./native/proc17_qa_supervisor
test-root parent: /tmp
test-root prefix: proc17-repository-hand-
fixed host mountpoints: /qa, /qa/source, /qa/scratch
namespace set: user, mnt, pid, net, ipc, uts
maximum /proc and mountinfo scan sizes
production supervisor exact executable identity
campaign pid/start epoch/cgroup identity
```

The session, subject and snapshot are opaque userdata with locked metatables.
They retain copied scalar records only. They hold no descriptor, pidfd,
namespace fd, mount fd, repository handle or provider pointer between calls.

Successful Lua projections contain ids, counts, booleans and truth status only.
They contain no raw path, pid, fd, command line, mount source or candidate bytes.

## 5. Observer Session Opening

`open()` performs these checks in order:

```text
O01 verify Linux /proc surfaces are present and bounded-readable
O02 open fixed production supervisor with O_NOFOLLOW | O_CLOEXEC
O03 require regular executable and copy dev/inode identity
O04 hash the fixed supervisor bytes with the existing proc17 SHA implementation
O05 require the expected production build identity relationship
O06 read campaign pid, starttime and exact cgroup identity
O07 close every descriptor opened by O01-O06
O08 return opaque immutable session
```

The observer does not trust process names as executable identity. The fixed
comm value is used only for fail-closed classification when a same-cgroup
zombie no longer exposes `/proc/<pid>/exe`.

The fixed current Linux value is `proc17_qa_super`, empirically confirmed from
the production `proc17_qa_supervisor` executable on 2026-07-29. The native
self-test must compare this value with a live production-supervisor fixture and
fail on drift; it is not caller configuration.

An unsupported or truncated required host surface returns a typed observer
error. It never degrades to a smaller residue claim.

## 6. Owned Root Subject

`bind_owned_root` accepts only the detached identity projection returned by
`owned_temp_root.identity(root)`:

```lua
{
  protocol_version = "repository.test_owned_root_identity.v0",
  path = "/tmp/proc17-repository-hand-XXXXXX",
  device = decimal_string,
  inode = decimal_string,
  mount_id = decimal_string,
}
```

The native binding independently:

```text
validates the exact path grammar;
opens /tmp and then the basename with no-follow semantics;
matches device, inode and mount id;
derives the fixed repository source path projects/candidate;
requires that source to be below the verified root;
copies the prior scalar identity/path into opaque subject userdata;
closes all descriptors before returning.
```

No caller-supplied repository-relative path is accepted. A post-cleanup capture
uses the already-verified subject. It does not accept a fresh raw path after the
root has disappeared.

## 7. Exact Parent Descriptor Snapshot

Capture ordering is fixed. The observer completes process, namespace, mount and
root-prefix scans first, closes every descriptor they opened, and only then
opens `/proc/self/fd` once and reads a bounded set. It
skips the scan directory descriptor itself. For every other descriptor it
copies:

```text
fd number
fstat device/inode/type
F_GETFD flags including close-on-exec
normalized F_GETFL access/status flags
bounded readlink target digest and availability class
```

It sorts records by fd number and full identity, hashes the normalized record,
closes the scan descriptor and rejects the capture if close fails. No host
resource is opened after this fd scan; projection assembly is memory-only.
Therefore a descriptor leaked by an earlier observer scan appears in the same
capture instead of hiding behind observation order.

`compare` derives independently:

```text
fd_opened
fd_missing
fd_identity_changed
fd_flags_changed
```

Equal descriptor counts are irrelevant. RF01 must demonstrate an equal-count
identity exchange that still yields a nonzero delta.

## 8. Process Snapshot

The bounded `/proc` census parses numeric pid entries. `/proc/<pid>/stat` is
parsed after the final closing parenthesis so spaces and parentheses in comm do
not shift fields.

Private process records include only what the comparator requires:

```text
pid and ppid
state
starttime
comm digest/value for fixed comparison
cgroup identity digest
executable dev/inode when readable
executable-read status
```

The public projection derives four independent channels:

```text
direct_live_child_count:
  ppid == campaign pid and state != Z

direct_zombie_count:
  ppid == campaign pid and state == Z

matching_supervisor_process_count:
  executable dev/inode == verified production supervisor identity

unresolved_supervisor_zombie_count:
  state == Z, cgroup matches campaign, fixed comm matches and executable
  identity is unreadable
```

The channels may overlap: for example, a direct production-supervisor child is
both a direct live child and an exact supervisor process. They are never summed
into a score. Exactness requires each named channel to be zero, independently.

The observer does not call `wait`, `waitpid`, `waitid`, `kill` or `pidfd_open`.
An unreadable process that could invalidate the exact claim yields either the
explicit unresolved count or a typed unsupported observation. It never becomes
zero by omission.

The clean baseline requires all four counts zero. Iteration and final deltas
require all four counts zero.

## 9. Namespace And Mount Snapshot

The observer copies `stat` device/inode identity for:

```text
/proc/self/ns/user
/proc/self/ns/mnt
/proc/self/ns/pid
/proc/self/ns/net
/proc/self/ns/ipc
/proc/self/ns/uts
```

Any parent namespace identity change is residue.

The mount reader parses bounded `/proc/self/mountinfo`, including kernel octal
escape decoding, and counts exact mountpoints only:

```text
/qa
/qa/source
/qa/scratch
verified owned root path
verified projects/candidate source path
```

Baseline/final captures have no subject and report only fixed `/qa` counts.
Iteration/post-cleanup captures use the opaque subject for current path counts.
The post-cleanup capture requires both current path counts zero.

Private namespace freedom is not derived from mountinfo alone. The campaign
requires the complete conjunction in TABLE section 10.

## 10. Root Prefix Snapshot

The observer scans `/tmp` for the exact fixed root grammar. For each matching
entry it records no-follow device/inode/type/mount identity. Unknown matching
entries are evidence and are never deleted by the observer.

The clean baseline requires:

```text
owned_root_count == 0
```

During `iteration` capture exactly the current owned subject may be present. It
is admitted, not residue. During `post_cleanup` and `final`, the complete root
set must equal the empty baseline.

Delta semantics therefore distinguish admitted current-root presence from an
extra or retained root. A simple count comparison is forbidden.

## 11. Opaque Snapshot And Delta

The native snapshot owns normalized private arrays in Lua userdata memory. Its
`__gc` releases only its own copied memory. It has no host cleanup effect.

The public projection and delta follow the TABLE schemas exactly. `exact` is
derived inside native code and cannot be submitted by Lua.

Comparison rejects:

```text
snapshots from different observer sessions;
baseline-vs-baseline or iteration-vs-iteration misuse;
scope/subject mismatches;
malformed or already-finalized userdata;
snapshot normalization overflow;
missing required host channel;
```

The same baseline snapshot may be compared with all iteration and final
snapshots. It is immutable.

## 12. Native Observer Falsifier Test

`native/tests/test_proc17_qa_residue_observer.c` owns deliberate defects. The
Lua observer API does not expose their creation.

Required native controls:

| ID | Test-owned defect | Required observer result |
|---|---|---|
| RO01 | clean self snapshot | exact |
| RO02 | exchange one fd while preserving count | identity delta |
| RO03 | retain one direct live child | live-child residue |
| RO04 | retain one direct zombie | direct-zombie residue |
| RO05 | hold one namespace or detached-mount fd | fd identity residue |
| RO06 | create `/qa` mount in a private test namespace | mount residue |
| RO07 | leave one owned-root grammar entry | root residue |
| RO08 | mutate one parent namespace identity in isolated child test | namespace mismatch |
| RO09 | truncate `/proc` or mount parser fixture | typed unsupported/error |
| RO10 | equal normalized snapshots | exact derived true |
| RO11 | caller attempts arbitrary root path | bind rejected |
| RO12 | observer scan descriptor closes before projection | no self residue |
| RO13 | execute the exact production supervisor on valid blocking descriptors | exact supervisor identity count, with `proc17_qa_super` confirmed |
| RO14 | retain one same-cgroup `proc17_qa_super` zombie without readable exe | unresolved-supervisor-zombie count |
| RO15 | retain one observer-owned non-fd-scan descriptor before the final fd scan | self-residue detected in the same capture |

The test harness may clean its own deliberate child/fd/mount/root after the
observer has recorded failure. That cleanup is protected test teardown, not an
observer operation. Host-mount falsifiers run in a private test namespace.

RO13 uses the production executable itself, not a renamed helper: the harness
provides valid fixed descriptors and leaves the request pipe open so the process
remains observable, then kills and reaps only after the assertion. RO14 is a
separate test child that sets the empirically fixed comm, exits and remains
unreaped until the unresolved fallback has been asserted.

## 13. Allocator Terminal Evidence And Memory Finality

Do not add a universal allocator-current-zero rule.

The current controller has two materially different terminal paths:

```text
cooperative return:
  candidate reaches lua_close before exit

controller-owned forced termination:
  output_limit or memory_limit can establish first cause and send SIGKILL
  before candidate destructors run
```

The second path can leave a nonzero value in shared allocator telemetry after
the process has been reaped. That value describes allocation-at-death; it does
not describe memory retained by the long-lived campaign host.

QN20 accepts memory finality only from this conjunction:

```text
existing private allocator snapshot is stable, bounded and reason-compatible
candidate process tree is reaped
controller/supervisor finality is complete
host process census is zero
parent fd identity set is restored
```

Required controls are observational, not new production policy:

```text
MQ01 existing clean terminal remains valid
MQ02 existing Lua-error terminal remains valid
MQ03 existing output-limit forced terminal remains valid after reap
MQ04 existing memory-limit forced terminal remains valid after reap
MQ05 current greater than peak remains invalid
MQ06 disagreeing terminal snapshots remain non-definitive
MQ07 no allocator current value enters public report, campaign ledger or output
```

`runtime_heap_peak_bytes` remains public cost/resource evidence. The private
current counter remains private.

## 14. Fixture Guard Amendments

Extend `native/tests/proc17_fixture_guard.c` without broadening its path grammar:

```text
absent PATH DEV INO MNT
sentinel-create
sentinel-probe PATH DEV INO MNT SIZE SHA256
sentinel-cleanup PATH DEV INO MNT
```

`absent` opens `/tmp`, validates the prior basename grammar and requires a
no-follow parent-relative lookup to return `ENOENT`. Any present replacement,
including a symlink or reused inode, fails.

The sentinel uses a separate fixed `/tmp/proc17-qa-sentinel-XXXXXX` grammar. It
is a regular file created with no-follow/create-exclusive semantics and exact
bytes. Probe and cleanup require device/inode/mount/size/content digest. The
sentinel is never below an owned repository root and never enters candidate
source. `sentinel-cleanup` returns success only after an identity-bound unlink
and a no-follow parent-relative `ENOENT` check prove the exact entry absent.

`tests/support/owned_temp_root.lua` gains:

```lua
owned_temp_root.identity(root)
owned_temp_root.absent(prior_identity)
owned_temp_root.use_prebuilt_helper()
owned_temp_root.with_root_phases(body_callback, after_cleanup_callback)
```

`identity` returns exactly `repository.test_owned_root_identity.v0`; it contains
only the validated path/device/inode/mount tuple. `with_root_phases` performs
identity-owned cleanup, drops the raw root reference before the second callback
and passes only that detached prior identity token. The existing `with_root`
remains compatible. `use_prebuilt_helper` runs the fixed helper self-test once
before baseline and marks no build authority; subsequent campaign root calls
must not enter `ensure_helper()` or Make.

## 15. Shared Production Provider Context

Refactor `tests/support/qa_provider_witness.lua` into two layers:

```lua
support.ensure_artifacts() -> true | nil, error       -- compatibility only
support.open_campaign() -> context
support.with_candidate_in_campaign(context, content, body, after_cleanup)
support.with_candidate(content, callback) -> compatibility wrapper
```

`open_campaign` executes once:

```text
load repository provider once
load QA provider once
probe QA environment once
freeze package.loaded table identities
freeze every used provider callable identity
freeze provider/protocol/build ids and normalized environment value digest
activate the already-built fixture helper without invoking Make
```

`open_campaign` assumes the outer Make target has built every artifact. It runs
no Make/compiler/build command and does not clear `package.loaded`. The fixed
fixture-helper self-test is permitted under its closed command/path grammar;
its child must terminate before baseline. The standalone QN20 process must
begin with both production provider modules absent, then load each exactly once.

`ensure_artifacts` preserves old one-shot tests: it may call the existing Make
helpers before loading, and `with_candidate` may clear each provider module once
before delegating to `open_campaign` for its single candidate. QN20 never calls
that compatibility path.

After baseline, the campaign asserts on every iteration:

```text
package.loaded entries are the original table identities
every frozen callable is the original function identity
context provider/protocol/build ids are unchanged
environment id and normalized value digest are unchanged
no build command runs
```

`with_candidate_in_campaign` creates fresh:

```text
owned root
Packet and lineage id
repository registry
root authority and grant
repository materialization
candidate seal
witness plan and transaction id
```

It reuses only the loaded production provider tables and frozen environment.
No registry, source lease, repository handle, report or root crosses iterations.

## 16. Per-Iteration Choreography

Each iteration follows this exact sequence:

```text
I01 verify provider/environment identities remain frozen
I02 create fresh owned root, bind observer subject and weak-track the subject
I03 create fresh Packet/registry/grant and materialize one fixture
I04 seal candidate and prepare one witness plan
I05 record Packet/public-root/economics ablation digest before execution
I06 weak-track all named body/support objects
I07 execute production witness once
I08 require expected exact outcome/reason/finality and consumed source
I09 replay the exact plan and require repository_qa_source_already_reserved
I10 prove the replay callback/provider was not entered using the existing boundary witness
I11 record Packet/public-root/economics ablation digest after execution
I12 probe the external sentinel after the transaction
I13 capture post-transaction host snapshot while root identity exists and weak-track its opaque/transient results
I14 compare post-transaction snapshot with baseline
I15 detach scalar/digest/delta evidence and release non-durable post-transaction observer results
I16 leave inner body scope and identity-clean the exact root
I17 require fixture-guard exact absence
I18 probe the external sentinel after cleanup
I19 run two full Lua collections and require all body/support weak sentinels absent
I20 capture and compare post-cleanup host snapshot using the prior opaque subject; weak-track its opaque/transient results
I21 release the subject and every non-durable per-iteration observer result
I22 run two full Lua collections and require all observer weak sentinels absent
I23 assemble the immutable iteration record
```

If I07 returns a trusted ambiguity instead of one of the four definitive
results, the campaign fails into QN19 semantics. It does not reinterpret the
iteration as rejected.

Protected teardown may remove the current exact root and sentinel if the
campaign aborts. It does not repair discovered process/fd/mount residue.

## 17. Closed Schedule

The enumerator contains exactly eight cycles of:

```lua
{
  {slot = "A", fixture = "candidate-clean-exit",
    outcome = "accepted", reason = "expected_exit"},
  {slot = "B", fixture = "candidate-lua-error",
    outcome = "rejected", reason = "unexpected_exit"},
  {slot = "C", fixture = "candidate-stdout-flood",
    outcome = "rejected", reason = "output_limit"},
  {slot = "D", fixture = "candidate-allocator-exhaustion",
    outcome = "rejected", reason = "memory_limit"},
}
```

The enumerator derives iteration, cycle and slot. The fixture `pressure` field
is never an oracle. Expected values carry `document_decision`; observed values
carry `runtime_confirmed`.

The production providers are already loaded before the baseline. Every fixture
is read and validated through the existing inert corpus and fixture guard.

## 18. Body, Root And Source Joins

The body ablation digest is a pure test derivation over:

```text
Packet status/operator/tick
trace and revision vector
tension/death/manifest
Packet-local budget and loss
public repository root projection
```

It excludes private source-lease lifecycle because that state is expected to
move from available through in-use to consumed.

The source join requires:

```text
report source disposition == consumed
pre/post inventory ids agree with the candidate seal
exact replay returns repository_qa_source_already_reserved
replay does not enter provider callback
public root projection is unchanged
post-transaction fd set equals baseline
```

The durable record stores no raw Packet, registry, plan, report, services,
provider table, root object or source handle.

## 19. Weak Liveness

Use separate body/support and observer weak-value tables per iteration. The
body/support table tracks at least:

```text
Packet instance
repository capability registry
provider witness plan
detached provider report
iteration service/support table
owned root record
```

The observer table tracks:

```text
opaque owned-root subject
post-transaction opaque snapshot and public projection
post-cleanup opaque snapshot and public projection
```

The iteration function must not return any tracked object. It returns scalar
ids, enums, counts, booleans, detached host deltas and digests only. After root
cleanup it performs the first pair of collections and requires
`live_body_weak_objects_after_gc == 0` while the opaque subject remains live for
the post-cleanup capture. After that capture, comparison and explicit release
of non-durable observer values, it performs a second pair:

```lua
collectgarbage("collect")
collectgarbage("collect")
```

`live_observer_weak_objects_after_gc` must then be zero. The frozen
provider/environment context, observer session, baseline snapshot and scalar
records are campaign-owned and excluded. The detached prior root identity and
durable host deltas are plain scalar projections, not observer userdata.

The opaque subject is released after its post-cleanup capture and is not
retained in the durable iteration record.

## 20. Sentinel

Create the external sentinel before the clean baseline. Its exact projection is
admitted baseline state:

```text
device
inode
mount id
regular-file type
length
content digest
```

Probe it after every transaction, after each root cleanup and before the final
snapshot after final GC. Any mismatch fails the campaign. Clean it only after
the final snapshot and summary have been assembled; the cleanup helper must
prove the exact sentinel entry absent before the success line is printed.

The observer does not own sentinel creation, probing or cleanup; the fixture
guard owns those operations.

## 21. Campaign Summary

The summary is assembled only when all 32 immutable iteration records are
present and exact.

Required aggregate:

```text
declared=32 executed=32 matched=32
accepted=8 ordinary_rejected=8
output_terminated=8 memory_terminated=8
replay_denials=32 replay_launches=0
fd=0 process=0 namespace=0 mount=0 root=0 source=0
memory_finality=0 lua=0 sentinel=0 body=0
final_snapshot_exact=true
```

The final capture occurs after:

```text
all 32 roots are absent
all iteration subjects are released
all iteration snapshots and transient projections are released
two final full Lua collections complete
the sentinel is still present and exact
```

Only then may the campaign print the bounded success line from the TABLE.

## 22. Make And Test Wiring

Add generated targets:

```make
qa-residue-observer-test
qa-supervisor-leak-loop-test
```

`qa-residue-observer-test` builds/runs only the test observer and native
falsifiers. Its module and native test depend explicitly on
`$(QA_SUPERVISOR)`, `$(QA_BUILD_IDENTITY)`, `proc17_sha256.c` and the relevant
Lua build flags, so the fixed production digest/comm relationship cannot go
stale behind an old observer artifact.

`qa-supervisor-leak-loop-test` depends on:

```text
provider-shell
qa-provider-shell
fixture-helper
qa-report-test
qa-residue-observer-test
```

and then executes exactly:

```text
cd .. && lua tests/run_qa_repeated_residue_campaign.lua
```

The Lua campaign starts as a fresh process after all dependencies complete. It
must not invoke `make` at all, including before baseline or inside an iteration.
The campaign support asserts frozen provider identity; build dependencies
belong only to Make. `clean` removes the observer module, observer native test
and every other generated QN20 artifact.

`tests/test_qa_repeated_residue_observer.lua` validates the closed Lua API,
opaque userdata, root binding, scope order, no raw authority and typed errors.

## 23. Red-First Sequence

Before implementation:

```text
QN20 remains red/deferred
ordinary native QA = 19/0/1
red matrix = 43/41
```

Implement controls in this order:

```text
R1 impossible allocator shape or unstable terminal pair must fail
R2 observer API target absent/red
R3 descriptor identity-exchange falsifier red then green
R4 process/zombie falsifiers red then green
R5 namespace/mount/root falsifiers red then green
R6 shared-provider identity/reload guard red then green
R7 one clean iteration exact
R8 one four-slot cycle exact
R9 full eight-cycle campaign exact
R10 production exclusion exact
R11 QN20 and color matrices exact
```

No aggregate campaign success is accepted before every named falsifier has an
individual green control.

## 24. Failure Semantics

Closed campaign error classes:

```text
unsupported_observer_environment
dirty_precondition
provider_identity_changed
environment_identity_changed
observer_capture_failed
observer_scope_invalid
host_residue_detected
candidate_result_mismatch
source_finality_mismatch
source_replay_mismatch
root_cleanup_failed
root_absence_unproven
memory_finality_mismatch
body_object_retained
observer_object_retained
sentinel_changed
body_root_changed
summary_incomplete
```

These are test harness diagnostics, not candidate reasons, Packet death causes
or public provider result kinds. No campaign failure is converted to accepted
or rejected candidate evidence.

## 25. Production Exclusion

After building production and test artifacts, assert:

```text
production supervisor/launcher/repository module do not export observer symbols
production Lua module tables do not expose observer/campaign APIs
production artifacts contain no campaign id, summary prefix or RF selector
production artifacts contain no test-root census API
observer module cannot be loaded as the production launcher
fault/observer build identities differ from production identities
```

The existing allocator terminal validation remains in the production
supervisor closure. Campaign schedule, observer and falsifier vocabulary are
not.

Artifact scans inspect the compiled result with `nm`, `readelf` and bounded
string/API tests. Source placement alone is insufficient.

## 26. Falsifier Coverage Map

| TABLE falsifier | CRYSTALL reader |
|---|---|
| RF01 fd identity exchange | RO02 + native delta comparator |
| RF02 direct live child | RO03 |
| RF03 direct zombie | RO04 |
| RF04 exact production supervisor | RO13 + campaign precondition |
| RF04a unreadable fixed-comm zombie | RO14 + unresolved channel |
| RF05 namespace/detached fd | RO05/RO08 |
| RF06 host `/qa` mount | RO06 |
| RF07 retained root | RO07 + guard `absent` |
| RF08 replay reaches provider | typed reserve denial + PT-T08 callback counter |
| RF09 impossible/unstable allocator terminal | MQ05/MQ06 |
| RF10 retained body/support object | body weak-sentinel control |
| RF10a retained observer object | observer weak-sentinel control |
| RF11 changed sentinel | fixture-guard sentinel control |
| RF12 changed body/public root | pure ablation control |
| RF13 observer linked to production | compiled artifact exclusion |
| RF14 final-only checking | iteration schema/order self-test |
| RF15 provider reload | frozen context identity control |
| RF16 observer self-fd | RO15 + fd scan ordered last |

Every TABLE falsifier has one first reader. No summary-only substitute exists.

## 27. Verification Battery

Focused:

```text
make -C native qa-report-test
make -C native qa-residue-observer-test
lua tests/test_qa_repeated_residue_observer.lua
make -C native qa-supervisor-leak-loop-test
```

Promotion:

```text
lua tests/test_qa_native_supervisor.lua
lua tests/red_qa_hand.lua              # expected nonzero, exact 44/40
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
```

Closure:

```text
make -C native qa-static-closure-test
production symbol/string/API exclusion audit
luac -p on changed Lua files
git diff --check
```

Native rigor:

```text
ASan/UBSan focused observer/report tests
LeakSan when the host supports it, supporting evidence only
GCC -fanalyzer on changed observer/report/fixture-guard code
```

Sanitizer or analyzer results cannot replace the exact QN20 residue vector.

## 28. Acceptance Gates

Gates before implementation:

```text
G0 cross-crystall audit names no unresolved authority or observability conflict
G1 CRYSTALL remains consistent with TABLE after audit amendments
G2 no runtime implementation file changed before G0/G1
```

Gates during implementation:

```text
G3 observer is read-only and test-only
G4 every capture closes its own descriptors before returning
G5 forced allocation-at-death is not confused with live host residue
G6 production providers are loaded/probed once before baseline
G7 all 32 iterations use fresh body/root/source identities
G8 both host observation phases exist for every iteration
G9 no raw iteration authority enters durable records/output
G10 every named falsifier is green
G10a outer Make owns all builds; campaign executes no Make command
G10b both body/support and observer weak sets reach zero at their phase boundary
```

Promotion gate:

```text
G11 declared=32 executed=32 matched=32
G12 all named residue channels equal zero/exact per iteration and final
G13 ordinary native QA = 20/0/0
G14 expected-red matrix = 44/40
G15 only QN20 changed color
G16 Packet/body QA authority remains absent
```

## 29. Implementation Gate

Current decision:

```text
CHAOS complete: yes
TABLE complete: yes
cross-table audit: satisfied
CRYSTALL complete: yes
cross-crystall audit: satisfied
cross-crystall audit record:
  docs/00_chaos/qa_e10_qn20_crystall_cross_audit_2026-07-29.md
implementation authorized: yes, C10.1-C10.7 in exact order
Packet/body QA authority: forbidden
```

Red-first checkpoint:

```text
E10.3 complete: yes
native observer controls: 15 red by absent module
Lua observer controls: 7 red by absent module
ordinary native QA: 19/0/1
expected-red QA matrix: 43/41
record:
  docs/00_chaos/qa_e10_qn20_red_observer_contract_2026-07-29.md
```

Next action:

```text
C10.1-C10.3 implement the test-only observer, native self-tests and fixture
phase support against the frozen red contracts; no Packet/body or
production-runtime semantic change
```

## 30. Implementation Amendment - 2026-07-29

The authorized sequence C10.1-C10.7 has now executed in full.

```text
C10.1 test-only native observer                  complete
C10.2 observer native/Lua falsifiers             complete
C10.3 exact absence and sentinel fixture support complete
C10.4 one-load frozen provider context           complete
C10.5 fixed 32-transaction campaign              complete
C10.6 QN20 and exact matrix wiring               complete
C10.7 focused/full/analyzer/exclusion closure    complete

ordinary native QA: 20 green / 0 red / 0 deferred
expected-red QA matrix: 44 green / 40 red
QN20: green
Packet/body QA authority: absent
```

Runtime evidence and the defects found during execution are recorded in:

```text
docs/00_chaos/qa_e10_qn20_campaign_implementation_2026-07-29.md
docs/03_manifest/qa_qn20_repeated_residue_e10.v0.md
```

The earlier red-first checkpoint and `Next action` above remain archaeology of
the implementation order; they no longer describe the active frontier.
