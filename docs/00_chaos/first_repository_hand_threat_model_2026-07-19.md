# First Repository Hand Threat Model

Amendment 2026-07-19:

```text
Step 7.2 converted this model into an expanded red battery and replaced the
unsafe temporary-root fixture. Observed evidence and the candidate hard limits
are recorded in first_repository_hand_red_battery_results_2026-07-19.md.
Step 7.3 implemented and tested the exact fail-closed loader and ABI shell.
Observed evidence is recorded in
first_repository_hand_loader_results_2026-07-19.md. Step 7.4 implemented the
read-only root identity and revalidation boundary; its evidence is recorded in
first_repository_hand_root_identity_results_2026-07-19.md. This threat model
remains the authority for the rows that are still red.
```

Status:

```text
layer: CHAOS
date: 2026-07-19
roadmap: 7.1 of 7.10
subject: first external repository mutation
implementation authority: none
router authority: unchanged
filesystem effect authority: still absent
decision truth status: document_decision
```

Sources:

```text
docs/00_chaos/capability_safe_repository_hands_notes_2026-07-19.md
docs/01_table/yellowprints/capability_safe_repository_hands_yellowprint.v0.md
docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
docs/03_manifest/repository_capability_boundary.v0.md
docs/00_chaos/repository_hands_red_battery_results_2026-07-19.md
```

This document does not widen the crystall. It gathers its safety laws into one
executable threat model and names missing proof before the first real write.

## 0. Safety Position

The default state of the first hand is:

```text
everything is denied
```

The only candidate exception is one exact effect:

```text
inside one host-granted repository identity
create one previously absent regular file
at one authorized relative path
with one authorized bounded UTF-8 byte string
using mode 0600
publish it atomically without replacement
then independently read the exact final target
```

The atomic algorithm also requires one tightly bounded internal mutation:

```text
one private temporary regular file
in the already-open exact target parent
under an unrequestable reserved name
for the lifetime of this exact effect attempt
```

That temporary inode is part of the authority surface and must be tested as
such. Calling it an implementation detail would hide a real external mutation.

The first hand does not:

```text
open arbitrary files
overwrite or accept an existing target
append, patch, delete, chmod, mkdir or rename caller-selected objects
execute the created content
execute a shell or command
follow symbolic or magic links
cross a mount boundary
select a repository, grant, action, path or content semantically
convert a writer report into verified success
```

## 1. Canonization Law

One happy-path write is not acceptance evidence. Canonization requires three
independent forms of proof:

| Proof | Question |
|---|---|
| positive | Can the hand perform the one permitted effect? |
| negative | Does every named forbidden case fail closed without forbidden mutation? |
| structural | Can a forbidden operation, path, authority or fallback be represented at all? |

The provider is not canonical while any required row in this document is
untested, skipped without a bounded claim, false-green, or dependent on a weak
fallback.

## 2. Trust Boundary

### 2.1 Untrusted or non-authoritative inputs

The following may influence meaning but cannot grant power:

```text
user prompt
substrate output
semantic grant names
Packet CHAOS/CALM/field content
public capability projections
route/action projections returned to callers
repository filenames and existing repository objects
environment inherited from the target task
provider success/error tables before strict validation
```

Repository contents are hostile for containment purposes. Existing directories,
files, symlinks, mount points and concurrent replacement may not be treated as
trusted merely because they are below a textual path.

### 2.2 Trusted computing base

The first proof necessarily trusts:

```text
the running Linux kernel and filesystem syscall semantics
the proc-17 host process and accepted Lua body code
the exact accepted native provider binary
the host administrator who selects project_base and repository_id
the private capability registry and opaque native handles
```

The native provider is not admitted to this set by compiling. Step 7 exists to
earn that status through contract validation, real filesystem tests and fault
injection.

### 2.3 Explicitly out of scope

This v0 cannot defend against:

```text
a compromised kernel
arbitrary native code execution inside the proc-17 process
ptrace/process-memory access by an already equally privileged attacker
a malicious same-uid process that independently owns equivalent filesystem
authority and races the transaction or mutates a file after read-back
physical storage lying after successful fsync
replacement of the accepted proc-17 installation by the host administrator
```

These exclusions are not success claims. In particular, read-back proves one
point-in-time observation. It does not freeze the repository forever.

## 3. Protected Assets

