# Lineage Mechanics Yellowprint v0

Status:

```text
table
source: docs/00_chaos/full_packet_tree_physics_notes.md
companion source: docs/00_chaos/packet_lineage_reentry_architecture_notes.md
body vocabulary: docs/01_table/yellowprints/packet_body_physics_yellowprint.v0.md
tree vocabulary: docs/01_table/yellowprints/operator_tree_physics_yellowprint.v0.md
scope: one continuing task across multiple mortal Packet bodies
crystall: docs/02_crystall/blueprints/lineage_mechanics.v0.md
```

## 0. Purpose

This table answers:

```text
how does one task process continue when every Packet body is mortal?
```

The lineage runner is proc-17 engine physics. It is not CLI/TUI convenience.

```text
Packet runner
  gives one body one life inside the 22-edge Tree

lineage runner
  gives one unfinished task a sequence of non-identical bodies
```

Without the lineage runner, generation fields are decorative, carriers have no
receiver, and Packet death still means task death.

## 1. Authority Columns

Rows use the same source classes as T1:

```text
CANON     ProcessLang boundary/operator law
DECISION  current proc-17 architecture decision
ANCESTOR  mechanism retained from Packet, Zig, UPM, or memoris work
RUNTIME   behavior already demonstrated by current proc-17 code/tests
DERIVED   assembled consequence awaiting crystall and experiment
OPEN      unresolved; code must not decide it invisibly
```

## 2. Scale Boundary

| Scale | Owns | Does not own |
|---|---|---|
| proc-17 body | reusable laws, runners, organs, storage adapters | one specific task identity |
| session | runtime room, sandbox roots, optional substrate context, local grave/compost | Packet identity |
| lineage | one continuing task ancestry, generations, cumulative economics, continuation ledger | internal operator route |
| Packet | one mortal task-shaped body and one 22-edge walk | descendants or session storage |
| corpse | immutable terminal fact and bounded readable records | mutation, routing, continuation authority |
| carrier | bounded material crossing a generational boundary | parent identity or living body state |
| substrate session | declared semantic continuity surface | body truth, Packet identity, route authority |

Default v0 relation:

```text
one fresh session
  -> one fresh lineage
  -> one living Packet at a time
```

`session_id` and `lineage_id` may initially be equal in value, but they remain
different concepts and fields.

## 3. Conceptual Lineage State

```text
R = <J, G, P, D, V, N, U, H, B, A>
```

| Symbol | Region | Meaning | Storage class |
|---|---|---|---|
| `J` | lineage identity | Stable identity of one continuing task ancestry | immutable header |
| `G` | generation registry | Ordered Packet/corpse ancestry | append-only |
| `P` | active Packet ref | At most one living Packet in linear v0 | ephemeral reference |
| `D` | corpses | Immutable terminal Packet records/capsules | append-only, retention-controlled |
| `V` | boundary carriers | Manifest or recovery projections used for ingress/output | append-only records plus external artifacts |
| `N` | continuation state | Current complete/continue/suspend/terminate decision | append-only decisions plus derived current state |
| `U` | substrate session | Provider/model/context identity and accounting | session-owned mutable runtime |
| `H` | grave/compost view | Session-scoped stored history available to births | bounded persistent storage |
| `B` | lineage economics | Cumulative costs and remaining limits across generations | append-only costs plus derived totals |
| `A` | lineage ledger | Auditable boundary decisions and provenance | append-only |

The lineage does not store a living super-Packet. It stores ancestry and the
conditions for another birth.

## 4. Authority Matrix

| Authority | May decide/write | Must not decide/write |
|---|---|---|
| Packet runner | one-life ticks, operator execution, local mortality, same-life terminalization | descendant birth, lineage completion policy, session storage |
| lineage runner | generation birth, continuation outcome, carrier selection, cumulative accounting, lineage terminal state | internal Tree route, Packet semantic mutation |
| Packet lifecycle | dead/final status, corpse source | posthumous repair or resurrection |
| △ MANIFEST | same-life materialization and terminal output candidate | next generation, NETWORK routing |
| grave classifier | warning/bequest/neutral classification from a real corpse | route, child mutation, semantic truth |
| session memory | scope, persistence, grave/compost retention | direct pressure or operator route |
| NETWORK@▽ | transport envelope validation and newborn ingress | operator role, living body export, route selection |
| substrate adapter | bounded semantic proposals and declared usage/session metadata | continuation, generation, route, runtime truth |
| external operator | task ingress, cancellation, explicit resume, policy/limit configuration | silent rewrite of body evidence |

