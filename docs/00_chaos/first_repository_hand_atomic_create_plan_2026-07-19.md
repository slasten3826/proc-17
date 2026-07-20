# First Repository Hand: Atomic Create Plan

date: 2026-07-19
status: implementation hypothesis for roadmap step 7.5
authority: document_decision; runtime evidence is recorded separately
depends_on:
- first_repository_hand_threat_model_2026-07-19.md
- first_repository_hand_root_identity_results_2026-07-19.md
- capability_safe_repository_hands_yellowprint.v0.md
- capability_safe_repository_hands.v0.md

## 1. Question

Can the body receive one narrowly bounded power to create one previously absent
text file without gaining overwrite, arbitrary-path, directory-creation,
read-back, command or routing authority?

Step 7.5 answers only this question. The hand is not yet a complete effect:
independent read-back belongs to 7.6, body wiring belongs to 7.7, and hostile
fault audit belongs to 7.8.

## 2. Authority Boundary

The native provider may accept only:

```text
one opaque repository handle proven by 7.4
one narrow repository-relative path
one bounded valid UTF-8 string without NUL
the exact pre-existing policy mode 0600
the absent-target precondition
```

It may create no parent directory. It may not open, truncate, append, patch,
delete or execute the requested final target. It may not follow a root, parent
or final symlink. It may not cross a mount boundary. It may not accept a shell
command, host path, descriptor, retry policy or temporary name from Lua.

The only additional internal name is one provider-generated sibling beginning
with `.proc17-tmp-`. The public path grammar cannot request that prefix.

## 3. Transaction

```text
1. validate the complete native request before a syscall
2. reopen project base and repository root and compare their retained identity
3. split the validated target into existing parent and basename
4. open the parent descriptor-relative with BENEATH, NO_SYMLINKS,
   NO_MAGICLINKS and NO_XDEV
5. require the final parent to be owned by the process effective UID and to
   grant no group/other write permission
6. request exactly 128 random bits once; there is no fallback source
7. attempt exactly one O_CREAT|O_EXCL private sibling with mode 0600
8. enforce mode 0600 on the opened descriptor
9. verify regular type, euid ownership, one link, zero size and exact 0600
10. write every content byte with a hard cap on EINTR/short-write handling
11. fsync and close the private file
12. publish with renameat2(RENAME_NOREPLACE), never check-then-rename
13. fsync the parent directory
14. close transaction descriptors and return a detached created receipt
```

The retained grant descriptors are not used as a shortcut. Every transaction
starts from a freshly reopened and revalidated root identity.

## 4. Point Of No Return

Before successful `renameat2`, the final name is absent or byte-identical to
the pre-existing object. Failure must attempt to unlink only the exact private
temporary name created by this transaction.

After successful `renameat2`, the final file may exist even if parent `fsync` or
descriptor close fails. Such an outcome is `ambiguous_effect`, never `created`.
Blind replay is forbidden because replay could only observe `target_exists` and
cannot prove whether this attempt published it.

If temporary cleanup fails before publication, the final target is still
untouched but repository state is not clean. The provider returns
`temp_cleanup_failed` with the exact reserved sibling name as typed residue.
That is an ambiguous effect and must later quarantine the grant; 7.5 proves the
record, while effect wiring remains outside this step.

## 5. Economics

```text
request/native validation failure             0 tool calls, 0 writes
fresh-root/parent/random failure               1 tool call, 0 writes
temporary create syscall entered               1 tool call, 1 file write
success or any later failure                    1 tool call, 1 file write
```

`mutation_primitive_entered` becomes true immediately before the single
`O_CREAT|O_EXCL` attempt. This deliberately prices an attempted mutation even
when the random sibling collides and the kernel changes nothing.

## 6. Failure Classes

| Stage | Required result |
|---|---|
| malformed request | contract/invalid_request, no syscall |
| fresh root differs | world/root_changed, no mutation |
| parent missing/not directory/symlink/cross-mount | typed world denial |
| parent is not process-owned or is group/world-writable | world/parent_not_private |
| random unavailable or short | world/io_failure, no fallback |
| private name collision | world/temp_name_collision, one attempt |
| write/fsync/close before publish | typed world failure; temp removed |
| final exists as any object type | world/target_exists; object unchanged |
| private cleanup fails | ambiguous/temp_cleanup_failed with residue |
| failure after publish | ambiguous/ambiguous_effect, published=true |
| malformed native record or impossible economics | loud harness failure |

## 7. Evidence Plan

The 7.5 gate requires all of the following:

```text
real absent target is created with exact bytes and mode 0600
symlink parent cannot escape and outside sentinel remains unchanged
missing and non-directory parents are typed
regular file, directory, FIFO and symlink final targets are not replaced
NUL, over-limit path/content and wrong mode fail before mutation
stale root handle cannot write into a replacement root
short write and EINTR complete safely
every injected pre-publish failure leaves no final and no owned temp
cleanup failure is visible and bounded
post-publish and parent-fsync failures are ambiguous, never success
descriptor count returns to baseline and close remains idempotent
production module exports no fault controls
production source contains no shell, path-helper or weaker rename fallback
```

The native battery is split without deleting its red future:

```text
make -C native test-create   must become GREEN in 7.5
make -C native test-read     remains RED until 7.6
```

The combined provider P0 case also remains red until independent read-back is
implemented. A create-only success must not be reported as completion.

## 8. Falsifiers

Step 7.5 fails if any test can:

```text
alter an existing final object
make partial final bytes visible
write through a symlink or into a replacement root
leave an unreported temporary object
turn post-publication uncertainty into success
trigger a retry or weaker syscall fallback
obtain read-back, routing or command authority
```

If a falsifier fires, this document remains as the attempted treatment and the
result document records the contradiction. The code is not canonized merely
because the ordinary happy path works.