| ID | Asset | Required protection |
|---|---|---|
| AS1 | host filesystem outside the granted root identity | never opened for mutation through the hand |
| AS2 | existing objects inside the granted repository | never overwritten, truncated, deleted or chmodded |
| AS3 | exact final target | absent before effect; complete or absent before publication; independently verified after |
| AS4 | private capability and directory handles | never serialized, traced, prompted or returned as integers/tables |
| AS5 | sessions, packets, graves, compost, trace and proc control files | unreachable through repository authority |
| AS6 | another repository or lineage | no grant/action reuse across identity boundaries |
| AS7 | audit truth | attempt, receipt, evidence and completion remain distinct |
| AS8 | process availability | path/content/read size, dispatch count and retries remain bounded |
| AS9 | confidential host names and read-back bytes | no absolute path or raw observed content enters trace/error projections |
| AS10 | provider integrity | loader, ABI, schemas and syscall outcomes fail loudly when contradictory |

## 4. Authority Flow

Authority and semantic data travel through different channels:

```text
semantic channel:
  field unit -> intent -> immutable action projection

authority channel:
  trusted host config -> private registry -> exact grant -> one-use effect lease

intersection:
  action identity + current field referent + exact live grant
    -> one bounded native transaction
```

The Packet may name the action. It never receives the root descriptor. The
native provider receives an opaque root handle, the exact relative path, exact
content bytes and fixed policy. It never receives the Packet, prompt, arbitrary
options, command, shell, absolute target path or a second repository selector.

## 5. Root Identity Law

Containment is identity-based, not string-prefix based.

The grant binds:

```text
trusted project-base identity
repository-relative name
repository root device/inode
provider identity
```

Every mutation and read-back must reopen the named base/root, compare identity,
and then operate only through fresh descriptor-relative traversal.

If the granted directory is renamed after the final identity check, an open
descriptor still names the granted inode. The operation may affect that granted
identity under its new host pathname; it must never transfer authority to a
replacement directory at the old name. Read-back must reopen and revalidate;
if the named identity changed, completion is impossible.

This is a deliberate identity law. A stronger promise that no concurrent host
rename can change the pathname of the granted inode would require host locking
or namespace isolation and is not claimed by v0.

## 6. Failure Classes

Safety depends on keeping three outcomes separate:

| Class | Example | Body consequence |
|---|---|---|
| denied/not ready | no grant, plan mode, malformed semantic path | no provider call and no external cost |
| expected/ambiguous world failure | target exists, disk full, root changed, fsync failed after publish | typed effect failure with actual cost; no false completion |
| trusted invariant failure | malformed native result, ABI mismatch, impossible cost or identity | loud harness failure; no honest Packet death or grave |

Evidence mismatch after a valid writer receipt is a fourth body-visible result:
`rejected`. It records reality without declaring the trusted runtime malformed.

No class may fall back to a weaker syscall, broad path helper, shell command or
blind retry.

## 7. Deny Matrix: Authority And Lifecycle

Evidence states used below:

```text
GREEN    already demonstrated by the step-6 boundary
RED      an existing red control names the missing implementation
NEW-RED  step 7.2 must add or strengthen the control
AUDIT    structural/source inspection is also required
```

| ID | Attempted authority widening | Required result | Evidence |
|---|---|---|---|
| TH-A01 | hands absent or disabled | no module load, provider call, trace or route delta | R0/R9 GREEN; loader assertion NEW-RED |
| TH-A02 | plan-mode action | no authorization and no provider call | G12 GREEN |
| TH-A03 | semantic text names a real grant id | ignored for authority | G1 GREEN |
| TH-A04 | missing, ambiguous or revoked grant | no effect lease/provider call | G0/G6/G8 GREEN; G7 RED |
| TH-A05 | cross-session, lineage or repository reuse | no match | G3/G4/G11 GREEN |
| TH-A06 | stale generation, field version or formation | no dispatch | A7/A10 GREEN |
| TH-A07 | caller mutates action projection | revalidation restores/rejects; no widening | A9 GREEN |
| TH-A08 | caller adds shell/root/handle/raw content | schema rejection | A11/P17 GREEN; native P17 RED |
| TH-A09 | action replay consumes another dispatch | exact generation count denies; no refund/reuse | E14 and replay control RED |
| TH-A10 | one-use lease changes path or is reused | loud rejection before second provider call | NEW-RED |
| TH-A11 | private handle enters Packet/trace/corpse/carrier | impossible projection plus source audit | G2/G10 GREEN + AUDIT |
| TH-A12 | unknown operation appears | no intent/action/provider call | intent/action GREEN; native unknown-operation NEW-RED |

## 8. Deny Matrix: Loader And Native Boundary

