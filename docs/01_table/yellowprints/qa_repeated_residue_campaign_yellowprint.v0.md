# QA Repeated Residue Campaign Yellowprint v0

Status:

```text
layer: TABLE
date: 2026-07-29
chapter: 8.5.5E10
source:
  docs/00_chaos/qa_e10_qn20_repeated_residue_notes_2026-07-29.md
scope: QN20 repeated private-provider residue only
machinist decision: one long-lived host, four-case x eight schedule
cross-table audit:
  satisfied by docs/00_chaos/qa_e10_qn20_table_cross_audit_2026-07-29.md
crystallization authorized: yes
runtime implementation authorized by this TABLE alone: no
Packet/body QA authority: forbidden
```

Cross-crystall precision amendment 2026-07-29:

```text
audit:
  docs/00_chaos/qa_e10_qn20_crystall_cross_audit_2026-07-29.md
the outer Make target owns every build before the campaign process starts
provider/environment identity includes exact callable and value surfaces
observer-owned per-iteration userdata is covered by a second GC boundary
all observer host scans close before the parent-fd snapshot is taken last
process channels are independent witnesses and are never arithmetically summed
sentinel identity is checked after transaction, after cleanup and before final
```

## 0. Fixed Decisions

| ID | Decision |
|---|---|
| R01 | QN20 executes 32 fresh transactions in one long-lived Lua process. |
| R02 | The outer Make target builds every required artifact before Lua starts; production repository and QA providers are then loaded and probed once before baseline. |
| R03 | The schedule is eight repetitions of clean, Lua error, output limit and allocator limit. |
| R04 | Every iteration owns a fresh Packet, registry, sealed root, source lease and transaction identity. |
| R05 | Residue is a named vector; no unbacked aggregate boolean is authoritative. |
| R06 | Parent descriptors are compared by exact identity set, not count alone. |
| R07 | Private namespace destruction is derived from process finality, descriptor restoration and host mount non-propagation. |
| R08 | Allocator terminal evidence must remain stable/bounded and is joined with process reap; nonzero allocation-at-death is not host residue. |
| R09 | Lua retention is tested by weak sentinels after full collection; RSS is excluded. |
| R10 | The test observer is read-only and absent from production artifacts and APIs. |
| R11 | Residue is checked after every iteration and after final GC. |
| R12 | Only QN20 changes color; no Packet/body QE/QV authority is promoted. |
| R13 | Observer subjects, snapshots and projections are iteration-owned too; no observer allocation may cross the next iteration merely because the observer is test-only. |
| R14 | Every host scan closes before the exact parent-fd scan runs last; observer self-residue cannot hide behind observation order. |

## 1. Scope

Owned here:

```text
qa.repeated_residue_campaign.v0
qa.residue_host_projection.v0
qa.residue_host_delta.v0
qa.repeated_residue_iteration.v0
qa.repeated_residue_summary.v0
closed 32-case schedule
test-only host observer authority
allocator-terminal/process-finality validation
per-iteration root/source/body/GC joins
QN20 exact promotion delta
```

Not owned here:

```text
Packet QA request or execution receipt
qa_check or qa_verdict
software acceptance
retry/resume
root compost or repository retention policy
general shell/command execution
production fault selectors
stable RSS or universal heap-leak claims
performance benchmarking
```

## 2. Supersession Boundary

This table supersedes only the provisional QN20 material in:

```text
docs/01_table/yellowprints/qa_hostile_execution_campaign_yellowprint.v0.md §15
docs/02_crystall/blueprints/qa_hostile_execution_campaign.v0.md §11
```

E1-E9, QN17-QN19 and every promoted provider contract remain unchanged. The old
QN20 text remains archaeology. It cannot authorize E10 implementation until a
new CRYSTALL amendment is derived from this table.

## 3. Campaign Identity

```lua
qa_repeated_residue_campaign_v0 = {
  protocol_version = "qa.repeated_residue_campaign.v0",
  campaign_id = "qa-qn20-campaign:" .. sha256(normalized_schedule),
  iteration_count = 32,
  cycle_count = 8,
  cycle = {
    "candidate-clean-exit",
    "candidate-lua-error",
    "candidate-stdout-flood",
    "candidate-allocator-exhaustion",
  },
  provider_id = "linux.qa_supervisor.lua54.v0",
  profile_id = "qa.profile.lua54_test_suite.v0",
  event_truth_status = "document_decision",
}
```

