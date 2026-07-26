# QA Detached Source Staging Yellowprint v0

Status:

```text
layer: table (candidate)
date: 2026-07-26
chapter: 8.5 second QA hand
roadmap slice: 8.5.5D provider physics
runtime implementation authorized: no
candidate execution authorized: no
body QA authority authorized: no
crystallization authorized: yes; D0 TABLE cross-audit 2026-07-26
gate record: docs/00_chaos/qa_first_candidate_table_cross_audit_2026-07-26.md
```

Primary CHAOS source:

[`../../00_chaos/second_qa_hand_first_candidate_transaction_notes_2026-07-26.md`](../../00_chaos/second_qa_hand_first_candidate_transaction_notes_2026-07-26.md)

Companion TABLE contracts:

```text
qa_provider_candidate_transaction_yellowprint.v0.md
qa_execution_capability_yellowprint.v0.md
candidate_seal_transaction_yellowprint.v0.md
repository_candidate_lifecycle_yellowprint.v0.md
capability_safe_repository_hands_yellowprint.v0.md
qa_contract_profile_yellowprint.v0.md
```

## 0. Selected Decisions

```text
DS01 the already-open sealed repository fd remains the sole source authority
DS02 a pathname derived from /proc/self/fd is a transient observation, never authority
DS03 source staging occurs only after entering a fresh private mount namespace
DS04 the transient locator is resolved and compared to the fd before self-bind
DS05 source is self-bound only inside that private namespace
DS06 open_tree clones the namespace-owned bind into one detached mount fd
DS07 the temporary self-bind is detached before host paths are hidden
DS08 readonly,nosuid,nodev,noexec are applied to the detached mount before attach
DS09 host /tmp is hidden only after the detached source mount exists
DS10 move_mount attaches that exact detached mount at /qa/source
DS11 original-root identity and staged-mount identity are separate facts
DS12 device+inode must remain equal across original, detached and attached views
DS13 staged mount id must remain equal before and after move_mount
DS14 cloned staged mount id is not required to equal the original mount id
DS15 locator text, raw host ids and mount fds remain native-private
DS16 normalized provider reports gain no second source-identity surface
DS17 environment_id binds the staging feature and exact staging policy digest
DS18 an old environment record never silently migrates to this policy
DS19 staging failure starts no candidate and emits no candidate report
DS20 source copying, writable overlays and post-hide pathname fallback are forbidden
DS21 fd 3..6 have one fixed pre-candidate meaning and candidates inherit none
DS22 same-authority races outside observable checkpoints remain an admitted host limit
DS23 probe and run use the same staging implementation, not two lookalike paths
DS24 no substrate actor selects, alters or interprets source staging
```

## 1. Closed Physical Claim

This table permits one narrow transformation:

```text
sealed repository fd
  -> exact detached read-only mount
  -> /qa/source inside one private candidate world
```

It does not permit:

```text
repository path as authority
source copying
writable source
candidate-controlled mount options
candidate execution by itself
QA check/verdict/body evidence
```

Successful staging proves only that the supervisor constructed the source side
of the declared environment. It does not prove that a candidate started or that
any software passed QA.

## 2. Three Surfaces, One Authority

| Surface | Form | Owner | May authorize mount? | May cross into Lua/body? |
|---|---|---|---|---|
| sealed root authority | inherited exact directory fd | repository registry and launcher | yes | no |
| transient locator | bounded absolute pathname derived from fd | trusted namespace setup | only after identity comparison | no |
| staged source mount | detached mount fd plus staged mount identity | trusted namespace setup | yes, once | no |
| normalized source result | `environment_id`, pre/post inventory ids, `stable=true` | transaction assembler after strict adapter | no | harness in D; body only in future joined transaction |

The locator does not become authority merely because the kernel mount API needs
a pathname for the self-bind step. Its only legal role is to let the private
namespace create a mount object whose identity is repeatedly compared to the
already-owned fd.

## 3. Identity Model

### 3.1 Original root identity

Native-private shape:

