# F4 Rejected-Generation Terminal Projection Notes - 2026-07-21

Status:

```text
chaos / document_decision candidate
decision owner: machinist + Codex
external evidence:
  docs/00_chaos/fable_full_project_f4_audit_raw_2026-07-21.md
supersedes as executable direction:
  standalone failure-crystal assumptions in the 2026-07-20 nested-layer sprint
code authority granted by this document: no
```

## 0. Decision

F4 chooses outcome A:

```text
There is no standalone runtime failure_crystal.v0 object.

Rejected-generation facts are owned by the exact QA records and are embedded
as one bounded structured projection in the Packet terminal manifest.
```

This is not a decision to forget failure. It is a decision not to duplicate
the same failure into a second authority-bearing object.

The rejected-generation projection is a view assembled from named existing
owners:

```text
candidate seal
QA contract
QA check records
final rejected QA verdict
Packet terminal manifest
corpse
lineage recovery carrier
```

Its durability comes from the full manifest retained by the corpse, not from
the bounded trace tail.

## 1. Why A Separate Crystal Is Wrong

The former design asked one object to combine two different truth classes:

```text
mechanical failure facts         runtime_confirmed
semantic account of what to do   semantic_proposal
```

That object would either duplicate the verdict or make semantic advice look
like body truth. It would also need a new writer, identity, schema, reader,
retention law and hostile-input boundary while adding no causal ability.

There is no separate success crystal. Accepted QA becomes a terminal candidate
through the verdict and manifest. Rejected QA follows the same law.

Canonical symmetry:

```text
accepted verdict -> ▲ -> △ -> accepted-generation corpse
rejected verdict -> ▲ -> △ -> rejected-generation corpse
```

The difference is in terminal content and lineage assessment, not in whether a
new intermediate organ exists.

## 2. Exact Phase Law

The four build glyphs describe evidence already present:

| Glyph | Rejected-generation phase | Exact boundary |
|---|---|---|
| `⋯` | candidate is still being materially formed | declared artifact set remains incomplete or unsealed |
| `⊞` | candidate is sealed and QA has not produced rejection evidence | exact QA verdict is absent |
| `◈` | one or more current required QA checks have rejected, but the one final immutable verdict has not yet been assembled | rejected check evidence is current; final verdict missing |
| `▲` | one final rejected verdict is bound to the exact current seal, contract and rejected check refs | Packet may enter △ and manifest the rejected generation |

Therefore:

```text
◈ is not a stored failure crystal.
◈ is the live body phase that crystallizes exact check evidence into one final verdict.

▲ is not a corpse and not root completion.
▲ is a Packet-local terminal candidate whose exact refs are ready for △.
```

The terminal projection itself is written at △. A living `▲` projection has
`boundary_terminalized=false`; after △ and corpse registration the historical
projection has `boundary_terminalized=true`.

## 3. Writer And Reader Chain

| Record or view | Exact writer | First named reader | Authority |
|---|---|---|---|
| QA check record | future bounded QA hand plus body verifier | QA verdict assembler | exact mechanical check evidence |
| final QA verdict | dedicated body verdict writer | work-layer/completion inspectors | candidate acceptance or rejection under one QA contract |
| rejected-generation terminal projection | △ manifest assembler | corpse capture and completion reader | durable bounded projection of exact rejected generation evidence |
| corpse | corpse capture after terminal Packet | lineage runner | immutable life evidence |
| recovery carrier | lineage carrier builder | NETWORK@▽ only | bounded inherited proposal for a fresh generation |
| semantic diagnosis | substrate through normal descendant observation/encode | descendant body | proposal only |

There is no writer named `failure_crystal_writer` and no reader named
`failure_crystal_reader`.

## 4. Terminal Manifest Law

For a `qa_rejected` generation, △ must embed this bounded structured projection
in the Packet manifest:

```lua
rejected_generation = {
  protocol_version = "runtime.rejected_generation_projection.v0",
  lineage_id = "lineage:...",
  generation = 2,
  packet_id = "packet:...",
  stage_id = "stage:<lineage_id>:2:build",
  repository_id = "repo:...",

  candidate_seal_id = "candidate-seal:...",
  qa_contract_id = "qa-contract:...",
  qa_verdict_ref = "qa-verdict:...",
  rejected_check_refs = {"qa-check:..."},
  rejected_checks = {
    -- bounded mechanical projections, schema deferred with qa-check.v0
  },

  source_refs = {},
  completeness = "complete" | "partial" | "unsupported",
  event_truth_status = "runtime_confirmed",
  content_truth_statuses = {},
}
```

The name describes a manifest member, not a new globally stored runtime object.
Its canonical identity is part of the enclosing manifest/corpse identity.

Required invariants:

```text
seal, verdict and every check belong to the same lineage/generation/candidate
verdict is final and rejected
every declared required check is accounted for
at least one required check is rejected
bounded projections are copied, not referenced through mutable tables
source refs preserve original truth statuses
no private QA handle, grant, host path or source-write authority is embedded
semantic diagnosis is absent or remains an explicitly separate proposal
```