| ID | Threat | Required result | Evidence |
|---|---|---|---|
| TH-L01 | target repository supplies a same-named `.so` | never loaded | explicit trusted install path NEW-RED + AUDIT |
| TH-L02 | `package.cpath`, cwd or task environment poisons lookup | no authority over provider selection | NEW-RED + AUDIT |
| TH-L03 | exact module absent while hands disabled | inert normal life | R0/R9 plus NEW-RED loader count |
| TH-L04 | exact module absent while requested | `provider_unavailable`, no fallback | provider build/availability RED |
| TH-L05 | module present with wrong ABI/provider id | loud harness failure | NEW-RED |
| TH-L06 | malformed native success/error table | loud harness failure, never Packet mortality | E4/E5 RED |
| TH-L07 | native handle represented as number/string/table | loader rejects; only opaque userdata accepted | NEW-RED + AUDIT |
| TH-L08 | runtime invokes shell, `realpath`, `readlink` or helper process | forbidden structurally | P17 + syscall/source AUDIT |
| TH-L09 | build/test hooks become production API | production module exports no fault controls | P16 RED + symbol/API AUDIT |
| TH-L10 | compiled module/test binary enters git accidentally | ignored build artifact and clean-tree check | NEW-RED/maintenance action |

The loader trust root is not yet specified precisely enough by the crystall.
Step 7.3 must name it before implementing `runtime/repository_provider.lua`.

## 9. Deny Matrix: Root, Path And Object Type

| ID | Host/repository state | Required result | Evidence |
|---|---|---|---|
| TH-P01 | absolute target path | reject before authorization | P1 GREEN |
| TH-P02 | `.`/`..`/empty path component | reject before authorization | P2/P3 GREEN |
| TH-P03 | control, NUL, invalid UTF-8, leading-dot component | reject before authorization | P4/P5 GREEN |
| TH-P04 | path/content beyond grant bounds | reject before authorization | P6/P8 GREEN |
| TH-P05 | repository root is symlink/magic link | grant cannot be minted | P9 RED |
| TH-P06 | parent is symlink/magic link | containment denial; outside sentinel unchanged | P10 RED |
| TH-P07 | final name is symlink | no follow, no overwrite, referent unchanged | P11 RED |
| TH-P08 | parent missing or not directory | typed failure; provider creates no directory | P12 RED; not-directory NEW-RED |
| TH-P09 | final target already exists as any type | `target_exists`; object/bytes unchanged | P13 RED; type matrix NEW-RED |
| TH-P10 | root identity replaced after grant | stale handle denied; replacement unchanged | P14 RED |
| TH-P11 | traversal crosses bind/mount/device boundary | containment denial | P15 explicit environmental RED/skip |
| TH-P12 | target names `.git`, `.agents`, `.codex` or body stores | grammar/grant denies before provider | intent GREEN; real-root controls NEW-RED |
| TH-P13 | reserved temp prefix requested by semantic action | grammar denies; prefix unavailable to final targets | current grammar structural + NEW-RED |
| TH-P14 | native receives NUL/truncated path despite Lua checks | native length-aware parser rejects | NEW-RED |
| TH-P15 | native receives oversized component/count/path | fixed provider ceiling rejects before syscall | NEW-RED |
| TH-P16 | hard-link attack on existing final | no existing final is opened/truncated; no-replace wins | P13 plus native AUDIT |

The provider must impose an absolute native ceiling in addition to grant bounds.
Exact path-byte, component-count and content-byte ceilings remain open for 7.2;
an arbitrarily large trusted-host grant must not become unbounded C allocation or
disk authority.

## 10. Deny Matrix: Mutation And Atomic Publication

| ID | Failure/attack | Required result | Evidence |
|---|---|---|---|
| TH-M01 | external call begins without immutable attempt | impossible at effect layer | E1/route RED |
| TH-M02 | random source unavailable/interrupted | typed failure; no time/pid/pseudo-random fallback | NEW-RED |
| TH-M03 | reserved temp name collides | typed failure after one attempt; no unbounded retry | NEW-RED |
| TH-M04 | short write or EINTR | complete bounded loop or typed failure | P16 native scaffold RED |
| TH-M05 | write returns zero/impossible count | loud/typed failure; no publish | NEW-RED |
| TH-M06 | write/fsync/close fails before rename | final absent; temp cleanup attempted; no success | P16 RED + fault stages NEW-RED |
| TH-M07 | temp cleanup fails | no success; exact ambiguous residue reported; grant quarantined before reuse | NEW-RED |
| TH-M08 | competing process creates final target | `RENAME_NOREPLACE` conflict; existing target unchanged | P13/P16 RED |
| TH-M09 | implementation performs check-then-rename fallback | treatment rejected | syscall/source AUDIT |
| TH-M10 | rename succeeds, later directory fsync fails | `ambiguous_effect`; never clean success or blind retry | P16 RED |
| TH-M11 | partial final bytes become visible | impossible publication pattern; fault harness observes none | P16 RED |
| TH-M12 | descriptor leak or double close | CLOEXEC, bounded cleanup, idempotent close | native scaffold RED + leak NEW-RED |
| TH-M13 | provider broadens file permissions | exact v0 mode 0600; no executable/group/other bits | NEW-RED |
| TH-M14 | content is executable/source text | created as inert bytes only; never loaded or executed | structural AUDIT |
| TH-M15 | second identical attempt treats existing bytes as success | typed conflict, never implicit replay success | P13 + replay NEW-RED |
| TH-M16 | group/other-writable final parent permits temp-name replacement | reject before mutation unless parent is euid-owned and private | real provider control GREEN |

