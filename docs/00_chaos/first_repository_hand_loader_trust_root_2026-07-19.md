# First Repository Hand Loader Trust Root

Status:

```text
layer: CHAOS / boundary decision
date: 2026-07-19
roadmap: 7.3 of 7.10
production mutation authority: absent
router authority: unchanged
```

Implementation observation:

```text
This boundary decision was implemented and tested in roadmap step 7.3.
See first_repository_hand_loader_results_2026-07-19.md.
```

## 0. Pressure

The crystall names an exact native Linux provider but did not finish naming the
filesystem authority from which that provider may be loaded.

This is not a packaging detail. A loader based on any of these values would let
task or process environment influence which machine code enters the body:

```text
require("proc17_repository_fs")
package.cpath
current working directory search
HOME or another environment-derived prefix
caller-supplied module path
target repository path
semantic or Packet state
```

The first repository hand cannot begin with an ambiguous hand identity.

## 1. Decision

The loader trust root is the proc-17 distribution that already supplied:

```text
runtime/repository_provider.lua
```

At module initialization the Lua loader reads its own source location, validates
the exact `runtime/repository_provider.lua` suffix, rejects parent traversal and
derives exactly one sibling path:

```text
<same-distribution-root>/native/proc17_repository_fs.so
```

It then calls `package.loadlib` with that exact path and exact initializer symbol:

```text
luaopen_proc17_repository_fs
```

There is no search. `package.cpath` is not read. A missing exact file produces a
closed provider with `provider_unavailable`. A present file that cannot load, has
the wrong initializer, wrong ABI, wrong provider identity, wrong contract, wrong
hard limits or extra exports is a loud harness failure.

The trust premise is intentionally narrow: the host must load the proc-17 Lua
body from a trusted distribution. If that Lua body itself has been replaced,
there is no remaining in-process security boundary to recover. Task semantics,
the target repository and substrate output do not receive this authority.

## 2. Step 7.3 Provider State

The native module introduced in this step is a contract shell:

```text
native ABI: loaded and validated
provider id: loaded and validated
contract id: loaded and validated
hard ceilings: declared identically in Lua and C
root open: unavailable
revalidation: unavailable
create: unavailable
read-back: unavailable
opaque handles: none can be created
```

`available() == true` means the exact native ABI shell is present and validated.
It does not claim that later operation stages have been promoted. Calling
`open_repository` in 7.3 returns a typed `provider_unavailable` record with zero
world cost. Step 7.4 owns the first successful handle.

## 3. No-Fallback Law

These outcomes must remain distinct:

```text
exact module absent
  -> normalized provider exists
  -> available() == false
  -> operations return provider_unavailable

exact module present and valid
  -> available() == true
  -> 7.3 root open still returns provider_unavailable

exact module present but malformed
  -> require/load fails loudly
  -> no Packet death, grave or semantic diagnostic

host never asks for repository hands
  -> loader need not be loaded
  -> ordinary body route remains unchanged
```

No branch may try another `.so`, a Lua writer, shell, `io.open` mutation,
`realpath`, helper process or legacy filesystem tool.

## 4. Hard Limits At This Boundary

The Lua adapter and native ABI declare the same v0 ceilings:

```text
relative path bytes: 1024
component bytes: 255
component count: 64
content bytes: 1048576
file mode: 0600
```

Declaration and identity validation belong to 7.3. Native enforcement against a
live repository handle remains red until 7.4-7.6. The capability registry may
not mint a grant whose path/content bounds exceed these provider ceilings, and
the first-hand mode is exactly 0600 rather than an arbitrary permission mask.

## 5. Falsifiers

Step 7.3 is false if any of these occur:

```text
a hostile package.cpath module is loaded
an absent exact module falls back to another implementation
a wrong-ABI module returns a usable provider
the native module exports test hooks or raw handles
the loader exposes its host path in the provider projection
0644 or another file mode can be minted
provider limits differ between Lua and native metadata
open_repository returns a handle before step 7.4
```

## 6. Boundary After 7.3

Successful completion changes one fact:

```text
before: the native hand has no loadable identity
after:  the exact hand can be identified and loaded, but cannot touch a repo
```

This is deliberately not the first contact with the target filesystem. It is
the installation of a known wrist with a closed fist.
