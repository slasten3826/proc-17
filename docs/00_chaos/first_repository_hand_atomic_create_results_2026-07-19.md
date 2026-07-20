# First Repository Hand: Atomic Create Results

date: 2026-07-19
status: roadmap step 7.5 complete; 7.6 remains red
truth: runtime-confirmed where a command/result is named below
plan: first_repository_hand_atomic_create_plan_2026-07-19.md

## 1. Verdict

The native provider can now create one absent UTF-8 text file beneath one
previously proven repository root. It cannot overwrite an existing object,
create a parent, follow a symlink, cross a mount, accept a broad mode, retry an
unbounded failure or claim clean success after uncertain publication.

This is not yet a complete repository effect. Native read-back remains
unavailable, no `runtime.repository_effect` exists, and the tree router has no
path that dispatches this primitive. Step 7.5 creates a bounded host primitive;
it does not give semantic Packet state direct filesystem authority.

## 2. Implemented Transaction

`native/proc17_repository_fs.c` now performs:

```text
strict native request validation
fresh base/root reopen and identity comparison
descriptor-relative parent open with BENEATH/NO_SYMLINKS/NO_MAGICLINKS/NO_XDEV
process-owned, non-group/world-writable final-parent policy
one 128-bit getrandom request and one private-name attempt
O_CREAT|O_EXCL|O_NOFOLLOW mode-0600 temporary creation
exact fchmod(0600)
regular/euid-owned/single-link/zero-size temporary identity verification
complete bounded write loop (maximum 64 EINTR retries)
temporary fsync and close
renameat2(RENAME_NOREPLACE)
parent-directory fsync
typed cleanup or post-publication ambiguity
```

The production dynamic module still exports one symbol only:

```text
luaopen_proc17_repository_fs
```

Fault controls exist only under `PROC17_REPOSITORY_FS_TESTING` and are absent
from the production ELF and Lua API.

## 3. Runtime Evidence

### 3.1 Normal body

```text
lua tests/run.lua
all tests ok (80 suites)
```

No normal route, budget, loss, lineage or manifest regression was observed.

### 3.2 Root and loader gates

```text
repository-provider-loader: 7 GREEN / 0 RED
repository-provider-root: 16 GREEN / 0 RED
repository-prewrite-security: 7 GREEN / 0 RED
repository-capability: 13 GREEN / 0 RED
```

The old ROOT12 assertion was not deleted. Its historical law, "7.4 contains no
mutation primitive", was revised into the 7.5 law: the source must contain the
exact no-replace transaction and must not contain truncate, append, O_TMPFILE,
plain rename or renameat fallback.

### 3.3 Real Linux provider boundary

```text
repository-provider-linux: 19 GREEN / 3 RED / 1 SKIP
```

The nineteen green controls include:

```text
exact nested, repository-root and zero-byte creation receipts
identical replay remains target_exists
root and parent symlink denial
missing/non-directory parent classification
group/world-writable parent denial before mutation
regular/directory/FIFO/symlink target no-replace
hard-link no-truncate evidence
Lua and direct-native malformed request rejection
stale root identity denial
native fault/atomicity harness
command-bearing request rejection
```

The three red controls are all read-back controls:

```text
P0 create plus independent read-back
root replacement between create and read-back
expected-plus-one bounded read-back
```

They remain red by design until 7.6. P15 cross-device bind-mount coverage remains
one explicit environmental skip; it is not counted as green.

The complete staged battery remains:

```text
repository-hands red baseline: 7 green suites / 4 red suites / 11 total
```

The four red suites are provider read-back/effect/progress/route work owned by
7.6-7.7, not regressions in the create primitive.

### 3.4 Native fault battery

```text
make -C native test-create
test_proc17_repository_fs ok
```

Seventeen create-side cases exercise:

```text
all named pre-publish failure stages
short write plus EINTR recovery
permanent EINTR termination after 65 calls
zero write rejection
single random/name attempt
foreign temp collision preservation
competing final creation
cleanup residue reporting
post-rename and parent-fsync ambiguity
all existing target object types
mode 0600 under hostile umask 0777
the exact 1 MiB content ceiling
descriptor baseline and idempotent close
```

The read target remains deliberately red:

```text
make -C native test-read
fails at PROC17_OUTCOME_OBSERVED because read-back is not promoted
```

No fixture remains after either the green create battery or the expected red
read boundary.

## 4. Faults Found During The Step

### 4.1 Test fixture restored umask too early

The first hostile-umask test failed before reaching the hand. The internal
fixture creator restored `umask=0777` before creating its repository tree and
therefore created an inaccessible test directory. The fixture now retains its
private 0077 mask through complete construction and restores the caller mask
afterward. One abandoned empty `/tmp/proc17-native-fs-*` fixture from the failed
run was identity-inspected and removed with non-recursive `rmdir`.

This was a test-harness defect, not a filesystem-hand defect, but leaving it
unfixed would have made the mode claim environment-dependent.

### 4.2 Named temporary file required a parent policy

A 128-bit name prevents pre-creation but does not by itself prevent a different
UID with directory write authority from replacing the named temporary entry
after it appears. The transaction now rejects a final parent unless:

```text
parent owner == process effective UID
parent mode has no group-write or other-write bit
```

This makes the remaining active replacement actor an equally privileged
same-UID process, which is outside the v0 trust boundary. The result document
does not claim protection from a malicious process holding equivalent host
authority.

## 5. Structural And Memory Checks

```text
GCC -fanalyzer production source: GREEN
GCC -fanalyzer test build: GREEN
ASan + UBSan create battery: GREEN
GNU_STACK: RW, non-executable
GNU_RELRO: present
BIND_NOW/NOW: present
defined dynamic exports: luaopen_proc17_repository_fs only
```

LeakSanitizer cannot run in the current restricted execution environment
because it reports the surrounding ptrace boundary. This is recorded as an
environmental limitation, not a green leak claim. Descriptor-baseline tests,
explicit close/GC tests from 7.4 and the create fault battery remain green.

## 6. Residual Boundary

Step 7.5 does not prove:

```text
that the final bytes can be independently observed
that a create receipt is completion
that ambiguous residue quarantines a live capability
that the body can dispatch the provider
that a Packet can finish repository work
that bind-mount denial ran on this host
```

The production primitive is reachable only by trusted Lua code holding the
opaque handle. No handle, root, host path, temporary name or fault control enters
Packet, trace, corpse, carrier or public capability projections.

## 7. Next Step

Roadmap 7.6 must add one exact read-back operation. It must freshly revalidate
the root, open only the created target, classify missing/non-regular objects,
read at most the caller's exact bound, and remain tied to the create action.

Until that evidence exists:

```text
created != verified
receipt != completion
provider create != body hand
```
