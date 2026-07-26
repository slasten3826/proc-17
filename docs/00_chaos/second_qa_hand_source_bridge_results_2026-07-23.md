# Second QA Hand Sealed-Source Bridge Results

status: runtime evidence for roadmap step 8.5.5B
date: 2026-07-23
authority: implementation and exercised tests, not QA promotion

## Implemented Boundary

The repository registry remains the sole owner of root authority. Candidate
seal now moves one already-open repository handle out of every public
source-write grant and into the private sealed-root record. Public grants are
terminally sealed and expose no handle.

The private API is now executable:

```text
reserve_qa_source -> one opaque lease bound to exact sealed coordinates
with_qa_source    -> one trusted callback, detached result only
finish_qa_source  -> sticky disposition and exact handle close
```

The binding checks session, lineage, generation, repository, root authority,
lifecycle, root fingerprint, closure, request and inventory identities. A
second transaction cannot reserve the same source. Callback failure or an
attempt to return the private handle consumes the lease and cannot reopen the
first hand.

## Shared Native ABI

`native/proc17_repository_handle_abi.h` is now the one closed prefix shared by
the repository provider and the future QA launcher. The first hand writes the
magic, ABI version, struct bound, descriptors and exact device/inode/mount
identities into that prefix.

The narrow launcher-side borrower implemented in this slice:

```text
checks the exact userdata metatable and ABI prefix
rejects closed or malformed handles
duplicates repository_fd with F_DUPFD_CLOEXEC
re-observes device/inode/mount on the duplicate
invokes one C-only consumer
closes the duplicate on every exercised branch
```

It does not expose a Lua launcher module, execute a process, create namespaces,
mount source, load candidate code or promote QA readiness.

## Evidence

```text
make -C native qa-shared-abi-test   green
make -C native test                 green
tests/test_qa_source_bridge.lua     4/4 green
lua tests/run.lua                   102 suites green
mortality battery                   8/8 green
```

Expected-red QA control delta:

```text
contract          14 green / 1 red
execution          5 green / 15 red
native              2 green / 18 red
check/verdict        0 green / 24 red
fixture guard        5 green / 0 red
total               26 green / 58 red
```

Newly green controls are exactly `QE06`, `QE07` and `QN04`. All process,
containment, provider, receipt, evidence and verdict controls remain red.

## Result

The second hand can now receive one exact sealed source descriptor through a
private, one-use, non-writing bridge. It still cannot execute anything. The
next slice may build the closed launcher ABI on this source boundary without
changing first-hand repository authority.