```lua
{
  device = uint64,
  inode = uint64,
  mount_id = uint64,
}
```

The launcher obtains this identity from the verified repository userdata and
re-observes it on the duplicated source fd. The supervisor observes the same
triple on fixed fd 3 before staging.

Required equality:

```text
repository userdata prefix
  == launcher duplicated fd
  == supervisor fixed fd 3
  == transient locator before self-bind
```

### 3.2 Staged mount identity

Native-private shape:

```lua
{
  device = uint64,
  inode = uint64,
  staged_mount_id = uint64,
}
```

The staged identity is observed on the detached mount before `move_mount` and
again at `/qa/source` after attach.

Required equality:

```text
detached.device == original.device
detached.inode  == original.inode

attached.device          == detached.device
attached.inode           == detached.inode
attached.staged_mount_id == detached.staged_mount_id
```

The following equality is explicitly false as a law:

```text
detached.staged_mount_id == original.mount_id
```

Mount cloning creates a new mount object. Treating the new mount id as a
contradiction would reject the selected mechanism; ignoring the new mount id
would fail to prove that the detached object is the one eventually attached.

### 3.3 Private staging attestation

The supervisor RUN/PROBE result wire contains one native-private attestation:

```lua
{
  protocol_version = "qa.native_source_staging_attestation.v0",
  policy_id = "qa.source_staging.detached_mount.v0",
  original = {device, inode, mount_id},
  detached = {device, inode, staged_mount_id},
  attached = {device, inode, staged_mount_id},
  source_flags = {
    readonly = true,
    nosuid = true,
    nodev = true,
    noexec = true,
  },
  temporary_self_bind_detached = true,
  candidate_started_after_attestation = boolean,
}
```

The exact launcher validates this attestation against its pre-exec source
identity. Raw numbers, the transient locator and the attestation digest do not
enter the Lua provider report. They would fingerprint host state and duplicate
the policy fact already carried by `environment_id`.

The normalized report therefore keeps the existing source projection:

```lua
source = {
  pre_inventory_id = string,
  post_inventory_id = string,
  stable = true,
}
```

`environment_id` proves which staging policy was measured. `source.stable`
proves pre/post candidate stability. No third public record is needed.

## 4. Exact Staging Transaction

The conforming order is:

| Phase | Operation | Required witness before next phase |
|---|---|---|
| S0 | duplicate and revalidate repository source fd | original identity exact |
| S1 | enter fresh user and mount namespaces | private propagation established |
| S2 | derive locator from `/proc/self/fd/3` | bounded absolute non-deleted locator |
| S3 | observe locator | locator identity equals original triple |
| S4 | self-bind locator onto itself | bound object identity equals original triple |
| S5 | `open_tree(CLONE | CLOEXEC)` the self-bind | detached fd exists; device+inode exact |
| S6 | detach temporary self-bind | locator is no longer a staging mount |
| S7 | apply recursive `RDONLY|NOSUID|NODEV|NOEXEC` to detached fd | all four flags observed |
| S8 | hide host `/tmp` and construct empty root | detached source remains reachable only by fd |
| S9 | `move_mount` detached fd to `/qa/source` | attached staged identity equals detached identity |
| S10 | verify `/qa/source` policy and write denial | exact mount; source write returns `EROFS` |
| S11 | close setup-only descriptors | candidate inherits no staging authority |
| S12 | create candidate | successful staging attestation already complete |

There is no pathname fallback after S8. There is no candidate process before
S12. Candidate-controlled bytes are never parsed during S0-S11.

## 5. Locator Admission

The transient locator is admitted only when all predicates hold:

```text
derived internally by readlink(/proc/self/fd/3)
byte length is 1..PATH_MAX-1
starts with '/'
contains no NUL by construction
does not carry the kernel " (deleted)" suffix
resolves before self-bind to original device+inode+mount_id
resolves after self-bind to original device+inode+mount_id
never enters argv, environment, request/result Lua tables, trace or corpus
```

The mount call is a direct syscall with a trusted internally derived string.
No shell, command parser or candidate selector is involved.

