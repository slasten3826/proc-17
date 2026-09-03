# QA Pinned Lua Static Dependency Blueprint v0

Status:

```text
layer: CRYSTALL
date: 2026-09-03
source table:
  docs/01_table/yellowprints/qa_pinned_lua_static_dependency_yellowprint.v0.md
existing parent contract:
  docs/02_crystall/blueprints/qa_native_supervisor.v0.md
implementation authority: exact files and controls in this blueprint only
candidate/Packet/QA semantic authority change: none
platform: Linux build path
dynamic fallback: forbidden
implicit network access: forbidden
```

## 0. Decision

Replace the default distribution-specific static Lua archive path with one
project-owned build of the exact already-admitted Lua 5.4.8 source.

```text
old default:
  /usr/lib/liblua5.4.a

new default:
  native/build/deps/lua-5.4.8/src/liblua.a
```

The old path remains usable only through an explicit maintainer override. It
is no longer an implicit assumption or fallback.

## 1. Exact New Files

```text
third_party/lua-5.4.8/lua-5.4.8.tar.gz
third_party/lua-5.4.8/SOURCE.md
third_party/lua-5.4.8/LICENSE
native/build_pinned_lua_static.sh
tests/test_qa_pinned_lua_static.lua
```

Modify:

```text
.gitignore
native/Makefile
tests/run.lua
README.md
release/v0.1.0/README.md
release/v0.1.0/MANIFEST.md
docs/03_manifest/current_state.md
```

## 2. Source Contract

```text
URL:
  https://www.lua.org/ftp/lua-5.4.8.tar.gz
size:
  374332 bytes
SHA-256:
  4f18ddae154e793e46eeab727c59ef1c0c0c2b744e7b94219710d76f530629ae
archive root:
  lua-5.4.8/
license:
  MIT, Copyright 1994-2025 Lua.org, PUC-Rio
```

The tarball is verified before it is admitted into Git and again before each
local extraction. Test/build paths never fetch it.

## 3. Builder Interface

```sh
native/build_pinned_lua_static.sh build
native/build_pinned_lua_static.sh verify
```

`build`:

```text
verifies fixed source bytes
creates native/build/deps if absent
extracts into an owned temporary directory
compiles only the `a` upstream target
verifies headers and archive members
atomically installs the complete extracted/build tree
prints the final archive digest
```

`verify`:

```text
verifies source digest
requires the complete local output
verifies exact Lua version headers
verifies expected archive members
prints the final archive digest
performs no mutation
```

Unknown arguments fail with exit status 2. Source, toolchain, compilation or
verification failures exit nonzero and do not produce an admitted final path.

## 4. Fixed Paths

All paths are derived from the physical location of the builder script, not
from caller cwd or task input.

```text
repository root:
  parent of native/
source archive:
  third_party/lua-5.4.8/lua-5.4.8.tar.gz
build parent:
  native/build/deps
final build root:
  native/build/deps/lua-5.4.8
final archive:
  native/build/deps/lua-5.4.8/src/liblua.a
```

Temporary directories are created only under `native/build/deps` and carry a
fixed `lua-5.4.8.tmp.*` prefix.

## 5. Compile Contract

The builder invokes the upstream `src/Makefile` `a` target with:

```text
CC=<host CC or cc> -std=gnu99
AR=<host AR or ar> rcsD
RANLIB=<host RANLIB or ranlib> -D
SYSCFLAGS=-DLUA_USE_LINUX
MYCFLAGS=-fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=3
```

The upstream Makefile supplies `-O2 -Wall -Wextra -DLUA_COMPAT_5_3`.

If a host archiver does not support deterministic mode, the build fails. It
does not silently weaken the compile policy under the same closure identity.

## 6. Verification Contract

Source verification:

```text
sha256sum exact vendored tarball
compare complete lowercase hex digest
reject mismatch before tar extraction
```

Version verification reads the extracted `src/lua.h` and requires:

```text
LUA_VERSION_MAJOR "5"
LUA_VERSION_MINOR "4"
LUA_VERSION_RELEASE "8"
```

Archive verification requires at least:

```text
lapi.o
lstate.o
lvm.o
lauxlib.o
lbaselib.o
linit.o
```

The final archive digest is observational output. The existing
`proc17_qa_prebuild.h` transaction remains the authority that binds those
bytes into the QA runtime dependency closure.

## 7. Makefile Contract

Add:

```text
QA_LUA_VERSION
QA_LUA_BUILD_ROOT
QA_LUA_STATIC_BUILDER
qa-lua-static
qa-lua-static-verify
```

Default:

```make
QA_LUA_STATIC_ARCHIVE ?= $(QA_LUA_BUILD_ROOT)/src/liblua.a
QA_LUA_STATIC_CFLAGS ?= -I$(QA_LUA_BUILD_ROOT)/src
```

The absolute archive target depends on the vendored tarball and builder. The
existing QA prebuild identity dependency therefore builds the local archive
before hashing it.

An explicit caller override remains possible because the existing variables
are public Make inputs. Make never searches system paths or falls back after a
failed default local build.

## 8. Git Contract

Committed:

```text
verified source tarball
source metadata and license
builder
contracts and tests
```

Ignored:

```text
native/build/
```

Generated dependency output, object files and archive bytes never enter the
source snapshot.

## 9. Test Contract

`tests/test_qa_pinned_lua_static.lua` runs before the QA provider loader and
asserts:

```text
vendored archive byte count
vendored archive SHA-256 through proc-17 core digest
builder build succeeds
builder verify succeeds
local archive exists under native/build/deps
archive is not a system path
```

The existing QA provider loader and native supervisor suites remain the
integration proof for linker, loader, environment identity and static closure.

No test mutates the committed source archive.

## 10. Failure And Cleanup

Builder failure before final installation removes only its owned temporary
directory. It leaves any prior complete final build untouched.

Builder success moves the old complete build to one owned backup path, moves
the new complete build into final position, then removes the backup. If final
installation fails, it restores the prior complete build when possible and
returns nonzero.

No path supplied by a candidate, Packet, substrate response or repository
grant reaches this transaction.

## 11. Compatibility

Supported:

```text
Manjaro/Arch host with shared lua54 package but no static archive
Debian-like host with Lua 5.4 development package
clean build with no network after repository checkout
explicit maintainer archive/header override
```

Not promised:

```text
non-Linux QA supervisor
cross-compiled target
byte-identical liblua.a across different compilers or libc toolchains
Lua versions other than 5.4.8 under this environment identity
```

## 12. Acceptance Gate

Implementation is accepted only when:

```text
PL01-PL12 have direct or inherited coverage
new pinned dependency test is green
full tests/run.lua completes green on Candy Shop
mortality remains 8/8
static Lua parse is green
git diff --check is green
no network request occurs during ordinary build/test
QA static closure verification remains green
```

Failure of host namespace/security primitives may remain a typed unavailable
environment only where the existing QA contract permits it. Missing system
`/usr/lib/liblua5.4.a` is no longer an accepted blocker.
