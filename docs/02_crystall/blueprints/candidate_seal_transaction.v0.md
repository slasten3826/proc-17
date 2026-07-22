# Candidate Seal Transaction Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-07-22
source table:
  docs/01_table/yellowprints/candidate_seal_transaction_yellowprint.v0.md
gate record:
  docs/00_chaos/candidate_seal_table_cross_audit_2026-07-22.md
implementation authority: candidate-seal request, exact native inventory,
  two-proof closure transaction and immutable body seal event
depends on:
  docs/02_crystall/blueprints/artifact_set_derivation.v0.md
  docs/02_crystall/blueprints/repository_candidate_lifecycle.v0.md
QA authority: forbidden
fresh repository allocator authority: forbidden
router promotion: forbidden
amended 2026-07-22: immutable seal-record finality is separated from pure
  current artifact alignment
```

## 0. Crystallized Claim

A candidate exists only when two independently owned facts agree:

```text
world fact       exact bounded inventory of the declared repository tree
authority fact   source-write authority for that root is irreversibly closed
body fact        one immutable ☶ event joins both facts to this Packet
```

A digest alone is not a seal. A private closure without a body event is not a
reported candidate. A body event without matching private closure is invalid.
The transaction makes these disagreement states explicit instead of repairing
them by reopening authority.

## 1. Implementation Slice

New Lua module:

```text
runtime/candidate_seal.lua
```

Modify:

```text
runtime/repository_capability.lua   lifecycle API from companion blueprint
runtime/repository_provider.lua     strict inventory adapter contract
runtime/body.lua                    dedicated candidate-seal writer
runtime/completion_scope.lua        body-event reader only
runtime/work_layer.lua              body-event reader only
core/packet.lua                     event kind, schema gate and ☶ actor right
native/proc17_repository_fs.c       bounded descriptor-relative inventory
native/proc17_repository_fs.h       inventory result/bounds ABI
tests/support/repository_hands.lua
tests/run.lua
```

New focused suites:

```text
tests/test_candidate_seal.lua
tests/test_candidate_seal_hostile.lua
```

This slice does not modify:

```text
router or pressure authority
Packet mortality causes
lineage recovery policy
QA capability/check/verdict contracts
artifact semantics
repository cleanup or replacement operations
```

## 2. Ownership Boundaries

| Fact | Sole authority writer | Consumer |
|---|---|---|
| artifact declaration | pure body derivation | seal planner |
| seal request | `candidate_seal.prepare` from current evidence | ☶ transaction |
| root/lifecycle state | private capability registry | transaction verifier |
| raw inventory bytes | native provider, private return only | strict Lua adapter |
| normalized inventory | strict Lua adapter | comparator and registry commit |
| closure receipt | capability registry | body seal verifier |
| candidate seal | dedicated ☶ body writer | completion/work layer, future QA |

The provider cannot assert closure. The registry cannot assert filesystem
continuity. The substrate cannot write any record in this table.

## 3. Public Module API

`runtime/candidate_seal.lua` exposes:

```lua
local candidate_seal = require("runtime.candidate_seal")

candidate_seal.prepare(instance, services, options)
  -> request | nil, diagnostic_or_err

candidate_seal.execute(instance, request, services, options)
  -> seal_result | nil, err, loud

candidate_seal.find(instance, candidate_seal_id)
  -> detached_seal, event | nil, reason

candidate_seal.current(instance)
  -> detached_seal, event | nil, reason

candidate_seal.validate_record(instance, seal)
  -> true | nil, err

candidate_seal.inspect_alignment(instance, seal)
  -> detached_alignment | nil, err

candidate_seal.validate_request(instance, request)
  -> true | nil, err

candidate_seal.validate_seal(instance, seal)
  -> true | nil, err
