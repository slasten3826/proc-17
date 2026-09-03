# Local Qwen And DeepSeek proc-17 Matched A/B Results

```text
layer: CHAOS
date: 2026-08-31
status: experiment_complete / semantic_review_complete
host: candy-shop
runtime revision: c3cada3788ba7e5ded68af3b861e98d567aa34e9
production code change authorized: no
substrate ranking canonized: no
cross-model carrier experiment: first treatment complete
next decision: crystallize the carrier boundary before production changes
```

```text
UPDATE 2026-08-31

The first cross-model treatment was executed after this document was drafted:
  raw structured carrier: rejected by the BUILD envelope, no file
  compiled textual carrier: complete, one file created

The treatment result is recorded in §10. The next state is therefore not
"queued" but "first treatment complete; carrier contract needs crystallization".
```

This document records the first matched comparison between a fully local small
model and the production cloud substrate inside the same proc-17 body. It also
defines the next experiment:

```text
DeepSeek PLAN
-> bounded explicit PLAN carrier
-> fresh local Qwen BUILD
```

It extends, but does not supersede:

```text
docs/00_chaos/bounded_plan_network_build_future_functionality_notes_2026-08-12.md
docs/00_chaos/network_cold_corpus_hot_carrier_notes_2026-08-12.md
docs/00_chaos/proc17_full_project_chronicle_2026-08-30.md
```

## 0. Why This Experiment Exists

The migration from the laptop to Candy Shop created a materially different
substrate host:

```text
CPU: AMD Ryzen 5 5600X, 6 cores / 12 threads
RAM: 32 GiB
GPU: NVIDIA GeForce GTX 1080, 8192 MiB
Vulkan: 1.4, NVIDIA driver 580.178.04
```

The local model had already demonstrated that it could enter proc-17 through
the OpenAI-compatible substrate boundary and complete both PLAN and BUILD
lives. That smoke result established compatibility, not cognitive quality.

The machinist's question was therefore narrower and testable:

> When proc-17, task, mode, authority, temperature and budget are held equal,
> how different are local Qwen and DeepSeek as semantic current?

The test does not compare the same models outside proc-17. It cannot directly
measure how much proc-17 changes either raw model.

## 1. Fixed Task

Both substrates received the same Russian task. Its SHA-256 was:

```text
d1bf205b948be0f8eefd5f4ccd02e88c4cb2f931bd5c080ac708bb9a61b73a42
```

The task asked for a minimal verifiable protocol for creating one file through
an unreliable external hand. It supplied these pressures:

```text
LLM may propose but cannot own runtime truth
old receipts may be replayed
host may crash after the write and before the ledger event
observer may read a stale snapshot
a rejected repository root must not be silently reused by a descendant
lineage affordability must not change intrinsic task truth
no second mutable truth store beside the ledger
exactly-once delivery is unavailable
```

The requested output had six parts:

```text
minimal state machine from proposal to confirmed effect
one writer and mandatory reader for every transition
crash behavior at every ambiguous boundary
intrinsic truth separated from lineage affordability
at least five falsifiers
explicit unproved assumptions
```

BUILD additionally had to materialize the full answer as one new root file:

```text
analysis.txt
```

## 2. Experimental Matrix

Four fresh independent Packet lives were grown. PLAN was not passed into BUILD
in this baseline.

| Cell | Mode | Substrate | Requested model |
|---|---|---|---|
| QP | PLAN | local Ollama | `qwen3:8b` |
| DP | PLAN | DeepSeek API | `deepseek-chat` |
| QB | BUILD | local Ollama | `qwen3:8b` |
| DB | BUILD | DeepSeek API | `deepseek-chat` |

Fixed body controls:

```text
router: tree
pressure policy: qualified_need_v0
temperature: 0
max steps: 64
max substrate calls: 4
max total tokens: 32768
max loss: 10
fresh proc-17 session per cell
separate empty create-only repository root per BUILD cell
```

The local model was observed as:

```text
Ollama name: qwen3:8b
model id: 500a1f067a9f
parameters: 8.2B
quantization: Q4_K_M
execution: 100% GPU
runtime context: 4096
```

The public proc-17 result retains the requested DeepSeek model but not the
provider-returned actual model id. This document therefore does not rename
`deepseek-chat` into a more specific observed provider version.

API credentials were stored outside tracked evidence and are not present in
this document or the experiment corpus.

## 3. Runtime-Confirmed Results

| Cell | Complete | Wall | Prompt | Completion | Total | Calls | Steps | Writes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Qwen PLAN | yes | 58.52 s | 653 | 1890 | 2543 | 1 | 5 | 0 |
| DeepSeek PLAN | yes | 9.37 s | 622 | 645 | 1267 | 1 | 5 | 0 |
| Qwen BUILD | yes | 32.04 s | 695 | 1071 | 1766 | 1 | 6 | 1 |
| DeepSeek BUILD | yes | 20.94 s | 665 | 1614 | 2279 | 1 | 6 | 1 |

