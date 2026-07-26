# Second QA Hand First Candidate Transaction Notes

Status:

```text
layer: CHAOS
date: 2026-07-26
roadmap: preparation for 8.5.5D
reasoning tier: Ultra
tier reason: first real candidate execution, mount authority and truth boundary
runtime implementation authorized by this note: no
candidate execution through the Packet body: forbidden
router/verdict/completion promotion: forbidden
```

Primary sources:

```text
docs/00_chaos/second_qa_hand_threat_model_2026-07-23.md
docs/00_chaos/second_qa_hand_source_bridge_results_2026-07-23.md
docs/00_chaos/second_qa_hand_environment_probe_results_2026-07-23.md
docs/01_table/yellowprints/qa_execution_capability_yellowprint.v0.md
docs/02_crystall/blueprints/qa_execution_capability.v0.md
docs/02_crystall/blueprints/qa_native_supervisor.v0.md
```

## 0. Mission

Step `8.5.5C` proved that the exact launcher and static supervisor can construct
the required isolated world. It deliberately mounted only one immutable
internal probe fixture and returned only `qa.environment.v0`.

Step `8.5.5D` must answer the next physical question:

```text
Can one real sealed repository source lease enter that exact isolated world,
run one silent clean Lua entrypoint or one failing Lua entrypoint, and return an
exact clean candidate report without giving Packet or candidate any new host
authority?
```

This is not yet the question:

```text
Can the Packet request QA, receive qa_check, derive qa_verdict or route from it?
```

Those are body-authority questions. They remain in `8.5.6`.

## 1. Current Runtime Boundary

Runtime-confirmed before this note:

```text
one exact candidate seal owns one terminal repository root
repository registry can reserve one opaque one-use QA source lease
the source callback receives the private repository userdata only
the launcher validates the shared native userdata ABI
the launcher can duplicate and revalidate the exact repository root fd
the exact static supervisor can cross the execveat memory-erasure boundary
the supervisor can build and destroy the required isolated Linux world
the production provider can probe that world
```

Still absent:

```text
native RUN request/result implementation
real repository source staging inside the mount namespace
candidate entrypoint execution through production provider
clean/rejected provider report normalization
private grant begin/receipt transaction
body request/check/failure/verdict writers
tree readiness from QA evidence
```

`runtime/qa_provider.lua` therefore still calls a native function whose only
legal result is `candidate_execution_not_promoted`.

## 2. The Source-Mount Contradiction Found In Step C

The crystallized native design says:

```text
bind /proc/self/fd/3 directly as /qa/source
```

The exercised 2026-07-26 host says:

```text
bind /proc/self/fd/3                         -> EINVAL
bind /proc/self/fd/3/.                       -> EINVAL
open_tree(fd, "", AT_EMPTY_PATH | CLONE)    -> EINVAL
open_tree(fd, ".", CLONE)                   -> EINVAL
open_tree("/proc/self/fd/3", CLONE)         -> EINVAL
```

The existing environment probe recovered by reading the absolute pathname from
the already verified fd and binding that pathname. That treatment is bounded
and honest for the fixed internal probe fixture, but it is not sufficient for
an arbitrary candidate. A repository can itself live below `/tmp`, while the
supervisor intentionally covers host `/tmp` with a private tmpfs before it
constructs the candidate root.

Copying source into scratch would avoid the mount problem but would change the
tested object and create a second tree materializer. That is rejected for v0.

## 3. Runtime Finding: Detached Source Staging Works

A second isolated mount experiment tested a namespace-owned staging sequence:

```text
1. inherit exact source fd 3
2. enter private user + mount namespaces
3. derive a transient absolute locator from /proc/self/fd/3
4. verify the locator resolves to the original fd identity
5. bind the source locator onto itself inside the private mount namespace
6. open_tree(CLONE | CLOEXEC) that new namespace-owned bind mount
7. detach the temporary self-bind
8. retain only the detached mount fd
9. apply RDONLY | NOSUID | NODEV | NOEXEC to the detached mount fd
10. cover host /tmp with private tmpfs and construct the empty root
11. move_mount the detached source mount into /qa/source
12. verify the attached source object and staged mount identity
```

