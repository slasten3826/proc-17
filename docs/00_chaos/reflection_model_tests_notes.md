# Reflection And Model Substrate Tests Notes

Raw notes from live DeepSeek reflection tests after `☵ ENCODE`, `☳ CHOOSE`,
`☶ LOGIC`, `☲ CYCLE`, and `☱ RUNTIME` were default parts of the CLI route.

Date:

```text
2026-06-28
```

Trace files:

```text
/tmp/proc17-reflect-semantic.jsonl
/tmp/proc17-reflect-repo.jsonl
/tmp/proc17-model-reflection.jsonl
```

The provider reported:

```text
provider = deepseek
requested model = deepseek-chat
actual model = deepseek-v4-flash
```

So these observations are Flash-substrate observations, not Pro-substrate
observations.

## Semantic Reflection Run

Task:

```text
Reflect on proc-17's current body loop.
Return exactly 6 short lines:
  3 about what the body can already do
  3 about what is still missing
No intro.
```

Observed substrate result:

```text
Already moves through space with coordinated limb cycles.
Already senses ground contact and adjusts force distribution.
Already maintains balance through distributed feedback loops.

Still lacks proprioceptive mapping of internal joint states.
Still cannot predict terrain changes before contact.
Still has no memory of past gait failures to avoid recurrence.
```

Finding:

```text
the word body was interpreted biologically when no proc-17 context was supplied
```

This is not a failure of the packet route.
It is a context failure at the task/substrate boundary.

The body route still behaved correctly:

```text
☵ encoded 6 substrate lines as semantic_line items
☳ selected 4 and killed 2 as attention loss
☶ kept the substrate result as semantic_proposal
☲ continued because the turn was payable
☱ reported pressure without promoting the proposal into truth
△ completed and died
```

Important invariant:

```text
reflection without runtime-confirmed context can reflect the wrong domain
```

## Repo-Bounded Reflection Run

Task:

```text
Reflect on proc-17 as a coding-agent body, not a biological body.
Use only runtime-confirmed facts from the repo listing when naming files.
Return exactly 6 short lines:
  3 capabilities already present
  3 missing organs or limits
No intro.
```

Runtime-confirmed listing:

```text
logic/choose.lua
logic/cycle.lua
logic/encode.lua
logic/repo_selection.lua
```

Observed substrate result:

```text
- Can choose between files using logic/choose.lua
- Can cycle through options using logic/cycle.lua
- Can encode data using logic/encode.lua
- Missing any sensor or input-reading organ
- Missing any output or effector organ
- Missing any memory or state persistence organ
```

Finding:

```text
explicit proc-17 context fixed the biological-body drift
runtime-confirmed listing constrained file naming
LOGIC accepted only paths that existed in the listing
missing-organ claims remained semantic_proposal, not runtime truth
```

Route shape:

```text
☵ encoded repo listing as runtime_confirmed repo_path field
☳ selected all 4 listed files because the field was small
☶ validated 3 named files from the substrate response
☱ reported accepted_count = 3 and rejected_count = 0
```

This exposed a useful nuance:

```text
repo-list mode makes ☵ field = repo paths
semantic-reflection mode makes ☵ field = substrate lines
mixed reflection with repo-list needs an explicit field intent later
```

Possible future pressure:

```text
field_intent = repo_focus | semantic_reflection | mixed
```

Do not implement this yet.
It is only pressure from the live run.

## Model Substrate Reflection Run

Task:

```text
Reflect on model substrates for proc-17.
Compare fast/cheap flash-like substrate versus stronger/slower pro-like
substrate as body drivers.
Return exactly 8 short lines:
  4 useful properties
  4 risks or unknowns
Do not claim a specific unavailable model exists.
```

Observed substrate result:

```text
Fast flash substrate: low latency, high throughput, cheap per token.
Pro substrate: higher coherence, deeper reasoning, robust over long contexts.
Flash risk: brittle under complex logic, hallucinates on nuanced tasks.
Pro risk: slower inference, higher compute cost, limited scalability.
Flash unknown: degradation under multi-step reasoning chains.
Pro unknown: efficiency at extreme scale or real-time constraints.
Flash property: ideal for simple, high-volume queries.
Pro property: suited for deliberate, safety-critical decisions.
```

Route shape:

```text
☵ encoded 8 semantic_line items
☳ selected the first 4 and killed the remaining 4
☶ preserved semantic_proposal boundary
☱ showed no death pressure and payable continuation
```

Current interpretation:

```text
models are not simply smarter or dumber
models are substrates with different pressure costs
```

Flash-like substrate pressure:

```text
cheap cycle
low latency
good for drafts and repeated observation
high drift risk under deep context or subtle logic
```

Pro-like substrate pressure:

```text
expensive cycle
higher coherence
better for crystallization and irreversible choices
still must not bypass LOGIC or RUNTIME
```

## Design Consequence

The body should not encode model choice as faith in a model.

Better shape:

```text
same organs
different substrate pressure profile
different budgets
different strictness
different cycle limits
same truth boundary
```

Possible future routing rule:

```text
cheap substrate for ⋯ and early ☴
strong substrate for ◈, irreversible ☳, and final △
```

But this must remain runtime-observed policy, not mythology.

## Current Pressure

Two concrete pressures appeared:

```text
1. reflection needs explicit domain context
2. substrate selection should become runtime pressure, not CLI folklore
```

Possible future organs:

```text
substrate_profile
substrate_router
field_intent
```

Do not implement them yet.
They are only raw pressure.
