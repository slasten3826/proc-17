# Documentation Corpus Assembly, Storage And Reentry Blueprint v0

Status:

```text
crystall
date: 2026-07-20
source table: docs/01_table/yellowprints/documentation_corpus_assembly_reentry_yellowprint.v0.md
snapshot source: docs/02_crystall/blueprints/documentation_layer_snapshots.v0.md
economy source: docs/02_crystall/blueprints/documentation_profiles_economy.v0.md
first implementation: in-memory structured corpus
filesystem export authority: separately promoted capability
new-task reentry authority: deferred until export/cold-reader proof
persistent same-lineage resume: forbidden
amended 2026-07-21: F6 canonical candidate-seal identity and terminal-generation corpus law
audit source: docs/00_chaos/fable_preimplementation_crystall_audit_raw_2026-07-21.md
F4 amendment: rejected generations persist through QA evidence/verdict and the
  terminal Packet manifest; no standalone failure-crystal object exists
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
2026-07-21 cross-table documentary gate: satisfied
```

## 0. Crystallized Claim

One mortal Packet manifests only the evidence available in its own life. The
lineage corpus is assembled later from verified references across all Packet
lives, stages and generations.

```text
Packet △ manifest       != lineage corpus
lineage corpus          != final delivery envelope
portable corpus reentry != resurrection
```

Corpus objects and export revisions are immutable. New evidence creates a new
object/index/export identity; it never patches an old history.

## 1. Ownership Boundary

```text
session
  -> lineage
       -> root process/documentation contracts
       -> stages
       -> generations
            -> Packet identity
            -> repository identity
            -> snapshots
            -> manifest/corpse
       -> corpus objects and indexes
       -> export revisions and receipts
       -> root delivery envelopes
```

| Object | Owner | May outlive Packet | Cross-generation law |
|---|---|---:|---|
| living field/CALM/runtime state | Packet | no | never |
| trace snapshot/corpse | lineage evidence | yes | bounded verified ref only |
| stage manifest | lineage stage | yes | typed stage ref/carrier |
| candidate repository | one build generation | yes as sealed evidence | never active child state |
| rejected-generation terminal manifest projection | source Packet manifest/corpse + lineage | yes | bounded recovery carrier |
| documentation snapshot | lineage | yes | historical verified ref |
| corpus/export | root lineage | yes | portable external artifact |
| private grant/provider handle | trusted host/session | bounded | never serialized/inherited |

## 2. Target Surface

Pure first slice:

```text
runtime/documentation_corpus.lua
runtime/documentation_reader.lua
tests/test_documentation_corpus.lua
tests/test_documentation_reader.lua
```

Capability-gated export slice:

```text
runtime/documentation_export_capability.lua
runtime/documentation_export_provider.lua
runtime/documentation_export.lua
tests/test_documentation_export_capability.lua
tests/test_documentation_export.lua
tests/test_documentation_export_linux.lua
```

Later, separately promoted:

```text
runtime/documentation_renderer.lua
runtime/documentation_reentry.lua
runtime/network_ingress.lua
runtime/lineage_runner.lua
runtime/completion_scope.lua
```

Dependencies:

```text
runtime/lineage.lua
runtime/lineage_budget.lua
runtime/corpse.lua
runtime/documentation_contract.lua
runtime/applicability.lua
runtime/documentation_economy.lua
runtime/documentation_snapshot.lua
runtime/completion_scope.lua
core/digest.lua
core/json.lua
core/sandbox.lua
```

The candidate repository capability/provider is a negative dependency: its
grant and root must never satisfy a documentation-export request.

## 3. Pure Corpus API

```lua
local corpus = require("runtime.documentation_corpus")

corpus.freeze_input(lineage_view, documentation_contract, bounds)
  -> frozen_input | nil, err

corpus.derive(frozen_input)
  -> corpus_candidate | nil, err

corpus.verify(corpus_candidate, source_resolver, bounds)
  -> verified_corpus | nil, err

corpus.same(left, right)
  -> boolean
```

The lineage view is a detached bounded projection at one exact ledger head. It
contains no mutable lineage object, private grant or provider closure.

`derive` performs no I/O and calls no substrate. It returns content-addressed
objects, one closed index and exact omissions entirely in memory.

## 4. Frozen Assembly Input

