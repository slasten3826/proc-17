# Documentation Profiles And Economics Yellowprint v0

Status:

```text
table
date: 2026-07-20
source chaos:
  docs/00_chaos/self_documenting_lineage_corpus_notes_2026-07-20.md
  docs/00_chaos/nested_work_layer_runtime_integration_2026-07-20.md
scope:
  documentation profile
  required/optional completion law
  documentation economics
production code change authorized: no
crystallization authorized: yes / completed by the sibling blueprint after the
  2026-07-21 cross-table audit
router authority change authorized: no
amended 2026-07-21: F4 rejected-generation terminal projection is work
  evidence; documenting it does not create a second QA charge or Packet-local cost
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
```

Sibling tables:

```text
documentation_layer_snapshots_truth_yellowprint.v0.md
documentation_corpus_assembly_reentry_yellowprint.v0.md
nested_work_layer_derivation_yellowprint.v0.md
completion_scope_candidate_seal_yellowprint.v0.md
stage_transition_generation_recovery_yellowprint.v0.md
```

## 0. Table Decision

Documentation is an orthogonal root-process contract, not a third work mode and
not another mutable Packet state.

The selected vocabulary is:

```text
work mode:             plan | build
derived work layer:    ⋯ | ⊞ | ◈ | ▲
documentation profile: off | structured | full
```

The body always records the evidence required for its own physics. The profile
controls only which portable corpus is exported from that evidence.

```text
off        -> mandatory body evidence only; no optional portable corpus
structured -> bounded deterministic machine corpus; no narration call required
full       -> structured corpus plus bounded human projections
```

`full` is strictly additive over `structured`. No full export may exist without
the exact structured source from which it was rendered.

## 1. Fixed Decisions

```text
D0  documentation is not a ProcessLang organ
D1  documentation profile is not plan/build mode
D2  profile is selected by the root process contract, never by substrate prose
D3  off never disables trace, lineage, economics, mortality or evidence
D4  structured export is the canonical portable machine representation
D5  full export depends on structured export and may add semantic narration
D6  structured export requires zero additional substrate calls in v0
D7  documentation costs are tagged separately but remain part of lineage cost
D8  documentation cap cannot mint extra lineage budget
D9  optional documentation cannot revoke accepted software completion
D10 required documentation may keep the root task incomplete
D11 exhaustion is reported, never hidden behind a shorter successful summary
D12 lineage-side documentation output cannot alter sealed candidate bytes or QA verdict
D13 profile changes cannot grant repository, test or provider authority
D14 descendant birth does not reset cumulative documentation spending
D15 caller-, substrate- or Markdown-authored completion labels have no authority
D16 documentation generated inside a delivered candidate is an ordinary declared artifact
D17 the complete lineage corpus remains lineage-side because post-seal QA/history cannot be self-contained in the candidate
D18 v0 audience is derived from profile, not selected through an independent flag
D19 documentation-scoped cost never decrements Packet-local budget or changes Packet mortality
D20 full + required means the complete declared structured and human projection; omitted narration must be a separate optional auxiliary export
```

## 2. Scope Matrix

| Surface | v0 table decision | Deferred |
|---|---|---|
| Profile vocabulary | `off`, `structured`, `full` | custom profiles/plugins |
| Selection authority | explicit root process contract | semantic task classifier |
| Mandatory body evidence | always on | none |
| Structured export | deterministic, bounded, no LLM | alternative encodings |
| Human export | bounded Markdown projection | rich media/TUI replay |
| Documentation token cap | explicit optional limit | adaptive pricing |
| Lineage accounting | tagged and cumulative | refunds/reservations market |
| Completion interaction | required versus optional | partial deliverable negotiation |
| Corpus placement | lineage archive only in v0 | remote publishing |
| Product documentation | ordinary predeclared candidate artifacts | packaged corpus subsets |
| Router effect | no direct effect | qualified required-export pressure after crystall |

## 3. Root Documentation Declaration

Candidate declaration:

```lua
{
  kind = "proc17_documentation_contract",
  protocol_version = "documentation.contract.v0",
  profile = "off" | "structured" | "full",
  required = boolean,
  placement = "lineage_archive",
  limits = {
    prompt_tokens = integer | nil,
    completion_tokens = integer | nil,
    total_tokens = integer | nil,
    substrate_calls = integer | nil,
    output_bytes = integer,
    files = integer,
  },
  requested_at = "root_birth",
  source_refs = string[],
  declaration_truth_status = "document_decision",
  binding_event_truth_status = "runtime_confirmed",
}
```

This is a table candidate, not a production schema.

The profile/required policy is a human/project decision. The body may
runtime-confirm that the exact declaration was bound before root birth without
promoting the policy itself into observed runtime physics.

Validation matrix:

| Declaration | Result |
|---|---|
| absent | compatibility default selected by host policy; must be recorded |
| unknown profile | loud contract error before Packet birth |
| `off`, `required=false` | valid |
| `off`, `required=true` | invalid contradictory contract |
| `structured` | machine-readable structured corpus; no human projection requirement |
| `full` | structured corpus plus human projection |
| `full`, no structured output | impossible; structured dependency is mandatory |
| caller supplies `candidate_repository` placement | rejected in v0; product docs use the ordinary artifact contract |
| negative/non-integer bound | loud contract error |
| caller supplies runtime completion status | ignored/rejected; not declaration authority |

Recommended compatibility default for the first implementation:

```text
profile = off
required = false
placement = lineage_archive
```

The first experiment may opt into `structured` explicitly. Promotion to a
different default requires profile ablation evidence.

## 4. Profile Product Matrix

| Product | `off` | `structured` | `full` |
|---|---:|---:|---:|
| Packet trace required | yes | yes | yes |
| lineage ledger required | yes | yes | yes |
| budget/loss evidence required | yes | yes | yes |
| corpse/carrier evidence required | when produced | when produced | when produced |
| candidate/QA evidence required | when produced | when produced | when produced |
| portable structured index | no | yes | yes |
| layer snapshots exported | no optional export | yes | yes |
| deterministic Markdown | no | no | yes where schema supports it |
| substrate-written explanation | no | no | allowed under cap |
| additional substrate calls | zero | zero | bounded, visible |
| sealed candidate may change after export starts | no | no | no |
| root completion may depend on docs | never | only if required | only if required |

`off` still permits the normal final product manifest already required by the
task contract. It disables the additional self-documenting corpus, not ordinary
result delivery.

## 5. Selection Authority

Authority order:

| Priority | Source | Permitted decision |
|---:|---|---|
| 1 | explicit CLI/TUI/API root contract | select profile, required flag and limits |
| 2 | trusted host default | fill an absent declaration and record that choice |
| 3 | body-derived task contract | declare exact required documentation artifacts if root contract allows it |
| 4 | substrate proposal | propose content only; cannot widen profile or limits |
| 5 | generated Markdown | no configuration authority |

Forbidden elevation:

```text
user asks for code
substrate decides "a detailed design document would be useful"
body silently changes off -> full
```

Allowed proposal path:

```text
substrate proposes documentation as a semantic option
body exposes it in result/residue
future explicit root contract may request it
```

Derived audience projection:

| Profile | Machine corpus reader | Human projection reader |
|---|---:|---:|
| `off` | no portable corpus | no |
| `structured` | yes | no |
| `full` | yes | yes |

## 6. Documentation Cost Namespace

Every budget cost keeps the existing physical axes and adds a causal scope:

```lua
{
  kind = "budget_cost",
  lineage_id = string,
  scope = "work" | "documentation",
  documentation_phase = nil
    | "structured_assembly"
    | "deterministic_render"
    | "substrate_narration"
    | "export_validation",
  cost = {
    steps = number,
    substrate_calls = number,
    prompt_tokens = number,
    completion_tokens = number,
    total_tokens = number,
    estimated_tokens = number,
    tool_calls = number,
    file_writes = number,
    time_ms = number,
    money_units = number,
  },
  source_refs = string[],
  truth_status = "runtime_confirmed" | "estimated",
}
```