Observed twice, including a source physically located below host `/tmp`:

```text
self-bind -> detached open_tree -> move_mount: success
source device + inode after move: exact match
source path hidden by private /tmp after staging: no effect
create file through staged source: EROFS
```

No host directory is created by staging. The temporary self-bind and its detach
exist only in the new private mount namespace. Candidate code does not yet
exist while the source mount is writable to trusted setup mechanics.

## 4. Selected Source-Staging Law

The authority remains the already-open repository fd, not the transient
pathname.

The pathname is admitted only as a staging observation under all of these
conditions:

```text
it is derived internally from the exact inherited fd
it never enters Lua, request wire, result wire, body trace or corpus
it is absolute, bounded and not marked deleted
its pre-bind device + inode + original mount id equal the source fd
the detached tree device + inode equal the source fd
the temporary self-bind is always detached before host paths are hidden
the detached tree is made read-only/noexec before candidate creation
the moved mount keeps the staged mount identity and source device + inode
any mismatch is infrastructure failure before candidate start
```

Mount cloning necessarily creates a new mount id. Therefore two identities
must not be conflated:

```text
original root identity:
  device + inode + original mount id
  proves the fd still names the sealed repository authority

staged mount identity:
  new mount id plus the same device + inode
  proves the detached mount observed before move is the mount attached after move
```

Demanding that the cloned mount id equal the original mount id would be a false
identity law. Accepting only matching device + inode without tracking the new
staged mount id would be too weak.

The existing same-authority host limitation remains unchanged: an actor with
the same host authority could race and restore a path entirely between bounded
observations. Candidate/task data cannot perform that substitution, and every
observable mismatch fails closed.

## 5. Environment Identity Consequence

Detached staging is part of isolation policy, not an invisible implementation
detail.

Step D must therefore:

```text
add detached-source-staging to the required probe feature set
exercise the same staging path in probe_environment
change the policy digest and supervisor build identity
produce a new qa.environment.v0 identity
leave the step-C environment record historical
```

An old QA contract bound to the step-C environment does not silently migrate.
It becomes not-ready under the existing environment law. A fresh build birth
may bind the new measured environment.

## 6. Step D Authority Ceiling

Step D is a provider-physics slice, not the full body transaction.

Authorized after its TABLE/CRYSTALL amendments and tests:

```text
trusted test harness creates one disposable real repository through the first hand
the repository is sealed through the existing candidate-seal boundary
one exact QA source lease is reserved for one test-owned transaction identity
one source callback performs pre-inventory, native run and post-inventory
the production launcher/supervisor executes one fixed Lua profile
the strict provider returns one detached candidate report to the trusted harness
```

Still forbidden:

```text
qa_capability.mint/begin promotion
Packet-triggered provider dispatch
private execution receipt commit
qa_check_request body event as execution authority
qa_check or qa_execution_failure body event
qa_verdict
completion/work-layer/tree readers
```

This split is required by the existing split-brain law. Committing a private
receipt before the body outcome writer exists would make every successful D
transaction an intentional `receipt exists / body event absent` corruption.

## 7. Exact D Witness Shape

The D corpus grows two independent disposable sealed repositories:

```text
D-clean:
  tests/run.lua is the inert clean fixture materialized through the first hand
  restricted Lua loads it as text and completes normally

D-rejected:
  tests/run.lua is the inert Lua-error fixture materialized through the first hand
  restricted Lua loads it as text and lua_pcall fails
```

The fixtures are never executed by the ordinary test process. They become code
only after entering the production supervisor.

Each witness performs:

```text
1. grow real repository generation and candidate seal
2. derive the exact command-free QA/native coordinates
3. snapshot Packet trace, budget, loss and revisions
4. reserve one exact repository QA source lease
5. enter one trusted with_qa_source callback
6. take existing-provider pre-inventory and require pre == candidate seal
7. invoke qa_provider.run(handle, exact native request) once
8. take existing-provider post-inventory and require post == pre == seal
9. finish source lease consumed or quarantined exactly once
10. validate the detached provider report
11. require Packet trace, budget, loss and revisions unchanged
12. require root state still sealed and source-write authority still closed
```

Clean and rejected use fresh roots because the source lease is intentionally
one-use and sticky.

## 8. Meaning Of Clean And Rejected In D

For the fixed exit-status-only Lua profile:

```text
luaL_loadfilex(text) + lua_pcall success + process exit 0
  -> candidate report: accepted / expected_exit

Lua load/runtime error or explicit nonzero process exit, with complete
containment, source stability and cleanup
  -> candidate report: rejected / unexpected_exit
```

The return value of the Lua chunk is not interpreted. `return false` with no
error is still exit zero. Tests are responsible for raising an error on failed
assertions under this profile.

Silent candidates are valid. Zero-byte stdout and stderr produce the SHA-256
of the empty stream; the production runner must not inherit the environment
probe's special requirement for a non-empty output witness.

`accepted` means only that this one exact entrypoint exited as required inside
this one exact environment. It is not `qa_check=accepted`, not a verdict and
not software acceptance.

## 9. Failure Separation Required Even Before E

Step D may claim clean accepted/rejected only when all of these are proved:

```text
candidate started
candidate and namespace init were reaped
stdout and stderr reached bounded EOF
source staging and mount policy were exact
pre == seal == post
scratch and mount namespace were destroyed
result frame and identities were complete
```

Otherwise:

| Condition | D classification |
|---|---|
| request/userdata/wire malformed | trusted invariant, loud |
| source mismatch before run | provider world error; no candidate report |
| staging/namespace/launcher failure | provider infrastructure error |
| normal Lua error with complete world | clean candidate rejection |
| source mismatch after run | ambiguous source drift; quarantine |
| reap/EOF/cleanup uncertainty | ambiguous infrastructure; quarantine |
| impossible native result | trusted invariant, loud |

Step `8.5.5E` will exercise signal, timeout, memory, output, scratch, seccomp,
trusted crash and repeated leak classifications. D must fail closed for those
paths but does not claim them green merely because code branches exist.

## 10. Fixed Descriptor Amendment

The crystallized descriptor prose lists source/request/result as `fd 3..5`,
while the implemented self-identity law also keeps the exact supervisor
executable as `fd 6` across `execveat`.

The real fixed contract is:

```text
fd 3  exact repository source root
fd 4  bounded request frame read end
fd 5  bounded result frame write end
fd 6  exact supervisor executable used for post-exec self hashing
```

`fd 6` is closed before namespace/candidate creation. Candidate code inherits
none of `3..6`. TABLE and CRYSTALL must say this explicitly.

## 11. Named Writers And Readers In D

| Fact | Writer | First reader | Body authority in D |
|---|---|---|---|
| sealed source/root truth | repository registry + candidate seal | D harness/source resolver | none added |
| detached staged mount identity | trusted namespace init | supervisor result validator | none |
| candidate process status | kernel wait state observed by supervisor | native classifier | none |
| stream/resource mechanics | trusted supervisor | strict Lua adapter | none |
| candidate report | supervisor + strict adapter | trusted D harness | none |
| pre/post inventory equality | existing repository provider + D harness | D acceptance assertion | none |

There is deliberately no Packet/body writer in this table. The D report is
runtime evidence about the provider, not current evidence owned by a Packet.

## 12. Expected Control Delta

Current expected-red matrix after C:

```text
39 green / 45 red
```

The bounded D target turns exactly this native control green:

```text
QN16 clean and nonzero fixtures classify exactly
```

Expected matrix after D:

```text
40 green / 44 red
native supervisor: 16 green / 4 red
```

