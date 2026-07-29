# QA E10 / QN20 Repeated Residue Notes

Status:

```text
layer: CHAOS
date: 2026-07-29
chapter: 8.5.5E10
scope: repeated private provider transactions and named host residue only
runtime authority: none
Packet/body QA authority: forbidden
source:
  docs/00_chaos/second_qa_hand_hostile_campaign_notes_2026-07-28.md
  docs/00_chaos/qa_e9_qn19_cleanup_ambiguity_notes_2026-07-28.md
  docs/03_manifest/qa_qn19_cleanup_ambiguity_e9.v0.md
next layer:
  docs/01_table/yellowprints/qa_repeated_residue_campaign_yellowprint.v0.md
```

## 0. Why QN20 Exists

QN17 proves that one hostile candidate remains contained. QN18 proves that one
trusted runtime failure does not become a candidate verdict. QN19 proves that
one ambiguous cleanup does not become a clean terminal story.

None of them proves closure under repetition.

A provider can be correct once and still accumulate one descriptor, child,
namespace owner, source handle, temporary root or Lua object per transaction.
The first run is then honest while the thirty-second run is a different
machine. QN20 asks one bounded question:

```text
Does the same long-lived host process return every named transient authority
channel to its admitted baseline after each fresh production QA transaction?
```

This is not a universal leak theorem. It is an exact campaign over named
channels with named writers and readers.

## 1. Current Provisional Contract Is Too Weak

The older TABLE/CRYSTALL sections say "32 clean/error transactions" and
"descriptor count returns to baseline". Those phrases leave false-green paths:

```text
32 separate Lua processes can hide all parent-process accumulation;
reloading the provider each iteration can hide retained native state;
an equal fd count can hide one closed baseline fd plus one leaked new fd;
host mountinfo cannot directly observe a private child mount namespace;
stable RSS can hide leaks and allocator caches can imitate leaks;
clean/error alone does not repeat a forced resource-termination path;
checking only after iteration 32 can hide transient monotonic accumulation;
one cleanup sweep at the end can repair evidence instead of observing it.
```

QN20 therefore needs a precision contract before implementation.

## 2. One Long-Lived Host

The campaign runs in one ordinary Lua 5.4 process. Before the baseline it:

```text
builds production QA artifacts once;
loads the production repository provider once;
loads the production QA provider once;
probes and freezes one environment identity once;
loads one test-only residue observer once;
creates one test-owned host sentinel once.
```

The loop must not clear `package.loaded`, rebuild the provider, replace the
provider, or spawn a fresh campaign process per iteration. Every transaction
gets a fresh Packet, registry, sealed root, source lease and transaction id, but
all transactions cross the same already-loaded provider boundary.

The residue observer is trusted test instrumentation. It is absent from the
production launcher/supervisor ABI and cannot execute a candidate, dispose a
source lease or mutate Packet state.

## 3. Closed 32-Life Schedule

The campaign repeats one four-case production schedule eight times:

| Slot | Existing inert fixture | Expected provider outcome | Cleanup shape exercised |
|---|---|---|---|
| A | `candidate-clean-exit` | accepted / `expected_exit` | ordinary success |
| B | `candidate-lua-error` | rejected / `unexpected_exit` | language failure |
| C | `candidate-stdout-flood` | rejected / `output_limit` | bounded output termination |
| D | `candidate-allocator-exhaustion` | rejected / `memory_limit` | allocator denial termination |

Thus:

```text
iterations = 32
accepted = 8
ordinary rejected = 8
output terminated = 8
memory terminated = 8
fresh roots = 32
fresh one-use source leases = 32
```

CPU, wall, scratch and policy fixtures remain QN17 evidence. QN20 does not need
to repeat every hostile fixture; it must repeat materially different cleanup
shapes.

## 4. What "Residue" Means Here

Residue is not one boolean. It is a vector:

```text
R(i) = {
  parent_descriptor_delta,
  live_or_direct_zombie_process_delta,
  private_namespace_owner_delta,
  host_mount_delta,
  owned_root_delta,
  source_lease_finality_delta,
  candidate_memory_finality_delta,
  lua_object_liveness_delta,
  host_sentinel_delta,
  Packet/root/economics_delta,
}
```

QN20 accepts iteration `i` only when every named member is zero or exact. It
does not accept an aggregate `residue=0` whose contributing records are absent.

## 5. Descriptor Residue

Count equality is insufficient. The observer takes an exact parent-process fd
snapshot after it has closed its own scan descriptor. Each member is identified
without exporting authority to Lua or stdout:

```text
fd number
fstat object identity and type
bounded readlink-target digest where available
close-on-exec state
```

The observer retains the set privately and returns only a snapshot identity and
typed difference counts. After every root cleanup:

```text
after_fd_set_id == baseline_fd_set_id
opened_since_baseline = 0
missing_from_baseline = 0
changed_identity_at_same_number = 0
```

