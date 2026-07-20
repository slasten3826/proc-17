# First Repository Hand: Independent Read-Back Plan

date: 2026-07-20
status: hypothesis tested; roadmap step 7.6 complete
predecessor: first_repository_hand_atomic_create_results_2026-07-19.md
authority boundary: native provider plus strict Lua adapter only
result: first_repository_hand_independent_read_results_2026-07-20.md

## 1. Question

Step 7.5 can atomically create one absent text file. Its receipt says that the
provider reached publication, but a receipt is still the writer speaking about
its own act.

Step 7.6 asks a narrower question:

```text
Can a separate bounded observation establish what occupies the exact target
path after create, without granting a general repository-read capability?
```

This step does not decide that work is complete. It only returns an ephemeral
observation to the trusted effect layer. Digest comparison, trace evidence,
LOGIC and completion belong to 7.7.

## 2. Authority Granted In This Step

The native provider may:

```text
re-open the already granted project base and repository root
compare both identities with the opaque repository handle
open one caller-supplied path accepted by the existing repository grammar
classify its final object as missing, regular_file or other
read at most max_bytes from a regular file
return those bytes transiently to trusted Lua
```

It may not:

```text
enumerate a directory
follow a symbolic or magic link
cross a mount boundary
read a second path internally
interpret file contents
compute task completion
write, repair, retry the action or route the Packet
put raw bytes or host paths into Packet, trace, grave or manifest
```

`native.read_text_file(handle, relative_path, max_bytes)` treats `max_bytes`
as the final hard allocation/read ceiling. In 7.7 the exact create verifier will
derive that value as `expected_bytes + 1`. The native provider does not infer
the expected length and therefore cannot silently widen the bound.

Hard provider ceiling:

```text
1 <= max_bytes <= max_content_bytes + 1
```

The extra byte exists only to prove that a target is longer than the expected
create content without reading the rest of it.

## 3. Observation Transaction

One read-back call performs one bounded transaction:

```text
1. Validate the opaque handle, exact argument count, relative path and bound.
2. Freshly re-open project base and repository root.
3. Compare device, inode and mount identity with the handle.
4. Open the target parent descriptor-relative with BENEATH, NO_SYMLINKS,
   NO_MAGICLINKS and NO_XDEV.
5. Open only the final component as O_PATH | O_NOFOLLOW and classify it.
6. ENOENT for that final component becomes observed/missing.
7. A present non-regular final object becomes observed/other and is never read.
8. Re-open a regular target read-only, nonblocking and no-follow; compare its
   identity with the classification descriptor.
9. Read at most max_bytes with a bounded EINTR policy.
10. Compare identity and metadata before/after the read.
11. Re-open the named root and exact target once more; reject replacement,
    rename or concurrent mutation instead of returning a mixed observation.
12. Close every descriptor before success or typed failure.
```

The nonblocking open is defensive: even if a regular target is raced into a
FIFO or device between classification and open, the provider must not hang or
perform device semantics. The identity comparison then rejects the race.

## 4. Truth And Economics

A successful provider record means only:

```text
this bounded observation happened at runtime
```

It does not mean:

```text
the bytes equal the requested content
the action is verified
the work is complete
```

Every admitted read-back call costs exactly one provider tool call and zero file
writes. Request/closed-handle rejection costs zero calls. All outcomes keep:

```text
mutation_primitive_entered = false
published = false
```

Raw content may exist only in the provider return value. Step 7.7 must consume
it into length/digest evidence without copying it into trace or public errors.

## 5. Typed Outcomes

Success:

```text
observed + missing       -> no content/bytes fields
observed + other         -> no content/bytes fields
observed + regular_file  -> bytes and content, both <= max_bytes
```

Failure families:

```text
invalid request / closed handle                   contract
root missing, changed or no longer representable  world
parent containment, symlink or permission denial  world
target identity changed during observation        world
target bytes changed while being read              world
bounded read/open/close failure                    world
unsupported openat2/statx environment              world/provider_unavailable
```

Read-back performs no mutation, so a failed observation is not an ambiguous
filesystem effect. It is a failed witness. The earlier create receipt remains
separately true, but no verification may be minted from this call.

## 6. Falsifiers

The implementation hypothesis is false if any of these occur:

```text
F1  a root replacement is read through the stale handle
F2  an intermediate or final symlink is followed
F3  a directory, FIFO, socket or device is opened with read semantics
F4  more than max_bytes is allocated or returned
F5  repeated EINTR can keep the provider alive without a bound
F6  a target replacement produces a successful mixed observation
F7  concurrent growth/shrink/rewrite produces successful stable evidence
F8  malformed request reaches a syscall or costs a tool call
F9  a failure reports mutation or file-write cost
F10 descriptors leak on any success/failure branch
F11 raw observed content appears in an error, trace, residue or manifest
F12 read-back silently becomes task completion or route authority
```

## 7. Required Evidence

Native fault harness:

```text
regular exact read
missing target
directory, symlink and FIFO classification without read
hard bound and expected-plus-one behavior
open/read fault
bounded perpetual EINTR
concurrent growth/replacement rejection
descriptor baseline on every branch
```

Real Linux provider:

```text
create then exact independent read
root replacement between create and read is denied
supplied hard bound is respected
missing/non-regular outcomes have no content
malformed requests remain zero-call contract failures
```

Repository checks:

```text
normal Lua suite remains green
7.6 provider controls turn green
7.7 effect/progress/route controls remain red
compiler warnings and static analyzer remain green
ASan/UBSan fault harness remains green where host policy permits
native module still exports only its one Lua initializer
```

## 8. Promotion Boundary

7.6 is complete only when the independent read primitive and adapter are proven.
Completion is still forbidden:

```text
created != verified
observed != matched
receipt + raw observation != work completion
```

The next step, 7.7, may consume the ephemeral bytes, calculate their digest,
record bounded verification evidence and let LOGIC judge the exact create. It
must not weaken any deny rule established here.
