# Operator Tree Physics Yellowprint v0

Status:

```text
table
source: docs/00_chaos/full_packet_tree_physics_notes.md
body vocabulary: docs/01_table/yellowprints/packet_body_physics_yellowprint.v0.md
scope: one living Packet walking the full ProcessLang Tree
crystall: docs/02_crystall/blueprints/operator_tree_physics.v0.md
```

## 0. Purpose

This table answers:

```text
how can one living Packet move and transform without a hidden pipeline?
```

It binds:

- ten operator contracts
- twenty-two canonical edges
- two eyes
- pressure derivation
- affordability, capability, safety, and mortality
- shadow-router migration from current rails

It does not describe cross-generation continuation. That is T3.

## 1. Canonical Graph

Source of adjacency truth:

```text
ProcessLang/canon.lua
core/topology.lua is the current proc-17 copy and must remain equivalent
```

Unique undirected edges:

```text
▽-☰  ▽-☷  ▽-☴
☰-☷  ☰-☴  ☰-☵
☷-☴  ☷-☳
☴-☵  ☴-☳  ☴-☱
☵-☱  ☵-☳  ☵-☲
☳-☱  ☳-☶
☱-△  ☱-☶  ☱-☲
☲-☶  ☲-△
☶-△
```

Validation check at table assembly:

```text
canonical unique edge count = 22
documented unique edge count = 22
```

## 2. Runtime Direction Law

ProcessLang adjacency is symmetric. One Packet life is directed.

| Node class | Runtime law |
|---|---|
| `▽` | ingress operator; may leave through three canonical edges |
| internal nodes | may traverse either direction of internal canonical edges |
| edge leading back to `▽` | forbidden for the same Packet; new `▽` means new life |
| `△` | terminal; no same-life transition leaves it |
| internal death | terminates at current operator without requiring a path to `△` |
| `NETWORK@▽` | lineage boundary outside canon, not an eleventh operator or edge |

Consequences:

```text
canon remains unchanged
runtime candidate filtering applies lifetime direction
reverse PL query traces remain valid language forms
same-life Packet traces never resurrect through ▽ or leave △
```

## 3. Operator Tick Protocol

Every live operator tick follows one body-owned protocol.

| Order | Stage | Owner | Required result |
|---:|---|---|---|
| 1 | alive/finality guard | Packet runner | dead Packet rejected |
| 2 | position stamp | Packet runner | `current_operator` equals operator about to run |
| 3 | input-view construction | body/organ adapter | bounded T1 refs and versions |
| 4 | organ execution | current operator organ | payload or explicit no-op/error |
| 5 | mutation validation | body contract | writes are within operator rights |
| 6 | event append | body trace | reads, writes, truth, provenance |
| 7 | cost/loss application | budget/loss physics | append-only records |
| 8 | invalidation/freshness update | owning body regions | dependent views marked stale |
| 9 | mortality and safety guards | body | die now or remain alive |
| 10 | pressure derivation | named readers/aggregator | per-edge contributions |
| 11 | candidate filtering | router | only legal, capable, safe, affordable neighbors |
| 12 | route selection and trace | router | one winner plus all candidate totals |

No operator calls the router from inside its mutation. No operator directly sets
`next_operator`.

## 4. Router Selection Is Not ☳ CHOOSE

The router selects one next operator, but this is not automatically a semantic
`☳` tick.

```text
router movement
  selects which transformation happens next
  does not suppress the Packet's semantic alternatives
  alternatives may remain available on later ticks
  costs runtime budget, not CHOOSE identity loss

☳ CHOOSE
  changes the potential field
  suppresses alternatives irreversibly
  records what died
  pays identity loss
```

If routing itself mutates or kills semantic potential, the design has hidden a
☳ operation and is invalid.

## 5. Ten Operator Contract Matrix

