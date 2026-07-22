# Repository Candidate Lifecycle Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-07-22
source table:
  docs/01_table/yellowprints/repository_candidate_lifecycle_yellowprint.v0.md
gate record:
  docs/00_chaos/candidate_seal_table_cross_audit_2026-07-22.md
implementation authority: private root authority, sticky generation claim,
  in-flight dispatch tracking and seal lifecycle primitives
native inventory authority: separate transaction blueprint
fresh repository allocator authority: forbidden
QA authority: forbidden
router promotion: forbidden
```

## 0. Crystallized Claim

One trusted repository root has one private authority record per registry
session. Its first generation-specific effect atomically gives that root one
owner generation. Neither clean failure, Packet death nor grant replacement
returns it to an unclaimed state.

```text
mint/open -> unclaimed root
first begin_effect by N -> materializing root owned by N
begin seal -> seal_pending
exact commit -> sealed
ambiguous world/authority -> quarantined
```

Only the owning generation may continue source-write work. Sealed and
quarantined roots are terminal for all source-write authority in the session.

## 1. Target Surface

Modify:

```text
runtime/repository_capability.lua
runtime/repository_action.lua          validation only if new projection fields
runtime/repository_effect.lua          root-wide quarantine/in-flight outcomes
runtime/repository_inspection.lua      diagnostics only
tests/support/repository_hands.lua
tests/test_repository_capability.lua
tests/test_repository_effect.lua
tests/test_repository_hostile_audit.lua
tests/test_repository_action.lua
tests/run.lua
```

New focused suite:

```text
tests/test_repository_candidate_lifecycle.lua
```

No changes in this slice:

```text
core/packet.lua mortality causes
runtime/lineage_runner.lua
runtime/candidate_seal.lua
runtime/completion_scope.lua
native/*
organs/*
router/pressure modules
```

## 2. Registry Private State

`repository_capability.new` extends its existing private state:

```lua
{
  -- existing provider/grant fields
  root_authorities = {
    [root_authority_id] = root_record,
  },
  root_order = string[],
}
```

No root record is placed in Packet, trace, run report, corpse, carrier or
substrate context.

### 2.1 Root authority identity

After provider open/identity normalization:

```lua
root_authority_id = "root-authority:" .. digest.record({
  session_id = registry_session_id,
  provider_id = provider_id,
  project_base_identity = normalized_private_base_identity,
  root_fingerprint = normalized_root_fingerprint,
})
```

`lineage_id` and `repository_id` are bound record fields, not key partitions.
The same trusted root identity with another logical id finds the same record
and is denied as an alias.

### 2.2 Root record

```lua
{
  protocol_version = "repository.root_authority.v0",
  root_authority_id = string,

  session_id = string,
  provider_id = string,
  project_base_identity = private_table,
  root_identity = private_table,
  root_fingerprint = string,
  lineage_id = string,
  repository_id = string,

  state = "unclaimed" | "materializing" | "seal_pending"
    | "sealed" | "quarantined",
  revision = integer,

  claim = nil | {
    lifecycle_id = string,
    lineage_id = string,
    generation = integer,
    repository_id = string,
    first_action_id = string,
    claim_revision = integer,
  },

  grant_ids = {[grant_id] = true},
  in_flight_dispatches = {[dispatch_id] = private_dispatch},

  seal_transaction_id = string | nil,
  seal_request_id = string | nil,
  closure_id = string | nil,
  inventory_id = string | nil,
  inventory_digest = string | nil,
  closure_projection = detached_private_seed | nil,
  quarantine_reason = detached_table | nil,
}
```

The record owns state. There is no parallel mutable
`candidate_lifecycles[generation]` table. `candidate_lifecycle` is a detached
projection of `state + claim`.

The registry does not store `candidate_seal_id` or body event ref. Those are
derived after closure receipt and checked against Packet trace without a second
private commit.

## 3. Grant Binding At Mint

Every private grant gains:

```lua
root_authority_id = string
```

Mint order:

```text
1. validate trusted grant input
2. open provider root and normalize identity
3. derive root_authority_id
4. create unclaimed root record or load existing one
5. reject lineage_id/repository_id aliases
6. reject seal_pending/sealed/quarantined root
7. create grant and attach grant id to root membership
8. return detached grant projection
```

If any step after provider open fails, the newly opened handle is closed.

For `unclaimed` or `materializing`, a matching-lineage/repository replacement
grant may attach under trusted host policy. Multiple active exact grants remain
ambiguous to normal resolution and begin-seal.

Revocation changes grant state/handle only. It never clears root claim or root
membership history.

## 4. Resolution Gate And G5 Narrowing

`capability.resolve` first performs existing exact grant matching, then applies
the root gate:

```lua
local function generation_may_resolve(root, context)
  if root.state == "unclaimed" then
    return true
  end
  if root.state == "materializing" then
    return root.claim.lineage_id == context.lineage_id
       and root.claim.generation == context.generation
       and root.claim.repository_id == context.repository_id
  end
  return false
end
```

Typed diagnostics added:

```text
repository_root_claimed_by_other_generation
repository_root_logical_alias
repository_root_seal_pending
repository_root_sealed
repository_root_quarantined
```

G5 becomes:

```text
unclaimed root + later same-lineage generation -> provisional resolution
claimed root + another generation -> denial before action/provider
```

Resolution does not claim the root.

## 5. Atomic Claim In begin_effect

After current action/grant validation and before action consumption:

```text
1. load grant.root_authority_id
2. verify root/grant/session/lineage/repository identities
3. reject pending/terminal root
4. if unclaimed, create exact claim and set state=materializing
5. if materializing, require exact owner generation
6. record consumed effect/action
7. issue lease bound to grant revision + root revision + lifecycle id
```

Claim identity:

```lua
lifecycle_id = "candidate-lifecycle:" .. digest.record({
  root_authority_id = root.root_authority_id,
  lineage_id = action.lineage_id,
  generation = action.generation,
  repository_id = action.capability.repository_id,
})
```

Creating the claim increments root revision once. Claim creation, effect-count
increment and action-dispatch consumption occur in one non-yielding registry
call before provider entry.

If the later effect reports no publication or zero files, the claim remains.
No API clears claim or returns `materializing` to `unclaimed`.

## 6. Effect Lease And In-Flight Tracking

Effect lease private state adds:

```lua
root = root_record,
root_revision = integer,
lifecycle_id = string,
generation = integer,
```

`lease_state` requires:

```text
grant active and exact revision
root state materializing
root revision exact
claim lifecycle/generation exact
provider handle present
```

Each provider boundary inside `effect_create` and `effect_read_back` uses one
private wrapper:

```lua
with_provider_dispatch(root, dispatch_id, fn)
  -> result... | panic_error
```

Wrapper law:

```text
insert dispatch before provider call
call through pcall/protected boundary
remove dispatch on every returned path
never refund action/effect consumption
return panic distinctly from provider_error
```

The map is authority. Any public `active_dispatch_count` is derived from it.
`action_dispatches` remains consumed-authority history and cannot block seal by
itself.

## 7. Root-Wide Quarantine

`quarantine_effect` resolves the lease root and atomically:

```text
state -> quarantined
root revision increments
quarantine reason deep-copied
every active root-member grant becomes quarantined/unavailable
every root-member provider handle closes
every old lease fails root/grant checks
```

A second quarantine request returns the same detached terminal projection when
the normalized reason is compatible; a contradictory reason is a loud private
invariant.

Schema-valid ambiguous world/provider results continue through existing typed
`effect_failure` mortality. Provider panic or malformed trusted output closes
the root defensively but remains a loud harness/runtime error.

## 8. Seal Lifecycle API

These registry APIs are authorized here; request/proof schemas are owned by the
transaction blueprint.

```lua
capabilities.begin_candidate_seal(registry, request)
  -> opaque_seal_lease | nil, diagnostic

capabilities.inventory_candidate(registry, seal_lease, inventory_request)
  -> private_provider_result | nil, provider_error_or_invariant

capabilities.abort_candidate_seal(registry, seal_lease, abort_proof)
  -> detached_lifecycle_projection | nil, err

capabilities.commit_candidate_seal(registry, seal_lease, commit_input)
  -> detached_closure_receipt | nil, err

capabilities.quarantine_candidate_seal(registry, seal_lease, reason)
  -> detached_lifecycle_projection | nil, err

capabilities.observe_candidate_closure(registry, query)
  -> detached_closure_receipt | nil, diagnostic

capabilities.root_authority(registry, query)
  -> detached_root_projection | nil, diagnostic

capabilities.candidate_lifecycle(registry, query)
  -> detached_lifecycle_projection | nil, diagnostic
```

Opaque seal leases live in a private weak-key map and bind:

```text
registry/root/grant/lifecycle
pending root revision
seal transaction/request id
single-use inventory/abort/commit state
```

### 8.1 begin

Requires:

```text
root materializing and owned by request generation
request root/lifecycle/revision exact
exactly one active matching root grant and it is the request grant
in_flight_dispatches empty
no current seal transaction
```

It sets `seal_pending`, advances revision, records transaction/request ids and
issues one lease. Old effect leases become invalid through root revision.

### 8.2 abort

Requires transaction-owned registry no-commit proof plus provider continuity
proof. It sets state back to `materializing`, advances revision, clears only
pending transaction fields and retains the same claim forever.

### 8.3 commit

Requires exact normalized request/inventory identities and one unused seal
lease. It sets:

```text
state = sealed
closure_id/request_id/inventory_id/inventory_digest
closure_projection seed
```

Then it closes every root-member provider handle and returns one detached
closure receipt. It does not append Packet trace and does not store a future
candidate seal id.

### 8.4 observe

For an already sealed root, exact query returns the same closure receipt from
private commit data. Different request/root/lifecycle identity is terminal
denial, not a new transaction.

## 9. Detached Projections

Root projection:

```lua
{
  protocol_version = "repository.root_authority_projection.v0",
  root_authority_id = string,
  root_fingerprint = string,
  lineage_id = string,
  repository_id = string,
  state = string,
  revision = integer,
  lifecycle_id = string | nil,
  owner_generation = integer | nil,
  active_grant_count = integer,
  active_dispatch_count = integer,
  seal_request_id = string | nil,
  closure_id = string | nil,
  inventory_digest = string | nil,
  event_truth_status = "runtime_confirmed",
}
```

Lifecycle projection is the owner-specific subset plus root authority id.
Closure receipt follows the transaction blueprint.

No projection contains handles, host paths, private identities/maps, leases or
mutator callbacks. Every return is deep detached.

## 10. Compatibility And Capability Delta

Existing direct single-generation repository lives remain behaviorally
identical except for additional private state/projection fields.

Intentional delta:

```text
after first begin_effect, generation N+1 cannot use the same root
```

Until a fresh-root allocator exists, a hands-enabled lineage recovery that
tries to reuse the old root receives a typed denial. No fallback restores old
G5 behavior.

Hand-disabled lives remain exact ablations: no root records, diagnostics,
trace events, route changes, loss or budget changes.

## 11. Control Battery

Required controls:

```text
LC01-LC25 from TABLE

claim battery:
  unclaimed provisional resolve
  first-use atomic claim
  same-generation continuation
  descendant denial
  failed-first-effect sticky claim
  Packet death/revoke do not release claim

alias battery:
  changed repository_id, same trusted root
  changed lineage_id, same trusted root
  changed root, same repository_id

dispatch battery:
  consumed action with zero in-flight does not block seal
  actual in-flight call blocks seal
  panic removes in-flight marker and closes root loudly

terminal battery:
  root-wide quarantine closes every grant
  pending/terminal denies old/new leases, mint and resolve
  returned projections cannot mutate private state
```

Tests that claim cross-generation denial must execute real `begin_effect`; a
hand-built claimed projection is not evidence.

## 12. Acceptance Gate

```text
all existing repository suites green or intentionally updated for G5 delta
four-way replacement of old G5 control green
no cross-generation provider entry after first claim
no claim release on every clean/failed/death/revoke path
root-wide terminal denial complete
in-flight map empty after every provider return/panic path
hand-disabled ablation exact
no private handle/state leak in trace/corpse/carrier/run report
```

## 13. Explicit Deferrals

```text
native inventory implementation
candidate seal body writer
fresh repository allocator
persistent root lock/resume
cleanup/compost
QA
router promotion
```

## 14. Blueprint Thesis

```text
Root ownership begins when authority is first spent, not when a file happens to
appear. Spent authority is irreversible history even when the world effect
fails cleanly.
```