## 6. Mount Policy And Tree Scope

The source mount is:

```text
read-only
nosuid
nodev
noexec
recursively covered by the selected mount attribute operation
```

The repository provider owns the root and candidate-seal inventory law. The QA
supervisor does not reinterpret repository contents or admit additional host
mounts. A nested mount, special object or unstable entry that violates the
sealed inventory remains a pre/post inventory failure, not a reason to widen
the namespace.

The v0 source is not copied. The tested bytes remain the bytes beneath the
sealed root authority. Scratch remains a separate private tmpfs.

## 7. Environment Identity Rotation

`detached-source-staging` enters both:

```text
isolation_feature_set_id
isolation_policy_digest
```

The changed supervisor binary also changes:

```text
supervisor_build_id
runtime_dependency_closure_id when the static closure changes
provider_build_id when the launcher module changes
```

Therefore the derived `qa.environment.v0.environment_id` changes. The step-C
record remains valid historical evidence for its old policy; it is not a valid
environment for D execution.

`probe_environment` must exercise the same staging implementation used by RUN.
A probe-only alternate bind path is forbidden because it would certify a world
the execution path never constructs.

An existing QA contract bound to the old environment becomes `not_ready`. It
is never rewritten in place. A fresh build birth may bind the new environment.

## 8. Fixed Descriptor Contract

Before supervisor setup:

| fd | Exact owner and meaning |
|---|---|
| 3 | duplicated exact sealed repository root |
| 4 | bounded authenticated request-frame read end |
| 5 | bounded authenticated result-frame write end |
| 6 | exact supervisor executable used for post-`execveat` self identity |

Rules:

```text
fd 6 closes immediately after self-hash verification
fd 3 closes after source staging is complete
fd 4 closes after exact request consumption
fd 5 remains supervisor-owned only until exact result/cleanup completion
candidate stdin/stdout/stderr are separately constructed
candidate inherits none of fd 3..6
all unrelated inherited descriptors are closed before candidate creation
```

The descriptor numbers are part of the native ABI. They are never exposed as
public capability ids.

## 9. Failure And Cleanup Law

### 9.1 Clean staging failure

If staging fails before candidate creation and all temporary mounts/fds/process
state are proven cleaned, the D transaction projects:

```lua
{
  protocol_version = "qa.provider_witness_error.v0",
  class = "world",
  code = "source_staging_failed",
  stage = "source_staging",
  candidate_started = false,
  source_stable = nil,
  cleanup_complete = true,
  cost = measured_cost,
}
```

The private native diagnostic may name a closed failure step such as
`locator_identity`, `self_bind`, `open_tree`, `self_bind_detach`,
`mount_setattr`, `move_mount` or `attached_identity`. That step does not cross
the strict adapter boundary in v0.

The native staging layer writes only its private process error. The D
transaction assembler owns the witness error above after joining source and
cleanup observations. A future Packet-owned transaction may project the same
physical class into `qa.provider_error.v0` only after its body request exists.

### 9.2 Ambiguous staging failure

If cleanup, detached-mount ownership or source identity cannot be proved after
entry, the transaction is quarantined. It does not return a candidate report.
The provider error uses the existing ambiguity/cleanup vocabulary rather than
pretending staging merely failed cleanly.

### 9.3 Trusted contradiction

Impossible attestation fields, unknown status codes, a candidate-start marker
before successful staging, or disagreement between launcher and supervisor
source identities are trusted invariant failures. They are loud and cannot be
converted into ordinary candidate rejection.

## 10. Named Writers And Readers

| Fact | Writer | First reader | Public/body projection |
|---|---|---|---|
| sealed source authority | repository registry | launcher ABI validator | none |
| original fd identity | repository provider + launcher reobservation | supervisor preflight and launcher result validator | none |
| transient locator | trusted supervisor namespace setup | immediate identity comparison | none |
| detached staged identity | trusted supervisor after `open_tree` | `move_mount`/post-attach validator | none |
| staging policy flags | trusted supervisor/kernel observation | launcher strict result validator | environment policy identity only |
| staging feature availability | environment probe | environment registry/contract binder | `qa.environment.v0` digests |
| pre/post source stability | repository inventory adapter | transaction assembler | inventory ids plus `stable=true` |