| Operator | Required input view | Legal body writes | Forbidden core writes | Identity loss | Main pressure effects |
|---|---|---|---|---|---|
| `▽ FLOW` | user or NETWORK@▽ ingress, birth scalars | newborn `Z`, initial `S`, FLOW/birth event | parent living body, inherited `M/C/E` | zero in newborn | relation, rigidity, observation |
| `☰ CONNECT` | addressable units, optional forms/evidence/history view | `E_raw`, recognition metrics/event | unit remap, `M`, semantic choice/truth | zero by default | encode motif, observe relation, dissolve rigidity |
| `☷ DISSOLVE` | active relation/form plus rigidity/staleness | weakened `E`, dissolved residue/event | new relations, remap, `M` | conditional | flow/relation/observe/choice |
| `☴ OBSERVE` | bounded upper field and substrate membrane | upper observation; proposal units append-only | inspected state mutation, route, truth promotion, `M` | zero direct | discharges upper observation debt; reveals others |
| `☵ ENCODE` | potential units, relation hints, representation policy | CALM, identity map, invalidation set, loss | hidden omission, truth validation, direct `M` write | mandatory | observe new form, connect new ids, choice, runtime, cycle |
| `☳ CHOOSE` | explicit possibility field and pressure | activation/suppression, choice residue/loss | remap, possibility invention, validation | mandatory | observe consequence, dissolve dead paths, encode focus, runtime, logic |
| `☲ CYCLE` | scalar phase and runtime-confirmed continuation condition | scalar phase and cycle event | semantic planning, progress ownership, `Z/E/M/C/Q` | exactly zero | carries continuation to encode/logic/runtime/manifest |
| `☶ LOGIC` | declared rules, candidate form, capabilities, evidence | constraints, verdicts, effect evidence, weakened/rejected state | semantic generation, new relations, `M` | conditional | choose admissible path, cycle test, runtime evidence, manifest |
| `☱ RUNTIME` | CALM, relations, evidence, history view, economics | `M`, active `E`, counters, runtime observations, derived pressure records | semantic rewrite, stale promotion, parent momentum import | OPEN/conditional | observe uncertainty, encode mismatch, choose branch, logic, cycle, manifest |
| `△ MANIFEST` | selected/validated form, evidence, output policy | output, materialization loss, corpse/residue terminal event | continued same-life mutation, living body export | mandatory terminal | no internal successor |

The detailed body regions and writer ownership remain T1 authority.

## 6. Operator Readiness Table

An adjacent operator is not executable merely because the edge exists.

| Operator | Minimum readiness witness | Explicit no-op witness |
|---|---|---|
| `▽` | valid ingress carrier and newborn identity | invalid/empty ingress terminates birth |
| `☰` | at least two addressable units or one current unit plus one external/history referent | `no_relation_candidates` |
| `☷` | active relation/form with measurable rigidity, staleness, rejection, or residue policy | `nothing_dissolvable` |
| `☴` | a declared bounded scope or semantic question | `scope_empty` |
| `☵` | potential material plus declared representation target/bound | `no_compressible_structure` |
| `☳` | at least two live alternatives with non-zero potential | `confirmation_not_choice` |
| `☲` | runtime-confirmed continuation/repetition condition | `no_continuation_condition` |
| `☶` | declared rule/test and target referent | `no_rule_or_target` |
| `☱` | runtime state or history/economics view to read | `runtime_view_empty` |
| `△` | output/carrier contract and usable form/residue | `nothing_manifestable` |

Readiness failure normally removes or strongly resists that candidate before
routing. It must not produce a fake successful tick to satisfy topology.

## 7. Pressure Vocabulary

### 7.1 Core pressure kinds

