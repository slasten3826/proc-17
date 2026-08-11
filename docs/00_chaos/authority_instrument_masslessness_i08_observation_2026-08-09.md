# Authority Instrument Masslessness I08 Observation

```text
layer: CHAOS
date: 2026-08-09
status: runtime_observation
source blueprint:
  docs/02_crystall/blueprints/authority_epoch_edge_credit.v0.md
slice: I08 full masslessness campaign
source baseline commit: 1d3433a
implementation commit: pending
default authority instrument: edge_stats_v2
canonical promotion decision: forbidden in this slice
```

## 0. Result

I08 is complete. The opt-in v3 authority instrument has zero measured mass on
Packet, repository, QA, mortality and economics across the required matched
lives. The campaign also found one real retention defect and one incomplete
observer-neutral time projection. Both were treated before this result was
recorded.

The runtime boundary remains:

```text
omitted authority_instrument -> edge_stats_v2
authority_instrument=v3      -> detached v3 measurement
authority_instrument=off      -> test override only
```

I08 does not promote v3 to the default and does not change route authority.

## 1. Matched-Life Evidence

| Case | Grown life | Required equality | Result |
|---|---|---|---|
| MI01 | birth and mortality corpse | exact Packet and raw corpse | green |
| MI02 | completed Plan life | exact Packet, corpse and life projection | green |
| MI03 | repository effect plus independent read-back | exact Packet, corpse and repository facts | green |
| MI04 | typed repository effect failure | exact Packet, corpse, cost and death | green |
| MI05 | accepted QA M4 terminal life | exact pre-seal Packet, terminal Packet, corpse and QA facts | green |
| MI06 | existing named observer off/on | only verified observer refs differ | green |

The comparisons use complete plain-data records, not selected scalar claims.
MI01-MI05 compare whole Packet and raw corpse digests. MI06 verifies and removes
only observer-named refs, then compares every observer-neutral component.

MI06 additionally grows three retention controls:

```text
long completed life        -> identical retained corpse body tail
budget-dead life           -> identical residue body tail
packet-memory capsule      -> exact equality
```

## 2. Runtime Defect Found: Observer Retention Mass

The observer already had a separate `observer-event-*` id lane, so it did not
renumber body events. It still occupied slots in bounded `trace_tail` arrays.
In a long life, enabling the observer displaced an older body event from:

```text
corpse.trace_tail
budget exhaustion residue.trace_tail
packet-memory capsule.trace_tail
```

That made the observer heritable: a grave or descendant could receive a
different body history merely because measurement was enabled. Separate ids
were therefore necessary but insufficient.

Treatment, canonicalized as TABLE Amendment A8:

```text
Packet append owns identity_lane=observer_instrumentation
core.packet.body_trace_tail counts only body-lane events
corpse, budget residue and packet memory share that one selector
complete Packet trace still retains observer evidence
```

The selector is bounded, detached and order-preserving. Historical in-memory
observer records are recognized only by the closed observer id and payload
contract; there is no payload-wording filter.

## 3. Instrument Defect Found: Copied Host Time

The first full-suite rerun crossed a host-clock second and made old LP10 red.
The exact diagnostic first named:

```text
corpse.residue.trace_tail[1].time
```

After that path was treated, a deliberately one-second-separated pair exposed
the same residue snapshot inside the payload of a retained terminal event.
This was one host-time fact copied through honest snapshots, not semantic time
and not a Packet physics delta.

Treatment:

```text
observer-neutral projection normalizes the closed A6 host-time paths
the closed set includes corpse.residue and death/manifest payload residue tails
exact projections retain every raw timestamp
metadata.time and arbitrary payload time remain comparison-significant
```

LP10 now forces the two lives to differ by one second. It is green because the
projector handles the complete closed structure, not because the fixture runs
fast enough.

## 4. False Red Found in the Test Harness

The first MI05 QA pair used generated Packet ids. The off and v3 lives therefore
became `packet-1` and `packet-2`, and exact equality correctly failed. The
fixture now supplies one explicit identity to both sides. With identity held
constant, pre-seal and terminal QA records are exact.

This did not reveal a QA-hand defect. It confirmed that a matched-life harness
must control every prerequisite before interpreting a body delta.

## 5. Verification

```text
I08 cases:                    6/6 green
edge-life projection:        green with forced one-second delta
full suite:                  124/124 modules green
mortality battery:           8/8 green
QA hand control matrix:      84/84 green
QA red baseline:             5/5 green
native QA supervisor:        QN01-QN20 green
hostile candidate campaign:  17/17 matched
trusted fault campaign:      9/9 matched
cleanup ambiguity campaign:  6/6 matched
repeated residue campaign:   32/32 matched, zero measured residue
luac:                        green
git diff --check:            green
```

The full suite retains its existing environment-gated cross-device bind-mount
skip. No new skip was introduced by I08.

## 6. Current Boundary

```text
I07 opt-in runner integration: complete
I08 full masslessness campaign: complete
I09 canonical v3 cutover: not started
I10 current evidence manifest: not started
```

The instrument is now safe to use explicitly on ordinary runner-grown
DISSOLVE/P10 lives: observing them does not alter the body history being
measured. Runtime evidence may inform I09 and the later DISSOLVE campaign, but
it cannot itself authorize a default-authority change.