The current capability parser accepts any positive permission mask through
0777. That is broader than the first-hand claim. Before the first real write,
policy must be narrowed to exact `0600` or the claim must return to TABLE. This
is a discovered pre-write blocker, not a provider implementation detail.

A named temporary sibling is the current crystallized atomic primitive. If its
cleanup fails, the provider cannot promise an untouched repository. The only
honest v0 result is a typed ambiguous effect, an exact reserved-name residue and
no further use of that lease/grant until host reconciliation. A silent orphan or
automatic retry is forbidden.

Implementation amendment 2026-07-19: the named sibling also requires a final
parent owned by the process effective UID with no group/other write bits. This
closes replacement by a differently privileged directory writer. A malicious
same-UID process with equivalent authority remains explicitly outside v0.

## 11. Deny Matrix: Read-Back, Truth And Leakage

| ID | Threat | Required result | Evidence |
|---|---|---|---|
| TH-E01 | writer says `created` | receipt only; not completion | E0/E3 RED |
| TH-E02 | read-back targets a different path/root/action | same-ref rejection before read or loud invariant | NEW-RED/E9-E10 RED |
| TH-E03 | read-back occurs without successful exact create receipt | no general read authority | NEW-RED |
| TH-E04 | final missing/non-regular/length mismatch/digest mismatch | rejected evidence; no completion | E3/E7 RED |
| TH-E05 | final exceeds expected bytes | read at most expected+1; reject without unbounded allocation | NEW-RED |
| TH-E06 | root changes between create and read-back | typed/ambiguous failure; no completion | P14 plus NEW-RED |
| TH-E07 | raw observed content enters trace/manifest/error | forbidden; only bytes/digest/reason retained | NEW-RED + AUDIT |
| TH-E08 | absolute host path enters public diagnostics | forbidden projection | NEW-RED + AUDIT |
| TH-E09 | caller mutates returned receipt/evidence | immutable trace remains unchanged | E12 RED |
| TH-E10 | malformed trusted evidence becomes honest death | loud harness failure | E4/E5 RED |
| TH-E11 | evidence for work/action A completes B | exact ref rejection | E9 RED |
| TH-E12 | provider cost is fabricated or impossible | loud invariant; no certified economics | E2/E13 RED + NEW-RED |

Read-back is mandatory but not a general repository read hand. Its authority is
the same one-use lease, exact target and bounded `expected_bytes + 1`. The raw
bytes exist ephemerally for hashing and comparison and must not escape through
trace, residue, grave or manifest.

## 12. Deny Matrix: Availability And Resource Bounds

| ID | Resource threat | Required result | Evidence |
|---|---|---|---|
| TH-RS01 | huge host grant | rejected by fixed provider ceiling | NEW-RED |
| TH-RS02 | repeated temp-name collisions | one measured attempt, no internal loop | NEW-RED |
| TH-RS03 | repeated effect/replay | bounded private dispatch count | capability/effect RED |
| TH-RS04 | disk full, quota, fd exhaustion, permission denial | typed actual-cost failure; no false receipt | E2 RED + fault controls NEW-RED |
| TH-RS05 | read-back file grows concurrently | expected+1 bound; reject | NEW-RED |
| TH-RS06 | syscall timer overflows/non-finite | strict result rejection | NEW-RED |
| TH-RS07 | cleanup/reconciliation loops forever | bounded attempt; external orchestration decides next life | NEW-RED/AUDIT |

No provider-internal retry loop is authorized except the bounded completion of
one interrupted/short `write` operation. Retry of the external action belongs to
body/lineage policy and must read the prior attempt state.

## 13. Test-Harness Safety

The test harness has filesystem authority independent of proc-17. It must not
become the first unsafe hand while testing the safe hand.

