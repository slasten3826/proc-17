# Полный аудит тела после repository hands и QA, 2026-08-01

Status:

```text
layer: CHAOS
scope: current body, authority, ten operators, 22 edges, promotion evidence,
       repository hand, QA hand, lineage and release boundary
source commit: fce00be Complete QA terminal retention M4
runtime implementation authorized by this document: no
router authority changed by this document: no
promotion authorized by this document: no
current_state / README changed by this document: no
```

This audit is a new observation layer. It does not rewrite older TABLE,
CRYSTALL or MANIFEST records in place. Where an older document is stale, that
document remains archaeology until a later amendment names its replacement.

## 0. Короткий вердикт

QA-дуга закончена, но полный Tree еще нет.

Сейчас proc-17 состоит из трех одновременно истинных машин:

```text
1. default laboratory body
   router_mode=shadow
   live movement=legacy
   tree=observer

2. narrow product body used by CLI
   router_mode=tree
   pressure_policy=qualified_need_v0
   relation consumer intentionally ablated
   exact Plan or one-file Repository life

3. completed manual QA transaction
   sealed candidate -> QA execution -> verdict -> terminal projection
   physically body-owned, economically charged and hostile-tested
   entered through explicit manual/grown transitions, not Tree pressure
```

The difficult organs are no longer the main uncertainty. The current hard
boundary is integration and measurement:

```text
all ten organs exist
eight organs have at least one automatic qualified role
two organs, DISSOLVE and CYCLE, have no qualified action vocabulary
QA has exact organ actions but no qualified route producer
the promotion ledger cannot distinguish binary-tree evidence from
qualified-tree evidence and ignores its own promotion_eligible flag
```

Therefore the next safe step is not to grow more edge fixtures immediately.
The promotion measuring instrument must be repaired first. Otherwise proc-17
can manufacture a false 38/38 by merging different policy epochs or by counting
an explicitly ineligible execution.

The body is already a real narrow software machine:

```text
Plan: semantic source -> exact structure -> optional real CHOOSE -> assessment
      -> plan result -> terminal Packet

Build: semantic source -> exact artifact -> capability-safe create-no-replace
       -> independent read-back -> exact repository result -> terminal Packet

QA: sealed exact candidate -> isolated fixed-profile execution -> body check
    -> deterministic verdict -> honest terminal projection -> corpse history
```

What it is not yet:

```text
one automatically routed Plan -> Build -> QA -> recovery lineage
a promoted 22-edge / 38-direction full Tree
a general coding agent over legacy repositories
a released v0.1.0 artifact
```

## 1. Основание аудита

### 1.1 Local clean baseline

The audit started from:

```text
branch: main
HEAD: fce00be
worktree: clean
origin/main: same commit
```

Executed during this audit:

```text
lua tests/run.lua                         GREEN, 114 suites
lua tests/smoke_mortality_battery.lua     GREEN, 8/8
lua tests/red_qa_hand.lua                 GREEN, 84/84, red=0, skip=0
targeted qualified plan/repository/QA      GREEN
luac -p core/runtime/organs/logic/cli      GREEN
```

The ordinary suite contains one explicitly optional cross-device provider
case when its bind-mount environment is not enabled. The suite still exits
green. No live DeepSeek call and no separate cold clone were used in this
audit; live claims below come only from already committed project records.

### 1.2 What was read

The audit reconciled:

```text
core/topology.lua
core/packet.lua
runtime/tension_runner.lua
runtime/router.lua
runtime/pressure.lua
runtime/qualified_pressure.lua
runtime/pressure_action.lua
runtime/pressure_composition.lua
runtime/operator_registry.lua
runtime/edge_catalog.lua
runtime/edge_stats.lua
organs/*, with focused reads of DISSOLVE, CYCLE, LOGIC, RUNTIME and MANIFEST
lineage/corpse/carrier/grave/session-memory paths
repository hand and candidate-seal paths
QA request/capability/execution/verdict/terminal paths
CLI and its permanent tests
current promotion TABLE records and current MANIFEST/README claims
```

