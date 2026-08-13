# NETWORK Cold Corpus And Hot Carrier Notes

```text
layer: CHAOS
date: 2026-08-12
status: future_architecture_hypothesis
trigger: machinist distinction between Packet logs on persistent storage and
         bounded resume markers in active context
production code change authorized: no
TABLE or CRYSTALL authorized: no
NETWORK authority change: no
```

This note extends, but does not supersede:

```text
docs/00_chaos/packet_lineage_reentry_architecture_notes.md
docs/00_chaos/self_documenting_lineage_corpus_notes_2026-07-20.md
docs/00_chaos/plan_build_carrier_live_software_experiment_2026-07-20.md
```

## 0. One Sentence

The complete Packet life belongs in an immutable cold lineage corpus; NETWORK
should carry only a bounded hot resume marker plus a typed semantic projection,
with content-addressed references back to the full evidence when a named reader
actually needs it.

In the machinist's terms:

```text
full Packet log -> persistent storage / cold corpus
where work stopped -> active memory / hot carrier
```

The terms `persistent storage` and `active memory` describe architectural
roles. They do not require one hardware technology.

## 1. Trigger

The paired text-appraisal experiment retained multi-megabyte Packet logs. Those
logs are valuable because they preserve the exact substrate response, trace,
pressure derivations, economics and terminal state. They are also the wrong
thing to insert into every descendant prompt.

A child normally needs:

```text
what task lineage this is
which stage and generation ended
what the parent materially produced
what remains unresolved
which exact contract governs the next stage
where the full evidence can be found
```

It does not normally need every pressure candidate, repeated projection, raw
response copy and full historical trace in active context.

## 2. Four Surfaces That Must Not Collapse

### 2.1 Cold Packet corpus

The complete immutable evidence of one life:

```text
input envelope and digests
full Packet snapshot
full trace
runner result
provider request/response metadata after redaction
budget and loss accounting
terminal manifest, corpse and residue
instrument ledgers and errors
```

Primary readers:

```text
auditor
reproducer
failure investigator
corpus assembler
explicit deep-reentry reader
```

### 2.2 Hot resume marker

The bounded current coordinate needed to continue a lineage:

```text
lineage_id
source packet/stage/generation ids
terminal/completion class
last accepted manifest ref
remaining-work summary
unresolved refs
next stage/mode proposal
cold corpus locator + digest + size
```

Primary readers:

```text
lineage runner
stage-transition policy
NETWORK carrier validator
new Packet birth
```

### 2.3 Typed semantic projection

The content that legitimately becomes new CHAOS:

```text
plan work sequence and completion boundary
build result and bounded rationale
QA verdict/evidence projection
failure or recovery constraints
declared documentation refs
```

Its content truth may remain `semantic_proposal`. Transport does not promote
it merely because its envelope is runtime-confirmed.

### 2.4 Substrate continuity

The same provider/session may retain a larger trajectory than the explicit
carrier. This can improve re-entry, but it is neither the cold corpus nor the
hot marker and cannot be required for correctness.

```text
explicit carrier works across a fresh model/session
hidden continuity is an optimization and an experimental variable
```

## 3. NETWORK's Role

The parent Packet does not cross `△`. Its identity, CALM, field, router
position, local loss and live capabilities remain dead.

```text
Packet_n
  -> △ terminal manifest
  -> corpse and cold corpus record
  -> lineage/stage decision
  -> typed NETWORK carrier
  -> ▽ new CHAOS
  -> Packet_n+1
```

NETWORK owns transport validation and ingress packaging. It does not author the
parent's semantic result and does not decide task truth.

Writers remain separate:

```text
△ / terminal assemblers    write what the life produced
lineage runner             decides continuation or stage transition
NETWORK adapter            selects an authorized bounded projection
▽ FLOW                     materializes it into the newborn field/CHAOS
new Packet organs          reinterpret and act on it
```

## 4. Candidate Carrier Shape

This is a sketch for a future TABLE, not an accepted schema.

