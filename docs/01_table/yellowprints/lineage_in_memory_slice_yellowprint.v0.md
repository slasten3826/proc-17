# In-Memory Lineage Slice Yellowprint v0

Status:

```text
table
source chaos: docs/00_chaos/lineage_in_memory_reconciliation_notes_2026-07-19.md
amends: docs/01_table/yellowprints/lineage_mechanics_yellowprint.v0.md
scope: first linear in-memory lineage, no persistence or hands
```

## 1. Fixed Decisions

```text
T0  lineage runner is core proc-17 mechanics
T1  one Packet remains one mortal Tree life
T2  lineage continuation is outside topology and never ☲
T3  NETWORK@▽ validates ingress but is not an operator
T4  Packet identity never crosses a terminal boundary
T5  v0 is linear: one living Packet, zero/one automatic child per corpse
T6  exact plan assessment/manifest, not pending-work relabelling, completes plan.v0
T7  cumulative economics survive every birth
T8  in-memory ledger is mandatory even when persistence is disabled
T9  carrier construction is deterministic and has no substrate call
T10 harness invariant failure remains loud and produces no synthetic corpse
```

## 2. Scope Matrix

| Surface | First slice | Deferred |
|---|---:|---:|
| Shared L1 `flow_domain` | yes | replacement policies |
| Packet generation identity | yes | branching |
| Lineage state/ledger | yes | disk transaction recovery |
| Cumulative budget | yes | pricing calibration/refunding |
| Canonical SHA-256 corpse/carrier identity | yes | persistent object store |
| Plan completion | yes | build/task-specific contracts |
| Recovery after local death | yes | semantic compaction |
| Session grave attachment | yes | general bequest/compost reader |
| Substrate context continuity | declared id only | provider session owner |
| Repository hands | no | capability sandbox sprint |

## 3. Lineage Root

```lua
{
  kind = "proc17_lineage",
  protocol_version = "lineage.in_memory.v0",
  lineage_id = string,
  session_id = string,
  status = "created" | "running" | "evaluating_terminal"
        | "continuing" | "suspended" | "complete"
        | "exhausted" | "terminated",
  work_mode = "plan" | "build",
  completion_contract_id = "plan.v0" | string,
  task = {
    task_id = string,
    payload = string,
    input_hash = sha256,
    payload_bytes = integer,
    media_type = "text/plain",
    content_truth_status = string,
  },
  current_generation = integer,
  current_packet_id = string | nil,
  current_corpse_id = string | nil,
  current_carrier_id = string | nil,
  substrate_session_id = string | nil,
  generations = generation_entry[],
  ledger = lineage_event[],
  budget = lineage_budget,
  policy = table,
  continued_corpses = {[corpse_id]=carrier_id},
  terminal = table | nil,
}
```

`current_generation=0` before first committed birth.

## 4. Generation Entry

```lua
{
  generation = integer,
  packet_id = string,
  parent_packet_id = string | nil,
  parent_corpse_id = string | nil,
  ingress_carrier_id = string | nil,
  corpse_id = string | nil,
  terminal_kind = string | nil,
  substrate_session_id = string | nil,
  local_budget_allocation = table,
  born_event_id = string,
  terminal_event_id = string | nil,
}
```

Only the terminal fields of the same entry may be filled once after birth.

## 5. Lineage Event

```lua
{
  id = "lineage-event:<n>",
  kind = string,
  lineage_id = string,
  generation = integer | nil,
  packet_id = string | nil,
  corpse_id = string | nil,
  carrier_id = string | nil,
  transaction_key = string | nil,
  payload = table,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_statuses = string[],
  time = number,
}
```

First-slice event kinds:

```text
lineage_created
generation_allocated
generation_born
packet_terminal
corpse_registered
grave_classified
lineage_budget_spent
completion_evaluated
carrier_built
continuation_decided
lineage_completed
lineage_suspended
lineage_exhausted
lineage_terminated
```

Every status change names the event that justified it.

## 6. Birth Transaction

| Phase | State before | Writer | Effect |
|---:|---|---|---|
| 1 | created/continuing | lineage budget | validate local allocation, append `generation_allocated` |
| 2 | allocation prepared | user ingress or NETWORK@▽ | produce prompt + immutable Packet options |
| 3 | Packet constructed | tension runner trusted hook | commit generation entry and charge generation |
| 4 | running | Packet runner | execute one complete mortal life |
| 5 | dead Packet | corpse module | capture immutable corpse |

