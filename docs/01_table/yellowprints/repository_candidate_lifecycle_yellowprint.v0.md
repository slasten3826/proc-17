# Repository Candidate Lifecycle Yellowprint v0

Status:

```text
layer: table (⊞)
date: 2026-07-22
scope: private root ownership, generation claim and terminal source-write lock
runtime implementation authorized: no
candidate seal implementation authorized: no
fresh repository allocator authorized: no
router promotion authorized: no
crystallization authorized: yes, by 2026-07-22 documentary gate
gate record:
  docs/00_chaos/candidate_seal_table_cross_audit_2026-07-22.md
crystallized as:
  docs/02_crystall/blueprints/repository_candidate_lifecycle.v0.md
```

Primary chaos source:

[`../../00_chaos/candidate_seal_runtime_boundary_notes_2026-07-21.md`](../../00_chaos/candidate_seal_runtime_boundary_notes_2026-07-21.md)

Companion TABLE contracts:

```text
artifact_set_derivation_yellowprint.v0.md
candidate_seal_transaction_yellowprint.v0.md
capability_safe_repository_hands_yellowprint.v0.md
completion_scope_candidate_seal_yellowprint.v0.md
stage_transition_generation_recovery_yellowprint.v0.md
```

This table narrows the cross-generation compatibility law in
`capability_safe_repository_hands_yellowprint.v0.md` and refines candidate
lifecycle/closure in `completion_scope_candidate_seal_yellowprint.v0.md`
§§6, 8, 9 and controls C13-C16/C31-C34.

## 0. Selected Decisions

```text
L01 trusted mint/open creates one private root-authority record
L02 repository_id is a logical coordinate, not a physical-root reset primitive
L03 the first generation-specific authority consumption atomically claims root
L04 root claim, lifecycle birth and first effect consumption are one transition
L05 effect_counts is audit evidence, never ownership authority
L06 a clean failure of the first effect does not release the claim
L07 Packet death, grant revocation and zero written files do not release claim
L08 the owning generation may continue; another generation is denied
L09 G5 cross-generation re-resolution is legal only while root is unclaimed
L10 one build generation must use one unique repository/root identity
L11 grant state and root/candidate state remain distinct
L12 consumed actions and in-flight provider dispatches remain distinct
L13 seal_pending invalidates old leases and denies new dispatch/mint/resolve
L14 sealed and quarantined are terminal source-write states
L15 root-wide quarantine closes every grant targeting the root
L16 returned projections, ids and receipts carry no authority
L17 root lock survives Packet generations inside one registry session
L18 v0 does not claim persistence across process loss or inode recycling
L19 identity collision denies in the safe direction
L20 no state transition may be selected by substrate output
```

## 1. Why A Grant Is Not A Candidate Lifecycle

The current grant is intentionally session/lineage scoped and can be
re-resolved by action context. It answers:

```text
what host authority exists for this repository operation?
```

It does not answer:

```text
which Packet generation first consumed authority against this physical root?
whether the root is currently being sealed
whether a descendant may reopen the root
whether all root-targeting authority is terminally closed
```

Adding `sealed=true` to one grant would be insufficient. Another grant or a
later-generation resolution could still target the same root. Candidate
finality is root-wide and generation-bound.

## 2. Two Identities, One Mutable Authority Surface

The body needs two logical identities:

```text
root authority
  exists from trusted mint/open
  answers whether this root can carry source-write authority at all

generation candidate lifecycle
  exists after first generation-specific authority consumption
  answers which exact generation owns materialization and sealing
```

They must not become two independently mutable stores. v0 uses one private
registry aggregate keyed by root authority. The generation lifecycle is the
claim nested in that aggregate and a detached derived projection of it.

This is one truth surface:

```lua
root_record.state + root_record.claim
```

It is not:

```lua
root_state_table[root] plus generation_state_table[generation]
```

with reconciliation after divergence.

## 3. Root Authority Identity

The registry derives `root_authority_id` only after the trusted provider opens
and normalizes the repository identity.

Conceptual identity seed:

```text
registry session id
provider id
trusted project-base identity
normalized provider root fingerprint
```

The caller-visible `repository_id` is bound inside the record but does not
partition the physical lock. Minting a new logical id that resolves to the same
trusted root identity finds the existing record and cannot erase its claim or
terminal state.

The current provider fingerprint includes normalized repository path and
device/inode evidence. Bind-mount/path aliases outside that identity are part
of the declared trusted-host boundary for v0; they are not silently claimed as
solved by this table.

## 4. Private Root Record

Conceptual private shape:

