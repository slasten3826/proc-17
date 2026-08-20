# External Harness Compatibility And Non-Duplication Notes

```text
layer: CHAOS
date: 2026-08-14
status: active architecture constraint / future integration direction
decision authority: machinist
external reference: DeepSeek Harness, observed 2026-08-14
fork DeepSeek Harness: no
vendor DeepSeek Harness into proc-17: no
runtime dependency on DeepSeek Harness: none
current integration implementation: absent and unauthorized
current DISSOLVE campaign change: none
```

This document records one permanent boundary discovered after reading the
DeepSeek Harness repository and the Cordis paper:

```text
proc-17 owns work physics
external harnesses may own commodity userland
```

DeepSeek Harness already implements a substantial generic agent host. proc-17
must not spend its remaining development campaign reproducing that host under
different names. At the same time, proc-17 must not become a fork, internal
module or vendor-specific extension whose physics changes whenever one
external project changes.

The intended relation is compatibility through a narrow boundary.

Named readers:

```text
any session proposing a new generic CLI, TUI, model adapter, session store,
sandbox host, approval UI, compactor, subagent manager or workflow engine

the future author of a DeepSeek Harness compatibility TABLE

the reviewer of any dependency added to proc-17 core
```

Read trigger:

```text
before implementing generic harness or product infrastructure
before integrating proc-17 with DeepSeek Harness or another agent host
before moving an existing proc-17 authority into an external component
```

## 1. Evidence And Truth Boundary

External observations current on 2026-08-14:

```text
DeepSeek Harness is a plugin-oriented agent harness.
It provides model and tool integration, sessions, persistence and replay,
permission/sandbox mechanisms, planning/compaction/workflow facilities,
and headless or application-facing surfaces.

Cordis describes the component and effect model used by that harness.
```

Sources:

```text
https://github.com/deepseek-ai/deepseek-harness
https://github.com/deepseek-ai/deepseek-harness/tree/master/docs
the Cordis paper supplied locally and inspected on 2026-08-14
```

These are external observations, not proc-17 runtime-confirmed facts. The
upstream project is young and may change interfaces or remove facilities.

Document decisions in this note:

```text
do not fork DeepSeek Harness
do not duplicate mature generic harness facilities by default
keep proc-17 independently executable and independently testable
make future compatibility optional and adapter-bound
never run two authorities over one Packet life
```

Not decided here:

```text
the exact DeepSeek plugin API
the transport protocol
whether the adapter is an in-process plugin or an external sidecar
which upstream facilities satisfy proc-17's security contracts
whether DeepSeek Harness remains the preferred first host
```

## 2. The Ownership Split

### 2.1 proc-17 kernel physics

These remain proc-17-owned even when an external harness supplies every
commodity mechanism around them:

```text
Packet birth, identity, status, mortality and terminal finality
operator topology, readiness, pressure, route authority and edge evidence
Packet budget, loss and lineage economy
typed completion and the distinction between truth and affordability
corpse, residue, grave, carrier, NETWORK and generation continuity
CALM/CHAOS boundary semantics and truth-status rules
candidate-seal meaning and work-stage semantics
hand authority contracts and the evidence required from their effects
QA acceptance semantics and rejected-generation terminal projection
DISSOLVE release, discharge and successor-obligation physics
the future bounded PLAN -> BUILD lineage semantics
```

An external host may execute a mechanism used by one of these laws. It may not
become the writer of the law or silently reinterpret its result.

### 2.2 Commodity userland

These are external-harness candidates and must not be rebuilt as product
features without a demonstrated missing contract:

```text
model-provider catalogs and streaming adapters
generic tool registries and protocol transports
interactive shell, web, headless and SDK surfaces
session presentation, search, replay, fork and generic persistence
credential, setting and provider configuration
approval presentation and ordinary user interaction
generic compaction transport
generic workflow and subagent scheduling mechanics
editor, LSP and other commodity developer integrations
host telemetry and operational dashboards
```

proc-17 may retain minimal local implementations used as executable fixtures,
reference providers or recovery paths. A minimal reference mechanism is not a
second product and must not grow by convenience into one.

### 2.3 Shared boundary

Some facilities have a proc-17 policy half and a host mechanism half:

| Facility | proc-17 owns | External harness may own |
|---|---|---|
| Model call | why, when, bounds, Packet accounting, evidence identity | provider transport, streaming, credentials |
| Tool call | capability contract, authority, allowed effect, typed result | protocol dispatch and provider process |
| Sandbox | threat model, required isolation and admissible evidence | a backend that proves those requirements |
| QA | check contract, acceptance law, seal binding, verdict truth | isolated execution mechanism and resource plumbing |
| Persistence | Packet/corpse/carrier schemas and truth authority | durable bytes, indexing, replay transport |
| Compaction | what may be lost and what semantic carrier must survive | token-oriented compression mechanism |
| Human approval | when authority requires a human and what is authorized | prompt/UI transport and authenticated response |

This split prevents two opposite errors:

```text
reimplementing a host because proc-17 needs one of its mechanisms
outsourcing proc-17 physics because a host already has a feature with a
similar name
```

## 3. The No-Fork Compatibility Law

Compatibility must satisfy all of these constraints:

```text
DeepSeek Harness source is not copied into this repository.
proc-17 core does not import unstable DeepSeek Harness internals.
The adapter is optional and lives outside the kernel ownership surface.
proc-17 continues to run against local fakes and other model/tool hosts.
DeepSeek Harness continues to run without proc-17.
An upstream breaking change requires an adapter change, not a physics change.
No DeepSeek-specific identifier becomes Packet ontology.
```

The likely integration shapes are:

```text
DeepSeek plugin -> versioned proc-17 process/protocol
or
proc-17 host adapter -> stable public DeepSeek headless/plugin surface
```

Neither shape is selected yet. The exact upstream extension surface must be
audited when integration work is authorized. A fork is not a fallback.

## 4. One Life, One Authority

DeepSeek Harness has its own agent loop. proc-17 has a body that decides
readiness, route, completion, mortality and continuation. Those loops cannot
both govern the same life.

The integration law is:

```text
when proc-17 governs a Packet, the external default agent loop is replaced,
bypassed or reduced to a bounded service call
```

The external harness may:

```text
deliver one model invocation
execute one admitted capability
persist one event or blob
return usage and typed host evidence
surface one human approval request
```

It may not independently decide:

```text
whether the Packet is finished
whether another reasoning turn is required
which operator owns the next tick
whether a death is recoverable
whether the lineage may afford a descendant
whether QA rejection is acceptance
```

Otherwise the system would have two rulers, two stopping laws and two
accounts of progress. Any apparent compatibility that requires this is a
failed integration.

## 5. Provisional Kernel ABI

The future TABLE should derive a small host ABI instead of mirroring the full
DeepSeek TypeScript API. Candidate operations are:

```text
model.invoke / model.stream / model.cancel
capability.discover / capability.invoke / capability.cancel
event.append / event.flush / event.replay
blob.put / blob.get by digest
sandbox.start / sandbox.observe / sandbox.stop
human.request / human.resolve
clock.now / deadline.remaining / usage.read
```

Every authoritative request should carry enough coordinates to prevent host
state from becoming implicit truth:

```text
protocol_version
lineage_id
packet_id
generation
operation_id
capability_ref
contract_ref
bounds and deadline
source/provenance refs where applicable
```

Every response should be detached, typed and bounded:

```text
result or exact failure class
provider and operation identity
usage and timing evidence
effect receipt where an effect was authorized
provenance refs
no direct Packet pointer and no permission to mutate Packet state
```

The Packet trace, corpse and carrier remain proc-17 schemas. A host can store
their serialized form as opaque durable data, but storage does not become
truth authority merely because it holds the bytes.

## 6. Build-Or-Reuse Gate

Before implementing a generic-looking feature, the implementing session must
answer in order:

1. Is this a proc-17 law about work, truth, mortality, authority or lineage?
2. Is it merely a generic host mechanism already supplied by DeepSeek Harness
   or another maintained host?
3. If both are involved, can policy stay in proc-17 while the mechanism crosses
   a narrow evidence-bearing adapter?
4. What minimal local fake or reference provider is required to test the
   proc-17 contract without creating a competing product?
5. Would omitting the feature prevent the v0.1 body from proving its physics,
   or would it only make the product more convenient?

Disposition:

```text
proc-17 law                         -> implement in proc-17
commodity mechanism with host      -> define seam; do not duplicate
mixed policy/mechanism             -> keep policy; adapt mechanism
testability requirement            -> minimal fake/reference implementation
convenience before v0.1 closure    -> defer
```

Similarity of names is not enough to outsource a law. Conversely, the desire
for local control is not enough to justify rebuilding a complete harness.

## 7. Current Project Disposition

This decision does not invalidate work already completed:

```text
the CLI remains a minimal body probe and reference surface
the substrate/provider paths remain testable reference mechanisms
the repository hand remains proc-17 authority physics
the QA hand and native supervisor remain the proven security/evidence boundary
the Packet log, corpse and carrier remain canonical proc-17 records
the DISSOLVE reader remains kernel physics
```

It constrains expansion:

```text
do not turn the CLI into a broad product shell before checking host reuse
do not build a provider marketplace
do not build generic session UI or generic workflow orchestration
do not build a second general-purpose persistence platform
do not add Cordis or DeepSeek-specific concepts to Packet physics
```

The current DISSOLVE sequence R1-R10 continues unchanged. Compatibility work
is deferred until that campaign is closed and the machinist explicitly opens
a new architecture round.

## 8. Future Compatibility Campaign

When authorized, the smallest honest campaign is:

```text
H1  inventory the then-current public DeepSeek Harness extension surfaces
H2  map each required operation to kernel / userland / shared boundary
H3  write the versioned host-ABI TABLE and threat boundary
H4  crystallize one adapter without importing host ontology into core
H5  implement the adapter outside proc-17 physics
H6  run standalone-vs-hosted matched ablations with a deterministic substrate
H7  run one live model experiment only after the deterministic gates pass
```

Required ablations include:

```text
same Packet route, loss, death and lineage result with reference vs host adapter
external default agent loop demonstrably absent from Packet authority
host restart/resume cannot rewrite Packet truth
cold corpus can remain host-backed while hot carrier stays bounded
host cancellation and provider failure return typed evidence
upstream adapter removal leaves standalone proc-17 tests green
```

This campaign is not part of DISSOLVE and is not authorized by this note.

## 9. Falsifiers

The boundary is violated if any of these becomes true:

```text
proc-17 core imports DeepSeek Harness implementation modules
an upstream release forces a change to Packet physics
two loops can both choose continuation for one Packet
host session state is read as canonical Packet truth
a model/tool adapter can route, kill or resurrect a Packet
QA accepts because the host says success without proc-17 evidence binding
generic userland is implemented locally without a recorded host gap
compatibility requires carrying a fork
the reference CLI/provider grows into an undocumented competing harness
```

Any such finding returns the design to CHAOS. It must not be normalized as
integration glue.

## 10. Compact Rule

```text
Build the physics that only proc-17 can own.
Borrow the machinery that a harness already knows how to provide.
Join them through evidence, not shared mutable truth.
Fork neither the harness nor the authority.
```
