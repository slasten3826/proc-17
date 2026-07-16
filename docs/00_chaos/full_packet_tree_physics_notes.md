# Full Packet Tree Physics Notes

Status:

```text
chaos
source synthesis, not an implementation contract
date: 2026-07-16
scope: one Packet life, the full 22-edge Tree, and lineage mechanics
table projection assembled: 2026-07-16
crystall projection assembled: 2026-07-16
```

Table projections:

```text
docs/01_table/yellowprints/packet_body_physics_yellowprint.v0.md
docs/01_table/yellowprints/operator_tree_physics_yellowprint.v0.md
docs/01_table/yellowprints/lineage_mechanics_yellowprint.v0.md
```

Crystall projections:

```text
docs/02_crystall/blueprints/packet_body_physics.v0.md
docs/02_crystall/blueprints/operator_tree_physics.v0.md
docs/02_crystall/blueprints/lineage_mechanics.v0.md
```

## 0. Why This Document Exists

Proc-17 is currently uneven in a useful way.

It already has working crystals and manifests for:

- packet birth and finality
- semantic observation through a substrate
- encode and choose
- runtime evidence
- cycle and logic
- budget, loss, mortality, grave, and compost
- a pressure-driven route skeleton

It also has a large chaos archive that records how those parts were found.

What it does not yet have is one shared table-shaped account of the body:

```text
what physically exists in a Packet
which operator may read or change each part
what produces pressure toward each neighboring operator
how all 22 canonical edges differ
where one Packet ends and another begins
```

This document is the chaos source for that missing table layer.

It must not be treated as a final schema. Its job is to assemble the physics
well enough that later yellowprints can separate it without losing the whole.

## 1. Epistemic Labels

The source corpus contains several generations of the same idea. They must not
be flattened into one authority level.

This document uses six labels:

```text
[CANON]
  operator identity, glyphs, layers, and the 22 undirected adjacencies from
  ProcessLang/canon.lua

[DECISION]
  a current proc-17 boundary or architecture decision confirmed during the
  rebuild

[ANCESTOR]
  a useful mechanism found in slop.raw, UPM Packet mathematics, PacketNet, or
  the Zig Packet prototype; preserve its invariant, not necessarily its shape

[DERIVED]
  a technical consequence assembled from canon, current decisions, and live
  runtime evidence; it still needs a table, crystal, and experiment

[OPEN]
  unresolved pressure; do not hide it inside code or a vibed constant

[RUNTIME]
  behavior already demonstrated by the current proc-17 code and tests; this
  confirms the present body, not every proposed future representation
```

Current code and green tests are runtime evidence for what proc-17 does now.
They are not automatically the final physics.

Myth is allowed to compress the architecture. Myth does not write
`runtime_confirmed` physics.

## 2. Source Order And Conflict Law

The sources used here are:

```text
ProcessLang/canon.lua
ProcessLang Lua operator manifestations
ProcessLang state-transfer documents
stak2/00_chaos/slop.raw.txt
UPM/MOS/packet.txt and packet2.md
PACKET_MODEL.md
DISSIPATIVE_MATHEMATICS.md
DISSIPATIVE_OPERATORS.md
packet_zig.raw layers 0-4
current proc-17 Lua body, tests, and chaos history
packet lineage, truth-rent, grave, compost, and karma notes
```

Conflict resolution:

1. `canon.lua` owns operator inventory and adjacency.
2. Current proc-17 decisions own Packet lifetime and boundary direction.
3. Current runtime evidence owns statements about what the code does today.
4. Ancestral documents supply mechanisms and invariants, not automatic schema.
5. New synthesis stays `[DERIVED]` until tested.

Examples:

```text
old Packet Model: OBSERVE chooses next_module
current decision: router owns routing; OBSERVE only observes

old Packet Model: fixed Z[K,D]
current decision: Packet field is task-shaped; preserve Z semantics, not shape

old Packet Model: MANIFEST may be an intermediate readout
current decision: △ is terminal for one Packet life

old NETWORK: exports a living Packet
current decision: identity never crosses △; NETWORK@▽ carries a new birth input
```

These are explicit revisions, not silent reinterpretations.

## 3. Core Thesis

[DERIVED]

```text
A Packet is a mortal, task-shaped field of potential, relations, formed state,
constraints, observations, and irreversible history.

It walks the ProcessLang Tree one adjacent edge at a time.

The next edge is produced by a pressure gradient derived from Packet state,
topology, affordability, freshness, capability, and history.

The substrate supplies semantic current but does not own the route.

△ materializes a carrier and ends that Packet identity.

A lineage may feed that carrier through NETWORK@▽ and birth a new Packet.
```

The apparent will of proc-17 is not a stored intention field.

```text
will = the observed walk produced by competing local pressures over time
```

This is why neither a fixed pipeline nor LLM-selected routing is the intended
final form.

## 4. Scales That Must Stay Separate

Several earlier confusions came from calling different scales "the agent" or
"the packet".

### 4.1 Proc-17 body

The operator laws, router, sandbox, economics, storage, and substrate adapters.
The body outlives individual Packets.

### 4.2 Session

A human or machine work context with its own grave, compost, substrate session,
and lineage registry. A new CLI/TUI session is clean by default.

### 4.3 Lineage