The continuation decision is body-owned even when its evidence contains
semantic proposals.

## 5. Lineage Lifecycle

| State | Meaning | Allowed successor |
|---|---|---|
| `created` | identity and policy exist; no Packet born | `running`, `terminated` |
| `running` | exactly one Packet is alive | `evaluating_terminal` |
| `evaluating_terminal` | Packet is immutable; corpse, evidence, and output are being read | `continuing`, `complete`, `suspended`, `exhausted`, `terminated` |
| `continuing` | carrier and child allocation have been accepted | `running` after one new birth |
| `suspended` | continuation needs external fact/capability/permission | `continuing`, `terminated` by explicit event |
| `complete` | task completion contract is satisfied | terminal |
| `exhausted` | cumulative lineage economics cannot pay for continuation | no automatic successor; explicit re-funding semantics are OPEN |
| `terminated` | unsafe, cancelled, invalid, or unrecoverable lineage | terminal |

Lifecycle laws:

```text
at most one living Packet per lineage in v0
every generation reaches a terminal Packet state before a child is born
one terminal Packet can produce at most one automatic child in v0
generation increases exactly once at accepted birth
Packet death alone does not imply lineage completion
lineage completion never resurrects or edits its final corpse
```

## 6. Identity Table

### 6.1 Lineage header

| Field | Meaning | Writer | Mutation law | Current mapping | Source |
|---|---|---|---|---|---|
| `lineage_id` | Stable ancestry id for one task | lineage constructor | immutable | missing | DECISION |
| `session_id` | Runtime room owning local storage/context | CLI/TUI/session runtime | immutable reference | `session_memory.session_id` | RUNTIME |
| `completion_contract_id` | Mode/task-specific definition of done | ingress policy | immutable or explicitly versioned | missing | DERIVED |
| `work_mode` | plan/build policy | ingress | explicit recorded change only | runner option | RUNTIME |
| `created_at` | lineage creation time | lineage constructor | immutable | missing | DERIVED |
| `status` | lineage lifecycle state | lineage runner | monotonic by state machine | missing | DERIVED |
| `current_generation` | highest accepted birth ordinal | lineage runner | monotonic +1 | missing | DECISION |
| `current_packet_id` | living Packet or last terminal body ref | lineage runner | boundary transitions only | session has partial field | RUNTIME GAP |
| `substrate_session_id` | Declared continuity surface | substrate/session adapter | explicit replacement event only | missing | DECISION |

### 6.2 Generation identity

| Field | Law |
|---|---|
| `packet_id` | Unique for one mortal body |
| `generation` | Positive monotonic ordinal inside lineage |
| `parent_packet_id` | Immediate predecessor Packet or nil for first birth |
| `parent_corpse_id` | Exact corpse used at re-entry or nil for first birth |
| `birth_kind` | `user`, `network_reentry`, or explicit `recovery` |
| `carrier_id` | Carrier used for this birth or nil for direct user ingress |
| `substrate_session_id` | Declared semantic session used by this generation |

Cross-generation similarity never makes `packet_id` equal.

## 7. One Generation Transaction

| Order | Stage | Owner | Required record |
|---:|---|---|---|
| 1 | allocate generation/local budget | lineage runner | `generation_allocated` |
| 2 | validate user or NETWORK@▽ ingress | ingress boundary | `ingress_accepted` or terminal denial |
| 3 | construct newborn Packet | Packet constructor | `generation_born` plus FLOW birth event |
| 4 | attach bounded history projection | lineage/session boundary | `history_attached` with counts/refs |
| 5 | run one mortal Tree life | Packet runner | Packet trace and terminal state |
| 6 | freeze/register corpse | lifecycle + lineage runner | `corpse_registered` |
| 7 | classify grave and persist allowed records | grave/session runtime | `grave_classified`, optional `composted` |
| 8 | derive task/continuation state | lineage runner | `continuation_evaluated` with evidence refs |
| 9 | build/select re-entry carrier when continuing | carrier builder + lineage runner | `carrier_selected` and boundary cost |
| 10 | reconcile Packet and boundary spending into cumulative economics | lineage budget reader | `lineage_budget_spent` |
| 11 | birth one child or terminalize lineage | lineage runner | `continuation_decided`, then birth or terminal event |

