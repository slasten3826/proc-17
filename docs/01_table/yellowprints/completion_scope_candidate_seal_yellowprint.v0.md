# Completion Scope And Candidate Seal Yellowprint v0

Status:

```text
table / yellowprint
documentation authority only
no runtime authority
no manifest gate changed
no QA capability granted
prepared for shadow completion inspection
amended 2026-07-21: F1 generation key, F2 seal order, F3 context identity,
  F5 generation rejection separated from stage status, F6 canonical ids,
  F4 standalone failure crystal removed in favor of a rejected-generation
  terminal manifest projection
audit source: docs/00_chaos/fable_preimplementation_crystall_audit_raw_2026-07-21.md
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
amended 2026-07-22: step 8.4 detailed declaration, root-lifecycle and seal
  transaction physics moved into three specialized TABLE contracts; this file
  retains completion-scope, QA and root-composition authority
specialized TABLE gate: cross-table audit required before CRYSTALL amendment
```

Date:

```text
2026-07-20
```

Primary chaos source:

[`../../00_chaos/nested_work_layer_runtime_integration_2026-07-20.md`](../../00_chaos/nested_work_layer_runtime_integration_2026-07-20.md)

Companion tables:

```text
nested_work_layer_derivation_yellowprint.v0.md
stage_transition_generation_recovery_yellowprint.v0.md
documentation_profiles_economy_yellowprint.v0.md
documentation_layer_snapshots_truth_yellowprint.v0.md
documentation_corpus_assembly_reentry_yellowprint.v0.md
artifact_set_derivation_yellowprint.v0.md
repository_candidate_lifecycle_yellowprint.v0.md
candidate_seal_transaction_yellowprint.v0.md
```

Current lower-level authority:

```text
capability_safe_repository_hands_yellowprint.v0.md
post_collapse_plan_delivery_yellowprint.v0.md
lineage_completion_continuation_separation_yellowprint.v0.md
```

## 0. Table Decision

`complete` is not one boolean.

The software process must distinguish at least:

```text
work item complete
artifact set complete
candidate sealed
stage complete
software accepted
root delivery complete
```

Each larger scope requires exact evidence from the smaller scopes plus its own
named evidence. No scope may be inferred from a label belonging to another.

Canonical candidate law:

```text
A build candidate is mutable only through declared create-once materialization.
Seal ends all source-write authority for that generation.
QA observes the sealed candidate.
Rejected QA never reopens it.
```

## 1. Why The Current Result Is Too Strongly Named

Current `runtime/repository_result.lua` proves a valuable fact:

```text
one current repository.create_text_file.v0 work unit
  -> authorized exact action
  -> attempt
  -> create receipt
  -> independent exact read-back
  -> accepted LOGIC validation
  -> ☱ work completion
  -> repository.result.v0
```

Its v0 resolver also explicitly requires:

```text
needed_count = 1
done_count = 1
remaining_count = 0
```

Within that one-artifact contract, `status = complete` is honest.

It does not prove:

```text
the whole software candidate contract was declared
all candidate artifacts were materialized
source-write authority was closed
required QA was executed
QA accepted the exact sealed bytes
root process requirements were satisfied
required canonical documentation was exported
```

Therefore the current result is retained as artifact evidence and reclassified
by future readers. It is not deleted or silently reinterpreted as root success.

## 2. Completion Scope Lattice

| Scope | Exact question | Minimal positive evidence | Does it complete the root task? |
|---|---|---|---:|
| `none` | Has any declared unit completed? | no | no |
| `work_item` | Is one exact work-unit version complete? | `runtime.work_completion.v0` | no |
| `artifact_set` | Are all artifacts in one current declared candidate set complete? | exact set contract + every current work completion | no |
| `candidate_sealed` | Is that exact artifact set immutable and independently identifiable? | seal receipt + capability closure + artifact digests | no |
| `stage` | Did the lineage verify that the current process stage satisfied its stage contract? | exact Packet terminal candidate + corpse + lineage stage assessment | no by itself |
| `software_accepted` | Did the lineage verify required QA for the exact sealed candidate under the root software contract? | accepted QA verdict bound to seal + Packet corpse + lineage software assessment | yes for software, not necessarily for required corpus export |
| `root_delivery` | Is the outward root contract, including required documentation, complete? | software acceptance + required docs completion + export receipt | yes |

