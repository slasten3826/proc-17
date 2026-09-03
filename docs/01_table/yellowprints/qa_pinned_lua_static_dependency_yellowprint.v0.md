# QA Pinned Lua Static Dependency Yellowprint v0

Status:

```text
layer: TABLE
date: 2026-09-03
trigger: v0.1 release battery failed on Manjaro because the system Lua 5.4
         package exposes headers and shared libraries but no static archive
source contract: docs/02_crystall/blueprints/qa_native_supervisor.v0.md
scope: trusted QA runtime dependency acquisition and build identity only
crystallization authorized: yes, machinist 2026-09-03
runtime implementation authorized: only after the paired CRYSTALL exists
QA candidate authority change: none
fallback: forbidden
```

## 0. Table Thesis

The QA supervisor already requires one exact Lua 5.4 static archive and forbids
a dynamic fallback. The defect is not that this requirement is too strict. The
defect is that `native/Makefile` assumes an admitted archive exists at one
distribution-specific path:

```text
/usr/lib/liblua5.4.a
```

The release-safe replacement is a project-owned, source-pinned static build:

```text
verified upstream source archive
-> bounded local extraction
-> fixed static compilation policy
-> project-local liblua.a
-> existing QA dependency-closure digest
```

No runtime or Packet authority changes.

## 1. Observed Host Counterexample

Candy Shop runs Manjaro Linux and has:

```text
lua54 5.4.8-6
/usr/bin/lua5.4
/usr/include/lua5.4/*.h
/usr/lib/liblua5.4.so
pkg-config lua5.4
```

It does not have:

```text
/usr/lib/liblua5.4.a
```

The deterministic suite reached `tests/test_qa_provider_loader.lua`, then the
native fixture build failed before the provider could load. Mortality remained
8/8 and static Lua parsing remained green.

This is a release portability failure, not a candidate rejection and not a
reason to weaken the QA environment identity.

## 2. Existing Laws Preserved

The change preserves:

```text
static PIE QA supervisor
embedded Lua major/minor exactly 5.4
no dynamic supervisor under the existing provider/environment identity
exact runtime dependency closure digest
fixed candidate probe source
fixed QA policy digest
launcher verification of exact supervisor bytes
typed unavailable/loud outcomes instead of fallback
```

The system Lua interpreter and shared development ABI remain host dependencies
for the proc-17 process and launcher module. They are not accepted as the
static supervisor runtime archive.

## 3. Source Identity

The admitted source is:

```text
project: Lua
version: 5.4.8
release date: 2025-05-21
source URL: https://www.lua.org/ftp/lua-5.4.8.tar.gz
source bytes: 374332
sha256: 4f18ddae154e793e46eeab727c59ef1c0c0c2b744e7b94219710d76f530629ae
license: MIT, Copyright 1994-2025 Lua.org, PUC-Rio
```

The exact verified upstream tarball is retained in the repository so ordinary
builds and tests require no network access.

## 4. Four Surfaces

### 4.1 Vendored source archive

Immutable input retained under:

```text
third_party/lua-5.4.8/lua-5.4.8.tar.gz
```

Its digest is verified before extraction on every build/verification entry.

### 4.2 Source metadata and license

Human-readable provenance retained beside the archive:

```text
third_party/lua-5.4.8/SOURCE.md
third_party/lua-5.4.8/LICENSE
```

Metadata does not replace digest verification of the archive bytes.

### 4.3 Local build tree

Derived, disposable output:

```text
native/build/deps/lua-5.4.8/
```

It is ignored by Git. It may be deleted and reconstructed without network.

### 4.4 Admitted static archive

The QA prebuild identity reads exactly:

```text
native/build/deps/lua-5.4.8/src/liblua.a
```

This output is not committed. Its exact bytes are hashed into the existing QA
runtime/dependency identities.

## 5. Build Transaction

```text
verify required host tools
-> verify vendored source SHA-256
-> extract into one owned temporary build directory
-> compile static Lua archive with the declared policy
-> verify version headers and expected archive members
-> atomically replace the disposable final build directory
-> hash final liblua.a through existing QA prebuild identity
-> build static supervisor
-> verify supervisor ELF closure and self-test
```

The build must never download source implicitly. Source acquisition is a
maintainer action outside the deterministic release battery.

## 6. Compile Policy

Required minimum policy:

```text
Lua source 5.4.8 only
ANSI/GNU C99 compiler mode
-O2
-fPIE
-fstack-protector-strong
-D_FORTIFY_SOURCE=3
-DLUA_USE_LINUX
deterministic static archive mode where supported
```

The compiler version, static archive bytes, proc-17 QA policy and probe source
remain inputs to the existing dependency closure identity.

## 7. Writer And Readers

| Surface | Writer | Reader | Authority |
|---|---|---|---|
| upstream tarball | maintainer import after external digest check | source verifier | no runtime authority |
| source metadata/license | maintainer | human/release auditor | provenance only |
| extracted source/build tree | pinned build script | compiler/build verifier | disposable build state |
| `liblua.a` | compiler + archiver | QA prebuild identity and linker | trusted runtime input after digest |
| runtime build id | existing QA build transaction | launcher/provider | existing private QA authority |

No LLM, candidate repository, Packet field or task text selects these paths,
versions, flags or tools.

## 8. Configuration Boundary

The default build uses the project-owned archive and local output. A maintainer
may override `QA_LUA_STATIC_ARCHIVE` and `QA_LUA_STATIC_CFLAGS` explicitly for
a controlled build, but that archive's bytes still enter the runtime identity.

An override does not become a fallback. Missing or invalid inputs fail closed.

## 9. Cleanup Boundary

Only the fixed disposable path below `native/build/deps` may be replaced by the
pinned dependency builder. Repository source, vendored input, system libraries
and arbitrary caller paths are never cleanup targets.

An interrupted build leaves either:

```text
the previous complete local build
or
an owned temporary directory that is not admitted as liblua.a
```

It must not leave a partially written final archive accepted by Make.

## 10. Falsification Controls

```text
PL01 exact vendored archive digest matches the admitted SHA-256
PL02 one-byte source archive mutation fails before extraction/compile
PL03 missing source archive is a typed build failure, not network download
PL04 local static archive can be rebuilt with network unavailable
PL05 default QA build does not read /usr/lib/liblua5.4.a
PL06 final headers declare Lua 5.4.8
PL07 archive contains the expected Lua core and standard library objects
PL08 full QA loader fixture builds on Manjaro with no system static Lua archive
PL09 static supervisor retains no PT_INTERP or DT_NEEDED dependency
PL10 runtime build identity changes when local liblua.a bytes change
PL11 build output and temporary trees remain Git-ignored
PL12 dynamic fallback under the same environment identity remains impossible
```

## 11. Non-Goals

```text
upgrade proc-17 to Lua 5.4.9 or Lua 5.5
replace the host CLI interpreter
publish prebuilt platform binaries
create a package manager
download dependencies during tests
make cross-compiler output byte-identical across hosts
weaken static QA containment
change candidate-visible Lua semantics
```

## 12. Promotion Boundary

This TABLE authorizes only the paired CRYSTALL. Implementation becomes lawful
only when the CRYSTALL fixes exact files, targets, paths, digest behavior,
build flags, cleanup and tests.