The campaign id, case ids and observer identity are test evidence. They never
enter production provider input, candidate bytes, launcher frames or supervisor
frames.

## 4. Long-Lived Host Precondition

The exact phase order is:

| Phase | Required act | Forbidden substitute |
|---|---|---|
| H0 | outer Make target builds repository provider, QA provider, supervisor identity, fixture guard and residue observer before Lua starts | any build command in the campaign process |
| H1 | load repository provider once | clear/reload module |
| H2 | load QA provider once | test/fault provider |
| H3 | probe one production environment | per-case alternate identity |
| H4 | load one test-only observer | observer linked into production |
| H5 | create one external sentinel | candidate-visible sentinel |
| H6 | prove clean process/root/mount precondition | accept dirt as baseline |
| H7 | take exact baseline | count-only baseline |

The campaign opens only prebuilt artifacts. Its Lua process does not run Make,
clear provider modules or compile a helper. The campaign fails before iteration
1 if:

```text
one matching production-supervisor process already exists;
one unresolved same-cgroup supervisor-shaped zombie already exists;
one direct live child or direct zombie already exists;
one /qa, /qa/source or /qa/scratch host mount exists;
one test-owned repository-root prefix entry already exists;
the observer cannot prove its own scan descriptors are closed;
the provider or environment identity is not production exact.
```

The sentinel itself is admitted baseline state and is excluded from the owned
repository-root prefix.

Provider continuity is stronger than table identity alone. The campaign freezes
the two `package.loaded` table identities, every production callable it uses,
the provider/protocol/build ids and a normalized environment value digest.
Every iteration must reproduce that complete surface. Mutating a function in
the same Lua table is provider drift, not continuity.

## 5. Closed Schedule

| Slot | Count | Fixture | Outcome | Reason | Named cleanup family |
|---|---:|---|---|---|---|
| A | 8 | `candidate-clean-exit` | accepted | `expected_exit` | normal terminal |
| B | 8 | `candidate-lua-error` | rejected | `unexpected_exit` | Lua failure terminal |
| C | 8 | `candidate-stdout-flood` | rejected | `output_limit` | output-bound termination |
| D | 8 | `candidate-allocator-exhaustion` | rejected | `memory_limit` | allocator-denial termination |

Every fixture is read from the existing inert QN17 corpus, validated by the
fixture guard, materialized through the first repository hand, candidate-sealed
and executed by the production provider. QN20 adds no candidate source.

## 6. Host Projection

The test-only observer returns no raw path, pid or fd:

```lua
qa_residue_host_projection_v0 = {
  protocol_version = "qa.residue_host_projection.v0",
  snapshot_id = "qa-host-snapshot:" .. sha256(private_normalized_record),
  scope = "baseline" | "iteration" | "post_cleanup" | "final",

  parent_fd_set_id = "qa-fd-set:" .. sha256(private_fd_set),
  parent_fd_count = non_negative_integer,

  parent_namespace_set_id = "qa-ns-set:" .. sha256(private_parent_namespaces),
  direct_live_child_count = non_negative_integer,
  direct_zombie_count = non_negative_integer,
  matching_supervisor_process_count = non_negative_integer,
  unresolved_supervisor_zombie_count = non_negative_integer,

  qa_host_mount_count = non_negative_integer,
  owned_source_identity_id = string | nil,
  owned_source_host_mount_count = non_negative_integer | nil,
  owned_root_set_id = "qa-owned-root-set:" .. sha256(private_root_set),
  owned_root_count = non_negative_integer,

  event_truth_status = "runtime_confirmed",
}
```

The private fd set contains, for each descriptor after the scan descriptor is
closed:

```text
fd number
fstat device/inode/type
F_GETFD close-on-exec flags
normalized F_GETFL access/status flags
bounded readlink target digest where available
```

Within one capture, process, namespace, mount and root scans complete and close
all of their descriptors first. The exact parent-fd scan runs last, closes its
own directory descriptor, and no later capture phase may open a host resource.
Thus a descriptor leaked by the observer itself is evidence rather than an
unobserved side effect of measuring residue.