The scopes are monotonic as historical facts but not interchangeable as current
authority. A rejected QA verdict does not erase that a candidate was sealed; it
changes the current generation/stage/root assessment.

Generation terminality is an orthogonal lifecycle fact, not a higher completion
scope. A rejected generation can reach a lawful `▲` death/recovery boundary
while the build stage and root task remain unfinished.

## 3. Scope Ownership

| Fact | Writer | Truth source | Named readers |
|---|---|---|---|
| work-item completion | ☱ body event | exact effect/verification/validation chain | body progress, artifact-set inspector |
| artifact-set declaration | pure body derivation over birth + one exact current formation/choice | contract status preserved | artifact-set inspector, seal planner |
| artifact-set completion | pure scope inspector | body-owned work completions | seal readiness, layer inspector |
| capability closure | trusted repository registry/provider | runtime effect | seal verifier, QA grant resolver |
| candidate seal | dedicated body writer after trusted closure receipt | runtime-confirmed act | QA, completion, lineage, corpus |
| QA attempt/result | future bounded QA capability + ☶/☱ | runtime evidence | final QA verdict assembly, stage/root completion, rejected-generation terminal projection |
| stage completion | lineage runner after exact stage assessment | mixed exact Packet/corpse evidence with preserved statuses | root completion, transition selector, corpus |
| software acceptance | lineage runner after exact root software assessment | accepted QA bound to seal + exact terminal Packet/corpse | docs assembler, final completion |
| documentation completion | lineage corpus/export contracts | immutable snapshots and receipt | final root completion |
| root delivery completion | lineage delivery assembler | all required exact refs | MANIFEST/delivery envelope |

No substrate output is listed as an authority writer. It may propose artifact
content, tests, explanations and failure interpretations while retaining
`semantic_proposal` content status.

## 4. Pure Completion Inspection

Conceptual API:

```lua
completion_scope.inspect(subject, contract_view) -> inspection | nil, err
```

`contract_view` is a verified immutable projection containing both the
`process_contract_id` and semantic `context`. Caller-provided strings have no
authority unless they match the Packet birth or lineage ledger contract.

`subject` is an exact read-only Packet/corpse view for Packet-local scopes or an
exact lineage-ledger view for stage/root scopes. One call may not silently join
an arbitrary live Packet table to unrelated lineage state.

Candidate envelope:

```lua
{
  protocol_version = "runtime.completion_scope_inspection.v0",
  inspection_id = "completion-scope:<digest>",

  subject_kind = "packet" | "corpse" | "lineage",
  packet_id = "packet:..." | nil,
  lineage_id = "lineage:..." | nil,
  generation = 2 | nil,
  stage_id = "stage:<lineage_id>:2:build" | nil,
  process_contract_id = "software.create.v0",
  context = "software_task.v0",

  highest_scope = "work_item" | "artifact_set" | "candidate_sealed"
    | "stage" | "software_accepted" | "root_delivery" | "none",

  work_items = {
    needed_count = 3,
    done_count = 3,
    remaining_count = 0,
    done_refs = {"work-completion:..."},
    missing_ids = {},
  },

  artifact_set = {
    state = "complete" | "incomplete" | "unsupported",
    contract_ref = "artifact-set-contract:..." | nil,
    artifact_refs = {"artifact:..."},
  },

  generation_state = {
    state = "active" | "terminal_candidate" | "terminal_incomplete"
      | "accepted_history" | "rejected_history" | "unsupported",
    terminal_ref = "corpse:..." | nil,
    rejected_generation_manifest_ref = "packet-manifest:..." | nil,
  },

  candidate = {
    state = "unsealed" | "sealed" | "qa_rejection_observed"
      | "qa_accepted" | "qa_rejected" | "unsupported",
    candidate_seal_id = "candidate-seal:..." | nil,
    candidate_seal_event_ref = "trace:..." | nil,
    qa_verdict_ref = "qa-verdict:..." | nil,
  },

  boundary_candidate = {
    state = "none" | "plan_stage_ready" | "software_acceptance_ready"
      | "rejected_generation_recovery_ready",
    terminalized = false | true,
    terminal_ref = "corpse:..." | nil,
    source_refs = {},
  },

  stage = {
    state = "active" | "complete" | "suspended" | "unsupported",
    completion_ref = "stage-completion:..." | nil,
  },

  root = {
    software_state = "unfinished" | "accepted" | "rejected" | "unsupported",
    documentation_state = "disabled" | "incomplete" | "partial" | "complete"
      | "blocked" | "unsupported",
    delivery_state = "unfinished" | "complete" | "unsupported",
  },

  source_refs = {},
  relevant_object_versions = {},
  missing_requirements = {},
  conflicting_refs = {},
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "semantic_proposal" | "mixed",
}
```

