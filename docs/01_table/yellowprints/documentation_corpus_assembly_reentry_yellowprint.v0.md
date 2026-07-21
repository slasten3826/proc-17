# Documentation Corpus Assembly, Storage And Reentry Yellowprint v0

Status:

```text
table
date: 2026-07-20
source chaos:
  docs/00_chaos/self_documenting_lineage_corpus_notes_2026-07-20.md
  docs/00_chaos/nested_work_layer_runtime_integration_2026-07-20.md
scope:
  lineage ownership
  immutable corpus assembly
  storage and capability boundary
  generation history
  retention/compost pressure
  cold-machine and NETWORK@▽ reentry
production code change authorized: no
crystallization authorized: yes / completed by the sibling blueprint after the
  2026-07-21 cross-table audit
router authority change authorized: no
amended 2026-07-21: F6 canonical candidate-seal identity and terminal-generation corpus law
audit source: docs/00_chaos/fable_preimplementation_crystall_audit_raw_2026-07-21.md
F4 amendment: standalone failure crystal removed; rejected-generation evidence
  is preserved through QA records and the terminal Packet manifest
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
```

Sibling tables:

```text
documentation_profiles_economy_yellowprint.v0.md
documentation_layer_snapshots_truth_yellowprint.v0.md
nested_work_layer_derivation_yellowprint.v0.md
completion_scope_candidate_seal_yellowprint.v0.md
stage_transition_generation_recovery_yellowprint.v0.md
```

## 0. Table Decision

The complete documentation corpus belongs to the root-task lineage, not to one
mortal Packet and not to one generated repository.

The assembly boundary has two levels:

```text
Packet △
  -> assembles one bounded Packet/stage/generation manifest

lineage corpus assembler
  -> reads verified Packet manifests, corpses, snapshots and lineage ledger
  -> assembles one portable root-task corpus export
```

The lineage assembler is outside the ProcessLang topology like the lineage
runner. It is not a twelfth organ and cannot route a living Packet.

The portable corpus uses immutable content-addressed objects and create-only
export revisions. A mutable `latest.md` or rewritten history is not required.

## 1. Fixed Decisions

```text
C0  root-task lineage owns the complete corpus
C1  one Packet owns only its living state and bounded terminal manifest
C2  Packet △ remains the Packet-local assembler
C3  cross-generation corpus assembly occurs after verified lineage events
C4  corpus assembly is not an operator and has no routing authority
C5  every corpus object is immutable and content-addressed
C6  every export revision is create-only and independently verifiable
C7  no private capability, provider handle or live Packet identity is exported
C8  lineage archive is the default destination
C9  generated candidate repository is a separate authority/root
C10 product documentation enters a candidate only as a predeclared create-once artifact; the complete corpus stays lineage-side
C11 failed and accepted generations retain distinct identities
C12 structured corpus is the portable machine carrier
C13 Markdown is a projection and cannot be the sole reentry source
C14 reentry always births a fresh Packet through NETWORK@▽ or a new root input
C15 old Packet identity and writable authority never cross reentry
C16 corpus integrity hash proves bytes/structure, not semantic correctness or authorship
C17 absence/truncation/redaction remains visible in the corpus index
C18 no compaction occurs before a retention contract and ablation exist
C19 v0 storage is bounded at birth to prevent accidental immortal growth
C20 every writer, object and export status has a named reader
C21 an export revision is unsealed while creating absent declared files and immutable after its verified receipt
```

## 2. Scope Matrix

| Surface | v0 table decision | Deferred |
|---|---|---|
| Ownership | one session-scoped root lineage | cross-session shared library |
| Corpus objects | immutable canonical structured records | database/index service |
| Export revisions | create-only directories/objects | mutable aliases |
| Packet manifest | existing △ boundary extended by exact refs later | rich presentation |
| Root corpus assembly | lineage-side deterministic assembler | distributed assembly |
| Human projection | bounded Markdown from structured source | web/TUI replay |
| Storage authority | separate documentation export grant | remote publishing |
| Candidate placement | explicit pre-seal artifact only | post-build injection forbidden |
| Reentry | verified bounded corpus as new input | persistent same-Packet resume |
| Retention | explicit caps, no silent deletion | tested compost/aggregation |
| Signing | hashes/digests only | cryptographic author signatures |

