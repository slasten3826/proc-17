# First Repository Hand Root Identity Results

Status:

```text
layer: CHAOS / observed implementation evidence
date: 2026-07-19
roadmap: 7.4 of 7.10 complete
production mutation authority: absent
repository identity authority: present, private and read-only
router authority: unchanged
```

Sources:

```text
docs/00_chaos/first_repository_hand_root_identity_plan_2026-07-19.md
docs/00_chaos/first_repository_hand_threat_model_2026-07-19.md
docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
```

## 0. Physical Change

Before 7.4 the accepted native ABI could identify itself but could not produce a
repository handle. After 7.4 it can establish and later re-observe one exact
directory identity:

```text
trusted absolute project_base
  -> openat2(NO_SYMLINKS | NO_MAGICLINKS)
  -> base device/inode/mount identity
  -> descriptor-relative repository openat2(
       BENEATH | NO_SYMLINKS | NO_MAGICLINKS | NO_XDEV)
  -> repository device/inode/mount identity
  -> opaque full userdata
```

The userdata retains two `O_PATH|O_DIRECTORY|O_CLOEXEC` descriptors and bounded
copies of the host-selected base path and repository-relative path. Its
metatable is protected. `tostring` reveals only open/closed state; no descriptor,
host path or native table is projected.

## 1. Revalidation Law Observed

`revalidate(handle)` reopens both named directories through the same resolution
policy and compares private device/inode/mount identities. It returns valid only
for an exact match.

Observed cases:

| Case | Result |
|---|---|
| stable base and root | `repository.provider_result.v0`, `outcome=valid` |
| repository replaced at same path | `root_changed` |
| project base replaced at same path | `root_changed` |
| repository renamed away | `root_changed` |
| repository root symlink | `path_symlink`/containment denial at initial open |
| project-base symlink | `path_symlink` |
| `/proc/self/root` magic-link path | `path_symlink` |
| missing root | `root_missing` |
| regular file used as root | `root_invalid` |
| closed handle | `handle_closed` |
| scalar or foreign userdata handle | loud adapter/native contract failure |

Revalidation is a read-only preflight. Future mutation must perform the same
identity check inside its own native transaction and continue from the freshly
opened descriptor; a Lua preflight alone will never authorize an effect.

## 2. Independent Native Bounds

The C boundary independently rejects before a syscall:

```text
non-absolute, root-only, repeated-separator or dot-component project bases
embedded NUL/control bytes
absolute or parent-traversing repository paths
internal body-store components
components above 255 bytes
more than 64 components
repository paths above 1024 bytes
```

The trusted project-base copy has an internal 4096-byte ceiling. Malformed
requests return `contract/invalid_request` with `tool_calls=0` and no mutation.

## 3. Descriptor Mortality

The root corpus opened 32 simultaneous handles and observed at least 64 new
descriptors. Explicit close returned the process to its exact baseline. It then
repeated the experiment and released all handles only through two Lua garbage
collections; the exact descriptor baseline returned again.

```text
first close: closes repository and base descriptors once
second close: true, no close against a potentially reused descriptor
__gc after explicit close: no-op
__gc without explicit close: closes both descriptors
```

Close is never retried after an error because on Linux retrying `close(2)` may
target a descriptor number already reused by another thread.

## 4. No Mutation Evidence

The production source contains none of the 7.5 primitives:

```text
O_CREAT / O_TMPFILE
write / pwrite
renameat2
unlinkat / mkdirat
fchmod / fsync
```

A before/after snapshot of the identity-owned fixture, including names, object
types, modes and sizes, was identical across open, revalidate and close. All
fixture construction, replacement attacks and cleanup remain test-harness
actions outside the production provider.

## 5. Executed Evidence

Root identity suite:

```text
before implementation: 1 GREEN / 12 RED / 0 SKIP
after implementation and corpus expansion: 16 GREEN / 0 RED / 0 SKIP
```

Full repository-hands battery:

```text
81 GREEN / 38 RED / 1 explicit SKIP
suite summary: 7 GREEN / 4 RED / 11 total
process exit: 1, expected while 7.5-7.7 remain absent
```

Provider Linux suite changed only at the owned boundary:

```text
native provider identity available: GREEN
symlink repository root denied: GREEN
replaced root identity rejected: GREEN
atomic create/read-back/fault cases: still RED
```

Ordinary body regression:

```text
80 suites passed
process exit: 0
```

Strict compilation and static analysis:

```text
-Wall -Wextra -Werror
GCC -fanalyzer
production dynamic export: luaopen_proc17_repository_fs only
GNU_STACK: RW, not executable
GNU_RELRO: present
BIND_NOW: present
```

Isolated runtime instrumentation:

```text
ASan + UBSan + LeakSanitizer
128 open/revalidate/double-close lives
128 GC-only handle lives
malformed native path corpus
result: no proc-17 diagnostic, leak or undefined behavior
```

The first attempted sanitizer command inherited ASan into `/usr/bin/make` and
detected a heap over-read in that external binary before the proc-17 test began.
That run is not counted as provider evidence. The accepted sanitizer run used a
prebuilt module and an isolated Lua probe with fixture birth/death owned by the
external identity guard.

## 6. Blocker Ledger After 7.4

| Blocker | State | Named reader |
|---|---|---|
| B1 trusted native load path | GREEN | loader suite |
| B2 exact mode policy | GREEN at registry/ABI boundary | prewrite suite |
| B3 hard ceilings | GREEN for root parser; create/content enforcement RED | root parser and future create tests |
| B4 secure fixture | GREEN | fixture guard |
| B5 ambiguous temporary residue | RED | 7.5 fault harness |
| B6 public effect-data leakage | RED | 7.7 event inspection |
| B7 root identity semantics | GREEN for open/revalidate | root suite; future transaction repeats check |
| B8 native artifact policy | GREEN | build/source controls |

## 7. Next Gate

Step 7.5 may introduce the first production mutation, but only inside an already
revalidated exact parent beneath this root:

```text
one private temporary regular file
exact mode 0600
complete bounded write
fsync and close before publication
renameat2(RENAME_NOREPLACE)
no overwrite and no weak fallback
typed cleanup/ambiguity on every fault stage
```

Read-back remains separately owned by 7.6. Route/effect authority remains absent.

Progression note (2026-07-19): this section records the boundary as it stood at
the end of 7.4. Step 7.5 is now complete; its implementation evidence is in
`first_repository_hand_atomic_create_results_2026-07-19.md`. The unresolved
read-back and route/effect statements remain current.