`unsupported` is an inspection/reader outcome, never a
`boundary_candidate.state`. When a named reader is absent, the candidate stays
`none` and the relevant component reports `unsupported` with an exact missing
requirement.

The inspector is read-only. It may not create the seal, QA verdict, stage
completion or documentation receipt that it is inspecting.

Subject ceiling:

| Subject | Highest scope it may derive |
|---|---|
| living Packet | current work item, artifact set and candidate seal; local QA may derive a boundary candidate but not a larger scope |
| frozen Packet/corpse plus exact terminal refs | the same Packet-local scope plus an exact terminal boundary candidate |
| verified lineage ledger view | stage, software acceptance and root delivery |

A boundary candidate is not a completion scope. `terminalized=false` says that
the living Packet is ready to enter △; `terminalized=true` says that an exact
manifest/corpse now binds the same evidence for a lineage decision. Neither
makes that decision. A Packet-local reader cannot claim `stage`,
`software_accepted` or `root_delivery` merely because it sees an accepted
artifact or QA verdict. A lineage reader must cite the exact Packet/corpse/seal/
QA and documentation refs from which the larger scope is composed.

For `subject_kind=packet|corpse`, `stage.state=complete` and
`root.software_state=accepted` are forbidden outputs; the inspector reports the
typed `boundary_candidate` instead. `accepted_history`, `rejected_history`,
stage completion and root acceptance are available only to a verified lineage
subject.

## 5. Declared Artifact Set

Step 8.4 amendment:

```text
artifact_set_derivation_yellowprint.v0.md owns the normative derivation gate,
formation/choice provenance and target schema amendments. The abbreviated
shape below remains the completion-scope view and must not be used to authorize
a caller-supplied member list.
```

An artifact set is not "whatever files happen to exist when budget ends".

The current generation needs one bounded declaration:

```lua
{
  protocol_version = "repository.artifact_set_contract.v0",
  artifact_set_id = "artifact-set:<digest>",
  packet_id = "packet:...",
  lineage_id = "lineage:...",
  generation = 2,
  stage_id = "stage:<lineage_id>:2:build",
  repository_id = "repo:lineage:gen2",
  artifacts = {
    {
      work_unit_id = "work:main-py",
      work_unit_version = 1,
      relative_path = "main.py",
      expected_kind = "regular_file",
    },
  },
  source_refs = {"plan-result:...", "field-formation:..."},
  event_truth_status = "runtime_confirmed",
  content_truth_status = "semantic_proposal" | "mixed",
}
```

The body confirms the declaration act and its exact shape. It does not thereby
confirm that the semantic artifact list is sufficient for the user's task.
That sufficiency is tested by QA and the process contract.

Artifact-set invariants:

```text
one current lineage/stage/generation/repository identity
unique relative paths
unique work-unit identities
bounded artifact count and aggregate bytes
no absolute paths
no parent traversal
no undeclared artifact can satisfy the set
no stale work-unit version can satisfy the set
```

## 6. Candidate Materialization State

`repository_candidate_lifecycle_yellowprint.v0.md` owns root claim, lifecycle
birth, pre-claim G5 compatibility and terminal root-lock mechanics. The state
names below are completion-facing projections, not a second mutable lifecycle.

| State | Allowed source-tree authority | Exit condition |
|---|---|---|
| `forming` | create each declared absent path once | exact current artifact set complete |
| `seal_pending` | no new action may be committed while seal transaction resolves | closure receipt accepted or typed failure |
| `sealed` | no source writes | QA verdict or terminal death |
| `qa_accepted` | no source writes | accepted stage/root accounting |
| `qa_rejection_observed` | no source writes | one final immutable QA verdict |
| `qa_rejected` | no source writes | rejected-generation terminal manifest, death and possible fresh generation |
| `terminal` | no mutation of Packet or candidate | lineage reads corpse/seal/verdict |