```lua
{
  protocol_version = "documentation.corpus_input.v0",
  session_id = string,
  lineage_id = string,
  ledger_head_ref = string,
  ledger_head_seq = integer,
  root_task_ref = string,
  process_contract_ref = string,
  documentation_contract_ref = string,
  profile = "structured" | "full",
  required = boolean,
  lineage_status = string,
  accepted_generation = integer | nil,
  stage_refs = string[],
  generation_records = bounded_table[],
  snapshot_refs = string[],
  terminal_record_refs = string[],
  economics_ref = string,
  completion_ref = string | nil,
  source_refs = string[],
}
```

The completion ref is the assessment available at this frozen head. For a
required documentation contract it cannot be the future final root-completion
event that depends on the export receipt.

Anything appended after `ledger_head_ref` belongs to a later corpus revision.

## 5. Corpus Object

```lua
{
  kind = "proc17_corpus_object",
  protocol_version = "documentation.corpus_object.v0",
  object_id = "corpus-object:<sha256>",
  object_kind = "root_contract" | "lineage_event" | "layer_snapshot"
    | "packet_manifest" | "corpse" | "stage_manifest"
    | "candidate_seal" | "qa_evidence" | "qa_verdict"
    | "economics" | "completion_assessment" | "lineage_slice"
    | "redaction_map",
  lineage_id = string,
  generation = integer | nil,
  packet_id = string | nil,
  payload = bounded_table,
  source_refs = string[],
  payload_truth_statuses = string[],
  completeness = table,
  created_event_ref = string,
}
```

`object_id` hashes every field except itself. The payload is canonical, bounded
and deeply detached. A matching digest proves byte integrity and identity, not
semantic truth or authorship.

## 6. Generation Entry

```lua
{
  generation = integer,
  packet_id = string,
  parent_corpse_id = string | nil,
  ingress_carrier_id = string | nil,
  stage_id = string,
  work_mode = "plan" | "build",
  candidate_repository_id = string | nil,
  candidate_digest = string | nil,
  candidate_seal_id = string | nil,
  qa_evidence_refs = string[],
  qa_verdict_ref = string | nil,
  packet_manifest_ref = string | nil,
  corpse_id = string,
  terminal_kind = string,
  death_cause = string,
  object_refs = string[],
}
```

Rules:

```text
one entry -> one Packet life
one entry -> one exact terminal event and registered corpse
living generation -> no generation entry and no fabricated terminal fields
generation identity strictly increases in linear v0 lineage
accepted_generation -> one exact accepted build generation
failed candidate digest never appears as accepted output
rejected Packet manifest embeds the bounded exact seal/verdict/check projection
descendant gets a new repository identity
plan generations keep candidate fields nil
```

Assembly at a ledger head with an active generation is legal only as an
explicitly partial historical corpus. The assembler includes terminal
ancestors, records the active generation in completeness/omission metadata and
cannot derive required full documentation or root delivery. A complete corpus
head contains terminal corpse-bound generations only.

## 7. Corpus Index

```lua
{
  kind = "proc17_documentation_corpus",
  protocol_version = "documentation.corpus.v0",
  corpus_id = "corpus:<sha256>",
  structured_content_id = "structured-content:<sha256>",
  lineage_id = string,
  session_id = string,
  ledger_head_ref = string,
  root_task_ref = string,
  process_contract_ref = string,
  documentation_contract_ref = string,
  profile = "structured" | "full",
  required = boolean,
  lineage_status = string,
  accepted_generation = integer | nil,
  stage_refs = string[],
  generation_refs = generation_corpus_entry[],
  layer_objects = {
    ["00_chaos"] = string[],
    ["01_table"] = string[],
    ["02_crystall"] = string[],
    ["03_manifest"] = string[],
  },
  source_bindings = {
    ["original-source-ref"] = "corpus-object:<sha256>",
  },
  redaction_object_refs = string[],
  omission_summary = table,
  economics_ref = string,
  completion_ref = string | nil,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_statuses = string[],
}
```

`structured_content_id` hashes the canonical profile-neutral evidence closure:
generation entries, layer object ids, redaction objects, omission inventory and
their source identities. It excludes documentation profile, required flag,
documentation contract, renderer and export metadata.

`corpus_id` hashes every field except itself. Every referenced object id is part
of the index hash and must resolve exactly once to independently verified bytes.
Changing `structured` to `full` over the same frozen evidence keeps
`structured_content_id` stable while the contract-specific corpus/export
envelope may change. A full renderer must name that exact structured content id.