The method remained:

```text
writer
-> immutable witness
-> pressure/action
-> readiness over the same refs
-> selected route
-> receiving organ effect
-> named reader
-> terminal or next derivation
```

An organ existing as a Lua module is not counted as a living route.

## 2. Фактическая власть

## 2.1 Authority is a tuple, not one flag

The code currently speaks as if `router_mode` names authority. It names only
who commits movement. The full physical authority is at least:

```text
authority_epoch = {
  router_mode,
  pressure_policy,
  composition_policy,
  policy_status,
  action_protocol,
  witness_gate_version,
  ablation_vector,
  legacy_observer_mode,
}
```

This distinction is runtime-confirmed:

```text
router_mode=tree, no pressure_policy
  -> pressure.binary.v0
  -> no exact action plan

router_mode=tree, pressure_policy=qualified_need_v0
  -> pressure.class_order.v0
  -> exact pressure.action_plan.v0
```

The first mode is the old binary/vibed Tree. The second is the newer causal
qualified Tree. They are not two measurements of one policy.

## 2.2 Current default

`runtime/tension_runner.lua` still defaults to:

```text
router_mode=shadow
pressure_policy=camera_reconciliation when omitted
```

Legacy moves the Packet. Tree observes. This is still the generic body default.

## 2.3 Current product path

`cli/proc17.lua` explicitly fixes:

```text
router_mode=tree
pressure_policy=qualified_need_v0
ablate_relation_consumer=true
legacy_shadow=false
```

Therefore Tree is not merely an unused experiment anymore. It is live product
authority over a deliberately narrow Plan/Build corridor. At the same time,
the CLI is not evidence for universal full-Tree promotion because its relation
consumer is intentionally removed and every such ablation marks the snapshot
as unqualified for promotion.

## 2.4 QA authority

QA M2-M4 uses actor-valid ordinary organ ticks and body writers:

```text
☶  execute exact current candidate
☱  assemble deterministic candidate verdict
△  project terminal QA truth
```

But `qualified_pressure.lua` and `pressure_action.lua` have no QA modes. The
grown M4 life proves this route shape:

```text
▽ -> ☴   tree + exact action
☴ -> ☵   tree + exact action
☵ -> ☴   tree + exact action
☴ -> ☳   harness_override
☳ -> ☶   harness_override
☶ -> ☱   harness_override
☱ -> ☶   harness_override
...       manual transaction spacing
☱ -> △   harness_override
```

The QA hand is real. Its automatic body route is not.

## 3. Карта десяти органов

| Operator | Effect exists | Qualified witness/action | Current automatic role | Audit verdict |
|---|---:|---:|---|---|
| `▽ FLOW` | yes | entry derivation | user/carrier birth | living |
| `☰ CONNECT` | yes | `connect_probe` | relation recognition/coverage | living; CLI ablates it |
| `☷ DISSOLVE` | yes, raw and active | none | no qualified ingress | organ without new-policy route |
| `☵ ENCODE` | yes | relation/structure formation | exact CALM formation | living |
| `☳ CHOOSE` | yes | `alternative_collapse` | real observed alternatives | living |
| `☴ OBSERVE` | yes | semantic/field/relation native | semantic and material sight | living |
| `☲ CYCLE` | yes | none | legacy/binary recurrence only | organ without new-policy route |
| `☶ LOGIC` | yes | repository effect | repository hand | living; QA action manual |
| `☱ RUNTIME` | yes | plan/repository review/reconcile | assessment and exact completion | living; QA verdict manual |
| `△ MANIFEST` | yes | plan/repository delivery | exact terminal delivery | living; QA terminal manual |

Exact installed action modes at `fce00be` are:

```text
connect_probe
relation_formation
structure_formation
alternative_collapse
semantic_observe
field_native_observe
relation_native_observe
plan_completion_review
plan_delivery
repository_action_review
repository_effect
repository_reconcile
repository_delivery
```

There is no installed action mode targeting `☷` or `☲`, and no QA execution,
verdict or terminal action in this vocabulary.

## 4. Evidence classes used by this audit

The edge map below does not collapse unlike evidence:

| Mark | Meaning | May satisfy qualified promotion? |
|---|---|---:|
| `Q-executed` | Body-grown Tree route under `qualified_need_v0` reached destination tick | only after eligibility/epoch ledger repair |
| `B-executed` | Old binary Tree or legacy control executed it | no |
| `B-selected` | Old binary shadow selected it but destination did not execute | no |
| `H-only` | Direct organ or `harness_override` fixture | no |
| `missing` | No current executed evidence found | no |

This audit grew a deterministic union of current qualified Plan, alternative
Plan, one-action Repository, alternative Repository, relation-native and
relation-plus-semantic lives. It observed fourteen executed directions:

```text
E01 ▽->☰
E03 ▽->☴
E05 ☴->☰
E06 ☰->☵
E09 ☴->☵
E09 ☵->☴
E10 ☴->☳
E10 ☳->☴
E11 ☴->☱
E12 ☵->☱
E16 ☳->☶
E17 ☱->☶
E17 ☶->☱
E20 ☱->△
```

`14/38` is an observed qualified-execution upper bound, not a promotion score.
The current ledger defects in section 6 make an exact promotion-eligible count
untrustworthy.

## 5. Карта 22 canonical edges

| Edge | Direction A | Direction B | Current reading |
|---|---|---|---|
| E01 `▽-☰` | `▽->☰` Q-executed | boundary | qualified relation ingress lives |
| E02 `▽-☷` | `▽->☷` H-only | boundary | raw release fixture; no pressure writer |
| E03 `▽-☴` | `▽->☴` Q-executed | boundary | qualified Plan/Build entry |
| E04 `☰-☷` | `☰->☷` H-only | `☷->☰` H-only | raw relation tests only |
| E05 `☰-☴` | `☰->☴` H-only | `☴->☰` Q-executed | relation recognition after semantic sight |
| E06 `☰-☵` | `☰->☵` Q-executed | `☵->☰` missing | relation formation forward only |
| E07 `☷-☴` | `☷->☴` H-only | `☴->☷` H-only | dissolve/upper controls only |
| E08 `☷-☳` | `☷->☳` missing | `☳->☷` missing | no body evidence found |
| E09 `☴-☵` | `☴->☵` Q-executed | `☵->☴` Q-executed | complete exact formation/sight pair |
| E10 `☴-☳` | `☴->☳` Q-executed | `☳->☴` Q-executed | complete real choice/sight pair |
| E11 `☴-☱` | `☴->☱` Q-executed | `☱->☴` H-only | plan review forward; reverse fixture only |
| E12 `☵-☱` | `☵->☱` Q-executed | `☱->☵` B-selected | repository review forward; old prediction reverse |
| E13 `☵-☳` | `☵->☳` H-only | `☳->☵` missing | current exact CHOOSE requires intervening sight |
| E14 `☵-☲` | `☵->☲` B-executed | `☲->☵` missing | old binary continuation only |
| E15 `☳-☱` | `☳->☱` B-selected | `☱->☳` B-selected | old pressure archaeology only |
| E16 `☳-☶` | `☳->☶` Q-executed | `☶->☳` missing | selected repository action reaches LOGIC |
| E17 `☱-☶` | `☱->☶` Q-executed | `☶->☱` Q-executed | complete repository review/effect/reconcile pair |
| E18 `☱-☲` | `☱->☲` B-executed | `☲->☱` B-executed | legacy mortality loop, no qualified action |
| E19 `☲-☶` | `☲->☶` B-executed | `☶->☲` H-only | old binary/direct organ only |
| E20 `☱-△` | `☱->△` Q-executed | boundary | plan/repository terminal path |
| E21 `☲-△` | `☲->△` missing | boundary | no qualified terminal recurrence |
| E22 `☶-△` | `☶->△` missing | boundary | no direct qualified validation delivery |