One task process that may require several Packet lives.

```text
lineage-17
  Packet 1 -> corpse 1 -> carrier 1
  Packet 2 -> corpse 2 -> carrier 2
  Packet 3 -> complete
```

### 4.4 Packet life

One mortal body from `▽` to internal death or `△`.

### 4.5 Operator tick

One operator reads its allowed view, performs its bounded transformation, emits
an event, pays costs, and changes the pressure field.

### 4.6 Edge transition

One topology-validated movement from the completed operator tick to one legal
neighbor.

### 4.7 Substrate session

The model/provider context that may remember earlier calls. It is a continuity
carrier, but it is not Packet identity, grave memory, or runtime truth.

## 5. Laws Of One Packet Life

### L1. The Packet is a body, not a message

[ANCESTOR, DECISION]

It may contain a prompt carrier, code, evidence, and output fragments, but it is
the state in which transformations occur. It is not the human explanation of
that state.

### L2. The body is task-shaped

[DECISION]

The old fixed `Z[K,D]` tensor is one possible substrate representation. It is
not the proc-17 schema.

A code task may form units such as:

```text
prompt fragments
repo paths
symbols
requirements
hypotheses
candidate edits
diagnostics
tool results
tests
residue
```

Another task may form different units. The physical contracts remain stable
while the local body shape changes.

### L3. The operator set is fixed; organs may be local

[CANON, DERIVED]

There are ten operator kinds. A concrete organ implementing one operator may
depend on task, substrate, capability, and runtime.

```text
fixed:     ☰ CONNECT contract
variable:  the connector for Lua source, a git graph, or test evidence
```

The body may assemble organs. It may not invent an eleventh operator to avoid a
contract.

### L4. Every motion is adjacent

[CANON]

```text
next_operator in canon.neighbors(current_operator)
```

No hidden jump and no silent trace repair.

### L5. Runtime direction is stricter than language adjacency

[DECISION]

ProcessLang adjacency is structurally symmetric and can describe reverse query
traces. A living Packet has an arrow:

```text
▽ is ingress-only for one life
△ is terminal for one life
```

Internal edges may be traversed in either direction when pressure supports it.
Boundary edges are oriented by lifetime law.

### L6. The substrate does not route

[DECISION]

The LLM may alter Packet state by returning a semantic proposal through ☴.
That altered state may change the route. The LLM does not select the route as an
authority.

Therefore replaceable substrates do not imply identical traces.

```text
same exact Packet state + same body laws -> same deterministic route
different substrate output -> different Packet state -> route may differ
```

Substrate independence means preserved body contracts, not behavioral identity.

### L7. Every executed operator leaves an event

[DERIVED]

An operator may validly find nothing to change. That is an explicit no-op event
with a reason, read set, cost, and truth status. Silent no-op is forbidden.

### L8. Structure and commitment have a price

[CANON, ANCESTOR]

☵ necessarily loses detail. ☳ necessarily suppresses potential. Other
operators may have conditional loss when their changes are irreversible.

### L9. Loss and budget are different physics

[DECISION, RUNTIME]

```text
loss    = irreversible damage to this Packet identity
budget  = fuel spent by runtime: steps, tokens, time, tools, writes, tests, money
```

More budget cannot restore paid loss. A cheap operator can still be destructive.
An expensive substrate call can preserve identity.

### L10. History is stored; pressure is derived

[DERIVED]

Trace, graves, compost, and evidence records may be stored. Freshness, karma,
and route tension are computed by a named reader against the living state.

### L11. Truth of an event and truth of its content are separate

[RUNTIME]

The body may confirm that a model returned a sentence without confirming the
sentence. The body may confirm that a test passed at tick 42 without claiming it
still passes at tick 142.

### L12. Every writer names a reader

[DECISION]

Every new field or record must state:

```text
who reads it
when it is read
what happens if it is stale
whether reading can affect motion
```

### L13. Death is final

[RUNTIME]

A dead Packet cannot mutate, manifest, pay, accumulate loss, receive karma, or
change its cause of death. Corpse classification may read it; descendants may
read projected residue.

### L14. Identity does not cross △

[DECISION]

CALM, `E_momentum`, and the living body are not copied into a child Packet. A
bounded carrier, substrate continuity, and body memory can influence the child
through distinct channels.

## 6. The Task-Shaped Packet Field

[DERIVED]

The old mathematics remains useful if its symbols are treated as contracts:

```text
P_t = <I, Z, E_raw, E, M, C, S, O, Q, L, B, H, T>
```

Where:

```text
I      identity and generation header
Z      task-shaped potential units
E_raw  transient relations detected in the current life/tick
E      active relation view
M      E_momentum: relation inertia owned by ☱
C      formed CALM structures and executable fragments
S      scalar regime and operator controls
O      observations and measurements
Q      constraints, validations, and runtime evidence
L      irreversible loss ledger
B      runtime and lineage budget ledgers
H      bounded attached history view
T      append-only trace of this life
```

This tuple is a conceptual inventory, not a Lua table declaration.

### 6.1 Z is potential, not a hash

`Z` is the material that can still become several forms.

A possible unit envelope is:

```text
unit.id
unit.carrier
unit.kind
unit.phase             chaos | calm | residue
unit.activation
unit.truth_status
unit.source_refs
unit.generation
```

