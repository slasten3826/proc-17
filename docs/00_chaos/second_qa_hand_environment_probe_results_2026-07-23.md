# Second QA Hand Environment Probe Results

status: runtime evidence for roadmap step 8.5.5C
date: 2026-07-23
authority: implementation plus exercised Linux probes, not candidate execution
production candidate execution authority: forbidden

## Implemented Boundary

Step `8.5.5C` proves that the current host can construct the exact world needed
by the second hand. It does not yet put a user repository or hostile candidate
inside that world.

The production probe path is now:

```text
runtime/qa_provider.lua
  -> fixed bounded proc17_qa_launcher.so
  -> module SHA-256 before package.loadlib
  -> exact closed Lua ABI
  -> open and SHA-256 the fixed supervisor sibling
  -> fork
  -> fixed descriptors
  -> execveat the already-open static supervisor
  -> one authenticated bounded wire transaction
  -> clone3 the isolated probe world
  -> return one normalized qa.environment.v0
```

`run_lua54_test_suite` exists only to close the ABI. It returns
`candidate_execution_not_promoted` without borrowing source authority or
starting a candidate.

## Static And Build Identity

The supervisor is built as an x86_64 static PIE with:

```text
no PT_INTERP
no DT_NEEDED
exact static Lua 5.4 archive
static libc, libm and libdl included in the dependency-closure digest
policy header included in the policy and closure identities
immutable probe.lua bytes included in the closure identity
final supervisor bytes hashed before launcher compilation
```

The launcher hashes the exact opened supervisor and the bounded immutable probe
fixture before `fork`. The supervisor hashes the same executable fd after
`execveat`, before closing it. A launcher loaded before a sibling rebuild
correctly rejects the new sibling; the control suite therefore performs one
cold build before its first `package.loadlib` and never mixes build epochs.

## Exercised Environment

The successful environment probe exercised all of the following rather than
checking only for declarations:

```text
CLONE_NEWUSER | CLONE_NEWNS | CLONE_NEWPID
CLONE_NEWNET | CLONE_NEWIPC | CLONE_NEWUTS
setgroups denial plus exact uid/gid map
private mount propagation
private tmpfs root
read-only, nosuid, nodev and noexec source
bounded writable scratch tmpfs
pivot_root plus old-root detach
fresh bounded Lua 5.4 state
closed package.cpath/loadlib/debug/shell surfaces
empty host environment plus exact HOME/TMPDIR/locale/timezone
exact rlimits
architecture-checked seccomp allowlist
source-write denial
fork/clone denial by SIGSYS
execveat denial by SIGSYS
socket denial by SIGSYS
bounded output pipe and hash
pidfd/timerfd wait and complete reap
namespace/mount destruction on exit
```

The successful native report is normalized by `core/qa_schema.lua`. The same
report passes through `runtime/qa_environment.lua` and receives a stable
content-derived `qa-environment:<sha256>` identity.

## Loader Boundary

`runtime/qa_provider.lua`:

```text
derives one sibling module path from its own source identity
reads at most 16 MiB
hashes bytes before package.loadlib
loads only luaopen_proc17_qa_launcher
requires the exact key set, ABI, provider, supervisor, limits and functions
ignores package.cpath
returns detached availability records
keeps native paths and module handles private
returns an unavailable adapter when the exact module is absent
fails loudly when a present module has the wrong ABI
```

The ordinary loader suite also proves that the probe-only native boundary
cannot execute a candidate even when called directly.

## Runtime Findings During Construction

Four defects were found by the live probe or final static analysis and fixed before evidence was
accepted.

### Result-pipe writer retained by parent

The first launcher kept its duplicated result write-end in the parent. The
parent then waited for an EOF that it prevented itself. Parent-owned child ends
are now closed immediately after `fork`, and the fd-count control is green.

### Self identity through a procfs symlink

