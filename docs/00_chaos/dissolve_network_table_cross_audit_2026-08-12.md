# DISSOLVE / NETWORK TABLE Cross-Audit

Status:

```text
layer: CHAOS audit evidence over TABLE treatment
date: 2026-08-12
scope: first production-grown DISSOLVE path only
result: TABLE contracts internally coherent after precision amendments
crystallization readiness: ready
runtime implementation authorized by this record: no
router/full-tree promotion authorized: no
```

Audited documents:

```text
docs/01_table/yellowprints/qa_rejected_lineage_recovery_yellowprint.v0.md
docs/01_table/yellowprints/network_rejected_form_materialization_yellowprint.v0.md
docs/01_table/yellowprints/qualified_dissolve_inherited_form_yellowprint.v0.md
docs/01_table/yellowprints/lineage_completion_continuation_separation_yellowprint.v0.md
docs/01_table/yellowprints/blocked_lineage_yellowprint.v0.md
```

Runtime surfaces were read as current-state evidence, not as authority over the
new contracts:

```text
runtime/completion.lua
runtime/carrier.lua
runtime/lineage.lua
runtime/lineage_runner.lua
runtime/network_ingress.lua
runtime/packet_birth.lua
core/packet.lua
organs/flow.lua
runtime/qualified_pressure.lua
runtime/pressure_action.lua
organs/dissolve.lua
runtime/field.lua
runtime/upper_coverage.lua
organs/observe.lua
```

## 1. Question

Can the first real DISSOLVE treatment be implemented without:

```text
letting grave grant QA recovery
copying the entire ancestor carrier into child semantics
turning historical rejection into a current child verdict
inventing a harness-only rigidity reason
erasing the rejected generation
creating a second mutable truth registry
or changing ordinary budget/stall recovery behavior
```

Answer after the amendments below: yes.

## 2. Selected End-To-End Chain

```text
real contained QA check rejects sealed candidate
-> deterministic QA verdict rejects candidate
-> △ writes exact rejected-generation terminal projection
-> Packet dies blocked and corpse freezes the full QA envelope
-> software.create.v0 completion derives unfinished/recoverable/qa_rejected
-> lineage appends completion_evaluated
-> carrier is built and verified from that corpse + assessment
-> pure NETWORK projector derives current work + inherited rejected form
-> continuation_decided binds carrier + projection + assessment
-> NETWORK revalidates the selected tuple
-> fresh child Packet and fresh repository are born
-> FLOW materializes current work + one live inherited rejected form
-> qualified pressure emits one blocking DISSOLVE need
-> Tree commits E02, ▽ -> ☷
-> ☷ atomically releases applicability and creates bounded residue
-> changed exact versions emit one compatible upper observation need
-> Tree commits ☷ -> ☴
-> semantic OBSERVE reads current work + bounded residue once
```

The child receives the ancestor failure as bounded history and an applicability
hypothesis. It does not inherit the ancestor artifact, repository, verdict as
its own verdict, or a command to patch the old candidate.

## 3. Cross-Table Defects Found And Closed

### X1. QA recovery had two possible authorities

The old blocked-lineage table routed blocked forms through grave. The later QA
contracts classify `qa_rejected` as exact generation evidence.

Disposition:

```text
exact QA rejection -> completion/lineage/NETWORK
generic non-QA blocked repair -> remains archaeological/open
grave -> death-only classification, never QA continuation authority
```

The direct-unit DISSOLVE insight survives; grave transport does not.

### X2. Full carrier remained a semantic alias

Current NETWORK serializes the full carrier into `raw_prompt`, and FLOW creates
one catch-all `network_carrier` unit. Adding a second rejected-form unit without
removing this path would let the ancestor form survive after DISSOLVE through
the carrier alias.

Disposition for QA-rejected recovery only:

```text
full carrier = lineage/NETWORK transport evidence
raw_prompt = canonical current_work projection
field = current_work unit + inherited_rejected_form unit
historical QA = no implicit semantic read
```

