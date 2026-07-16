# Packet Body Physics Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/packet_body_physics_yellowprint.v0.md
implementation target for one mortal Packet body
code not changed by this document
```

## 1. Scope

This blueprint crystallizes the state and mutation contract required before the
full ProcessLang Tree can control a Packet.

It defines:

```text
identity and lifecycle
task-shaped potential units
raw, active, and momentum relations
CALM references
two-eye observation records
state revisions and freshness inputs
history attachment
loss, budget, pressure, trace, and terminal ownership
```

It does not implement ☰, ☷, the full router, NETWORK@▽, or the lineage runner.

## 2. Migration Law

The current body remains the migration base:

```text
physis
chaos
boundary
calm
runtime
tension
trace
manifest / death / residue
```

Add one canonical `field` region. Do not create parallel replacements for every
existing area.

```text
chaos     owns raw ingress and semantic fragments
field     owns addressable potential units and relation state
calm      owns formed structures and executable work
regime    owns versioned operator controls and scalar phase
runtime   owns evidence, history view, foundation, and economics
boundary  owns observations and irreversible operator records
```

During migration, compatibility aliases must reference the same Lua table or be
read-only projections. Dual writable copies are forbidden.

## 3. Target Files

```text
core/packet.lua                 extend identity, lifecycle, revisions, events
runtime/field.lua               NEW: task-shaped units and relation APIs
runtime/body.lua                canonical CALM/work and observation helpers
runtime/grave.lua               attach into runtime.history
runtime/budget.lua              revision/event integration
runtime/loss.lua                revision/event integration
tests/test_packet.lua           identity, lifecycle, terminal state
tests/test_field.lua            NEW: field ownership and revisions
tests/test_body.lua             observation/CALM contracts
tests/test_grave.lua            history attachment compatibility
tests/run.lua                   register test_field
```

No target file is permission to implement this blueprint in one patch. The
implementation order is specified below.

## 4. Packet Root Shape

```lua
{
  protocol_version = "packet.next.v1",
  id = string,
  lineage_id = string,
  generation = integer,
  parent_id = string | nil,
  parent_corpse_id = string | nil,
  birth_kind = "user" | "network_reentry" | "recovery",
  carrier_id = string | nil,
  substrate_session_id = string | nil,

  status = "born" | "running" | "dying" | "dead",
  operator = glyph,
  topology = string,
  revisions = table,

  physis = table,
  chaos = table,
  field = table,
  boundary = table,
  calm = table,
  regime = table,
  runtime = table,
  tension = table,
  trace = table,

  manifest = table | nil,
  death = table | nil,
  residue = table,
  terminal = table | nil,
}
```

Compatibility:

```text
id remains the canonical packet_id in v1
parent_id remains the compatibility name for parent_packet_id
physis remains canonical; substrate may alias physis temporarily
manifested is no longer a durable status; manifestation is terminal.kind
```

## 5. Identity Constructor Contract

```lua
packet.new(prompt, options) -> instance
```

Required options after lineage work begins:

```lua
{
  id = string | nil,
  lineage_id = string | nil,
  generation = integer | nil,
  parent_id = string | nil,
  parent_corpse_id = string | nil,
  birth_kind = string | nil,
  carrier_id = string | nil,
  substrate_session_id = string | nil,
  budget = table | nil,
  history = table | nil,
}
```

Defaults before the lineage runner exists:

```text
lineage_id = packet id
generation = 1
birth_kind = user
all parent/carrier refs = nil
```

Validation:

```text
generation is integer >= 1
generation=1 requires no parent corpse for user birth
generation>1 requires lineage id and parent corpse
network_reentry/recovery requires carrier id
identity fields are immutable after construction
```

## 6. Revision Vector

Initialize:

```lua
revisions = {
  potential = 0,
  relations_raw = 0,
  relations_active = 0,
  momentum = 0,
  calm = 0,
  constraints = 0,
  evidence = 0,
  history = 0,
  scalars = 0,
  budget = 0,
  loss = 0,
}
```

Rules:

```text
only the owning mutation API increments a component
increments happen after successful mutation and before event append completes
failed/no-op mutation does not increment
observations store the revisions they read
freshness compares stored read revisions with current revisions
revision counters never decrement or reset inside one life
```

Revision is applicability evidence, not semantic truth.

## 7. Task-Shaped Field

### 7.1 Root

```lua
field = {
  protocol_version = "field.v0",
  next_unit_id = 1,
  next_relation_id = 1,
  unit_order = {},
  units = {},
  relations = {
    raw = {
      epoch = 0,
      source_revision = 0,
      items = {},
    },
    active = {},
    momentum = {},
  },
  identity_maps = {},
}
```

`units`, `active`, and `momentum` are keyed by stable local ids. `unit_order`
preserves deterministic traversal and serialization.

### 7.2 Potential unit

```lua
{
  id = string,
  kind = string,
  carrier = any | nil,
  carrier_ref = string | nil,
  source_refs = table,
  event_truth_status = string,
  content_truth_status = string,
  density = number | nil,
  activation = "live" | "selected" | "suppressed" | "dissolved",
  created_by = glyph,
  created_event_id = string,
  generation = integer,
  version = integer,
}
```

Minimum laws:

```text
carrier or carrier_ref is required
source_refs is non-empty except direct user ingress
semantic proposal remains semantic proposal after indexing
id is stable inside one generation
☵ remap creates a new id and an explicit identity-map record
☳ may change activation but never id or carrier
```

Density is optional until a measured derivation exists. Missing density must not
silently become zero.

### 7.3 Relation record

```lua
{
  id = string,
  from = string,
  to = string,
  kind = string,
  weight = number | nil,
  confidence = number | nil,
  state = "raw" | "active" | "weakened" | "locked" | "dissolved",
  source_refs = table,
  event_truth_status = string,
  content_truth_status = string,
  observed_tick = integer | nil,
  version = integer,
}
```

Endpoint ids must exist in the current generation. Self-relations require an
explicit relation kind that permits them.

### 7.4 Momentum record

```lua
{
  relation_key = string,
  strength = number,
  recurrence_count = integer,
  last_seen_tick = integer,
  source_relation_refs = table,
  version = integer,
}
```

Only ☱ may create, update, weaken, or remove momentum. Foundation, grave,
compost, and trace are not momentum aliases.

### 7.5 Identity map

```lua
{
  kind = "field_identity_map",
  encode_event_id = string,
  old_ids = table,
  new_ids = table,
  mapping = table,
  invalidated_relation_ids = table,
  invalidated_observation_ids = table,
  truth_status = "runtime_confirmed",
}
```

☵ emits this record. ☱ is the only writer that applies its momentum
invalidation set.

## 8. Field API

Target module:

```text
runtime/field.lua
```

Public contract:

```lua
field.init(instance) -> field
field.add_unit(instance, actor, input) -> unit | nil, err
field.get_unit(instance, id) -> unit | nil
field.set_activation(instance, actor, id, activation, source) -> unit | nil, err
field.snapshot_raw_relations(instance, actor, input) -> snapshot | nil, err
field.activate_relations(instance, actor, relation_ids, source) -> payload | nil, err
field.weaken_relation(instance, actor, relation_id, source) -> payload | nil, err
field.record_identity_map(instance, actor, input) -> record | nil, err
field.apply_momentum(instance, actor, input) -> record | nil, err
field.view(instance, refs) -> bounded_view | nil, err
```

Actor rights:

| API | Allowed actor |
|---|---|
| `add_unit` | ▽, ☴, ☷, ☵ |
| `set_activation` | ☳; ☷ only for `dissolved` |
| `snapshot_raw_relations` | ☰ |
| `activate_relations` | ☱ |
| `weaken_relation` | ☷ or ☶ with distinct reason kinds |
| `record_identity_map` | ☵ |
| `apply_momentum` | ☱ only |

Every mutator calls `packet.assert_mutable` and appends or references one trace
event. There is no unguarded table write outside tests and migration adapters.

## 9. CALM Contract

Keep the current `calm` root and normalize new structures:

```lua
{
  id = string,
  kind = string,
  member_unit_ids = table,
  relation_ids = table,
  payload = any | nil,
  payload_ref = string | nil,
  identity_map_ref = string | nil,
  source_refs = table,
  status = "proposed" | "accepted" | "rejected" | "done",
  event_truth_status = string,
  content_truth_status = string,
  created_event_id = string,
  version = integer,
}
```

`calm.current` remains a reference to a structure in `calm.structures`, not a
second independently mutable copy.

`calm.work_units` may remain as a compatibility projection until all work
readers use structure ids. It must be rebuilt from the owning structure and must
not diverge silently.

## 10. Scalar Regime Contract

Canonical storage:

```lua
regime = {
  encoding = {
    policy_id = string | nil,
    bounds = table,
  },
  choice = {
    policy_id = string | nil,
    bounds = table,
  },
  cycle = {
    phase = integer,
    recurrence_key = string | nil,
  },
  logic = {
    contract_id = string | nil,
  },
  runtime = {
    momentum_policy_id = string | nil,
  },
  manifest = {
    output_policy_id = string | nil,
  },
}
```

Rules:

```text
ingress/body policy initializes policy ids and bounds
☲ alone advances cycle.phase
operator options may narrow declared bounds but never silently widen them
budget and loss remain separate ledgers, not regime scalars
thresholds are versioned policy inputs and identify measured/vibed origin
successful scalar mutation increments revisions.scalars
```

No scalar is allowed to become an untraced control channel for routing.

## 11. Two-Eye Observation Contract

Canonical storage:

```lua
boundary.observations = {
  upper = {},
  lower = {},
}
```

Shared record:

```lua
{
  id = string,
  eye = "upper" | "lower",
  operator = "☴" | "☱",
  scope_refs = table,
  read_revisions = table,
  payload = table,
  source_refs = table,
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
  tick = integer,
  trace_event_id = string,
}
```

Rules:

```text
☴ may append semantic proposal units after observing; the observation itself is confirmed
☱ may update active relations/momentum/counters after measuring runtime
neither eye writes the route
neither eye mutates the state it claims merely to have read
freshness is derived from read_revisions; no stale flag is rewritten into history
```

Migration:

```text
chaos.observations may alias boundary.observations.upper temporarily
runtime snapshots may project boundary.observations.lower
new code writes only through body.record_observation
```

## 12. History Attachment

Canonical newborn view:

```lua
runtime.history = {
  warnings = {},
  bequests = {},
  neutral = {},
  compost = {},
  carrier_ref = string | nil,
  source_session_id = string | nil,
  attached_at_tick = integer,
}
```

During migration:

```lua
runtime.karma = runtime.history
```

This is one table alias, not a copied store. The name `karma` is removed after
T2 routes from derived pressure rather than stored warnings.

Attachment increments `revisions.history`. Attached records are immutable.

## 13. Constraints And Evidence

Keep existing owners:

```text
calm.constraints       declared active rules
boundary.validations   verdict records
runtime.evidence       tool/test/reality-change records
runtime.foundation     current-life reinforced patterns
```

All effect evidence stores a referent or expiry clock. Adding evidence increments
`revisions.evidence`; changing a rule increments `revisions.constraints`.

Inherited grave/compost records never enter `runtime.evidence`.

## 14. Economics And Pressure

Keep current `runtime.budget` and `runtime.loss` ledgers. Add revision increments
on successful append:

```text
budget event -> revisions.budget += 1
loss event   -> revisions.loss += 1
```

Target `tension` shape:

```lua
tension = {
  current = nil,
  derived_at_tick = nil,
  derivation_version = nil,
}
```

`tension.current` is a cache of one T2 pressure snapshot. Past snapshots live in
trace events. No operator stores an authoritative pressure source in `tension`.

Existing fields such as `last_choice_pressure`, `loss_exhausted`, and
`loss_remaining` move behind readers or become compatibility projections.

## 15. Trace And Position

Add event types required by T2/T3:

```text
operator_tick
route
observation
relation_snapshot
relation_mutation
identity_map
history_attach
terminal
```

Required APIs:

```lua
packet.assert_mutable(instance, operation) -> true | nil, err
packet.begin_tick(instance, operator, input_refs) -> tick_event | nil, err
packet.commit_transition(instance, decision) -> route_event | nil, err
packet.append_event(instance, event) -> stored | nil, err
packet.begin_terminal(instance, terminal) -> terminal_event | nil, err
packet.freeze(instance, cause, residue) -> corpse_source | nil, err
```

`commit_transition` validates adjacency and lifecycle direction before updating
`instance.operator`. This removes the current split between runner-local
position and stale Packet position.

## 16. Terminal Contract

Target state machine:

```text
born -> running -> dying -> dead
```

Manifestation is a terminal kind:

```lua
terminal = {
  kind = "manifest" | "internal_death",
  cause = string,
  operator = glyph,
  manifest_ref = string | nil,
  residue_ref = string | nil,
  loss_snapshot = table,
  budget_snapshot = table,
  trace_tail_ref = string,
  truth_status = "runtime_confirmed",
}
```

Terminal sequence:

```text
body is alive
terminal output/residue and mandatory loss are produced
terminal event is appended internally
status becomes dead
all public mutators reject future writes
```

`freeze` is idempotent only as rejection: a second call returns an error and
does not rewrite cause, residue, manifest, trace, or terminal record.

## 17. Mutation Transaction

Every state-changing API uses this order:

```text
1. assert mutable and actor rights
2. validate complete input
3. build mutation and affected refs without writing
4. apply one bounded mutation
5. increment owning revisions
6. append trace event with reads/writes/truth/cost/loss refs
7. return stored record/payload
```

If step 4 or 5 fails, no success event may be emitted. Lua v0 may implement the
transaction by validate-before-write and bounded mutations rather than a generic
rollback engine.

## 18. Writer-Reader Closure

| Written record | Writer | Required reader and read moment |
|---|---|---|
| potential unit | ▽, ☴, ☷, or ☵ through field API | relevant field organ before transformation |
| raw relation epoch | ☰ | ☱ activation and ☵/☴ relation view before epoch expires |
| active relation | ☱; bounded weakening by ☷/☶ | ☵/☳/☶/☱ and pressure readers each relevant tick |
| relation momentum | ☱ only | ☱/pressure reader at lower-eye derivation |
| identity map/invalidation | ☵ | ☱ momentum invalidator and freshness reader immediately after encode |
| CALM structure | ☵ and bounded later status owners | ☳/☱/☲/☶/△ after formation |
| scalar regime mutation | owning body/operator policy | affected operator and pressure reader on next tick |
| upper/lower observation | ☴/☱ | freshness and pressure derivation before route selection |
| constraint/verdict | ☶ | ☱, route readiness, and △ after validation |
| effect evidence | capability/☶ | freshness, ☱, ☶, △, and lineage completion |
| history projection | lineage/session birth boundary | ☰ and ☱ while child is alive |
| budget event | body/capability runtime | budget guard after every charged action; lineage reconciliation after death |
| loss event | operator physics | mortality guard after mutation; △ and corpse capture at terminal |
| pressure snapshot | T2 named readers | router and trace in the same tick |
| trace event | body owner | validator, corpse capture, audit/UI |
| terminal record | Packet lifecycle | corpse capture and lineage runner after death |

An implementation PR adding a stored record must add its named reader in the
same crystall/code change or mark the record shadow-only with an expiry plan.

## 19. Implementation Order

### Phase A: identity, revisions, and finality

```text
extend constructor fields
export assert_mutable
make operator position body-owned
introduce terminal record without removing compatibility status yet
audit every mutator
```

### Phase B: canonical field in shadow use

```text
add runtime/field.lua
populate ingress and observed units alongside current encode input
do not route from it yet
compare field units with current encoded inputs in tests
```

Compatibility writes must use field APIs; direct dual writes are forbidden.

### Phase C: observations and history

```text
add shared eye envelope
move grave attachment to runtime.history alias
add revision-based freshness inputs
```

### Phase D: promote field consumers

```text
☵ consumes bounded field views
☳ mutates unit activation through field API
☱ owns active relations and momentum
remove obsolete projections only after behavior tests
```

## 20. Required Tests

### Identity and lifecycle

```text
default standalone Packet gets lineage=id and generation=1
lineage birth validates parent/corpse/carrier fields
identity fields cannot mutate
commit_transition updates Packet operator and trace together
invalid transition changes neither
dead Packet rejects every public mutator
second death and posthumous manifest are rejected without changing corpse source
```

### Field

```text
unit ids are stable and deterministic inside one body
semantic status survives indexing and encoding references
☰ alone snapshots raw relations
☱ alone creates/activates relations and writes momentum;
☷/☶ can only perform their declared weaken/lock mutations
☵ identity map invalidates affected refs but does not write momentum
☳ changes activation and records suppressed alternatives
no-op/failed mutation leaves revision unchanged
```

### Observation and freshness

```text
both eyes emit the shared envelope
upper proposal content remains semantic_proposal
lower runtime snapshot event is confirmed
field mutation makes only dependent read revisions stale
reader does not mutate observation history
```

### Compatibility

```text
current encode/choose/mortality suites remain green during each phase
runtime.karma and runtime.history are the same table during migration
calm.current cannot diverge from owning structure
JSON packet/capsule serialization remains deterministic enough for hashes/tests
```

## 21. Explicitly Open

Do not crystallize these as hidden defaults:

```text
density formula
relation weight/confidence normalization
relation kind registry versus open names
momentum gain and decay formula
conditional ☱ identity loss
identity-loss normalization across different carrier/unit kinds
materialization loss formula
pressure normalization
history relevance matching
final removal date for compatibility aliases
```

Every temporary value must be labeled `vibed` or supplied by test options.

## 22. Acceptance

T1 is manifested correctly when:

```text
there is one canonical task-shaped field, not two writable bodies
all field mutations enforce operator ownership
☱ is the sole momentum writer
both eyes use one observation envelope
freshness can be derived from revision snapshots
history is attached but karma is not stored as mutable pressure
Packet operator and route trace cannot disagree
death freezes every public mutation surface
all existing tests and the new field/finality tests pass
```