The private parent namespace set contains the identities of:

```text
user, mount, pid, network, ipc and uts namespaces
```

The four process channels are independent witnesses. A process may satisfy
more than one channel; the campaign never adds these counts into one score, so
overlap cannot double-count pressure or manufacture residue. The clean claim is
the conjunction that every named channel is zero.

`matching_supervisor_process_count` uses the exact device/inode identity of the
already-verified static production supervisor executable. It is not a process
name grep. If an exited process no longer exposes `/proc/<pid>/exe`, the
observer conservatively counts a same-cgroup, fixed-comm zombie
as `unresolved_supervisor_zombie_count`. That fallback can create a fail-closed
false positive; it cannot certify absence.

The fixed Linux `comm` fallback for the current production filename is exactly
`proc17_qa_super`, confirmed from a live production-supervisor probe on
2026-07-29. A native self-test must fail if that relationship drifts.

`direct_zombie_count` is derived from bounded `/proc/<pid>/stat` records whose
parent is the campaign process and whose state is `Z`. The observer does not
call `wait`, `waitpid` or `waitid`: consuming a waitable child would make the
observer a cleanup actor and would erase the residue it is required to record.

`qa_host_mount_count` counts only exact host mountpoints:

```text
/qa
/qa/source
/qa/scratch
```

`owned_source_host_mount_count` is derived separately for the current
fixture-guard-verified root and repository source path. It catches propagation
of the temporary source self-bind, whose host-side mountpoint would not be
named `/qa`. The identity and count are required for `scope = "iteration"` and
`scope = "post_cleanup"`; they must both be nil for baseline/final projections.

`owned_root_set_id` covers only entries matching the fixed test-owned root
grammar and includes their device/inode/mount identities. Unknown entries are
observed, never removed.

## 7. Host Delta

```lua
qa_residue_host_delta_v0 = {
  protocol_version = "qa.residue_host_delta.v0",
  baseline_snapshot_id = string,
  observed_snapshot_id = string,

  fd_opened = non_negative_integer,
  fd_missing = non_negative_integer,
  fd_identity_changed = non_negative_integer,
  fd_flags_changed = non_negative_integer,

  parent_namespace_changed = boolean,
  direct_live_children = non_negative_integer,
  direct_zombies = non_negative_integer,
  matching_supervisor_processes = non_negative_integer,
  unresolved_supervisor_zombies = non_negative_integer,
  qa_host_mounts = non_negative_integer,
  owned_source_host_mounts = non_negative_integer,

  owned_roots_added = non_negative_integer,
  owned_roots_missing = non_negative_integer,

  exact = boolean,
  event_truth_status = "runtime_confirmed",
}
```

`exact` is derived and true iff every numeric delta is zero, namespace identity
is unchanged and all baseline identity sets agree. A caller cannot submit or
override it.

For `scope = "iteration"`, the one opaque, fixture-guard-verified current root
is admitted presence and is excluded from `owned_roots_added`; it must appear
exactly once with the bound identity. Every other matching root is residue. For
`scope = "post_cleanup"`, no root is admitted and the complete root set must
equal the clean baseline.

## 8. Per-Iteration Record

The campaign persists scalars, enums and digests only. It must not retain the
raw Packet, registry, plan, report, services or root object.

