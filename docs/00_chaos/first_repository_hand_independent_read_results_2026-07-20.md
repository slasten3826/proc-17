# First Repository Hand: Independent Read-Back Results

date: 2026-07-20
status: roadmap step 7.6 complete
plan: first_repository_hand_independent_read_plan_2026-07-20.md
next: roadmap step 7.7, effect evidence and LOGIC without route authority

## 1. Result

The trusted Linux provider can now perform a separate bounded observation after
an atomic create:

```text
create receipt -> fresh root revalidation -> exact target classification
               -> bounded regular-file read -> fresh named reobservation
```

This closes the provider-level gap left by 7.5:

```text
the hand can create one absent text file
the hand can independently observe one exact target through the same root grant
```

It does not yet close the body-level effect:

```text
created != verified
observed != matched
receipt + observation != completion
```

No Packet, substrate, router, trace writer or completion gate received new
authority in this step.

## 2. Native Read Transaction

`native.read_text_file(handle, relative_path, max_bytes)` now:

```text
validates exact argument count, path grammar and 1..1,048,577 byte bound
rejects a closed or forged handle
freshly re-opens project base and repository root
compares device, inode and mount identity with the opaque handle
opens the exact parent beneath root without symlinks, magic links or xdev
classifies the final component through O_PATH | O_NOFOLLOW
returns missing without content for exact ENOENT
returns other without content for directories, symlinks, FIFOs and other types
opens only a regular file with O_RDONLY | O_NONBLOCK | O_NOFOLLOW
compares the classification descriptor and read descriptor identities
reads no more than the supplied hard bound
terminates repeated EINTR after 65 read calls
compares file identity, size, mode, ownership, link count, mtime and ctime
freshly re-opens the named root and target for all three target classes
rejects replacement or concurrent mutation instead of mixing observations
closes every transaction descriptor before returning
```

The final reobservation is common to `missing`, `other` and
`regular_file`. A successful target kind is therefore not merely an
observation through a descriptor that may have been renamed away while the
call was running.

## 3. Lua Adapter

`runtime/repository_provider.lua` now validates a strict read envelope:

```lua
{
  relative_path = string,
  max_bytes = integer,
}
```

Unknown keys, malformed paths, zero/fractional/oversized bounds and closed
handles fail before a provider call. Success is accepted only as:

```text
observed/missing      with no bytes or content
observed/other        with no bytes or content
observed/regular_file with bytes == #content <= request.max_bytes
```

Every admitted observation reports:

```text
tool_calls = 1
file_writes = 0
mutation_primitive_entered = false
published = false
```

Impossible target/content combinations, mutation claims, residue, unknown
stage/code pairs and impossible economics remain loud trusted-contract
failures. The old `read_back_not_promoted` shell and its now-readerless
validation helper were removed.

## 4. Test Evidence

### 4.1 Native fault battery

```text
make -C native test-read
test_proc17_repository_fs ok
```

Read-side controls now cover:

```text
expected-bytes-plus-one bounded observation
zero-byte and exact regular observations
the complete 1 MiB content boundary through a 1 MiB + 1 hard allowance
missing target
directory, final symlink and FIFO classification without read()
open and read failure
permanent EINTR termination after 65 calls
concurrent growth rejection as read_unstable
target replacement rejection as target_changed
descriptor return to baseline on every tested branch
```

The create-only target remains green, proving that the read fault machinery did
not change atomic create behavior.

### 4.2 Real Linux provider

Before 7.6:

```text
repository-provider-linux: 19 GREEN / 3 RED / 1 SKIP
```

After 7.6 and the added hostile controls:

```text
repository-provider-linux: 29 GREEN / 0 RED / 1 SKIP
```

The one skip remains the explicitly unconfigured bind-mount fixture
`PROC17_TEST_BIND_MOUNT`; it is not counted as evidence.

The former red controls are now green:

```text
create plus independent exact read
root replacement between create and read
hard bounded read
```

Additional real controls prove missing/non-regular projections, repository-root
targets, malformed adapter/native envelopes, closed handles and symlink-parent
denial. The FIFO control completes without blocking.

### 4.3 Layer boundary

```text
repository-hands staged corpus: 8 GREEN suites / 3 RED suites / 11 total
```

The three remaining red suites are exactly:

```text
repository_effect
repository_progress
repository_route
```

They remain red because `runtime/repository_effect.lua` and the body-owned
verification/completion chain do not exist. Provider read-back did not make
those claims accidentally.

The normal repository-independent body remains:

```text
lua tests/run.lua
80/80 suites green
```

## 5. Structural And Memory Checks

```text
strict C compilation with -Wall -Wextra -Werror: GREEN
GCC -fanalyzer production source: GREEN
GCC -fanalyzer test build: GREEN
ASan + UBSan complete create/read fault battery: GREEN
git diff --check: GREEN
GNU_STACK: RW, non-executable
GNU_RELRO: present
BIND_NOW/NOW: present
defined dynamic exports: luaopen_proc17_repository_fs only
forbidden shell/exec/overwrite primitive source scan: empty
```

LeakSanitizer remains unavailable inside the current ptrace boundary. The
attempt failed with the explicit LeakSanitizer ptrace diagnostic and is not
counted as green evidence. ASan/UBSan were rerun with only leak detection
disabled. Native descriptor-baseline tests remain green.

## 6. Corrections Discovered During 7.6

### 6.1 Readerless promotion shell

After the real read method replaced the unavailable shell, strict compilation
found the old C `unavailable()` helper had no reader. It was removed instead
of being retained as archaeology in production code. The Lua shell validator
and dispatcher became readerless for the same reason and were also removed.

### 6.2 Uniform named reobservation

The first implementation reobserved only regular files after their byte read.
Missing and non-regular results were safe for completion because 7.7 must reject
them, but their observation law was weaker. The transaction was refactored so
all target classes pass one `reobserve_named_target` mechanism. This closes
the gap before it becomes a public truth distinction.

### 6.3 Bound terminology

The native `max_bytes` value is the final hard read/allocation bound. It is
not itself an expected file length. In 7.7 the effect verifier must pass:

```text
max_bytes = expected_content_bytes + 1
```

This separation keeps resource physics in the provider and content comparison
in LOGIC.

## 7. Residual Boundary

The native provider method accepts one trusted relative path because it is the
mechanism below the effect layer. At present only trusted Lua holding the opaque
repository handle can invoke it; Packet and substrate cannot obtain the handle
or call the method.

Step 7.7 must add the missing action-owned restriction:

```text
successful exact create receipt exists
read path is derived from the same canonical action, never supplied anew
read bound is derived from the same action content length
raw bytes are consumed transiently into length and SHA-256
only bounded digest/length evidence enters trace
LOGIC accepts or rejects without promoting semantic truth
```

Until then there is a safe provider primitive, not a body-routed hand.

## 8. Next Step

Roadmap 7.7 implements the effect boundary without changing router authority:

```text
one private effect lease
attempt -> create receipt -> exact bounded read
ephemeral digest comparison
accepted/rejected verification event
typed provider failure and ambiguity
actual economics
no work completion yet unless the required RUNTIME/LOGIC chain is present
```

The existing red effect corpus is the specification. No new route is authorized
merely because the provider primitive is now green.
