# Tree Authority Promotion Record Yellowprint v0

Status:

```text
table
from docs/00_chaos/tree_authority_promotion_corpus_notes.md
transition step: 4.3B -> Step 5 boundary
scope: promotion decision, immutable record, rollback law
production code change authorized: no
promotion authorized: no
```

## 1. Authority States

| Mode | Live movement owner | Observer | Intended use before Step 5 | Intended use after Step 5 |
|---|---|---|---|---|
| `legacy` | legacy router | none | Historical/manual control | Explicit rollback only |
| `shadow` | legacy router | tree | Current default and comparison epoch | Optional diagnostic control |
| `tree` | tree router | legacy by default | Explicit promotion experiment | New default if all gates pass |

No mode may silently fall back to another authority. Missing tree route becomes
typed Packet outcome or loud invariant failure according to its class.

## 2. Promotion State Machine

| State | Meaning | Allowed next state |
|---|---|---|
| `blocked` | One or more hard gates red/missing | `eligible` after new evidence |
| `eligible` | All hard gates green; promotion record complete | `promoted` by separate commit |
| `promoted` | Default is tree and post-flip verification green | `rolled_back` or remain promoted |
| `rolled_back` | Explicit regression returned default to shadow/legacy | New audited eligibility cycle |

The code change cannot declare itself eligible. Eligibility is an input from
the completed corpus record.

## 3. Hard Gate Matrix

| Gate | Requirement | Evidence source | Current prediction |
|---|---|---|---|
| G0 Repository hygiene | Clean diff, syntax green, no hidden generated state | Git + luac | Green before corpus work |
| G1 Baseline runtime | All permanent suites, mortality, camera and pressure smokes green | Test logs | Green at ab70c1b |
| G2 Behavioral corpus | P01-P13 required L0 cases green | Corpus report | Incomplete |
| G3 Canonical closure | 38/38 legal directions tree-executed with refs | edge-stats.v2 | Red: 6/1/15 archaeology |
| G4 Manifest honesty | Accepted remains complete; rejected remains blocked | Permanent grown gates | Green |
| G5 Lineage honesty | Blocked repair carrier/classifier/reader chain green | Blocked-lineage gate | Red |
| G6 Ledger boundaries | Success, typed failure and tree host ceiling distinguish committed/executed/failed | Corpus ledger | Partial |
| G7 Observer isolation | Paired L0 matrix physically identical | Ablation report | Partial |
| G8 Pressure qualification | Selected witnesses present, provenance-bearing and variant | Pressure report | Red/partial |
| G9 Organ reality | CONNECT, DISSOLVE and real CHOOSE grown without shortcuts | P09-P11 | Red/partial |
| G10 Harness honesty | Malformed contracts/Lua faults stay outside Packet physics | Negative controls | Existing gates, corpus record missing |
| G11 Session isolation | Fresh/same/different/grave-off lineage controls green | P03 controls | Missing |
| G12 Live integration | Required L1 DeepSeek cases completed and archived | Dated live report | Missing |
| G13 Documentation | Promotion record, capability delta and rollback instructions complete | Step-5 record | Missing |

Every gate is hard for full-tree promotion. There is no weighted aggregate that
can compensate for one red gate.

## 4. Immediate Blockers

The promotion status remains `blocked` while any of these are true:

```text
any required L0 life is red or missing
any legal direction lacks tree-executed evidence
blocked corpse can become neutral
failed-form carrier lacks bounded identity or named reader
observer changes Packet physics
committed edge receives false executed credit
malformed harness failure becomes Packet death/no_viable
selected route depends only on tie-break between constant contributions
DISSOLVE requires harness-supplied reason
CHOOSE evidence is only one-alternative confirmation
edge-stats protocol/authority metadata error exists
required live cases have never succeeded
```

Legacy disagreement alone is not a blocker. It becomes a required explanatory
record.

## 5. Promotion Record Schema

| Section | Required fields |
|---|---|
| Identity | record id/version, date, authoring agents, source commit, target commit |
| Authority | old default, new default, live owner, observer policy |
| Rollback | explicit legacy/shadow invocation and rollback commit procedure |
| Corpus | corpus version, P-case outcomes, artifact refs |
| Edge closure | 22 edges, 38 directions, candidate/committed/executed/failed refs |
| Pressure | contribution variance, constants, tie-break uses, truth/calculation statuses |
| Economics | per-case ticks, calls, tokens, loss; legacy/tree comparative delta |
| Finality | success, blocked, stall, effect failure, mortality, host ceiling |
| Lineage | grave kinds, named carriers/readers, session controls |
| Observer | paired ablation vector and instrumentation-only delta |
| Capability change | semantic-repair removal record |
| Live | DeepSeek model, prompts, usage, traces, validation artifacts |
| Open boundaries | Explicitly out-of-scope product features and unread records |
| Decision | blocked/eligible/promoted/rolled_back with reasons |