No stage may edit the corpse to make the next stage easier.

## 8. Packet Terminal And Corpse Contract

### 8.1 Terminal kinds

| Terminal kind | Trigger | Possible lineage reading |
|---|---|---|
| `manifest_complete` | △ produced output and completion contract passed | complete; no child |
| `manifest_partial` | △ released usable partial form while work remains | bequest/continue |
| `identity_loss` | local loss capacity exhausted | warning or recoverable residue by evidence |
| `budget_exhausted` | local allocation exhausted | bequest with progress; warning without progress |
| `invalid_topology` | same-life route violated canon/lifecycle | warning or terminated defect |
| `unsafe_scope` | sandbox/safety law denied state | terminated or explicit human recovery |
| `cancelled` | external cancellation | suspended/terminated by policy |
| `stalled` | no legal/progressive physical motion, if crystallized | warning, blocked, or recovery |

### 8.2 Minimum corpse record

```lua
{
  corpse_id = string,
  lineage_id = string,
  packet_id = string,
  generation = integer,
  terminal_kind = string,
  death_cause = string,
  manifest_ref = string | nil,
  residue = table,
  final_loss = table,
  final_budget = table,
  terminal_trace_ref = string,
  completion_evidence_refs = table,
  frozen_at = number,
  truth_status = "runtime_confirmed",
}
```

Corpse laws:

```text
all Packet mutators reject it
death cause and residue are write-once
trace is sealed with a terminal digest/reference
classification and projection create new records; they do not annotate corpse
child birth references corpse but never owns or mutates it
```

## 9. Boundary Carrier Table

### 9.1 Carrier classes

| Carrier class | Source | Use | Cost ownership |
|---|---|---|---|
| `manifest` | △ output produced while Packet was alive | external result and/or next ingress | Packet pays materialization loss; lineage pays transport/storage economics |
| `recovery` | bounded projection from immutable corpse/residue after internal death | continue unfinished task | lineage pays projection/transport economics; dead Packet ledger is not rewritten |
| `external_resume` | new operator fact/capability joined to suspended lineage | resume through new birth | external provenance plus lineage economics |

### 9.2 Minimum carrier envelope

```lua
{
  kind = "proc17_lineage_carrier",
  carrier_id = string,
  lineage_id = string,
  source_packet_id = string,
  source_corpse_id = string,
  source_generation = integer,
  target_generation = integer | nil,
  media_type = string,
  payload = any,
  payload_hash = string,
  source_refs = table,
  semantic_truth_status = string,
  applicability_truth_status = "reentry_proposal" | "not_evaluated",
  materialization_loss = table,
  created_at = number,
  substrate_session_id = string | nil,
}
```

### 9.3 What may and may not cross

| May cross as bounded projection | Must never cross as live state |
|---|---|
| manifest artifact/text/code/reference | parent Packet identity |
| residue and remaining-work projection | living `Z`, `E_raw`, `E`, or `M` |
| external artifact and evidence references | parent CALM as child CALM |
| warning/bequest/compost refs through attached `H` | current operator/router position |
| declared substrate session id | unbounded parent trace/context |
| provenance and source truth statuses | silently fresh runtime truth |

`target_generation` is nil when a final manifest is delivered outward without a
descendant. It becomes an integer only after continuation accepts re-entry.

The child gets a new local loss capacity, but it does not get pristine source
material. Carrier omission/materialization loss is already present in the
payload and remains visible in lineage history.

## 10. NETWORK@▽ Contract

NETWORK is an ingress implementation, not an operator.

```text
human input
  -> FLOW@▽

machine/self re-entry carrier
  -> NETWORK validation at ▽
  -> FLOW@▽
```

| NETWORK may | NETWORK must not |
|---|---|
| validate envelope, identity, bounds, provenance, and media type | appear in canon adjacency |
| place only carrier payload into newborn CHAOS | export/import a living Packet |
| pass metadata into immutable newborn header/history refs | copy parent CALM, relations, momentum, or truth freshness |
| emit ingress and transport-cost events | choose the first internal route or operator role |

`△ -> NETWORK@▽` is a lineage boundary transaction, not a twenty-third edge.

## 11. Continuation Decision Table

