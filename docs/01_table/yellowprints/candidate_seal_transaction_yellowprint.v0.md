# Candidate Seal Transaction Yellowprint v0

Status:

```text
layer: table (⊞)
date: 2026-07-22
scope: exact candidate seal preparation, inventory, closure and body append
runtime implementation authorized: no
native inventory implementation authorized: no
QA execution authorized: no
router promotion authorized: no
crystallization authorized: yes, by 2026-07-22 documentary gate
gate record:
  docs/00_chaos/candidate_seal_table_cross_audit_2026-07-22.md
crystallized as:
  docs/02_crystall/blueprints/candidate_seal_transaction.v0.md
```

Primary chaos source:

[`../../00_chaos/candidate_seal_runtime_boundary_notes_2026-07-21.md`](../../00_chaos/candidate_seal_runtime_boundary_notes_2026-07-21.md)

Companion TABLE contracts:

```text
artifact_set_derivation_yellowprint.v0.md
repository_candidate_lifecycle_yellowprint.v0.md
completion_scope_candidate_seal_yellowprint.v0.md
capability_safe_repository_hands_yellowprint.v0.md
stage_transition_generation_recovery_yellowprint.v0.md
```

This table refines the transaction, failure and control surfaces in
`completion_scope_candidate_seal_yellowprint.v0.md` §§7-9, 18-21. It preserves
that table's completion-scope and QA boundaries.

## 0. Selected Decisions

```text
S01 a seal binds exact derived declaration, exact final inventory and closure
S02 seal review is ☱; physical closure/inventory/append is one ☶ boundary
S03 declaration is re-derived; no caller-selected artifact subset is accepted
S04 begin-seal requires the exact owning generation lifecycle
S05 begin-seal rejects several active exact-root grants
S06 action consumption and in-flight provider execution remain distinct
S07 seal_pending invalidates old leases before final inventory
S08 inventory is descriptor-relative, no-follow, bounded and exact-tree
S09 native provider returns bounded bytes privately; trusted Lua computes SHA-256
S10 public inventory/seal records contain digests, never raw source bytes
S11 registry proves no commit/in-flight; provider proves root continuity
S12 abort to materializing requires both positive proofs
S13 missing proof, root/entry drift or ambiguous postcondition quarantines root
S14 commit then body-append failure is loud; private sealed state never reopens
S15 exact idempotence requires request, private closure and body event agreement
S16 quarantine uses existing Packet effect_failure mortality
S17 seal confirms identity/closure, not semantic software correctness
S18 QA remains absent until a later read-only capability contract
```

## 1. Closed Physical Claim

```text
Given one exact complete body-derived artifact set owned by one generation/root
lifecycle, proc-17 can close all of its source-write authority, observe the
bounded final tree, compare that tree to exact completion evidence, and append
one immutable candidate seal that joins the observation and closure facts.
```

After success:

```text
the current registry session cannot write that root again
the candidate has one independently addressable identity
future QA can revalidate and inspect exactly those sealed bytes
semantic correctness is still unproven
```

The operating system and unrelated host processes are outside this physical
immutability claim. Future QA must revalidate root identity and inventory.

## 2. Preconditions And Readiness

Seal preparation is legal only when every condition is exact:

```text
living build Packet with immutable birth/work coordinates
artifact_set.derive succeeds
artifact_set.inspect reports complete and inventory-compatible field evidence
every declared unit/version has current accepted work-completion evidence
one exact root authority record and owner generation lifecycle
root lifecycle state = materializing
one active exact-root materialization grant
zero provider dispatches in flight
no current candidate-seal body event for a different request
all relevant object versions remain current
```

Failure before `seal_pending` is readiness/task evidence. It changes no
lifecycle and does not invoke the provider.

## 3. Record Chain

### 3.1 Seal review and request

☱ derives and reviews one exact request:

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

Expected bytes and hashes are derived from exact accepted repository
verification/completion chains, not copied from substrate claims.

The request is a detached action plan. A ☱ review event may preserve its digest
and refs for routing/audit. It has no registry authority and cannot close a
grant.

### 3.2 Private provider inventory result

The native provider returns a private bounded result to the trusted Lua adapter:

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

Raw file content exists only across this trusted private adapter boundary. It
is bounded in aggregate and discarded after hashing/comparison.

### 3.3 Normalized seal inventory

