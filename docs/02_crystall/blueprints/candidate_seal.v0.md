# Candidate Seal Blueprint v0

Status:

```text
crystall
date: 2026-07-20
source table: docs/01_table/yellowprints/completion_scope_candidate_seal_yellowprint.v0.md
depends on: docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
implementation authority: disabled-by-default candidate lifecycle and seal transaction
QA execution authority: forbidden
root completion authority: forbidden
F4 boundary: seal exposes exact immutable identity to future QA; rejected
  terminal projection is owned later by the verdict/manifest chain
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
2026-07-21 cross-table documentary gate: satisfied
```

## 0. Crystallized Claim

A candidate seal is not a hash and not a status label.

```text
seal = exact declared artifact set
     + exact final no-follow inventory
     + atomically closed source-write authority
     + immutable body-owned receipt
```

After a valid seal, no actor can create another path, reuse an old lease, mint a
new materialization grant for that generation/repository, or treat the seal id
as authority.

## 1. Safety Refinement

The table describes inventory and authority closure as one conceptual
transaction. The executable order is refined to remove a time-of-check/time-of-
use window:

```text
1. prove artifact-set completion and construct exact seal request
2. private registry atomically changes repository lifecycle active -> seal_pending
3. that transition invalidates future dispatch and every unconsumed old lease
4. trusted provider revalidates root identity and takes final bounded inventory
5. registry commits seal_pending -> sealed against that exact inventory digest
6. body verifies closure receipt and appends candidate_seal
```

No file authority exists between final inventory and committed closure. Failure
after step 2 either returns to `active` only when the provider proves no closure
occurred, or quarantines the lifecycle. Ambiguous authority state never reopens.

## 2. Target Surface

New:

```text
runtime/artifact_set.lua
runtime/candidate_seal.lua
tests/test_artifact_set.lua
tests/test_candidate_seal.lua
tests/test_candidate_seal_hostile.lua
```

Modify:

```text
runtime/repository_capability.lua   private generation/repository lifecycle
runtime/repository_provider.lua     bounded no-follow inventory operation
runtime/body.lua                    closed candidate-seal event writer
core/packet.lua                     event schema/actor rights only
native/proc17_repository_fs.c       native inventory if Lua provider cannot prove it
native/proc17_repository_fs.h       exact inventory API
tests/support/repository_hands.lua
tests/run.lua
```

The provider implementation is selected only after a threat-model test proves
the same no-follow/root-identity guarantees as the current create/read path.

## 3. Artifact-Set Contract

Module:

```lua
local artifact_set = require("runtime.artifact_set")

artifact_set.validate(contract) -> normalized | nil, err
artifact_set.inspect(instance, contract) -> inspection | nil, err
artifact_set.same(left, right) -> boolean
```

Contract:

```lua
{
  protocol_version = "repository.artifact_set_contract.v0",
  artifact_set_id = "artifact-set:<sha256>",
  packet_id = string,
  lineage_id = string,
  generation = integer,
  stage_id = string,
  repository_id = string,
  artifacts = {
    {
      work_unit_id = string,
      work_unit_version = integer,
      relative_path = string,
      expected_kind = "regular_file",
    },
  },
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "semantic_proposal" | "mixed",
}
```

Hard bounds are supplied by trusted configuration:

```text
max_artifacts
max_relative_path_bytes
max_total_declared_bytes when sizes are declared
max_directory_depth
```

Validation rejects duplicate paths, duplicate work ids, absolute paths, parent
traversal, NUL, malformed UTF-8 under current path policy, symlink/special-file
expectations and every foreign identity.

Inspection joins each declared work id/version to one exact current
`work_completion` and accepted verification chain. Undeclared files never make
the set complete.

## 4. Private Repository Lifecycle

`runtime.repository_capability` gains one private lifecycle keyed by:

```text
session_id
lineage_id
generation
repository_id
root_fingerprint
```

State:

```lua
{
  state = "active" | "seal_pending" | "sealed" | "quarantined",
  revision = integer,
  active_dispatches = integer,
  seal_transaction_id = string | nil,
  candidate_seal_id = string | nil,
  inventory_digest = string | nil,
}
```

The lifecycle is private closure state. Returned grant projections may report a
non-authoritative lifecycle label/revision for diagnostics, but cannot mutate or
replace it.

New conceptual API:

```lua
capabilities.begin_candidate_seal(registry, request)
  -> seal_lease | nil, err

capabilities.commit_candidate_seal(registry, seal_lease, provider_receipt)
  -> closure_receipt | nil, err

capabilities.abort_candidate_seal(registry, seal_lease, provider_no_effect)
  -> lifecycle_projection | nil, err

capabilities.candidate_lifecycle(registry, identity)
  -> detached_projection | nil, err
```

