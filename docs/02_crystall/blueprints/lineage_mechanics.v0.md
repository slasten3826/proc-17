# Lineage Mechanics Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/lineage_mechanics_yellowprint.v0.md
depends on Packet Body Physics and Operator Tree Physics blueprints
implementation target for one task across mortal Packet generations
code not changed by this document
```

## 1. Scope

This blueprint manifests the outer proc-17 engine that continues an unfinished
task after one Packet body becomes terminal.

It defines:

```text
lineage identity and state
generation transaction
canonical corpse record
manifest/recovery carriers
NETWORK@▽ ingress
body-owned continuation evaluation
cumulative lineage economics
grave/compost/history attachment
substrate-session continuity contract
lineage ledger, recovery, and tests
```

The lineage runner is core proc-17 mechanics. CLI, TUI, and repository hands are
clients of it.

## 2. Hard Boundary Laws

```text
one Packet = one mortal body and one Tree life
one lineage = one continuing task ancestry
Packet identity never crosses a terminal boundary
parent CALM, relations, momentum, route position, and local ledgers never copy
one automatic child maximum per corpse in v0
one living Packet maximum per lineage in v0
lineage continuation is not ☲ CYCLE
NETWORK@▽ is ingress machinery, not an operator or edge
substrate wording does not own continuation or completion
reincarnation does not reset cumulative economics
```

## 3. Target Files

```text
runtime/lineage.lua               NEW: lineage state and append-only ledger
runtime/lineage_budget.lua        NEW: cumulative allocation/accounting
runtime/corpse.lua                NEW: terminal Packet projection and hash
runtime/carrier.lua               NEW: bounded manifest/recovery carrier
runtime/network_ingress.lua       NEW: carrier validation and FLOW input
runtime/completion.lua            NEW: mode-specific body-owned completion
runtime/lineage_runner.lua        NEW: outer generational state machine
runtime/session_memory.lua        lineage index, atomic persistence, history view
runtime/packet_memory.lua         canonical corpse references/migration
runtime/grave.lua                 corpse input and history projection integration
core/digest.lua                   NEW: canonical SHA-256 record digest
substrates/contract.lua           declared substrate-session metadata
substrates/session.lua            NEW: optional explicit context owner
core/packet.lua                   consume T1 generation identity
tests/test_lineage.lua            NEW
tests/test_lineage_budget.lua     NEW
tests/test_carrier.lua            NEW
tests/test_network_ingress.lua    NEW
tests/test_lineage_runner.lua     NEW
tests/test_session_memory.lua     storage/session isolation
tests/run.lua                     register suites
```

## 4. Storage Layout

All persistent state remains under the proc-17 sandbox.

```text
sandbox/sessions/<session_id>.json
sandbox/lineages/<lineage_id>.json
sandbox/corpses/<corpse_id>.json
sandbox/carriers/<carrier_id>.json
sandbox/packets/<packet_id>.json       compatibility capsules
```

Rules:

```text
safe-id validation applies to every path component
symlink-safe sandbox resolution is required before live repository hands
write temporary file, flush/close, then atomic rename for lineage/session state
corpses and carriers are create-once; an existing different hash is an error
lineage/session files may update only through their owning modules
```

The exact filesystem backend may later change. Identity, atomicity, and sandbox
laws may not.

### 4.1 Canonical hashing

`core/json.lua` already emits object keys in stable sorted order. Add:

```lua
digest.sha256(text) -> lowercase_hex
digest.record(value, options) -> lowercase_hex
```

`digest.record` deep-projects the declared identity fields, encodes them with
`core/json.lua`, and hashes the result with SHA-256 implemented in Lua 5.4 or a
verified bundled implementation. It must not shell out.

Hash laws:

```text
corpse hash excludes corpse_hash itself
carrier hash excludes carrier_hash itself
storage path, save time, and mutable session metadata are excluded
frozen_at comes from the existing Packet terminal event, not capture wall time
carrier created_at comes from the prepared boundary transaction event
array order is semantic and preserved
map key order is canonical JSON order
same source transaction must reproduce the same digest
```

Ids are allocated once in the lineage transaction and included in the hashed
record. A digest does not allocate identity by itself.

## 5. Lineage State

Target module:

```text
runtime/lineage.lua
```

### 5.1 Root shape

```lua
{
  kind = "proc17_lineage",
  protocol_version = "lineage.v0",
  lineage_id = string,
  session_id = string,
  label = string | nil,
  status = "created" | "running" | "evaluating_terminal"
        | "continuing" | "suspended" | "complete"
        | "exhausted" | "terminated",
  work_mode = "plan" | "build",
  completion_contract_id = string,
  task = {
    task_id = string,
    payload = any | nil,
    input_ref = string | nil,
    input_hash = string,
    payload_bytes = integer,
    media_type = string,
    content_truth_status = string,
  },
  created_at = number,
  updated_at = number,

  current_generation = integer,
  current_packet_id = string | nil,
  current_corpse_id = string | nil,
  current_carrier_id = string | nil,
  substrate_session_id = string | nil,

  generations = table,
  ledger = table,
  budget = table,
  policy = table,
  terminal = table | nil,
}
```

### 5.2 Policy

```lua
policy = {
  history_enabled = boolean,
  persistence_enabled = boolean,
  allow_recovery = boolean,
  allow_fresh_substrate_fallback = boolean,
  packet_budget = table,
  carrier = {
    max_bytes = integer,
    allowed_media_types = table,
  },
  emergency_max_generations = integer | nil,
}
```

`carrier.max_bytes` is required for automatic continuation. It has no hidden
default in v0.

At `created`, `current_generation = 0`. A prepared generation number does not
become current until `commit_birth` succeeds.

Exactly one of `task.payload` or `task.input_ref` is required. The original task
is bounded by an explicit ingress policy and hashed before the first birth.

### 5.3 Generation entry

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

Entries append in generation order. Existing entries are never rewritten except
to fill their own terminal refs exactly once.

## 6. Lineage API

```lua
lineage.create(task, options) -> state | nil, err
lineage.append_event(state, event) -> stored | nil, err
lineage.begin_generation(state, allocation) -> transaction | nil, err
lineage.commit_birth(state, transaction, packet) -> entry | nil, err
lineage.register_corpse(state, corpse) -> entry | nil, err
lineage.set_status(state, status, source) -> state | nil, err
lineage.finish(state, terminal) -> state | nil, err
lineage.validate(state) -> true | nil, err
```

Only `runtime/lineage.lua` writes lineage status, generation, refs, and ledger.

## 7. Ledger Event

```lua
{
  id = string,
  kind = string,
  lineage_id = string,
  generation = integer | nil,
  packet_id = string | nil,
  corpse_id = string | nil,
  carrier_id = string | nil,
  transaction_key = string | nil,
  payload = table,
  source_refs = table,
  event_truth_status = "runtime_confirmed",
  content_truth_statuses = table,
  time = number,
}
```

Required kinds:

```text
lineage_created
generation_allocated
ingress_accepted
generation_born
packet_terminal
corpse_registered
grave_classified
history_projected
continuation_evaluated
carrier_built
carrier_selected
lineage_budget_spent
continuation_decided
substrate_session_changed
lineage_suspended
lineage_completed
lineage_exhausted
lineage_terminated
transaction_recovered
```

Continuation evaluation records every considered outcome and exclusion, not
only the selected result.

## 8. Canonical Corpse

Target:

```text
runtime/corpse.lua
```

### 8.1 API

```lua
corpse.capture(dead_packet, options) -> corpse | nil, err
corpse.hash(record) -> string
corpse.save(record, options) -> record, path | nil, err
corpse.load(corpse_id, options) -> record | nil, err
```

### 8.2 Shape

```lua
{
  kind = "proc17_corpse",
  protocol_version = "corpse.v0",
  corpse_id = string,
  corpse_hash = string,
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
  trace_tail = table,
  completion_evidence_refs = table,
  frozen_at = number,
  truth_status = "runtime_confirmed",
}
```

Capture preconditions:

```text
Packet status is dead
T1 terminal record exists
Packet identity and terminal cause agree
trace contains matching terminal event
```

The corpse is a bounded immutable record, not a serialized living body. It does
not contain mutable `field`, CALM, active relations, momentum, or runtime
objects.

`packet_memory.capsule` remains a compatibility/archive format until callers
migrate to corpse records.

## 9. Carrier Contract

Target:

```text
runtime/carrier.lua
```

### 9.1 API

```lua
carrier.from_manifest(corpse, assessment, options) -> carrier | nil, err
carrier.from_recovery(corpse, assessment, options) -> carrier | nil, err
carrier.with_external_input(corpse, input, options) -> carrier | nil, err
carrier.validate(record, lineage) -> true | nil, err
carrier.hash(record) -> string
carrier.save(record, options) -> record, path | nil, err
```

### 9.2 Shape

```lua
{
  kind = "proc17_lineage_carrier",
  protocol_version = "carrier.v0",
  carrier_id = string,
  carrier_hash = string,
  lineage_id = string,
  source_packet_id = string,
  source_corpse_id = string,
  source_generation = integer,
  target_generation = integer | nil,
  carrier_class = "manifest" | "recovery" | "external_resume",
  media_type = string,
  payload = any,
  payload_bytes = integer,
  source_refs = table,
  semantic_truth_status = string,
  applicability_truth_status = "reentry_proposal" | "not_evaluated",
  materialization_loss = table,
  substrate_session_id = string | nil,
  created_at = number,
}
```

### 9.3 Deterministic v0 payload

No LLM call is permitted during carrier construction.

For structured recovery use:

```lua
{
  original_task_ref = string,
  manifest = table | nil,
  residue = table,
  remaining_work = table,
  artifact_refs = table,
  evidence_refs = table,
  source_generation = integer,
}
```

Warning grave material is attached through history, not injected as an
untyped command inside carrier payload.

If the deterministic payload exceeds `max_bytes`:

```text
do not truncate silently
return carrier_too_large with measured size
allow only an explicit projection policy that records omissions and loss
```

### 9.4 Loss ownership

```text
manifest carrier: △ paid Packet materialization loss before death;
                  lineage pays serialization/transport economics