The matrix exposes two different remaining questions:

```text
missing implementation:
  DISSOLVE, CYCLE and automatic QA causal chains

possibly stale authority surface:
  directions whose old witness bypasses newer mandatory phase laws,
  especially direct ☵->☳ and QA-like ☶->△
```

Do not create fixtures that violate the newer observation/verdict laws merely
to make 38 green. Each such direction must either receive a real state in which
the direct movement is lawful or trigger an explicit topology/authority-surface
revision through the documentation pipeline.

## 6. Findings

## F1. `tree` names two incompatible policy epochs

```text
severity: high for promotion evidence, medium for current narrow runtime
class: authority identity underspecified
```

`router_mode=tree` without an explicit pressure policy executes
`pressure.binary.v0`. The CLI executes `qualified_need_v0`. Tests named
`tree-authority gate` mostly exercise the former, while product Plan/Build
tests exercise the latter.

Consequences:

```text
a green tree test does not identify which physics was green
binary control can be mistaken for qualified authority
promotion records that name only router_mode are ambiguous
```

Required treatment: make the authority epoch explicit in every run result,
edge ledger, corpus record and merge boundary.

## F2. Edge statistics can merge binary and qualified evidence

```text
severity: high
class: false-green promotion ledger
```

`tension_runner` initializes `edge_stats.v2` with only:

```text
work_mode
router_mode
```

It omits `pressure_policy`, composition policy/status, witness version and
ablation vector. `edge_stats.merge` verifies protocol and observer metadata but
does not require equal authority labels.

Runtime reproduction from this audit:

```text
binary Tree labels:     router_mode=tree, pressure_policy=nil
qualified Tree labels:  router_mode=tree, pressure_policy=nil
edge_stats.merge:       accepted
```

This can add old vibed-control executions and new qualified executions into one
closure report. No 38/38 claim is trustworthy until this is impossible.

## F3. `promotion_eligible` is written but has no ledger reader

```text
severity: high
class: record without named reader / false-green edge credit
```

`pressure_composition` marks each candidate from snapshot diagnostics and
fixture provenance. `router.derive_tree_authority` keeps the selected candidate
but drops the decision-level eligibility field. `edge_stats` counts candidate,
commit and arrival without consulting either field.

Runtime reproduction:

```text
entry selected_candidate.promotion_eligible = false
E03 executed_count                          = 1
E03 coverage                                = complete
edge_stats labels pressure_policy           = nil
```

The project has rediscovered its canonical defect class exactly: the writer
exists, but the intended promotion reader does not.

Required treatment:

```text
route retains exact eligibility and reasons
arrival credit has separate physical_executed and promotion_eligible counts
ineligible execution remains useful regression evidence
ineligible execution cannot satisfy canonical closure
merge rejects unlike authority epochs
```

## F4. DISSOLVE and CYCLE are organs without qualified causal chains

```text
severity: promotion blocker
class: missing witness/action/readiness join
```

For DISSOLVE, the body already has both:

```text
raw relation release
active relation weakening/dissolution
```

But the new policy has no rigidity/release witness and no action plan capable
of carrying exact relation, phase, reason and target-state refs into readiness.
Old binary rigidity pressure cannot provide those options.

For CYCLE, the body already has bounded continuation decisions and correct
economics. But the new policy has no continuation witness or cycle action.
Lineage rebirth is not a replacement for same-Packet recurrence.

This is more than missing corpus. It is missing vocabulary.

## F5. QA is complete as a transaction, incomplete as routed body life

```text
severity: known integration boundary
class: manual authority, not QA safety defect
```