Every Packet died with:

```text
status: dead
death cause: complete
stop reason: manifested
budget exhausted: false
```

BUILD artifacts:

| Cell | Bytes | SHA-256 |
|---|---:|---|
| Qwen BUILD | 357 | `13a56a2e599831cb2ab09d6d73c71526ee442db0f24d0f683f1699aaecc35a26` |
| DeepSeek BUILD | 6740 | `be2274a1a289ec7503f858e4317e25622ad4e2fd156a400485547670cfb79f6e` |

These facts establish execution, accounting, death and materialization. They do
not establish semantic correctness.

## 4. Qwen PLAN Observation

The local plan returned five items:

```text
request receipt
receive receipt
write file
log ledger entry
confirm completion
```

The form was valid enough for the PLAN body, but the semantics were weak:

```text
receipt was ordered before the write
the agent, not the external hand, was assigned the write
replay defense was absent
crash ambiguity was absent
stale observation was absent
fresh-root recovery was absent
intrinsic truth and affordability were absent
falsifiers and unproved assumptions were absent
```

This was not token or body-budget exhaustion. Qwen spent one model call and
completed its Packet with remaining budget.

## 5. DeepSeek PLAN Observation

The cloud plan returned seven precise work items covering:

```text
state machine
writers and readers
crash behavior
intrinsic truth versus affordability
seven falsifier classes
unproved assumptions
BUILD materialization boundary
```

It retained almost every pressure named by the task while using about half the
tokens and one sixth of the wall time of local Qwen PLAN.

The plan was still a semantic proposal. Its writer/reader assignments were not
fully precise, and it assumed idempotency machinery not established by the
task. The observed gap is large without making DeepSeek infallible.

## 6. Qwen BUILD Observation

The body lawfully created exactly one file and independently read it back. The
file was not an answer. It contained a transport-shaped JSON template whose
nested artifact content was the literal placeholder:

```text
...
```

This is the central false-acceptance observation:

```text
runtime complete == one declared allowed effect completed
runtime complete != artifact content is semantically adequate
```

The repository hand, candidate result and manifest behaved correctly. The
missing reader is semantic content QA, not another create authority.

## 7. DeepSeek BUILD Observation

DeepSeek produced a full 6740-byte protocol containing every requested section,
seven falsifiers and ten explicit assumptions. It was substantially more useful
than the local artifact.

The artifact still contains concrete defects:

```text
final confirmation has two competing possible writers
two reads or a delay are treated as proof of freshness
one crash path skips the receipt state while declaring that state mandatory
changing generation id is treated as enough to make a rejected root fresh
the ledger is called the only mutable state while agent-held intermediate
state is also required
```

These defects remain semantic judgments by the reviewer. The body correctly
labels the artifact content as `semantic_proposal`.

## 8. What proc-17 Did And Did Not Do

The experiment rejects a strong magical interpretation:

```text
weak model + proc-17 -> strong cognition
```

The local 8B model remained dramatically weaker on this causal protocol task.
proc-17 did not manufacture missing competence.

What the body did provide was equally important:

```text
same bounded work contract
same authority and create-only hand
same truth-status boundary
same death and accounting vocabulary
comparable evidence for both substrates
containment of a semantically failed artifact
no promotion of model prose into runtime truth
```

The correct claim is therefore:

> proc-17 contains and measures substrate differences. It does not erase them.

## 9. Why The Next Experiment Matters

The baseline leaves a more useful engineering question:

> Can a small local BUILD substrate execute substantially better when a short
> high-quality PLAN projection is supplied by a stronger model?

If the answer is positive, model orchestration becomes an economic property of
the body rather than an external convenience:

```text
rare expensive semantic orientation
-> compact typed carrier
-> repeated cheap local execution
```

This would not make models interchangeable. It would allow proc-17 to assign
different cognitive work to different substrates while preserving one body and
one lineage.

## 10. Next Matched Experiment: DeepSeek PLAN To Qwen BUILD

The treatment arm will use the complete DeepSeek PLAN from this baseline as a
dead parent life.

```text
DeepSeek PLAN Packet
-> terminal manifest
-> bounded seven-item semantic projection
-> source refs + task digest + parent result digest
-> explicit applicability status
-> fresh Qwen BUILD Packet
-> new empty repository root
-> analysis.txt
```

The child must not receive:

```text
the live parent Packet
parent field or CALM
parent capabilities
full parent trace by default
hidden DeepSeek conversation memory
reviewer's later criticism of either artifact
```

The immediate matched comparison is:

```text
A: existing direct Qwen BUILD
B: same Qwen BUILD plus the exact bounded DeepSeek PLAN projection
```

