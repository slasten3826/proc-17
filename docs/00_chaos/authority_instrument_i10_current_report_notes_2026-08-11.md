# Authority Instrument I10 Current Report Notes

```text
layer: CHAOS
date: 2026-08-11
status: implementation_hypothesis
source:
  docs/02_crystall/blueprints/authority_epoch_edge_credit.v0.md
  docs/00_chaos/authority_instrument_i09_cutover_observation_2026-08-11.md
baseline revision: 12817e4
authority change: forbidden
promotion decision: forbidden
```

## 0. Why I10 Exists

I09 made v3 the ordinary observer. The instrument can now answer what the
current body actually did, but the answer is still scattered across per-life
ledgers and incompatible evidence epochs.

I10 must produce one reproducible current report without committing the oldest
measurement error in the project: adding unlike worlds together and calling
the sum reality.

The report therefore has two simultaneous views:

```text
per-epoch closure views: auditable facts, never merged across epoch ids
cross-epoch union:       diagnostic index only, never promotion evidence
```

## 1. Inputs

The campaign grows fresh deterministic lives through the ordinary runner with
the canonical v3 default. Each admitted life carries:

```text
one verified edge-stats.v3 ledger
one exact authority epoch
one immutable post-life projection
one current case id from tree-authority-cases.v0
one exact implementation revision and verifier ref
```

No hand-built route record may enter the current report. Unit and archaeology
layers remain visible in their own tests but are excluded from current corpus
credit.

## 2. Report Questions

The report must answer, mechanically:

1. Which physics and evidence epochs were observed?
2. Which legal directions physically executed inside each epoch?
3. Which directions received qualified execution credit inside each epoch?
4. Which eligibility rejection reasons occurred, in which epochs, and which
   protocol reasons remained unobserved?
5. What is the diagnostic physical/eligible union across all observed epochs?
6. What is the current status of every P01-P13 and L1 case gate?
7. Why is promotion still blocked?

The seventh answer is not inferred from optimistic counts. The report has no
target epoch decision and no authority to create one.

## 3. No Cherry-Pick Law

An epoch record is retained even when it contributes no eligible direction or
only rejection reasons. An observed red/invalid ledger aborts report assembly;
it cannot be omitted to improve the union. Duplicate life/run identity rejects.

Every evidence epoch gets its own closure query. A cross-epoch union carries:

```text
truth_status = diagnostic_query
promotion_eligible = false
source_epoch_ids = exact sorted set
```

It is an index for choosing the next experiment, not a synthetic super-epoch.

## 4. Case Gates

The current `tree-authority-cases.v0` manifest remains the owner of the case
vocabulary. The report copies every derived status from corpus closure:

```text
P01-P05
P06a / P06b
P07-P13
L1_ACCEPTED_BUILD
L1_REJECTED_BUILD
L1_MULTI_CHOOSE
L1_LONG_TREE
```

Growing a life with a case id does not make its case green. The named evaluator
and required controls must still produce verified case evidence. Missing stays
missing; blocked stays blocked; red is never dropped.

## 5. Rejection Vocabulary

The edge-credit module owns the closed eligibility reason vocabulary. I10 may
read a detached sorted list from that owner. It must not duplicate the list in
the report writer. Every reason appears in the report with count and exact
epoch ids, including zero-count reasons.

## 6. Output Boundary

The durable manifest contains no Packet, provider handle, source bytes, grant,
live corpus object or mutable ledger. It records bounded scalar summaries,
direction ids, protocol ids, case statuses, rejection counts and report digest.

The full machine-readable campaign result may be regenerated from the named
script and revision. The human manifest is a projection of that result, not a
second decision surface.

## 7. Falsifiers

```text
CR01 unlike evidence epochs are summed into one closure -> red
CR02 a missing case is rendered green from direction count -> red
CR03 an unobserved eligibility reason disappears from vocabulary -> red
CR04 dirty/unknown implementation provenance receives corpus credit -> red
CR05 caller inserts promotion_authorized=true -> verification red
CR06 changed report scalar keeps old report id -> red
CR07 duplicate evidence_run_id is admitted -> red
CR08 hand-built unit route enters current union -> red
CR09 invalid instrument ledger is silently omitted -> red
CR10 regeneration at one revision changes report digest -> red
```

## 8. Expected Honest Result

The likely first report is incomplete. That is success, not failure. It should
show the directions the current body can grow, the epochs that produced them,
the reasons other executions were ineligible, and many missing case gates.

I10 completes the measuring instrument when it can say "not enough evidence"
precisely. It does not complete the full Tree or DISSOLVE campaign.
