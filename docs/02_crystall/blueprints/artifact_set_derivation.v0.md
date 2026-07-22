# Artifact Set Derivation Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-07-22
source table:
  docs/01_table/yellowprints/artifact_set_derivation_yellowprint.v0.md
gate record:
  docs/00_chaos/candidate_seal_table_cross_audit_2026-07-22.md
implementation authority: pure formation reader, artifact-set derivation and
  schema migration
candidate seal authority: forbidden; separate blueprint
repository mutation authority: unchanged
QA authority: forbidden
router promotion: forbidden
```

## 0. Crystallized Claim

The body, not the caller, derives the only artifact-set declaration admissible
to candidate sealing.

```text
immutable build birth coordinates
  + one exact current repository formation
  + exact current live/selected units
  + exact choice evidence when selected
  -> one deterministic repository.artifact_set_contract.v0
```

Derivation confirms causal membership and normalized identity. It does not
confirm completion, filesystem contents, seal or semantic sufficiency.

## 1. Target Surface

New pure module:

```text
runtime/repository_formation.lua
tests/test_repository_formation.lua
```

Modify:

```text
runtime/artifact_set.lua
runtime/repository_intent.lua
runtime/completion_scope.lua       compatibility reader only
tests/test_artifact_set.lua
tests/test_repository_intent.lua
tests/test_completion_scope.lua
tests/test_work_layer.lua
tests/run.lua
```

No changes in this slice:

```text
core/packet.lua
runtime/body.lua
runtime/repository_capability.lua
runtime/repository_provider.lua
runtime/tension_runner.lua
native/*
organs/*
```

## 2. Shared Pure Formation Reader

`runtime.repository_formation` prevents repository intent and artifact-set
derivation from implementing incompatible formation truth.

Public API:

```lua
local formation = require("runtime.repository_formation")

formation.for_unit(instance, unit_id, unit_version)
  -> unit_basis | nil, diagnostic

formation.current_set(instance, options)
  -> set_basis | nil, diagnostic
```

`options` accepts exactly:

```lua
{
  max_units = integer,
}
```

It cannot accept formation ids, choice ids, unit lists or repository paths.

### 2.1 Unit basis

```lua
{
  protocol_version = "runtime.repository_unit_formation_basis.v0",
  packet_id = string,
  lineage_id = string,
  generation = integer,
  unit_id = string,
  unit_version = integer,
  unit_created_event_ref = string,
  activation = "live" | "selected",
  formation_event_ref = string,
  choice_event_ref = string | nil,
  provenance_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

### 2.2 Set basis

```lua
{
  protocol_version = "runtime.repository_formation_set.v0",
  packet_id = string,
  lineage_id = string,
  generation = integer,
  formation_event_ref = string,
  choice_event_ref = string | nil,
  units = unit_basis[],
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "semantic_proposal" | "mixed",
}
```

`current_set` scans canonical `field.unit_order`, selects current-generation
live/selected `repository.create_text_file.v0` units, resolves each through
`for_unit`, and requires one shared formation event. It returns detached data.

### 2.3 Formation and choice verification

For one unit, the reader requires:

```text
current exact field unit id/version/generation
one structure_formation event written for this Packet/generation
formed_unit_ids contains the unit exactly once
formed_unit_versions names a formation-time version <= current version
unit creation/source refs agree with the formation chain
```

If activation is `selected`, it additionally verifies one current CHOOSE event
whose frozen choice set is the same formation and whose selected member is this
unit/version. Suppressed peers cannot satisfy `for_unit`.

Multiple matching formation or choice events are typed ambiguity. The reader
does not select the newest, first or lexicographically smallest event.

### 2.4 Repository-intent migration

`runtime.repository_intent` removes its private `formation_for` implementation
and calls `repository_formation.for_unit`. Existing intent/action identities
must remain byte-identical for the same evidence because the returned
formation/provenance refs are unchanged.

The migration requires a matched ablation fixture:

```text
old reader shadow vs shared reader
same intent id, action id, path, content digest and provenance refs
```

The old reader may remain temporarily only as an observation-only comparison;
it cannot remain a second production authority.

## 3. Artifact-Set API

Target API:

```lua
local artifact_set = require("runtime.artifact_set")

artifact_set.derive(instance)
  -> detached_contract | nil, diagnostic

artifact_set.identify(value)
  -> artifact_set_id | nil, err

artifact_set.validate(value)
  -> normalized_detached_contract | nil, err

artifact_set.inspect(instance, contract)
  -> inspection | nil, err

artifact_set.same(left, right)
  -> boolean
```

`derive` accepts no caller contract or process view. `validate` remains a shape
and identity verifier; it does not grant caller-supplied declarations seal
authority.

## 4. Target Contract Schema

`repository.artifact_set_contract.v0` is amended before candidate sealing is
implemented:

```lua
{
  protocol_version = "repository.artifact_set_contract.v0",
  artifact_set_id = "artifact-set:<sha256>",

  packet_id = string,
  lineage_id = string,
  generation = integer,
  process_contract_id = "build.only.v0" | "software.create.v0",
  context = "software_task.v0",
  stage_id = string,
  repository_id = string,

  birth_ref = string,
  formation_event_ref = string,
  choice_event_ref = string | nil,

  artifacts = {
    {
      work_unit_id = string,
      work_unit_version = integer,
      unit_created_event_ref = string,
      relative_path = string,
      expected_kind = "regular_file",
      provenance_refs = string[],
    },
  },

  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "semantic_proposal" | "mixed",
}
```

Exact-key validation rejects old caller-built v0 records that omit the new
authority fields once the migration lands. Tests and compatibility callers
must derive records rather than hand-assemble them.

Identity is `digest.record` over the fully normalized record with
`artifact_set_id=nil`.

Normalization:

```text
artifacts sorted by relative_path then work_unit_id
provenance/source refs unique and byte-sorted
paths normalized by repository_intent.validate_relative_path
all arrays strict and bounded
all returned tables deep detached
```

## 5. Birth Contract Reader

`artifact_set.derive` verifies the first Packet trace event directly or through
one shared pure birth-contract helper introduced by the completion-scope
implementation. It must not call a caller-supplied contract view.

Required equality:

```text
Packet id, lineage, generation
work mode = build
process_contract_id compatible with build
context = software_task.v0
stage_id exact and non-empty
repository_id exact and non-empty
```

If the existing local `completion_scope.birth_contract` helper is extracted,
the extraction must preserve `completion_scope` output byte-for-byte. A second
mutable birth cache is forbidden.

## 6. Derivation Algorithm

```text
1. validate living Packet and immutable build birth
2. reject absent repository_id
3. obtain repository_formation.current_set(instance, max_artifacts)
4. require one exact formation and bounded non-empty unit set
5. parse each current carrier path and expected regular-file kind
6. reject duplicate work ids and normalized paths
7. assemble named and generic provenance refs
8. preserve weakest content truth status
9. normalize and digest contract
10. validate the produced contract through the public validator
11. return a detached copy
```

Any discrepancy between pure derivation and validation is a loud module
invariant, not a typed absence.

## 7. Inspection Compatibility

`artifact_set.inspect` keeps its current responsibility:

```text
join every declared unit/version to current field evidence
join exact accepted work completion and verification
report complete/incomplete, undeclared current units and conflicts
```

It additionally verifies that named birth/formation/choice/unit creation refs
remain exact for the current Packet. Generic `source_refs` alone cannot satisfy
these checks.

`completion_scope` may continue accepting a detached artifact-set assertion in
its shadow `contract_view`, but it must:

```text
validate it
re-derive the current set
require artifact_set.same(supplied, derived)
```

This preserves current shadow callers while removing caller selection as an
authority path.

## 8. Diagnostics

Typed derivation diagnostics:

```text
repository_artifact_set_absent
repository_identity_absent
repository_formation_missing
repository_formation_ambiguous
repository_choice_missing
repository_choice_ambiguous
repository_artifact_limit_exceeded
repository_artifact_duplicate_path
repository_artifact_duplicate_work_id
repository_artifact_foreign_generation
repository_artifact_stale
```

Malformed trusted field/trace structures return plain invariant errors and
remain loud at the harness boundary.

## 9. Control Battery

Required suites:

```text
tests/test_repository_formation.lua
  RF01 one exact live unit
  RF02 one exact selected unit with grown CHOOSE
  RF03 selected without choice
  RF04 suppressed peer excluded
  RF05 two matching formations ambiguous
  RF06 foreign/stale unit rejected
  RF07 detached-return mutation

tests/test_artifact_set.lua
  AS01-AS20 from TABLE
  schema migration exact-key rejection
  derive/validate/identify round trip
  deterministic multi-file ordering
  caller subset/superset mismatch

tests/test_repository_intent.lua
  shared-reader ablation preserves existing intent identity

tests/test_completion_scope.lua and tests/test_work_layer.lua
  supplied exact derived set remains current
  caller-built/subset set cannot advance scope
```

Formation and choice fixtures are grown through ENCODE/CHOOSE. Synthetic event
tables are not promotion evidence.

## 10. Acceptance Gate

```text
all existing suites green
repository-intent identity ablation exact
derive is mutation-free
caller cannot select declaration members
all AS/RF controls green
hand-disabled route/loss/trace ablation exact
no new substrate call
no capability or provider access from derivation modules
```

## 11. Explicit Deferrals

```text
multi-formation composition
imported artifacts
stage-ledger v1
seal lifecycle/provider/native inventory
QA
router promotion
```

## 12. Blueprint Thesis

```text
Artifact-set identity is a deterministic reading of the Packet's causal body,
not a list chosen at the irreversible boundary.
```