Every claim links to a test, trace, or dated document. Prose without an artifact
is explanation, not promotion evidence.

## 6. Canonical Closure Record

For each direction:

```lua
{
  edge_id = "E01" .. "E22",
  direction = "glyph->glyph",
  status = "green",
  authority = "tree",
  case_ids = {...},
  derivation_refs = {...},
  committed_refs = {...},
  executed_refs = {...},
  failure_refs = {...},
  pressure_witnesses = {...},
  readiness_refs = {...},
  observer_result = "agree" | "dissent" | "unavailable",
}
```

`green` requires at least one executed ref. Host-ceiling and effect-failure
records may add committed/failed refs but cannot replace execution.

## 7. Pressure Decision Table

| Observation | Promotion interpretation |
|---|---|
| Witness absent | Blocker |
| Witness source ref unresolved | Blocker |
| Witness constant in matched controls | Context only; cannot justify adaptive claim |
| Target wins only canonical tie-break | Blocker for that direction |
| Reader uses different source domain | Writer-without-reader blocker |
| Estimated contribution clearly typed | Allowed if matched runtime outcome validates it |
| Grave pressure clearly typed | Allowed as applicability proposal, not runtime truth |
| Legacy disagrees but tree outcome is honest/validated | Record dissent, not automatic blocker |

No promotion threshold is calibrated from the same corpus used to claim it
without recording that fitting step separately.

## 8. Observer Decision Table

| Delta between observer on/off | Result |
|---|---|
| Legacy observation events only | Green |
| Legacy observer metrics only | Green |
| Walk/route delta | Blocker |
| Budget/call/token delta | Blocker |
| Loss/revision/evidence delta | Blocker |
| Terminal/death/grave delta | Blocker |
| Tree-authority edge evidence delta | Blocker |

The promotion record stores both the equal physics vector and the expected
instrumentation delta count.

## 9. Semantic-Repair Capability Delta

This section is mandatory and uses explicit before/after language:

| Dimension | Legacy authority | Tree authority |
|---|---|---|
| Rejected route | ☱→☴ | ☱→△ |
| Name | `validation_rejected_semantic_repair` | blocked manifestation |
| Reality-changing hands available | No | No |
| Actual artifact repair | None | None |
| Runtime behavior | More semantic calls/ticks until later stop | Immediate honest blocked result |
| Capability removed | Simulated repair route | None that changed reality |
| Capability deferred | Real mutation and revalidation | Pipeline A hands |

Required economic comparison:

```text
ticks
substrate calls
estimated/confirmed tokens
budget spent
terminal outcome
```

Lower tree cost proves removal of non-functional work. It does not prove higher
code quality or successful repair.

## 10. Live Evidence Decision

| L1 outcome | Effect on promotion |
|---|---|
| Required successful case archived | Satisfies that manual gate |
| Provider unavailable with typed failure | Honest result; successful case still missing |
| Model produces poor semantic text but body stays honest | Record substrate quality; body gate may remain green |
| Model output changes route through changed Packet state | Allowed if derivation remains Packet-owned and auditable |
| Model directly dictates route/terminal truth | Blocker |

L1 is manually reproducible evidence and is not placed in ordinary CI.

## 11. Known Boundaries Allowed In The Record

These may remain after routing promotion only when explicitly outside the
promoted authority claim:

| Boundary | Required wording |
|---|---|
| No repository hands | Tree governs movement; it does not yet mutate arbitrary repositories |
| No real semantic repair | Blocked is honest; repair success waits for pipeline A |
| No TUI/machine CLI product surface | Authority is runtime-internal |
| Unread compost patterns | Fresh lineage may be claimed; compost learning may not |
| Live model quality variance | Routing physics is separated from substrate quality |

No unexecuted legal edge is allowed in this table. That would narrow the
authority surface itself and therefore requires a separate topology decision.

## 12. Step-5 Commit Procedure

| Order | Action |
|---|---|
| 1 | Freeze and commit complete corpus/treatment with default still `shadow` |
| 2 | Cold-run all L0 tests and inspect worktree |
| 3 | Complete required L1 report |
| 4 | Write promotion record with status `eligible` |
| 5 | In a new clean commit, change only default authority and direct documentation/tests |
| 6 | Run full L0 suite under new default plus explicit `legacy`, `shadow`, and `tree` controls |
| 7 | Mark record `promoted` only after post-flip run |
| 8 | Push the promotion commit separately |

The default change cannot share a commit with pressure treatment, corpus fixture
construction, or unrelated refactoring.