```lua
{
  protocol_version = "repository.root_authority.v0",
  root_authority_id = "root-authority:<sha256>",

  session_id = string,
  provider_id = string,
  project_base_identity = private_identity,
  root_identity = private_identity,
  root_fingerprint = "repository-root:...",
  lineage_id = string,
  repository_id = string,

  state = "unclaimed" | "materializing" | "seal_pending"
    | "sealed" | "quarantined",
  revision = integer,

  claim = nil | {
    lifecycle_id = "candidate-lifecycle:<sha256>",
    lineage_id = string,
    generation = integer,
    repository_id = string,
    first_action_id = string,
    claim_revision = integer,
  },

  grant_ids = private_set,
  in_flight_dispatches = private_map,

  seal_transaction_id = string | nil,
  closure_id = string | nil,
  seal_request_id = string | nil,
  inventory_digest = string | nil,
  quarantine_reason = table | nil,
}
```

`active_dispatch_count` in detached projections is derived from
`in_flight_dispatches`; it is not stored as a second counter of truth.

Grant-local maps retain their narrower meanings:

```text
action_dispatches[action_id] = consumed authority ledger
effect_counts[generation] = consumed-effect accounting/audit evidence
```

Neither owns root claim or current in-flight state.

## 5. State Meaning And Transitions

| State | Claim | Source-write meaning | Legal exits |
|---|---|---|---|
| `unclaimed` | absent | grants may resolve provisionally; no generation has consumed authority | first effect claim |
| `materializing` | exact owner | only owner generation may use active exact grants | more owner effects, seal_pending, quarantined |
| `seal_pending` | exact owner | no new/old source-write dispatch may enter provider | materializing by proven abort, sealed, quarantined |
| `sealed` | exact owner | terminally no source-write authority | none |
| `quarantined` | exact owner when known | terminally no source-write authority | none |

Canonical state graph:

```text
mint/open
  -> unclaimed

unclaimed -- first begin_effect --> materializing
materializing -- begin_seal --> seal_pending
seal_pending -- dual positive abort proof --> materializing
seal_pending -- exact closure commit --> sealed
materializing/seal_pending -- ambiguous world/authority --> quarantined
```

There is no transition:

```text
materializing -> unclaimed
sealed -> materializing
quarantined -> materializing
owner generation N -> owner generation N+1
```

## 6. Atomic First-Use Claim

The first exact `begin_effect` against an unclaimed root performs one private
transition:

```text
1. validate action envelope and Packet identity
2. resolve exact active grant and root record
3. verify root unclaimed or already owned by this generation
4. if unclaimed, bind lineage/generation/repository and create lifecycle id
5. consume action/effect authority
6. create the opaque effect lease
7. only then permit provider entry
```

Claim creation and consumed-effect accounting cannot be separated by a caller
yield or provider call.

The existing `effect_counts[generation]` zero-to-one transition is a useful
implementation hook and control witness. Ownership is read only from the root
record claim.

### 6.1 Sticky claim law

Once step 4 succeeds, none of these release the claim:

```text
provider returns a typed no-effect failure
target already exists
capability is later revoked
Packet dies before materializing any file
budget or loss kills the generation
host chooses not to continue
```

Even zero successfully written files does not make the root unborn again.
Release would let a descendant reuse the failed ancestor root and violate the
fresh-generation law.

## 7. Resolution And Mint Policy

### 7.1 Resolve

| Root state | Resolution context | Outcome |
|---|---|---|
| unclaimed | any exact same-session/lineage provisional generation | existing G5 compatibility may resolve |
| materializing | owner lineage/generation/repository | active exact grant may resolve |
| materializing | another generation or repository coordinate | typed denial |
| seal_pending | any source-write operation | typed denial |
| sealed | any source-write operation | terminal denial |
| quarantined | any source-write operation | terminal denial |

The provisional unclaimed resolution has no ownership effect. The first
`begin_effect`, not `resolve`, wins the atomic claim.

### 7.2 Mint

The first successful mint/open creates the root record and attaches one grant.

Further mint attempts:

```text
same trusted root + different repository_id
  -> deny logical alias

same trusted root + different lineage_id
  -> deny lineage alias

same root while unclaimed/materializing + matching lineage/repository
  -> may attach a replacement/additional grant under host policy

same root in seal_pending/sealed/quarantined
  -> deny
```

Several active exact-root grants remain legal host state before sealing, but
normal capability resolution reports ambiguity and begin-seal rejects them.
The body never chooses one silently.

Revoked grant membership remains historical in the root record. Only active
exact grants participate in ambiguity and sealing preconditions.

## 8. Lease, Consumption And In-Flight Dispatch

Three states must remain distinct:

| Fact | Private owner | Meaning |
|---|---|---|
| action consumed | grant `action_dispatches` | this action id can never dispatch again |
| lease issued | opaque lease table | exact authority was reserved but provider may not have been entered |
| provider in flight | root `in_flight_dispatches` | trusted provider call has begun and not returned |

