# NETWORK Receiver-Native Semantic Anchor Future Notes

```text
layer: CHAOS
date: 2026-08-31
status: future_functionality / experimentally_motivated
production code change authorized: no
TABLE or CRYSTALL authorized: no
NETWORK authority change authorized: no
```

This note extends, but does not supersede:

```text
docs/00_chaos/packet_lineage_reentry_architecture_notes.md
docs/00_chaos/network_cold_corpus_hot_carrier_notes_2026-08-12.md
docs/00_chaos/bounded_plan_network_build_future_functionality_notes_2026-08-12.md
docs/00_chaos/local_qwen_deepseek_proc17_matched_ab_results_2026-08-31.md
```

External research context:

```text
https://github.com/slasten3826/slastack/tree/main/research/memoris
```

## 0. One Sentence

NETWORK should not pretend that a semantic anchor survives a substrate change.
It should carry a bounded portable semantic projection and arrange a
receiver-side re-entry phase in which the receiving substrate grows its own
anchor without gaining authority to rewrite the inherited carrier.

In the machinist's terms:

```text
meaning may cross bodies
an anchor belongs to the body that produced it
NETWORK transports the conditions from which the new body can grow another
anchor
```

## 1. Trigger

The first matched cross-model treatment used:

```text
DeepSeek PLAN
-> bounded seven-item carrier
-> local Qwen BUILD
```

The experiment separated two failures that would otherwise look like one.

With a raw JSON-shaped carrier, Qwen produced materially useful semantic
content but copied the wrong surface into the BUILD envelope:

```text
key: analysis.txt
```

instead of:

```text
key: repository.create_text_file.v0
```

The body correctly rejected the proposal. No repository effect occurred.

With the same seven semantic values deterministically rendered as bounded
plain text, Qwen completed the BUILD life and materialized `analysis.txt`.
The result was much stronger than direct Qwen BUILD, but it still followed the
DeepSeek plan closely and inherited defects from that plan.

The supported observation is therefore narrow:

```text
portable semantic structure can improve a different substrate
sender-native semantic posture was not shown to transfer
input surface materially changes how the receiving substrate uses the carrier
```

This is not proof of hidden state transfer, universal cross-model memory or
production NETWORK authority.

## 2. Relation To Memoris

The `memoris` branch records a stronger same-body effect:

```text
long self-generation trajectory
-> dense late self-generated fragment
-> fragment re-enters the substrate that produced it
-> a wider operator mode may reactivate
```

That research explicitly does not promise that a fragment produced by one
model will preserve the same continuity in another model.

The proc-17 cross-model case has a different shape:

```text
sender substrate produces a bounded semantic residue
-> explicit carrier crosses NETWORK
-> receiver substrate reads foreign semantics
-> receiver must form its own working posture
```

The shared principle is compression into a re-entry surface. The new problem
is target specificity: the same semantic payload may not be a usable anchor
for every substrate, model, profile or mode.

## 3. Four Objects That Must Not Collapse

### 3.1 Portable semantic carrier

The bounded inherited work surface:

```text
objective and source refs
ordered work or dependency structure
constraints and forbidden scope
unresolved questions
completion and stopping boundary
artifact/output contract
truth and applicability statuses
cold evidence refs
```

The carrier is explicit, content-addressed and auditable. It is the inherited
authority surface, subject to its declared truth statuses.

### 3.2 Sender-native anchor

A fragment that helped the sender substrate hold its mode or trajectory.

```text
model-specific
profile-specific
possibly session-sensitive
valuable as cold evidence
not presumed portable
```

It may be retained in the cold corpus. It must not silently become the
receiver's active anchor merely because both substrates accept text.

### 3.3 Receiver-native anchor

A bounded self-generated projection produced by the receiver from the portable
carrier before substantive execution.

```text
derived from one exact carrier digest
bound to one target substrate fingerprint and work mode
produced by the receiving substrate
used as a hot re-entry lens
never promoted above the carrier's truth
```

The receiver anchor is guidance for cognition, not a second mutable store of
task truth.

### 3.4 Body truth and runtime evidence

Repository effects, receipts, validation, seal state, QA evidence, mortality
and accounting remain owned by the proc-17 body. Neither carrier nor anchor can
declare these facts into existence.

## 4. Proposed Future Flow