This channel catches leaked repository handles, pipes, pidfds, timerfds,
detached mount descriptors and namespace descriptors held by the long-lived
host process.

## 6. Process And Namespace Residue

No one observation proves process finality. QN20 joins three owners:

```text
provider report:
  candidate terminal + process tree reaped + namespace cleanup complete

host observer:
no direct live child or direct zombie remains after the synchronous call
no process with the exact production supervisor executable identity remains
no same-cgroup fixed-comm supervisor zombie remains unresolved when its
  executable link is no longer readable

descriptor observer:
  no pidfd, namespace fd or detached mount fd was added to the parent set
```

The production supervisor binary identity is read before the loop. A dirty
precondition with an already-running matching process is a campaign failure,
not part of the baseline.

Private `/qa/source` and `/qa/scratch` mounts are not expected to appear in the
host namespace. Their destruction is derived from:

```text
all namespace processes are gone;
no host descriptor retains the namespace or detached mount;
no exact /qa mountpoint appeared in the host namespace.
```

This is stronger than grepping host mountinfo for a child-private mount that the
host cannot normally see. The campaign separately checks that the host
namespace gained no `/qa`, `/qa/source` or `/qa/scratch` mountpoint and no
mountpoint equal to the fixture-guard-verified current source/root path. The
latter catches accidental propagation of the temporary source self-bind that
exists before pivoting into `/qa`.

The observer records residue but does not kill a discovered process or unmount
anything. An observer that repairs the world would erase the evidence it is
supposed to test.

## 7. Root And Source Residue

Each iteration uses one fresh identity-owned fixture root. Cleanup is legal
only with the original tuple:

```text
validated bounded path
device
inode
mount id
```

After cleanup, the guard proves the exact path entry is absent. The campaign
also compares the complete test-root prefix identity set with its clean
precondition; it never deletes an unknown root to make the count pass.

The source transaction is complete only when:

```text
the report says source disposition consumed;
pre/post inventory ids equal the candidate seal inventory;
a replay of the same witness plan is denied before provider launch;
the public root projection remains exactly unchanged;
the parent fd set proves the private repository source handle was closed.
```

All four scheduled candidate paths are definitive candidate reports, so every
QN20 source is consumed. Quarantine behavior remains QN19 evidence and is not
laundered into this campaign.

## 8. Memory Residue Without RSS Theology

QN20 names one exact host-memory channel and one process-finality derivation:

1. The Lua harness keeps weak sentinels for iteration-owned Packet, registry,
   plan, report and support objects. After the iteration scope ends and two full
   collections run, no sentinel may remain live.
2. Reaped candidate/controller/supervisor processes imply their address spaces
   no longer exist. The private allocator snapshot remains bounded terminal
   evidence, not a host-residue counter.

An important audit correction applies here. Cooperative candidate return calls
`lua_close`, but `output_limit` and `memory_limit` are owned by the controller,
which may kill the candidate before Lua destructors run. Their terminal
`current_bytes` can therefore be nonzero while the process has already been
reaped and all of its memory has ceased to exist. Requiring zero would reject
honest forced termination and confuse historical allocation-at-death with live
host residue.

QN20 instead requires the existing private snapshot to remain stable, bounded
and causally compatible with its terminal reason, then joins it with complete
process-tree reap and zero host process residue. It adds no public allocator
field and no new production allocator rule.

QN20 explicitly does not claim:

```text
stable parent RSS;
zero allocator caching;
zero leak in every libc/Lua dependency;
universal native heap freedom;
performance stability.
```

ASan/UBSan and LeakSan, where available, remain separate supporting probes. A
stable RSS sample is neither required nor accepted as the QN20 proof.

## 9. Host Sentinel And Body Ablation

One sentinel outside every candidate and fixture root is created before the
loop. Its identity, type, size and content digest must remain exact after every
iteration and final cleanup.

Before each provider transaction, the campaign derives one digest over:

```text
Packet status/operator/tick/trace/revisions/tension/death/manifest;
Packet-local budget and loss/economics;
public repository root projection.
```

The same digest is required after source finality. Private source-lease state is
allowed to change and is intentionally absent from the public root projection.
No QN20 observer may write a Packet event.

## 10. Observation Phases

The campaign has explicit phases:

```text
P0 build/load/probe trusted components once
P1 reject dirty process/root/mount preconditions
P2 create sentinel and take exact baseline

for each iteration:
  P3 grow fresh sealed candidate root
  P4 derive pre-transaction body/root digest
  P5 execute once through production provider witness
  P6 validate outcome, finality, source and memory-finality relation
  P7 attempt replay and require pre-launch denial
  P8 observe host quiescence and current source mount propagation before cleanup
  P9 leave iteration scope and identity-clean its root
  P10 run full GC and compare every named residue channel again

P11 run final full GC and final comparison
P12 identity-clean sentinel
P13 print bounded summary and exit
```

The campaign checks before and after every identity-owned root cleanup, not only
at P11. Final cleanup cannot
hide a monotonic leak that existed during the sequence.