`QN17-QN20` remain red for E. `QE08-QE20` remain red because the private
grant/receipt/body transaction is intentionally not promoted by D. No verdict
control becomes green.

If D accidentally greens a verdict or tree-readiness control, the authority
ceiling has been crossed and the implementation is rejected.

## 13. Required TABLE/CRYSTALL Amendments Before Code

The existing documents remain mostly valid, but implementation cannot proceed
directly from their stale mount sentence.

Required amendments:

```text
TABLE qa_execution_capability:
  replace direct procfd bind with authority/observation/staged-mount law
  state the D provider-physics ceiling and delayed receipt/body join

CRYSTALL qa_native_supervisor:
  exact self-bind -> open_tree -> detach -> mount_setattr -> move_mount order
  original-root identity versus staged-mount identity
  source-under-/tmp control
  fixed fd 6 self-identity contract
  silent-stream law

CRYSTALL qa_execution_capability:
  separate D harness transaction from future qa_execution/body transaction
  forbid receipt creation in D

step-C evidence:
  retain as historical build evidence and append the new environment-identity boundary
```

## 14. Falsifiers For The Next Layer

The TABLE amendment must make these executable without inventing policy:

```text
S1 direct procfd/open_tree failure cannot trigger pathname fallback after /tmp is hidden
S2 source below host /tmp stages and remains exact after host /tmp is hidden
S3 transient path substitution before self-bind fails original identity comparison
S4 detached tree with wrong device/inode never reaches move_mount
S5 moved mount with wrong staged mount id never reaches candidate
S6 source write through /qa/source returns EROFS
S7 staging failure starts no candidate and emits no candidate report
S8 clean silent fixture returns accepted/expected_exit with empty-stream digests
S9 Lua error returns rejected/unexpected_exit, not provider corruption
S10 pre/post inventory drift produces no clean candidate report
S11 source lease replay starts no second supervisor
S12 D execution changes no Packet trace, budget, loss, revisions or readiness
S13 no private receipt or body QA event is created in D
S14 QN16 alone crosses red-to-green
```

## 15. Proposed Implementation Slices After Documentation

```text
D0 TABLE amendment and cross-document audit
D1 CRYSTALL amendment
D2 detached source staging in probe mode; environment identity rotates
D3 RUN wire request/result and strict launcher parser
D4 clean/nonzero candidate task and separate bounded stream measurements
D5 strict qa_provider candidate-report normalization
D6 real sealed-source integration witness with pre == seal == post
D7 QN16 red-to-green, full regressions and evidence note
```

No D slice may add body readiness to make an integration test convenient.

## 16. Open Questions For TABLE

The physics is now bounded enough that the remaining questions are narrow:

```text
Q1 Which exact staged mount fields enter the native result, and which remain private?
Q2 Which closed provider error code names failure of detached source staging?
Q3 Does D expose only qa_provider.run internally, or one narrower test-owned witness helper?
Q4 Which existing inventory API is the single pre/post reader in the real-source harness?
Q5 Which exact native result fields are required for clean empty stdout/stderr?
Q6 How is provider cost measured in D without projecting it into Packet economics?
```

These questions do not reopen shell commands, source copying, writable overlays,
body receipts or verdict authority.

## 17. Model Economy

This CHAOS pass required Ultra because it joined:

```text
Linux mount physics
sealed repository authority
environment identity
private receipt finality
body truth ownership
red-control promotion
```

Recommended next level:

```text
TABLE amendment and cross-table audit: Ultra
CRYSTALL transcription after TABLE closes Q1-Q6: High
C/Lua implementation from accepted crystall: High
mechanical test runs and evidence formatting: Medium
return to Ultra only on a new authority/identity contradiction
```

## 18. Thesis

```text
The first real candidate must enter through a mount whose authority came from
the sealed fd, whose temporary path was only an observed staging instrument and
whose new mount identity is tracked honestly.

The provider may learn that the candidate exited cleanly before the Packet is
allowed to know it. Physics is built first; body truth arrives only with its
named writer.
```