This table does not require changing the existing cost-event schema exactly as
shown. It requires one unambiguous attribution dimension so the same total can
be reported by cause.

Cost invariants:

```text
lineage total = work-tagged costs + documentation-tagged costs
documentation spent <= documentation contract cap, when a cap exists
documentation cap does not increase lineage total limit
documentation-tagged steps never enter Packet-local step balance or mortality
provider usage beats local estimation
estimated usage remains typed estimated
one documentation cost id commits documentation-cap and lineage totals atomically
```

There are two ledgers at this boundary:

```text
Packet-local budget/loss -> mortality of the current Packet life
lineage economics        -> cumulative work + documentation cost and future affordability
```

Documentation-scoped work is charged only to the lineage total and its bounded
documentation cap. It cannot increment body ticks, decrement the current
Packet's step allowance, create Packet loss or alter that Packet's route/death.
If an operation is required by the body even when documentation is off, it is
ordinary work and is charged once as work. If it exists only to capture,
serialize, render, validate or export the corpus, it is documentation work.

## 7. Charging Matrix

| Action | Scope | Required charge |
|---|---|---|
| derive evidence already required by body with documentation off | work | normal body cost; never double charge |
| capture an observer-only snapshot for export | documentation | lineage steps/time only; zero Packet-local mass |
| canonicalize/export structured snapshot | documentation | steps/time/tool/write bytes as observed |
| deterministic Markdown render | documentation | steps/time/tool/write bytes |
| call substrate for narration | documentation | substrate call + exact/estimated token usage |
| validate refs/digests/redactions | documentation | steps/time/tool calls |
| write corpus file | documentation | file write + bytes/time when available |
| run software QA | work | never documentation merely because result is documented |
| generate source code | work | never documentation merely because prose accompanies it |

The body must not charge one physical action twice. Attribution answers why the
action occurred; the lineage ledger still records one actual cost.

## 8. Documentation Cap Evaluation

Candidate status:

```lua
{
  kind = "documentation_economy_assessment",
  protocol_version = "documentation.economy.v0",
  profile = string,
  required = boolean,
  spent = table,
  remaining = table,
  exhausted = boolean,
  exhausted_keys = string[],
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  usage_truth_statuses = string[],
}
```

Evaluation rules:

| State | Optional documentation | Required documentation |
|---|---|---|
| cap available | continue bounded export | continue bounded export |
| exact cap reached after complete export | complete | complete |
| cap exhausted before complete export | stop export, mark partial | root documentation requirement unsatisfied |
| lineage total exhausted first | normal lineage exhaustion/terminal law | same; docs do not mask it |
| provider usage unknown | use bounded estimate if policy permits | otherwise block narration, preserve structured evidence |
| output byte/file cap reached | partial with exact omitted inventory | incomplete required deliverable |

The documentation cap can stop documentation work. It cannot rewrite the task
assessment of an already accepted candidate.

## 9. Completion Products

The completion reader must derive separate products:

```lua
software_task_state = "incomplete" | "accepted" | "rejected"
                    | "blocked" | "unknown"

documentation_state = "disabled" | "incomplete" | "partial"
                    | "complete" | "blocked"

root_task_state = derived from the explicit root process contract
```

Matrix:

| Software | Documentation profile/state | Required | Root result |
|---|---|---:|---|
| accepted | off/disabled | false | complete candidate for root manifest |
| accepted | structured/complete | false or true | complete candidate |
| accepted | structured/partial | false | software complete; docs partial |
| accepted | structured/partial | true | root incomplete, exact docs requirement missing |
| accepted | full/structured complete, prose partial | false | software complete; docs partial |
| accepted | full/structured complete, human projection partial | true | root incomplete; the declared full product is missing |
| rejected | any | any | root not complete; documentation cannot launder rejection |
| blocked/unknown | full prose says complete | any | remains blocked/unknown |

This separation repeats the established rule:

```text
economics and policy do not rewrite intrinsic task evidence
```

## 10. Optional Versus Required Documentation

Optional documentation is an auxiliary lineage export.