Provider dispatch protocol:

```text
validate current lease/root revision
insert exact dispatch id into in_flight_dispatches
enter provider through protected boundary
remove dispatch id after every normal/error/panic return path
classify result without refunding consumed authority
```

`begin_candidate_seal` requires the in-flight map to be empty. It may
invalidate unconsumed old leases by changing the root/lifecycle revision.

Synchronous Lua makes normal overlap impossible today. The state still exists
because safety may not depend on that accidental scheduler property.

## 9. seal_pending And Terminal Lock

Entering `seal_pending` is root-wide:

```text
root revision advances
new source-write resolve/mint/begin_effect is denied
all older unconsumed leases fail revision checks
one exact seal transaction id becomes current
```

Exact abort may return the same owner lifecycle to `materializing`; it never
returns the root to `unclaimed`.

Commit to `sealed` records the candidate seal and inventory identities. A
quarantine records a typed private reason. Both terminal states:

```text
close every root-targeting provider handle/grant authority
deny every present and future source-write path in the registry session
survive owner Packet death and descendant birth
```

A seal id, lifecycle id, root-authority id or detached projection is evidence,
not a capability.

## 10. Quarantine Scope

An ambiguous effect cannot quarantine only the grant that happened to expose
the ambiguity. The uncertainty concerns the root.

Root-wide quarantine:

```text
sets root state quarantined once
increments root revision
invalidates every lease
closes every root-member provider handle
marks active member grants unavailable
preserves exact reason and source refs privately
```

A schema-valid world/authority ambiguity gives the living Packet the existing
typed `effect_failure` path. If the registry quarantines defensively while a
trusted receipt/provider contract is itself malformed, the root still closes
but the harness fails loudly; quarantine must not launder broken runtime
physics into an ordinary Packet death.

## 11. Session Lifetime And Identity Reuse

The v0 registry is private in-memory session state:

```text
root lock survives Packet death and generation changes in that registry
root lock does not claim persistence after runtime process/registry loss
step 8.4 performs no cleanup or recycling of terminal roots
```

Device/inode reuse may cause a later root identity to collide with a session
lock. The required direction is safe denial. A future allocator chooses a
different root; it cannot delete the lock or rename `repository_id` to force
acceptance.

Persistent root birth identity, cleanup/compost and crash recovery require a
later contract. Until then a resumed process cannot claim that an old in-memory
seal lock survived.

## 12. Detached Projections

Conceptual read API:

```lua
capabilities.root_authority(registry, root_identity)
  -> detached_root_projection | nil, diagnostic

capabilities.candidate_lifecycle(registry, identity)
  -> detached_lifecycle_projection | nil, diagnostic
```

Projections may contain:

```text
protocol/id
root fingerprint
logical repository coordinate
state/revision
owner lineage/generation when claimed
derived active_dispatch_count
closure/request/inventory refs when terminal
runtime-confirmed truth status
```

They never contain:

```text
provider object or handle
host path
grant private state
lease
mutable maps
method/callback
authority to change lifecycle
```

Mutating a returned projection has zero private-state effect.

## 13. Failure And Death Separation

| Event | Root result | Packet/runtime result |
|---|---|---|
| malformed action before claim | remains unclaimed | typed denial or loud contract failure |
| first provider call cleanly denies with no effect | remains materializing and claimed | typed effect failure under existing policy |
| ambiguous provider result during materialization | quarantined | Packet dies `effect_failure` |
| owner Packet dies normally before seal | remains materializing and claimed | descendant must use fresh root |
| foreign descendant resolves same root | no state change | typed denial |
| seal abort with dual positive proof | materializing, same owner | Packet may continue |
| seal ambiguity | quarantined | Packet dies `effect_failure` |
| private state/body projection contradiction | never auto-repaired | loud runtime invariant |

No lifecycle error is converted into `complete` or a cosmetic layer glyph.

## 14. Truth And Actor Rights

| Claim/action | Owner | Truth |
|---|---|---|
| host grant mint | trusted session host/registry | runtime-confirmed act |
| root identity normalization | trusted provider + registry | runtime-confirmed |
| root claim | private registry | runtime-confirmed act |
| consumed action/effect | private grant registry | runtime-confirmed act |
| provider in-flight membership | private registry boundary | runtime-confirmed act |
| sealed/quarantined transition | private registry | runtime-confirmed act |
| artifact meaning | substrate/body evidence | preserved semantic status |
| applicability of ancestor result | later carrier/lineage | not decided here |

Only trusted registry APIs mutate this surface. The substrate, Packet field,
router, TUI and returned tables have read/proposal rights only.

