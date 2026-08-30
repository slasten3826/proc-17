# External Harness Convergence And Kernel Scope Notes

```text
PROJECT EXECUTION READER 2026-08-23:
docs/00_chaos/proc17_kernel_roadmap_and_model_orchestration_notes_2026-08-23.md

This document owns the kernel/userland and model-independence decision. The
roadmap owns milestone order, release closure and Sol/Luna work orchestration.
```

```text
layer: CHAOS
date: 2026-08-23
status: active architecture scope decision
decision authority: machinist
extends: external_harness_compatibility_and_non_duplication_notes_2026-08-14.md
external observations: DeepSeek Harness and Hax
current integration implementation: absent
current integration authority: not granted
current DISSOLVE campaign change: none
```

## 0. Why This Note Exists

The DeepSeek Harness audit already produced the law:

```text
proc-17 owns work physics
external harnesses may own commodity userland
```

Hax appeared independently and reached a materially similar boundary from a
different implementation direction. It supplies a small terminal-native host,
multiple model transports, local-model support, sessions, compaction and Unix
composition without knowing proc-17.

This is no longer one upstream project suggesting one possible reuse. It is
convergent external evidence that generic agent userland is being built outside
proc-17 and will remain replaceable.

The project decision is therefore stronger than the 2026-08-14 deferral:

```text
proc-17 v0.1 development is kernel development
proc-17 does not own a product UI
proc-17 does not own a general agent harness
proc-17 does not require model fine-tuning for process-law correctness
```

This note does not select Hax or DeepSeek Harness as a dependency. It narrows
what proc-17 itself must finish.

Named readers:

```text
any session proposing CLI/TUI product work
any session proposing another provider/session/workflow framework
any session proposing that model weights must contain proc-17 law
the future author of an external-host adapter
the reviewer deciding whether v0.1 kernel work is complete
```

Read trigger:

```text
before adding user convenience to proc-17 core
before moving body authority into a host or model
before declaring fine-tuning a runtime prerequisite
before resuming the old Go TUI branch
```

## 1. Result Of The Repository Check

This thought was not missing from the corpus. The 2026-08-14 external-harness
note already separated kernel physics from commodity userland after inspecting
DeepSeek Harness and the Cordis paper.

What was still missing was:

```text
a second independent external observation
an explicit disposition of the old proc-17-owned TUI branch
an explicit law for fine-tuning versus runtime correctness
a concrete example of a host acting only as bounded model transport
```

Therefore this document is an amendment and convergence record, not a parallel
architecture.

## 2. External Evidence And Truth Status

### 2.1 DeepSeek Harness

Observation recorded on 2026-08-14:

```text
generic agent hosting, model/tool integration, persistence, replay, workflow,
compaction, sandbox/permission mechanisms and application-facing surfaces are
already an external engineering category
```

Reference:

```text
https://github.com/deepseek-ai/deepseek-harness
```

### 2.2 Hax

Observation recorded from Hax v0.4.0 on 2026-08-23:

```text
terminal-native interactive and one-shot operation
multiple cloud and OpenAI-compatible providers
first-class llama.cpp and Ollama paths
session recording, resume and automatic compaction
Unix subprocess composition
raw one-shot mode without system context or tools
selected provider/model/effort inherited by child commands
```

References:

```text
https://github.com/OleksandrChekhovskyi/hax
https://github.com/OleksandrChekhovskyi/hax/blob/master/docs/usage.md
https://github.com/OleksandrChekhovskyi/hax/blob/master/docs/philosophy.md
```

These are source-audit observations, not proc-17 runtime-confirmed facts. No
Hax binary has been admitted as a proc-17 substrate and no hosted ablation has
run. Upstream interfaces may change.

The convergence claim is a document decision:

```text
two unrelated projects already cover enough generic userland that proc-17 has
no architectural reason to build another complete host before kernel closure
```

It is not a claim that either host already satisfies proc-17's authority,
evidence or safety contracts.

## 3. The Kernel Scope

proc-17 owns the laws that must remain true across every host and substrate:

```text
Packet birth, identity, generation and mortality
operator topology, readiness, pressure and route authority
budget, loss and lineage economics
typed completion and honest non-completion
trace, body evidence and truth-status boundaries
corpse, grave, residue, carrier, NETWORK and rebirth
candidate seal and immutable-generation work semantics
repository-hand and QA-hand authority
DISSOLVE release and successor-obligation physics
PLAN -> BUILD semantic inheritance and stopping contracts
manifestation and the exact boundary of what may be claimed
```

These are not UI features and not prompt conventions. They are the process
physics that only proc-17 can own.

An external host may transport or display their records. It cannot reinterpret
or write them merely because it owns a terminal, session or model connection.

## 4. Commodity Userland Is Outside The Kernel Roadmap

The following are not active proc-17 v0.1 product work:

```text
general interactive TUI or web UI
provider catalog and credential UX
local-model discovery and lifecycle UI
generic chat/session browser
generic transcript search, fork and replay UX
stream rendering and terminal presentation
plugin marketplace or generic tool registry
general workflow/subagent scheduler
generic token compactor
editor/LSP integrations
ordinary approval presentation
```

proc-17 may expose a narrow machine ABI and retain minimal reference adapters.
That is kernel testability, not a mandate to grow a competing harness.

The existing Lua machine CLI survives because it is:

```text
a body probe
a deterministic integration surface
a reference process boundary
a way to run the kernel without any preferred external host
```

It must remain narrow. Convenience pressure is redirected to external hosts or
future downstream interfaces.

## 5. Disposition Of The Old TUI Branch

The old TUI notes correctly discovered one durable requirement:

```text
body state must be observable without asking the substrate to explain it
```

That requirement survives as kernel ABI pressure:

```text
typed snapshots
append-only events
current operator and route evidence
budget/loss/pressure projections
manifest and terminal outcome
```

The following old decisions are no longer active kernel roadmap commitments:

```text
proc-17 must build its own Go TUI
proc-17 must own the human cockpit
the Go cockpit follows immediately after the machine bridge
```

A future Hax integration, DeepSeek Harness application, standalone viewer or
another host may render the same body evidence. The renderer remains
replaceable. The body-visibility contract remains proc-17-owned.

This is partial supersession, not deletion. The old UI sketches remain useful
as downstream display requirements and archaeology.

## 6. Model Independence And Fine-Tuning

The substrate is an untrusted semantic proposal generator.

Therefore:

```text
process-law correctness must not depend on a fine-tuned model
Packet authority must not be learned behavior
truth status must not be inferred from model confidence
mortality, stopping, capability and evidence laws stay in runtime
```

This does not mean every model can solve every task. An incapable substrate may
produce poor proposals, spend more generations or die without completion. The
body's obligation is to contain that failure and report it honestly, not to
turn insufficient capability into false success.

Fine-tuning remains a valid later optimization. It may improve:

```text
proposal relevance
operator and schema compliance
token efficiency
generation count
repeated-failure rate
small local-model usefulness
```

It is not a kernel prerequisite and not a hidden storage location for missing
physics.

Compact criterion:

```text
better weights may make a Packet life cheaper
weights may not decide what makes that life lawful
```

The existing local-substrate hypothesis remains an experiment:

```text
same local model + raw prompt
same local model + generic harness loop
same local model + proc-17 Packet lineage
```

Fine-tuning can become a fourth arm later. It must not replace the first three
or make their comparison impossible.

## 7. Hax As A Candidate Mechanism, Not Authority

Hax exposes one especially relevant candidate seam:

```text
hax --raw --no-session -p
```

Source inspection indicates that raw mode removes Hax system/context sections
and tools, while no-session prevents its session store from becoming implicit
continuity. This shape could provide bounded model transport:

```text
proc-17 composite task
-> Hax raw one-shot transport
-> provider or local model
-> detached semantic proposal
-> proc-17 body validation and accounting
```

Hax also exports selected provider, model and reasoning effort to child
commands. This suggests a later ergonomic composition:

```text
human-facing host
-> proc-17 machine CLI
-> raw model transport using the selected substrate
```