```text
accepted software remains accepted
partial export is visible
the final result points to available corpus records
no recovery generation is born solely to improve optional prose
```

Required documentation is a declared deliverable.

```text
its exact required files/sections are known before completion
missing items appear in missing_requirements
substrate confidence cannot satisfy them
budget exhaustion remains the real blocking cause
```

In v0, `profile=full` and `required=true` requires the complete declared human
projection as well as the structured corpus. A contract that requires only the
machine corpus must select `structured + required`; it may request a separate
optional `full` export. Likewise, any narration intentionally excluded from the
required human projection must be declared as a separate auxiliary export.
`full + required` cannot quietly redefine a failed required renderer as optional.

When product documentation belongs inside the candidate repository, it is an
ordinary required artifact, not the canonical lineage-corpus placement. It must
be formed and materialized before the candidate seal. A lineage-side renderer
may not patch those files after QA. Final QA evidence and post-seal lineage
history remain in the external corpus.

## 11. Interaction With Packet Mortality And Lineage

Documentation does not make a Packet immortal.

```text
Packet loss remains Packet-local physics
Packet body work remains paid from Packet-local budget
documentation never receives or spends Packet-local budget
lineage economics remain cumulative
documentation costs survive in the lineage ledger
new generation receives remaining lineage allowance, not a reset counter
```

An optional full export should normally occur at a stage/root boundary after
the structured evidence exists. If narration cannot finish before its
documentation cap, lineage limit or host interruption, the lineage may preserve
`documentation_state=partial`; it must not resurrect a completed Packet merely
to make prose prettier.

Whether a required documentation deliverable permits a dedicated continuation
is an open crystall decision. It must use typed lineage mechanics, not an
unbounded hidden LLM loop.

## 12. Writer And Reader Matrix

| Record | Writer | First named reader | Effect reader |
|---|---|---|---|
| documentation contract | CLI/TUI/API or trusted default | contract validator | profile/economy inspector |
| tagged cost event | budget/economics body | documentation economy inspector | lineage budget and report |
| documentation economy assessment | pure/recorded body derivation | corpus assembler and completion reader | continue/partial/block decision |
| documentation status | corpus assembler | root completion policy | manifest/CLI/TUI |
| optional partial record | corpus assembler | final manifest | external human/machine |
| required missing requirement | completion reader | lineage runner/report | typed continuation or terminal result |

No status is accepted from the renderer whose work it judges.

## 13. Profile Ablation Matrix

The initial control corpus uses fake/deterministic substrate lives, lineage-side
placement and a fixed accepted candidate. Candidate-repository documentation is
a different root contract and is covered separately by A12.

| ID | One changed variable | Required result |
|---|---|---|
| A0 | profile absent versus explicit off | same Packet route, candidate, QA and completion |
| A1 | off versus structured | same Packet route/ticks/local budget/loss/death and candidate bytes/digest |
| A2 | structured export disabled after snapshots | body route and candidate unchanged; corpus absent |
| A3 | structured versus full with narration disabled | identical structured evidence closure/content identity; contract/export envelopes may differ |
| A4 | full narration enabled | candidate/QA unchanged; only docs calls/cost/output added |
| A5 | narration text changes | structured corpus and candidate unchanged |
| A6 | docs cap low versus high | current Packet history is identical; docs status/output/cost and later lineage affordability may differ |
| A7 | required false versus true with complete docs | same software evidence; root both complete |
| A8 | required false versus true with partial docs | same software evidence; only root completion differs |
| A9 | substrate says profile=full under off contract | remains off |
| A10 | renderer writes software-complete claim | no effect on software assessment |
| A11 | descendant generation | documentation spent remains cumulative |
| A12 | caller requests candidate_repository corpus placement | contract rejected; candidate unchanged |
| A13 | documentation event reports `cost.steps > 0` | lineage/docs totals change; current Packet step balance and mortality do not |

The ablation compares:

```text
route
operator ticks
Packet-local step balance and death cause
work substrate calls
work token use
loss
candidate digest
QA evidence/verdict
software assessment
lineage generation outcome
```