`source_bindings` closes portability. Every required source ref used by the
index, generation entries, snapshots or claims must resolve through this map to
exactly one included corpus object, unless it is a declared public schema ref.
A digest without the bounded record whose content it identifies is not a
portable proof and makes the relevant product partial or invalid.

The index is a closed inventory at one ledger head. It cannot inventory its own
future export receipt or a root-completion event causally dependent on that
receipt.

## 8. Pure Assembly Procedure

```text
1. validate documentation contract and frozen lineage identity
2. validate one exact bounded ledger head
3. collect eligible immutable snapshots and terminal records
4. verify schema, hash, ancestry, generation and bounds for every source
5. derive one generation entry per Packet life
6. verify accepted-generation and stage references
7. derive omissions, redactions, economics and available completion summary
8. canonicalize each corpus object
9. build one closed corpus index
10. build source_bindings and verify every required ref resolves exactly once
11. reject recursive or causally future inventory
12. return detached objects/index with no side effect
```

The assembler reads evidence; it does not write software acceptance, QA verdict,
generation death, documentation policy or root completion.

## 9. Packet, Corpus And Delivery Ordering

Normal required-documentation chain:

```text
Packet terminal + software lineage assessment
  -> frozen corpus candidate
  -> structured export transaction
  -> verified export receipt
  -> documentation completion assessment
  -> final root completion event
  -> root delivery envelope
```

The boundary prevents recursive identity:

```text
corpus does not contain its own receipt
corpus does not contain the final event that depends on its receipt
delivery envelope names corpus + receipt + final root-completion ref
delivery envelope does not contain itself
```

For optional documentation, root completion may predate export because the
receipt is not a root requirement. A later corpus revision may then include the
already-existing completion event without a cycle.

## 10. Export Capability

The export hand is separate from repository hands.

```lua
{
  kind = "proc17_documentation_export_capability",
  protocol_version = "documentation.export_capability.v0",
  capability_id = string,
  session_id = string,
  lineage_id = string,
  root_identity = table,
  allowed_operations = { create = true, read_back = true },
  allowed_prefixes = string[],
  max_files = integer,
  max_bytes = integer,
  grant_revision = integer,
  expires_at = number | nil,
}
```

Public serialized records may contain `capability_id` and root-identity digest
only. The private provider, descriptor/closure/token and resolved host path are
never serializable.

Required checks before every effect:

```text
capability active and unexpired
session/lineage identity exact
root identity unchanged
operation create/read_back only
relative path canonical and under allowed prefix
no absolute, dot, parent or empty component
no symlink/non-regular root, parent or target
transaction file/byte caps not exceeded
candidate repository capability rejected by kind and owner
```

No generic shell or filesystem authority is exposed.

## 11. Export Storage Shape

Crystallized relative shape under one trusted session root:

```text
lineages/<lineage-id>/corpus/
  objects/<sha256>.json
  exports/<export-id>/
    corpus-index.json
    00_chaos/
    01_table/
    02_crystall/
    03_manifest/
    export-receipt.json
```

The capability resolver owns the trusted absolute root. All module-facing paths
are relative. Validated/sanitized session and lineage ids are never interpreted
as path fragments before validation.

Object behavior:

| Existing target | Requested bytes | Result |
|---|---|---|
| absent | valid canonical bytes | create, read back, verify |
| regular file with exact bytes/digest | exact request | idempotent success |
| existing mismatched bytes under same identity | any | loud integrity failure |
| symlink/non-regular target or parent | any | deny |
| changed root identity | any | invalidate capability |

## 12. Export API And Transaction

```lua
local export = require("runtime.documentation_export")

export.prepare(verified_corpus, documentation_contract, projection_bundle)
  -> export_plan | nil, err

export.execute(export_plan, private_capability, provider)
  -> verified_receipt | nil, err

export.verify(receipt, private_capability, provider)
  -> true | nil, err
```

`projection_bundle` is already rendered, bounded and source-linked in memory.
The filesystem executor never invokes a renderer or substrate.

Transaction order:

```text
1. verify corpus and contract again
2. verify the pre-rendered projection bundle and its source closure
3. derive exact completion/omission state
4. derive every intended pre-receipt path/digest and export_id
5. validate capability/root and total bounds
6. create/reuse exact content-addressed objects
7. create/reuse exact export files while transaction is unadvertised
8. independently read back and verify every pre-receipt file
9. write and read back one receipt file
10. seal the export revision in lineage evidence
```