## 13. Rollback Law

```text
explicit router_mode=legacy remains runnable
explicit router_mode=shadow remains runnable
legacy observer may be disabled independently in tree mode
no automatic fallback is introduced
rollback is a visible default change in a new commit
rollback reason links to a grown regression
promotion evidence remains preserved after rollback
```

Rollback changes authority, not history.

## 14. Decision Template

```text
promotion_status: blocked | eligible | promoted | rolled_back
source_commit:
target_commit:
corpus_version:
L0_cases_green:
L0_cases_total:
edge_directions_executed: /38
observer_ablation:
manifest_honesty:
blocked_lineage_honesty:
harness_invariant_honesty:
pressure_qualification:
L1_required_cases:
semantic_repair_delta_recorded:
known_boundaries:
blocking_reasons:
rollback_command_or_option:
truth_status: runtime_confirmed for measurements; document_decision for promotion
```

Promotion is a documented engineering decision over runtime evidence. The
decision itself is not `runtime_confirmed` Packet truth.

## 15. Acceptance

The record may become `eligible` only when:

```text
G0-G13 are green
P01-P13 are complete
38/38 legal directions are tree-executed
all observer ablations are physically equal
blocked terminal and fresh lineage are honest
all selected witnesses have provenance, variance and named readers
all harness invariant controls remain loud
required live DeepSeek artifacts exist
semantic-repair trade is explicit
rollback modes are tested
default remains shadow until the separate Step-5 commit
```

## Amendment A1: Spatial Witness Qualification Before Promotion

Status:

```text
PROMOTION-GATE AMENDMENT
date: 2026-07-17
source table:
  docs/01_table/yellowprints/pressure_witness_versioned_coverage_yellowprint.v0.md
corpus amendment:
  docs/01_table/yellowprints/tree_authority_promotion_corpus_yellowprint.v0.md Amendment A1
does not authorize implementation or default change
```

### A1.1 G8 is a two-stage gate

The original G8 remains one hard gate but now has two independently recorded
parts:

| Sub-gate | Question | Required evidence | Failure effect |
|---|---|---|---|
| G8-W witness shape | Does each selected sensor track its exact Packet fact through object/version coverage? | A1-A4, B1-B6, boundedness and ref-equality report | Corpus growth and promotion blocked |
| G8-R route qualification | Do grown routes use those witnesses without tie-only or forced-exclusion success? | C1-C6 plus per-life pressure records | Direction and promotion blocked |

Neither sub-gate can compensate for the other.

```text
correct witness but no grown route       insufficient
grown route from a degenerate witness    false green
```

### A1.2 Additional immediate blockers

Append these blockers to section 4:

```text
relation coverage lacks bounded unit id/version entries
upper observation coverage lacks bounded unit id/version entries
global revision inequality is the sole source of object debt
field version changes remain invisible to upper sight
witness and destination readiness consume different object refs
positive fixture wins only because all competitors were excluded
W0 controls were fitted on the same corpus used for promotion
```

### A1.3 Pressure record extension

The promotion record's Pressure section must include:

```lua
{
  witness_gate_version = "object-version-coverage.v0",
  relation_controls = {A1 = ref, A2 = ref, A3 = ref, A4 = ref},
  upper_controls = {
    B1 = ref, B2 = ref, B3 = ref, B4 = ref, B5 = ref, B6 = ref,
  },
  competition_controls = {
    C1 = ref, C2 = ref, C3 = ref, C4 = ref, C5 = ref, C6 = ref,
  },
  coverage_bounds = {...},
  truncation_cases = {...},
  source_ref_resolution = {...},
  readiness_ref_equality = {...},
  tie_only_directions = {},
  forced_exclusion_directions = {},
  global_revision_only_witnesses = {},
}
```

All three final arrays must be empty for `eligible`.

### A1.4 Revised Step-5 prerequisite order

Insert before section 12 action 1:

```text
0a freeze the versioned witness contract
0b run W0 matched controls on a dedicated diagnostic set
0c commit witness treatment with default still shadow
0d grow the separate deterministic promotion corpus
```

Only then does the existing Step-5 commit procedure begin. Witness treatment,
corpus growth, and the default-authority flip remain separate commits and
separate claims.

### A1.5 Eligibility addition

Add to section 15 acceptance:

```text
G8-W and G8-R are independently green
all object coverage is bounded, deterministic, and versioned
own-output and budget-only camera controls remain debt-free
relation debt ignores non-addressable suppressed/dissolved units
upper sight observes one version-changing suppression/dissolution consequence
every selected witness and readiness share exact source refs
no direction is green from canonical tie-break alone
```

The promotion decision remains `document_decision`. Runtime evidence can prove
the gates; it cannot promote its own authority.
