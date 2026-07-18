# Vertical Packet Life Manifest v0

Status:

```text
manifest
roadmap step 4
implemented and locally verified 2026-07-18
source crystall: docs/02_crystall/blueprints/vertical_packet_life_gate.v0.md
default router promotion: forbidden
production source adapter: not selected
```

## Result

One opt-in Packet life now crosses the selected L1, L2, CALM and lower-body
contracts without replacing the live default:

```text
continuing L1 flow_domain
-> atomic Packet birth and bounded ingress projection
-> exact transient raw relation
-> observe | release | form
-> CALM/lower body
-> honest MANIFEST and terminal corpse
```

The integration is enabled only by:

```lua
packet_life = {
  protocol_version = "vertical_packet_life.v0",
  flow_domain = domain,
  projection_adapter = "vertical_single.v0" | "vertical_pair.v0",
}
```

Absent or unknown protocols retain the legacy control. Fixture-selected routes
carry `authority=harness_override` and are ineligible for router promotion.

## Manifested Contracts

### L1 birth

`runtime/flow_domain.lua` owns one continuing L1(C) state outside mortal
Packets. One accepted birth advances it exactly once. Projection or Packet
construction failure rolls the tentative tick and birth sequence back.

The newborn owns a bounded flow mark; the mark is audit provenance, not route,
semantic, relation, or lineage authority. Packet death does not stop the domain.

### FLOW ingress

`FLOW` materializes prompt/carrier, bounded physical projection, and inherited
grave pressure as distinguishable field units. The flow mark itself never
becomes an addressable unit. Duplicate FLOW materialization is rejected.

### Exact L2 probe

`runtime/object_coverage.lua` records ordered `{object_id, version}` coverage.
The raw epoch is its own probe stamp. An unchanged object set cannot re-arm
CONNECT merely because a global revision moved.

Registered pair projection yields one body-detected non-semantic raw relation.
Single projection yields one honest empty epoch. Vertical CONNECT rejects
caller-injected candidates.

### Three raw dispositions

`field.raw_relation_phase` derives phase from current field plus immutable
trace; no mutable lifecycle ledger exists.

```text
☴ relation_native  -> observed, non-terminal, no substrate or retained form
☷ scope=raw        -> released, terminal, optional unit residue, zero formed loss
☵ relation_input  -> encoded, terminal, CALM form + identity map + explicit loss
```

RUNTIME cannot activate raw relations in the vertical protocol. Contradictory
terminal dispositions are a loud invariant failure.

### Retained form

Only ENCODE originates retained relation structure. CALM stores
`l2.relation_formation.v0`, formed unit ids, exact raw provenance and a
deterministic `identity_map:N` reference. The legacy `relations.active`
surface stays empty.

Formation loss is derived from identity compaction. The pair fixture forms
`2 -> 1` identities and therefore records `loss=0.5`.

### Body-native sight

OBSERVE now owns separate sensors:

```text
semantic       requires substrate.ask and emits proposal content
relation_native reads exact raw relation/endpoints without LLM or output unit
field_native    reads exact arbitrary field-unit versions without LLM or output unit
```

Native sensors spend a body tick but no substrate call and create no identity
loss.

## Grown Evidence

| Life | Runtime-confirmed result |
|---|---|
| A | One physical sample produces one covered empty probe and no repeat |
| B | Raw relation is observed without field growth, CALM, retention, or substrate |
| C | Raw relation is released without activation or identity loss |
| D | Formed relation crosses ☲, ☶, ☱ and △ to a complete corpse |
| E1 | One new formed unit re-arms CONNECT exactly once |
| E2 | CHOOSE version changes re-arm upper sight exactly once |
| F | Real-file referent mutation creates one validation debt; recast discharges it |

Life D:

```text
▽ FLOW -> ☰ -> ☵ -> ☲ -> ☶ -> ☱ -> △
6 charged Packet ticks
0 substrate calls
identity loss 0.5
manifest sources include birth, raw epoch and formation events
final status dead
death cause complete
source flow_domain remains open
```

The arrows are canonical and body-committed, but selected by the V-PHYSICS test
harness. They prove organ seams and body laws, not pressure routing quality.

## Ablation Evidence

```text
OFF absent/unknown integration -> legacy walk/economics/loss unchanged
remove raw relation            -> no relation-guided ENCODE
disable relation reader        -> no hidden raw consumption
mask Packet flow mark          -> L2 semantics/economics/loss unchanged
disable L1 projection          -> relation seam goes dark
disable lower update           -> no runtime reconciliation provenance
reject real validation         -> blocked manifest and blocked corpse
```

The flow-mark mask is an intentionally invalid post-FLOW test state. It proves
non-authority; it is not an allowed production Packet.

## Verification

```text
lua tests/run.lua                              56 suites passed
tests/test_vertical_packet_life.lua            A-F passed
tests/test_vertical_packet_life_ablation.lua   OFF/ON ablations passed
tree authority Gate A                          10/10 passed
tree instrumentation Gate B                    7/7 passed
tree manifest honesty                          4/4 passed
lua tests/smoke_mortality_battery.lua           8/8 passed
lua tests/smoke_runtime_camera_treatment.lua    passed
lua tests/smoke_pressure_ablation.lua           passed
luac -p over all 128 Lua sources                passed
git diff --check                               passed
```

## Explicit Limits

```text
vertical_packet_life.v0 remains opt-in
projection adapters are deterministic fixtures, not production prompt seeding
routes are harness_override, not tree-authority evidence
coverage is a freshness fact, not automatically relation pressure
relation_need, upper-eye pressure and pressure composition remain untreated
binary coefficients and canonical tie-break remain uncalibrated
general multi-organ rollback remains absent
outer lineage runner and production L1 ownership remain later work
repository hands, machine CLI and Go TUI remain absent
```

The old pressure ablation still exposes the known witness disease. This
manifest does not relabel it as solved.

## Decision

Roadmap step 4 is complete. The four layers can participate in one mortal,
auditable Packet life. The live default does not change.

Roadmap step 5 now has concrete body facts to read: exact probe deltas, exact
upper sight deltas, raw dispositions, formed CALM provenance and terminal
evidence. It must repair witnesses and measure routing before any promotion.