| Kind | Derived from | Named reader | Primary targets | Discharged or transformed by |
|---|---|---|---|---|
| `relation_debt` | unbound units, missing dependency/evidence links | field relation reader | ☰ | successful ☰ snapshot |
| `rigidity` | overstable edges/forms, stale/rejected structures, inherited framing | rigidity/freshness reader | ☷ | ☷ release; may become new flow/relation pressure |
| `upper_observation_debt` | stale/missing view of CHAOS, new/remapped units, semantic uncertainty | upper freshness reader | ☴ | ☴ refresh; newly seen facts create other pressure |
| `encoding_debt` | unstructured potential, receiver/transfer requirement, stable motif | structure reader | ☵ | ☵ form plus recorded loss |
| `choice_pressure` | live alternatives, entropy, unresolved branch, separation affordability | possibility reader | ☳ | ☳ suppression/commitment |
| `runtime_mismatch` | CALM not installed, representation no longer fits execution, relation inertia change | lower eye/runtime reader | ☱ or ☵ depending current node | ☱ reconciliation or ☵ recode |
| `lower_observation_debt` | stale progress/evidence/budget/loss/foundation view | lower freshness reader | ☱ | ☱ refresh |
| `validation_debt` | untested claim, missing capability evidence, violated constraint | evidence/constraint reader | ☶ | ☶ verdict/effect evidence |
| `continuation` | remaining repeatable work and affordable recurrence | runtime progress reader | ☲ | one ☲ impulse; reason remains owned by runtime state |
| `manifest` | complete/usable partial form, accepted evidence, output request | readiness reader | △ or local edges approaching terminal neighbor | △ terminal boundary |
| `mortality` | near identity death, near budget exhaustion, unsafe state | mortality reader | terminal direction if available; death guard when exhausted | manifest or death |
| `karma_help` | matching bequest/compost relation to live state | ☱ history derivation | matching continuation/repair edge | use, invalidation, or expiry |
| `karma_resistance` | matching warning/compost pattern to current path | ☱ history derivation | resistance on matching edge/path | route avoidance or explicit override evidence |
| `capability_resistance` | missing organ/tool/capability | organ/sandbox registry | affected candidate | capability grant/organ assembly |
| `safety_resistance` | sandbox/lifecycle/topology denial | body policy | affected candidate | cannot be outweighed when hard deny |

### 7.2 Component behavior

```text
an eye refresh reduces observation debt only
☵ reduces encoding debt but adds loss and may create choice/observation debt
☳ reduces choice entropy but adds loss and consequence debt
☲ does not create continuation pressure; it spends one existing impulse
☶ reduces validation debt but may create repair or cycle pressure
☱ turns runtime/history state into current pressure; it does not invent tasks
```

## 8. Pressure Contribution Contract

```lua
{
  kind = string,
  source_ref = string,
  current_operator = glyph,
  target_operator = glyph,
  target_edge = "A-B",
  amount = number,
  reason = string,
  calculation_status = "runtime_confirmed" | "estimated",
  source_truth_status = string,
  freshness = number | status,
  derivation_version = string,
}
```

Table-level laws:

```text
amount may help or resist
hard lifecycle/safety deny is not a large negative number; it removes candidate
semantic proposal can contribute pressure without becoming truth
every contribution references an existing T1 record
every contribution expires with its derivation tick
```

Exact amount normalization is OPEN.

## 9. Candidate And Route Record

### 9.1 Candidate construction

```text
canonical = topology.neighbors(current)
directed  = apply Packet lifetime law
capable   = retain available operator organs/capabilities
safe      = apply sandbox and finality policy
ready     = apply minimum operator input witness
affordable= apply budget and near-death policy
candidates= intersection of all above
```

### 9.2 Candidate record

```lua
{
  to = glyph,
  edge = "A-B",
  contributions = {},
  positive = number,
  resistance = number,
  total = number,
  ready = boolean,
  affordable = boolean,
  exclusions = {},
}
```

### 9.3 Route decision

First control policy:

```text
select highest total among legal candidates above movement threshold
break exact ties by stable canon order
record all candidates, not only winner
do not use substrate/LLM tie-breaking
```

Softmax/temperature routing is out of v0 until deterministic edge statistics
exist.

## 10. No-Viable-Edge Outcome

This remains OPEN, but table constraints are fixed:

```text
no hidden default edge
no invalid jump toward a desired distant operator
no free self-loop
no LLM request to choose the route
```

Candidate physical outcomes to crystallize later:

| Condition | Candidate outcome |
|---|---|
| complete/usable form and terminal neighbor reachable | manifest pressure |
| needs external fact/capability explicitly unavailable | needs-user or blocked residue |
| no progress and no legal transformation | stalled death |
| unsafe/invalid body | immediate death |
| pressure below threshold but body can wait | explicit body hold outside Tree movement, if adopted |

