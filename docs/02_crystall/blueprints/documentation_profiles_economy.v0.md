# Documentation Profiles And Economics Blueprint v0

Status:

```text
crystall
date: 2026-07-20
source table: docs/01_table/yellowprints/documentation_profiles_economy_yellowprint.v0.md
root completion authority: verified lineage only
Packet-local mortality authority: unchanged
first implementation profile: explicit structured
router authority: forbidden
substrate narration: deferred
F4 boundary: rejected-generation projection is existing work evidence;
  documentation capture adds no Packet-local QA charge
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
2026-07-21 cross-table documentary gate: satisfied
```

## 0. Crystallized Claim

Documentation is an explicit root-process product with its own bounded economy.
It is not a work mode, Packet organ, routing pressure or free side effect of
software generation.

```text
body evidence exists for every profile
off        -> no portable documentation corpus
structured -> deterministic machine-readable lineage corpus
full       -> structured corpus plus declared human projection
```

Documentation work is paid by cumulative lineage economics. It never spends the
current Packet's local step allowance, creates Packet loss, changes a committed
route or changes the cause of that Packet's death.

## 1. Target Surface

New pure modules:

```text
runtime/documentation_contract.lua
runtime/documentation_economy.lua
tests/test_documentation_contract.lua
tests/test_documentation_economy.lua
tests/test_documentation_profile_ablation.lua
```

Later integration, after pure controls are green:

```text
runtime/lineage.lua
runtime/lineage_budget.lua
runtime/lineage_runner.lua
runtime/completion_scope.lua
runtime/process_contract.lua         new only if root contracts gain a common owner
runtime/documentation_snapshot.lua   sibling crystall
runtime/documentation_corpus.lua     sibling crystall
```

Forbidden first-slice changes:

```text
runtime/tree_router.lua
runtime/pressure.lua
runtime/budget.lua Packet-local charging law
organs/*
candidate repository contents
substrate system prompt
```

## 2. Public Contract API

```lua
local documentation_contract = require("runtime.documentation_contract")

documentation_contract.bind(declaration, host_policy, context)
  -> bound_contract | nil, err

documentation_contract.verify(bound_contract, context)
  -> true | nil, err

documentation_contract.products(bound_contract)
  -> product_requirements | nil, err
```

`bind` runs before root lineage birth. It validates an explicit declaration or
records the exact trusted host default used when the declaration is absent.

```lua
local documentation_economy = require("runtime.documentation_economy")

documentation_economy.new(bound_contract, lineage_context)
  -> economy_state | nil, err

documentation_economy.charge(economy_state, cost_event, lineage_context)
  -> next_state | nil, err

documentation_economy.assess(economy_state, lineage_budget, product_state)
  -> assessment | nil, err

documentation_economy.snapshot(economy_state)
  -> detached_state
```

Every operation is deterministic over explicit inputs. Returned objects are
detached deep copies. No API receives a living Packet instance.

## 3. Bound Documentation Contract

```lua
{
  kind = "proc17_documentation_contract",
  protocol_version = "documentation.contract.v0",
  contract_id = "documentation-contract:<sha256>",

  profile = "off" | "structured" | "full",
  required = boolean,
  placement = "lineage_archive",

  required_products = {
    structured_corpus = boolean,
    human_projection = boolean,
  },

  limits = {
    prompt_tokens = integer | nil,
    completion_tokens = integer | nil,
    total_tokens = integer | nil,
    substrate_calls = integer | nil,
    output_bytes = integer,
    files = integer,
  },

  requested_at = "root_birth",
  selection_source = "explicit" | "trusted_host_default",
  source_refs = string[],
  declaration_truth_status = "document_decision",
  binding_event_ref = string,
  binding_event_truth_status = "runtime_confirmed",
}
```

`contract_id` hashes the canonical representation excluding itself and the
runtime binding event ref. Policy and binding remain separate facts:

```text
profile choice                 -> document_decision
body bound this exact choice   -> runtime_confirmed
```

Derived product requirements are fixed:

| Profile | Structured corpus | Human projection |
|---|---:|---:|
| `off` | no | no |
| `structured` | yes | no |
| `full` | yes | yes |

For `required=true`, every product marked yes is required. In particular,
`full + required` cannot silently downgrade a failed or omitted human
projection to optional narration.

## 4. Contract Validation

The validator applies this order:

```text
1. reject caller-supplied runtime completion/status fields
2. select explicit declaration or one recorded trusted default
3. validate protocol/profile/required/placement
4. reject off + required
5. require lineage_archive placement
6. validate every bound as a non-negative integer or nil where allowed
7. derive exact required products
8. canonicalize and bind one contract before root birth
```

Compatibility default:

```text
profile = off
required = false
placement = lineage_archive
```

Unknown profiles, malformed limits and contradictory declarations are trusted
contract errors. They fail loudly before Packet birth; they are not Packet
deaths and receive no semantic fallback.

## 5. Cost Event Contract

Documentation reuses the existing physical cost axes but adds one mandatory
causal scope.

```lua
{
  kind = "budget_cost",
  cost_id = "cost:<sha256>",
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
    output_bytes = number,
    time_ms = number,
    money_units = number,
  },
  source_refs = string[],
  truth_status = "runtime_confirmed" | "estimated",
}
```

Rules:

```text
one physical action -> one cost event
body-required action -> scope=work
capture/render/export-only action -> scope=documentation
provider usage -> runtime_confirmed when independently received
local token estimate -> estimated
unknown usage -> never flattened into zero or confirmed
```

An action observed by both work and documentation is charged once under its
physical cause. Documentation reporting may reference the work cost; it may not
duplicate it.

## 6. Two-Ledger Boundary

The ledgers answer different questions.

| Ledger | Owns | Must not own |
|---|---|---|
| Packet-local budget/loss | mortality of one Packet life | corpus/export costs |
| lineage economics | cumulative work plus documentation cost | Packet identity loss |
| documentation cap | bounded documentation activity | additional lineage funds |

Required equations:

```text
lineage_spent = work_spent + documentation_spent
documentation_spent <= documentation_cap when bounded
documentation_cap does not increase lineage_limit
new generation inherits remaining lineage allowance, never a fresh total
```

A documentation-scoped cost event may update lineage totals and documentation
cap totals only. It must not:

```text
increment Packet body ticks
decrement Packet-local budget.steps
change Packet loss
advance Packet revisions
append Packet field/CALM state
alter readiness, pressure or committed route
change Packet status or death cause
```

This is an invariant, not an implementation preference.

The two lineage-side totals commit atomically. The integration must preflight
both the documentation cap and the lineage allowance, derive both next states,
and append one transaction keyed by `cost_id`. Either the documentation state
and lineage budget both name that charge or neither does. A crash or rejected
overdraw cannot leave one ledger spent and the other unchanged.

## 7. Economy State

```lua
{
  protocol_version = "documentation.economy_state.v0",
  contract_id = string,
  lineage_id = string,
  profile = "off" | "structured" | "full",
  required = boolean,

  spent = {
    prompt_tokens = number,
    completion_tokens = number,
    total_tokens = number,
    substrate_calls = number,
    output_bytes = number,
    files = number,
    steps = number,
    tool_calls = number,
    file_writes = number,
    time_ms = number,
    money_units = number,
  },

  cost_event_refs = string[],
  usage_truth_statuses = string[],
  revision = integer,
}
```

The state is owned by the lineage-side documentation transaction, not the
Packet. `charge` returns a new state; callers may persist only the validated
result and event ref in the lineage ledger.

Negative, NaN, infinite, malformed, duplicate or cross-lineage cost events are
rejected loudly. Duplicate exact `cost_id` is idempotent and not charged twice.

## 8. Economy Assessment

```lua
{
  kind = "documentation_economy_assessment",
  protocol_version = "documentation.economy.v0",
  assessment_id = "documentation-economy:<sha256>",
  contract_id = string,
  lineage_id = string,
  profile = string,
  required = boolean,
  spent = table,
  remaining = table,
  exhausted = boolean,
  exhausted_keys = string[],
  lineage_affordable = boolean,
  product_state = "disabled" | "incomplete" | "partial" | "complete"
    | "blocked",
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  usage_truth_statuses = string[],
}
```

Assessment rules:

| Condition | Optional docs | Required docs |
|---|---|---|
| cap available | continue bounded work | continue bounded work |
| cap ends after complete product | complete | complete |
| cap ends before complete product | partial and stop | exact requirement missing |
| lineage allowance exhausted | normal lineage affordability result | same |
| exact usage absent | estimate if policy permits | otherwise deny optional narration path |
| file/byte bound reached | explicit omitted inventory | exact requirement missing |

The assessment may say whether this lineage can afford more work. It never
changes whether a candidate was accepted, rejected or intrinsically
recoverable.

## 9. Completion Join

Three facts remain separate:

```text
software_task_state
documentation_state
root_task_state
```

Only a verified lineage completion reader may join them.

| Software | Documentation | Required | Root consequence |
|---|---|---:|---|
| accepted | disabled | false | eligible for root delivery |
| accepted | complete | false/true | eligible for root delivery |
| accepted | partial | false | software stays accepted; docs visibly partial |
| accepted | partial/incomplete | true | root incomplete with exact missing docs |
| rejected | any | any | rejected remains rejected |
| blocked/unknown | prose says complete | any | blocked/unknown remains unchanged |