Opening `/proc/self/exe` with `O_NOFOLLOW` correctly rejected the symlink. The
supervisor now hashes the exact executable fd used by `execveat`, then closes
that fd before namespace creation. There is no second pathname lookup.

### Fixed descriptor collision

Because the launcher closes `0/1/2`, the supervisor's first internal pipe may
legally receive those numbers. The first output setup treated a write-end at
fd 1 as a high temporary descriptor and closed stdout after `dup2(1,1)`.
Internal candidate pipe ends are now duplicated above the fixed range before
`fork`; only then are stdout and stderr installed. A raw write witness proves
the output path independently of libc buffering.

These are all descriptor-ownership defects. None was repaired by weakening
containment.

### Ambiguous close ownership on a rejected probe fixture

The bounded probe-source verifier originally closed `probe.lua` inside one
compound predicate and then retained the same numeric descriptor for generic
cleanup. A rare `close` error could therefore drive cleanup into a second
close against a descriptor whose ownership was no longer knowable. GCC
`-fanalyzer` reproduced the path.

Probe-source validation is now staged explicitly. The descriptor is marked
released immediately after the one close attempt, and every failure path has
one visible owner. The fixed `3..6` exec descriptors are likewise tracked and
closed individually on setup or `execveat` failure. Both native translation
units pass `-fanalyzer` with warnings promoted to errors.

## Probe-only Source Mount Qualification

On the observed Linux 6.18 host:

```text
open_tree(..., OPEN_TREE_CLONE) on the inherited source mount -> EINVAL
raw mount("/proc/self/fd/3", ..., MS_BIND)                    -> EINVAL
```

The internal probe therefore reads one bounded absolute pathname from the
already-verified source fd, bind-mounts that fixed internal fixture and then
requires the mounted `device + inode` to equal the original fd. Rename or
replacement between those observations fails closed.

This is authorized only for the immutable step-C probe fixture, whose bytes
are also bound into the build closure. It is not authority for step D to mount
an arbitrary candidate repository. A candidate source may itself live under a
host path later hidden by the private tmpfs; step D still requires a
descriptor-staging solution that works for that case without accepting a
caller path.

## Evidence

Native controls:

```text
QN01-QN15  green
QN16-QN20  red by design
```

The newly green range covers the wire, shared handle ABI, closed launcher ABI,
static closure, supervisor identity, exec boundary, fd contract, namespaces,
mounts, restricted Lua, seccomp, limits and production environment probe.

Expected-red QA matrix:

| Suite | Green | Red |
|---|---:|---:|
| fixture guard | 5 | 0 |
| contract | 14 | 1 |
| execution | 5 | 15 |
| native supervisor | 15 | 5 |
| check/verdict | 0 | 24 |
| total | 39 | 45 |

The total is exactly the predicted step-C matrix. No candidate, evidence or
verdict control became accidentally green.

Regression evidence:

```text
lua tests/run.lua                         103 suites green
tests/test_qa_provider_loader.lua         6/6 green
lua tests/smoke_mortality_battery.lua     8/8 green
make -C native qa-wire-test               green
make -C native qa-static-closure-test     green
make -C native qa-launcher-contract-test  green
make -C native qa-launcher-identity-test  green
make -C native qa-launcher-exec-test      green
make -C native qa-launcher-fd-test        green
make -C native qa-native-probe-test       green
GCC -fanalyzer supervisor + launcher      green
git diff --check                          green
```

## Result And Next Gate

The body can now answer one mechanical question truthfully:

```text
Can this exact host, launcher, supervisor, runtime closure and policy construct
the world in which the second hand would be allowed to run?
```

On the observed host, the answer is a runtime-confirmed environment record.
That record is not evidence that any software candidate was tested.

The next slice is `8.5.5D`:

```text
one isolated clean/rejected Lua test transaction
using one exact sealed repository source lease
with no verdict/body promotion yet
```

`QN16-QN20`, execution evidence and every verdict control remain closed until
that transaction and its hostile/fault/leak follow-up are implemented.