Amendment 2026-07-19: `recoverable` in the older completion schema is split into
`terminal_recoverable` and a separate lineage continuation decision by
[`lineage_completion_continuation_separation_yellowprint.v0.md`](lineage_completion_continuation_separation_yellowprint.v0.md).
This restores the separation already implied by the two-stage table below.

### 11.1 Inputs

| Input | Required status | Meaning |
|---|---|---|
| completion contract | body policy/version | Defines done for this task and mode |
| terminal kind/cause | runtime-confirmed | Why one body ended |
| manifest/residue refs | status preserved per content | What can be delivered or recovered |
| progress evidence | runtime-confirmed or explicitly estimated | What reality changed or structure completed |
| remaining-work view | derived with provenance | What still requires another body |
| lineage budget snapshot | runtime-confirmed derivation | Whether another birth can be paid |
| carrier viability | runtime-confirmed envelope checks | Whether bounded re-entry is physically possible |
| capability/safety state | runtime-confirmed policy | Whether continuation is allowed now |
| external stop/resume event | runtime-confirmed occurrence | Human/machine boundary decision |

### 11.2 Outcomes

| Derived condition | Outcome | Child? |
|---|---|---:|
| completion contract passed | `complete` | no |
| unfinished, recoverable, safe, carrier viable, affordable | `continue` | yes, exactly one in v0 |
| missing external fact/capability/permission | `suspend_needs_input` | not automatically |
| lineage economics exhausted | `lineage_budget_exhausted` | no |
| unsafe or invalid ancestry | `terminate_unsafe` | no |
| no useful carrier can be constructed | `blocked_no_carrier` | no |
| operator explicitly cancels | `cancelled` | no unless later explicit resume policy |
| evidence insufficient to classify | `suspend_unknown` | no hidden guess |

### 11.3 Decision record

```lua
{
  kind = "lineage_continuation_decision",
  lineage_id = string,
  source_corpse_id = string,
  outcome = string,
  completion_contract_id = string,
  evidence_refs = table,
  remaining_work_count = number | nil,
  carrier_id = string | nil,
  budget_snapshot_ref = string,
  reason = string,
  event_truth_status = "runtime_confirmed",
  basis_truth_statuses = table,
}
```

The fact that the runner made a decision is runtime-confirmed. Semantic claims
inside its basis keep their own status.

Exact completion predicates are OPEN and mode-specific. Build mode cannot use
a substrate saying "done" as effect evidence. Plan mode may complete a semantic
artifact while preserving `semantic_proposal` on its content.

## 12. Lineage Ledger

The lineage runner is a power and therefore requires its own append-only ledger.

| Event | Required fields | Named readers |
|---|---|---|
| `lineage_created` | ids, policy, completion contract, limits | runner, audit, UI |
| `generation_allocated` | generation, local budget, remaining lineage budget | Packet constructor, economics |
| `generation_born` | Packet/parent/carrier/session refs | audit, session, grave |
| `packet_terminal` | corpse and terminal trace refs | classifier, continuation reader |
| `corpse_registered` | immutable corpse id/hash | grave, carrier builder, audit |
| `grave_classified` | grave id/kind/source corpse | history attachment, compost |
| `carrier_built` | carrier id/hash/loss/source refs | NETWORK@▽, economics |
| `continuation_evaluated` | all candidate outcomes and exclusions | decision, tests, UI |
| `continuation_decided` | selected outcome/reason | runner state machine |
| `lineage_budget_spent` | axis, amount, generation, source event | economics, mortality/terminal guard |
| `substrate_session_changed` | old/new fingerprint and reason | observation, experiments, audit |
| `lineage_completed` | completion evidence and final artifact/corpse | external boundary, session |
| `lineage_suspended` | missing requirement and resume contract | CLI/TUI/machine caller |
| `lineage_terminated` | cause and residue | session/audit |

The ledger records every candidate continuation outcome, not only the winner.

## 13. Packet And Lineage Economics

| Quantity | Scope | Reset at birth? | Owner | Terminal effect |
|---|---|---:|---|---|
| Packet identity loss | one body | yes, new identity capacity | T1 loss physics | kills current Packet |
| Packet budget allocation | one body | replaced by new allocation | Packet/lineage boundary | kills current Packet when exhausted |
| lineage tokens/time/calls/tools/money | whole task ancestry | no | lineage ledger/reader | blocks automatic child when exhausted |
| generation count | whole task ancestry | no | lineage runner | policy limit or audit |
| carrier/materialization loss | boundary artifact | no restoration; carried as fidelity damage | △ or lineage carrier builder | degrades what child can reconstruct |
| substrate context load | session/runtime | no while context retained | substrate adapter/session | compaction/switch pressure |

