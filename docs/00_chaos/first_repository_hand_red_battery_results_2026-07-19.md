# First Repository Hand Red Battery Results

Status:

```text
layer: CHAOS / observed test pressure
date: 2026-07-19
roadmap: 7.2 of 7.10
status: safe fixture green; pre-write security frontier red
production repository provider: absent
production filesystem effect: absent
router authority: unchanged
```

Sources:

```text
docs/00_chaos/first_repository_hand_threat_model_2026-07-19.md
docs/00_chaos/repository_hands_red_battery_results_2026-07-19.md
docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
```

## 0. Result

Step 7.2 did not implement a repository hand. It changed the conditions under
which the first hand may be tested.

The resulting split is:

```text
test harness authority:
  can create and destroy one identity-owned disposable root under /tmp

proc-17 production authority:
  capability/intent/action only
  cannot load a native provider
  cannot acquire an effect lease
  cannot mutate a repository
```

The red battery now attacks the safety boundary before implementation rather
than discovering it after the first write.

## 1. Safe Fixture Guard

New test-only surfaces:

```text
native/tests/proc17_fixture_guard.c
tests/support/owned_temp_root.lua
tests/test_repository_fixture_guard.lua
```

The C guard:

```text
creates /tmp/proc17-repository-hand-XXXXXX with mkdtemp and mode 0700
creates only projects/repo/src below the new directory
returns path plus device/inode/mount identity
reopens the root with O_DIRECTORY|O_NOFOLLOW
refuses probe/cleanup when device, inode or mount id differs
recursively removes through directory descriptors
uses statx(..., AT_SYMLINK_NOFOLLOW) before every descent
refuses to cross a mount boundary during cleanup
never traverses a symlink during cleanup
removes the root only after a final identity comparison
```

Its self-test grows real filesystem attacks:

```text
wrong inode cannot clean a live fixture
wrong mount id cannot clean a live fixture
a symlink inside the fixture is unlinked, not followed
a symlink substituted for the root is rejected
an outside sentinel remains intact
the moved original fixture can still be recovered and cleaned
```

The old sequence:

```text
os.tmpname -> os.remove -> mkdir -p -> rm -rf
```

is no longer used by the repository provider suite.

Provider attack setup still uses constant test-only `mkdir`, `ln`, `mv`,
`mkfifo` and `test` commands inside the identity-owned root. No user prompt,
substrate material, action path or repository content is interpolated into those
commands. Runtime shell remains forbidden. This residual harness authority is
named for source/syscall audit in 7.8.

## 2. Fixture Verification

Commands and observations:

```text
make -C native fixture-test
  proc17_fixture_guard ok

lua tests/test_repository_fixture_guard.lua
  5 green, 0 red, 0 skip

GCC -fanalyzer over proc17_fixture_guard.c
  passed with -Wall -Wextra -Werror

ASan + UBSan + LeakSanitizer over proc17_fixture_guard.c
  proc17_fixture_guard ok
  no sanitizer diagnostics

find /tmp -maxdepth 1 -name 'proc17-repository-hand-*'
  no remaining fixture roots
```

The sanitizer binary was built separately under `/tmp` with
`-fsanitize=address,undefined -fno-omit-frame-pointer`. The ptrace-based command
sandbox cannot run LeakSanitizer, so the full leak-enabled self-test was executed
once outside that sandbox. It passed with no ASan, UBSan or leak diagnostics.

## 3. Expanded Red Surface

New or strengthened controls cover:

```text
B1 trusted native loader versus hostile package.cpath/cwd
B2 exact 0600 first-hand mode
B3 fixed native path/component/content ceilings
B5 ambiguous temporary residue and grant quarantine
B6 raw read-back bytes and absolute host path leakage
B7 root replacement between create and read-back
B8 native artifact ignore/clean policy
one-use action/effect lease
same-target expected+1 read-back
non-directory parents
existing directory/FIFO targets
native NUL, path/content hard caps and mode rejection
getrandom failure without fallback
one-attempt temporary collision
zero write
all named pre-publish fault stages
cleanup failure
post-publish fsync ambiguity
descriptor return to baseline
production absence of test hooks/helper-process fallback
```

The native fault contract now has a real header and syntax-checked test source:

```text
native/proc17_repository_fs_test.h
native/tests/test_proc17_repository_fs.c
make -C native contract-test-syntax -> passed
```

