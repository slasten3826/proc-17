# Body Blueprint v0

Blueprint means stable implementation contract for the next build pass.

## Primary Constraint

```text
LLM is not the agent.
LLM is substrate current.
Packet is the mortal body.
Procesis is the law.
```

The cognitive wrapper owns process control.

The substrate is called by the body.
It does not decide the full task lifecycle from a prompt.

## Topology Correction

The body must be designed around two centers:

```text
☴ OBSERVE  = chaos-facing reader
☱ RUNTIME  = manifest-facing sustainer
```

`OBSERVE` may inspect the packet, files, command output, and substrate output.

`RUNTIME` may sustain state, budget, cost, residue, and executable conditions.

Neither center is allowed to absorb all agency.

## Organ Contracts

```text
▽ FLOW
  receive task and birth packet

☰ CONNECT
  bind task to repo, tools, known context, and procesis law

☷ DISSOLVE
  remove stale assumptions, invalid context, dead branches, repeated loops

☵ ENCODE
  compress relevant state into machine-facing packet payload

☳ CHOOSE
  select next valid operation, route, tool, or pressure mode

☴ OBSERVE
  inspect without deciding; produce observations and uncertainty

☲ CYCLE
  iterate when continuation has budget and pressure

☶ LOGIC
  validate topology, permissions, tests, claims, and patch scope

☱ RUNTIME
  sustain budget, trace, residue, decoding conditions, and death checks

△ MANIFEST
  produce visible output, patch, command result, commit, artifact, or death
```

## Runtime Is Not A Memory Database

Runtime must not be implemented as an immortal chat log.

Runtime owns:

```text
budget
cost
pressure
trace continuity
residue index
decoding conditions
death conditions
```

Memory-like behavior is implemented as fast decoding of residue under current
conditions.

## Unsupported Semantic Form

Substrate output may contain unsupported forms:

```text
nonexistent method
nonexistent API
nonexistent file path
nonexistent prior action
nonexistent capability
```

The body must not manifest these as facts.

Required handling:

```text
☴ OBSERVE  capture the emitted form
☶ LOGIC    check it against files, specs, tools, and trace
☷ DISSOLVE remove unsupported factual status
☵ ENCODE   preserve the gap shape as residue
☳ CHOOSE   reject, defer, or promote to explicit work
☱ RUNTIME  record cost, recurrence, and confirmation state
△ MANIFEST only output it as fact if validated
```

Promotion rule:

```text
unsupported form + repeated recurrence + architectural fit
  -> candidate missing organ / spec / test
```

Unsupported form without recurrence or fit decays.

## Packet Children

Future multi-agent work must use child packets, not prompt-only phantoms.

Each child packet must have:

```text
parent_id
operator_role
task_slice
budget
trace
substrate_events
manifest
residue
death
```

No child packet is immortal.

First body should avoid agent multiplication.

If a phantom is needed, it must be:

```text
parent-linked
role-bound
budgeted
trace-visible
dead after return
```

## No Hidden Steering

Any hidden instruction inserted into a generic scaffold becomes an attractor.

Therefore:

```text
generic body scaffolds must stay generic
domain pressure must be explicit
task constraints must be visible in packet trace
operator prompts must not smuggle implementation preferences
```

## First Build Order

```text
1. packet protocol
2. canonical topology/router
3. runtime budget/death model
4. unsupported form protocol
5. fake substrate adapter
6. fake tool facade
7. machine-facing single-task CLI loop
8. trace/residue writer
9. tests for packet, topology, runtime, unsupported form
```

Real LLM providers must not be first.
The body should prove its loop with fake substrate before real model noise is
introduced.

## Language Contract

First implementation language:

```text
Lua
```

Lua owns the first nervous system:

```text
packet routing
organ modules
runtime budget
provider facade
tool facade
trace/residue writing
CLI loop
```

Hard runtime pieces may later move to C/Zig only after the Lua body has exposed
stable organ boundaries.

## ProcessLang Lua Reuse Contract

The old stack Lua source may be reused only as helper material.

Allowed:

```text
borrow small pure functions for organs
borrow naming where it matches current canon
borrow simple Lua style
```

Required corrections:

```text
topology must match current procesis canon
canonical operator order must be current order
packet protocol must be packet.v0
runtime must mean sustain/cost/death, not generic history
unsupported form protocol must be first-class
imports must not depend on old stack layout
```

Test status:

```text
manual_check: compare old Lua source before borrowing each module
unit_test: topology_valid_route_unit
unit_test: topology_invalid_route_unit
```

## Test Obligations

Before any real provider adapter is considered stable, these must exist:

```text
packet_birth_unit
packet_budget_spend_unit
packet_death_unit
topology_valid_route_unit
topology_invalid_route_unit
unsupported_form_capture_unit
unsupported_form_dissolve_unit
unsupported_form_promote_unit
fake_substrate_loop_integration
```

## Packet Protocol Link

The packet implementation must follow:

```text
docs/02_crystall/blueprints/packet_protocol.v0.md
```

## Machine CLI Link

The first CLI implementation must follow:

```text
docs/02_crystall/blueprints/machine_cli.v0.md
```

## Substrate Adapter Link

Current substrate adapters must follow:

```text
docs/02_crystall/blueprints/substrate_adapters.v0.md
```

## Tool Facade Link

Current tool facade must follow:

```text
docs/02_crystall/blueprints/tool_facade.v0.md
```

## Trace Store Link

Current trace persistence must follow:

```text
docs/02_crystall/blueprints/trace_store.v0.md
```

## Organogenesis Link

Future organ growth must follow:

```text
docs/02_crystall/blueprints/organogenesis.v0.md
```

## Body Modes Link

Future process mode gating must follow:

```text
docs/02_crystall/blueprints/body_modes.v0.md
```

## Sandbox Policy Link

Host interaction policy must follow:

```text
docs/02_crystall/blueprints/sandbox_policy.v0.md
```