```

`prepare` is pure over current Packet/body evidence and detached registry
projections. It calls the artifact-set derivation and inspection contracts. It
does not enter `seal_pending`, invoke the provider or append trace.

`execute` is a trusted body service used by the ☶ boundary. It owns the causal
order but delegates every fact to its named writer. It never accepts caller-
supplied replacement declarations, inventories, closure receipts or seal ids.

`validate_record` verifies immutable schema, digest identity and Packet subject
binding without consulting mutable current artifact evidence. `find` and
`current` use that historical verifier. `validate_seal` remains the stricter
writer-side verifier and additionally requires exact current body evidence at
the original append boundary.

## 4. Seal Request Schema

The exact request is:

```lua
{
  protocol_version = "repository.candidate_seal_request.v0",
  request_id = "candidate-seal-request:<sha256>",

  packet_id = string,
  lineage_id = string,
  generation = integer,
  process_contract_id = string,
  context = "software_task.v0",
  stage_id = string,
  repository_id = string,

  root_authority_id = string,
  lifecycle_id = string,
  lifecycle_revision = integer,
  root_fingerprint = string,
  grant_id = string,
  grant_revision = integer,

  artifact_set_id = string,
  artifact_set_inspection_id = string,
  expected_files = {
    {
      relative_path = string,
      expected_kind = "regular_file",
      work_unit_id = string,
      work_unit_version = integer,
      expected_bytes = integer,
      expected_sha256 = string,
      completion_ref = string,
      verification_ref = string,
    },
  },
  expected_directories = string[],
  inventory_bounds = bounded_contract,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "semantic_proposal" | "mixed",
}
```

Identity is the SHA-256 of the normalized value excluding `request_id`.
Expected files are path-byte ordered. Expected directories are exactly the
root-relative ancestors required by those files. Sizes and digests come from
accepted repository verification/completion evidence, never substrate text.

Request validation re-derives the artifact set and inspection and requires
exact identity equality. A detached request is a plan, not authority.

## 5. Native Inventory ABI

The native provider gains one operation conceptually equivalent to:

```lua
provider.inventory_tree(repository_handle, bounds)
  -> private_provider_result | nil, provider_error
```

The expected declaration is deliberately absent from the native input. The
provider must observe the full bounded tree; it may not hide unexpected paths
by filtering for expected files.

Required bounds:

```lua
{
  protocol_version = "repository.inventory_bounds.v0",
  max_entries = integer,
  max_depth = integer,
  max_path_bytes = integer,
  max_component_bytes = integer,
  max_file_bytes = integer,
  max_total_bytes = integer,
}
```

Provider result:

```lua
{
  protocol_version = "repository.provider_inventory_result.v0",
  operation = "inventory_tree",
  outcome = "observed" | "bound_exceeded",
  root_before = trusted_identity,
  root_after = trusted_identity,
  stable = boolean,
  entries = {
    {
      relative_path = string,
      kind = "directory" | "regular_file" | "symlink" | "special",
      identity_before = trusted_identity,
      identity_after = trusted_identity,
      bytes = integer | nil,
      content = string | nil,
    },
  },
  bounds_observed = table,
  mutation_primitive_entered = false,
  published = false,
  cost = table,
}
```

The ABI must enforce:

```text
descriptor-relative traversal
no symlink following at every component
root identity before and after traversal
regular-file identity before and after bounded read
deterministic normalized names plus a second bounded enumeration or
  equivalent stable-directory proof