There is no state named:

```text
reopen
repairing
patching
accepted_with_unverified_changes
```

## 7. Candidate Seal Contract

The seal is both an immutable evidence record and a real authority boundary.
A hash without capability closure is not a seal.

Conceptual record:

```lua
{
  protocol_version = "repository.candidate_seal.v0",
  candidate_seal_id = "candidate-seal:<digest>",

  packet_id = "packet:...",
  lineage_id = "lineage:...",
  generation = 2,
  stage_id = "stage:<lineage_id>:2:build",
  repository_id = "repo:lineage:gen2",
  root_fingerprint = "repository-root:...",
  artifact_set_id = "artifact-set:...",

  artifacts = {
    {
      relative_path = "main.py",
      work_unit_id = "work:main-py",
      work_unit_version = 1,
      bytes = 1234,
      sha256 = "...",
      completion_ref = "work-completion:...",
      verification_ref = "repository-verification:...",
    },
  },

  inventory_ref = "repository-seal-inventory:...",
  inventory_digest = "...",

  materialization_grant_id = "grant:...",
  materialization_grant_revision_before = 4,
  sealed_grant_revision = 5,
  authority_closure_ref = "candidate-seal-receipt:...",
  source_refs = {},

  event_truth_status = "runtime_confirmed",
  content_truth_status = "mixed",
}
```

`content_truth_status = mixed` is expected when artifact bytes originated as
semantic proposals but their exact observed bytes, hashes and closure act are
runtime-confirmed. The record must preserve per-field provenance rather than
pretend all content became runtime truth.

## 8. Seal Transaction

The seal transaction must execute in this causal order:

```text
1. inspect exact current artifact-set completion and construct the seal request
2. verify source refs, object versions, root identity and zero active dispatches
3. trusted registry atomically enters seal_pending for the exact generation/repository
4. the lifecycle revision invalidates future dispatch and every unconsumed old lease
5. trusted provider revalidates root identity and takes the final bounded no-follow inventory
6. require inventory to match the declared artifact/directory contract
7. registry commits seal_pending -> sealed against that exact inventory digest
8. provider/registry returns immutable closure receipt and sealed root fingerprint
9. body verifies the receipt and appends candidate_seal with exact refs
10. future capability resolution sees source-write authority as closed
```

Rules:

```text
seal request failure before seal_pending -> typed no-effect failure; lifecycle remains active
failure after seal_pending -> active only when registry proves no commit/no
  in-flight dispatch and provider independently proves root continuity;
  otherwise quarantine
closure succeeds but receipt is malformed -> loud harness/world invariant failure; never reopen ambiguously
closure receipt accepted but body cannot append trusted evidence -> loud runtime failure; sealed remains sealed
repeat exact seal -> idempotent observation of same seal, never a new authority transition
seal with changed root/artifact -> rejected
```

No source-write authority exists between the final inventory and committed
closure. This ordering supersedes the pre-crystall inventory-first sketch and
matches `docs/02_crystall/blueprints/candidate_seal.v0.md` §1.

The normative transaction schemas, exact-tree inventory, idempotence and
failure matrix now live in
`candidate_seal_transaction_yellowprint.v0.md`. The existing CRYSTALL remains
unchanged until the specialized TABLE cross-audit is accepted.

The inventory must be bounded and must reject symlinks, special files, path
escapes and undeclared source artifacts. Fresh-root allocation plus create-only
effects narrows the problem but does not replace the final observation: a seal
must describe the world that exists, not merely the writes the body remembers.

Multi-file candidates may require a separately declared directory skeleton or
a future create-directory hand. Directory creation is materialization authority
and must be covered by the same artifact-set contract and post-seal closure.

The table does not prescribe the final host API name. Crystall must decide
whether this extends `repository_capability` or introduces a narrowly scoped
candidate-lifecycle registry.

## 9. Post-Seal Enforcement

The seal closes all source-tree mutations, including operations not yet
implemented.

