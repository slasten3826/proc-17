# Authority Instrument I09 Cutover Observation

```text
layer: CHAOS
date: 2026-08-11
status: runtime_observation_and_treatment
source blueprint:
  docs/02_crystall/blueprints/authority_epoch_edge_credit.v0.md
slice: I09 canonical v3 cutover
source checkpoint commit: 93c5cfc
implementation commit: pending
live default: edge-stats.v3
historical reader: runtime/edge_stats_v2.lua
route authority change: none
```

## 0. Result

I09 is complete in the working tree. `runtime.edge_stats` is the canonical v3
facade, the runner defaults to v3, and historical v2 has no live reader or
writer. Explicit selection of v2 is rejected. `off` remains a test-only
ablation behind its existing override.

The first full run exposed a host-cost defect in the new default instrument.
The physical ledger was correct, but each observation entered through the
public adversarial API:

```text
verify all old evidence
deep-copy the whole ledger
append one fact
verify all evidence again
deep-copy the whole ledger back
```

Because source verification recomputes cryptographic identities, one Packet
life paid repeatedly for its complete observation history. The cost grew with
history rather than with the new fact. The interrupted stack terminated in
`edge_stats_v3.verify_source_record` while rehashing an old source during a new
route commit.

This was not Packet budget or identity mass, but it made the supposedly
massless instrument operationally capable of dominating the measured life.

## 1. Boundary Diagnosis

Two callers had been conflated:

| Caller | Trust boundary | Required behavior |
|---|---|---|
| external/corpus caller with a public ledger | ledger may have been mutated | verify old state, transact on a copy, verify result |
| live runner that solely owns one unfinished observation | no reader can yet consume a ledger | detach inputs, append pending observations, verify once at closure |

The public `record_*` API was not wrong. Using it as the internal tick path was
wrong. Removing its checks would make hostile mutation cheap again; disabling
v3 in normal tests would hide the cost from the real body.

## 2. Treatment

### 2.1 Statistics recorder

`edge_stats.begin_runtime` creates an opaque, one-life recorder. Every runtime
call stores a deep copy of one observation. The recorder exposes no counters,
source store or intermediate evidence.

At `finish_runtime`:

```text
replay observations in causal order
if one operation rejects, rebuild the accepted prefix
record the rejection as typed instrument error
refresh derived edge state
verify the complete ledger once
publish detached edge_stats and edge_evidence
destroy the pending journal
```

The rebuild on rejection preserves public transaction semantics even when a
low-level operation had touched its private working ledger before returning an
error.

A fresh runtime ledger contains exactly one named life. Its per-life source
usage is therefore derived directly from the already verified global usage,
instead of rescanning every older source before each capture. Merged
multi-life ledgers retain the complete per-life scan.

### 2.2 Credit state

Edge credit cannot be fully deferred because selection, commit and arrival
records are source facts for later phases of the same life. Its runner-owned
path therefore appends directly to the one private event tail. Each operation
records the old tail length and truncates back to it on rejection. The entire
state is verified once before publication.

Public credit methods retain their copy-and-verify transactions.

## 3. Truth And Reader Law

The pending recorder is not a second ledger:

```text
writer: live runner only
reader: edge_stats.finish_runtime only
truth status before closure: none
durable identity before closure: none
publication: only after complete v3 verification
crash before closure: no evidence artifact
```

The credit state is different: it mints phase records needed by the next phase,
but remains runner-owned and unpublished until its closing verifier succeeds.

No route, pressure, organ, Packet revision, budget, loss, repository or QA
decision reads either optimization surface.

## 4. Controls

The new ER battery proves:

| ID | Control | Result |
|---|---|---|
| ER01 | runtime credit and strict credit produce identical closed state | green |
| ER02 | rejected runtime credit operation leaves no event tail | green |
| ER03 | deferred stats and strict stats produce byte-equal ledgers; queued inputs are detached | green |
| ER04 | rejected queued observation becomes typed error with no partial source or counter | green |

The cutover controls additionally prove:

```text
runtime.edge_stats protocol = edge-stats.v3
live runner does not load runtime.edge_stats_v2
omitted authority_instrument selects v3
explicit edge_stats_v2 is rejected
off requires test override
result has only canonical edge_stats / edge_evidence fields
```

## 5. Runtime Observation

A representative Tree build life with the canonical default completed:

```text
body ticks:          7
captured sources:    80
ledger status:       valid
wall time:           about 0.53 seconds on this host
```

This number is diagnostic, not a calibrated performance promise. The important
shape changed from repeated whole-history verification to one closing
verification.

## 6. Verification

```text
full suite:                  126/126 modules green
mortality battery:           8/8 green
QA hand control matrix:      84/84 green
QA red baseline:             5/5 green
native QA supervisor:        QN01-QN20 green
ER runtime recorder battery: 4/4 green
luac:                        green
```

The existing cross-device bind-mount control remains the only environment-gated
skip. I09 adds no skip.

## 7. Current Boundary

```text
I08 full masslessness campaign: complete
I09 canonical v3 cutover:       complete in working tree
I10 current evidence manifest:  not started
DISSOLVE semantic treatment:    not authorized by this result
```

The measuring instrument is now the default observer. It is ready to measure
the current body and the coming DISSOLVE experiments, but its records still
cannot promote a topology or invent an organ law without the named corpus and
decision gates.