The carrier may be text, an AST node reference, a file identity, a diagnostic,
a patch hunk, a test result, or another packet-native object.

The important property is remaining potential, not the carrier type.

### 6.2 Relations have three timescales

```text
E_raw  = what ☰ recognizes now
E      = what is active now
M      = what repeated runtime has made inertial
```

☰ detects but does not preserve. ☱ preserves but does not invent the semantic
relation. ☷ and ☶ can weaken active relations but cannot write momentum.

`M` is mutable current-life inertia. It is not append-only history and must not
be conflated with graves or trace.

### 6.3 CHAOS and CALM may coexist

[ANCESTOR: Zig, DERIVED]

The old Packet mode switch treated ENCODE as a global `CHAOS -> CALM` boundary.
The Zig body showed a better mechanism: gradual crystallization. A portion of
CHAOS becomes CALM while unresolved CHAOS remains alive.

Working rule:

```text
Packet may contain both unresolved potential and formed structure.
☵ transforms a bounded source region and records the remap.
```

When identities change, relations and momentum referencing those identities
must be invalidated or remapped explicitly. This reset should be scoped to the
affected region unless a full-body encode actually occurred.

### 6.4 The field is not human-readable by requirement

The user needs output and evidence. The body needs addressability, provenance,
and enough structure to act. It does not need to expose every internal unit as
human prose.

## 7. Physical Quantities

### 7.1 Potential and density

Potential is the remaining capacity of units and relations to produce different
forms. Density is a local concentration of active potential, relation, evidence,
or unresolved work.

The user phrase "Packet density throws it toward tension" can be made precise as:

```text
local concentrations and mismatches contribute pressure to adjacent edges
```

### 7.2 Tension

`Z` and tension are intimately related but not identical.

```text
Z        = distributed potential
tension  = mismatch or gradient between that potential and the current form,
           relations, constraints, observations, history, and boundary
```

Tension is not one permanent scalar. It is a vector of local reasons to move.

Examples:

```text
relation pressure
rigidity pressure
observation debt
encoding pressure
choice pressure
runtime mismatch
validation pressure
continuation pressure
manifest pressure
mortality pressure
karma contribution
```

### 7.3 Edge pressure

[DERIVED]

For current operator `o` and legal neighbor `n`:

```text
tau_t(o -> n) =
    sum(pressure contributions targeting n)
  - transition resistance
  - affordability penalty
  - safety/capability penalty
```

Candidate set:

```text
A_t(o) =
  canon_neighbors(o)
  intersect lifecycle-legal directions
  intersect available organs/capabilities
  intersect sandbox policy
  intersect affordable transitions
```

The router consumes a pressure snapshot. It does not read prose and decide what
feels correct.

### 7.4 Pressure records need provenance

Each contribution should eventually expose:

```text
source_kind
source_ref
target_operator or target_edge
amount
reason
calculation_status
source_truth_status
freshness
```

A runtime-confirmed calculation over semantic proposals does not promote those
proposals to facts.

### 7.5 Stored tension is only a snapshot

Current `instance.tension` is a useful staging area. In final physics it should
not become a second mutable truth store.

```text
authoritative: Packet state and immutable records
derived:       tension snapshot at tick t under derivation version v
```

### 7.6 Loss

Loss is cumulative and irreversible inside one life.

It should record what was lost, not only how much:

```text
operator
source refs
loss kind
potential mass before/after
detail or alternatives suppressed
amount
measurement method
```

### 7.7 Budget

Budget measures runtime economics:

```text
steps
input/output tokens
substrate calls
wall time
tool calls
file writes
test runs
money or provider units
```

Packet budget is local. Lineage budget is cumulative so death cannot reset the
price of a task.

### 7.8 Freshness

Freshness is computed when evidence is read:

```text
freshness(record, current_referent, tick)
```

The historical event remains true as history. Its applicability may decay.

### 7.9 Karma

Karma is not stored pressure.

```text
stored: graves, bequests, warnings, compost patterns, trace
derived: effect of that history on the current field and candidate edges
```

Warnings can resist a repeated path. Bequests can lower the cost of a matching
continuation. The same history can help one Packet and obstruct another.

## 8. The Two Eyes

### 8.1 ☴ OBSERVE: upper eye

[DECISION]

☴ looks toward CHAOS, potential, ingress, relation emergence, and semantic
uncertainty. It is the primary membrane through which an LLM substrate enters.

It may:

- inspect a bounded view
- measure it
- append an observation record
- append substrate output as `semantic_proposal` potential
- report what it could not see

It may not:

- mutate the observed units as a side effect of seeing
- promote semantic content to runtime truth
- choose the next operator
- write `E_momentum`

Observation is incomplete by construction. Its scope and missing region belong
in the event.

### 8.2 ☱ RUNTIME: lower eye

[DECISION]

☱ looks toward CALM, execution, evidence, budget, loss, cycles, foundation,
manifest readiness, and attached history.

It is also the sole owner of `E_momentum`.

It may:

- update relation inertia from runtime-confirmed recurrence
- derive the active relation view
- count ticks, cycles, and resource spending
- read bounded history and derive karma contributions
- expose runtime evidence and manifest readiness

It may not:

- rewrite semantic potential merely because a habit exists
- ask the LLM to bless a route
- treat old evidence as fresh without a read-time check