Held equal:

```text
original task bytes and digest
Qwen model and quantization
temperature
proc-17 revision
body budgets
artifact path and create-only authority
fresh local model conversation
fresh repository root
```

The sole intended semantic treatment is the inherited PLAN projection. A host
harness may assemble this first experiment, but it must state explicitly:

```text
not production lineage_runner authority
not production NETWORK authority
not proof of automatic cross-model routing
```

### 10.1 Raw Structured Carrier Result

The first treatment passed the DeepSeek PLAN as a JSON-shaped semantic carrier.
Qwen produced a complete-looking analysis inside the artifact value, but its
outer work item used:

```text
key: analysis.txt
```

The BUILD contract requires the literal operation key:

```text
key: repository.create_text_file.v0
```

The body rejected the proposal before the repository hand. No file was created.

```text
result: stalled
substrate calls: 1
spent tokens: 2565
wall time: 41.40 s
writes: 0
```

A diagnostic repeat with the same raw carrier reproduced the same failure:

```text
result: stalled
spent tokens: 2565
wall time: 35.03 s
writes: 0
```

This is a valid negative result. It shows that semantic inheritance can be
present while the child still fails to satisfy the transport envelope.

### 10.2 Deterministically Compiled Carrier Result

The second treatment carried the same seven DeepSeek work-item values as a
numbered plain-text list. It removed transport-shaped keys and explicitly said
that the carrier itself must not be reproduced. No new semantic instruction,
review judgment or DeepSeek BUILD answer was added.

```text
result: complete
substrate calls: 1
spent tokens: 2472
wall time: 38.34 s
writes: 1
artifact: analysis.txt
artifact bytes: 1651
artifact sha256:
  a0d76a1cf1a14b789565be6fdff43fa0c158f74b3bbcb3f4f6bfdcb04d4b617c
```

The artifact contains the requested state machine, transition table, crash
handling, intrinsic/affordability distinction, seven falsifiers and eight
assumptions. It is far better than the direct Qwen BUILD baseline (357-byte
placeholder), but it largely follows DeepSeek's plan and inherits its defects.

### 10.3 Cross-Model Interpretation

The two arms separate three facts that would otherwise be conflated:

```text
raw semantic carrier -> Qwen semantic output: supported
raw semantic carrier -> valid proc-17 BUILD envelope: not supported
deterministically compiled carrier -> valid BUILD envelope: supported
```

The first carrier was correctly rejected by the body. Relaxing the validator to
accept `analysis.txt` as an alias would hide a protocol error and would not be
an acceptable fix.

The correct architectural lesson is:

> A future PLAN carrier needs a deterministic compiler at the body boundary.
> The compiler must preserve semantic proposal status while emitting a prompt
> envelope that the child substrate cannot confuse with the final artifact
> protocol.

This is stronger evidence for cross-model lineage, but not yet evidence for
production NETWORK authority. The host harness still selected the transition,
assembled the carrier and chose the fresh repository.

## 11. Acceptance And Falsification

The cross-model treatment is interesting only if Qwen improves on the known
direct baseline without receiving the final DeepSeek BUILD answer.

Minimum checks:

```text
artifact is not a transport template or placeholder
all six requested sections are materially present
write occurs before receipt in the proposed causal order
replay, crash and stale-observer boundaries are explicit
fresh root is distinct from generation id
intrinsic truth remains independent of affordability
at least five actual falsifiers are present
unproved assumptions remain explicit
Packet/body authority and accounting remain unchanged
```

Falsifiers:

```text
X01 child receives the full DeepSeek BUILD answer
X02 child silently shares provider conversation state with DeepSeek
X03 carrier changes repository authority or body budget
X04 generic stopping instructions, not PLAN content, explain the improvement
X05 Qwen copies plan items without resolving them into a coherent protocol
X06 semantic score improves only because output becomes longer
X07 the inherited plan is laundered into runtime-confirmed truth
X08 a malformed or tampered plan carrier still enters the child
```

An optional later control may give Qwen the same carrier envelope with the
seven PLAN items removed. That separates carrier/stopping effects from the
semantic value of the plan itself.

## 12. Conserved Result

```text
The local model works as a real proc-17 substrate.
It is not yet a competitive semantic planner for this task.

DeepSeek is materially stronger in this matched sample.
It remains fallible and subordinate to body truth.

proc-17 made the difference measurable and safe.
It did not make the difference disappear.

The next experiment is cross-model lineage, not another raw model comparison:
DeepSeek plans once; local Qwen attempts to build from the bounded residue.
```

Local raw evidence remains under:

```text
sandbox/substrate_ab_20260831_01/
```

The sandbox is intentionally Git-ignored. This document preserves the task
identity, controls, metrics, artifact hashes, bounded conclusions and next
falsifier without publishing credentials or multi-megabyte runtime state.