Documentation-only costs and export events are expected differences. A later
lineage continuation decision may also differ when cumulative spend changes;
the already observed Packet life may not.

## 14. Budget Controls

| ID | Grown condition | Required result |
|---|---|---|
| B0 | structured profile, zero narration cap | structured export still possible without LLM |
| B1 | full profile, exact provider usage | costs runtime-confirmed and tagged documentation |
| B2 | full profile, provider usage absent | estimate typed estimated or narration blocked by policy |
| B3 | documentation cap exhausted | no further narration call |
| B4 | docs cap exhausted, optional | software result preserved, docs partial |
| B5 | docs cap exhausted, required | exact missing documentation requirement |
| B6 | lineage total exhausted during docs | normal lineage terminal law, no special free completion |
| B7 | new generation born | previous docs cost remains spent |
| B8 | one action observed by work and docs | one physical cost event, not two |
| B9 | output byte cap reached | bounded partial inventory; no silent truncation |
| B10 | documentation-scoped steps recorded during a live Packet | lineage/docs totals change; Packet-local steps/death remain identical |

## 15. False-Green Matrix

| False green | Rejecting rule/control |
|---|---|
| off disables trace to save space | D3 + A0/A1 |
| full Markdown exists without structured source | D5 + A3 |
| documentation tokens omitted from total cost | D7/D8 + B1/B7 |
| docs get a fresh budget each generation | D14 + B7 |
| optional prose failure makes working software failed | completion matrix + B4 |
| required docs ignored because code passed | completion matrix + B5 |
| model chooses a more expensive profile | selection authority + A9 |
| renderer declares its own completion | D15 + A10 |
| same physical action charged as work and docs | charging law + B8 |
| truncation called complete | D11 + B9 |
| documentation in candidate patched after seal | D16/D17 + A12 |
| documentation steps kill or reroute the observed Packet | D19 + A1/A13/B10 |
| required full export succeeds with missing human projection | D20 + completion matrix |

## 16. Failure Classification

| Failure | Classification | Product consequence |
|---|---|---|
| malformed documentation contract | trusted input/contract error | loud before birth |
| unsupported profile | typed contract error | no silent fallback |
| optional docs budget exhausted | known auxiliary outcome | docs partial; software unchanged |
| required docs budget exhausted | known root requirement failure | root incomplete/blocked by exact contract |
| provider usage unavailable | epistemic/economy condition | estimated or narration denied by policy |
| renderer exception | world/harness failure | loud for required path; optional export visibly failed |
| candidate bytes change under profile ablation | body invariant violation | reject implementation |
| untagged documentation substrate call | accounting invariant violation | reject implementation |
| full output without structured dependency | provenance invariant violation | reject export |

World/harness failures are not converted into honest Packet mortality unless a
future contract explicitly makes the exporter a bounded body capability with a
typed runtime failure. Lua corruption remains loud.

## 17. Non-Goals

This table does not define:

```text
the exact layer snapshot schema
the corpus filesystem/object-store layout
Markdown templates
the corpus digest tree
redaction algorithms
NETWORK@▽ ingestion
retention/compost policy
which ProcessLang edge satisfies required documentation pressure
human prose quality scoring
`qa-check.v0` and QA execution authority
```

Those belong to the sibling tables or later crystallization.

This table also does not authorize:

```text
new substrate calls
new file writes
router promotion
candidate repository mutation
automatic documentation by task classification
```

## 18. Crystallization Gate

This table is ready for crystallization only when its sibling tables agree on:

```text
which structured products count as complete
which component records the documentation status
which identity binds export to lineage/generation/candidate
where lineage-side output may be written
how full rendering proves dependence on structured source
```

Gate result, 2026-07-21:

```text
all five joins are named consistently across TABLE and CRYSTALL
F4 rejected-generation evidence remains work evidence, not a documentation charge
qa-check.v0 remains explicitly deferred with QA execution
cross-table crystallization gate satisfied
production implementation authority remains limited by each blueprint
```

The first code target after crystall remains:

```text
explicit profile=structured
lineage-side export
zero narration calls
shadow/observer-only behavior
profile ablation before authority
```
