# First Repository Hand Loader Results

Status:

```text
layer: CHAOS / observed implementation evidence
date: 2026-07-19
roadmap: 7.3 of 7.10 complete
production mutation authority: absent
repository root handle authority: absent
router authority: unchanged
```

Sources:

```text
docs/00_chaos/first_repository_hand_threat_model_2026-07-19.md
docs/00_chaos/first_repository_hand_red_battery_results_2026-07-19.md
docs/00_chaos/first_repository_hand_loader_trust_root_2026-07-19.md
docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
```

## 0. Change In Physical State

Before 7.3, the native hand had no loadable identity. After 7.3, proc-17 can
derive exactly one native path from the Lua body that supplied its provider
adapter, load one Lua 5.4 ABI and validate its identity, contract and hard
ceilings.

The loaded module is deliberately a closed shell:

```text
available()                         true
open_repository                    provider_unavailable
opaque repository handles created  0
repository syscalls implemented    0
mutation primitives entered        0
published files                    0
reported world cost                0
```

This is a known wrist with a closed fist. It is not a weak repository hand.

## 1. Loader Boundary Demonstrated

The production adapter derives only:

```text
<body-root>/native/proc17_repository_fs.so
```

from the validated source identity:

```text
<body-root>/runtime/repository_provider.lua
```

It does not consult `package.cpath`, current task data, environment variables,
the target repository, Packet state or substrate output. It invokes exactly:

```text
package.loadlib(exact_path, "luaopen_proc17_repository_fs")
```

Observed outcomes:

| State | Result |
|---|---|
| exact module present with accepted ABI | normalized provider available |
| exact module absent | typed unavailable provider; no fallback |
| hostile same-named module in `package.cpath` | ignored |
| exact module present with wrong ABI | loud harness failure |
| valid shell receives root-open request | typed zero-cost refusal |

The public provider object exposes neither its native path, native table, file
descriptor, opaque handle nor fault-injection hooks.

## 2. ABI And Limits

Observed build environment:

```text
Lua runtime: 5.4.8
Lua development metadata: available through pkg-config lua5.4
C compilation: -Wall -Wextra -Werror
static analysis: GCC -fanalyzer
defined dynamic symbols: luaopen_proc17_repository_fs only
```

Lua and C independently declare the same exact v0 values:

```text
native ABI: proc17.repository.fs.lua54.v0
provider: linux.openat2.renameat2.v0
contract: repository.provider.create_readback.v0
relative path bytes: 1024
component bytes: 255
component count: 64
content bytes: 1048576
file mode: 0600
```

The capability registry now requires exact provider limits, refuses grants above
them and stores a private snapshot at provider registration. Mutating the
provider's later public limits cannot widen an already-created registry.

Native enforcement against paths and content remains red because no repository
handle or native request parser exists yet. Declaration is not reported as
enforcement.

## 3. Executed Evidence

Focused loader suite:

```text
repository-provider-loader: 7 GREEN / 0 RED / 0 SKIP
```

Pre-write security suite:

```text
repository-prewrite-security: 7 GREEN / 0 RED / 0 SKIP
```

Capability suite:

```text
repository-capability: 13 GREEN / 0 RED / 0 SKIP
```

Full repository-hands battery after 7.3:

```text
63 GREEN / 40 RED / 1 explicit SKIP
suite summary: 6 GREEN / 4 RED / 10 total
process exit: 1, expected while later hand stages remain absent
```

The 7.2 baseline was:

```text
48 GREEN / 47 RED / 1 explicit SKIP
```

No later-stage assertion was weakened to obtain the delta. Provider root-open,
atomicity, read-back, effect, completion and route suites remain red.

The ordinary body regression suite remains:

```text
80 suites passed
process exit: 0
```

The C shell and wrong-ABI fixture pass strict compilation and `-fanalyzer`. The
future native atomicity target now reaches the linker and fails on the absent
`proc17_fs_run_test_case` and `proc17_fs_test_close_twice` implementations. That
is the intended red boundary for 7.5-7.6, not a missing-toolchain failure.

## 4. Blocker Ledger After 7.3

| Blocker | State | Named evidence |
|---|---|---|
| B1 trusted native load path | GREEN | loader suite L0-L5 and hostile-cpath probe |
| B2 exact mode policy | GREEN at registry/ABI boundary | prewrite B2; live native enforcement deferred |
| B3 hard ceilings | GREEN declaration and registry snapshot; RED enforcement | loader L1, capability ceiling tests, future native parser |
| B4 secure test fixture | GREEN | fixture guard suite |
| B5 ambiguous temporary residue | RED | effect and native fault tests |
| B6 public effect-data leakage | RED | effect event inspection |
| B7 root identity semantics | RED | root open/replacement tests |
| B8 native artifact policy | GREEN | ignore/source/build controls |

## 5. No First Contact

Step 7.3 did not open the target repository even once. The C module contains no
root traversal, create, write, rename, read-back or filesystem synchronization
algorithm. Its operation functions only allocate a typed Lua refusal record.

All filesystem mutation observed during tests belonged to the identity-owned
fixture harness under `/tmp`, never to a Packet or production provider.

## 6. Next Gate

Step 7.4 may add only:

```text
secure Linux project-base open
descriptor-relative repository-root open
root device/inode identity capture
opaque userdata handle with idempotent close
fresh root revalidation
```

It still may not create a file. The first mutation primitive remains owned by
7.5.