This is contract evidence only. The production C implementation is absent, so
none of the native effect assertions is green.

## 4. Observed Battery

Command:

```text
lua tests/red_repository_hands.lua
```

Observed suite result:

```text
repository-hands red baseline: green=4 red=5 total=9
process exit: 1
```

Observed executable controls:

```text
48 GREEN
47 RED
1 explicit SKIP
```

Breakdown:

| Suite | Green | Red | Skip |
|---|---:|---:|---:|
| repository-fixture-guard | 5 | 0 | 0 |
| repository-prewrite-security | 1 | 6 | 0 |
| repository-capability | 12 | 0 | 0 |
| repository-intent | 12 | 0 | 0 |
| repository-action | 13 | 0 | 0 |
| repository-effect | 0 | 14 | 0 |
| repository-provider-linux | 0 | 15 | 1 |
| repository-progress | 0 | 7 | 0 |
| repository-route | 5 | 5 | 0 |
| total | 48 | 47 | 1 |

The non-zero process exit is expected. A red suite may turn green only when its
named implementation exists and the assertion reaches the intended boundary.

## 5. Concrete Defect Reproduced Before Native Code

The first-hand policy says mode 0600. Current capability parsing accepts any
positive permission mask through 0777.

The new control calls `capabilities.mint` with 0644 and receives a valid grant.
It therefore fails as:

```text
B2/TH-M13 first hand admits only mode 0600
broader file mode must be rejected: 420
```

This is not a native-provider defect because the provider does not exist. It is
an already-live authority-width defect at the step-6 boundary. Step 7.3 must
narrow the capability policy before a real writer can be loaded.

## 6. Candidate Hard Ceilings

The red contract now names conservative first-hand ceilings:

```text
relative path bytes: 1024
single component bytes: 255
component count: 64
content bytes: 1048576
file mode: 0600
```

These are candidate v0 protocol bounds, not runtime-confirmed facts. They remain
red until the Lua loader/provider and native parser expose and enforce the same
values independently. If implementation evidence rejects a number, the change
returns to TABLE/CRYSTALL and the tests are revised explicitly; the provider may
not silently choose another limit.

## 7. Blocker Ledger After 7.2

| Blocker | State after tests | Named reader |
|---|---|---|
| B1 trusted native load path | RED | prewrite loader controls and later source audit |
| B2 exact mode policy | RED with reproduced live defect | capability parser test |
| B3 provider hard ceilings | RED | provider metadata plus native request tests |
| B4 secure test fixture | GREEN | fixture guard suite |
| B5 ambiguous temp residue | RED | effect quarantine plus native fault tests |
| B6 public-data leakage | RED | exact repository event inspection |
| B7 root identity semantics | RED | create/read-back replacement fixture |
| B8 native artifact policy | GREEN | gitignore/build-product control |

No blocker is hidden by a skip. P15 cross-device coverage remains one explicit
environmental skip because no safe test-only mount namespace fixture exists yet.
Consequently, no complete cross-device safety claim is made.

## 8. Regression Control

Command:

```text
lua tests/run.lua
```

Observed:

```text
80 suites passed
process exit: 0
```

The new fixture suite remains outside the ordinary runner because it requires a
C compiler and performs test-owned filesystem setup. Capability, intent and
action remain in the normal runner. No existing body route, mortality,
lineage, budget or manifest behavior changed.

Lua syntax, native contract syntax, trailing-whitespace and diff checks pass.

## 9. No First Contact Yet

The only new real filesystem mutations were performed by the explicit test
harness inside unique roots under `/tmp`. The proc-17 Packet, router, organs and
capability registry still cannot call a production writer.

In particular:

```text
runtime/repository_provider.lua is absent
native/proc17_repository_fs.c is absent
runtime/repository_effect.lua is absent
repository_capability.begin_effect remains unavailable
```

Therefore step 7.2 is not a weak implementation of the hand. It is the measured
red perimeter around the hand that may be built next.

## 10. Next Gate

Step 7.3 may implement only:

```text
fail-closed trusted native loader
fixed provider identity and ABI
exact hard-limit declaration
mode 0600 policy narrowing
production API without test hooks
```

It must not yet authorize root traversal or a real file create. Step 7.4 owns
root open/revalidation; step 7.5 owns the first mutation primitive.