```text
sender Packet_n
  -> finite PLAN or other semantic result
  -> △ terminal manifest
  -> corpse + immutable cold record
  -> lineage/stage continuation decision
  -> portable NETWORK carrier
  -> NETWORK validates carrier and target boundary
  -> receiver-side anchor compilation
  -> receiver-native anchor proposal
  -> NETWORK binds anchor to carrier and target fingerprint
  -> ▽ creates fresh receiver CHAOS
  -> receiver Packet_n+1 receives carrier + native anchor
  -> ordinary body routing and authority continue
```

For the first target case:

```text
DeepSeek PLAN
-> portable plan carrier
-> Qwen re-entry / anchor compilation
-> Qwen-native anchor
-> fresh Qwen BUILD
```

The anchor compilation phase does not solve the task. Its purpose is to let
the receiving substrate restate the inherited work into a fragment that it can
itself hold during the next life.

## 5. NETWORK Ownership

NETWORK owns the boundary protocol:

```text
validate source manifest, lineage and carrier digest
verify transition and target mode were authorized elsewhere
retain target substrate/model/profile identity in trace
select an authorized deterministic carrier renderer
invoke the receiver-side re-entry contract
verify structural coverage of inherited carrier items
bind the returned anchor to carrier digest and target fingerprint
deliver carrier + anchor to fresh CHAOS at ▽
record failure without inventing successful continuity
```

NETWORK does not own the semantic content of the receiver anchor. The receiving
substrate produces that content.

NETWORK must not:

```text
rewrite inherited facts
promote semantic proposals to runtime truth
declare that hidden model state transferred
carry the living sender Packet or its capabilities
let the receiver delete inherited requirements silently
accept receiver wording as a replacement for the carrier
let an LLM rewrite transport operation keys or protocol fields
choose task truth, QA truth or repository truth
```

The lineage/stage policy still decides whether a transition should happen.
NETWORK performs an authorized transition; it does not crown itself as the
continuation authority.

## 6. Receiver Anchor Compilation Contract

This is a candidate surface for future TABLE work, not an accepted schema.

Input:

```lua
{
  protocol_version = "network.anchor_request.v0",
  carrier_ref = "sha256:...",
  carrier_item_ids = { "P1", "P2", "P3" },
  target = {
    provider = string,
    model = string,
    profile = string | nil,
    work_mode = string,
    substrate_protocol = string,
  },
  bounds = {
    max_calls = integer,
    max_input_bytes = integer,
    max_output_bytes = integer,
    max_tokens = integer,
  },
  instruction = "form_receiver_anchor_without_solving",
}
```

Candidate output:

```lua
{
  protocol_version = "network.receiver_anchor.v0",
  carrier_ref = "sha256:...",
  target_fingerprint = "sha256:...",
  work_mode = string,
  anchor_text = string,
  covered_item_ids = { "P1", "P2", "P3" },
  omitted_item_ids = {},
  added_proposals = {},
  truth_status = "semantic_proposal",
}
```

The exact schema is unresolved. The law is already visible:

```text
carrier items remain authoritative and immutable
anchor wording may change
coverage is mechanically checkable
new receiver thoughts remain proposals
```

## 7. Stable Item Identity

The portable carrier needs stable semantic item identifiers. For example:

```text
P1 state machine
P2 transition ownership
P3 crash boundary
P4 stale observer
P5 fresh descendant root
P6 intrinsic truth versus affordability
P7 falsifiers and assumptions
```

The receiver may reorder or restate `P1` through `P7`. It may not silently
drop them. A new receiver observation can be emitted as `proposal:Q1`, but it
cannot impersonate an inherited item.

Structural coverage does not prove semantic equivalence. It only prevents the
easiest class of loss. Semantic preservation remains an experimental and QA
question.

## 8. Prompt Surface And Protocol Surface

The first cross-model treatment showed that these are separate products:

```text
portable carrier data
deterministic receiver-facing rendering
receiver-native anchor
final BUILD output protocol
```

A JSON-shaped carrier can accidentally teach a weak receiver to imitate
transport structure. A plain-text carrier can reduce that confusion. This does
not make plain text canonical. It establishes a requirement for a deterministic
renderer owned by the body.

The renderer may change presentation. It may not change carrier meaning,
truth status, item identity or artifact authority.

## 9. Identity, Cache And Invalidation

A receiver anchor is valid only for the boundary under which it was formed.

Candidate cache identity:

```text
carrier digest
target provider/model fingerprint
target profile and work mode
system/body protocol revision
anchor compilation contract version
```

Changing any of these should invalidate reuse unless a later TABLE explicitly
proves a compatible relation.