## 11. Eye Freshness Replaces Hard Rails

Current scaffolding:

```text
☵ -> ☴
☳ -> ☴
☲ -> ☱
☶ -> ☱
```

Target physics:

| Completed mutation | View likely stale | Derived pressure | Direct alternative remains possible when |
|---|---|---|---|
| ☵ remap/form | upper observation and relations over changed units | toward ☴ and possibly ☰ | target operator can consume the runtime-confirmed encode result without refreshed semantic sight |
| ☳ suppression | upper view of consequences/remaining potential | toward ☴ | runtime commit or logic can consume explicit choice record directly |
| ☲ recurrence | lower progress/economics view | toward ☱ | direct ☵/☶/△ condition was already runtime-confirmed and remains fresh |
| ☶ verdict/effect | lower evidence/foundation view | toward ☱ | direct ☳/☲/△ condition is body-confirmed and fresh |

Promotion rule:

```text
do not delete rails because direct edges exist
delete rails only after shadow traces show freshness pressure recreates eyes when needed
```

## 12. Full 22-Edge Table

Each row gives both internal directions. For boundary edges, the reverse
same-life direction is forbidden by lifecycle law.

### 12.1 FLOW boundary edges

| Edge | Direction A -> B | Reverse | Required witness | Main pressure | First integration witness |
|---|---|---|---|---|---|
| `▽-☰` | Ingress produced multiple addressable units requiring relations. | `☰ -> ▽` forbidden same life. | at least two relation candidates | relation debt | prompt/carrier with two linked requirements produces `E_raw` |
| `▽-☷` | Ingress carrier contains rigid/stale inherited framing to release. | `☷ -> ▽` forbidden same life. | dissolvable inherited/form record with provenance | rigidity | child carrier with stale frame emits dissolution residue |
| `▽-☴` | Newborn potential needs first semantic/body observation. | `☴ -> ▽` forbidden same life. | bounded upper scope | upper observation debt | raw task reaches substrate membrane without prior structure |

### 12.2 Upper field edges

| Edge | Direction A -> B | Direction B -> A | Required witness | Main pressure | First integration witness |
|---|---|---|---|---|---|
| `☰-☷` | Newly detected relation is contradictory, stale, or too rigid. | Released parts need a new relation snapshot. | relation plus rigidity, or residue plus unbound endpoints | rigidity/relation debt | connect a false dependency, dissolve it, reconnect surviving units |
| `☰-☴` | Relation quality or completeness needs observation. | Observation reveals unbound candidate endpoints. | `E_raw` or observed unit delta | relation confidence/coverage | observe relation snapshot without changing endpoints |
| `☰-☵` | Stable relation motif supports an encoding. | New encoded identities need relation detection. | motif or remap invalidation set | encoding/relation debt | dependency motif encodes hierarchy; encoded ids reconnect |
| `☷-☴` | Dissolution result needs inspection. | Observation detects stale/rigid unsupported form. | dissolution event or rigidity observation | consequence/rigidity | stale evidence is observed, dissolved, then re-observed |
| `☷-☳` | Released potential exposes alternatives. | Suppressed alternatives need residue release. | at least two freed paths or choice residue | choice/dissolution | dissolve old constraint, choose path; choice residue returns through ☷ |

### 12.3 Middle field and eyes