The adapter validates the provider result and produces:

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

Canonical entry order is path byte order after the declared path policy. Raw
content, handles, absolute paths and provider callbacks are absent.

### 3.4 Closure receipt

After exact comparison, the registry commits the private lifecycle and returns
a detached receipt:

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

The receipt carries no authority. Its fields must exactly match private sealed
state when the body verifies it.

### 3.5 Candidate seal body event

☶ appends one immutable event containing:

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

`mixed` preserves that exact bytes/closure are runtime-confirmed while the
software meaning of those bytes originated as semantic material.

## 4. Exact-Tree Inventory Contract

Allowed tree:

```text
regular files = exactly the artifact declaration paths
directories   = root plus exactly the ancestors required by those paths
everything else is visible mismatch
```

An extra empty directory is not ignored. Host metadata outside the candidate
root is irrelevant; host contamination inside the root makes the candidate
not sealable.

Native inventory laws:

```text
descriptor-relative traversal only
no symlink following at any component
root identity checked before and after traversal
each regular file identity checked before and after bounded read
directory entries observed in deterministic normalized form
second bounded enumeration or equivalent stability proof
hard path length, component, depth, entry and aggregate-byte ceilings
special files named but never opened for content
unexpected entries never filtered by expected declaration
no shell, helper process or Lua filesystem fallback
```

The provider does not receive an expected-file filter that could hide extra
entries. The trusted Lua verifier performs comparison after full bounded
observation.

### 4.1 Hash ownership

The native provider returns bounded captured bytes. The trusted Lua adapter:

```text
checks exact byte count
computes SHA-256 with core.digest
compares expected completion digest
constructs normalized inventory
drops raw bytes before any public/body record
```

This preserves one SHA implementation. Per-file and aggregate byte ceilings
must both be enforced before allocation can exceed trusted bounds.

## 5. Causal Transaction

Canonical path:

```text
1. artifact_set.derive re-derives the only authoritative declaration
2. artifact_set.inspect proves exact current completion
3. ☱ reviews request and names one ☶ reader
4. registry revalidates owner lifecycle, one active grant and zero in-flight
5. registry atomically enters seal_pending and advances revision
6. every old lease/new source-write path is now denied
7. provider performs bounded stable exact-tree inventory
8. Lua adapter validates, hashes and compares every entry
9. registry commits seal_pending -> sealed against request/inventory digests
10. registry returns detached closure receipt
11. ☶ verifies private projection + receipt and appends candidate_seal
12. ☱ observes the seal and completion/work-layer readers may derive
    candidate_sealed / build ⊞
```

No source-write authority exists during steps 7 through 11. No substrate call
is required after the declaration exists.

## 6. Abort, Quarantine And Loud Failure

### 6.1 Two-proof abort law

Return from `seal_pending` to `materializing` requires both:

```text
registry proof
  the closure commit did not occur
  the exact seal transaction is still current
  no provider dispatch remains in flight

provider proof
  original root identity was revalidated after the attempt
  observation postconditions are exact enough to classify no closure
```

Neither actor may testify for the other.

### 6.2 Decision matrix

| Condition | Registry evidence | Provider evidence | Lifecycle result | Runtime/Packet result |
|---|---|---|---|---|
| readiness fails before pending | no transition | no call | materializing | typed not-ready |
| stable complete inventory has missing/extra/mismatched entry | commit absent | continuity proven | materializing | typed seal mismatch; no false seal |
| bound exceeded, bounded receipt closes with root continuity | commit absent | continuity proven | materializing | typed bounded failure |
| active provider dispatch found before pending | no transition | call still active | materializing | begin-seal not ready |
| root replaced | commit absent/unknown | continuity disproven | quarantined | typed `effect_failure` |
| entry changes during inventory | commit absent | stable observation absent | quarantined | typed `effect_failure` |
| schema-valid ambiguous provider failure/unknown publication | commit absent/unknown | continuity absent | quarantined | typed `effect_failure` |
| provider panic or malformed trusted result | cannot safely accept commit | continuity absent | quarantined | loud boundary/runtime invariant |
| trusted result contradicts private request/lifecycle identity | cannot accept commit | invalid | quarantined | loud invariant + terminal authority denial |
| malformed trusted receipt while pending | cannot safely consume | continuity not independently proven | quarantined | loud invariant, not cosmetic Packet death |
| exact commit succeeds | sealed | exact receipt | sealed | append body event |
| body append fails after commit | sealed fact remains | inventory already exact | sealed | loud runtime invariant; no reopen |