| Attempt after seal | Required outcome |
|---|---|
| recreate existing path | denied before provider write |
| create a new absent path | denied before provider write |
| replace exact file | capability does not exist; denied |
| delete or rename | capability does not exist; denied |
| mint another materialization grant for same generation/repository | denied by lifecycle registry |
| use stale pre-seal lease | denied by grant revision/state |
| pass seal id as if it were a grant | no authority |
| QA read exact sealed files | permitted only through separate bounded read-only QA authority |
| QA write scratch output outside candidate source tree | separate future contract only |

This closes a gap left by create-no-replace alone: without the seal, a caller
could still create another absent path after QA began.

The QA sandbox should expose the sealed candidate read-only and direct caches,
temporary files and test outputs into a distinct bounded scratch root. Runtime
artifacts such as language bytecode caches must not silently mutate the sealed
candidate tree.

## 10. QA Contract Boundary

QA is a body capability, not a substrate role.

Required causal chain:

```text
current candidate seal
  -> declared bounded QA contract
  -> authorized QA attempt
  -> runtime receipt (exit/timeout/bounded output/digests/cost)
  -> exact validation
  -> immutable accepted or rejected verdict
```

Candidate verdict shape:

```lua
{
  protocol_version = "qa.candidate_verdict.v0",
  verdict_id = "qa-verdict:<digest>",
  lineage_id = "lineage:...",
  generation = 2,
  stage_id = "stage:<lineage_id>:2:build",
  candidate_seal_id = "candidate-seal:...",
  qa_contract_id = "qa-contract:...",
  verdict = "accepted" | "rejected",
  required_checks = 9,
  accepted_checks = 9,
  rejected_checks = 0,
  check_refs = {"qa-check:..."},
  runtime_cost = {},
  source_refs = {},
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "mixed",
}
```

The substrate may propose a QA contract. The host/process contract decides
whether that proposal becomes an authorized bounded contract. The substrate
cannot mint execution permission or its own accepted verdict.

The exact QA hand and threat model are deferred. This table defines what its
result must prove.

## 11. QA Verdict Semantics

| Evidence | Candidate state | Stage/root consequence |
|---|---|---|
| no seal | QA unavailable | candidate still forming |
| seal, no QA receipt | `sealed` | build checking; root unfinished |
| all required checks accepted | `qa_accepted` | software acceptance candidate |
| any current required check rejected, final verdict absent | `qa_rejection_observed` | final rejected-verdict assembly required |
| final rejected verdict bound to current seal/checks | `qa_rejected` | rejected-generation terminal candidate |
| optional check rejected only | contract-defined; no implicit acceptance | exact policy reader decides |
| timeout | rejected or typed incomplete according to declared contract | never accepted by prose |
| malformed provider response | invariant/harness failure | not Packet rejection and not acceptance |
| QA refs target another seal | invalid evidence | no state change |

QA cannot mutate the sealed source tree. A test that changes source bytes makes
the capability contract fail; it does not create a new candidate version.

## 12. Rejected Candidate Boundary

Rejected QA creates an exact failure fact, not repair authority.

Required sequence:

```text
one or more current required QA checks rejected
  -> build ◈ assembles one final verdict from exact refs
  -> final rejected QA verdict bound to exact seal/contract/checks
  -> build ▲ rejected-generation terminal candidate
  -> △ embeds a bounded rejected-generation projection in the Packet manifest
  -> immutable corpse
  -> lineage completion assessment: root unfinished/recoverable if intrinsic cause permits
  -> optional paid recovery carrier
  -> fresh Packet and fresh repository identity
```

The rejected-generation terminal projection must contain:

```text
current lineage/generation/Packet/stage/repository identities
current candidate seal id
current QA contract id and final rejected verdict ref
all rejected check identities
bounded mechanical exit/timeout/output facts required by the QA contract
exact source refs and preserved truth statuses
completeness or bounded omission status
```

It may not contain a writable handle, live lease, host path, semantic repair
instruction or any authority that reopens the rejected repository. Semantic
diagnosis belongs to a later descendant substrate call and remains
`semantic_proposal`.

The projection is a member of the terminal Packet manifest, not a separate
runtime object. Corpse capture preserves the full manifest; `trace_tail` is
diagnostic and cannot be the only storage for check evidence needed after
death.

## 13. Plan Stage Completion

Plan mode uses the established exact chain:

```text
plan delivery candidate
  -> ☱ plan completion assessment
  -> plan.result.v0
  -> Packet-local manifest/corpse
  -> lineage stage completion assessment
  -> stage completion
```

Under `plan.only.v0`, that stage may also satisfy the root contract.

Under `software.create.v0`, exact plan stage completion means:

```text
stage complete = true
root software accepted = false
next lawful action = lineage stage-transition assessment
```

The same plan result can therefore be stage-terminal without being root-terminal.
The process contract, not the plan content, owns this distinction.

## 14. Build Stage Completion

Build stage outcomes:

| Outcome | Stage state | Root software state | Continuation class |
|---|---|---|---|
| candidate not sealed | active | unfinished | same Packet while affordable, or recovery after honest death |
| sealed, QA pending | active/checking | unfinished | same Packet first hypothesis |
| QA accepted, Packet still living | active / acceptance candidate | unfinished | Packet terminal manifest/corpse |
| QA accepted + exact corpse + lineage assessment | complete | accepted | documentation/final delivery boundary |
| rejected check evidence, final verdict absent | active/crystallizing verdict | unfinished current generation | no transition yet |
| final rejected verdict, Packet still living | active / rejected terminal candidate | rejected current generation | Packet terminal manifest/corpse |
| rejected-generation manifest + corpse + lineage generation assessment | rejected generation complete as history | root unfinished | build-generation recovery |
| budget/loss death before verdict | terminal incomplete | unfinished | intrinsic recovery assessment |

"Rejected generation complete as history" means its terminal accounting is
complete. It does not mean the software stage or root task succeeded.

## 15. Root Completion Composition

For the primary process contract:

```text
software.create.v0
```

The living build Packet can produce a software-acceptance candidate from:

```text
exact current build stage
exact current candidate seal
exact accepted required QA verdict bound to that seal
boundary_candidate.terminalized = false
```

△ then binds those exact refs into the Packet-local terminal manifest/corpse and
re-derives the candidate with `terminalized=true` and `terminal_ref=corpse_id`.

The lineage can then derive software acceptance only from:

```text
the exact terminalized software-acceptance candidate and verified corpse
no newer active/rejected generation superseding the verdict
root software contract satisfied
one lineage-owned software assessment event with all source refs
```

Final root delivery requires software acceptance plus documentation policy:

| Documentation profile | Additional requirement |
|---|---|
| `off` | no canonical corpus export required |
| `structured` optional | software may deliver; corpus can be a separate optional export |
| `structured` required | structured corpus completion + export receipt |
| `full` optional | software may deliver; full corpus is separately reported |
| `full` required | complete structured corpus + complete declared human projection + full export receipt |

The canonical corpus is assembled lineage-side after software acceptance. It
cannot be placed inside the already sealed candidate source tree.

Therefore the outer causal boundary is:

```text
software acceptance
  -> lineage corpus assembly/export when required
  -> documentation completion
  -> root delivery completion
  -> final outward delivery envelope
```

## 16. Manifest Permission Matrix

| Evidence available | Packet-local artifact manifest | stage manifest | final root delivery |
|---|---:|---:|---:|
| one work item complete | diagnostic/artifact result only | no | no |
| artifact set complete | candidate materialization report | no | no |
| candidate sealed | sealed-candidate report | no | no |
| exact plan result, Packet still living | plan-stage candidate | no | no |
| exact plan corpse + lineage stage assessment | all exact refs | yes | only for `plan.only.v0` after lineage root assessment |
| build QA accepted, Packet still living | software-acceptance candidate | no | no |
| accepted build corpse + lineage software assessment | all exact refs | yes | yes if docs are not required |
| final build QA rejection, Packet still living | rejected-generation terminal candidate | no | no |
| rejected build corpse + lineage generation assessment | all exact refs | rejected boundary | no |
| required docs pending | accepted software may be reported internally | stage complete | no |
| required docs receipt + lineage root assessment exact | all exact refs | yes | yes |

The existing repository manifest remains temporarily authoritative during
shadow migration. The future scope observer must record its disagreement:

```text
legacy terminal says complete
scope observer says artifact_set/candidate_sealed at most; QA missing
```

## 17. Completion And Economics Separation

Completion facts do not depend on affordability.

Matched law:

```text
same sealed candidate + same QA verdict
  with lineage budget available   -> same completion assessment; continuation/delivery affordable
  with lineage budget exhausted   -> same completion assessment; continuation/delivery may be denied
```

A wallet cannot turn `qa_accepted` into rejected or `qa_rejected` into accepted.
It can prevent a new Packet, QA attempt, corpus export or final delivery action
from being paid.

This preserves the existing separation between intrinsic task state and
lineage economics.

## 18. Truth Matrix

| Claim | Truth status |
|---|---|
| exact bytes/hash observed | runtime_confirmed |
| materialization capability closed | runtime_confirmed |
| candidate seal event appended | runtime_confirmed |
| artifact semantics are correct | semantic_proposal until tested by declared evidence; may remain mixed |
| QA command/check executed | runtime_confirmed |
| check interpretation | runtime_confirmed for mechanical predicate; semantic_proposal/mixed for model interpretation |
| QA verdict under exact contract | runtime_confirmed |
| rejected-generation terminal projection | runtime_confirmed assembly over preserved seal/verdict/check statuses |
| descendant semantic diagnosis of prior rejection | semantic_proposal with inherited exact source refs |
| stage/root completion derivation | runtime_confirmed act over preserved source statuses |
| required corpus exported | runtime_confirmed receipt |

Manifestation, sealing and inheritance never upgrade semantic content merely by
transporting it.

## 19. Failure Classification

| Failure | Class | Packet/world consequence |
|---|---|---|
| artifact missing or rejected read-back | task/effect evidence | Packet continues or dies honestly |
| no matching materialization grant | typed capability exclusion | no provider write |
| artifact set ambiguous | task-contract unsupported | no seal |
| seal precondition absent | not ready | no seal transition |
| seal provider denies closure | typed effect failure | no false seal |
| malformed closure receipt | harness/world invariant failure | runner fails loudly |
| post-seal source write attempt | denied capability action | candidate remains sealed |
| QA required but capability absent | typed missing capability | root unfinished |
| QA check rejects | task evidence | final verdict assembly; no acceptance |
| malformed QA provider response | harness/world invariant failure | runner fails loudly |
| conflicting current verdicts | body invariant failure | no completion |
| documentation export unavailable when required | typed stage/root incompletion | software acceptance preserved; final delivery pending |

The body must distinguish a task rejection from broken Lua/host physics. It may
not turn an invariant error into a beautiful Packet death.

## 20. Named Reader / Writer Matrix

| Record | Writer | Named readers |
|---|---|---|
| artifact-set contract | process/stage formation path | progress, seal readiness, documentation snapshots |
| work completion | ☱ dedicated body writer | progress, scope inspector, seal verifier |
| seal request | body action planner | trusted capability registry/provider |
| closure receipt | trusted provider/registry | seal verifier only |
| candidate seal | dedicated body writer | QA resolver, scope inspector, lineage, corpus |
| QA attempt/receipt | future QA hand | validator and budget accounting |
| QA check record | future bounded QA hand + body verifier | final QA verdict assembler |
| QA verdict | dedicated QA body writer | scope inspector, △ terminal manifest assembler, lineage |
| rejected-generation terminal projection | △ manifest assembler | corpse, completion reader, recovery carrier, corpus |
| software acceptance | lineage root completion reader | docs assembler, delivery assembler |
| documentation receipt | corpus exporter | final root completion |
| scope inspection | pure inspector/optional trace observer | layer projection, corpus, TUI, promotion corpus |

There is no storage surface in this table without a named reader.

## 21. Permanent Control Matrix

### Artifact-set controls

| ID | Control | Expected |
|---|---|---|
| C01 | one of three declared units incomplete | artifact set incomplete |
| C02 | all three exact current completions | artifact set complete |
| C03 | completion for old unit version | does not satisfy current set |
| C04 | undeclared extra file exists | does not satisfy or expand set |
| C05 | duplicate path/work id in declaration | contract rejected |
| C06 | substrate says set is complete | no authority delta |

### Seal controls