```lua
{
  protocol_version = "network.stage_carrier.v0",
  transition_kind = "recovery" | "plan_to_build" | "build_to_plan"
                  | "qa_to_plan" | "external_reentry",

  lineage = {
    lineage_id = string,
    source_packet_id = string,
    source_stage_id = string,
    source_generation = integer,
    target_work_mode = "plan" | "build",
  },

  cold_record = {
    corpus_ref = string,
    sha256 = "sha256:...",
    bytes = integer,
    protocol_version = string,
  },

  resume = {
    terminal_class = string,
    manifest_ref = string | nil,
    remaining_work_count = integer,
    unresolved_refs = string[],
    next_contract_ref = string | nil,
  },

  semantic_projection = {
    kind = string,
    content_truth_status = string,
    applicability_truth_status = string,
    payload = bounded_value,
    source_refs = string[],
  },
}
```

The carrier must remain useful without opening `cold_record`. If ordinary
continuation always requires full-log ingestion, the resume projection is
underspecified.

## 5. Mode-Specific Semantic Carriers

### 5.1 PLAN to BUILD

The plan life writes a finite work contract:

```text
original task/source refs
bounded objective
ordered work units or dependency graph
constraints and forbidden scope
completion criteria
allowed unresolved outcomes
artifact/output contract
plan truth and applicability statuses
```

BUILD receives this as inherited orientation. The plan is not runtime truth,
but its finite completion boundary can constrain how far BUILD must continue.

### 5.2 BUILD to PLAN

The build life writes two distinct channels:

```text
runtime-confirmed:
  artifact inventory and digests
  candidate seal
  hand effects and receipts
  QA evidence and verdict
  completion state

semantic proposal:
  rationale
  decisions and assumptions
  unresolved problems
  documentation projections
  deviations from the prior plan
```

The next PLAN may compare both channels, but it may not treat BUILD's narrative
as proof that the artifact works.

### 5.3 Recovery within one mode

Not every death changes work mode.

```text
unfinished PLAN  -> PLAN continuation
unfinished BUILD -> BUILD recovery generation
complete PLAN    -> BUILD stage candidate
rejected BUILD   -> PLAN review candidate
accepted root    -> no descendant
```

The transition kind must therefore be explicit. `death happened` is not enough
to choose the child's work mode.

## 6. Persistent Storage Is Evidence, Not Prompt

The cold record needs content identity and a bounded lookup contract:

```text
canonical encoding
digest over exact stored bytes or canonical record
declared protocol/version
declared byte size and retention class
session/lineage/generation coordinates
redaction record
```

Normal re-entry reads the hot carrier. Full-log retrieval is explicit and
bounded:

```text
reader names why it needs historical evidence
reader requests exact record/ref/range or typed projection
corpus layer verifies digest and bounds
retrieved material keeps original truth statuses
retrieval cost enters lineage economics
```

An LLM similarity search over all prior logs must not silently become lineage
authority. Semantic retrieval may propose candidates; deterministic refs and
verification decide which evidence was actually loaded.

## 7. Why This Matters Economically

Repeatedly inserting the full log creates three avoidable costs:

```text
prompt tokens grow with lineage age
old irrelevant detail competes with current work
provider cache behavior becomes correctness-critical
```

The hot marker makes active context scale with current unresolved work rather
than total historical trace length. The cold corpus still preserves complete
auditability.

This does not make history free. Storage, indexing, retrieval and optional full
ingestion remain visible lineage costs. They simply do not consume every
Packet's context by default.

## 8. Documentation Relationship

The structured lineage corpus is the durable machine record. Human Markdown is
one optional projection.

```text
Packet log           complete physical evidence
structured corpus    bounded cross-life index/projections
hot carrier          immediate continuation state
Markdown             human-readable selected history
```

`documentation_profile=off` cannot delete the Packet log or hot carrier. It
only suppresses optional exported narration.

## 9. Retention, Compost And Security

Cold does not mean immortal and unbounded.

Candidate retention tiers:

```text
hot      current carrier and active stage refs
warm     recent complete generation records
cold     immutable full logs needed for audit/reproduction
compost  aggregate patterns after individual retention expires
```

Compaction must not destroy a record still named by a live carrier, accepted
artifact, QA verdict, corpse, grave or root manifest. A compacted ref must
resolve to an explicit tombstone/aggregate status, not silently disappear.

Cold records must exclude or visibly redact:

```text
API keys
authentication headers
live provider/capability handles
reusable grants
undeclared host paths and external content
unbounded stdout/stderr
```

The redaction itself is evidence and receives a named record.

## 10. First External Prototype

The 2026-08-12 text-appraisal continuation simulated, outside production
NETWORK:

```text
existing dead/complete Pro PLAN Packet
-> full plan Packet log retained in cold sandbox storage
-> compact carrier with parent hashes and seven plan items
-> fresh Pro BUILD Packet in a fresh repository
-> exact output path assessment.md
-> full child log retained separately
```

The prototype says explicitly:

```text
transition selected by host harness
not production lineage_runner
not production NETWORK authority
no hidden provider conversation continuity required
```

The experiment tests whether bounded explicit plan transport changes the
analytic BUILD result. It does not prove automatic re-entry.

Immediate runtime facts:

```text
parent Pro PLAN Packet             dead / complete
parent full Packet log             3,632,438 bytes
hot carrier                        5,148 stored bytes
carrier / parent log               approximately 0.14%
child model requested/observed     deepseek-v4-pro
child substrate calls              1
child ticks                         6
child tokens                        7,040
child terminal                      dead / complete
materialized artifact              assessment.md, 8,239 bytes
```

The complete PLAN plus BUILD cost is 11,566 tokens and two substrate calls.
The direct BUILD control cost 7,615 tokens and stalled after proposing a
non-ASCII path. Body liveness and semantic quality must be judged separately:
the staged condition also fixed the output path and supplied an explicit
stopping contract.

Local evidence and an independent ChatGPT validation brief are retained in:

```text
sandbox/proc17_plan_build_appraisal_20260812/
```

External semantic validation is complete and is conserved with its defects,
confounders and next matched experiment in:

```text
docs/00_chaos/bounded_plan_network_build_future_functionality_notes_2026-08-12.md
```

That semantic review is not runtime evidence. No causal claim about PLAN, the
stopping rule or NETWORK is promoted by it.

## 11. Falsifiers

```text
C01 child needs the entire raw parent log despite a complete carrier
C02 carrier omits a fact required for its declared completion contract
C03 parent semantic proposal becomes runtime-confirmed during transport
C04 full cold log enters every child prompt by default
C05 tampered cold record still verifies against carrier digest
C06 missing cold record makes ordinary continuation impossible when no deep
    historical reader was requested
C07 BUILD narrative overrides contrary artifact/QA evidence
C08 same death record ambiguously chooses both recovery and stage transition
C09 hidden substrate memory is required to reproduce the child result
C10 retention deletes evidence still named by an active or terminal root record
C11 optional Markdown is treated as the machine carrier
C12 carrier or cold corpus leaks live authority or secrets
```

## 12. Future Documentation Path

If experiments support this split:

```text
TABLE A  cold Packet record identity, retention and bounded retrieval
TABLE B  hot resume marker and transition-specific semantic projections
TABLE C  PLAN<->BUILD<->QA stage transition ownership and completion

CRYSTALL then fixes schemas, readers, digests, storage roots, bounds and
lineage economics.
```

No current carrier, corpse, packet-memory or documentation contract is amended
by this note.

## 13. Current Verdict

The machinist's PZU/RAM distinction is accepted as the strongest current
storage model for long Packet lineages:

```text
remember everything needed for audit
carry only what is needed for the next life
retain exact pointers so the next life can ask for more
```

NETWORK is therefore not a pipe for an immortal Packet and not a context dump.
It is the bounded membrane between a complete dead life on disk and the exact
initial conditions of a new life.