`materializing` after abort means only that registry authority is coherent. It
does not claim the candidate can be repaired or eventually sealed. With an
undeletable extra path, higher body logic may honestly stop the Packet.

### 6.3 Mortality law

Seal quarantine reuses the existing path:

```text
root quarantine
  -> typed terminal repository effect_failure
  -> operator_failure body event
  -> Packet death cause effect_failure
  -> blocked lineage in v0
```

No `seal_failed` death cause is introduced. Automatic fresh-root recovery is a
future lineage policy and inherits no candidate truth from a quarantined root.

This mortality path applies to schema-valid world/authority ambiguity. A
defensive quarantine caused by malformed trusted output still closes the root,
but the harness/runtime invariant remains loud and does not get laundered into
an aesthetically valid Packet death.

## 7. Commit And Public/Private Agreement

The registry may commit `sealed` only after exact inventory comparison. The
body may append `candidate_seal` only after verifying:

```text
request identity is current
closure receipt is schema-exact
private lifecycle projection is sealed
private request/inventory/seal refs match receipt
Packet actor tick is ☶ and still mutable
no existing contradictory seal event exists
```

The append and private commit cannot be made one OS-level transaction. The
failure direction is therefore explicit:

```text
private closure is irreversible
body append is attempted immediately in the same ☶ boundary
append failure stops the harness loudly
source-write authority remains sealed
```

Reopening authority to repair trace appearance is forbidden.

## 8. Exact Idempotence

An exact repeat after success returns the existing seal only when all three
surfaces agree:

```text
same normalized request digest
same private sealed lifecycle and closure receipt
same immutable candidate-seal body event
```

Outcomes:

| Repeat state | Result |
|---|---|
| all three exact | detached existing seal; no transition/event/costly inventory |
| sealed private state, body event missing | loud invariant |
| body seal event present, private session state contradictory | loud invariant/current session cannot claim idempotence |
| same root, changed declaration/request | terminal denial |
| same request id, changed normalized content | digest/contract failure |

Idempotence is observation of an existing fact, never a second seal attempt.

## 9. Operator And Routing Boundary

Canonical organ choreography:

```text
☱ candidate review
  -> ☶ closure + inventory + candidate_seal append
  -> ☱ committed-seal observation
```

The ☶ operation may return one of:

```text
sealed result
typed stable mismatch/no-effect result
typed quarantine effect failure
loud invariant error
```

This TABLE does not add pressure readers or promote routes. Direct service
tests and observation-only instrumentation prove transaction physics first.
The legacy/current router remains untouched until a later promotion record.

## 10. Completion And QA Boundary

After a valid body event:

```text
completion_scope may derive highest_scope = candidate_sealed
work_layer may derive build ⊞ / candidate_sealed_qa_pending
```

It may not derive:

```text
QA accepted
software accepted
stage complete
root delivery complete
```

QA receives a future separate read-only capability and must revalidate the
root/inventory before trusting the body-relative seal. The seal itself is not
a read or write capability.

## 11. Truth Matrix

| Claim | Truth status |
|---|---|
| exact request assembled from body evidence | `runtime_confirmed` act |
| root authority entered seal_pending/sealed | `runtime_confirmed` |
| observed root identity and entries | `runtime_confirmed` under provider contract |
| bytes/hash comparison | `runtime_confirmed` |
| candidate-seal event append | `runtime_confirmed` |
| artifact semantics/correctness | preserved `semantic_proposal` or `mixed` |
| seal applicability after unrelated host mutation | must be revalidated; not eternal truth |
| QA outcome | absent in step 8.4 |

## 12. Named Writers And Readers

| Record/view | Writer | First named reader |
|---|---|---|
| artifact-set declaration | pure body derivation | artifact inspector/seal planner |
| artifact-set inspection | pure current evidence inspector | seal planner |
| seal review/request | ☱ body action review | ☶ seal effect |
| private root/lifecycle transition | capability registry | inventory/closure path and detached verifier |
| private provider inventory result | native provider | strict Lua inventory adapter |
| normalized inventory | strict Lua adapter | seal comparator and registry commit |
| closure receipt | private registry | candidate-seal body verifier |
| candidate seal | dedicated ☶ body writer | completion scope, future QA, corpse/corpus |
| stable mismatch diagnostic | seal comparator/operator outcome | ☱/higher body policy |
| quarantine effect failure | registry/provider boundary | operator failure/mortality path |
| build ⊞ projection | pure work-layer inspector | instrumentation, future QA pressure |