Ordinary budget/stall recovery keeps the compatibility path until its own
matched semantic-continuity ablation.

### X3. Recovery basis had no exact typed join at NETWORK

Current carrier source refs contain `assessment_id`, but an array position is
not a contract. NETWORK could otherwise guess `continuation_basis`.

Disposition:

```text
pure projector input includes exact completion assessment + ledger event
projection binds assessment_id + completion_event_ref + basis
continuation event binds carrier_id + projection_id + assessment_id
NETWORK prepare checks the same ledger tuple
```

No second assessment registry is introduced.

### X4. Historical QA had provenance but no address

`carrier.qa_history.v1` had no dedicated id. A vague `historical_qa_ref` would
force implementation to invent one.

Disposition:

```text
historical_qa_id = "qa-history:" + sha256(canonical normalized qa_history)
```

This is an immutable derived address over the carrier-owned record, not a new
writer.

### X5. Release and residue identities were circular

The first draft let the release identify the residue while the residue carried
the release id. Deriving either id from the other would be circular.

Disposition:

```text
reserve next field unit id at exact potential revision
compute release id over payload containing that planned unit id
residue carrier may then contain release id
```

The existing field allocator remains the only field-unit numbering law.

### X6. DISSOLVE aftermath could create two competing OBSERVE actions

A field-native action for the changed target and a semantic action for residue
would be non-mergeable current modes aimed at the same operator.

Disposition:

```text
one semantic action covers both semantic and material classes
coverage includes current work, dissolved target and residue exact versions
prompt presents current work once + bounded residue once
dissolved target carrier is covered but never presented as task content
```

## 4. Authority Audit

| Decision/fact | Sole authority | Forbidden substitute |
|---|---|---|
| QA execution fact | QA body evidence | substrate prose |
| Final candidate verdict | deterministic verdict assembler | LLM judgment |
| Rejected terminal projection | △ manifest honesty | trace-tail inference |
| Intrinsic task recoverability | completion contract | wallet/grave |
| Continue or stop lineage | lineage runner/ledger | carrier itself |
| Re-entry semantic projection | pure NETWORK projector | FLOW |
| Field materialization | FLOW | NETWORK/grave |
| Need to release exact form | qualified pressure consumer | harness reason |
| Target readiness | ☷ independent re-derivation | committed reason alone |
| Applicability release | atomic DISSOLVE transaction | OBSERVE/ENCODE |
| Meaning after release | semantic OBSERVE proposal | DISSOLVE |

No substrate call appears before the post-release OBSERVE tick.

## 5. Truth Audit

| Claim | Required status |
|---|---|
| Ancestor check/verdict/terminal projection happened | `runtime_confirmed` |
| Completion/NETWORK/FLOW/release acts happened | `runtime_confirmed` |
| Rejected ancestor form applies to child before inspection | `inherited_proposal` |
| Child has already failed QA | forbidden inference |
| Release makes child implementation correct | no claim |
| Residue combines historical fact and prior applicability | `mixed` |

The DISSOLVE effect changes applicability and live-set membership only. It does
not rewrite the historical QA verdict.

## 6. Identity And Finality Audit

The causal chain is joined by distinct immutable identities:

```text
corpse id/hash
completion assessment id + completion event ref
carrier id/hash
NETWORK projection id
historical QA digest id
rejected-form projection id
field unit id/version
release id
residue unit id/version
```

Required finality laws:

```text
one corpse produces at most one selected continuation
one projection is bound before child birth
one rejected candidate produces at most one inherited form
one exact unit version produces at most one release
dissolved units cannot reactivate
dead Packets cannot mutate
```

## 7. Writer-To-Reader Closure