## 3. Ownership Hierarchy

```text
session
  -> lineage
       -> root process contract
       -> stages
       -> generations
            -> Packet identity
            -> candidate repository identity
            -> snapshots
            -> terminal manifest/corpse
       -> corpus objects
       -> export revisions
```

Ownership rules:

| Object | Owner | May outlive Packet | May cross generation |
|---|---|---:|---:|
| living field/CALM/runtime state | Packet | no | no |
| Packet trace snapshot/corpse | lineage evidence | yes | by bounded ref only |
| stage manifest | lineage stage | yes | through typed stage carrier/ref |
| candidate repository | one build generation | yes as immutable evidence | files never as active child state |
| rejected-generation terminal manifest projection | source Packet manifest/corpse plus lineage | yes | through bounded recovery carrier |
| corpus layer snapshot | lineage | yes | yes as historical evidence |
| root corpus export | lineage | yes | portable external artifact |
| private grant/provider handle | trusted host/session | bounded | never exported/inherited |

## 4. Candidate Storage Shape

```text
sessions/<session-id>/
  lineages/<lineage-id>/
    corpus/
      objects/
        <sha256>.json
      exports/
        <export-id>/
          corpus-index.json
          00_chaos/
          01_table/
          02_crystall/
          03_manifest/
          export-receipt.json
```

Generation evidence may live in an existing session/lineage store and be
referenced by digest rather than duplicated:

```text
generations/<generation>/...
```

This is a shape candidate, not a committed path contract.

Path laws:

```text
session and lineage ids are validated/sanitized before path construction
all stored paths are relative to one trusted session root
no absolute path, dot component, parent traversal or symlink escape
object filename must equal canonical content digest
export directory is absent before creation
existing export/object with mismatched bytes is a loud integrity conflict
```

## 5. Immutable Object Store

Candidate object envelope:

```lua
{
  kind = "proc17_corpus_object",
  protocol_version = "documentation.corpus_object.v0",
  object_id = sha256,
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

Identity:

```text
object_id = SHA-256(canonical encoding of every field except object_id)
```

Store behavior:

| Existing state | Requested bytes | Result |
|---|---|---|
| object absent | valid bytes/hash | create once, read back, verify |
| object exists | exact same bytes/hash | idempotent reference, no rewrite |
| object exists | different bytes under same id | loud integrity failure |
| target symlink/non-regular | any | deny |
| parent/root identity changed | any | invalidate grant/deny |

Content addressing provides integrity and idempotence. It does not prove that a
semantic proposal is true or that a trusted author created it.

## 6. Corpus Index

Candidate index:

```lua
{
  kind = "proc17_documentation_corpus",
  protocol_version = "documentation.corpus.v0",
  corpus_id = sha256,
  structured_content_id = sha256,
  lineage_id = string,
  session_id = string,
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
    ["original-source-ref"] = string,
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

`structured_content_id` hashes the profile-neutral evidence closure: generation
entries, layer object ids, redaction objects, omission inventory and source
identities. This lets `full` prove that it projects the exact structured content
also available under `structured`; profile/required/contract/export metadata is
not part of this inner identity.

`corpus_id` hashes the canonical index excluding itself. Referenced object ids
are part of the hash; object bytes are verified independently.

Every required Packet/trace/ledger source ref used by exported claims must
resolve through `source_bindings` to exactly one included corpus object, unless
it is a declared public schema ref. A digest without the bounded source record
is not a portable proof.

The index is a closed inventory for one export revision. New evidence creates a
new corpus/export id rather than mutating the old index.

## 7. Generation Corpus Entry

Candidate entry:

```lua
{
  generation = integer,
  packet_id = string,
  parent_corpse_id = string | nil,
  ingress_carrier_id = string | nil,
  stage_id = string,
  work_mode = "plan" | "build",
  candidate_repository_id = string | nil,
  candidate_digest = sha256 | nil,
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
one generation entry names one Packet life in the linear v0 lineage
one generation entry requires the exact terminal event and registered corpse
an active living generation is never represented by a fabricated terminal entry
accepted_generation points to exactly one verified accepted build generation
failed candidate digest never appears as accepted output
rejected Packet manifest embeds the exact bounded seal/verdict/check projection
child generation may cite that terminal projection but receives a new repository identity
```

Plan stage generations with no repository candidate retain nil candidate fields.

A corpus may be assembled at a ledger head with an active generation only as an
explicitly partial historical corpus. It includes terminal ancestor generation
entries, records the active generation in the omission/completeness inventory,
and cannot satisfy required full documentation or root delivery. A complete
corpus head requires every included generation to be terminal and corpse-bound.

## 8. Packet And Lineage Manifest Boundary

Packet `△` remains responsible for the facts available inside one mortal life:

```text
typed Packet result
Packet-local structured output
residue
truth statuses
source refs
current economics/loss
terminal event and death
```

It must not pretend to know future descendants.

The lineage assembler acts only after the lineage runner has appended the
required Packet-terminal and task/stage assessment events. It can then assemble:

```text
all verified ancestor generation records
all accepted stage outputs
all rejected generation failures
cumulative economics
lineage status at the frozen ledger head
software/stage/root completion assessment available at that head
```

Therefore:

```text
Packet manifest != root lineage corpus
root lineage corpus contains Packet manifests by verified reference
```

Required documentation introduces an ordering boundary:

```text
Packet terminal and software assessment
  -> corpus candidate/export
  -> verified export receipt
  -> documentation completion assessment
  -> final root completion event
  -> outer delivery envelope names completion + corpus + receipt
```

Optional documentation may be exported after a lineage is already complete.

The corpus cannot contain its own export receipt or the final event that depends
on that receipt without a recursive identity cycle. The outer delivery envelope
is the exact boundary that closes this chain; it is not hidden self-reference.

## 9. Assembly Transaction

Candidate deterministic order:

```text
1. validate documentation contract and current lineage identity
2. freeze one bounded lineage ledger head for this export attempt
3. collect eligible immutable snapshots and terminal records by source ref
4. verify every object schema, hash, ancestry and bound
5. derive generation entries and accepted-generation identity
6. derive omission/redaction/economy/completion summaries
7. build canonical structured objects and corpus index in memory
8. validate that every index ref resolves exactly once
9. render and validate bounded human projections in memory when profile is full
10. derive the exact intended file inventory/digests and export id
11. resolve a private documentation export grant
12. create content-addressed objects and export revision under the grant
13. independently read back and verify every written digest
14. create and read back one immutable export receipt
15. append one lineage documentation-export event/status
```

Rendering precedes the first filesystem effect because `export_id` includes the
rendered file digests. If full rendering fails, the transaction may still form
a bounded structured export plus a visibly partial full result. It does not
rewrite the structured index as complete-full.

For `profile=full, required=true`, that partial full export cannot satisfy the
documentation contract or root delivery. Optional human rendering is expressed
as a required structured profile plus a separate optional full export, not by
weakening a required full profile after failure.

## 10. Export Receipt

Candidate receipt:

```lua
{
  kind = "proc17_documentation_export_receipt",
  protocol_version = "documentation.export_receipt.v0",
  receipt_id = sha256,
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
    { relative_path = string, digest = sha256, bytes = integer }
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

The receipt confirms the export effect and read-back. It does not upgrade the
truth statuses of the exported content.

`file_receipts` inventories every export file created before the receipt and
does not include the receipt file itself. The receipt identity hashes every
field except `receipt_id`.

An export revision may create each declared absent file while its transaction
is open. It is not advertised as complete until the verified receipt exists.
After that receipt, the revision is sealed; additional material requires a new
export id and directory.

Candidate export identity law:

```text
export_id = SHA-256(
  corpus_id
  + profile_requested
  + render_protocol_version
  + canonical ordered intended file paths/digests excluding the receipt
)
```

Changing only human rendering leaves `corpus_id` stable and changes
`export_id`. Repeating the same renderer over the same corpus produces the same
export id and may reuse only exact verified files.

## 10A. Root Delivery Envelope

The non-recursive final delivery projection may be derived after root completion:

```lua
{
  kind = "proc17_lineage_delivery",
  protocol_version = "lineage.delivery.v0",
  delivery_id = sha256,
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

The envelope is a final response/report projection over already committed
records. It is not required to contain itself and is not counted as a missing
file inside the corpus it references. `delivery_id` hashes every field except
itself.

## 11. Documentation Export Capability

Lineage-side export requires a separate private grant.

Candidate grant scope:

```text
session id
lineage id
documentation root identity
allowed operation: create corpus object/export file
allowed relative prefixes
maximum files/bytes
expiry/revocation revision
```

It must not reuse the candidate repository grant because:

```text
the roots have different owners
the candidate is immutable after seal
documentation may continue after candidate QA
compromise of the renderer must not grant source-code mutation
```

The public corpus contains only a projection of the grant identity if needed
for audit. Private handles, tokens, file descriptors and provider closures never
enter an object or carrier.

## 12. Candidate Repository Placement

Default and only canonical corpus placement in v0:

```text
documentation placement = lineage_archive
candidate repository contains only declared product artifacts
```

Explicit product documentation:

```text
root contract names exact documentation artifacts before build
their content is formed before materialization
create-only repository hand writes them with the rest of the fresh candidate
candidate seal includes their digests
QA validates the sealed set
lineage exporter never patches them later
```

Those files may project pre-seal chaos/table/crystall material, but they are not
the complete self-documenting lineage corpus. Final QA evidence, failed/accepted
generation history, export receipt and final completion occur after the seal.
They remain in the external corpus/delivery envelope or require a new whole
product generation if the product contract truly demands their inclusion.

`placement = candidate_repository` is therefore rejected as a corpus option in
v0. Candidate documentation is specified through the normal artifact contract.

## 13. Human Projection Assembly

Full profile directories are projections over one verified corpus index:

```text
00_chaos/
01_table/
02_crystall/
03_manifest/
```

Every rendered file requires a projection header or machine sidecar containing:

```text
export id
corpus id
source object ids
profile/render version
completeness state
truth-status summary
redaction/omission refs
```

Deterministic sections should be rendered without substrate calls. A bounded
substrate may explain semantic relations, but its output is linked as a
projection claim and validated for refs, size and forbidden data.

No renderer may:

```text
add a new runtime-confirmed claim
remove a failed generation from the history
change accepted generation identity
claim omitted evidence was checked
write outside the export grant
```

## 14. Cold Reader Contract

A human or machine with only the structured corpus and declared public schemas
must be able to establish:

```text
the root request digest and process contract
the documentation profile and completeness
the stage/generation sequence
which candidate, if any, was accepted
which exact candidate digest each QA verdict covered
which ancestors failed and what constraints were inherited
which claims are semantic, estimated, inherited or runtime-confirmed
which records are missing, truncated or redacted
the cumulative reported economics
the final root completion state
```

The reader need not trust explanatory Markdown to establish those facts.

## 15. Corpus Reentry Classes

Two future uses must remain distinct.

### New Task Ingestion

```text
old corpus is an external bounded source
new session/lineage receives a new root request
corpus enters through user/source ingress or NETWORK@▽ adapter
old lineage id is provenance, not current identity
all applicability is evaluated again
```

### Persistent Lineage Resume

```text
same lineage continuation after process restart
requires transactional persistent lineage authority
must recover exact ledger head, budget and continuation rights
```

Persistent resume is not implemented or authorized by this table. A portable
documentation corpus alone is insufficient to resume the same live lineage.

## 16. Reentry Carrier

Candidate new-task carrier:

```lua
{
  kind = "proc17_corpus_ingress_carrier",
  protocol_version = "documentation.corpus_ingress.v0",
  carrier_id = sha256,
  source_corpus_id = sha256,
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

Verification must check:

```text
corpus/index/object hashes
schema versions
bounds and selected object closure
no private capabilities or host handles
source lineage consistency
target identity freshness
payload size
truth/applicability statuses preserved
```

`corpus_reentry_proposal` is admitted only by the closed applicability
vocabulary in the stage-transition table. Unknown or mismatched status tokens
make the carrier invalid; they are never accepted as generic proposals.

`NETWORK@▽` materializes a new Packet prompt/options from the verified bounded
payload. No old Packet field, CALM, runtime state, loss counter, budget wallet,
repository grant or Packet id crosses the boundary.

## 17. Reentry Truth Law

Examples:

| Prior corpus fact | At new-task ingress |
|---|---|
| generation 2 candidate digest was H | prior runtime-confirmed fact about source lineage |
| generation 2 passed test contract Q | prior runtime-confirmed fact scoped to H and Q |
| blueprint recommends architecture A | preserved semantic/document status |
| rejected-generation manifest records failure B | prior exact fact plus new applicability proposal |
| prior root was complete | does not complete the new root task |
| prior private grant existed | not transported |

The new Packet may use the corpus as pressure or semantic material only through
normal body contracts. Reentry is not resurrection.

## 18. Retention And Compost Pressure

Unbounded corpus retention would reintroduce immortality through documentation.

v0 prevention:

```text
max generations per lineage
max snapshots per generation/layer
max object bytes
max export files/bytes
max trace-tail/source expansion
```

When a bound is reached before a compaction law exists:

```text
record explicit truncation/omission
stop accepting additional optional export material
do not silently delete existing evidence
required corpus may become incomplete
```

Future compost may transform old individual records into aggregates only after
tests establish which evidence must survive for:

```text
accepted-result reproducibility
rejected-generation QA and terminal-manifest provenance
economics
security audit
generation-learning curves
```

Compacted statistics belong to foundation/lineage memory only if they gain a
named reader. The documentation corpus must retain a visible compaction event
and the digests/categories of what no longer exists.

## 19. Writer And Reader Matrix

| Record | Writer | First named reader | Effect reader |
|---|---|---|---|
| Packet manifest | △ | completion/corpse/lineage runner | corpus assembler |
| layer snapshot object | snapshot recorder | corpus assembler | structured reader/renderer |
| generation corpus entry | corpus assembler from lineage ledger | corpus validator | external reader/reentry selector |
| corpus index | corpus assembler | export validator | renderer/cold reader/reentry verifier |
| export grant | trusted session host | capability resolver | corpus storage provider |
| file/object receipt | storage provider + independent verifier | export transaction | export receipt builder |
| export receipt | corpus assembler after verification | documentation status/completion | CLI/TUI/external auditor |
| root delivery envelope | lineage delivery/report layer | CLI/TUI/API | external human/machine |
| reentry selection | explicit new-task contract | corpus carrier builder | NETWORK@▽ verifier |
| corpus ingress carrier | deterministic carrier builder | NETWORK@▽ | fresh Packet birth |
| compaction event | future retention authority | corpus reader/foundation reader | audit/report |

No record depends solely on an unnamed future reader.

## 20. Assembly Matched Controls

| ID | One changed variable | Required result |
|---|---|---|
| A0 | same ledger head and objects assembled twice | same corpus id; no object rewrite |
| A1 | one new snapshot after prior export | new corpus/export id; old export unchanged |
| A2 | object bytes mutate after id calculation | verification failure |
| A3 | one source ref missing | corpus partial/invalid per requirement; never complete |
| A4 | Packet manifest claims future generation | ancestry validation rejects |
| A5 | failed and accepted candidates have same semantic text | generation/repository ids remain distinct |
| A6 | renderer disabled | structured corpus unchanged |
| A7 | renderer output changes | corpus id unchanged; projection/export id changes as designed |
| A8 | optional full renderer fails | structured export survives; full status partial |
| A9 | required renderer fails | exact required docs failure; software evidence unchanged |
| A10 | existing object exact bytes | idempotent success/no rewrite |
| A11 | existing object mismatched bytes | loud integrity conflict |
| A12 | required corpus export succeeds | receipt precedes root completion event |
| A13 | corpus claims to contain its own receipt/final dependent event | reject recursive inventory |

## 21. Generation Controls

| ID | Grown life | Required result |
|---|---|---|
| G0 | one accepted plan Packet only | stage manifest; no accepted build generation |
| G1 | plan stage then accepted build generation | both stages linked; build accepted |
| G2 | build generation 1 QA rejected | failed manifest embeds exact seal/verdict/check projection |
| G3 | generation 2 born from G2 | new Packet/repository ids; terminal projection preserved by carrier ref/copy |
| G4 | generation 2 accepted | accepted_generation=2; generation 1 remains failed |
| G5 | child attempts to inherit parent repository grant | denied/not representable |
| G6 | same plan carrier across two test lineages | distinct lineage/generation identities |
| G7 | lineage budget exhausted before child | no generation entry fabricated |
| G8 | candidate repo deleted after verified corpus export | corpus retains digests/evidence, not fake readable files |
| G9 | corpus requested while current generation is alive | partial ancestor corpus only; active generation omitted explicitly; no root delivery |

## 22. Storage And Capability Controls

| ID | Condition | Required result |
|---|---|---|
| P0 | valid absent object/export path | create, read back, verify |
| P1 | absolute/parent/dot path | reject before effect |
| P2 | symlink in root/parent/target | deny, no outside write |
| P3 | export root identity changed | grant invalidated |
| P4 | file/object count exceeds bound | explicit partial/failure; no extra write |
| P5 | bytes exceed bound | explicit partial/failure; no unbounded file |
| P6 | renderer includes private grant/provider handle | export validation rejects/redacts per contract |
| P7 | renderer includes synthetic secret | redaction recorded, secret absent |
| P8 | candidate repository passed as lineage export root | scope mismatch denied |
| P9 | write attempted after export receipt | new export revision required, old unchanged |
| P10 | provider claims write but read-back differs | rejected export effect |
| P11 | malformed receipt/schema | loud invariant failure |

Real filesystem controls should reuse the repository-hand discipline: unique
test-owned roots, native provider where available, independent read-back and no
cleanup outside created identities.

## 23. Reentry Controls

| ID | One changed variable | Required result |
|---|---|---|
| R0 | valid bounded corpus | fresh root/Packet input candidate |
| R1 | corpus index hash tampered | no carrier/birth |
| R2 | referenced object missing | no complete carrier; typed incomplete source |
| R3 | selected object closure exceeds bound | carrier too large/bounded rejection |
| R4 | private capability inserted | reject before NETWORK ingress |
| R5 | old Packet id offered as target id | fresh identity replaces/rejects caller value |
| R6 | old root completion present | new task remains unassessed |
| R7 | rejected-generation terminal projection present | applicability to the new task remains proposal |
| R8 | Markdown only, no structured corpus | not accepted as verified corpus carrier |
| R9 | same corpus ingested by cold different substrate | body identities/contracts equivalent; semantics may differ |
| R10 | corpus reentry disabled | normal fresh task behavior unchanged |

## 24. False-Green Matrix

| False green | Rejecting rule/control |
|---|---|
| one Packet document called whole lineage history | two-level assembly law |
| root corpus assembled before lineage terminal event | assembly ordering |
| mutable latest index called append-only | C5/C6 + A0/A1/P9 |
| required lineage marked complete before corpus receipt | assembly ordering + A12 |
| corpus inventory claims its own receipt | self-reference boundary + A13 |
| content hash treated as author signature | C16 |
| renderer has candidate repository authority | C9-C11 + P8 |
| failed candidate omitted from learning history | G2-G4 |
| accepted QA applied to wrong generation | generation entry identity + G4 |
| corpus resumes same lineage by itself | reentry class separation |
| prior root complete makes new task complete | R6 |
| old capability crosses through JSON | C7/C15 + R4 |
| Markdown accepted as machine truth source | C12/C13 + R8 |
| silent deletion called compost | C18 + retention law |
| write failure hidden behind in-memory index | export receipt/read-back controls |

## 25. Failure Classification

| Failure | Classification | Consequence |
|---|---|---|
| malformed lineage/Packet trusted record | world/invariant failure | loud; no corpus fabrication |
| missing optional snapshot | known export incompleteness | partial structured/full export |
| missing required snapshot | required documentation failure | root incomplete per profile table |
| hash/schema mismatch | integrity failure | reject object/index/carrier |
| storage capability denied | typed export effect failure | no write; optional/required policy applies |
| provider escapes root | security invariant failure | loud; implementation rejected |
| renderer failure after structured corpus derivation | projection failure | structured export remains possible, full partial |
| reentry source incomplete | typed ingestion outcome | no false verified carrier |
| corpus exceeds retention bound | known truncation pressure | explicit omission; no silent deletion |
| unknown schema version | compatibility/epistemic outcome | refuse verified interpretation |

Lua errors and malformed trusted receipts remain harness/world failures. They are
not turned into pretty corpus residue.

## 26. Shadow-First Implementation Sequence

The eventual implementation should be split into independently falsifiable
increments:

```text
I0 in-memory pure corpus derivation from fixed grown fixtures
I1 observer captures immutable snapshots, writes nowhere
I2 observer ablation proves no Packet effect
I3 lineage in-memory object/index assembly
I4 create-only session-scoped structured export with native provider
I5 independent read-back and export receipt
I6 cold deterministic structured reader
I7 bounded corpus reentry into a fresh task fixture
I8 deterministic Markdown projections
I9 optional bounded substrate narration
I10 retention/compost only after a separate table/crystall campaign
```

No step promotes documentation into router authority.

## 27. Non-Goals

This table does not authorize:

```text
persistent lineage resume
remote/cloud publication
cryptographic identity/signatures
mutable corpus updates
post-seal candidate documentation edits
general filesystem or shell access
`qa-check.v0` schema or QA execution authority
semantic retrieval over all past corpora
automatic cross-session memory
compost implementation
```

It also does not decide the prose style of generated documents.

## 28. Crystallization Gate

The three documentation tables may crystallize only after a cross-table audit
confirms:

```text
profile completion terms name exact corpus products
snapshot objects satisfy the corpus identity/schema needs
all costs have one physical charge and one causal scope
Packet △ and lineage assembler powers do not overlap ambiguously
required export receipt and final completion avoid recursive self-inclusion
candidate and lineage export roots are capability-separated
optional failure cannot relabel software evidence
required failure produces an exact missing requirement
reentry preserves truth status and creates fresh identity
every stored record has a named reader
```

Gate result, 2026-07-21:

```text
profile, snapshot, corpus, Packet manifest and lineage delivery scopes agree
rejected generations use QA records plus the terminal Packet manifest
no failure-crystal object kind or authority surface remains
qa-check.v0 remains explicitly deferred with QA execution
cross-table crystallization gate satisfied
production implementation authority remains limited by each blueprint
```

The first production slice remains deliberately narrow:

```text
explicit structured profile
one in-memory lineage
one bounded already-supported plan/build fixture
observer-only snapshots
lineage-side structured export
no narration
no reentry authority
no router change
```