No record is written without a named reader.

## 13. Permanent Controls

### Preparation controls

| ID | Control | Expected result |
|---|---|---|
| ST01 | caller omits one artifact from detached set | re-derive mismatch; no pending |
| ST02 | one declared work version stale | no pending |
| ST03 | artifact set incomplete | no pending |
| ST04 | multiple active exact-root grants | typed ambiguity; no pending |
| ST05 | active provider dispatch | not ready; no pending |
| ST06 | substrate claims root sealed | zero registry/body delta |

### Authority controls

| ID | Control | Expected result |
|---|---|---|
| ST07 | old lease issued before seal_pending | denied after revision, zero provider calls |
| ST08 | new action after seal_pending | denied before provider call |
| ST09 | new mint/resolve after seal_pending | denied |
| ST10 | descendant generation same root | denied by owner/terminal lock |

### Inventory controls

| ID | Control | Expected result |
|---|---|---|
| ST11 | exact one-file tree | exact normalized inventory |
| ST12 | nested declared tree | only required ancestors accepted |
| ST13 | extra regular file | stable mismatch; no seal |
| ST14 | extra empty directory | stable mismatch; no seal |
| ST15 | missing declared file | stable mismatch; no seal |
| ST16 | stable symlink at any depth | never followed; stable mismatch and no seal |
| ST16a | symlink/path race prevents stable postcondition | never followed; quarantine |
| ST17 | fifo/socket/device | never opened; mismatch |
| ST18 | readdir order permutations | identical inventory digest |
| ST19 | file grows/replaced during read | quarantine |
| ST20 | root replacement | quarantine |
| ST21 | entry/depth/path/byte bound | typed bounded result; active only with dual proof |
| ST22 | raw file bytes searched in public trace/receipt | absent |

### Commit/idempotence controls

| ID | Control | Expected result |
|---|---|---|
| ST23 | exact request + inventory + closure | one seal event |
| ST24 | repeat exact seal | same seal, no second transition/event |
| ST25 | repeat with changed artifact | terminal denial |
| ST26 | closure receipt contradicts private state | loud invariant |
| ST27 | append fails after private commit | sealed remains; loud invariant |
| ST28 | mutate returned receipt/seal | zero private/trace delta |
| ST29 | private sealed but event absent | loud invariant, not idempotent success |

### Mortality/isolation controls

| ID | Control | Expected result |
|---|---|---|
| ST30 | stable inventory mismatch | Packet not falsely complete/sealed |
| ST31 | quarantine through grown ☶ life | Packet dies `effect_failure`, lineage blocked |
| ST32 | malformed trusted receipt | harness red, not beautiful Packet death |
| ST33 | seal observer enabled/disabled | same route/loss before promotion |
| ST34 | documentation profile changes | same seal identity |

Native hostile fixtures must exercise real directory descriptors and races.
Body fixtures must grow formation, effects and completion through the real
organs; synthetic seal/closure tables cannot satisfy promotion evidence.

## 14. CRYSTALL Consequences

The later CRYSTALL round must amend:

```text
candidate_seal.v0 request/inventory/closure schemas and two-proof failure law
capability_safe_repository_hands.v0 in-flight provider boundary
completion_scope.v0 candidate-seal reader
work_layer_projection.v0 candidate-sealed reason/refs
native provider ABI contract before native code is touched
```

The CRYSTALL must explicitly mark prior single-lifecycle and generic
`provider_no_effect` wording as superseded. It may not begin QA design.

## 15. Explicit Deferrals

```text
QA capability/check/verdict execution
fresh repository allocator
automatic recovery from quarantine
persistent crash recovery of seal_pending/sealed state
global filesystem snapshot/immutability
source-tree cleanup or repair
replace/delete/rename hands
router promotion
CLI/TUI rendering
documentation export
```

## 16. Table Thesis

```text
A seal is the moment when the body proves both what exists and that it has
stopped being able to rewrite it. A digest without closed authority is a label;
closed authority without an exact body event is an unreported fact. The
candidate exists only when both sides agree.
```