Refs alone are insufficient for portability. A descendant or cold corpus reader
may not retain the ancestor's complete trace, so the manifest must include the
bounded mechanical facts needed by its declared readers.

## 5. Trace Tail Is Not Durable Storage

Current corpse capture retains:

```text
full Packet manifest
bounded trace_tail, currently 32 events by default
```

The trace tail is diagnostic evidence, not the durable owner of terminal
requirements. Any check older than the tail can disappear from the corpse's
trace view while the corpse remains valid.

Consequently:

```text
terminal facts required after death must be embedded in the manifest
trace refs may supplement that projection but cannot replace it
```

This extends manifest honesty. It does not expand trace retention.

## 6. Recovery Law

After rejected terminalization:

```text
△ writes bounded rejected-generation projection and kills Packet N
corpse freezes Packet N
lineage verifies intrinsic unfinished/recoverable state
lineage economics independently decides whether continuation can be paid
recovery carrier copies the bounded rejected-generation projection
NETWORK@▽ births Packet N+1 with fresh Packet and repository identities
Packet N+1 derives build ⋯ from its own empty candidate state
```

The carrier may expose prior facts as inherited material. It does not command a
patch and cannot reopen generation N.

The descendant may ask the substrate to interpret the evidence. That output is
new `semantic_proposal`, not a retroactive fact about the dead generation.

## 7. Grave Boundary

Grave and QA remain separate:

```text
grave classifies how a Packet life ended and whether its mortality residue is
a warning, bequest or neutral record

lineage classifies whether a rejected software generation is intrinsically
unfinished/recoverable and whether a new generation can be afforded
```

QA rejection alone cannot change grave kind. Grave cannot authorize recovery.
The rejected-generation projection may coexist with grave residue, but neither
is a substitute for the other.

## 8. Corpus Law

The lineage corpus stores the existing authority records:

```text
candidate seal
QA check evidence when available
final QA verdict
Packet manifest containing rejected_generation projection
corpse
lineage assessment and carrier
```

It does not store a `failure_crystal` object kind.

If a future portable renderer produces a named failure summary, that summary is
a pure corpus projection. It cannot become a runtime writer, completion fact or
recovery authority.

## 9. Explicit QA Deferral

This F4 decision does not invent the QA hand.

The following remain one later capability campaign:

```text
qa.contract.v0 authority and selection
qa-check.v0 schema
read-only candidate exposure
bounded scratch filesystem
command/test allowlists
timeout, output and process-tree bounds
receipt verification
final qa.candidate_verdict.v0 writer
hostile QA controls
```

`qa-check.v0` must eventually define enough bounded mechanical content for the
terminal projection. Until then, tests may use explicit typed fixtures, but no
runtime implementation may invent the check schema locally.

The legacy `io.popen` spell path is not a QA capability and must not be reused
as one.

## 10. Falsifiers

The decision is wrong if any of these are observed:

```text
F0 a named reader needs information unavailable from seal/verdict/check/manifest/corpse
F1 rejected generation reaches ▲ before one final current rejected verdict exists
F2 rejected check evidence exists but the work layer remains ⊞
F3 semantic advice can change the exact rejected verdict or terminal projection
F4 a long rejected life loses required failure facts when trace_tail truncates
F5 descendant receives an ancestor grant, path or writable repository identity
F6 rejected generation is classified as accepted/root complete
F7 grave kind changes merely because QA metadata is present
F8 wallet exhaustion changes the intrinsic rejected/recoverable assessment
F9 substrate-supplied crystal-shaped data is accepted as body truth
F10 documentation observer changes Packet route, loss, budget or verdict
```

Minimum matched corpus:

```text
short rejected life versus same life padded beyond trace_tail
rejected checks present versus final verdict present: ◈ -> ▲
accepted verdict versus rejected verdict at the same sealed candidate boundary
same rejected corpse with lineage wallet available versus exhausted
same mortality residue with and without QA metadata
carrier enabled versus disabled: child identity/evidence changes, ancestor does not
```

## 11. Documentary Consequence

The six TABLE documents and seven CRYSTALL blueprints must use one vocabulary:

```text
rejected QA check evidence
final rejected QA verdict
rejected-generation terminal candidate
rejected-generation terminal projection
rejected-generation manifest/corpse
build-generation recovery carrier
```

The following vocabulary is removed from current executable direction:

```text
failure_crystal
failure crystal
typed failure crystal
failure_crystal_recorded
qa_rejected_failure_crystal_missing
```

Historical CHAOS documents and explicitly superseded archaeology may retain the
old terms. They are evidence of the path, not current authority.

## 12. Decision Boundary

Resolving F4 closes the documentary ambiguity. It does not authorize QA code or
promote any router/completion authority.

After TABLE/CRYSTALL synchronization and cross-check:

```text
F4 documentary decision: resolved
cross-table crystallization gate: satisfied
QA implementation gate: still closed by explicit deferral
production code authority: only what each individual blueprint explicitly grants
```

The next implementation campaign begins from exact blueprints, not from this
CHAOS record.