recovery carrier: lineage records projection loss/economics;
                  dead Packet loss ledger remains untouched
```

## 10. NETWORK@▽ Ingress

Target:

```text
runtime/network_ingress.lua
```

API:

```lua
network_ingress.prepare(lineage, carrier, options) -> birth_input | nil, err
```

Output:

```lua
{
  flow = {
    kind = "flow_ingress",
    birth_kind = "network_reentry" | "recovery",
    payload = carrier.payload,
    media_type = carrier.media_type,
    source_refs = {carrier.carrier_id},
    content_truth_status = carrier.semantic_truth_status,
  },
  packet_options = {
    lineage_id = lineage.lineage_id,
    generation = carrier.target_generation,
    parent_id = carrier.source_packet_id,
    parent_corpse_id = carrier.source_corpse_id,
    birth_kind = carrier.carrier_class == "recovery" and "recovery"
      or "network_reentry",
    carrier_id = carrier.carrier_id,
    substrate_session_id = carrier.substrate_session_id,
  },
}
```

Validation:

```text
lineage ids match
source corpse exists and hash/reference matches
source generation equals current generation
target generation equals current generation + 1
carrier class/media type permitted by policy
payload hash and byte bound match
lineage budget can allocate birth
```

Only `flow.payload` enters semantic CHAOS. Envelope metadata enters immutable
Packet identity/provenance.

## 11. Completion Contract

Amendment 2026-07-19: the ambiguous `recoverable` field in this pre-runtime
schema is superseded by `terminal_recoverable` plus the separate continuation
evaluation in section 12. See
[`lineage_completion_continuation_separation.v0.md`](lineage_completion_continuation_separation.v0.md).

Target:

```text
runtime/completion.lua
```

API:

```lua
completion.evaluate(lineage, corpse, options) -> assessment | nil, err
```

Assessment:

```lua
{
  kind = "lineage_completion_assessment",
  contract_id = string,
  task_state = "complete" | "unfinished" | "blocked"
             | "unsafe" | "unknown",
  progress = table,
  remaining_work = table,
  evidence_refs = table,
  manifest_refs = table,
  missing_requirements = table,
  terminal_recoverable = boolean,
  terminal_recovery_basis = string | nil,
  event_truth_status = "runtime_confirmed",
  basis_truth_statuses = table,
}
```

### 11.1 Plan v0

`plan.v0` may classify complete when:

```text
manifest contains the requested plan/spec artifact
body progress has no declared remaining structural work
latest applicable validation is not rejected
```

The assessment event is confirmed. Plan content remains semantic proposal.

### 11.2 Build v0

`build.v0` requires:

```text
no declared remaining work
manifest references an artifact
all required capability effects have fresh successful evidence
latest logic verdict is accepted
no unsafe or rejected effect remains unresolved
```

Substrate text such as "done", Packet death cause `complete`, or non-empty code
alone is insufficient.

Exact task-specific requirements enter through a versioned completion contract,
not a prompt interpreted by the lineage runner.

## 12. Continuation Evaluation

```lua
lineage_runner.evaluate_continuation(lineage, corpse, assessment, context)
  -> decision | nil, err