`begin_candidate_seal` requires zero active dispatch leases. It increments the
lifecycle revision, moves to `seal_pending`, makes every materialization
resolution fail, and issues one opaque single-use seal lease.

`commit_candidate_seal` is valid once. `sealed` and `quarantined` are terminal
for source-write authority.

Minting a grant against a non-active lifecycle is denied even if every supplied
identity string is correct.

## 5. Seal Request

`runtime.candidate_seal` exposes:

```lua
candidate_seal.prepare(instance, artifact_contract, services, options)
  -> request | nil, err

candidate_seal.verify_closure(request, provider_receipt, closure_receipt)
  -> seal | nil, err

candidate_seal.commit(instance, seal)
  -> stored_event | nil, err

candidate_seal.find(instance, candidate_seal_id)
  -> detached_seal, event | nil, reason
```

`prepare` is pure over Packet evidence and detached host projections. It does
not change lifecycle state. The trusted runner/body calls registry methods only
after readiness and action identity agree.

Request:

```lua
{
  protocol_version = "repository.candidate_seal_request.v0",
  request_id = "candidate-seal-request:<sha256>",
  packet_id = string,
  lineage_id = string,
  generation = integer,
  stage_id = string,
  repository_id = string,
  root_fingerprint = string,
  artifact_set_id = string,
  artifacts = table[],
  completion_refs = string[],
  verification_refs = string[],
  materialization_grant_id = string,
  materialization_grant_revision = integer,
  source_refs = string[],
}
```

## 6. Provider Inventory Contract

The provider receives only an opaque repository handle and closed request:

```lua
provider.inventory_candidate(handle, {
  expected_root_fingerprint = string,
  expected_paths = string[],
  max_entries = integer,
  max_total_bytes = integer,
  max_path_bytes = integer,
}) -> inventory_receipt | nil, provider_error
```

Receipt:

```lua
{
  protocol_version = "repository.candidate_inventory.v0",
  repository_id = string,
  root_fingerprint = string,
  entries = {
    {
      relative_path = string,
      kind = "regular_file" | "directory",
      bytes = integer | nil,
      sha256 = string | nil,
      mode = integer,
    },
  },
  entry_count = integer,
  total_file_bytes = integer,
  inventory_digest = string,
  provider_id = string,
  event_truth_status = "runtime_confirmed",
}
```

Provider laws:

```text
descriptor-relative traversal only
no symlink following at any component
root identity revalidated before and after inventory
regular files read with hard expected-plus-one bounds
undeclared files and directories remain visible in inventory
special files are reported and rejected, never opened for content
directory/file count and byte limits are hard
no shell/helper fallback
```

The seal verifier requires exact agreement between declaration, work
completion, read-back verification and inventory bytes/digests.

## 7. Closure Receipt

The private registry returns:

```lua
{
  protocol_version = "repository.candidate_seal_closure.v0",
  closure_id = "candidate-seal-closure:<sha256>",
  transaction_id = string,
  repository_id = string,
  root_fingerprint = string,
  lifecycle_revision_before = integer,
  sealed_lifecycle_revision = integer,
  materialization_grant_id = string,
  materialization_grant_revision_before = integer,
  inventory_digest = string,
  state = "sealed",
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

The closure receipt has no provider handle, lease, path root or callable
authority.

## 8. Candidate Seal Record

```lua
{
  protocol_version = "repository.candidate_seal.v0",
  candidate_seal_id = "candidate-seal:<sha256>",

  packet_id = string,
  lineage_id = string,
  generation = integer,
  stage_id = string,
  repository_id = string,
  root_fingerprint = string,
  artifact_set_id = string,

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

  inventory_ref = string,
  inventory_digest = string,
  materialization_grant_id = string,
  materialization_grant_revision_before = integer,
  sealed_grant_revision = integer,
  authority_closure_ref = string,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "mixed",
}
```

`candidate_seal_id` hashes every field except itself. Artifact order follows the normalized
artifact-set contract. The event writer deep-copies and validates the complete
record before append.

## 9. Body Event And Rights

New event:

```text
type: candidate_seal
actor: body-owned dedicated seal commit path
operator: current lawful body operator selected by later routing treatment
truth_status: runtime_confirmed
```

The generic trace writer cannot forge it. The substrate cannot return it as a
tool result. The event append occurs only after both provider and registry
receipts validate.

If authority closes but the body cannot append the trusted record, the runner
fails loudly and leaves lifecycle `sealed` or `quarantined`. It never reopens to
make the Packet look coherent.

## 10. Post-Seal Enforcement

Every source-write resolution checks private lifecycle before issuing a lease.

| Attempt | Required result |
|---|---|
| old unconsumed effect lease | invalidated by lifecycle revision |
| recreate existing path | denied before provider call |
| create new absent path | denied before provider call |
| mint another grant | denied by sealed lifecycle key |
| caller mutates grant projection | no authority delta |
| caller supplies seal id as grant | no matching private authority |
| root identity changes | lifecycle quarantined; seal verification fails loudly |
| read for future QA | separate read-only QA capability only |
| write test cache into source root | denied |

## 11. Failure Classes

| Failure | Classification | State consequence |
|---|---|---|
| artifact set incomplete/stale | task readiness | lifecycle stays active |
| no exact grant/lifecycle | typed capability exclusion | no provider call |
| active dispatch exists | typed seal exclusion | no transition |
| begin-seal validation fails | no-effect trusted error | active |
| provider reports declared mismatch | task/effect evidence | abort to active only with exact no-effect proof |
| provider root changes or inventory is ambiguous | authority ambiguity | quarantine |
| malformed provider receipt | harness/world invariant | loud; seal_pending/quarantine |
| closure commit succeeds, body append fails | runtime invariant | loud; sealed remains sealed |
| post-seal write attempted | denied capability action | sealed unchanged |

No invariant failure becomes an honest Packet death.

## 12. Truth Law

```text
declaration act                         runtime_confirmed
artifact semantic sufficiency           semantic_proposal/mixed
exact observed bytes and inventory       runtime_confirmed
authority lifecycle transition           runtime_confirmed
seal append act                          runtime_confirmed
artifact meaning after seal              unchanged proposal/mixed
```

Sealing freezes identity and authority. It does not prove software quality.

## 13. Permanent Controls

```text
AS01 duplicate path/work id rejects declaration
AS02 stale completion cannot satisfy artifact set
AS03 undeclared extra path does not satisfy set and blocks seal inventory
AS04 complete exact multi-artifact set is order-stable

SE01 complete set + exact inventory + closure creates one seal
SE02 repeating exact seal returns same historical seal, no second transition
SE03 incomplete set never begins seal
SE04 begin seal with active dispatch is excluded
SE05 old lease cannot execute after seal_pending revision
SE06 new grant cannot be minted during seal_pending
SE07 new grant cannot be minted after sealed
SE08 create existing path after seal is zero-provider-call denial
SE09 create new absent path after seal is zero-provider-call denial
SE10 root replacement during inventory quarantines lifecycle
SE11 symlink/special/undeclared inventory entry rejects seal
SE12 malformed trusted receipt fails harness loudly
SE13 closure success plus event-append failure never reopens authority
SE14 returned request/receipt/seal mutation changes no stored state
SE15 seal/corpse/carrier exports contain no handle or lease
SE16 observer enabled/disabled before authority promotion changes no route/loss
```

Hostile controls must use the real native provider whenever available. A pure
Lua fake cannot prove no-follow or descriptor-root identity.

## 14. Implementation Order

```text
1. artifact-set validation and pure completion inspection
2. private repository lifecycle with active-only grant mint/resolve
3. seal_pending transition and old-lease invalidation tests
4. bounded provider inventory and native hostile tests
5. closure receipt and quarantine branches
6. candidate_seal pure verification and body event writer
7. post-seal create/mint/replay denial battery
8. exact seal repeat/idempotence controls
9. completion_scope shadow consumption
10. separate QA threat-model campaign
```

Each step lands red tests before implementation. Steps 2-7 require the same
paranoid review standard as the first repository hand.

## 15. Promotion Gates

```text
G0 artifact-set schema and bounds are closed
G1 lifecycle is private and cannot be forged through projections
G2 seal_pending removes all write readiness before inventory
G3 native inventory proves no-follow/root identity under hostile fixtures
G4 sealed lifecycle rejects every current and future write surface
G5 ambiguous trusted state quarantines rather than reopens
G6 seal event is body-only, immutable and exact
G7 full suite, mortality and repository hostile batteries remain green
```

## 16. Explicit Deferrals

```text
QA command/test hand
`qa-check.v0` record schema and final QA-verdict writer
QA scratch filesystem
replace/delete/rename hands
same-candidate repair
post-seal product-documentation edits
automatic cleanup of sealed/rejected roots
remote/network provider
persistent lifecycle recovery after host crash
semantic selection of artifact or QA contracts
root completion promotion
```

## 17. Crystall Thesis

```text
The candidate is ready to be judged only when the body has made further source
mutation physically unavailable, not merely socially forbidden.
```
