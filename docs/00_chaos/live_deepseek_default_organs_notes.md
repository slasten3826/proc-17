# Live DeepSeek Default Organs Notes

Raw notes from first live runs after `☶ LOGIC`, `☲ CYCLE`, and `☱ RUNTIME`
became default-on CLI organs.

## Default Route Observed

Current live route:

```text
▽ task
☰ connect
☴ observe / substrate call
☴ substrate_result = semantic_proposal
☱ runtime/tool contact
☶ logic boundary
☲ cycle decision
☱ runtime pressure snapshot
△ manifest
△ death
```

This route is topologically valid:

```text
☴ -> ☱ -> ☶ -> ☲ -> ☱ -> △
```

## Sanity Run

Task:

```text
Return one word: ok
```

Observed:

```text
DeepSeek returned: ok
substrate_result truth_status = semantic_proposal
LOGIC validation truth_status = runtime_confirmed
CYCLE decision = continue
RUNTIME snapshot truth_status = runtime_confirmed
final status = dead
death cause = complete
```

Boundary held:

```text
DeepSeek text was not promoted to runtime truth.
The body only runtime-confirmed its own validation, cycle, and pressure trace.
```

## Meta Reflection Run

Runtime-confirmed context:

```text
README.md
docs/03_manifest/current_state.md
docs/02_crystall/blueprints/runtime_pressure_snapshot.v0.md
docs/00_chaos/runtime_manifestation_notes.md
```

Task:

```text
Read the runtime-confirmed context.
Say what proc-17 is, what already works, and what the lower runtime eye changes.
Do not invent files outside the context.
```

Observed DeepSeek summary:

```text
proc-17 is the first procesis body
not a chatbot
packet runtime around replaceable LLM substrate
body owns lifecycle/topology/budget/trace/death/residue
substrate output is semantic_proposal, not runtime truth
lower runtime eye exposes pressure without becoming planner/agent
```

Assessment:

```text
good meta-reflection
no obvious invented file claims
kept the semantic_proposal/runtime_confirmed boundary readable
```

## Repo Listing Selection Run

Runtime-confirmed listing:

```text
docs/02_crystall
```

Task:

```text
Using only the runtime-confirmed listing, name the two most relevant blueprint
files for runtime and cycle work. Include exact paths only.
```

DeepSeek returned:

```text
docs/02_crystall/blueprints/crystallization_cycle.v0.md
docs/02_crystall/blueprints/cycle_decision.v0.md
```

LOGIC result:

```text
accepted_count = 2
rejected_count = 0
```

RUNTIME observed:

```text
logic_pressure.accepted_count = 2
logic_pressure.rejected_count = 0
cycle_pressure.last_cycle_decision = continue
```

This shows the first useful `☶ -> ☲ -> ☱` pressure chain.

## Adversarial Path Run

Task asked DeepSeek to return:

```text
docs/02_crystall/blueprints/runtime_pressure_snapshot.v0.md
docs/02_crystall/blueprints/not_real_runtime.v0.md
```

When returned as bare text, current LOGIC accepted the real path but did not
reject the absent one.

Observed shape:

```text
accepted_paths included runtime_pressure_snapshot.v0.md
not_real_runtime.v0.md remained in unparsed_text
rejected_paths did not include not_real_runtime.v0.md
```

When returned as backticked paths:

```text
`docs/02_crystall/blueprints/runtime_pressure_snapshot.v0.md`
`docs/02_crystall/blueprints/not_real_runtime.v0.md`
```

LOGIC result:

```text
accepted:
  docs/02_crystall/blueprints/runtime_pressure_snapshot.v0.md

rejected:
  docs/02_crystall/blueprints/not_real_runtime.v0.md = absent_from_listing
```

RUNTIME observed:

```text
logic_pressure.accepted_count = 1
logic_pressure.rejected_count = 1
logic_pressure.rejection_reasons = ["absent_from_listing"]
cycle_pressure.last_cycle_decision = continue
```

## Finding

The body is now useful as a pressure instrument.

It can show:

```text
what the substrate proposed
what LOGIC accepted/rejected
what CYCLE decided
what RUNTIME saw after the pressure reached the lower hub
```

But LOGIC has a concrete extractor gap:

```text
bare unknown paths are not always extracted as candidates
therefore they can remain only in unparsed_text
backticked unknown paths are rejected correctly
```

## Next Pressure

Strengthen LOGIC path extraction:

```text
extract bare path-like tokens with slash and extension
validate them against runtime-confirmed listing
reject absent candidates as absent_from_listing
keep conservative boundaries
do not repair or normalize paths
do not accept basename-only matches
```

This is a good next crystallization target.
