# QA E10 / QN20 Observer And Fixture Implementation Checkpoint

Status:

```text
layer: CHAOS evidence/checkpoint
date: 2026-07-29
chapter: 8.5.5E10.4
source:
  docs/01_table/yellowprints/qa_repeated_residue_campaign_yellowprint.v0.md
  docs/02_crystall/blueprints/qa_repeated_residue_campaign.v0.md
completed implementation slices: C10.1, C10.2, C10.3
production semantic change: none
Packet/body QA authority: unchanged and forbidden here
QN20 promotion: not authorized
truth status:
  selected contracts: document_decision
  implementation observations: runtime_confirmed
```

## 1. Boundary Reached

E10.3 left 22 executable red observer controls and no implementation. E10.4
supplies the test-only reader behind that fixed boundary:

```text
native/tests/proc17_qa_residue_observer.c
native/tests/proc17_qa_residue_observer_lua.c
native/tests/proc17_qa_residue_observer.h
```

The implementation is one separately built Lua module and one separately
loaded C ABI. It is not linked into the production supervisor, launcher,
repository provider, Packet body or runtime modules.

The observer is read-only. It owns no operation capable of killing or reaping a
process, closing a foreign descriptor, unmounting a namespace or deleting a
root. Discovery and repair remain materially separate.

## 2. Host Facts Now Observable

One opaque observer session fixes the current campaign process identity,
cgroup identity and exact production-supervisor file identity. Captures derive
bounded normalized records for:

```text
exact parent fd number/identity/flags/link-digest set
six parent namespace device/inode identities
direct live children
direct zombies
exact production-supervisor executable matches
unresolved fixed-comm supervisor zombies
fixed host /qa mountpoints
the verified current source host mountpoint
all /tmp/proc17-repository-hand-XXXXXX identities
```

Process, namespace, mount and root scans close before the parent-fd scan runs
last. The fd census excludes only its own currently open census descriptor.
RO15 proves that an observer descriptor retained before this final scan becomes
visible residue rather than disappearing behind observation order.

Snapshots are immutable opaque userdata. Lua receives only tagged digests,
counts, scope and `runtime_confirmed`; it receives no raw pid, fd, path, mount
record or native handle. Comparison is baseline-directed and session-bound.
The same baseline can lawfully read iteration, post-cleanup and final captures.

`post_cleanup` now has its own physical guard: the previously bound basename
must be absent. A caller cannot claim the phase while the old root or a
replacement at that name remains live.

## 3. Fixture Finality Added

`native/tests/proc17_fixture_guard.c` gained only the bounded test operations
authorized by CRYSTALL:

```text
absent PATH DEV INO MNT
sentinel-create
sentinel-probe PATH DEV INO MNT SIZE SHA256
sentinel-cleanup PATH DEV INO MNT
```

`absent` validates the old root grammar and requires a no-follow,
parent-relative lookup to return `ENOENT`. Any present replacement, including
a symlink, fails.

The external sentinel has a disjoint
`/tmp/proc17-qa-sentinel-XXXXXX` grammar and fixed bytes. Creation publishes its
device, inode, mount id, size and SHA-256. Probe validates all five facts;
cleanup validates the same fixed object, unlinks it by its parent and succeeds
only after a second no-follow lookup proves absence. It never enters candidate
source or an owned repository root.

`tests/support/owned_temp_root.lua` now provides detached identity, exact
absence and two-phase cleanup. `with_root_phases` drops its local raw root
reference before invoking the post-cleanup callback and passes only the prior
identity projection. `use_prebuilt_helper` runs the fixed self-test but never
invokes Make. The focused Make target now builds the helper before Lua starts.

## 4. Corrections Found By Execution

Implementation corrected five assumptions without weakening the selected
contract:

1. Tagged SHA-256 ids require 96 bytes, not the original 72-byte red-contract
   placeholder.
2. Root basenames are length-checked before allocation and copied exactly;
   compiler inference is not treated as proof of the grammar.
3. Empty normalized root/fd sets do not call `qsort` with a null base. UBSan
   found this boundary before promotion.
4. The Lua observer test no longer invokes Make inside its process; prebuild
   ownership is now material rather than prose.
5. `post_cleanup` rejects a still-present subject basename inside the observer,
   independently of the fixture guard's absence proof.

One nested expected-red run observed `dirty_precondition` immediately after
the older native campaigns. The original red harness did not print the dirty
channel, so the exact transient was not recoverable. An immediate direct
QN19-to-observer repetition and subsequent dedicated repetitions were clean.
The harness now prints only the named dirty channel counts on recurrence, with
no raw authority. No retry, delay or weakened baseline was introduced.

## 5. Runtime Evidence

Observed after the final E10.4 corrections:

```text
make -C native qa-residue-observer-test
  native RO01-RO15: green=15 red=0
  Lua RL01-RL07:    green=7 red=0

make -C native fixture-test
  proc17_fixture_guard ok

GCC -fanalyzer
  observer core: clean
  Lua binding: clean
  native falsifier harness: clean
  fixture guard: clean

ASan + UBSan
  native observer/falsifier corpus: green=15 red=0
  Lua binding corpus: green=7 red=0
  fixture guard self-test: green
  LeakSanitizer is unavailable under the host ptrace boundary; ASan/UBSan ran
  with leak scanning disabled, while explicit fd/root/process controls stayed on

lua tests/run.lua
  107 suites, all tests ok

lua tests/smoke_mortality_battery.lua
  8/8

lua tests/test_qa_native_supervisor.lua
  green=19 red=0 skip=1

lua tests/red_qa_hand.lua
  expected nonzero
  exact control matrix: green=43 red=41 skip=0

production artifact scan
  no observer protocol marker or exported observer symbol in
  proc17_qa_supervisor, proc17_qa_launcher.so or proc17_repository_fs.so
```

The staged QN20 target now advances through the observer successfully and
stops at exactly the next missing organ:

```text
tests/run_qa_repeated_residue_campaign.lua: absent
```

## 6. Non-Claims

E10.4 does not claim that:

```text
one production-provider transaction has passed the joined residue protocol;
provider/environment identity is frozen across repeated transactions;
body/support or observer userdata has passed the campaign GC boundaries;
allocator-at-death evidence has been joined to host-process finality;
the fixed 4-case or 32-transaction schedule exists;
QN20 is green or promotable;
Packet-owned request, receipt, check evidence or verdict exists.
```

The private allocator validator already exists in the production QA report and
the host observer now supplies the other side of memory finality. Their
per-iteration conjunction remains a future campaign fact, not an inferred
property of this checkpoint.

## 7. Next Step

E10.5 starts with C10.4: split `qa_provider_witness` into compatibility build
support and one prebuilt, one-load campaign context. It must freeze repository
provider, QA provider, callable surface and environment identity before the
baseline. Only then may C10.5 grow one clean joined transaction, one exact
four-slot cycle and finally the closed 32-transaction schedule.

QN20 changes color only after the full schedule, GC boundaries, sentinel,
replay denial, allocator/process join, final snapshot and production-exclusion
controls are all green together.