Neither composition is authorized by this note.

Hard boundary:

```text
ordinary Hax bash/edit/write tools are not proc-17 hands
the Hax agent loop is not Packet route authority
Hax session state is not corpse/carrier truth
Hax compaction output is not runtime-confirmed lineage memory
```

Hax explicitly assigns host security to a container or VM rather than to
per-command permission prompts. That is a valid host philosophy, but it does
not satisfy proc-17 hand contracts by declaration. Any future adapter must use
the shared policy/mechanism split already defined in the 2026-08-14 note.

## 8. Persistence And Compaction Boundary

External session persistence may be operationally useful, but it does not own
continuity semantics.

```text
host transcript/session     -> operational cache or cold transport
proc-17 trace               -> Packet life ledger
corpse                      -> immutable terminal witness
carrier                     -> bounded hot inheritance
lineage/corpus              -> proc-17 continuity authority
```

A model-produced host summary is always semantic material unless proc-17 has a
separate evidence-bearing derivation that authorizes a narrower projection.
The existence of automatic compaction does not permit silent promotion from
summary to inherited truth.

This preserves the earlier PZU/RAM decision:

```text
large histories may stay cold
bounded carriers may stay hot
host storage can hold bytes
storage ownership does not imply truth ownership
```

## 9. One Life, One Loop

The one-life/one-authority law remains unchanged.

If proc-17 owns a Packet life, an external harness may perform a bounded
service operation but may not run its own continuation policy over the same
life.

Forbidden dual control:

```text
host decides another turn is needed while body says terminal
host retries an effect after hand authority is consumed
host resumes compacted context as if it were a carrier
host marks task complete from model prose
host creates a descendant outside lineage economics
```

Allowed mechanism examples:

```text
one bounded model invocation
one admitted capability transaction
one typed persistence operation
one host-evidence observation
one authenticated human response
```

The response returns to proc-17 as detached evidence or proposal. It never
receives a mutable Packet pointer.

## 10. Current Development Disposition

This convergence does not open a Hax integration campaign now.

Current order:

```text
1. finish the active DISSOLVE pressure-relief campaign
2. complete the remaining full-tree kernel physics and its evidence
3. define v0.1 kernel closure from runtime behavior, not product polish
4. only then test one optional external-host adapter
```

Explicitly deferred:

```text
Go TUI implementation
Hax adapter implementation
DeepSeek Harness plugin implementation
provider/session framework expansion
fine-tuning dataset production
fine-tuned substrate dependency
```

The appearance of better external hosts is evidence for staying on the kernel,
not a reason to interrupt DISSOLVE and chase integration.

## 11. Future Minimal Adapter Experiment

When separately authorized, the first experiment should be smaller than a
product integration:

```text
A: current reference substrate
B: Hax raw/no-session transport to the same model endpoint
```

Hold constant:

```text
task
composite prompt bytes
model and reasoning setting
Packet limits
route authority
repository/QA capabilities
```

Measure:

```text
proposal bytes
usage and provider identity
route, loss, death and lineage outcome
stdout/stderr separation
timeout and cancellation behavior
host/session writes
```

Required result:

```text
adapter changes transport evidence only
adapter cannot change body law or acquire hand authority
removing Hax leaves standalone proc-17 tests green
```

No source fork is required for this experiment.

## 12. Falsifiers

This scope decision is violated if:

```text
proc-17 starts building provider/UI features already supplied by replaceable hosts
the old Go TUI becomes a v0.1 kernel completion gate
a model must memorize body law for the runtime to remain correct
fine-tuning is used to hide an unenforced authority boundary
host compaction becomes canonical lineage truth
host tools bypass repository or QA hands
two agent loops govern one Packet life
an upstream host release forces Packet ontology to change
the narrow machine CLI grows into an undocumented general harness
```

Any such finding returns the decision to CHAOS.

## 13. Compact Law

```text
External projects may make proc-17 convenient.
Model weights may make proc-17 efficient.
Neither may make proc-17 correct.

Correct process belongs to the kernel.
```