```

Decision:

```lua
{
  kind = "lineage_continuation_decision",
  outcome = "complete" | "continue" | "suspend_needs_input"
          | "lineage_budget_exhausted" | "terminate_unsafe"
          | "blocked_no_carrier" | "cancelled" | "suspend_unknown",
  source_corpse_id = string,
  assessment_ref = string,
  candidate_outcomes = table,
  exclusions = table,
  carrier_class = string | nil,
  carrier_id = string | nil,
  budget_snapshot_ref = string,
  reason = string,
  event_truth_status = "runtime_confirmed",
  basis_truth_statuses = table,
}
```

Deterministic order:

```text
unsafe/cancelled policy
completion contract
external requirement/block
lineage affordability
recovery permission
carrier viability
continue
```

This order is lifecycle filtering, not semantic CHOOSE.

## 13. Cumulative Economics

Target:

```text
runtime/lineage_budget.lua
```

### 13.1 Shape

```lua
{
  limits = table,
  spent = table,
  remaining = table,
  events = table,
  exhausted = boolean,
  exhausted_keys = table,
}
```

Axes:

```text
steps
substrate_calls
prompt_tokens
completion_tokens
total_tokens
estimated_tokens
tool_calls
file_writes
test_runs
time_ms
money_units
generations
carrier_bytes
```

Each configured axis is either a non-negative number or the literal string
`"unlimited"`. A missing required axis is invalid; Lua `nil` is not used to
encode an explicit unlimited decision.

### 13.2 API

```lua
lineage_budget.init(lineage, limits) -> budget
lineage_budget.allocate_packet(lineage, requested) -> allocation | nil, err
lineage_budget.charge(lineage, input) -> event | nil, err
lineage_budget.reconcile_packet(lineage, corpse) -> payload | nil, err
lineage_budget.snapshot(lineage) -> snapshot
lineage_budget.can_continue(lineage, requested) -> boolean, reasons
```

Deduplication key:

```text
source packet budget event id
or lineage boundary transaction event id
```

The same cost cannot be charged once during execution and again at corpse
reconciliation.

Allocation:

```text
each finite local axis <= finite lineage remaining axis
generation charge happens only after successful birth commit
failed birth may charge real attempted I/O/time, but not generation count
```

Packet identity loss resets with new identity. Carrier loss remains in carrier
fidelity and lineage audit; it is not converted into cumulative Packet loss.

## 14. Session, Grave, And History

Extend session shape:

```lua
{
  ...current session fields...,
  lineage_ids = table,
  current_lineage_id = string | nil,
  grave = table,
  compost = table,
}
```

Default:

```text
fresh run -> fresh session -> fresh lineage -> empty grave/compost
```

After corpse registration:

```text
classify real corpse
add grave to this session only
run explicit/threshold compost policy when configured
record both operations in lineage ledger
```

Before newborn FLOW:

```lua
session_memory.project_history(session, lineage, options) -> history_view
```

Projection:

```lua
{
  warnings = table,
  bequests = table,
  neutral = table,
  compost = table,
  source_session_id = string,
  projected_at = number,
  truth_status = "runtime_confirmed",
}
```

`history_enabled=false` attaches an empty view but does not disable lineage
ledger, active corpse registration, or cumulative economics.

Readers after T2:

```text
warning -> ☱ derives matching resistance
bequest -> ☰ relates current refs; ☱ derives matching help
compost -> weak foundation/history contribution
router reads only resulting Packet-local pressure
```

## 15. Substrate Session

Target optional module:

```text
substrates/session.lua
```

API:

```lua
substrate_session.create(adapter, options) -> session
substrate_session.ask(session, call, options) -> response | nil, err
substrate_session.snapshot(session) -> metadata
substrate_session.switch(session, adapter, reason) -> event | nil, err
```

Metadata:

```lua
{
  substrate_session_id = string,
  provider = string,
  model = string,
  adapter_version = string,
  context_handle = string | nil,
  visible_message_refs = table,
  usage = table,
  context_limit = number | nil,
  compaction_state = table,
}
```

Rules:

```text
fresh proc-17 session starts fresh substrate context by default
lineage generations may reuse one explicit substrate session
provider/model/context switch is a lineage event
usage is charged to lineage budget
same handle confirms transport identity only
remembered meaning is measured through re-entry experiments
```

No automatic context compaction enters v0 before the memoris ablation.

## 16. Lineage Runner

Target:

```text
runtime/lineage_runner.lua
```

### 16.1 API

```lua
lineage_runner.run(task, substrate, options) -> lineage, result | nil, err
lineage_runner.resume(lineage_or_id, substrate, input, options)
  -> lineage, result | nil, err