Neither the renderer nor substrate may write any of these states. Corpus
assembly writes documentation evidence; the lineage completion reader derives
the documentation and root states from the contract, verified receipt and exact
missing inventory.

## 10. Product Documentation Inside The Candidate

Documentation files declared as product artifacts are ordinary build work:

```text
declared before materialization
written through repository hands
included in the candidate seal
covered by QA
charged as work
```

They are not the lineage corpus. Final QA, failed ancestors, cumulative
economics and root delivery happen after the candidate seal and remain in the
lineage archive. The lineage renderer has no authority to patch candidate files.

## 11. Writer And Reader Contract

| Record | Sole writer | First named reader | Effect reader |
|---|---|---|---|
| bound documentation contract | trusted root binder | contract validator | documentation transaction |
| documentation cost event | effect/economy boundary | economy charger | lineage budget/report |
| economy state | pure charger result committed by lineage | economy assessor | corpus transaction |
| economy assessment | pure assessor committed by lineage | corpus assembler | completion reader |
| documentation product status | corpus/export verifier | lineage completion reader | delivery/report |
| missing documentation requirement | completion reader | lineage runner/report | continuation/terminal policy |

No writer may also invent its reader's verdict.

## 12. Failure Law

| Failure | Class | Required behavior |
|---|---|---|
| malformed declaration | trusted contract/world error | loud before birth |
| unknown profile | contract error | no fallback |
| optional cap exhausted | typed auxiliary outcome | partial; preserve software result |
| required cap exhausted | typed root requirement failure | exact missing items |
| provider usage unavailable | epistemic/economy condition | estimated or narration denied |
| renderer exception | host/effect failure | loud transaction failure; required remains incomplete |
| untagged docs call | accounting invariant failure | reject implementation/event |
| docs alter Packet route/death | body invariant violation | reject implementation |
| full lacks structured source | provenance invariant failure | reject product |
| required full lacks human projection | requirement failure | never mark complete |

Host/runtime exceptions remain host failures. They are not translated into a
graceful Packet death.

## 13. Permanent Matched Controls

Minimum permanent tests:

```text
D0 absent declaration equals explicit off for the whole Packet life
D1 off versus structured leaves route/ticks/local budget/loss/death/candidate identical
D2 structured export uses zero substrate calls
D3 structured versus full with narration disabled has identical structured evidence closure and structured_content_id; contract/export envelopes may differ
D4 narration changes only projection/cost, never candidate or structured corpus
D5 low versus high docs cap leaves the observed Packet history identical
D6 optional partial docs preserve accepted software
D7 required partial docs block only root delivery with exact requirement
D8 substrate cannot widen profile or cap
D9 renderer cannot write software acceptance
D10 documentation cost survives generation birth in lineage totals
D11 one physical action is never charged twice
D12 documentation steps never enter Packet-local mortality
D13 candidate_repository placement is rejected
D14 full+required fails when the declared human projection is incomplete
D15 malformed/duplicate cost events fail or remain idempotent as specified
```

Every Packet-isolation test compares:

```text
walk
committed/executed edge ledger
Packet-local steps
loss
revision vector
substrate calls used by body
candidate bytes/digest
death/status
```

## 14. Implementation Sequence

```text
P0 implement pure contract binding/validation
P1 implement pure documentation economy state/charge/assessment
P2 grow unit controls for malformed contracts and cost attribution
P3 bind explicit structured contract to an in-memory lineage fixture
P4 consume observer snapshots without writing files
P5 record documentation costs in lineage economics only
P6 run off/structured Packet ablation
P7 connect verified corpus receipt to lineage completion
P8 add deterministic human projection
P9 consider bounded substrate narration in a separate promotion
```

Each phase is independently revertible. No phase changes router authority.

## 15. Promotion Gate

The profile/economy slice may become lineage authority only when:

```text
all contract errors are loud before Packet birth
structured profile requires zero substrate calls
all documentation costs are scoped and cumulative
Packet-local mortality ablation is exact
optional and required failures remain distinct
software acceptance cannot be written by documentation
full depends mechanically on verified structured source
every stored status has the named reader above
```

Until then, documentation assessments are shadow/report evidence and cannot
block root delivery in production authority.

## 16. Deferred

```text
automatic profile selection from task semantics
custom profiles/plugins
adaptive pricing or refunds
remote publishing
rich TUI replay
persistent same-lineage resume
documentation-only recovery generations
`qa-check.v0` schema and QA execution authority
substrate narration authority
router pressure from documentation
```

The first executable target remains one explicit `structured` contract over one
in-memory lineage with zero narration and exact observer ablation.