```lua
qa_repeated_residue_iteration_v0 = {
  protocol_version = "qa.repeated_residue_iteration.v0",
  campaign_id = string,
  iteration = integer_1_to_32,
  cycle = integer_1_to_8,
  slot = "A" | "B" | "C" | "D",
  fixture_id = closed_fixture_id,

  packet_id = string,
  lineage_id = string,
  generation = 1,
  root_identity_id = "qa-root:" .. sha256(device_inode_mount),
  candidate_seal_id = string,
  transaction_id = string,

  expected_outcome = "accepted" | "rejected",
  observed_outcome = "accepted" | "rejected",
  expected_reason = closed_reason,
  observed_reason = closed_reason,
  report_id = "qa-report:" .. sha256(detached_report),

  finality = {
    source_staging_complete = true,
    candidate_started = true,
    candidate_terminal_observed = true,
    process_tree_reaped = true,
    stdout_eof_observed = true,
    stderr_eof_observed = true,
    scratch_observation_complete = true,
    namespace_cleanup_complete = true,
  },

  memory_finality = "private_allocator_terminal_validated_and_owner_reaped",
  source_disposition = "consumed",
  source_replay = "denied_before_provider",
  root_cleanup = "identity_absent",
  sentinel_exact = true,

  body_root_digest_before = string,
  body_root_digest_after = string,
  body_root_exact = true,

  tracked_body_weak_objects = positive_integer,
  live_body_weak_objects_after_gc = 0,
  tracked_observer_weak_objects = positive_integer,
  live_observer_weak_objects_after_gc = 0,
  post_transaction_host_delta = qa_residue_host_delta_v0,
  post_cleanup_host_delta = qa_residue_host_delta_v0,

  expectation_truth_status = "document_decision",
  observation_truth_status = "runtime_confirmed",
}
```

The post-transaction delta is observed after source finality/replay denial but
before root cleanup, while the verified source identity still exists. The
post-cleanup delta is observed after identity-owned root cleanup and full GC.
The iteration record is valid only after both comparisons. It cannot be emitted
while the fixture root still exists.

## 9. Candidate Finality Join

| Required fact | Writer | Reader | Iteration consequence |
|---|---|---|---|
| candidate terminal | controller | launcher validator | outcome may exist |
| process tree reaped | controller/top supervisor | launcher validator | no live tree claim |
| stdout/stderr EOF | stream collectors | private/public terminal validators | no stream owner remains |
| scratch observation | controller | terminal validator | scratch fact complete |
| namespace cleanup | top supervisor | terminal finalizer | private namespace may terminate |
| launcher reap/result EOF | launcher collector | process normalizer | synchronous provider call complete |

An iteration with any missing finality fact is not a QN20 candidate result. It
belongs to QN19 ambiguity and fails this closed campaign.

## 10. Namespace Residue Derivation

The claim `private_namespace_residue = 0` is legal only from this conjunction:

```text
report.finality.namespace_cleanup_complete == true
report.finality.process_tree_reaped == true
host_delta.direct_live_children == 0
host_delta.direct_zombies == 0
host_delta.matching_supervisor_processes == 0
host_delta.unresolved_supervisor_zombies == 0
host_delta.fd_opened == 0
host_delta.fd_identity_changed == 0
host_delta.parent_namespace_changed == false
host_delta.qa_host_mounts == 0
host_delta.owned_source_host_mounts == 0
```

No single mountinfo row or cleanup boolean substitutes for the conjunction.

## 11. Allocator Terminal Evidence And Memory Finality

The private controller result already carries a stable allocator snapshot. The
existing validator requires:

```text
current_bytes <= peak_bytes <= ceiling_bytes
two post-terminal snapshots agree
denial/system/notification fields are bounded and reason-compatible
```

QN20 does not add a universal `current_bytes == 0` rule. Cooperative return can
run `lua_close`, but controller-owned `output_limit` and `memory_limit` may send
`SIGKILL` before Lua destructors execute. In those rows, a nonzero current value
is historical allocation-at-death inside a process that has already been
reaped; it is not memory retained by the long-lived campaign host.

`memory_finality` is therefore derived from this conjunction:

```text
private allocator terminal snapshot is stable/bounded/reason-compatible
report.finality.process_tree_reaped == true
report.finality.namespace_cleanup_complete == true
host process and descriptor residue channels are zero
```

The public provider report remains unchanged. Peak allocation remains resource
measurement, not residue. No current allocator byte count enters the campaign
ledger or successful output.

Required native controls remain the existing report/allocator controls:

| ID | Input | Expected result |
|---|---|---|
| MQ01 | clean terminal with valid stable snapshot | valid |
| MQ02 | Lua-error terminal with valid stable snapshot | valid |
| MQ03 | output-limit terminal with bounded allocation-at-death | valid after reap |
| MQ04 | memory-limit terminal with bounded denial evidence | valid after reap |
| MQ05 | current greater than peak | rejected as trusted contradiction |
| MQ06 | two terminal snapshots disagree | controller emits no definitive result |

## 12. Lua Liveness