| Edge | Direction A -> B | Direction B -> A | Required witness | Main pressure | First integration witness |
|---|---|---|---|---|---|
| `☴-☵` | Bounded observation is ready for representation. | Encode changed form and made the relevant view stale. | observation refs or encode remap event | encoding/upper observation | live substrate response encodes; changed form earns eye pressure |
| `☴-☳` | Observation exposes a separable possibility field. | Choice consequences require sight. | explicit alternatives or choice event | choice/consequence | observed alternatives collapse; killed paths remain visible |
| `☴-☱` | Potential-side view must meet actual runtime state. | Runtime lacks semantic fact or detects mismatch. | upper observation or lower uncertainty record | runtime mismatch/semantic uncertainty | runtime rejection requests repair observation, then returns lower |
| `☵-☱` | Encoded structure is installed/held; ☱ applies momentum invalidation. | Runtime representation no longer fits execution. | CALM plus invalidation set, or mismatch evidence | runtime/encoding | remap causes ☱ scoped momentum reset; stale runtime requests recode |
| `☵-☳` | Encoded form exposes explicit alternatives. | Chosen path needs narrower/rebuilt form. | possibility field or selected refs | choice/re-encoding | hierarchy alternatives choose one, then encode selected implementation |
| `☵-☲` | Encoded work defines a repeatable transform. | One recurrence requests another bounded encode pass. | work unit recurrence contract | continuation/encoding | iterative generator alternates encode and cycle until trigger/loss |
| `☳-☱` | Chosen path becomes executable runtime commitment. | Runtime exposes unresolved branch. | choice record or branch evidence | commitment/choice | selected work installs; runtime later raises new explicit branch |
| `☳-☶` | Chosen path needs validation. | Rules define admissible paths requiring commitment. | choice plus rule, or accepted candidate set | validation/choice | choose target then validate; logic filters set then choose one |

### 12.4 Lower field and terminal edges

| Edge | Direction A -> B | Direction B -> A | Required witness | Main pressure | First integration witness |
|---|---|---|---|---|---|
| `☱-☶` | Runtime needs test/rule/capability evidence. | Verdict/effect evidence enters runtime/foundation. | validation debt or fresh verdict | validation/lower observation | build artifact runs test and runtime records evidence |
| `☱-☲` | Remaining repeatable work is affordable. | Recurrence returns to owner of counters/progress. | fresh progress plus budget | continuation/accounting | N work units produce exactly N bounded cycles |
| `☲-☶` | Iteration/convergence claim needs checking. | Valid rule/test requests another bounded run. | cycle result or rerun verdict | repeated validation | test-run/fix loop traverses both directions without LLM routing |
| `☱-△` | Runtime sees completion, usable partial output, or near-death release. | forbidden same life | fresh readiness/economics/evidence | manifest/mortality | completed runtime state manifests and Packet becomes immutable |
| `☲-△` | Runtime-confirmed count/convergence/limit condition releases output directly. | forbidden same life | fresh terminal cycle condition | terminal recurrence | procedural generation reaches declared bound and manifests |
| `☶-△` | Validated artifact is directly materializable. | forbidden same life | accepted fresh evidence plus output contract | validated manifest | tests pass and validated code manifests without semantic reroute |

## 13. Cross-Edge Invariants

```text
every transition is adjacent and recorded
every intermediate operator performs real work
shortest path is never sufficient justification
direct edge does not bypass input readiness
boundary direction cannot be outweighed by pressure
death guard runs before routing
route decision never promotes semantic truth
choice loss occurs only when ☳ mutates potential
cycle never owns the reason or count of work
runtime remains sole E_momentum writer
```

## 14. Shadow Router Contract

The shadow router reads the same post-tick T1 state as the current router.

Output per tick:

```lua
{
  kind = "shadow_route_decision",
  current_operator = glyph,
  candidates = {},
  predicted_to = glyph | nil,
  predicted_reason = string,
  live_to = glyph,
  agreement = boolean,
  divergence = string | nil,
  truth_status = "runtime_confirmed",
}
```

Rules:

```text
no control authority
no Packet mutation except append-only shadow trace
same topology/lifecycle/capability filters as target router
all constants marked measured or vibed
invalid/no-candidate predictions remain visible
```

## 15. Edge Statistics Table

Required counters after shadow/live runs:

```text
edge candidate count
edge selected count
directional count
average positive pressure
average resistance
exclusion reasons
eye-rail agreement/divergence
completion correlation
budget-death correlation
identity-death correlation
stalled/no-candidate count
substrate/model/work-mode labels
```

Statistics observe behavior. They do not rewrite canon adjacency.

## 16. Promotion Gates

Full router authority is allowed only when:

```text
T1 body regions required by pressure exist
☰ and ☷ organs emit body-native events
all 22 edges have at least one integration witness or explicit untested status
shadow candidate records contain provenance
hard eye rails can be recreated by freshness pressure on cases that need them
direct edges do not bypass validation/freshness in adversarial tests
mortality still terminates before host tick limit
rollback switch preserves current router
live DeepSeek coding battery does not regress without an explained tradeoff
```

## 17. Current Route Mapping

| Current behavior | T2 interpretation | Migration state |
|---|---|---|
| start at `☴` after constructor | `▽-☴` seam exists but FLOW organ tick is implicit | needs explicit birth/FLOW trace |
| `☵ -> ☴` | hard upper eye rail | shadow first, then freshness replacement |
| `☳ -> ☴` | hard consequence eye rail | shadow first, then freshness replacement |
| `☲ -> ☱` | hard lower eye rail | shadow first, then freshness replacement |
| `☶ -> ☱` | hard lower evidence eye rail | shadow first, then freshness replacement |
| ☴ chooses among ☵/☳/☱ through router predicates | partial upper pressure tree | convert returns to contributions |
| ☱ chooses among ☴/☲/☶/△ through router predicates | partial lower pressure tree | convert returns to contributions |
| ☰/☷ absent | seven edges are directly unreachable; fifteen total edges remain unexercised or incomplete for several causes | blocked until organs, T1 relations, and free routing |
| mutable `instance.tension` | mixed snapshot/source | replace with versioned derived snapshot |

## 18. T2 Open Rows Before Crystall

```text
pressure normalization and movement threshold
exact no-viable-edge terminal contract
organ/capability registry shape
whether a body-level hold exists outside operator movement
minimum relation readiness for ☰ with one current unit plus inherited record
manifest-pressure propagation when current operator is not terminal-adjacent
conditional runtime/dissolve/logic loss formulas
tie behavior after deterministic v0
edge-test corpus beyond synthetic tasks
```

## 19. T2 Acceptance

This table is ready to feed T3 and later crystall when:

```text
all 22 canon edges appear exactly once as unique rows
both directions are described for every internal edge
▽ and △ lifetime directions are explicit
operator writes do not conflict with T1 ownership
router selection is separated from ☳ semantic collapse
eyes measure while router owns route authority
pressure records name T1 sources and readers
current hard rails are marked scaffolding with a measured removal path
lineage recurrence is absent from the 22-edge walk
```

## Amendment A1: Runtime Camera And Reconciliation Routing

Status:

```text
CAMERA CONFIRMED IN SHADOW / TREATMENT PARTIALLY CONFIRMED
source: docs/00_chaos/runtime_camera_reconciliation_hypothesis_notes.md
body amendment: packet_body_physics_yellowprint.v0.md Amendment A1
old rows remain as historical pre-audit design
no rail removal or router promotion authorized
initial treatment status was PENDING; outcome is appended below
```

### A1.1 Defect annotation

The current table maps any stale lower progress/evidence/budget/loss/foundation
sample to `lower_observation_debt -> ☱`. Runtime code also maps the same stale
sample to `runtime_mismatch -> ☱` when CALM exists.

Observed consequences:

```text
routine body cost makes lower freshness stale every tick
one stale source contributes twice to ☱
☱ receives total 2 while most candidates receive 0 or 1
shadow lower-rail recall is therefore not valid promotion evidence
```

This amendment does not dispute strict historical freshness. It disputes the
direct mapping from every lower revision change to route pressure.

### A1.2 Candidate tick protocol amendment

Insert a body-owned camera stage after all current tick economics/effects and
before mortality/pressure:

| Order | Stage | Owner | Required result |
|---:|---|---|---|
| 7 | cost/loss application | budget/loss physics | append-only records |
| 8 | operator physics and revision effects | body | final post-tick state |
| 9 | runtime camera capture | Packet runner/body | immutable frame, no extra step |
| 10 | mortality and safety guards | body | die now or remain alive |
| 11 | pressure derivation | named readers | current contributions |
| 12 | candidate filtering/selection | router | one audited movement |

Exact numbering supersedes section 3 only if the treatment experiment passes.

### A1.3 Candidate ☱ contract amendment