```

Injectable dependencies for tests:

```lua
options.packet_runner = function | nil
options.clock = function | nil
options.id_source = function | nil
options.storage = table | nil
```

Production default Packet runner is the promoted T2 tension runner.

### 16.2 Result

```lua
{
  kind = "lineage_runner_result",
  lineage_id = string,
  session_id = string,
  status = string,
  generations = integer,
  packet_results = table,
  corpse_ids = table,
  carrier_ids = table,
  budget = table,
  terminal = table | nil,
  ledger_tail = table,
}
```

### 16.3 Main transaction

```text
create/load lineage and session
allocate generation candidate without incrementing committed count
prepare user FLOW or NETWORK@▽ input
construct and commit newborn Packet
attach bounded history
run one Packet life
require terminal Packet; capture and register corpse
reconcile cumulative economics
classify/store grave and optional compost
evaluate completion and continuation candidates
if terminal: finalize lineage and return
if suspended: persist resume contract and return
if continue: build/save carrier, commit decision, repeat
```

The outer loop condition is lineage state, not `while true` plus a host tick
limit.

## 17. Idempotent Boundary Transaction

Transaction key:

```text
<lineage_id>:<source_corpse_id-or-birth>:<target_generation>
```

States:

```text
prepared
carrier_saved
birth_committed
closed
failed
```

Rules:

```text
same key + same hashes resumes the incomplete transaction
same key + different carrier/Packet hash is ancestry corruption
generation increments only at birth_committed
one committed key cannot create another child
crash after corpse save but before carrier save resumes from corpse
crash after child save but before lineage save discovers child by transaction key
```

V0 may use a write-ahead event in the lineage file plus create-once artifact
files. It does not require a database.

## 18. Lineage Terminal Outcomes

```lua
terminal = {
  outcome = "complete" | "exhausted" | "suspended"
          | "unsafe" | "cancelled" | "no_carrier" | "invalid",
  final_packet_id = string | nil,
  final_corpse_id = string | nil,
  final_manifest_ref = string | nil,
  evidence_refs = table,
  reason = string,
  time = number,
  truth_status = "runtime_confirmed",
}
```

`suspended` is non-running but resumable through an explicit external event.
Whether re-funding an exhausted lineage resumes it or creates another lineage is
OPEN; v0 does not silently resume.

## 19. Two Recurrences Test

The runner must prove the scale split:

```text
☲ tick:
  same packet_id
  same generation
  one local step cost