## 11. Trusted Observer Boundary

The residue observer may:

```text
read `/proc/self/fd` and bounded process metadata;
read the host process's mountinfo;
compare the exact fixed supervisor executable identity;
inspect only the fixed test-root prefix;
inspect one current root/source path only after validating its complete fixture
  identity tuple;
return opaque snapshot ids and typed counts.
```

It may not:

```text
run a candidate;
accept an arbitrary/unverified caller path, pid, fd or fault selector;
kill, reap or unmount discovered residue;
delete an unknown root;
write Packet/root/source disposition;
enter the production launcher or supervisor closure;
emit raw paths, pids or fds in the successful public summary.
```

Detailed failure diagnostics remain bounded test evidence and use identities or
digests, not live handles.

## 12. Named Writers And Readers

| Record | Writer | First reader | Fate |
|---|---|---|---|
| candidate finality | production supervisor/launcher | strict process normalizer | joined into provider report |
| allocator terminal snapshot | candidate allocator telemetry | private terminal validator | stable/bounded reason evidence; not host residue |
| source disposition | repository registry | report/replay assertion | terminal once |
| fd snapshot | test-only host observer | per-iteration comparator | discarded after campaign |
| process census | test-only host observer | per-iteration comparator | discarded after campaign |
| host mount projection | test-only host observer | per-iteration comparator | discarded after campaign |
| owned-root absence | fixture identity guard | per-iteration comparator | discarded after campaign |
| weak liveness | Lua GC + weak table | per-iteration comparator | discarded after campaign |
| sentinel projection | fixture identity guard | per-iteration comparator | discarded after campaign |
| body/root digest | campaign derivation | per-iteration comparator | discarded after campaign |
| QN20 expectation fields | TABLE schedule | campaign comparator | document_decision |
| QN20 observation fields | campaign assembler | native control/red battery | runtime_confirmed |

No written QN20 record is admitted without a named reader.

## 13. False-Green Matrix

| False proof | Why it lies | Required rejection |
|---|---|---|
| 32 fresh campaign processes | process exit cleans the leak | one long-lived process required |
| provider reloaded each iteration | unload/reinit hides retained state | one provider identity required |
| fd count equality | swapped identity can preserve count | exact set comparison |
| final-only observation | late cleanup hides accumulation | check every iteration |
| stable RSS | allocator caching and leaks are confounded | RSS excluded |
| host mount grep only | child-private namespace is invisible | process + fd + host-mount join |
| cleanup observer kills leftovers | repair erases evidence | observer is read-only |
| reused root/source | one transaction is replayed, not repeated | 32 fresh identities |
| raw report retained in ledger | harness itself creates Lua retention | retain scalars/digests only |
| test/fault provider | production path is bypassed | production identity required |
| only clean/error fixtures | forced cleanup path never repeats | four-case schedule required |
| aggregate residue boolean | missing channels can disappear | named vector required |

## 14. Falsifiers

The eventual red-first harness must demonstrate that it detects at least:

```text
one retained descriptor with unchanged total count;
one direct zombie;
one matching supervisor process;
one retained namespace or detached-mount descriptor;
one host /qa mountpoint;
one exact root left after cleanup;
one source replay that reaches the provider;
one impossible allocator snapshot (`current > peak` or unstable terminal pair);
one strongly retained iteration object after GC;
one changed sentinel;
one changed Packet/root/economics digest;
one QN20 id or observer symbol in a production artifact.
```

Test-only falsifiers cannot enter production candidate bytes, provider input,
launcher ABI or supervisor ABI.

## 15. Expected Promotion

Before E10:

```text
ordinary native QA: 19 green / 0 red / 1 deferred
expected-red QA matrix: 43 green / 41 red
QN20: red
```

After E10, and only after the complete campaign:

```text
ordinary native QA: 20 green / 0 red / 0 deferred
expected-red QA matrix: 44 green / 40 red
QN20: green
```

No QE/QV/body/completion/router control may change.

## 16. Non-Claims

QN20 does not create:

```text
Packet-owned QA request or execution authority;
qa_check or qa_verdict;
software acceptance;
retry/resume policy;
repository cleanup/compost policy;
general command execution;
universal host or heap leak freedom.
```

It closes the repeated-host-residue question for the existing private provider
boundary only.

## 17. Proposed E10 Slices

```text
E10.0 CHAOS diagnosis and precision boundary                 complete
E10.1 TABLE contract and old-contract supersession           complete
E10.2 cross-table audit + CRYSTALL + cross-crystall gate      complete
E10.3 red observer/harness falsifiers                         complete
E10.4 memory-finality join + test-only observer               next
E10.5 32-transaction production campaign                      pending
E10.6 production exclusion, full batteries and exact colors   pending
E10.7 MANIFEST promotion and current-state update             pending
```

Code is not authorized by this CHAOS document.

E10.3 runtime evidence is recorded in
`docs/00_chaos/qa_e10_qn20_red_observer_contract_2026-07-29.md`.