Rendering precedes the first filesystem effect because `export_id` depends on
rendered digests. A failed full renderer yields a bounded partial projection
bundle: the exact structured files remain exportable, omissions remain visible,
and a required full contract remains unsatisfied.

A failed storage transaction may leave exact create-only files, but without a
verified receipt the revision is not complete or externally advertised. Retry
may reuse only byte-identical verified files. Any mismatch is loud.

## 13. Export Identity And Receipt

```text
export_id = SHA-256(
  corpus_id
  + requested profile
  + render protocol version
  + ordered intended pre-receipt paths/digests
)
```

```lua
{
  kind = "proc17_documentation_export_receipt",
  protocol_version = "documentation.export_receipt.v0",
  receipt_id = "documentation-receipt:<sha256>",
  export_id = string,
  corpus_id = string,
  lineage_id = string,
  ledger_head_ref = string,
  profile_requested = string,
  profile_delivered = "structured" | "full",
  completion_state = "complete" | "partial",
  render_protocol_version = string,
  destination_root_id = string,
  file_receipts = {
    { relative_path = string, digest = string, bytes = integer },
  },
  object_count = integer,
  total_bytes = integer,
  omissions = table,
  redactions = table,
  economics_ref = string,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

`receipt_id` hashes every field except itself. `file_receipts` inventories all
files created and verified before the receipt; it excludes the receipt file to
avoid self-reference. The provider still reads the receipt file back after
writing it. `object_count` and `total_bytes` describe the same pre-receipt
inventory.

Changing only a human rendering leaves `corpus_id` stable and changes
`export_id`. Repeating the same renderer over the same corpus is idempotent.

## 14. Human Projection

`full` is a projection over a verified structured corpus, never an independent
truth source.

```lua
{
  protocol_version = "documentation.projection_bundle.v0",
  corpus_id = string,
  structured_content_id = string,
  profile_requested = "structured" | "full",
  state = "complete" | "partial",
  render_protocol_version = string,
  files = {
    {
      relative_path = string,
      bytes = string,
      digest = string,
      source_object_refs = string[],
    },
  },
  omissions = table,
  redactions = table,
  cost_event_refs = string[],
}
```

The renderer receives a bounded verified public corpus view and returns bytes;
it receives no storage or repository capability. The bundle validator checks
digests, refs, bounds, forbidden data and profile completeness before
`export.prepare` may calculate an export id.

Each rendered file or sidecar names:

```text
export id and corpus id
source object ids
render protocol version
completeness
truth-status summary
redaction/omission refs
```

Deterministic sections use no substrate. Optional bounded substrate narration,
if later promoted, may explain only existing source-linked claims and receives
no repository/export capability.

The renderer cannot:

```text
add runtime-confirmed facts
hide failed generations
change accepted-generation identity
claim omitted evidence was checked
write outside the private export transaction
```

For `full + required`, missing declared human projection means documentation is
incomplete. The structured export remains valid evidence but does not satisfy
the root contract. In that case the receipt records
`profile_requested=full`, `profile_delivered=structured` and
`completion_state=partial` with exact omissions.

## 15. Root Delivery Envelope

```lua
{
  kind = "proc17_lineage_delivery",
  protocol_version = "lineage.delivery.v0",
  delivery_id = "lineage-delivery:<sha256>",
  lineage_id = string,
  root_completion_ref = string,
  accepted_generation = integer | nil,
  accepted_candidate_ref = string | nil,
  corpus_id = string | nil,
  export_receipt_id = string | nil,
  documentation_state = string,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

Only the lineage delivery/report layer derives this envelope from already
committed facts. `delivery_id` hashes every field except itself. The envelope
is not inserted retroactively into the corpus it references.

## 16. Cold Reader

```lua
local reader = require("runtime.documentation_reader")

reader.open(index_bytes, object_resolver, public_schemas, bounds)
  -> verified_view | nil, err

reader.inspect(verified_view)
  -> cold_report
```

With no private session state and no Markdown trust, a cold reader must verify:

```text
root request/process/documentation contracts
profile and completeness
stage/generation sequence
accepted generation and candidate digest, if any
QA verdict binding to exact candidate seals
failed ancestors and inherited constraints
truth/applicability status per claim
missing/truncated/redacted inventory
cumulative reported economics
completion state available at the corpus head
```

The reader resolves original Packet/trace/ledger refs only through the closed
`source_bindings` map. It never reaches back into the source session as an
implicit dependency.

Unknown schema versions, missing objects and hash mismatches prevent verified
interpretation. They do not trigger best-effort semantic guessing.

## 17. New-Task Reentry

Portable corpus reentry is a future, separate authority after cold-reader proof.

```lua
{
  kind = "proc17_corpus_ingress_carrier",
  protocol_version = "documentation.corpus_ingress.v0",
  carrier_id = "corpus-ingress:<sha256>",
  source_corpus_id = string,
  source_lineage_id = string,
  target_session_id = string,
  target_lineage_id = string,
  selected_object_refs = string[],
  bounded_summary = table,
  payload_bytes = integer,
  source_refs = string[],
  content_truth_statuses = string[],
  applicability_truth_status = "corpus_reentry_proposal",
}
```

Carrier construction requires:

```text
verified corpus/index/object closure
explicit new-task ingestion contract
fresh target session/lineage identity
bounded selected object set
no private capabilities/handles/host paths
preserved content truth statuses
new applicability status for this task
```

The carrier verifier delegates the exact protocol/class/status tuple to
`runtime.applicability`; this protocol admits only
`corpus_reentry_proposal`. Unknown tokens and statuses belonging to grave or
lineage carriers are rejected.

`NETWORK@▽` may later materialize this bounded payload as source CHAOS for a
fresh Packet. No old Packet id, field, CALM, runtime state, loss, budget wallet
or repository authority crosses.

Prior completion remains a fact about the source lineage and cannot complete
the new root task.

## 18. Persistent Resume Is Not Reentry

Resuming the same lineage after process restart would require transactional
recovery of:

```text
exact ledger head
remaining cumulative budget
continuation rights
private capability lifecycle
uncommitted transaction state
```

The corpus deliberately does not contain these powers. Persistent same-lineage
resume is forbidden in v0 and requires a separate threat model and crystall.

## 19. Retention Boundary

Initial explicit bounds:

```text
max generations per lineage
max snapshots per generation/layer
max object bytes
max export files/bytes
max trace/source expansion
```

Before a separately tested compost law exists:

```text
record exact truncation/omission
stop optional retention at the bound
never silently delete or rewrite old evidence
required corpus may become incomplete
```

Future compaction must preserve the evidence required for accepted-result
verification, rejected-generation QA/terminal-manifest provenance, economics,
security audit and
generation-learning curves. Every compacted record needs a named reader and a
visible compaction event.

## 20. Writer And Reader Contract

| Record | Sole writer | First named reader | Effect reader |
|---|---|---|---|
| Packet manifest | △ | corpse/lineage completion | corpus assembler |
| verified layer snapshot | lineage-side recorder | corpus assembler | cold reader/renderer |
| generation entry | pure corpus derivation committed by lineage | corpus verifier | external reader/reentry selector |
| corpus index | pure assembler | corpus verifier | export/reader/reentry |
| private export grant | trusted host/session | capability resolver | export provider |
| file receipt | provider + independent read-back | export transaction | receipt builder |
| export receipt | verified export transaction | documentation completion | delivery/report |
| root delivery envelope | lineage delivery layer | CLI/TUI/API | external consumer |
| reentry selection | explicit new-task contract | carrier builder | NETWORK@▽ verifier |
| ingress carrier | deterministic carrier builder | NETWORK@▽ | fresh Packet birth |

No stored record lacks a named reader. No reader may rewrite its source.

## 21. Failure Law

| Failure | Class | Required behavior |
|---|---|---|
| malformed trusted lineage record | world/invariant failure | loud; no corpus |
| optional snapshot missing | known incompleteness | partial export |
| required snapshot missing | documentation requirement failure | root incomplete |
| object/index hash mismatch | integrity failure | reject |
| recursive inventory | causal identity failure | reject |
| export capability denied | typed effect failure | no write; profile policy applies |
| provider escapes root | security invariant failure | loud; reject implementation |
| provider/read-back mismatch | effect integrity failure | no receipt |
| renderer fails after structured corpus derivation | projection failure | structured export remains possible; full partial |
| reentry source incomplete | typed ingestion outcome | no verified carrier |
| unknown schema | compatibility outcome | refuse verified reading |
| bound exhausted | typed truncation | explicit omission; no silent deletion |

Lua/host faults remain harness faults and are never laundered into Packet death.

## 22. Permanent Controls

Assembly and identity:

```text
A0 same frozen head assembled twice -> same corpus id
A1 one new snapshot -> new corpus id; old corpus unchanged
A2 mutated object bytes -> verification failure
A3 missing source ref -> partial/invalid, never complete
A4 Packet manifest naming a future generation -> reject
A5 equal semantic text in different generations -> identities remain distinct
A6 renderer disabled/changed -> structured corpus unchanged
A7 optional renderer failure -> structured survives, full partial
A8 required renderer failure -> exact root documentation requirement missing
A9 existing exact object -> idempotent success
A10 same object id with different bytes -> loud conflict
A11 required receipt precedes final root completion
A12 corpus inventorying own receipt/future final event -> reject
```

Generation and authority:

```text
G0 plan-only lineage has no accepted build generation
G1 plan stage + accepted build preserve both stages
G2 rejected generation keeps manifest, QA verdict and bounded rejected-check projection
G3 recovery generation gets fresh Packet/repository ids
G4 later acceptance does not erase failed ancestor
G5 inherited repository grant is impossible/denied
G6 same carrier in two lineages yields distinct identities
G7 exhausted lineage cannot fabricate a child entry
G8 deleted source repo leaves verified digests, not fake readable files
G9 active generation yields partial ancestor corpus only and no root delivery
```

Storage and reentry:

```text
P0 valid absent target -> create/read-back/verify
P1 absolute/dot/parent path -> reject before effect
P2 symlink root/parent/target -> deny
P3 changed root identity -> invalidate capability
P4 file/byte cap -> explicit partial/failure; no extra write
P5 private handle/secret in public object -> reject or typed redaction
P6 candidate repository capability as export grant -> reject
P7 post-receipt write -> new export revision required
P8 claimed write/read-back mismatch -> no receipt
R0 valid bounded corpus -> eligible new-task carrier
R1 tampered/missing object -> no verified carrier
R2 old Packet/lineage identity cannot become target identity
R3 old completion cannot complete new task
R4 private capability cannot cross JSON/carrier
R5 Markdown without structured corpus is not verified ingress
R6 reentry disabled leaves fresh-task behavior identical
```

Security controls must run against the native provider on the supported host,
including symlink and root-substitution races, before filesystem authority is
promoted.

## 23. Implementation Sequence

```text
C0 pure object/index schemas and canonical identity
C1 in-memory derivation from one fixed grown lineage
C2 independent cold reader over in-memory bytes
C3 observer snapshots -> in-memory corpus assembly
C4 off/structured ablation proves zero Packet effect
C5 private export capability with deny-by-default policy
C6 create-only native provider and hostile path tests
C7 structured export + independent read-back + receipt
C8 required/optional completion ordering and delivery envelope
C9 deterministic Markdown projection
C10 bounded new-task carrier, still disabled by default
C11 NETWORK@▽ reentry experiment into a fresh lineage
C12 retention/compost only through a new TABLE/CRYSTALL campaign
```

Each capability step is promoted separately. A green pure assembler does not
authorize filesystem writes; a green exporter does not authorize reentry.

## 24. Promotion Gates

### 24.1 In-Memory Corpus

```text
all objects/indexes deterministic and independently verified
generation/acceptance identities exact
all required source refs resolve inside the portable closure
missing evidence remains explicit
recursive inventory rejected
every snapshot class has a reader
Packet observer ablation exact
```

### 24.2 Filesystem Export

```text
separate deny-by-default capability
no candidate repository grant reuse
relative-path/root/symlink controls green on native provider
create-only idempotence and mismatch failure proven
read-back precedes receipt
documentation costs lineage-scoped
```

### 24.3 New-Task Reentry

```text
cold reader verifies the complete selected closure
carrier bounded and capability-free
target identity fresh
truth/applicability statuses preserved
old completion cannot complete new task
reentry-off ablation exact
```

## 25. Deferred

```text
persistent same-lineage resume
remote/cloud publication
mutable latest indexes
cryptographic author signatures
automatic cross-session memory
semantic retrieval over all corpora
substrate-authored structured truth
`qa-check.v0` schema and QA execution authority
post-seal candidate documentation edits
compost/aggregation
router authority from documentation
```

The first executable proof is deliberately smaller than this full contract:
explicit `structured`, one in-memory lineage, observer-only snapshots, pure
corpus assembly, zero narration, zero filesystem write and zero reentry.
