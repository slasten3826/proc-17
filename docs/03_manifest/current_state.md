# Current State

Clean-room rebuild has started.

Current target:

```text
packet core first
```

Implemented:

```text
core/packet.lua
runtime/body.lua
logic/cycle.lua
```

Current body invariant:

```text
packet.calm.work_units -> body.progress -> logic.cycle
```

`runtime/body.lua` does not replace packet core.

It binds packet state to operator decisions:

```text
record_choice
record_validation
record_cycle
progress
cycle_input
decide_cycle
apply_crystallized_work
```

Cycle compatibility status:

```text
unit_test: body progress with remaining work -> ☲ again
unit_test: body completed work -> ☲ stop_complete
unit_test: rejected progress -> ☲ stop_invalid
```

Next organ target:

```text
☵ organs/encode.lua
☳ organs/choose.lua
```

Implemented:

```text
organs/encode.lua
  CHAOS -> logic.encode -> packet.crystallize -> CALM

organs/choose.lua
  CALM -> logic.choose -> body.record_choice -> BOUNDARY
```

Guardrails now tested:

```text
☵ source refs point to chaos
☵ does not encode substrate host secret as task material
☵ writes calm/work_units through crystallization
☳ records selected/killed alternatives
☳ does not rewrite work_units
☳ does not decide continuation
☳ does not kill packet
☲ can read encode-created work_units through body.progress
```

Next live-substrate target:

```text
☴ organs/observe.lua
```

Implemented:

```text
organs/observe.lua
  packet.chaos.raw_prompt -> substrate.ask -> packet.append_chaos
```

Guardrails now tested:

```text
☴ substrate response enters packet.chaos.fragments
☴ response remains semantic_proposal
☴ writes trace through packet.append_chaos
☴ does not write CALM
☴ missing substrate fails cleanly
```

First body route:

```text
runtime/runner.lua
  ▽ packet.new
  ☴ observe
  ☵ encode
  ☳ choose
  ☲ cycle
  △ assemble turn manifest
```

Guardrails now tested:

```text
single-pass runner moves fake substrate through observe/encode/choose/cycle/manifest
☲ again leaves packet.status = running
☲ again does not call packet.manifest_packet
☲ again does not kill packet
missing substrate fails as observe:missing_substrate
```

Next architecture pressure:

```text
fixed runner rail is smoke-only
real movement should be pressure-routed
```

Routing documents:

```text
docs/00_chaos/packet_will_routing_notes.md
docs/01_table/yellowprints/packet_routing_yellowprint.v0.md
docs/02_crystall/blueprints/packet_routing.v0.md
```

Routing v0 rule:

```text
☵ -> ☴
☳ -> ☴
☲ -> ☱
☶ -> ☱
☴ -> ☵/☳/☱
☱ -> ☲/☶/☴/△
```

Important separation:

```text
loss = packet physics
budget = runtime economics
```

Implemented:

```text
runtime/router.lua
```

Router status:

```text
standalone decision module only
not integrated into runner yet
```

Next runner target:

```text
runtime/tension_runner.lua
```

Tension runner documents:

```text
docs/00_chaos/tension_runner_notes.md
docs/01_table/yellowprints/tension_runner_yellowprint.v0.md
docs/02_crystall/blueprints/tension_runner.v0.md
```

Implemented:

```text
runtime/tension_runner.lua
```
