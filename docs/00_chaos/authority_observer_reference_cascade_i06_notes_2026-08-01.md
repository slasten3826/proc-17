# Authority Observer Reference Cascade I06 Notes

```text
layer: CHAOS
date: 2026-08-01
status: runtime_confirmed_contract_falsification
source blueprint:
  docs/02_crystall/blueprints/authority_epoch_edge_credit.v0.md
slice: I06 edge-life-projection.v0
source baseline commit: 1d3433a
implementation commit: pending
body authority change: none
```

## 0. What The First Real Pair Found

The first projector controls passed on one completed life and on a deliberately
constructed named observer event. The first independently grown Tree pair did
not:

```text
legacy observer off:
  removed refs = 0

legacy observer on:
  removed refs = 1

after exact named-event removal:
  observer-neutral equality = false
```

The remaining differences occupied almost every causal component:

```text
operator walk
committed routes
budget ledger
field provenance
runtime camera
terminal residue
packet trace
```

This was not observer mass in those components. It was one identity cascade.

## 1. Root Cause

`core/packet.lua` allocated every trace event from one process-global counter.
The observer wrote one `tension_measure` into that same namespace. Therefore:

```text
observer event receives event-N
every later body event receives event-(N+1) instead of event-N
body provenance refs change
witness ids containing those refs change
pressure-action ids containing witness ids change
terminal and corpse refs change
```

Removing the observer event after death cannot undo identifiers already
derived from the shifted refs. The old observer had no economic or routing
mass, but it did have causal-address mass.

Independent matched runs also expose a second, smaller source of false red:
host wall-clock values in trace events, `death.time` and `corpse.frozen_at`.
Wall time is not a routing, budget, loss, field or terminal-cause difference.

## 2. Why Projector-Wide String Rewriting Is Rejected

A tempting repair is to recursively replace every string that resembles an
event id. That is unsafe:

```text
user content may equal an event-looking string
content-addressed witness ids embed refs inside serialized strings
rewriting derived ids requires reimplementing every owning hash contract
an over-broad filter can turn a real body delta green
```

The writer must stop manufacturing the cascade. The reader may normalize only
named host-time fields whose irrelevance is declared in advance.

## 3. Proposed Physical Identity Law

Trace identity is Packet-local. Durable corpus identity already binds
`life_id + source kind + original source id + payload digest`, so process-global
event uniqueness is unnecessary.

Two disjoint lanes are sufficient:

```text
body lane:
  event-1, event-2, ...

observer-instrumentation lane:
  observer-event-1, observer-event-2, ...
```

Both ordinals are derived from the append-only Packet trace. No second mutable
counter is introduced. An observer can add or remove its own events without
changing any later body id.

## 4. Observer-Neutral Time Law

The exact projection retains raw wall time and raw corpse identity. The
observer-neutral projection normalizes only these closed paths:

```text
packet_trace[*].time
manifest_death_residue_terminal.death.time
manifest_death_residue_terminal.residue.trace_tail[*].time
corpse.trace_tail[*].time
corpse.frozen_at
corpse.corpse_hash
```

`corpse_hash` is omitted from every observer-neutral corpse, not only from the
side that happened to contain observer events. It is a digest of the raw tail,
so retaining it would reintroduce the excluded representation indirectly.

No other field named `time`, no event id and no semantic payload is normalized.
An unexplained delta remains red.

## 5. Falsifiers

```text
R01 actual observer on/off pair changes a body-lane event id -> red
R02 actual pair differs after named observer removal and closed time normalization -> red
R03 observer event consumes body ordinal -> red
R04 unnamed same-kind event disappears -> red
R05 arbitrary metadata.time is normalized -> red
R06 raw exact projections become equal merely because neutral normalization exists -> red
R07 new mutable id counter is stored outside the trace -> red
R08 corpus source identity loses life_id binding -> red
```

## 6. Consequence For I06

The synthetic LP03 control is not sufficient. I06.2 closes only after a real
Tree life with the legacy observer enabled compares green against its real
disabled twin, including a captured corpse. This defect was found by the
instrument before the instrument was used to judge DISSOLVE; that is the right
order of failure.