### 8.3 The eyes speak one measurement language

Both eyes should emit versioned observation records with:

```text
observed area
referent fingerprint/version
tick
metrics
missing scope
truth metadata
```

Their difference is direction, not epistemic quality.

### 8.4 Blink is component-wise discharge

[DERIVED]

An eye tick pays observation debt by refreshing a view. It does not reduce loss.
It does not necessarily reduce total tension.

```text
before sight: uncertainty pressure is high
after sight:  uncertainty pressure falls
new finding:  rigidity, choice, or validation pressure may rise
```

Thus observation can lower one component while increasing another.

### 8.5 Eye ticks should eventually emerge from freshness

[DERIVED]

The current hard rails:

```text
☵ -> ☴
☳ -> ☴
☲ -> ☱
☶ -> ☱
```

are useful scaffolding, not canonical law.

When an operator changes the region seen by an eye, the old observation becomes
stale. That staleness should create pressure toward the relevant eye. If the
next operation can proceed from fresh runtime-confirmed state, a direct edge may
remain legal and no forced blink is needed.

This makes eyes frequent for physical reasons without hardcoding them after
every tick.

## 9. Operator Rights And Effects

This section is still chaos. It is designed to project into a read/write table.

### ▽ FLOW

Role:

```text
birth of raw potential
```

Reads:

- user ingress or NETWORK@▽ carrier
- initial engagement/resistance and birth policy

Writes:

- new generation identity
- raw potential units in `Z`/CHAOS
- birth trace
- initial scalar regime

Forbidden:

- inheriting a parent living field
- reusing parent `Z`, CALM, active edges, or momentum
- reading semantic memory as if it were raw flow

Cost:

- runtime budget for ingestion
- no identity loss in the newborn; carrier loss was paid at the prior boundary

Pressure effect:

- creates relation, dissolution, and observation candidates

### ☰ CONNECT

Role:

```text
recognize and form transient relations without preserving them
```

Reads:

- potential units
- formed units when new relations must be discovered
- evidence and bounded inherited-history views
- connection scalars such as depth, field of view, and threshold

Writes:

- `E_raw` relation records
- recognition depth, reciprocity, boundary fluidity, and provenance
- a connection event, including an explicit no-relation result

Forbidden:

- remapping unit identity
- making a transient relation into habit
- choosing or validating semantic truth
- reading raw grave files directly

Cost:

- compute budget
- no Packet identity loss unless the connector intentionally sparsifies its
  source view; such projection loss must be named separately

Pressure effect:

- lowers relation debt
- may raise encode pressure when a stable motif appears
- may raise dissolve pressure when contradictory or rigid relations appear

### ☷ DISSOLVE

Role:

```text
weaken rigid form and return recoverable residue to potential flow
```

Reads:

- active relations and formed structures
- rigidity, staleness, failed validation, and process-alignment metrics
- source provenance needed to preserve residue

Writes:

- weakened or removed active relations
- dissolved residue with reasons and source refs
- fluidity/rigidity measurements
- a dissolution event

Forbidden:

- creating new relations
- remapping identities
- writing `E_momentum`
- silent deletion

Cost:

- runtime budget
- conditional identity loss proportional to information made irrecoverable;
  residue-preserving release is not priced the same as erasure

Pressure effect:

- lowers rigidity
- can increase flow, connect, observe, or choice pressure

### ☴ OBSERVE

Role:

```text
read the potential side and expose a bounded observation
```

Reads:

- a bounded chaos/potential view
- relation and structure summaries when needed
- substrate adapter contract

Writes:

- observation records and metrics
- semantic proposal units returned by the substrate
- freshness metadata and missing-scope markers

Forbidden:

- direct body mutation
- truth promotion
- route selection
- momentum writes

Cost:

- substrate tokens/time/calls and observation budget
- zero direct Packet identity loss; a lossy observation describes its own
  fidelity rather than eroding the observed body

Pressure effect:

- discharges observation debt
- reveals other pressure components

### ☵ ENCODE

Role:

```text
create addressable form by hierarchy, sequence, category, network, teaching,
language, spatial, narrative, or another declared encoding
```

Reads:

- potential units
- relation hints
- target representation and receiver constraints
- bounded loss/size policy

Writes:

- CALM structures
- old-to-new identity map
- source refs and omitted detail
- invalidation set for affected relations/momentum
- mandatory loss record

Forbidden:

- pretending compression is reversible
- changing identity without a map/invalidation record
- hiding omitted material
- validating the truth of the encoded content

Cost:

- usually high runtime budget
- mandatory Packet identity loss

Pressure effect:

- lowers raw encoding debt
- raises observation debt for the new form
- may create choice, runtime, relation, or cycle pressure

### ☳ CHOOSE

Role:

```text
collapse competing potential under pressure
```

Reads:

- an explicit possibility field
- activation/potential distribution
- current relation and constraint view
- temperature, separation cost, and commitment pressure

Writes:

- selected/actualized potential
- suppressed potential and dead-alternative residue
- before/after distribution
- mandatory choice loss

Forbidden:

- remapping identities
- inventing the possibility field
- treating a single available option as a meaningful choice
- replacing LOGIC validation

Cost:

- moderate runtime budget
- mandatory identity loss based on suppressed potential mass and separation,
  not merely the count of list items

Pressure effect:

- lowers choice entropy
- raises consequence observation, runtime commitment, validation, or
  restructuring pressure

### ☲ CYCLE

Role:

```text
emit one bounded recurrence impulse: again
```

Reads:

- scalar regime
- runtime-confirmed continuation condition
- cycle phase and bounded progress summary

Writes:

- scalar phase/continuation record
- a cycle event

Forbidden:

- planning work
- selecting the next semantic task
- owning progress counters
- changing potential, relations, momentum, or constraints

Cost:

- small runtime budget per tick
- exactly zero direct identity loss

Pressure effect:

- carries existing continuation pressure to encode, logic, runtime, or manifest
- does not create the reason to continue

### ☶ LOGIC

Role:

```text
enforce declared constraints and test executable claims
```

Reads:

- active relations and candidate form
- declared rules
- runtime evidence and sandbox capabilities

Writes:

- constraint masks
- validation violations/verdicts
- spell/tool evidence with `reality_changed`
- weakened/rejected forms and logic trace

Forbidden:

- generating semantic truth
- creating new Packet relations as a correction
- writing `E_momentum`
- executing outside explicit capabilities

Cost:

- tool/test/time budget
- conditional identity loss when constraints irreversibly suppress form

Pressure effect:

- lowers validation debt
- can raise choose, cycle, runtime, repair-observation, or manifest pressure

External reality may change through a sandboxed spell. Internally, LOGIC remains
subtractive: it records whether the declared action actually happened; it does
not turn intention into evidence by wording alone.

### ☱ RUNTIME

Role:

```text
hold executable state in a real environment and observe the manifest side
```

Reads:

- CALM structures and work state
- raw and active relations
- evidence, constraints, trace, budget, loss, cycle state
- bounded attached history and compost patterns

Writes:

- `E_momentum` and active relation view
- counters and budget evidence
- foundation patterns
- runtime observation records
- derived freshness, karma, readiness, and pressure snapshots

Forbidden:

- rewriting semantic potential because a habit prefers it
- promoting stale evidence
- copying parent momentum into a new Packet
- delegating routing authority to the substrate

Cost:

- runtime budget
- exact Packet-loss profile remains open; persistence can reduce degrees of
  freedom, but not every runtime tick should erode identity

Pressure effect:

- exposes work, evidence, continuation, validation, mortality, and manifest
  gradients

### △ MANIFEST

Role:

```text
assemble a bounded external form and terminate this Packet identity
```

Reads:

- selected/validated CALM
- runtime evidence
- output contract and boundary policy
- explicit loss and provenance summaries

Writes:

- output artifact or manifest carrier
- materialization loss
- corpse and residue
- terminal trace

Forbidden:

- continuing the same Packet
- exporting a living field or momentum
- claiming that output contains the whole process

Cost:

- output/runtime budget
- terminal materialization loss

Pressure effect:

- none inside the dead Packet
- the carrier may create birth pressure in a new generation through NETWORK@▽

## 10. The 22 Edges

[CANON topology, DERIVED physical readings]

The graph contains 22 unique undirected edges. The readings below are not Tarot
labels and not fixed routes. They are the physical work that can justify each
local transition.

### Boundary edges from ▽

| Edge | Runtime direction | Physical reading | Principal pressure |
|---|---|---|---|
| `▽-☰` | `▽ -> ☰` | New potential contains several addressable units and needs a relation snapshot. | relation debt, unbound sources |
| `▽-☷` | `▽ -> ☷` | Ingress arrived with rigid inherited framing that must be released before use. | inherited rigidity, stale carrier form |
| `▽-☴` | `▽ -> ☴` | The newborn field needs first sight, semantic expansion, or a substrate response. | observation debt, semantic uncertainty |

Returning to `▽` does not rewind a living Packet. A new `▽` means a new life.

### Upper field edges

| Edge | First direction | Reverse direction | Principal pressure |
|---|---|---|---|
| `☰-☷` | `☰ -> ☷`: a detected relation is rigid, contradictory, stale, or overbound. | `☷ -> ☰`: released parts need new relations. | relation rigidity versus free parts |
| `☰-☴` | `☰ -> ☴`: emerging relations need measurement. | `☴ -> ☰`: observation reveals unbound candidate relations. | relation confidence and coverage |
| `☰-☵` | `☰ -> ☵`: relation motifs are sufficient to support structure. | `☵ -> ☰`: new encoded identities need a fresh relation scan. | compressible motif versus relation invalidation |
| `☷-☴` | `☷ -> ☴`: the body must inspect what dissolution exposed or damaged. | `☴ -> ☷`: observation detects rigid, stale, or unsupported form. | rigidity and dissolution consequence |
| `☷-☳` | `☷ -> ☳`: freed potential now exposes alternative directions. | `☳ -> ☷`: suppressed alternatives are released as residue rather than silently deleted. | freed space versus dead alternatives |

### Two-eye and middle-field edges

