# proc-17 v0.1.0 Release Manifest

```text
artifact: proc-17
version: v0.1.0
status: release_candidate / tag_pending
release surface: release/v0.1.0
source surface: repository root at the release tag
laboratory status: remains in the same repository and is not part of the claim
```

## 1. Release Claim

This release claims one independently executable, machine-first proc-17 body
with the following bounded public capability:

```text
one isolated plan Packet
or
one isolated create-only build Packet producing one absent root-level UTF-8 file
```

The claim is about the body and its authority boundaries. It is not a claim
that every semantic proposal is correct, that generated software is accepted,
or that the body is already a general coding agent.

## 2. Included Body

The release snapshot includes the source necessary to run and test:

```text
Packet identity, mortality, finality, trace, budget and loss
CALM/CHAOS/BOUNDARY/TENSION body areas
ten registered ProcessLang operators
legacy, shadow and opt-in tree routing boundaries
truth statuses and append-only body evidence
in-memory corpse, grave, compost and bounded lineage continuation
NETWORK@▽ fresh-generation ingress
candidate seal and create-only repository capability
native read-back and effect receipts
bounded QA execution support and terminal evidence retention
machine JSON CLI for one plan or one build Packet
deterministic tests and hostile authority tests
```

The full laboratory documentation remains available in the repository, but it
is not required to understand the narrow CLI claim. Research documents are
not silently promoted into release authority by being present in Git.

## 3. Explicit Exclusions

The release does not authorize or claim:

```text
patch, overwrite, delete, rename or arbitrary repository inspection
commands or unrestricted shell execution
multi-file or directory-creating software transactions
automatic PLAN -> BUILD -> QA orchestration
persistent disk lineage recovery or unbounded historical retrieval
provider-owned hidden conversation continuity
general DISSOLVE mark/sweep or semantic garbage collection
default full-tree authority promotion
cross-model receiver-native anchor compilation
TUI or product UI
universal software acceptance
```

An excluded capability may exist in a laboratory experiment or internal test.
That does not make it part of this release.

## 4. Runtime Authority Contract

```text
LLM/substrate       supplies semantic proposals
Packet body         owns state, movement, truth and death
router              derives the next position from body pressure
registry            dispatches the already committed organ
repository hand    performs only an explicitly granted create-only effect
native read-back    verifies observed bytes independently
manifest           reports the terminal body result
```

The LLM does not select unrestricted tools, mutate runtime truth, bypass
capabilities, revive a terminal Packet, or turn a semantic proposal into an
accepted software result.

## 5. CLI Contract

```sh
lua proc17.lua plan  [TASK | --task-file FILE] [options]
lua proc17.lua build [TASK | --task-file FILE] \
  --project-base ABS --repository REL [options]
lua proc17.lua help
```

Important constraints:

```text
one invocation -> one mortal Packet
omitted session -> fresh isolated session
explicit session -> only that named session may be resumed
build repository -> one explicitly granted relative root
build effect -> one previously absent root-level UTF-8 file
stdout -> one proc17.cli.result.v0 JSON value
```

Exit classes:

```text
0 complete Packet or help
2 invalid input, configuration or session
3 honest non-complete Packet terminal
4 trusted runtime, setup or invariant failure
```

`ok=true` means only that the Packet reached `complete`.

## 6. Verification Baseline

The baseline must be refreshed from a clean checkout immediately before the
release tag. The current laboratory evidence records:

```text
ordinary Lua suite: 140 suites passed
mortality battery: 8/8 passed
static Lua parse: required
native provider build: required for build-path verification
expected-red QA matrix: internal containment evidence, not acceptance
```

Required release commands:

```sh
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
luac -p proc17.lua cli/proc17.lua core/*.lua runtime/*.lua organs/*.lua logic/*.lua
```

The clean-checkout battery must also exercise:

```text
fake plan
fake create-only build
one native create-only build when host dependencies are present
duplicate-path rejection with unchanged original bytes
hostile CLI arguments and private-authority non-disclosure
trusted setup failure as exit 4
```

Live cloud success is supporting evidence, not a deterministic release gate.

## 7. Release Transaction

The release is not complete while any of these remain unresolved:

```text
README and current_state disagree with measured release scope
clean-checkout battery has not passed
release manifest is not committed with the source snapshot
release commit is not identified by an annotated v0.1.0 tag
origin/main and the tag do not point to the published snapshot
worktree contains unintended release changes
```

The final transaction is:

```text
release TABLE/manifest
-> documentation correction only where measured
-> clean-checkout battery
-> release commit
-> annotated v0.1.0 tag
-> push commit and tag
-> verify clean tree and tag target
```

Until that transaction is complete, this directory honestly remains a release
candidate rather than a published release.

## 8. Laboratory Boundary

The root repository continues to host experiments after this candidate is
published. Later work must not rewrite this manifest to make new powers appear
retroactively in v0.1.0. A later version may reference this one and add new
authority only after its own CHAOS, TABLE, CRYSTALL and MANIFEST path.

The first future candidate currently visible in the laboratory is the
receiver-native semantic anchor path:

```text
DeepSeek PLAN
-> portable carrier
-> receiver-native Qwen anchor
-> Qwen BUILD
```

It is intentionally excluded here. Its evidence and open contract live in
`docs/00_chaos/network_receiver_native_semantic_anchor_future_notes_2026-08-31.md`.