| ID | Control | Expected |
|---|---|---|
| C07 | complete set + valid closure | one seal |
| C08 | repeat exact seal | same seal/idempotent, no second transition |
| C09 | incomplete set | no seal request |
| C10 | root fingerprint changes before closure | seal rejected |
| C11 | stale work completion | seal rejected |
| C12 | mutate returned seal | stored evidence unchanged |
| C13 | create existing path after seal | denied |
| C14 | create new absent path after seal | denied |
| C15 | replay pre-seal lease | denied by state/revision |
| C16 | mint second write grant for sealed generation | denied |
| C16a | undeclared path/symlink/special file appears in seal inventory | seal rejected |
| C16b | declared nested directory absent or unaccounted | seal rejected |

### QA controls

| ID | Control | Expected |
|---|---|---|
| C17 | no seal | no QA capability/action |
| C18 | QA verdict references another seal | ignored/rejected |
| C19 | all required checks exact accepted | software acceptance candidate |
| C20 | one required check rejected, final verdict absent | rejection observed; build `◈`; no terminal candidate |
| C20a | final rejected verdict binds exact seal and every required check | rejected candidate; build `▲` terminal candidate |
| C21 | timeout hidden by substrate summary | mechanical timeout remains non-accepted |
| C22 | QA modifies source tree | capability/invariant failure; no accepted verdict |
| C23 | malformed provider output | loud harness failure, not Packet death |

### Scope controls

| ID | Control | Expected |
|---|---|---|
| C24 | current one-file repository result | work-item/artifact-set only; not root |
| C25 | plan result + corpse + lineage assessment under `plan.only.v0` | stage and root complete |
| C26 | same exact terminal plan evidence under `software.create.v0` | stage complete, root unfinished |
| C27 | accepted QA without Packet corpse/lineage assessment | software-acceptance candidate only; no stage/root completion |
| C28 | accepted build corpse + lineage assessment, docs off | software accepted; root delivery may complete |
| C29 | accepted build corpse + lineage assessment, required docs pending | software accepted, root delivery incomplete |
| C29a | accepted build corpse + lineage assessment + required docs receipt | root delivery complete |
| C30 | same corpse, wallet available/exhausted | identical intrinsic completion scope |

### Generation controls

| ID | Control | Expected |
|---|---|---|
| C31 | accepted QA from generation N attached to N+1 | no acceptance |
| C32 | rejected N, fresh N+1 | N seal remains historical; N+1 begins unsealed |
| C33 | fresh N+1 shares old repository identity | invariant failure |
| C34 | descendant semantic diagnosis proposes exact patch to N | no mutation authority over N |

## 22. Shadow Migration

Migration order:

```text
1. implement pure artifact-set/scope inspection over current evidence
2. classify current repository.result.v0 as artifact evidence
3. append optional shadow scope observations
4. prove observer ablation
5. grow false-green corpus from current live software tasks
6. implement candidate-seal transaction behind an explicit disabled-by-default capability
7. prove post-seal denial controls before any QA hand exists
8. design and attack the first read-only QA capability
9. grow accepted/rejected candidate lives
10. promote root completion gate only after matched corpus is green
```

No step removes the current manifestation path before its replacement has
evidence and rollback.

## 23. Promotion Gates

| Gate | Requirement |
|---|---|
| E0 | exact scope schemas crystallized |
| E1 | current artifact completion preserved |
| E2 | scope observer ablation exact |
| E3 | one vs many artifact-set controls green |
| E4 | seal closes every materialization path, including new absent paths |
| E5 | stale grants/leases cannot cross seal |
| E6 | QA threat model and bounded capability complete |
| E7 | accepted/rejected QA matched pairs green |
| E8 | root gate separates software acceptance from required corpus completion |
| E9 | old-generation/cross-seal evidence denied |
| E10 | invariant failures remain loud host/runtime failures |

Only E0-E3 are needed for a shadow completion observer. E4-E10 are required
before replacing the current root manifestation authority.

## 24. Explicit Deferrals

This table does not yet authorize:

```text
general shell execution
arbitrary test commands
networked QA
`qa-check.v0` schema, writer and hostile-input contract
same-candidate repair
replace/delete/rename hands
automatic cleanup of failed repositories
semantic selection of required QA
persistent lineage resume
root manifest gate replacement
```

## 25. Table Thesis

```text
A file can be complete while a candidate is unfinished.
A candidate can be sealed while QA is absent.
A generation can be rejected while its history is complete.
Software can be accepted while required delivery documentation is pending.

Only exact scope composition may say that the root task is complete.
```
