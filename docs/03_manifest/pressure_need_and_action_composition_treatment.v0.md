# Qualified Pressure Treatment Manifest v0

Amendment 2026-07-19:

```text
The action-mode inventory and partial-pressure limits in this W0 record are
historical. Exact structure_formation and alternative_collapse treatment is
manifested in qualified_encode_choose_treatment.v0.md. Exact plan completion
and delivery are manifested in post_collapse_plan_delivery.v0.md. Keep this
document as the route-to-effect foundation; read the newer manifests for the
current action surface. Default-authority restrictions remain unchanged.
```

Status:

```text
manifest
W0 treatment implemented and locally verified 2026-07-19
source table: docs/01_table/yellowprints/pressure_need_and_action_composition_yellowprint.v0.md
source crystall: docs/02_crystall/blueprints/pressure_need_and_action_composition.v0.md
default router promotion: forbidden
full 38-direction promotion corpus: not authorized
bounded qualified treatment corpus: authorized
```

## Result

The body now has a second pressure language beside the historical binary
control. A qualified pressure witness is no longer only a positive number on
an edge. It is one current body fact joined to one bounded executable action:

```text
current Packet fact
-> pressure.witness.v1
-> pressure.action_plan.v0
-> class composition
-> committed route evidence
-> exact organ readiness
-> exact effect scope
```

The implementation is selected only by:

```lua
pressure_policy = "qualified_need_v0"
```

The default remains `router_mode=shadow` with the historical
`camera_reconciliation` binary policy. Qualified pressure may observe that
life without changing it. Explicit qualified tree lives are treatment fixtures,
not a default authority change.

## Manifested Contracts

### One relation detector

`runtime/relation_inspection.lua` is the pure bounded source for:

```text
relation pressure
CONNECT readiness
CONNECT execution revalidation
```

Candidate identity includes predicate, directional endpoints, exact endpoint
versions and provenance. A coverage gap with no registered candidate may make
one bounded CONNECT probe ready, but it creates no autonomous pressure.

The initial named consumer is exactly:

```text
encode.relation_formation.v0
accepted predicates:
  connect.parent_carrier.v0
  connect.l1_registered_projection.v0
causal class: causal_affordance
```

Before CONNECT, a supported missing/stale candidate produces
`relation_recognition_need -> ☰`. After CONNECT, an available/observed raw
relation produces `relation_formation_need -> ☵`. ENCODE terminally discharges
that formation phase. No mutable need object crosses phases; each witness is
re-derived from current field and immutable trace.

### Versioned upper sight

`runtime/upper_coverage.lua` derives observation coverage by:

```text
(field unit id, exact version, observation class)
```

Initial classes and sensors are:

```text
semantic -> semantic OBSERVE
material in vertical life -> field-native OBSERVE
material outside vertical life -> semantic OBSERVE
relation -> relation-native OBSERVE when an explicit body plan exists
```

Routine budget, loss and clock changes do not create upper pressure. L1
physical samples and grave units do not create generic upper pressure.
Unknown field mutations remain typed diagnostics and make the affected
snapshot ineligible for promotion.

Semantic OBSERVE prevalidates its output unit and records that planned version
inside the same trusted commit as the observation. Its own unchanged output
therefore cannot immediately demand a second sight.

### Action plans

`runtime/pressure_action.lua` owns canonical action identity, schema
validation, compatible merge, precondition checks, registry context projection,
and same-scope verification.

Allowed v0 action modes are:

```text
connect_probe
relation_formation
semantic_observe
field_native_observe
relation_native_observe
```

Unknown options, mode/target mismatch, forged plan identity, stale object
versions, caller scope replacement, and readiness/effect scope mismatch fail
loudly as harness invariants. They do not become Packet deaths.

### Class composition

`runtime/pressure_composition.lua` applies this non-numeric order:

```text
terminal_boundary > blocking_demand > causal_affordance
```

It filters lifecycle, capability, readiness and affordability before choosing.
Compatible same-target actions merge. Independent equal needs return
`ambiguous_pressure`; incompatible same-target actions return
`ambiguous_action`. A canonical fallback exists only as an explicit control and
is always `promotion_eligible=false`.

### Route-to-effect authority

The chosen action is copied into the immutable `route_derivation`, then into
the committed `route` event. `runtime/tension_runner.lua` obtains the next
organ context from that committed event rather than reconstructing scope from
runner options.

The equality gate is:

```text
witness scope == action scope == readiness scope == effect scope
```

The route event records `selected_action_plan_id`. The receiving tick rejects a
target mismatch, identity mismatch, stale precondition or caller override
before organ execution. The effect is checked before body physics and arrival
credit are recorded.

## Named Readers