lineage continuation:
  parent is terminal
  new packet_id
  generation +1
  carrier and birth costs
  no topology edge named NETWORK
```

Any test where ☲ increments generation or continuation appears in a Packet
route is a failure.

## 20. Writer-Reader Closure

| Written record | Writer | Required reader and read moment |
|---|---|---|
| task descriptor | lineage constructor | first FLOW, completion evaluator, and carrier builder |
| lineage header/policy | lineage module | runner and budget guard at every boundary transaction |
| generation allocation | lineage budget/module | Packet constructor and birth commit before execution |
| generation entry | lineage module | ancestry validator, session index, audit |
| Packet terminal ref | Packet runner/lineage ledger | corpse capture immediately after life |
| canonical corpse | corpse module | grave classifier, completion evaluator, carrier builder |
| grave classification | grave/session runtime | history projector and compost |
| compost pattern | session memory | bounded foundation/history projector at later birth |
| history projection | session/lineage boundary | newborn T1 history attachment, then ☰/☱ |
| completion assessment | completion module | continuation evaluator in same terminal transaction |
| continuation candidates/decision | lineage runner | state machine and audit before child/terminal outcome |
| carrier | carrier module | NETWORK@▽ only after accepted continuation |
| cumulative cost/allocation | lineage budget | continuation guard and UI/audit after each event |
| substrate-session metadata | substrate session | adapter, budget accounting, and ablation logger |
| transaction state | lineage module | crash recovery before any repeated boundary write |
| lineage terminal | lineage module | CLI/TUI/machine caller and session index |
| lineage ledger | all lineage authorities through lineage module | recovery, tests, audit/UI; never Packet router directly |

Every create-once writer must prove that its reader can resume from the stored
record without mutating it.

## 21. Implementation Order

### Phase A: identity, corpse, carrier

```text
consume T1 generation fields
capture a real terminal Packet as canonical corpse
build deterministic carrier
validate NETWORK@▽ birth input
do not loop automatically yet
```

### Phase B: lineage state and fake Packet runner

```text
implement lineage ledger and cumulative budget
run two deterministic fake generations
prove completion/no-child and unfinished/one-child cases
prove idempotent crash recovery
```

### Phase C: current memory stack

```text
register graves from canonical corpses
attach bounded history per session policy
connect warning/bequest/compost only through T1/T2 named readers
```

### Phase D: real Packet runner

```text
wrap promoted T2 runner
run multi-generation artifact task with fake substrate
then run live DeepSeek plan/build tasks
```

### Phase E: substrate continuity experiment

```text
add explicit substrate-session adapter
run same-session/fresh-session/different-substrate/body-memory ablation
do not compact context before results
```

## 22. Required Unit Tests

### Identity and corpse

```text
first generation has no parent and generation=1
child has new id, generation+1, exact parent/corpse/carrier refs
corpse capture requires dead Packet and matching terminal trace
corpse contains no living field/CALM/momentum/runtime tables
corpse create-once hash collision is rejected
```

### Carrier and ingress

```text
carrier construction is deterministic for same corpse/options
oversize carrier fails without silent truncation
recovery loss does not mutate dead Packet
NETWORK rejects wrong lineage/generation/corpse/hash
only payload enters FLOW semantic input
NETWORK never appears in topology trace
```

### Completion and economics

```text
plan semantic artifact can complete while content remains proposal
build substrate saying done without fresh evidence is unfinished/unknown
fresh successful evidence plus no remaining work completes build
local Packet budget resets; cumulative spend does not
duplicate packet event reconciliation does not double-charge
unaffordable birth does not increment generation
```

### Runner and recovery

```text
complete first generation creates no child
unfinished recoverable generation creates exactly one child
unsafe/unknown/no-carrier does not create hidden child
crash at each boundary transaction state resumes idempotently
one corpse cannot create two automatic children
suspended lineage resumes only with explicit event
☲ never affects generation
```

### Session history

```text
fresh session has empty history
another session graves never attach
history disabled still retains mandatory active lineage ledger
warning/bequest effects are derived by readers, not stored as route commands
compost record loses individual corpse identity
```

## 23. Integration And Ablation Tests

### Generation integrity

```text
Packet_1 -> corpse_1 -> carrier_1 -> Packet_2
all refs/hashes/generations agree
Packet_2 has no copied parent CALM/relations/momentum/local ledgers
```

### Economics integrity

```text
two children each receive local allocation
lineage totals equal unique Packet events plus unique boundary events
lineage exhaustion prevents another birth without host generation ceiling
```

### Re-entry matrix

```text
A same carrier + same live substrate session + body memory
B same carrier + fresh substrate session + body memory
C same carrier + different substrate + body memory
D same live substrate session + empty body memory
E fresh substrate session + empty body memory
```

Measure completion, generations, ticks/routes, tokens/time/tools, repeated
failures, carrier loss/size, and external interventions.

### Complex task

```text
one real multi-file coding task
multiple Packet generations
sandbox artifacts persist by external references
tests execute and produce fresh evidence
final generation satisfies build completion contract
no manual replanning between generations
```

Compare with raw substrate and fixed-loop control after proc-17 succeeds on its
own terms.

## 24. Explicitly Open

```text
task-specific completion contract compiler
default lineage limits and Packet allocation policy
minimum sufficient carrier projection
automatic recovery policy by death cause
grave/compost relevance matching
compost-to-foundation strength and decay
same-lineage semantics after explicit re-funding
provider-specific context handles and local-model KV continuity
context compaction after memoris ablation
branching and subordinate Packet lineages
long-term corpse/lineage retention and compost above session scale
```

No open row may become an undocumented default.

## 25. Acceptance

T3 is manifested correctly when:

```text
the lineage runner is a tested core module independent of CLI/TUI
every generation is a new Packet identity born only after parent terminality
corpses and carriers are immutable, hashed, bounded, and sandboxed
NETWORK@▽ performs ingress without becoming an operator
completion and continuation are body-owned and auditable
cumulative economics cannot be reset by rebirth
grave, compost, and substrate continuity remain three distinct channels
every lineage write has a named reader and ledger event
boundary crash recovery cannot duplicate children or spending
the two-generation fake test, re-entry ablation, and real multi-generation task pass
all existing Packet, mortality, grave, compost, and Tree tests remain green
```