Each iteration creates weak-value sentinels before its inner scope ends. The
body/support set tracks at least:

```text
Packet instance
repository capability registry
provider witness plan
detached provider report
iteration services/support object
owned-root record
```

The observer set tracks every non-durable per-iteration observer object:

```text
opaque owned-root subject
post-transaction opaque snapshot and public projection
post-cleanup opaque snapshot and public projection
```

The ledger stores no strong reference to either set. After the inner body scope
returns and identity-owned root cleanup completes, two full collections must
remove every body/support object while the opaque subject remains intentionally
live for the post-cleanup observation. After that observation and comparison,
the subject, both opaque snapshots and both non-durable public projections are
released and two further full collections run:

```lua
collectgarbage("collect")
collectgarbage("collect")
```

Both weak live counts must be zero at their named boundary. Shared production
provider/environment modules, the observer session, the baseline snapshot and
scalar/digest iteration records are campaign-owned and are excluded. Durable
host deltas are detached plain projections; they contain no observer userdata.

This proves bounded Lua-object retention for the named objects. It does not
prove stable RSS or universal Lua/libc allocation freedom.

## 13. Root And Source Finality

Per iteration:

| Phase | Fact |
|---|---|
| RS1 | a fresh root identity is absent from all earlier iterations |
| RS2 | one fresh Packet/registry materializes and seals it |
| RS3 | one source lease is reserved and attempted |
| RS4 | one definitive report completes source disposition as consumed |
| RS5 | replay of the exact plan is denied before provider launch |
| RS6 | public root projection equals its pre-transaction projection |
| RS7 | private source handle closure is covered by restored parent fd set |
| RS8 | fixture guard removes only the exact owned root identity |
| RS9 | exact path entry is absent and owned-root set returns to baseline |

`source_replay = denied_before_provider` requires the typed
`repository_qa_source_already_reserved` denial from the registry reserve
boundary. That boundary precedes the provider call by construction; PT-T08
remains the counted unit witness that the callback/process is not entered. The
campaign cannot infer replay denial from a generic error.

## 14. Sentinel And Body Ablation

The external sentinel projection contains:

```text
device, inode, mount id, regular-file type, byte length, content digest
```

It is compared after every transaction, again after that iteration's root
cleanup, and before the final snapshot after final GC. Its path and handle do
not enter candidate source or public output. Identity-owned sentinel cleanup is
the last protected action and must itself prove the exact path absent before a
success line is printed.

The body/root ablation digest covers:

```text
Packet status, operator and tick
trace and revision vector
tension, death and manifest
Packet-local budget and loss
public repository root projection
```

Private source-lease lifecycle is intentionally excluded; that private state is
supposed to move from available to terminal.

## 15. Campaign State Machine

```text
declared
  -> production_ready
  -> clean_precondition
  -> baseline_recorded
  -> iteration_open (x32)
  -> candidate_final
  -> replay_denied
  -> host_quiescence_observed
  -> root_cleaned
  -> body_gc_observed
  -> residue_compared
  -> observer_gc_observed
  -> final_gc_observed
  -> sentinel_cleaned
  -> complete
```

Illegal transitions:

```text
next iteration before previous root cleanup;
host comparison while observer scan fd is open;
root cleanup before current-source mount propagation was observed;
iteration record before source finality;
aggregate completion with one missing channel;
cleanup of an unowned root;
observer kill/reap/unmount as repair;
provider reload between iterations;
observer subject or snapshot retained across iterations;
successful summary after any mismatch.
```

On failure, protected cleanup may remove only the current exact fixture root and
sentinel. Detected process/fd/mount residue is not repaired by the observer.

## 16. Summary Schema

```lua
qa_repeated_residue_summary_v0 = {
  protocol_version = "qa.repeated_residue_summary.v0",
  campaign_id = string,
  declared = 32,
  executed = 32,
  matched = 32,
  accepted = 8,
  ordinary_rejected = 8,
  output_terminated = 8,
  memory_terminated = 8,
  replay_denials = 32,
  replay_launches = 0,

  fd_residue = 0,
  process_residue = 0,
  namespace_residue = 0,
  host_mount_residue = 0,
  root_residue = 0,
  source_residue = 0,
  memory_finality_mismatches = 0,
  lua_object_residue = 0,
  sentinel_deltas = 0,
  body_root_deltas = 0,

  final_snapshot_exact = true,
  expectation_truth_status = "document_decision",
  observation_truth_status = "runtime_confirmed",
}
```