Every written record has a named reader. No row gives semantic data authority
over mount selection or host identity.

## 11. Permanent Controls

| ID | Falsifier | Required result |
|---|---|---|
| DS-T01 | direct procfd bind/open_tree is unsupported | no fallback after host `/tmp` is hidden |
| DS-T02 | exact source physically resides below host `/tmp` | staging succeeds; candidate sees exact source |
| DS-T03 | locator changes before self-bind | original identity mismatch; no candidate |
| DS-T04 | self-bind resolves another mount | mismatch; detach/cleanup; no candidate |
| DS-T05 | detached tree has wrong device or inode | no `move_mount` |
| DS-T06 | attached mount id differs from detached mount id | no candidate report; quarantine/loud as applicable |
| DS-T07 | cloned mount id differs from original mount id | accepted when device+inode and staged continuity are exact |
| DS-T08 | source write/create/rename through `/qa/source` | `EROFS`; source remains exact |
| DS-T09 | source executable bit or shebang exists | no direct exec; source remains `noexec` |
| DS-T10 | source contains device/suid object | candidate cannot activate it; inventory policy still applies |
| DS-T11 | temporary self-bind survives setup | setup failure; no candidate |
| DS-T12 | fd 3..6 visible to candidate | control fails loudly |
| DS-T13 | probe path differs from RUN staging path | environment claim withheld |
| DS-T14 | policy/build changes but environment id does not | invariant failure |
| DS-T15 | old contract names step-C environment | typed not-ready, no migration |
| DS-T16 | staging fails cleanly | D witness error `source_staging_failed`; `candidate_started=false` |
| DS-T17 | staging cleanup is ambiguous | quarantine; no candidate report |
| DS-T18 | raw locator/device/inode/mount id appears in Lua/body/corpus | strict rejection |
| DS-T19 | candidate bytes influence locator or mount flags | schema/invariant rejection |
| DS-T20 | source copy or writable overlay is introduced | non-conforming implementation |

The source-under-`/tmp` and write-denial controls must use the real native path,
not a Lua mock.

## 12. Cross-Contract Consequences

This table supersedes only the direct-bind mechanics in:

```text
qa_execution_capability_yellowprint.v0.md section 8
qa_execution_capability.v0.md source-world construction
qa_native_supervisor.v0.md mount sequence
```

It does not supersede:

```text
candidate seal finality
repository source lease ownership
QA request/grant/receipt/body join
candidate report versus provider error separation
Packet mortality or tree authority
```

The companion provider-transaction table owns when this staged world may run a
candidate and which result may escape it.

## 13. Explicit Deferrals

```text
source copying
writable overlays
imported external repositories without first-hand seal authority
generic mount profiles
multiple source roots
host-global immutability against same-authority actors
privileged/root fallback
cross-host or persistent mount leases
body-visible staging diagnostics
```

## 14. TABLE Closure

The source-staging questions from CHAOS are closed as follows:

```text
Q1 native-private wire carries raw original/detached/attached identities and flags;
   normalized Lua/body surfaces carry none of them beyond environment identity
   and existing pre/post inventory stability

Q2 a clean pre-candidate failure is world/source_staging_failed at
   stage=source_staging; ambiguity remains quarantine

Q3 source staging is one internal implementation shared by probe and RUN;
   it creates no independently callable Lua authority
```

The companion provider transaction and existing QA execution contract passed
the D0 cross-table audit on 2026-07-26. Crystallization is authorized only for
the exact step-D surface; runtime implementation remains closed until CRYSTALL.

## 15. Table Thesis

```text
The pathname helps the kernel construct a mount, but it never becomes the
reason the mount is trusted. Trust begins with the sealed fd, survives as two
explicit identity comparisons, and ends before candidate code is born.
```