| Edge | First direction | Reverse direction | Principal pressure |
|---|---|---|---|
| `☴-☵` | `☴ -> ☵`: a bounded observation is rich enough to encode. | `☵ -> ☴`: the new form made the prior view stale and needs inspection. | encoding readiness versus form freshness |
| `☴-☳` | `☴ -> ☳`: the possibility landscape is visible enough to commit. | `☳ -> ☴`: consequences and killed alternatives must be observed. | choice separation versus consequence debt |
| `☴-☱` | `☴ -> ☱`: potential-side observation must be reconciled with actual runtime state. | `☱ -> ☴`: runtime lacks semantic evidence or needs repair/clarification. | chaos/CALM mismatch and semantic uncertainty |
| `☵-☱` | `☵ -> ☱`: an encoded form is installed, held, or executed; affected momentum is rebuilt. | `☱ -> ☵`: runtime state no longer fits its representation and requires recoding. | form/runtime mismatch |
| `☵-☳` | `☵ -> ☳`: encoding exposes an explicit possibility field. | `☳ -> ☵`: commitment requires a narrower or differently shaped representation. | structured alternatives and commitment |
| `☵-☲` | `☵ -> ☲`: encoded work defines a repeatable transform. | `☲ -> ☵`: recurrence requests another bounded encoding/refinement pass. | iterative formation; self-limited by encode loss |
| `☳-☱` | `☳ -> ☱`: a chosen path is committed into executable state. | `☱ -> ☳`: runtime exposes a decision that can no longer remain unresolved. | commitment versus runtime branching |
| `☳-☶` | `☳ -> ☶`: the chosen path needs constraint/evidence checking. | `☶ -> ☳`: rules define an admissible set from which one path must be selected. | choice is not validation |

### Lower field and terminal edges

| Edge | First direction | Reverse direction | Principal pressure |
|---|---|---|---|
| `☱-☶` | `☱ -> ☶`: runtime needs a rule, test, or capability-backed proof. | `☶ -> ☱`: validation/effect evidence must enter runtime and foundation. | evidence debt and executable constraint |
| `☱-☲` | `☱ -> ☲`: remaining work and affordability justify one more recurrence. | `☲ -> ☱`: the recurrence impulse returns to the owner of counters and state. | continuation versus accounting |
| `☲-☶` | `☲ -> ☶`: each iteration or convergence claim needs checking. | `☶ -> ☲`: a valid rule/test requests another bounded run. | repeated validation |
| `☱-△` | `☱ -> △` only in one life | Runtime sees completion, usable partial output, or near-death manifestation pressure. | manifest readiness and mortality |
| `☲-△` | `☲ -> △` only in one life | A runtime-confirmed iteration/convergence/limit condition directly releases output. | terminal cycle condition |
| `☶-△` | `☶ -> △` only in one life | A validated artifact can be materialized without another semantic decision. | accepted evidence and output readiness |

The reverse adjacency from `△` remains valid in ProcessLang state-transfer
grammar. It is forbidden for the same Packet body by lifetime law.

## 11. How Pressure Traverses The Tree

An unresolved need may target an operator that is not adjacent to the current
one. The router still cannot jump.

[DERIVED]

Pressure should be projected onto local edges by the transformations that can
legitimately carry it.

Example:

```text
current: ☷
need:    a new encoded form

invalid jump: ☷ -> ☵

possible local carriers:
  ☷ -> ☰ -> ☵   released parts first reconnect
  ☷ -> ☴ -> ☵   released field is first observed
  ☷ -> ☳ -> ☵   dissolution opens alternatives, one is chosen and re-encoded
```

The shortest path is not automatically correct. Each intermediate operator must
have real work to perform and must emit evidence of that work.

Manifest pressure can similarly propagate toward terminal neighbors, but death
does not need to walk to △. If budget or identity is already exhausted, the
Packet dies at its current operator and leaves residue.

## 12. Routing Law

### 12.1 Router authority is narrow

The router:

- obtains legal neighbors from canon
- receives a derived pressure snapshot
- removes lifecycle, capability, sandbox, and affordability violations
- selects one candidate according to a deterministic policy
- records all candidates and the reason for the winner

The router does not:

- interpret the user's prose
- call the LLM
- mutate Packet content
- repair an invalid transition
- manufacture pressure because no candidate looks good

### 12.2 No viable edge is a physical outcome

[OPEN]

If no legal affordable candidate has sufficient pressure, the body must not move
for free. Candidate outcomes include:

```text
stalled death with residue
needs-user boundary
explicit hold represented outside operator movement
emergency partial manifestation when a terminal path is physically available
```

The exact contract requires a table and experiment. A hidden fallback route is
not acceptable.

### 12.3 Tie-breaking

[OPEN]

The first pressure router should be deterministic and auditable. A canonical
stable order can break exact ties. Softmax/temperature belongs later, after edge
statistics exist.

### 12.4 Shadow before authority

[DECISION]

The current router remains live while a shadow router:

```text
scores all legal neighbors
records per-edge contributions
predicts the next operator
does not control the Packet
```

Only after ☰, ☷, the task-shaped field, and pressure provenance exist can the
hard eye rails be removed.

## 13. History, Grave, Compost, And Momentum

### 13.1 Four different persistence forms

```text
trace       immutable history of one Packet life
E_momentum  mutable relation inertia inside one living Packet
grave       bounded individual residue across Packet lives in one session
compost     aggregated pattern after individual graves decay
```

They must not share one vague `memory` field.

### 13.2 Named history reader

[DERIVED]