Successful bounded output:

```text
proc17 QN20 residue campaign ok: declared=32 executed=32 matched=32 accepted=8 ordinary_rejected=8 output_terminated=8 memory_terminated=8 replay_denials=32 replay_launches=0 fd=0 process=0 namespace=0 mount=0 root=0 source=0 memory_finality=0 lua=0 sentinel=0 body=0
```

No successful summary contains raw paths, pids, fds, output or candidate bytes.

## 17. Test-Only Observer Authority

Allowed:

```text
same-process `/proc/self/fd` observation;
bounded `/proc` process census;
fixed production-supervisor executable identity comparison;
same-cgroup fixed-comm zombie uncertainty census;
parent namespace identity observation;
host mountinfo observation for exact /qa mountpoints;
host mountinfo observation for one fixture-guard-verified current source root;
fixed test-root prefix census;
opaque snapshot and typed delta assembly.
```

Forbidden:

```text
candidate execution;
production request/result participation;
source lease or root disposition;
Packet writes;
kill, wait/reap, unmount or global deletion as repair;
arbitrary or unverified caller-selected path/pid/fd/fault input;
production linkage or exported production symbol;
raw authority in successful output.
```

If `/proc` or required exact observations are unavailable, QN20 fails as an
unsupported campaign environment. It does not silently weaken the claim.

## 18. Writers And Readers

| Fact | Writer | First reader | Truth status |
|---|---|---|---|
| fixed schedule | this TABLE | campaign enumerator | document_decision |
| candidate outcome/finality | production controller/launcher | process normalizer | runtime_confirmed |
| allocator/process memory finality | allocator telemetry + private validator + reap owner | campaign comparator | runtime_confirmed |
| source disposition | repository registry | report/replay assertion | runtime_confirmed |
| root cleanup absence | identity guard | campaign comparator | runtime_confirmed |
| fd/process/ns/mount projection | test-only observer | campaign comparator | runtime_confirmed |
| body/support weak liveness | Lua collector/body weak table | campaign comparator before post-cleanup capture | runtime_confirmed |
| observer weak liveness | Lua collector/observer weak table | campaign comparator before next iteration | runtime_confirmed |
| sentinel projection | identity guard | campaign comparator | runtime_confirmed |
| body/root digest | pure campaign derivation | campaign comparator | runtime_confirmed |
| iteration expectation fields | TABLE schedule | campaign comparator | document_decision |
| iteration observation fields | campaign assembler | summary assembler | runtime_confirmed |
| summary expectation fields | TABLE schedule | QN20 control/red matrix | document_decision |
| summary observation fields | summary assembler | QN20 control/red matrix | runtime_confirmed |

## 19. Required Falsifiers

| ID | Deliberate test-only defect | Required observation |
|---|---|---|
| RF01 | exchange one baseline fd for one retained fd | identity delta despite equal count |
| RF02 | leave direct child live | process residue |
| RF03 | leave direct zombie | direct-zombie residue |
| RF04 | execute the exact production supervisor and hold it live | exact supervisor-process residue |
| RF04a | retain a same-cgroup zombie with fixed comm `proc17_qa_super` and unreadable executable identity | unresolved-supervisor-zombie residue |
| RF05 | retain namespace/detached-mount fd | fd/namespace residue |
| RF06 | add host `/qa` mountpoint in isolated test namespace | host-mount residue |
| RF07 | skip exact root cleanup | root residue |
| RF08 | let replay reach provider | replay launch count nonzero |
| RF09 | make allocator current exceed peak or make terminal snapshots disagree | definitive terminal rejected |
| RF10 | retain one tracked body/support Lua object | body weak live count nonzero |
| RF10a | retain one observer subject or snapshot | observer weak live count nonzero |
| RF11 | mutate sentinel | sentinel delta |
| RF12 | mutate Packet/public root/economics | ablation delta |
| RF13 | link observer marker into production artifact | production exclusion failure |
| RF14 | check only final iteration | harness self-test rejection |
| RF15 | reload provider inside loop | provider identity/reload rejection |
| RF16 | leave an observer-owned process/mount scan descriptor open before the final fd scan | observer self-residue or typed capture failure |