The anchor may be hot during the child life and retained cold for audit after
death. It must not become an unversioned mutable session truth.

## 10. Failure Must Stay Typed

Candidate failure classes:

```text
carrier_invalid
target_adapter_unavailable
anchor_compilation_failed
anchor_bounds_exceeded
carrier_item_omitted
carrier_ref_mismatch
target_fingerprint_changed
receiver_added_untyped_requirement
```

The exact mortality and continuation policy is unresolved. A failed anchor
compilation must not be reported as successful semantic continuity, and it must
not release a child BUILD Packet with a partially trusted anchor.

## 11. Security And Authority Boundary

The receiver-side call is a semantic call, not a hand capability.

It receives no:

```text
repository grants
provider secrets
live sender handles
mutable ledger references
unbounded cold logs
authority to select its own target provider
authority to alter transport protocol fields
```

If carrier content contains text resembling BUILD operations, repository
receipts or runtime events, those remain quoted semantic content. They do not
become executable merely because the receiver repeats them.

## 12. First Falsification Experiment

Use the already fixed task and controls from:

```text
docs/00_chaos/local_qwen_deepseek_proc17_matched_ab_results_2026-08-31.md
```

Compare:

```text
A  direct Qwen BUILD
B  DeepSeek carrier -> deterministic rendering -> Qwen BUILD
C  DeepSeek carrier -> Qwen anchor compilation -> fresh Qwen BUILD
```

Keep constant:

```text
source task
DeepSeek PLAN and exact carrier digest
Qwen model and runtime profile
BUILD output contract
repository path grammar
budgets, temperature and body revision
```

Measure separately:

```text
body completion and valid effect
carrier item coverage
semantic requirement coverage
new false requirements or contradictions
inheritance of sender defects
token and wall-time overhead
whether the receiver anchor is materially better than a neutral restatement
```

The anchor hypothesis gains support only if condition C improves receiver work
without deleting carrier requirements, inventing runtime truth or merely adding
tokens.

## 13. Falsifiers

```text
A01 receiver anchor omits a required carrier item and the body accepts it
A02 anchor wording replaces the immutable carrier as lineage truth
A03 changing the target model reuses an unversioned old anchor
A04 NETWORK itself authors task semantics instead of invoking the receiver
A05 receiver adds a new mandatory requirement without proposal status
A06 anchor compilation performs repository or other hand effects
A07 raw sender anchor works no better than neutral carrier rendering
A08 receiver-native anchor adds cost but no reproducible quality improvement
A09 BUILD succeeds only when hidden provider conversation state is reused
A10 carrier transport promotes parent proposal to child runtime truth
A11 receiver copies carrier transport fields into the BUILD effect envelope
A12 failed anchor compilation still births an apparently valid BUILD Packet
```

## 14. Open Questions

```text
Q1 Is one bounded receiver call enough, or do some substrates need a short
   self-generation chain?
Q2 Is anchor compilation part of NETWORK@▽ itself, or a named receiver ingress
   phase immediately before FLOW materialization?
Q3 Does a receiver anchor survive between generations of the same model but a
   fresh provider session?
Q4 Which target fingerprint fields are required to prevent false reuse?
Q5 Can a deterministic renderer alone provide most of the benefit for strong
   models, making anchor compilation optional?
Q6 How is semantic preservation judged without giving a judge model authority
   over body truth?
Q7 Does BUILD receive both carrier and anchor, or a renderer that keeps the
   carrier visibly authoritative inside one bounded prompt?
Q8 What is the typed lineage outcome when anchor compilation fails?
```

## 15. Future Documentation Path

If the falsification experiment supports the hypothesis:

```text
TABLE A  portable carrier versus sender/receiver anchor identity
TABLE B  NETWORK receiver re-entry transaction and ownership
TABLE C  target fingerprint, cache, invalidation and failure outcomes
TABLE D  cross-model anchor ablation corpus

CRYSTALL then fixes schemas, bounds, writers, readers, truth statuses,
transaction ordering and promotion gates.
```

No production implementation should begin from this CHAOS document alone.

## 16. Current Verdict

The first cross-model treatment did not show that one model's semantic anchor
can be moved intact into another model. It showed something narrower and more
useful:

```text
a compact semantic carrier can cross substrates
the receiving substrate still needs a compatible entry surface
the body can preserve authority while the receiver forms its own posture
```

Therefore the future NETWORK law is:

> NETWORK does not transport model state. NETWORK transports verified semantic
> conditions under which a fresh receiving body may reconstruct a working
> state of its own.

