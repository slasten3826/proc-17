# Vertical Packet Life Implementation Observations - 2026-07-18

Status:

```text
chaos / runtime observation log
roadmap step 4
contract: docs/02_crystall/blueprints/vertical_packet_life_gate.v0.md
live default promotion: forbidden
```

## 4.1 Flow Domain And Atomic Birth

Implemented:

```text
runtime/flow_domain.lua
runtime/packet_birth.lua
versioned Packet ingress/flow mark storage
corpse and packet-memory mark projection
tests/test_flow_domain.lua
```

Runtime-confirmed observations:

```text
one accepted birth advances birth_seq and L1 ticks exactly once
failed Packet construction after tentative tick commits neither
failed birth clears the in-process serialization lock
Packet death leaves the source domain open
the next Packet receives a distinct ordered mark
two domains do not advance one another
receipt/corpse copies cannot rewrite Packet/domain records
frozen domain rejects another birth
lua tests/run.lua -> 48 suites green
```

Interpretation:

```text
continuity now belongs to flow_domain
mortality remains local to Packet
flow_mark is bounded evidence, not route or semantic authority
```
## 4.2 Ingress Projection And FLOW Materialization

Implemented:

```text
registered vertical_single.v0 and vertical_pair.v0 fixture projections
projection construction inside the atomic L1 birth transaction
grave preflight before accepted birth in the opt-in runner path
grave attach before FLOW in the opt-in runner path
multi-unit FLOW materialization with explicit provenance classes
duplicate FLOW rejection in the organ as well as registry readiness
tests/test_vertical_ingress.lua
```

Runtime-confirmed observations:

```text
pair ingress materializes prompt + two non-semantic L1 samples
single ingress materializes prompt + one non-semantic L1 sample
flow_mark remains provenance and is not an addressable field unit
FLOW creates neither raw/active relations nor CALM form
unknown projection adapter rolls back the tentative L1 tick and birth sequence
invalid inherited grave fails before Packet birth and consumes no L1 event
second FLOW call cannot duplicate materialized units
the default Packet/FLOW path remains the one-unit control
lua tests/run.lua -> 49 suites green
```

Interpretation:

```text
L1 now reaches the newborn through a bounded physical fixture seam
the seam has no routing, semantic or retention authority
CONNECT remains the first organ allowed to recognize a relation
```

## 4.3 Object-Version Coverage And Exact CONNECT Probe

Implemented:

```text
pure runtime/object_coverage.lua capture/diff/ref contract
field coverage domains ordered by canonical unit_order
field.raw_relations.v1 probe policy and object coverage
registered L1 structural candidate recognition in CONNECT
exact probe readiness for vertical_packet_life.v0 only
tests/test_object_coverage.lua
```

Runtime-confirmed observations:

```text
same object ids and versions produce an empty delta regardless of global revision
new unit and changed version produce exact versioned source refs
pair projection is recognized as one raw non-semantic relation
single projection writes one honest empty raw epoch
the raw epoch itself discharges immediate CONNECT repetition
legacy CONNECT behavior remains the default control
lua tests/run.lua -> 50 suites green
```

Interpretation:

```text
probe freshness is now spatially exact rather than revision-shaped
coverage is a body fact, not yet a pressure vote
the new reader is active only inside the opt-in vertical life
```

## 4.4 Derived Raw Relation Phase

Implemented:

```text
pure field.raw_relation_exact lookup
pure field.raw_relation_phase derivation from current field plus immutable trace
dedicated relation_formation trace event right for ENCODE
contradictory terminal disposition invariant
tests/test_relation_phase.lua
```

Runtime-confirmed observations:

```text
new raw identity derives available
matching native observation derives observed without consuming it
exact formation and release derive distinct terminal phases
endpoint version change derives stale
Packet terminality derives expired
encoded plus released for one raw identity is rejected loudly
lua tests/run.lua -> 51 suites green
```

Interpretation:

```text
raw phase is a causal projection, not a mutable lifecycle object
no second phase ledger can disagree with field and trace
future organs must consume the same epoch/id/endpoint-version tuple
```

## 4.5 Body-Native Relation OBSERVE

Implemented:

```text
mode-aware OBSERVE capability contract in operator registry
relation_native readiness over exact raw refs
body-native observation envelope with versioned endpoint coverage
zero-output native sensor path in organs/observe.lua
substrate charging bypass only for explicit substrate_called=false
tests/test_relation_native_observe.lua
```

Runtime-confirmed observations:

```text
relation-native OBSERVE executes with no substrate capability
semantic OBSERVE still requires substrate.ask
native sight appends no chaos fragment, field unit, active relation or CALM form
observation stores exact endpoint versions and its writer event ref
unchanged exact relation cannot be observed twice
raw phase moves from available to observed and remains non-terminal
lua tests/run.lua -> 52 suites green
```

Interpretation:

```text
the glyph owns sight; LLM mediation is one sensor rather than the organ itself
body-native sight has body cost but no substrate call or identity loss
```

## 4.6 Raw DISSOLVE Without Retention

Implemented:

```text
exact raw-release readiness with registered body-visible fixture policies
field.release_raw_relation terminal disposition writer
optional residue as a new bounded unit
vertical caller-candidate rejection in CONNECT
vertical raw activation denial in RUNTIME field API
tests/test_raw_dissolve.lua
```

Runtime-confirmed observations:

```text
raw release changes derived phase without mutating the raw causal record
relations.active stays empty and its revision does not move
release without residue does not grow potential
optional residue is a live unit, never a retained relation
raw release contributes zero formed-identity loss
released identity rejects a second release
lua tests/run.lua -> 53 suites green
```

Interpretation:

```text
DISSOLVE can end potentiality without first pretending that potentiality was form
only ENCODE may originate retained structure in vertical_packet_life.v0
```

## 4.7 Relation-Guided ENCODE Into CALM

Implemented:

```text
exact relation-guided ENCODE readiness
deterministic identity_map:N planning before crystallization
CALM-owned l2.relation_formation.v0 form
new formed_relation field units and relation_guided identity map
dedicated relation_formation event
identity-compaction loss derived from old/new identity counts
tests/test_relation_guided_encode.lua
```

Runtime-confirmed observations:

```text
available or observed exact raw relation can form once
CALM references the final identity map without post-hoc rewrite
two endpoint identities compact to one formed identity with loss 0.5
source content truth remains non_semantic_measurement
relations.active stays empty
raw phase derives encoded from the dedicated formation event
ordinary text ENCODE reports semantic_text rather than relation_guided
lua tests/run.lua -> 54 suites green
```

Interpretation:

```text
raw relation is potentiality; retained relation form belongs to ENCODE/CALM
formation pays visible identity loss while DISSOLVE and OBSERVE do not
```

## 4.8 Grown Vertical Lives A-F

Implemented:

```text
tests/support/vertical_life.lua V-PHYSICS harness
tests/test_vertical_packet_life.lua
field_native upper-eye sensor required by Life E2
manifest provenance refs for birth/raw relation/relation formation
vertical relation policy excludes semantic prompt but includes formed/residue units
```

Runtime-confirmed observations:

```text
A single physical sample produces one covered empty probe and no repeat
B native sight observes without substrate, field growth, CALM or retention
C raw release leaves zero identity loss and optional unit residue
D six paid ticks reach complete terminal with loss 0.5 and zero substrate calls
E1 one formed unit re-arms CONNECT once with its exact id/version
E2 CHOOSE version changes re-arm upper sight once and are then covered
F real-file evidence changes validation debt once and recast discharges it
all grown routes are harness_override and promotion_eligible=false
lua tests/run.lua -> 55 suites green
```

Observation from E2:

```text
real CHOOSE changes both selected and suppressed unit versions
upper coverage therefore reports both exact deltas
the test requires the suppressed current-version ref without hiding selection
```

## 4.9 OFF/ON And Component Ablations

Implemented:

```text
tests/test_vertical_packet_life_ablation.lua
OFF absent/unknown protocol matched control
raw relation, relation reader, flow mark, projection and lower-update ablations
accepted versus rejected validation terminal comparison
```

Runtime-confirmed observations:

```text
absent and unknown packet_life protocols preserve legacy walk/economics/loss
without raw relation ENCODE cannot claim relation_guided
field-native sight cannot secretly consume raw relation
masking only Packet flow_mark after FLOW changes no L2 relation/economics/loss
without L1 projection semantic prompt cannot keep the fixture seam green
without ☱ a terminal may exist but runtime reconciliation provenance is absent
rejected real-file evidence reaches blocked manifest and blocked corpse
lua tests/run.lua -> 56 suites green
```

Boundary:

```text
the flow_mark mask is an explicit invalid-Packet ablation after FLOW
it is evidence of non-authority, not an authorized production state
```

## 4.10 Treatment Manifest And Final Audit

Manifested:

```text
docs/03_manifest/vertical_packet_life.v0.md
docs/03_manifest/current_state.md
```

The treatment manifest names the implemented L1/L2/body contracts, the six
grown lives, the OFF/ON ablations, the verification surface and the limits that
remain outside this treatment. It does not promote either the fixture harness
or the tree router.

The final contract audit found and repaired three narrow boundary errors:

```text
invalid inherited_graves now rejects before the tentative L1 transaction
historical raw epochs preserve their own snapshot event provenance after replacement
plural relation inputs may carry the union of exact endpoint versions
```

The plural input rule is still exact per referenced relation: every expected
endpoint id/version must match. Extra entries are accepted only because one
formation event may name several raw relations and therefore carry their union.

Runtime-confirmed final observation:

```text
lua tests/run.lua                              56 suites green
lua tests/smoke_mortality_battery.lua          8/8 green
lua tests/smoke_runtime_camera_treatment.lua   green
lua tests/smoke_pressure_ablation.lua          green
luac -p over all 128 Lua sources               green
git diff --check                               green
```

The pressure ablation still exposes the known old witness disease. This is the
starting evidence for roadmap step 5, not a reason to grant routing authority
during step 4.

Decision:

```text
roadmap step 4 complete
vertical_packet_life.v0 remains opt-in
default live routing remains unchanged
router promotion remains forbidden
```