hard bounds before aggregate allocation can exceed policy
special files identified but never opened for content
no shell/helper process and no Lua filesystem fallback
```

`bound_exceeded` must still carry enough bounded root/postcondition evidence
for the Lua layer to decide whether abort is proven or quarantine is required.

## 6. Private Inventory Adapter

`candidate_seal` validates every provider field before interpreting it. A
schema-valid `observed` result becomes:

```lua
{
  protocol_version = "repository.seal_inventory.v0",
  inventory_id = "repository-seal-inventory:<sha256>",
  request_id = string,
  root_fingerprint = string,
  root_continuity = "proven",
  entries = {
    {
      relative_path = string,
      kind = "directory" | "regular_file" | "symlink" | "special",
      bytes = integer | nil,
      sha256 = string | nil,
      stable_identity_ref = string,
    },
  },
  observed_entry_count = integer,
  observed_total_bytes = integer,
  inventory_digest = string,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

Trusted Lua checks byte counts and computes all SHA-256 values with
`core.digest`; native code does not introduce a second hash implementation.
Raw content is discarded before the normalized inventory, diagnostics, trace,
closure receipt or run report is constructed.

Exact-tree comparison permits only:

```text
regular files = exactly expected_files
directories   = root plus exactly expected_directories
```

Every symlink, special file, extra file, extra directory, missing path, kind
mismatch, byte mismatch or digest mismatch prevents a seal. A stable complete
observation yields a typed mismatch. Missing stability/continuity yields
quarantine.

## 7. Causal Transaction

Canonical execution order:

```text
T01 re-derive artifact set
T02 inspect current completion and accepted repository verification
T03 validate detached request against both current derivations
T04 registry revalidates owner lifecycle, exact grant and zero in-flight
T05 registry enters seal_pending and invalidates all old effect leases
T06 registry invokes bounded provider inventory under opaque seal lease
T07 Lua validates provider schema, hashes bytes and compares exact tree
T08 on exact match, registry commits sealed against request/inventory digest
T09 registry returns detached closure receipt
T10 body verifies request + private sealed projection + closure receipt
T11 ☶ appends one immutable candidate-seal event
T12 later ☱ observes that event; pure readers may derive candidate_sealed
```

Steps T05 through T11 are one synchronous runtime boundary. This does not make
private commit and body append an impossible OS-level atomic transaction; it
makes their one legal failure direction explicit.

No substrate call is allowed in T01-T12.

## 8. Registry Calls And Proof Objects

The transaction uses the companion lifecycle API exactly:

```lua
capabilities.begin_candidate_seal(registry, request)
  -> seal_lease | nil, diagnostic

capabilities.inventory_candidate(registry, seal_lease, inventory_request)
  -> private_provider_result | nil, provider_error_or_invariant

capabilities.abort_candidate_seal(registry, seal_lease,
  provider_observation_proof)
  -> lifecycle_projection | nil, err

capabilities.commit_candidate_seal(registry, seal_lease, commit_input)
  -> closure_receipt | nil, err

capabilities.quarantine_candidate_seal(registry, seal_lease, reason)
  -> lifecycle_projection | nil, err

capabilities.observe_candidate_closure(registry, query)
  -> closure_receipt | nil, diagnostic
```

Inventory input contains only the seal transaction identity and trusted
bounds. The opaque lease supplies the provider handle privately.

Effective abort proof, assembled inside the private registry boundary:

```lua
{
  protocol_version = "repository.candidate_seal_abort_proof.v0",
  request_id = string,
  transaction_id = string,
  registry = {
    closure_commit_absent = true,
    current_transaction = true,
    in_flight_dispatches = 0,
    root_revision = integer,
  },
  provider = {
    root_continuity = "proven",
    observation_postcondition = "stable_mismatch" | "bounded_no_closure",
    root_before_ref = string,
    root_after_ref = string,
  },
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

The strict adapter supplies only the outer identity, source references, and
the provider subsection derived from validated native evidence. The registry
constructs the `registry` subsection from private state and joins both halves
before authorizing the abort. No caller can supply or override registry-owned
closure, transaction, in-flight, or revision facts.

Commit input:

```lua
{
  protocol_version = "repository.candidate_seal_commit.v0",
  request_id = string,
  transaction_id = string,
  inventory_id = string,
  inventory_digest = string,
  root_fingerprint = string,
  comparison = "exact",
  source_refs = string[],
}
```

## 9. Failure Classification

| Condition | Root result | Body/harness result |
|---|---|---|
| readiness failure before pending | unchanged materializing | typed not-ready |
| stable missing/extra/mismatched entry | abort to materializing with both proofs | typed seal mismatch |
| bounded result with continuity and no closure | abort to materializing with both proofs | typed bounded failure |
| in-flight provider call before begin | unchanged materializing | typed not-ready |
| root replacement or entry race | quarantined | typed `effect_failure` |
| schema-valid ambiguous publication/postcondition | quarantined | typed `effect_failure` |
| malformed trusted provider result | quarantined defensively | loud runtime invariant |
| trusted identity contradicts private request | quarantined defensively | loud runtime invariant |
| exact closure commit | sealed | append body event |
| append failure after private commit | sealed forever | loud runtime invariant |

Typed world ambiguity proceeds through the existing repository
`effect_failure -> operator_failure -> Packet death -> blocked lineage` path.
Malformed trusted output is not converted into a beautiful Packet death. The
authority is closed defensively and the harness remains red.

Returning to `materializing` asserts only coherent authority and proven
no-closure. It does not claim the candidate is repairable. With create-only
hands, a stable extra path may make this generation permanently unable to
seal; higher body policy decides its honest terminal outcome later.

## 10. Closure Receipt And Body Seal

Closure receipt:

```lua
{
  protocol_version = "repository.candidate_closure_receipt.v0",
  closure_id = "candidate-closure:<sha256>",
  request_id = string,
  root_authority_id = string,
  lifecycle_id = string,
  root_fingerprint = string,
  grant_id = string,
  lifecycle_revision_before = integer,
  lifecycle_revision_after = integer,
  inventory_id = string,
  inventory_digest = string,
  state = "sealed",
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

Candidate-seal payload:

```lua
{
  protocol_version = "repository.candidate_seal.v0",
  candidate_seal_id = "candidate-seal:<sha256>",
  packet_id = string,
  lineage_id = string,
  generation = integer,
  process_contract_id = string,
  context = "software_task.v0",
  stage_id = string,
  repository_id = string,
  root_authority_id = string,
  lifecycle_id = string,
  root_fingerprint = string,
  artifact_set_id = string,
  request_id = string,
  inventory_id = string,
  inventory_digest = string,
  authority_closure_ref = string,
  artifacts = {
    {
      relative_path = string,
      work_unit_id = string,
      work_unit_version = integer,
      bytes = integer,
      sha256 = string,
      completion_ref = string,
      verification_ref = string,
    },
  },
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "mixed",
}
```

The dedicated body writer must verify:

```text
Packet is mutable, build-mode and currently acting as ☶
request identity is current and re-derived
closure receipt schema and digest are exact
private closure projection is sealed and agrees with receipt
request, inventory and closure refs all agree
no contradictory candidate-seal event exists
```

Only then may it call the private repository-event append path. The registry
stores closure/request/inventory identity, not `candidate_seal_id`; the latter
belongs to the body event after append.

## 11. Idempotence And Split-Brain Detection

An exact repeated call succeeds without provider work only when:

```text
normalized request digest is identical
private registry reports the identical sealed closure
immutable body trace contains the identical candidate-seal event
```

| State | Result |
|---|---|
| all three exact | detached existing seal; no transition/event/inventory |
| private sealed, body event absent | loud invariant |
| body event present, private state absent/contradictory | loud invariant |
| same root with changed request | terminal denial |
| same request id with changed normalized content | identity failure |

Idempotence reads existing facts. It never performs a second closure commit or
manufactures a missing public/private half.

## 12. Operator Boundary And Shadow Integration

Canonical choreography is:

```text
☱ review candidate-seal request
☶ execute closure, inventory, commit and body append
☱ observe committed candidate seal
```

The first implementation exposes direct service calls plus observation-only
instrumentation. It does not add a pressure reader, change readiness of an
existing organ, alter routes or promote the seal path to body authority.

On a valid body event, pure readers may derive:

```text
completion_scope.highest_scope = candidate_sealed
work_layer = build ⊞ / candidate_sealed_qa_pending
```

They may not derive QA acceptance, software acceptance, stage completion or
root delivery.

### 12.1 Historical Finality And Alignment

A valid candidate-seal event remains visible for the rest of its generation.
Later field motion cannot turn it into `candidate_seal_absent`.

The current comparison is a separate pure projection:

```lua
{
  protocol_version = "repository.candidate_seal_alignment.v0",
  alignment_id = "candidate-seal-alignment:<sha256>",
  packet_id = string,
  lineage_id = string,
  generation = integer,
  candidate_seal_id = string,
  sealed_artifact_set_id = string,
  current_artifact_set_id = string | nil,
  state = "aligned" | "diverged",
  reason = "exact_current_artifact_evidence"
    | "current_artifact_set_unavailable"
    | "current_artifact_set_changed"
    | "current_artifact_evidence_changed",
  source_refs = string[],
  conflicting_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

Identity hashes every field except `alignment_id`. `aligned` requires the exact
current artifact-set identity, completed artifact evidence, completion refs,
verification refs and sealed artifact values. A typed current-body absence or
staleness derives `diverged`; malformed body/seal invariants remain loud.

The view stores no state and grants no authority. Divergence cannot reopen the
root, lower physical scope below `candidate_sealed`, authorize QA acceptance or
request repository materialization.

## 13. Control Battery

Implement all TABLE controls `ST01` through `ST34`. The minimum blocking
groups are:

```text
preparation
  caller omission, stale version, incomplete set, multiple grants, in-flight

authority
  old lease denial, new action/mint denial, descendant denial

inventory
  exact flat/nested tree, every extra/missing/kind mismatch
  symlink no-follow and race, special files, root/file replacement
  deterministic order, all hard bounds, no raw bytes in public state

commit
  one exact event, exact repeat, changed request, contradictory receipt
  post-commit append failure remains sealed and loud

mortality/isolation
  grown quarantine death, malformed trusted output keeps harness red
  observer enabled/disabled has identical route/loss/budget/revisions

finality/alignment
  SF01-SF08 from TABLE
  historical seal remains visible after relevant body drift
  divergence is typed and detached; malformed history remains loud
  completion/work layer never request materialization from a sealed root
```

Hostile inventory tests use real descriptors and race hooks in the native
fixture. End-to-end body tests grow formation, choice, effects and completion
through real writers. Synthetic closure/seal tables cannot satisfy evidence.

## 14. Acceptance Gate

```text
all existing repository, mortality and authority suites green
all ST01-ST34 controls green or explicitly blocked by a named deferral
no provider entry after seal_pending
no raw bytes/handle/absolute path in trace, corpse, carrier or run report
exact private/public split-brain cases fail loudly
schema-valid quarantine reaches existing effect_failure mortality
malformed trusted output never becomes ordinary Packet death
hand-disabled and seal-observer-disabled ablations are exact
router/pressure trace is unchanged before promotion
post-seal drift preserves seal identity and terminal root authority
```

The native implementation is not accepted on fake-provider tests alone.

## 15. Explicit Deferrals

```text
QA read-only capability/check/verdict execution
fresh repository allocator
automatic quarantine recovery
persistent crash recovery of private sealed state
host-global filesystem immutability
cleanup/repair/delete/rename hands
router promotion
CLI/TUI presentation
documentation export
```

## 16. Supersession Map

This blueprint supersedes the transaction details in
`candidate_seal.v0.md`:

```text
old single generation/repository lifecycle key
old active_dispatches counter as in-flight evidence
old provider_no_effect abort wording
old lifecycle field candidate_seal_id
old generic inventory/provider boundary
```

The older blueprint remains archaeology and still owns no QA implementation.
Its high-level definition of a seal remains compatible.

## 17. Blueprint Thesis

```text
The candidate exists only when the body proves what is present and the registry
proves that its own hand can no longer rewrite it. Neither proof may speak for
the other, and disagreement is never repaired by reopening the world.
```