The router should not open session files or count graves directly.

A runtime-owned derivation layer at ☱ should:

1. receive a bounded history view attached at birth
2. compare records with current units, relations, and edge candidates
3. emit help/resistance contributions with source refs
4. let the router consume those contributions

☰ may form explicit relations between current units and inherited records, but
it receives the bounded view from runtime. It does not own storage retrieval.

### 13.3 Warning and bequest are not commands

```text
warning  can increase resistance to a matching repeated edge pattern
bequest  can reduce continuation cost for matching unfinished work
neutral  remains historical context
```

Applicability is a current-life hypothesis even when the ancestor's death is a
runtime-confirmed fact.

### 13.4 Compost feeds foundation only through a reader

Compost is statistical soil. It does nothing by existing. A named runtime reader
must derive a pattern contribution and record when it affected motion.

## 14. Truth, Observation, And Trace

### 14.1 Event truth versus content truth

Every important record should eventually distinguish:

```text
event_truth_status
content_truth_status
calculation_status
applicability_status
```

Example:

```text
LLM returned "file x exists"
  event:   runtime_confirmed
  content: semantic_proposal

filesystem stat confirmed x at tick 20
  event:   runtime_confirmed
  content: runtime_confirmed at referent fingerprint r20

same record read at tick 80 after repo mutation
  history: still confirmed
  applicability: stale/estimated until rechecked
```

### 14.2 Trace is physics, not logging decoration

Each transition must record:

```text
packet_id and generation
tick
from/to operator
candidate pressures
selected edge and reason
state refs read
state refs written
cost and loss
truth metadata
```

The Packet's current operator must advance with the walk. Death and manifest
must stamp the actual current operator, not the birth default.

### 14.3 Tests must grow physical fixtures

Warnings, graves, stale evidence, and deaths used in integration tests should be
produced by real Packet runs when the claimed behavior depends on lifecycle.
Synthetic fixtures may supplement but not replace the living path.

## 15. Economics And Mortality

### 15.1 Preliminary operator profile

Exact amounts remain open. The qualitative profile is enough for table work.

| Operator | Runtime budget | Packet identity loss |
|---|---|---|
| `▽` | ingress/parse cost | none in newborn |
| `☰` | relation search | none by default; projection loss if sparsified |
| `☷` | relation/form rewrite | conditional on irrecoverable dissolution |
| `☴` | observation and possibly LLM tokens | none to observed identity |
| `☵` | usually high | mandatory encoding loss |
| `☳` | selection computation | mandatory suppressed-potential loss |
| `☲` | very low per recurrence | zero by law |
| `☶` | validation/tool/test cost | conditional constraint loss |
| `☱` | state/accounting/persistence cost | open; never automatic per-tick erosion |
| `△` | materialization/output cost | terminal materialization loss |

### 15.2 Mortality order

After an operator pays its costs:

```text
1. append the completed operator event
2. accumulate budget and identity loss
3. evaluate death guards
4. if alive, derive pressure and route
```

Death can occur at any operator. `△` is a successful/usable terminal boundary,
not the only way to die.

### 15.3 External tick limits are insurance

Normal termination comes from body physics:

- completion at △
- budget exhaustion
- identity loss
- invalid topology
- unsafe scope
- cancellation
- a future explicit stalled-life cause

`max_ticks` remains a high emergency ceiling, not the main clock.

## 16. Lineage Mechanics

[DECISION]

The lineage runner is part of proc-17's physical engine, not product plumbing.

The Packet runner gives one mortal body a life. The lineage runner makes a
sequence of non-identical mortal bodies carry one unfinished task process.

Without it:

```text
death terminates the task rather than one attempt
manifest carriers have no receiver
NETWORK@▽ has no caller
generation identity is decorative
grave and compost can warn later manual runs but cannot continue the process
```

Hands, CLI, and TUI make the engine useful to an operator. The lineage runner
makes the engine itself complete across Packet death.

### 16.1 Normal sequence

```text
Packet_n reaches △ or dies
Packet_n becomes immutable corpse_n
a bounded manifest/residue carrier is assembled
lineage runner derives continuation from lineage state and body-owned evidence
NETWORK@▽ presents the carrier as ingress
Packet_n+1 is born with new identity and generation
```

### 16.2 Required identity

```text
lineage_id
packet_id
generation
parent_packet_id
parent_corpse_id
substrate_session_id
```

### 16.3 What may cross

Potential continuity carriers:

```text
manifest carrier
bounded grave/compost view
same-substrate session context
explicit external artifacts and runtime evidence
```

Forbidden direct copy:

```text
living CALM
active relations
E_momentum
unbounded trace/context
parent identity
```

### 16.4 The lineage needs its own ledger

The lineage runner is a new authority and must be auditable.

It records:

```text
generation_born
corpse_registered
carrier_selected
continuation_decided
lineage_completed
lineage_budget_spent
```

### 16.5 Same-substrate continuity is measured, not assumed

The substrate may remember earlier generations and produce the memoris effect.
That continuity is real only as observed behavior under a declared session. It
does not make the dead Packet secretly alive.

### 16.6 Lineage recurrence is not ☲

```text
☲ CYCLE
  repeats a bounded operation inside one living Packet

lineage runner
  births a new Packet after the previous body is terminal
```

