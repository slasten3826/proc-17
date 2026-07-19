# Repository Capability Boundary Manifest v0

Status:

```text
manifest
implemented and locally verified 2026-07-19
roadmap step: 6 of 10
source chaos: docs/00_chaos/capability_safe_repository_hands_notes_2026-07-19.md
source red baseline: docs/00_chaos/repository_hands_red_battery_results_2026-07-19.md
source table: docs/01_table/yellowprints/capability_safe_repository_hands_yellowprint.v0.md
source crystall: docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
scope: capability, exact intent and immutable authorized action
filesystem effect authority: absent
router authority change: absent
decision truth status: document_decision
```

## Result

The body now has the complete authority boundary immediately before its first
repository hand:

```text
trusted host repository root
  -> private session capability registry
  -> detached public grant projection

current exact repository work unit
  -> pure repository intent
  -> intent/grant intersection
  -> immutable authorized action
  -> exact review/effect/reconcile action schemas
```

This step grants no filesystem effect. It proves that the body can name one
permitted future action without placing the authority required to perform that
action inside the Packet, trace, corpse, carrier or semantic material.

## Session Boundary

`Packet` now accepts an optional non-secret `session_id`. Standalone packets do
not receive an implicit session. `lineage_runner` supplies the host session id
to every generation and overrides any conflicting generation option.

A repository grant is resolved only by the exact conjunction:

```text
session_id
lineage_id
repository_id
operation
active grant revision
```

The semantic field may contain a `semantic_grant_id`, but capability resolution
ignores it. Semantic material cannot mint, choose, widen or retain authority.

## Private Capability Registry

`runtime/repository_capability.lua` owns a weak-key private registry. Public
registry and grant projections contain no provider object, directory handle,
absolute host path or mutable private record.

The registry implements:

```text
new
mint
resolve
project
revoke
```

Minting validates one exact provider contract, root identity, operation set,
bounds and file policy. Resolution returns typed missing, ambiguous and revoked
outcomes. Every public projection is detached from private state.

`begin_effect` deliberately returns `repository_effect_unavailable`. A grant is
therefore real authority held by the host, but no code path can spend it before
step 7 supplies the exact provider transaction.

## Pure Intent

`runtime/repository_intent.lua` derives one
`repository.action_intent.v0` only from a current field-native structured work
unit produced by an actual structure-formation event.

The derivation verifies:

```text
current packet generation
live or selected activation
exact formed-unit membership
work-unit id and version
formation event identity
supported operation
strict relative path grammar
valid UTF-8 text without NUL
exact byte length and SHA-256
exact provenance and coverage refs
```

Suppressed or dissolved work cannot become an intent. Required multi-item sets
return `multi_item_scheduling_deferred`; the body does not silently choose one
file. Empty text is valid and remains an exact zero-byte artifact.

Intent derivation is pure: it neither mutates the Packet nor contacts a
provider.

## Authorized Action

`runtime/repository_action.lua` intersects the intent with trusted host context
and one exact live grant. Authorization is build-only and rejects terminal
packets, stale field versions, mismatched generations, wrong repositories,
unsupported operations and exceeded bounds.

The resulting `repository.action.v0` binds:

```text
packet, session, lineage and generation
work-unit id, version and formation event
grant id and revision
repository and root fingerprints
operation and target precondition
content referent, byte length and SHA-256
required budget
scope and provenance refs
```

The action carries a content referent, not a second content copy. Immediately
before a future effect, `materialize` revalidates the current field object and
returns ephemeral content plus a detached grant projection. No private handle
crosses that boundary.

## Pressure Schema Boundary

`runtime/pressure_action.lua` now understands three exact, non-mergeable modes:

```text
repository_action_review -> ☱
repository_effect        -> ☶
repository_reconcile     -> ☱
```

Each schema requires the same exact action identity, work/version/formation
refs, grant revision and evidence shape. Caller logic options may coexist but
cannot replace the repository subtree. This is schema preparation only: no new
pressure reader, route authority or organ effect is active in step 6.

## Security Claims Demonstrated

The green boundary tests demonstrate:

```text
no implicit session identity
one lineage session survives across generations
grant scope cannot cross session, lineage or repository
ambiguous and revoked grants do not resolve
public projections cannot mutate private authority
semantic grant names have no authority
plan mode cannot authorize a repository action
stale generation and field versions are rejected
path, content and bound violations are rejected
action identity is stable and tamper-evident
raw content and host authority cannot enter an action projection
pure intent/action qualification leaves Packet identity unchanged
no provider create or read method is called
```

## Verification

```text
lua tests/run.lua
  80 suites passed

new step-6 suites
  repository-capability: 12/12 passed
  repository-intent:     12/12 passed
  repository-action:     13/13 passed

lua tests/red_repository_hands.lua
  green=3 red=4 total=7
  expected process exit: 1

luac syntax checks
  passed

git diff --check and trailing-whitespace scan
  passed
```

The red frontier is now exact:

```text
green: capability, intent, authorized action
red:   effect, Linux provider, work completion, integrated route
```

The red runner remains outside `tests/run.lua`. Its non-zero exit is expected
until the remaining implementation steps exist.

## Deliberate Limits

This manifest does not claim:

```text
an available native provider
any repository mutation
an effect attempt or read-back receipt
LOGIC validation of filesystem evidence
RUNTIME completion or repository progress
qualified repository pressure readers
Tree routing through the hand
multi-file scheduling
CLI/TUI repository grants
```

The native build gate remains red because Lua 5.4 development headers are not
available on the observed host. Step 7 must satisfy that prerequisite or report
the provider unavailable; it must not install a weaker path-based fallback.

## Next Boundary

Roadmap step 7 is the first exact file hand: implement the Linux provider and
one create/read-back transaction for one absent UTF-8 text file. The capability
contract manifested here is the fixed input to that work. Step 7 may consume it;
it may not widen it.