| Operator | Required input | Distinguishing write | Explicit no-op | Forbidden |
|---|---|---|---|---|
| `☱ RUNTIME` | significant unintegrated runtime frames, actual CALM/runtime mismatch, recurrence, or bounded history pressure | reconciliation record, watermark, `M`, active `E`, foundation/completion integration | `nothing_to_reconcile` | LLM call, semantic rewrite, route choice, generic snapshot-only tick |

Routine current runtime availability is no longer sufficient readiness by
itself. `physis:budget` existing does not justify a ☱ tick.

### A1.4 Pressure vocabulary amendment

| Current kind | Defect status | Treatment candidate |
|---|---|---|
| `lower_observation_debt` | sampled lower view is stale from routine body economics | replace route use with `runtime_reconciliation_debt` |
| `runtime_mismatch` | implementation duplicates lower freshness | require independent CALM/runtime comparator or emit nothing |
| `manifest` | normal legacy completion is not represented Packet-locally | derive from reconciliation/completion and manifestable Packet material |
| `continuation` | may already be directly body-confirmed | do not force ☱ unless recurrence consequence needs integration |

Candidate new kind:

| Kind | Minimum witness | Primary target | Discharge |
|---|---|---|---|
| `runtime_reconciliation_debt` | at least one significant body-confirmed runtime frame after the last applicable reconciliation | ☱ | successful ☱ reconciliation covering exact frame refs |

Non-witnesses by default:

```text
clock advanced
one expected step was charged
trace appended an already-accounted event
```

Threshold transitions remain evidence, but may target mortality or △ directly.

### A1.5 Lower rail interpretation

Current rails stay authoritative:

```text
☲ -> ☱
☶ -> ☱
```

The treatment must grow both classes before either rail can be reconsidered:

| Case | Expected shadow behavior |
|---|---|
| cycle/logic produced significant unintegrated runtime consequence | select or strongly support ☱ |
| cycle/logic effect is already attached and direct next condition is confirmed | permit a non-☱ adjacent edge |
| routine budget-only change | do not select ☱ solely for that change |
| CALM contradicts actual effect | select ☱ from independent mismatch evidence |

### A1.6 E11 interpretation

The `☴-☱` edge gains a precise candidate reading:

```text
☱ -> ☴
  reconciled runtime still contains semantic uncertainty
  ☱ records bounded unresolved runtime refs
  ☴ may show those refs to the substrate as semantic context

☴ -> ☱
  semantic proposal refers to runtime state but has not been reconciled
  ☱ compares body facts without promoting proposal truth
```

LLM access remains inside ☴. The amendment does not add substrate calls to ☱.

### A1.7 Diagnostic before treatment

First diagnostic matrix:

```text
C0 current policy
A  disable duplicate runtime_mismatch
B  ignore routine budget/loss deltas only for lower routing debt
AB combine A and B
```

Second treatment comparison, only after diagnosis:

```text
L0 sampled lower-eye routing debt
L1 continuous runtime camera + reconciliation debt, shadow only
```

Required measurements:

```text
per-reader variation
candidate totals
rail recall/bypass
E05/E12/E15 predictions
normal manifest prediction
prediction errors
live route/economics equality
```

### A1.8 Promotion impact

Step 10 remains blocked until at minimum:

```text
duplicate lower contribution is absent
routine ticks do not create constant ☱ pressure
real unintegrated effects recreate ☱ pressure
normal completion creates a Packet-local path to △
trace frames are immutable
shadow failures are typed separately from physical no-edge outcomes
```

Outcome:

```text
status: CAMERA CONFIRMED IN SHADOW / TREATMENT PARTIALLY CONFIRMED
diagnostic evidence: docs/00_chaos/pressure_ablation_diagnostic_results_2026-07-16.md
treatment evidence: docs/00_chaos/runtime_camera_treatment_results_2026-07-16.md
old lower-eye rows: retained, disputed for routing use
confirmed: current runtime_mismatch removed from L1; routine frames create no debt; significant frames do
rejected: E05 and all E12 selections disappear under A/AB
open: tied binary pressure can support ☱ without selecting it; independent mismatch and manifest remain absent
```