Falsifiers execute only in dedicated test identities. They do not enter the
production provider, supervisor, launcher or candidate corpus.

## 20. Production Exclusion

Production artifact/API scans must reject:

```text
QN20 campaign id or summary prefix
QN20 fixture schedule ids as selector vocabulary
residue observer module/symbol names
test-root census API
fd/process/mount snapshot API
falsifier ids or selectors
```

The production supervisor retains its existing stable/bounded allocator
validation and process/finality vocabulary. It contains no campaign or observer.

## 21. Promotion Delta

Input:

```text
ordinary native QA: 19 green / 0 red / 1 deferred
expected-red QA matrix: 43 green / 41 red
QN20: red
```

Output:

```text
ordinary native QA: 20 green / 0 red / 0 deferred
expected-red QA matrix: 44 green / 40 red
QN20: green
```

Only QN20 may change. QN01-QN19 remain green. Every QE/QV/body/completion/router
control retains its previous status.

## 22. Verification Battery

Future implementation must run:

```text
red-first QN20 observer and campaign falsifiers
make -C native qa-supervisor-leak-loop-test
lua tests/test_qa_native_supervisor.lua
lua tests/test_qa_provider_witness.lua
lua tests/red_qa_hand.lua              # exact expected nonzero 44/40
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
make -C native qa-static-closure-test
production symbol/string/API exclusion audit
ASan/UBSan focused observer/native boundary
LeakSan when host permits it, supporting only
GCC -fanalyzer on changed native observer/validator code
luac -p on changed Lua files
git diff --check
```

## 23. Anticipated Implementation Surface

Expected, not yet authorized:

```text
native/tests/proc17_qa_residue_observer.c or equivalent test-only module
native/tests/test_proc17_qa_residue_observer.c
tests/run_qa_repeated_residue_campaign.lua
tests/support/qa_provider_witness.lua shared-provider campaign context
tests/support/owned_temp_root.lua exact absence/census support
native/Makefile qa-supervisor-leak-loop-test
tests/test_qa_native_supervisor.lua QN20 promotion
tests/red_qa_hand.lua exact 44/40 frontier
```

CRYSTALL may refine file placement. It may not weaken the identities, schedule,
observation phases, named channels or promotion delta without a TABLE amendment.

## 24. Cross-Table Audit Questions

Before crystallization, audit:

```text
A1 Does exact fd identity observation avoid exporting live fd authority?
A2 Can the process census detect direct zombies, orphaned supervisor images and
   fail closed when zombie executable identity is unreadable?
A3 Is namespace destruction derived only from facts owned by process/fd/mount readers?
A3a Does mount observation include the verified current source path as well as
    fixed `/qa` mountpoints?
A4 Does memory finality distinguish bounded allocation-at-death from memory
   retained by a live process or the long-lived campaign host?
A5 Can weak sentinels be collected without retaining raw reports in the ledger?
A5a Are observer subjects/snapshots themselves covered before the next iteration?
A6 Does replay denial prove no second provider launch rather than generic failure?
A7 Is root absence proved by identity instead of path deletion?
A8 Does one loaded provider callable/value surface remain exact across all 32 transactions?
A9 Can every test observer/falsifier be excluded from production artifacts?
A10 Does the campaign leave Packet/public root/economics unchanged?
A11 Does any current QN17-QN19 contract conflict with the four-case schedule?
A12 Is every written record assigned a named reader?
```

## 25. Gate

```text
CHAOS complete: yes
TABLE complete: yes
cross-table audit: satisfied
cross-table audit record:
  docs/00_chaos/qa_e10_qn20_table_cross_audit_2026-07-29.md
CRYSTALL authorized: yes
runtime implementation authorized by this TABLE alone: no
subsequent implementation authority:
  docs/00_chaos/qa_e10_qn20_crystall_cross_audit_2026-07-29.md
  docs/02_crystall/blueprints/qa_repeated_residue_campaign.v0.md
Packet/body QA authority: forbidden
```