Allocation law:

```text
child local budget <= currently available lineage allowance
all actual child spending is charged to both local and cumulative views
boundary and substrate-session costs are charged to lineage even when no child is born
reincarnation never resets task economics
```

Packet loss does not become one cumulative lineage identity meter. A child is a
new identity. The lineage does retain an audit total of all losses and carrier
degradation, but that total does not retroactively damage a newborn unless the
degraded carrier actually shapes its field.

`max_generations` and host ceilings are emergency/policy guards. They must not
masquerade as the normal cumulative budget.

## 14. Three Continuity Channels

| Channel | Stored where | What it carries | Epistemic law |
|---|---|---|---|
| explicit carrier | corpse/lineage boundary | bounded artifact/residue/provenance | payload status preserved; applicability is proposal |
| body memory | session grave/compost and newborn `H` | inspectable warnings, bequests, statistical soil | storage fact confirmed; current effect derived |
| substrate continuity | substrate session | provider-visible conversation/context trajectory | declared handle confirmed; internal remembering only measured behavior |

These channels may reinforce each other but never collapse into Packet identity.

## 15. Grave And Karma Table

### 15.1 Classification

| Corpse evidence | Grave kind | Meaning |
|---|---|---|
| budget death with progress | `bequest` | useful work remains to continue |
| budget death without progress/do-not-repeat | `warning` | repeated path should resist |
| identity loss | `warning` | inherited form/path damaged identity |
| complete | `neutral` | fact belongs to ancestry but creates no automatic pressure |
| cancellation/other | policy plus explicit evidence | never guessed from cause alone |

### 15.2 Birth attachment and named readers

| Stored record | Attachment | Living reader | Derived effect |
|---|---|---|---|
| fresh warning | bounded immutable `H` view | ☱ history reader | `karma_resistance` against matching live path |
| fresh bequest | bounded immutable `H` view | ☰ relates refs; ☱ evaluates current fit | `karma_help` or unresolved continuation pressure |
| neutral grave | audit-only `H` view when requested | audit/observation | no route pressure by default |
| compost warning pattern | bounded `H`/foundation bridge | ☱ foundation/history reader | weaker statistical resistance |
| compost bequest pattern | bounded `H`/foundation bridge | ☱ foundation/history reader | weak habit/help, never exact work restoration |

Karma law:

```text
grave is stored
karma is derived when a living Packet reads grave against current state
router sees packet-local pressure contributions, never session files
warning is resistance, not prohibition
bequest is assistance, not instruction
```

## 16. Compost And Foundation Boundary

| Stage | Input | Output | Forbidden shortcut |
|---|---|---|---|
| compost | excess old graves | aggregate pattern without individual identity | immortal full grave archive |
| birth projection | bounded relevant compost patterns | read-only `H` slice | router opening session storage |
| foundation bridge | compost pattern plus current-life relation/evidence | weak body habit contribution | old count becoming runtime truth about current task |
| runtime reinforcement | current-life tool/test evidence | updated current-life foundation | inherited statistic counted as executed evidence |

Fresh graves may exert stronger pressure. Compost may bias. Foundation may hold
a body habit. None is a hard route command.

The exact compost relevance filter and bridge weight are OPEN.

## 17. Session And Storage Contract

```text
fresh CLI/TUI run without explicit session
  -> fresh session id
  -> fresh lineage id
  -> empty grave and compost
```

| Storage | Scope | Retention | Default reader |
|---|---|---|---|
| lineage ledger | one lineage | complete ancestry or configured archival projection | lineage runner/audit |
| Packet capsule/corpse | one generation | immutable; may later be compacted by explicit policy | grave/carrier/audit |
| fresh grave | one session | bounded until compost | birth history projector |
| compost | one session | bounded aggregate with its own decay/retention policy | foundation/history projector |
| substrate context | one session/adapter | provider/model/context limits | substrate adapter |

Persistence to disk may be configurable, but an active lineage always owns the
minimum in-memory ledger needed to continue safely. Turning off long-term memory
must not make continuation authority unauditable during the run.