## 15. Named Writers And Readers

| Private record/fact | Writer | First named readers |
|---|---|---|
| root-authority record | trusted mint/open registry path | mint alias check, resolve, begin-effect, begin-seal |
| generation claim/lifecycle identity | atomic first begin-effect transition | resolve gate, effect gate, seal planner |
| grant membership | mint/revoke registry paths | ambiguity resolver and seal precondition |
| consumed action/effect maps | begin-effect | replay denial, budget/audit controls |
| in-flight dispatch map | protected provider-call boundary | begin-seal exclusion and failure cleanup |
| seal transaction/current revision | begin/abort/commit seal registry paths | lease checks, inventory commit, body verifier |
| terminal root lock | seal commit or quarantine | every future mint/resolve/effect path |
| quarantine reason | registry/provider classifier | operator failure or loud invariant report |
| detached lifecycle projection | pure private-state reader | body verifier, instrumentation and tests |

Every private writer has an in-registry safety reader. Diagnostic projections
are not the only consumers of authority state.

## 16. Permanent Controls

### Claim controls

| ID | Control | Expected result |
|---|---|---|
| LC01 | mint one fresh root | unclaimed root record |
| LC02 | resolve generation N before first use | provisional match, no claim |
| LC03 | first exact begin_effect by N | atomic N claim + consumed effect |
| LC04 | same generation continues | allowed under active exact grant |
| LC05 | generation N+1 after N claim | denied before provider call |
| LC06 | failed first effect with zero published files | N claim remains |
| LC07 | owner Packet dies | claim remains |
| LC08 | owner grant revoked | claim remains |
| LC09 | returned claim projection mutated | zero private delta |

### Alias and grant controls

| ID | Control | Expected result |
|---|---|---|
| LC10 | same root, changed repository_id | denied alias; same root record |
| LC10a | same root, changed lineage_id | denied alias; same root record |
| LC11 | same repository_id, different trusted root | distinct unclaimed root record |
| LC12 | two active exact-root grants | resolve/seal ambiguity; body chooses none |
| LC13 | revoked old + one active replacement for owner | one exact active grant may continue |
| LC14 | mint against sealed/quarantined root | denied |

### Lease/dispatch controls

| ID | Control | Expected result |
|---|---|---|
| LC15 | issued old lease then seal_pending | old lease denied, zero provider calls |
| LC16 | provider call in-flight then begin-seal | begin-seal denied/not ready |
| LC17 | action_dispatches populated but no call in-flight | does not falsely block seal |
| LC18 | provider panic | in-flight bookkeeping closes, root quarantines, harness fails loudly |

### Terminal controls

| ID | Control | Expected result |
|---|---|---|
| LC19 | exact seal commit | terminal sealed root |
| LC20 | ambiguous effect | terminal root-wide quarantine |
| LC21 | second grant tries after terminal transition | denied |
| LC22 | descendant reuses same root after ancestor terminal | denied |
| LC23 | descendant receives different root | not denied by ancestor lock |
| LC24 | simulated fingerprint reuse in same session | typed safe denial |
| LC25 | hand-disabled ablation | route/loss/Packet mutation unchanged |

The old G5 fixture is replaced, not merely edited, by LC02-LC06. The tests
must exercise `begin_effect` and real private state transitions rather than
constructing claimed projections by hand.

## 17. Migration And Capability Delta

This table intentionally changes one compatibility ability:

```text
before first authority consumption:
  same-lineage later-generation resolution may still resolve provisionally

after first authority consumption:
  cross-generation root reuse is denied
```

Current grown repository-hand lives do not rely on cross-generation reuse.
When repository hands and lineage recovery are combined before a fresh-root
allocator exists, recovery may become honestly blocked instead of mutating the
ancestor root. That is a known capability gap, not a reason to retain unsafe
G5 behavior.

## 18. CRYSTALL Consequences

The later CRYSTALL round must amend:

```text
capability_safe_repository_hands.v0 grant resolution and G5 controls
candidate_seal.v0 private lifecycle shape and APIs
stage_transition_generation_recovery.v0 only where denial meets allocator
completion_scope.v0 only for lifecycle/seal reader refs
```

The blueprint must preserve one mutable private authority surface and must not
reintroduce state duplication through a convenience lifecycle cache.

## 19. Explicit Deferrals

```text
fresh repository allocator
persistent root locks and resume
terminal-root cleanup or compost
bind-mount/path-alias elimination beyond current trusted provider identity
imported artifact roots
parallel/asynchronous provider implementation
QA read-only capabilities
router promotion
```

## 20. Table Thesis

```text
The first paid touch of a repository root gives that root one mortal owner.
Failure may end the owner, but it does not make the root unborn again.
```