Trusted one-life hook:

```lua
options.on_packet_birth(instance, birth_receipt) -> true | nil, err
```

It runs after Packet/budget/loss construction and before FLOW. It may register
identity; it may not route or mutate the Packet.

## 7. Corpse Schema

```lua
{
  kind = "proc17_corpse",
  protocol_version = "corpse.v0",
  corpse_id = string,
  corpse_hash = sha256,
  lineage_id = string,
  packet_id = string,
  generation = integer,
  parent_corpse_id = string | nil,
  terminal_kind = "manifest" | "internal_death",
  death_cause = string,
  manifest = table | nil,
  residue = table,
  final_loss = table,
  final_budget = table,
  terminal_trace_ref = string,
  trace_tail = table[],
  completion_evidence_refs = string[],
  frozen_at = number,
  truth_status = "runtime_confirmed",
}
```

Identity projection excludes `corpse_hash`. `trace_tail` is explicitly bounded.
No live Packet area enters this record.

## 8. Carrier Schema

```lua
{
  kind = "proc17_lineage_carrier",
  protocol_version = "carrier.v0",
  carrier_id = string,
  carrier_hash = sha256,
  lineage_id = string,
  source_packet_id = string,
  source_corpse_id = string,
  source_generation = integer,
  target_generation = integer,
  carrier_class = "recovery",
  media_type = "application/vnd.proc17.recovery+json",
  payload = {
    original_task = string,
    prior_manifest = table | nil,
    residue = table,
    remaining_work_count = integer | nil,
    source_generation = integer,
  },
  payload_bytes = integer,
  source_refs = string[],
  semantic_truth_status = string,
  applicability_truth_status = "reentry_proposal",
  materialization_loss = table,
  substrate_session_id = string | nil,
  created_at = number,
}
```

`payload_bytes = #json.encode(payload)`. `payload_bytes > max_bytes` returns
typed `carrier_too_large` and cannot birth a child.

## 9. NETWORK@▽ Output

```lua
{
  prompt = canonical_json(carrier.payload),
  packet_options = {
    lineage_id = lineage.lineage_id,
    generation = carrier.target_generation,
    parent_id = carrier.source_packet_id,
    parent_corpse_id = carrier.source_corpse_id,
    birth_kind = "recovery",
    carrier_id = carrier.carrier_id,
    substrate_session_id = carrier.substrate_session_id,
    work_mode = lineage.work_mode,
  },
  source_refs = {carrier.carrier_id, carrier.source_corpse_id},
}
```

Validation rehashes the carrier and checks lineage/source/current/target/bounds.
No `NETWORK` event enters the Packet trace.

## 10. Completion Assessment

Amendment 2026-07-19: the original first-slice schema below combined intrinsic
terminal recoverability with lineage policy. That field is superseded by
[`lineage_completion_continuation_separation_yellowprint.v0.md`](lineage_completion_continuation_separation_yellowprint.v0.md).
The original text is retained here as the defect's archaeological source; it is
not an alternative active contract.

```lua
{
  kind = "lineage_completion_assessment",
  assessment_id = string,
  contract_id = string,
  task_state = "complete" | "unfinished" | "blocked"
             | "unsafe" | "unknown",
  progress = table,
  remaining_work = table,
  evidence_refs = string[],
  manifest_refs = string[],
  missing_requirements = string[],
  recoverable = boolean,
  event_truth_status = "runtime_confirmed",
  basis_truth_statuses = string[],
}
```

`plan.v0` complete predicate:

```text
terminal_kind=manifest and death_cause=complete
manifest.mode=plan_delivery
manifest.output.type/status=plan/complete
manifest.output.structured.protocol_version=plan.result.v0
manifest.assembly.rule/input_provenance=plan_delivery.v0/packet_state
assessment source ref exists
```

CALM work-unit status is not part of plan completion.

Recoverable first-slice predicates:

```text
budget_exhausted | identity_loss | stalled
policy.allow_recovery=true
not unsafe/cancelled
```

Active replacement:

```text
completion assessment: terminal cause -> terminal_recoverable
continuation decision: policy + lineage budget -> child eligibility
```

Unknown completion contract produces `unknown`, never an implicit complete.

## 11. Cumulative Budget

Axes:

```text
steps substrate_calls prompt_tokens completion_tokens total_tokens
estimated_tokens tool_calls file_writes test_runs time_ms money_units
generations carrier_bytes
```

Each configured limit is finite non-negative or `"unlimited"`.

```lua
{
  limits = table,
  spent = table,
  remaining = table,
  events = table,
  charged_keys = {[dedupe_key]=true},
  exhausted = boolean,
  exhausted_keys = string[],
}
```

Allocation checks only axes requested for the local Packet. Reconciliation uses
the corpse's final runtime-budget `spent` values and one key per source Packet.
Boundary charges use transaction keys. Identity loss is not a budget axis.

## 12. Runner Algorithm

```text
create session/lineage/shared flow_domain
while lineage state permits automatic work:
  prepare allocation for generation N+1
  prepare user or NETWORK ingress
  run one Packet with birth-commit hook
  require returned Packet is dead
  capture/register corpse
  append packet to session; classify/store grave
  reconcile cumulative Packet spending
  evaluate completion
  complete -> finalize lineage and return
  unsafe/unknown/exhausted -> finalize/suspend and return
  recoverable -> build/charge/select one carrier
  mark source corpse continued exactly once
  attach bounded session graves to next birth when enabled
```

The loop is lineage-state bounded. `emergency_max_generations` may stop with a
typed suspension but may not report completion.

## 13. Options

Minimum production call:

```lua
lineage_runner.run(task_string, substrate, {
  session_id = string | nil,
  work_mode = "plan",
  completion_contract_id = "plan.v0",
  flow_domain = domain | nil,
  flow_source = lua_array | nil,
  packet_budget = table,
  lineage_budget = table,
  carrier = {max_bytes = integer},
  allow_recovery = boolean,
  history_enabled = boolean,
  emergency_max_generations = integer | nil,
  packet_runner_options = table,
  id_source = function | nil,
  clock = function | nil,
  packet_runner = function | nil,
})
```

Production default `packet_runner` is `tension_runner.run`.

## 14. Invariant Failure Boundary

| Failure | Result |
|---|---|
| typed terminal Packet | capture/evaluate normally |
| carrier too large | lineage suspended/no child |
| cumulative budget cannot pay | lineage exhausted/no child |
| unknown completion | lineage suspended/no child |
| Packet runner returns live Packet | loud invariant failure |
| Packet runner Lua/error contract failure | loud error, lineage terminated; no grave fabricated |
| birth hook identity mismatch | loud invariant failure; no generation double-commit |
| same corpse requests second child | loud ancestry error |
| carrier hash/ancestry mismatch | reject NETWORK birth |

## 15. Test Matrix

### Primitive controls

```text
D0 SHA-256 known vectors and canonical record order
C0 dead Packet -> stable bounded corpse
C1 live Packet rejected
C2 corpse has no live areas or aliases
R0 recovery carrier stable hash/size
R1 oversize carrier rejected
N0 valid carrier -> exact generation-2 Packet options
N1 bad hash/lineage/generation rejected
B0 allocation cannot exceed lineage remaining
B1 Packet spending reconciles once
B2 generation/carrier charged once
```

### Lineage controls

```text
L0 exact plan completes generation 1, no child
L1 local budget death -> recovery carrier -> generation 2 completes
L2 parent/corpse/carrier ancestry exact
L3 child starts with no parent CALM/relations/operator state
L4 no NETWORK operator/event in Packet trace
L5 ☲ does not change generation
L6 cumulative budget spans both generations
L7 source corpse cannot generate duplicate child
L8 carrier oversize suspends visibly
L9 plan content remains semantic_proposal
L10 runner/hook invariant error remains loud
L11 history ablation changes attachment only
L12 source corpse remains final after descendant life
```

## 16. Promotion Boundary

Passing this slice proves only:

```text
proc-17 owns linear task ancestry in memory
one local death can lawfully produce one new Packet identity
one exact plan can finish the lineage
```

It does not prove persistent crash recovery, build completion, repository work,
substrate remembering, hands, CLI/TUI, or default router promotion.