QA containment, one-use authority, exact cost, check/failure split, verdict,
terminal projection, corpse retention and historical carrier all passed. This
audit found no new QA sandbox defect.

However:

```text
qualified_pressure has no QA consumers
pressure_action has no QA modes
tension_runner.run never invokes the manual QA helpers
CLI never binds or invokes QA
QA transitions do not enter the normal edge ledger
```

Therefore `QA hand complete` means the hand and body transaction are complete.
It does not mean autonomous software acceptance is complete.

## F6. DISSOLVE registry declaration is stale

```text
severity: medium before registry enforcement or DISSOLVE treatment
class: declaration differs from effect
```

The registry declares DISSOLVE reads/writes only around active relations,
validation, trace, potential and loss. Raw mode also reads and mutates the raw
relation phase and may write a residue unit. Rights remain descriptive in v0,
so current tests do not fail. A future enforcement layer or generated audit
would receive a false declaration.

Repair the descriptor as part of DISSOLVE TABLE/CRYSTALL, not as an unrelated
one-line code edit.

## F7. Current documentation mixes three epochs

```text
severity: medium operationally
class: stale release and promotion claims
```

Examples:

```text
README says 107 suites; current count is 114
README still asks for a 40-green/44-red QA run; current QA is 84/84 green
release closure freezes QA as absent; that freeze was deliberately superseded
  by the empirically required QA campaign
promotion TABLE still marks several lineage/choice/tick boundaries as missing
  even though their mechanics now exist
promotion TABLE says no hands and no CLI as allowed boundaries; both now exist
full_tree_edge_evidence.v0 predates qualified actions
current_state calls all bequests unread, while binary pressure now has a
  karma_help reader; qualified pressure and compost still do not
```

These records should be amended after the authority-ledger treatment decides
the new evidence schema. Editing them now would replace one guessed count with
another.

## F8. Grave/compost reading remains policy-local

```text
severity: post-v0 boundary
class: incomplete inheritance integration
```

The old binary pressure reads bequest/warning karma. Qualified pressure does
not. Compost patterns still have no router/foundation consumer. This does not
block the current Plan/Build/QA transaction, but a future claim that qualified
lineages learn from all inherited memory would be false.

## 7. Promotion gate reassessment

The old G0-G13 table remains the authority until amended. Current reading:

| Gate | Audit color | Reason |
|---|---|---|
| G0 repository hygiene | green | clean baseline at `fce00be` |
| G1 baseline runtime | green | 114 suites, mortality 8/8, QA 84/84 |
| G2 P01-P13 corpus | partial/stale | mechanics grew, unified current corpus did not |
| G3 38 directions | red/unmeasurable | 14 qualified-executed upper bound; eligibility ledger unsound |
| G4 manifest honesty | green | accepted/rejected/QA terminal projections pinned |
| G5 lineage honesty | partial | in-memory budget recovery works; automatic rejected QA recovery does not |
| G6 ledger boundaries | mechanism green, promotion red | committed/executed is sound; epoch/eligibility is not |
| G7 observer isolation | partial | binary Tree proven; no full qualified family matrix |
| G8 pressure qualification | partial | installed families strong; DISSOLVE/CYCLE/QA absent |
| G9 organ reality | red | CONNECT and real CHOOSE green; DISSOLVE unrouted |
| G10 harness honesty | green | typed effects vs loud invariant failures heavily tested |
| G11 session isolation | partial | CLI fresh/resume and lineage identity green; promotion P03 matrix stale |
| G12 live integration | partial | committed live artifacts exist; no current promotion-format campaign |
| G13 documentation | red | README, release and promotion records cross epochs |

Promotion status remains:

```text
blocked
```

Changing the generic default from `shadow` is not authorized.

## 8. What must not be reopened

The audit found no reason to redesign or weaken:

```text
Packet corpse finality and deep-copy trace law
budget/loss mortality
runtime camera and watermark
candidate seal and terminal root lock
repository capability and independent read-back
QA private source, supervisor, receipt and containment campaigns
QA check versus infrastructure-failure separation
deterministic QA verdict and terminal projection
completion truth versus lineage affordability
fresh Packet/fresh repository generation law
legacy observer isolation
exact pressure action/ref verification already installed
```

These are foundations for the next integration, not candidates for cleanup.

## 9. Ordered next work

## 9.1 Common mandatory step: repair promotion evidence

This step is required whether the next goal is v0 release or full-tree
promotion.

```text
T0.1 CHAOS      this audit                                      complete
T0.2 TABLE      authority_epoch + eligible edge-credit contract next
T0.3 CRYSTALL   exact run labels, merge law and dual counters
T0.4 CODE       propagate policy/eligibility into result/route/edge_stats
T0.5 TEST       binary+qualified merge rejected
                unlike ablation epochs rejected or separately bucketed
                ineligible execution cannot close an edge
                physical execution remains retained as evidence
T0.6 MANIFEST   regenerate current qualified edge report
```

Minimum authority identity for T0.2:

```text
router_mode
pressure_policy / derivation_version
composition_policy and policy_status
action_protocol
witness gate version
ablation vector
observer mode
```

No pressure semantics need to change in T0.

## 9.2 If the goal is to finish the product v0

After T0, the shortest finite route is:

```text
R1 qualified QA routing
   sealed eligible candidate -> ☶ execution -> ☱ verdict -> △ terminal

R2 grown lifecycle
   accepted -> finish
   rejected -> corpse/carrier -> fresh repository generation
   infrastructure failure -> typed failure, never candidate rejection

R3 public policy
   either keep CLI completion explicitly below QA acceptance
   or expose one fixed QA-enabled lifecycle; do not blur them

R4 repeat the roguelike falsifier without semantic self-acceptance

R5 clean-checkout release battery, README/current_state amendment, tag v0.1.0
```

DISSOLVE, CYCLE, compost reading, 38/38 promotion and the Go TUI do not have to
block this narrow release unless the release claim explicitly includes them.

## 9.3 If the goal is full 22-edge Tree promotion

After T0, the causal order is:

```text
F1 DISSOLVE treatment
   exact rigidity/release inspection
   raw and active action modes
   readiness consumes the same refs
   registry declaration repair
   body-grown positive and negative lives

F2 CYCLE treatment
   exact continuation/stop witness
   repeat/progress/budget source refs
   route-carried cycle action
   no conflation with lineage rebirth

F3 automatic QA treatment
   reuse completed transaction; add only route producers/actions

F4 remaining direction campaign
   grow real direct states where lawful
   identify directions made obsolete by newer phase laws

F5 explicit topology/authority decision
   implement the remaining lawful directions or revise the declared surface
   through CHAOS -> TABLE -> CRYSTALL; never use accepted exceptions

F6 separate promotion commit
```

The immediate next document is the same in both branches: the T0.2 TABLE for
authority epochs and eligible edge credit.

## 10. Falsifiers for this audit

This audit must be amended if a later run proves any of the following:

```text
edge_stats already rejects unlike pressure/ablation epochs
an ineligible selected candidate cannot create executed closure credit
qualified_need_v0 already installs a DISSOLVE or CYCLE action
ordinary tension_runner.run already routes the complete QA transaction
the 14-direction union omitted a current body-grown qualified execution
a supposedly direct missing edge has a permanent qualified test with arrival ref
```

New evidence should link exact run, route derivation and destination arrival.
A synthetic transition is not a falsifier for a routing claim.

## 11. Audit thesis

```text
The hands are built.
The QA hand is built.
The narrow Tree already works in public.

What remains is not another ontology chapter before every useful action.
It is to make authority evidence incapable of lying, then choose explicitly:
finish the narrow product lineage, or finish the entire Tree.
```