The lineage runner lives outside the 22-edge walk but inside proc-17 mechanics.
It does not add an operator or an edge. It owns the generational boundary around
many mortal Tree walks.

## 17. Current Proc-17 Against This Physics

### 17.1 What already stands

```text
canonical topology data                    present
Packet areas and append-only trace         present
semantic substrate boundary at ☴          present
☵ and ☳ with explicit loss records        present
☲, ☶, ☱, △ working skeletons              present
budget and loss mortality                  present
corpse finality guards                     substantially present
grave, warning/bequest classification      present
session-scoped grave and compost storage   present
truth freshness derivation                 present
tests for mortality and generational karma present
```

### 17.2 Edges exercised by the current live route

The current body uses approximately these seven unique edges:

```text
▽-☴
☴-☵
☴-☳
☴-☱
☱-☲
☱-☶
☱-△
```

The canonical graph exists, but 15 edges do not yet have live route physics.

### 17.3 Current scaffolding and gaps

```text
FLOW exists mostly as constructor/birth, not a full organ tick
☰ CONNECT is missing
☷ DISSOLVE is missing
hard eye rails replace full pressure competition
current encode field is useful but still heavily line/section-shaped
E_raw/E/E_momentum do not yet exist as one canonical relation system
runtime.foundation is not the same thing as E_momentum
instance.tension is a mutable catch-all rather than a derived vector snapshot
stored runtime.karma counts records rather than deriving relational pressure
compost has storage but no causal reader
only ☵ and ☳ currently accumulate Packet identity loss
△ does not yet accumulate materialization loss or build a re-entry carrier
lineage runner and NETWORK@▽ are documented but not manifested
current operator/trace position still needs the audited advancement fix
```

This is not evidence that the current body is wrong. It identifies exactly what
the next table layer must separate before code changes.

## 18. Table Projections Required

One giant yellowprint would recreate the current unevenness. Nine tiny tables
would fragment the assembled physics again. This one chaos document should
produce three substantial tables.

Source authority, current mappings, and open conflicts belong as columns inside
all three tables rather than becoming a fourth artifact.

### T1. Packet Body Physics

```text
field/region
meaning
owner
writers
readers
lifetime
freshness/invalidation
current Lua mapping
potential/density semantics
pressure kind
source records
named reader
discharge condition
freshness rule
truth propagation
operator cost dimensions
identity loss dimensions
death thresholds
near-death behavior
measured/vibed status
```

T1 answers:

```text
what is physically inside one living Packet?
```

### T2. Operator Tree Physics

```text
operator
reads
writes
forbidden writes
event
budget profile
loss profile
pressure outputs

edge, for all 22 canonical edges
directional reading A -> B
directional reading B -> A
required state/evidence
pressure sources and resistance
capabilities
test witness

shadow/current route mapping
promotion and rollback evidence
```

T2 answers:

```text
how can one living Packet move and transform without a hidden pipeline?
```

### T3. Lineage Mechanics

```text
birth and generation identity
living Packet tick
internal death and manifest death
corpse finality
manifest/residue carrier
NETWORK@▽ ingress
lineage runner decisions and ledger
Packet versus lineage economics
session/substrate continuity
trace, grave, bequest, warning, compost, and foundation
event truth, applicability, retention, and named readers
next generation and lineage completion
current Lua mapping and missing mechanisms
```

T3 answers:

```text
how does the task process continue when every Packet body is mortal?
```

## 19. Open Pressure

The following questions are intentionally not answered here:

1. What is the minimum concrete Lua schema for a task-shaped potential unit?
2. Does partial ☵ remap only affected relation momentum, or can some encodings
   require a full reset?
3. Which runtime patterns belong in `E_momentum`, and which belong in
   foundation, evidence, grave, or compost?
4. What normalization lets unrelated pressure kinds compete without fake
   precision?
5. What exact condition removes the hard eye rails?
6. What is the physical outcome when no legal edge has enough pressure?
7. Which conditional ☷, ☶, and ☱ changes count as Packet identity loss?
8. What is the smallest sufficient manifest carrier for NETWORK@▽?
9. What runtime-confirmed predicate lets the lineage runner continue or complete?
10. How are substrate capabilities bound to task-specific organs?
11. Which of the 22 edges remain rare but necessary, and which indicate a bad
    field or bad pressure model when overused?
12. Can nested task forms birth subordinate Packets, or is that a later network
    layer outside the first lineage runner?

No threshold or answer should enter code merely to make this document look
complete.

## 20. Proposed Next Movement

The next movement is not `▲`.

```text
read this chaos document with current code
build T1: Packet Body Physics
observe contradictions
build T2: Operator Tree Physics
observe again
build T3: Lineage Mechanics
cross-check all writers, readers, costs, deaths, and boundary transitions
only then assemble a full-tree crystal
```

The difficult part is not writing a larger router. It is making the Packet state
rich enough that the correct route is a local physical consequence instead of a
hidden plan.

Short formula:

```text
task-shaped field
+ ten bounded operators
+ twenty-two legal edges
+ two read-only eyes
+ derived pressure
+ irreversible loss
+ finite budget
+ terminal Packet identity
+ inherited but non-identical lineage
+ lineage runner across mortal bodies
= proc-17 full Packet Tree physics
```
