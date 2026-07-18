# L1 Flow Domain And Packet Birth Blueprint v0

Status:

```text
crystall / roadmap step 3 contract 1 of 4
date: 2026-07-18
table: docs/01_table/yellowprints/l1_continuing_flow_birth_mark_yellowprint.v0.md
assembly audit: docs/01_table/yellowprints/processlang_lua_four_layer_assembly_audit_yellowprint.v0.md
target interpreter: Lua 5.4
implementation authorized by this document: no
router or pressure authority: forbidden
production source adapter: still open
```

## 0. Selected Law

```text
one session-scoped flow_domain owns one continuing mutable L1(C) state
one accepted Packet birth advances that state exactly once
the newborn receives one immutable bounded flow_mark
Packet death freezes its copied mark, not the source flow_domain
prompt, Packet identity, lineage identity and L1 identity remain distinct
```

L1 is physical non-semantic current. A flow mark is evidence that one L1 event
occurred. It is not a signature authorizing CONNECT, identity, routing, lineage,
or semantic truth.

## 1. Target Modules

```text
l1/field.lua                       preserve exact standalone parity law
runtime/flow_domain.lua            NEW: continuing domain ownership
runtime/packet_birth.lua           NEW: atomic domain-to-Packet birth
core/packet.lua                    optional versioned ingress extension
organs/flow.lua                    materialize prepared ingress after birth
runtime/tension_runner.lua         opt-in birth path only in roadmap step 4
tests/test_flow_domain.lua         NEW: domain and transaction law
tests/support/l1_projection.lua    NEW: deterministic fixture adapter only
```

`runtime/session_memory.lua` does not become the mutable L1 owner in the first
implementation. It may hold an administrative domain reference. Persistence and
restart loading require a later explicit transaction contract.

## 2. Flow Domain Shape

```lua
{
  kind = "l1_flow_domain",
  protocol_version = "l1.flow_domain.v0",
  l1_protocol_version = "l1.field.v0",
  interpreter_contract = "lua-5.4",
  variant = "C",

  stream_id = string,
  stream_epoch = integer,
  birth_seq = integer,
  state = l1_state,
  status = "open" | "frozen",

  source_provenance = {
    adapter_id = string,
    source_ref = string,
    source_count = integer,
    config_ref = string | nil,
  },

  birth_events = immutable_event[],
  busy = boolean,
}
```

Invariants:

```text
stream_epoch >= 1
birth_seq >= 0
state.ticks == birth_seq for packet_birth-only v0 domains
state.source.ref == source_provenance.source_ref
status=frozen forbids another birth
busy is an in-process serialization lock, not persisted truth
```

The exact birth identity is:

```text
(stream_id, stream_epoch, birth_seq)
```

The bounded L1 fingerprint may collide and has no identity authority.

## 3. Public Domain API

```lua
local flow_domain = require("runtime.flow_domain")

domain, err = flow_domain.new(source, options)
view, err   = flow_domain.snapshot(domain)
domain, err = flow_domain.freeze(domain)
```

`new` delegates canonical physics to `l1.initialize`. It requires an explicit
bounded source adapter result and provenance. It never reads a prompt.

`snapshot` returns a deep copy of administrative state plus `l1.snapshot`; it
does not expose the mutable ring arrays.

`freeze` is for explicit session/domain shutdown. Ordinary Packet death never
calls it.

Only `runtime.packet_birth` may advance an integrated domain in v0. The domain
module does not expose a public free-running `tick` operation.

## 4. Flow Mark Envelope

```lua
{
  protocol_version = "l1.flow_mark.v0",
  l1_protocol_version = "l1.field.v0",
  variant = "C",
  stream_id = string,
  stream_epoch = integer,
  birth_seq = integer,
  trigger = "packet_birth",
  snapshot = l1_snapshot,
  source_provenance = bounded_copy,
  domain_event_ref = string,
  event_truth_status = "runtime_confirmed",
  content_truth_status = "non_semantic_measurement",
  semantic_claim_status = "none",
}
```

The Packet stores one owned copy under a versioned ingress extension:

```lua
packet.ingress = {
  protocol_version = "packet.ingress.v0",
  integration_protocol = "vertical_packet_life.v0" | nil,
  flow_mark = flow_mark | nil,
  l1_projection = bounded_projection | nil,
  carrier_ref = string | nil,
  inherited_grave_refs = string[],
}
```

The birth trace event stores another copy. Corpse and packet-memory projections
include bounded `flow_mark` provenance but never the live domain state.

## 5. Atomic Birth API

```lua
local packet_birth = require("runtime.packet_birth")

instance, receipt_or_err = packet_birth.create(domain, prompt, options)
```

`options` may contain already validated Packet identity/options and one explicit
fixture projection adapter. It may not contain an arbitrary prebuilt flow mark.

Transaction order:

```text
1. validate prompt, Packet identity, carrier metadata and domain ownership
2. reject frozen or busy domain
3. clone canonical L1 state into tentative state
4. tick tentative L1(C) exactly once
5. snapshot tentative state and construct mark/event/receipt
6. construct Packet with independent mark copies and append birth evidence
7. commit tentative state, birth_seq and domain event as one in-memory commit
8. clear serialization lock and return Packet plus receipt copies
```

Expected validation failure commits nothing. A Lua/invariant failure is loud and
must clear the in-process lock; it is not a Packet death. No caller can observe a
Packet before the domain commit completes.

Required receipt:

```lua
{
  kind = "l1_packet_birth_receipt",
  protocol_version = "l1.packet_birth.v0",
  packet_id = string,
  flow_ref = {stream_id=string, stream_epoch=integer, birth_seq=integer},
  flow_mark = owned_copy,
  event_truth_status = "runtime_confirmed",
}
```

## 6. Birth, Grave Attach, NETWORK And FLOW Ordering

The complete ingress order is fixed even though the outer lineage runner is a
later roadmap step:

```text
0. NETWORK/recovery code validates carrier and prepares identity metadata
1. session selects inherited graves without mutating a Packet
2. packet_birth atomically advances L1 and creates the newborn
3. grave.attach seeds karma/unresolved pressure into that newborn
4. FLOW materializes prepared prompt/carrier/projection/repair inputs
5. only after FLOW completes may a route be derived and committed
```

`NETWORK@▽` is a boundary protocol, not an eleventh operator. It never appears
in topology or the Packet trace as a glyph. The first operator remains `▽`.

Current `tension_runner` attaches graves after FLOW. The opt-in vertical path
must reverse that local order. The default path remains unchanged until matched
off/on tests pass.

Invalid carrier or grave selection fails before the L1 birth transaction and
therefore consumes no birth sequence. A failure after an accepted birth is a
failure in that newborn's life; it may not silently rewind the continuing
domain.

## 7. Prompt, Mark And Projection Separation

```text
prompt          -> semantic ingress through FLOW
flow_mark       -> audit/replay provenance only
l1_projection   -> optional bounded physical fixture input
canonical L1    -> never copied into Packet
```

Removing only `flow_mark` while keeping all other fixture input equal must not
change route, semantics, Packet budget, or identity loss.

The production projection law remains open. Roadmap step 4 may use one explicit
deterministic fixture adapter with these restrictions:

```text
reads only the tentative post-birth L1 state and mark
returns bounded ordered non-semantic measurements
creates no retained form and chooses no route
declares every structural relation candidate through material provenance
is disabled unless vertical_packet_life.v0 is explicitly selected
```

The fixture projection is evidence for seam assembly, not a production source
adapter and not evidence that L1 improves coding.

## 8. Cost And Truth

```text
L1 birth tick        one domain compute event
Packet step budget   unchanged
Packet LLM budget    unchanged
Packet identity loss zero
semantic truth       no claim
```

The domain event may measure host time, but unknown host cost is not fabricated.
Domain economics remain separate from Packet-local budget until lineage
economics names a reader.

## 9. Death, Replay And Concurrency

Packet terminality:

```text
freezes Packet ingress copies
does not freeze or mutate flow_domain
does not carry Packet identity through △
```

The next generation receives a new mark from a new accepted birth even when it
inherits a carrier from the preceding corpse.

Replay requires initial source, exact L1 protocol, stream epoch and ordered
accepted birth events. Session restart either restores all of them atomically or
starts a named new epoch. Silent reset is forbidden.

Two births sharing one domain are serialized. Duplicate
`(stream_id, stream_epoch,birth_seq)` is an invariant failure.

## 10. Permanent Tests

| ID | Grown assertion |
|---|---|
| L1D1 | Same source/domain schedule reproduces every mark except Packet id |
| L1D2 | Two births advance sequence and L1 tick exactly once each |
| L1D3 | Fingerprint collision does not collide birth identity |
| L1D4 | Packet death leaves domain live and corpse mark immutable |
| L1D5 | Two domains never advance each other |
| L1D6 | Failed birth construction commits no state/sequence/event |
| L1D7 | Mark ablation changes no route, semantics, loss, or Packet budget |
| L1D8 | Freeze forbids birth; new epoch is explicit |
| L1D9 | Reentrant/concurrent request cannot duplicate a birth key |
| L1D10 | Full and small standalone parity remain exact under Lua 5.4 |

## 11. Explicit Deferrals

```text
production source adapter
production L1-to-TABLE projection law
domain persistence and crash recovery
domain compute pricing
environmental L1 events beyond packet_birth
lineage runner and carrier construction
any routing or semantic authority for flow marks
```

## 12. Acceptance

This crystall is implementation-ready when:

```text
the continuing domain is outside every mortal Packet
birth is one atomic tick/mark/Packet transaction
mark, prompt, carrier and optional projection remain separate
grave attach precedes FLOW in the opt-in ingress path
NETWORK remains a boundary protocol at ▽
death preserves the copied mark and cannot freeze the source
all persistent records have named replay/audit readers
no open production adapter is smuggled in through the fixture
```