| ID | Harness threat | Required result | State |
|---|---|---|---|
| TH-T01 | predictable temp root is replaced before `mkdir -p` | impossible: atomic unique directory creation | current fixture unsafe; 7.2 blocker |
| TH-T02 | cleanup follows/reaches a substituted path | cleanup only an identity-owned fixture; refuse ambiguity | NEW-RED/helper redesign |
| TH-T03 | fixture shell receives user/semantic text | forbidden; constants/test-generated names only | source AUDIT |
| TH-T04 | attack sentinel is outside unique fixture | forbidden; all sentinels remain under fixture but outside granted repo | source AUDIT |
| TH-T05 | skipped mount test reported green | explicit SKIP and claim withheld | P15 currently explicit SKIP |
| TH-T06 | production module exports fault injection | symbol/API rejection | P16 + AUDIT |
| TH-T07 | failed test leaves module/binary/temp artifact staged | clean-tree and artifact scan | NEW-RED/maintenance control |

The current Lua provider fixture uses:

```text
os.tmpname -> os.remove -> shell `mkdir -p`
```

That sequence has a check/create race and `mkdir -p` can accept an attacker-
supplied object. It was sufficient while the provider module was absent, but it
is not accepted for the first real write. Step 7.2 must replace it before any
provider test is allowed to become green.

Runtime prohibition of shell remains absolute. A constant-only shell command in
the test harness is a separate authority and must still be minimized and
audited; it is never evidence that runtime shell is acceptable.

## 14. Newly Discovered Pre-Write Blockers

Step 7.1 found these unresolved boundaries:

| Blocker | Why first write is forbidden until resolved |
|---|---|
| B1 trusted native load path | cwd/package-path lookup could substitute the hand itself |
| B2 exact mode policy | current host policy parser admits more than v0 mode 0600 |
| B3 provider hard ceilings | a broad trusted grant can request unbounded native work |
| B4 secure test fixture | current temp-root creation races before the provider is tested |
| B5 ambiguous temp residue | cleanup failure needs quarantine and named evidence |
| B6 raw-data diagnostic policy | host paths/read-back bytes must be proven absent from public records |
| B7 root identity semantics | tests/docs must assert identity authority rather than promise impossible pathname immobility |
| B8 native artifact policy | `.so` and native test binaries need explicit build/ignore/clean rules |

These blockers do not invalidate the step-6 capability boundary. They are
pressures discovered because the next step touches the filesystem for real.

## 15. Step 7.2 Test Work

Before native implementation, the red battery must be amended to cover at
least:

```text
secure identity-owned fixture allocation and cleanup
trusted absolute module load path; cwd/package.cpath poisoning
wrong ABI/provider identity and non-userdata handle
exact 0600 policy
fixed native path/component/content ceilings
native NUL and unknown-operation rejection
temp collision and getrandom failure without retry/fallback
zero write, short write and EINTR
every pre-publish failure stage and temp cleanup failure
post-publish fsync ambiguity
regular/directory/FIFO/device/symlink existing target matrix
read-back same-target lease and expected+1 bound
root replacement between create and read-back
no raw content/absolute host path in public output
fd/resource cleanup and production absence of test hooks
compiled artifact exclusion and clean-tree verification
```

Controls may initially be red because the provider does not exist. They must not
be green because a fixture did not execute, a module silently fell back, or an
environmental prerequisite was skipped.

## 16. Acceptance Gate For First Contact

No body-routed production repository write is authorized until:

```text
all B1-B8 blockers have an explicit treatment or bounded rejected claim
the red battery can grow and destroy its own fixture without broad deletion
the runtime loader cannot search the task repository
the provider API cannot express shell, overwrite or a second target
the native layer independently validates path, content, mode and hard bounds
real symlink/root replacement/existing-target controls remain outside-only safe
the native fault harness proves no partial final publication
all ambiguous post-mutation states remain visible and non-retriable
read-back is exact, bounded, separate and non-public
the normal body remains behaviorally unchanged while hands are disabled
```

Only then may the one permitted effect be observed in a disposable test-owned
repository. A successful observation returns to the four-layer process for
canonization. Any missing primitive or falsifier returns to TABLE/CRYSTALL; it
does not authorize a weaker hand under the same provider name.

## 17. Chapter Position

```text
7.1 threat model and deny matrix                         complete by this note
7.2 extend the red battery and repair the test harness   complete
7.3 native provider and fail-closed loader               complete
7.4 root open/revalidate                                 complete
7.5 atomic create-no-replace                             complete
7.6 independent exact read-back                          complete
7.7 Lua effect boundary without route authority          next
7.8 adversarial/fault-injection audit                    blocked by 7.7
7.9 promote only demonstrated suites                     blocked by 7.8
7.10 manifest the first hand                             blocked by 7.9
```