| Written record | Named reader | Activation |
|---|---|---|
| relation inspection | qualified relation reader, CONNECT readiness and execution | each derivation/selected probe |
| upper coverage observation | upper need derivation | each qualified pressure derivation |
| qualified witness | pressure composition | same route derivation |
| action plan in route derivation | Packet route commit | selected tree decision |
| action plan in route event | tension runner and operator registry | receiving operator tick |
| unqualified diagnostic | composition promotion gate and tests | same snapshot |
| typed composition outcome | shadow comparison / edge statistics | each router observation |

No new mutable ledger was introduced for relation need, upper need or action
carry.

## Grown Evidence

Permanent relation cases now cover:

```text
empty domain: readiness may exist, pressure absent
registered exact pair: one recognition affordance
CONNECT: recognition absent, formation present
relation ENCODE: formation absent
unrelated formed unit: no invented relation need
endpoint version change: stale raw form, exact re-armed recognition
consumer ablation: candidate remains, pressure disappears
unchanged fact: deterministic witness identity, no visit-based discharge
```

Permanent upper cases now cover:

```text
empty field: no upper need
prompt: exact semantic action
semantic own output: atomically covered
L1 physical sample: no generic sight debt
ENCODE material: exact field-native action in vertical life
field-native effect: exact discharge
CHOOSE activation versions: exact re-arm
DISSOLVE activation version: one exact re-arm
unknown unit class: typed unqualified diagnostic
```

Permanent composition/action cases cover:

```text
blocking demand beats affordance independent of glyph order
terminal class beats nonterminal in the pure algorithmic control
equal independent demands remain ambiguous
incompatible same-target modes remain ambiguous_action
capability exclusion occurs before class selection
compatible action scopes merge deterministically
control fallback is deterministic and promotion-ineligible
caller action scope override fails loudly
```

The body-grown qualified action-carry fixture executes without harness-supplied
organ scopes:

```text
▽ -> ☰ relation recognition
☰ -> ☵ relation formation
☵ -> ☴ field-native material sight
```

Every destination payload discharges the exact scope sealed in its route. A
separate fake-substrate fixture selects `▽ -> ☴` by blocking semantic need and
uses the same action-carry boundary.

## Shadow Ablation

Matched legacy lives were run with:

```text
pressure_policy=camera_reconciliation
pressure_policy=qualified_need_v0
router_mode=shadow
```

The following remained equal:

```text
live routes
body ticks
step and substrate-call economics
identity loss
Packet revision vector
```

Only pressure snapshots, predictions and typed outcome counters changed. The
qualified observer named `selected` and `no_qualified_need` outcomes in
`edge-stats.v2`; it acquired no movement authority or physical mass.

## Verification

```text
lua tests/run.lua                               61 suites passed
tests/test_relation_need.lua                    passed
tests/test_upper_observation_need.lua           passed
tests/test_pressure_action.lua                  passed
tests/test_pressure_composition.lua             passed
tests/test_qualified_pressure_shadow.lua        passed
lua tests/smoke_mortality_battery.lua           8/8 passed
lua tests/smoke_deepseek_mortality_battery.lua  2 live cases passed
lua tests/smoke_runtime_camera_treatment.lua    passed
lua tests/smoke_pressure_ablation.lua           passed
luac -p over all Lua sources                    passed
```

The historical pressure ablation retained its prior binary outputs. This is
control evidence that W0 did not silently rewrite `pressure.binary.v0`.

## Explicit Limits

```text
qualified witnesses currently cover relation recognition/formation and upper sight
lower camera/reconciliation still uses the separate binary witness family
generic semantic ENCODE, CHOOSE, DISSOLVE, LOGIC, CYCLE and terminal action
  do not yet have pressure.action_plan.v0 producers
MANIFEST still depends on runner-projected result material
relation projection adapters remain deterministic fixtures
fixture promotion_source cannot satisfy production promotion evidence
no numeric Z/Tau calibration was attempted
no age/fairness policy was added
no default router authority changed
no 38-direction corpus direction is relabelled green by this manifest alone
```

Qualified tree authority over an incomplete witness vocabulary honestly stalls
with `no_qualified_need`. That is expected evidence, not proof that the full
body can already govern every task life.

## Corpus Decision

The deterministic corpus decision is split deliberately:

```text
bounded W0 R/U/C treatment corpus: YES, begin and keep permanently
full tree-authority promotion corpus: NO, still blocked
default authority promotion: NO
```

The bounded corpus may grow action-owned evidence for the directions exercised
by relation and upper sight. It may not claim full-tree closure, and fixture
projection routes remain supporting mechanics rather than promotion evidence.

The full corpus may begin only after the next bounded treatments give named
actions to enough remaining pressure families that a complete Packet life can
reach honest terminal without binary fallback or `no_qualified_need`. The next
work should therefore expand qualified witnesses by body domain, preserving
the same shadow/ablation/action-carry gates, before attempting 38-direction
closure.

## Decision

W0 is complete. Pressure now carries a bounded bodily verb rather than only a
glyph preference. The treatment is permanent, shadow-safe and ready to serve
as the pattern for the remaining pressure families. It is not a coronation.