| Record | Writer | First named reader |
|---|---|---|
| QA check | QA hand/body | verdict assembler |
| QA verdict | deterministic assembler | △ |
| Terminal QA projection | △ | corpse capturer/completion |
| Completion assessment/event | completion + lineage ledger | carrier/NETWORK/runner |
| Recovery carrier | carrier builder | NETWORK verifier |
| Re-entry projection | NETWORK pure projector | continuation/packet birth/FLOW |
| Current-work unit | FLOW | qualified semantic pressure/OBSERVE |
| Inherited rejected form | FLOW | DISSOLVE pressure/readiness |
| Unit dissolution event | ☷ transaction | pressure discharge/coverage/audit |
| Rejected-form residue | ☷ transaction | semantic OBSERVE |
| Upper observation | ☴ | later pressure/structure work |

No newly introduced record lacks a named reader.

## 8. Failure Classification

| Failure | Classification | Result |
|---|---|---|
| QA infrastructure failure | world/effect evidence | Not candidate rejection |
| Generic blocked terminal | task outcome | Not QA recovery |
| Missing QA claim | honest absence | No rejected-form witness |
| Contradictory trusted QA tuple | invariant failure | Loud; no child |
| Empty wallet/recovery disabled | economy/policy | Assessment unchanged; no child |
| Carrier/projection mismatch | boundary invariant | Loud before birth |
| Stale DISSOLVE action | body precondition failure | No writes |
| Lua/internal transaction failure | world failure | Loud; never Packet mortality |
| Missing substrate after release | capability boundary | DISSOLVE remains valid; OBSERVE blocks honestly |

## 9. Compatibility Audit

Unchanged by this treatment:

```text
plan.v0 completion behavior
budget_exhausted / stalled recovery carrier semantics
grave warning/bequest death-only classification
raw-relation DISSOLVE
formed-relation DISSOLVE
candidate seal and QA evidence finality
Packet mortality and corpse freeze
observer/instrumentation masslessness
```

The QA path is selected by exact contract/evidence, not by a broad `blocked`
or `birth_kind=recovery` check.

## 10. Required Crystall Controls

The blueprints must preserve at least these matched families:

```text
exact QA rejection vs generic blocked vs infrastructure failure
same intrinsic assessment under funded/exhausted/recovery-disabled lineages
rejected vs accepted/no-QA rejected-form subprojection
full carrier alias absent on QA path
projection failure before continuation event
live form vs absent/foreign/stale/already-released form
ordinary consumer vs consumer ablation
release success vs staged transaction failure
one merged aftermath observation vs competing-action regression
observer on/off body identity
real grown ancestor/descendant vs synthetic assessment/form fixtures
```

The existing pending R3 red gate remains outside `tests/run.lua`; it describes
the raw-relation choreography gap and is not silently relabelled as evidence
for this direct-unit treatment.

## 11. Explicit Deferrals

This audit does not authorize or claim:

```text
semantic age or every-tick garbage collection
automatic decay of arbitrary thoughts/forms
generic grave-repair continuation
raw stale-relation growth in ordinary runner choreography
persistent cold-corpus storage
ordinary recovery migration away from the full-carrier compatibility prompt
all DISSOLVE modes or all 22 tree edges
router/full-tree promotion
```

## 12. Decision

The three new TABLE documents are mutually coherent after X1-X6 and are
precise enough to crystallize without inventing policy in code.

```text
TABLE cross-audit: satisfied
crystallization: technically ready
runtime implementation: still forbidden until blueprints exist and are read back
promotion claim: forbidden
```

The next bounded action is to produce three blueprints in dependency order:

```text
1. qa_rejected_lineage_recovery.v0
2. network_rejected_form_materialization.v0
3. qualified_dissolve_inherited_form.v0
```

## 13. Execution Update 2026-08-12

The machinist authorized CRYSTALL. All three blueprints were produced and
cross-read against the current body. The resulting dispositions and bounded
runtime authority are recorded in:

```text
docs/00_chaos/dissolve_network_crystall_cross_audit_2026-08-12.md
```

This update does not rewrite the pre-crystall decision above; it closes its
named next action.