## 18. Substrate Session Contract

Minimum declared state:

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
model/provider/session changes are lineage ledger events
same handle is evidence of transport continuity, not proof of remembered meaning
semantic output remains proposal regardless of session age
Packet internals are not dumped into context to fake continuity
context cost counts against lineage economics
automatic semantic compaction waits for memoris ablation evidence
```

## 19. Re-entry Experiment Matrix

Use the same task boundary and explicit carrier.

| Line | Substrate condition | Body memory | What it isolates |
|---|---|---|---|
| A | same live substrate session | same session grave/compost | full proc-17 continuity |
| B | same model, fresh substrate session | same session grave/compost | explicit carrier plus body memory |
| C | different substrate | same session grave/compost | substrate-independent body continuity |
| D | same live substrate session | body memory disabled/empty | substrate continuity contribution |
| E | fresh substrate session | empty grave/compost | explicit carrier-only control |

Measure:

```text
task completion and evidence
generation count
ticks and route per generation
tokens/time/tool calls
repeated defect count
carrier size and loss
human interventions
```

Equal wording is not expected. Improved convergence is the relevant signal.

## 20. Two Recurrences

| Property | ☲ CYCLE | Lineage continuation |
|---|---|---|
| scope | inside one Packet life | between terminal Packet lives |
| identity | unchanged | new `packet_id`, generation +1 |
| topology | canonical operator in 22-edge Tree | outside Tree boundary |
| input | runtime-confirmed repeat condition | corpse, task state, carrier, lineage policy |
| cost | local and cumulative runtime economics | carrier/birth plus cumulative lineage economics |
| loss | zero direct identity loss | boundary carrier may be lossy; child has new local identity |
| owner | ☱ owns recurrence condition; ☲ emits one impulse | lineage runner owns continuation decision |

Using ☲ to reincarnate a Packet or using the lineage runner for an ordinary
same-life loop is a scale error.

## 21. Recovery And Failure Table

| Failure | Required response |
|---|---|
| carrier envelope invalid | reject birth; record lineage suspension/termination |
| parent/corpse reference mismatch | reject birth as ancestry violation |
| generation not exactly previous +1 | reject birth |
| lineage budget cannot allocate child | terminal `exhausted` |
| substrate session unavailable | continue only if policy permits fresh-session carrier path; record switch |
| grave/history unreadable | do not invent memory; continue clean or suspend by policy |
| child constructor fails | no generation increment; ledger failure; corpse remains untouched |
| lineage runner crashes after corpse registration | recovery resumes from ledger idempotently; no duplicate child |
| completion evidence stale | suspend or re-enter for validation; do not mark complete |
| no viable carrier | preserve final corpse and block lineage visibly |

Birth and continuation operations require idempotency keys derived from lineage,
source corpse, and target generation.

## 22. Branching Policy

V0 is linear:

```text
one corpse -> zero or one automatic child
one lineage -> zero or one living Packet
```

Parent references are still explicit so later branching does not require
rewriting history. Branching, subordinate Packets, and cross-lineage NETWORK
belong to a later network layer and must not be smuggled into v0 carrier logic.

## 23. Current Lua Mapping

| Target mechanism | Current implementation | Gap |
|---|---|---|
| one-life Packet runner | `runtime/tension_runner.lua` | starts after implicit FLOW; no outer lineage owner |
| Packet id/parent | `core/packet.lua` `id`, `parent_id` | lineage/generation/corpse/carrier ids missing |
| corpse finality | dead guards in `core/packet.lua` | formal corpse record/hash and full mutator audit remain |
| terminal manifest/death | `logic/manifest.lua` plus `packet.manifest_packet/die` | no partial/recovery carrier contract or △ loss |
| Packet capsule | `runtime/packet_memory.lua` | capsule is memory record, not yet canonical corpse/carrier |
| session scope | `runtime/session_memory.lua` | session has no lineage registry or cumulative ledger |
| grave classification/attach | `runtime/grave.lua` | attachment exists; T1 `H` projection and generic readers incomplete |
| warning generation curve | integration tests/current router | one narrow ☱☲ pattern, not general pressure derivation |
| bequest | seeds `chaos.unresolved_pressure` | named causal reader not implemented |
| compost | bounded patterns in session memory | foundation/history reader not implemented |
| substrate adapter | scalar calls with usage | no session-owned conversation/context contract |
| cumulative economics | local budget only | lineage spending/allocation missing |
| NETWORK@▽ | documented only | ingress adapter missing |
| continuation decision | documented only | body-owned predicate/ledger/runner missing |

Current grave generation tests demonstrate ancestry effects between manual runs.
They are evidence for components, not an implemented lineage runner.

## 24. Named Reader Registry

| Written record | Required reader | Read moment | Failure if absent |
|---|---|---|---|
| lineage header | lineage runner | every boundary transaction | generations have no owner |
| generation allocation | Packet constructor/economics | birth | budget reset exploit |
| terminal Packet/corpse | grave classifier and continuation reader | after every life | death cannot teach or continue |
| manifest/recovery carrier | NETWORK@▽ | accepted continuation | output has no receiver |
| continuation candidates | lineage decision/trace | terminal evaluation | hidden fixed pipeline |
| continuation decision | lineage runner state machine | same boundary transaction | ledger is decorative |
| cumulative cost | lineage budget guard | before allocation and after spending | reincarnation becomes free |
| warning grave | ☱ history derivation | child runtime reads matching state | warning cannot resist repetition |
| bequest grave | ☰ relation reader and ☱ fit derivation | child field/runtime formation | useful death cannot help |
| compost pattern | foundation/history bridge | bounded birth/runtime read | compost is dead storage |
| substrate-session record | substrate adapter and experiment logger | call/re-entry | memoris is unauditable claim |
| completion evidence | completion contract reader | terminal evaluation | model can declare itself done |
| lineage terminal event | session/CLI/TUI/machine caller | final boundary | task has no observable result |

## 25. Test Matrix

### 25.1 Body-only and fake-substrate tests

```text
first birth has generation=1 and no parent
second birth has new packet_id, generation=2, exact parent/corpse/carrier refs
child has no parent CALM, active relations, momentum, route position, or local ledger
corpse rejects every mutator and cannot produce duplicate automatic child
carrier metadata stays outside semantic CHAOS
carrier payload enters only through ▽
NETWORK never appears in a Packet topology trace
complete terminal state produces no child
unfinished recoverable death produces exactly one child
unknown/unsafe/no-carrier outcome produces no hidden child
lineage budget remains cumulative across local budget resets
failed child birth does not consume generation number twice
lineage ledger can resume idempotently after a simulated boundary crash
☲ recurrence does not increment generation
```

### 25.2 Grave and memory tests

```text
death fixtures are grown through real Packet lives
warning changes derived pressure but does not hard-ban a route
bequest helps matching work and does not block a good route
unrelated session grave never attaches
compost removes individual identity and keeps bounded statistics
compost affects body only through named weak reader
empty-memory control repeats the known failure more often than inherited line
```

### 25.3 Live-substrate tests

```text
run re-entry matrix A-E with one task and one explicit carrier contract
record provider/model/session changes
complete a real multi-file coding task over multiple generations
execute tests and retain runtime evidence across boundary by references, not truth copying
final generation completes without manual replanning
compare against raw substrate and fixed-loop control
```

## 26. Open Rows Before Crystall

```text
exact mode-specific completion contract
minimum sufficient carrier payload and size bound
which internal deaths are automatically recoverable
recovery carrier projection algorithm and loss formula
lineage budget axes, allocation policy, and default limits
whether explicit re-funding resumes the same lineage or births a new one
history attachment policy when persistent memory is disabled
grave/compost relevance matching without LLM retrieval
bequest named-reader behavior in the task-shaped field
compost-to-foundation weighting and decay
substrate-session adapter shape per provider/local runtime
idempotency and crash-recovery storage transaction
later branching semantics
```

## 27. T3 Acceptance

This table is ready for crystall only when:

```text
lineage runner is classified as core proc-17 mechanics
one-life routing and inter-life continuation are separate authorities
identity never crosses △ or internal death
NETWORK@▽ is ingress machinery, not an operator or edge
carrier content, body memory, and substrate continuity remain distinct
local Packet loss is separated from cumulative lineage economics
every lineage decision and cost has an append-only ledger event
every stored corpse/carrier/grave/compost record has a named reader
completion cannot be declared by substrate wording alone
v0 has one living Packet and at most one child per corpse
current Lua components are treated as ancestors, not proof that the outer runner exists
```
