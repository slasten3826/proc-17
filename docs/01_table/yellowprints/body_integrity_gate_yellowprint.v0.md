# Body Integrity Gate Yellowprint v0

Status:

```text
table
from docs/00_chaos/body_integrity_gate_notes_2026-07-18.md
scope: existing body integrity only
```

## 1. Boundary Matrix

| Boundary | Current risk | v0 writer law | Returned value law |
|---|---|---|---|
| `packet.new` options | nested metadata/host/memory aliases | deep-copy body-owned options | Packet is trusted body |
| `packet.append_chaos` | fragment aliases CHAOS | copy before store | event copy |
| `packet.crystallize` | one delta aliases history/current/loss | independent copies per projection | event copy |
| `packet.measure_tension` | nested values alias caller | copy each stored value | event copy |
| `body.record_*` | boundary payload aliases caller | copy before trace/store | payload + event copies |
| `body.apply_crystallized_work` | array copied, units aliased | deep-copy units | derived progress |
| `foundation.reinforce` | evidence and pattern alias spell result | independent copies | pattern copy |
| `budget.charge` / `loss.apply` | returned ledger record aliases stored history | copy detail/store/return independently | ledger record copy |
| `grave.attach` / packet memory | inherited records alias source | copy before Packet/session storage | copy or Packet only |
| `packet.manifest_packet` | manifest aliases caller | copy before store | event copies |
| `packet.freeze/die` | residue/corpse aliases caller/Packet | independent corpse projection | corpse copy |
| trace append | stored event returned directly | store internal, return copy | immutable-by-ownership copy |

Internal aliases that are intentional must be explicit compatibility aliases,
for example `instance.substrate == instance.physis` and upper observations under
the old CHAOS name. Accidental aliases across evidence/current/caller are banned.

## 2. Mutation Classes

| Class | Examples | Position required | Current tick required |
|---|---|---:|---:|
| organ event write | observation, choice, validation, cycle | yes | yes |
| organ Packet write | append CHAOS, crystallize, field mutation, foundation reinforce | yes | yes |
| body physics | budget charge, loss charge, death/freeze, route commit | attributed/validated by own contract | no extra organ lease |
| body read | progress, freshness, snapshots, readiness | no | no |
| birth materialization | FLOW field unit before first route | `▽` | birth lease |

The exported trace writer is an organ/event boundary and therefore verifies
current actor + current-visit lease. Core-internal birth/route/terminal writes use
the private append path and keep their stronger dedicated contracts.

## 3. Visit Lease Derivation

No mutable lease registry is added.

```text
assert_actor_tick(Packet, actor):
  actor resolves and equals Packet.operator
  if actor == ▽ and no route exists:
      return birth event as birth lease
  scan trace backwards:
      matching operator_tick before any route -> current tick witness
      route before matching tick               -> reject
```

For field writes with a `created_event_id` or mutation `event_id`:

```text
event exists
event.operator == actor
event occurs at or after the current visit lease
FLOW may use the birth event itself
```

Error family:

```text
mutation actor does not match packet position
organ mutation requires current operator tick
mutation source event is outside current operator tick
```

## 4. Cost Schema

Known axes:

```text
steps substrate_calls prompt_tokens completion_tokens total_tokens
estimated_tokens tool_calls file_writes test_runs time_ms money_units
```

Discrete axes:

```text
steps substrate_calls prompt_tokens completion_tokens total_tokens
estimated_tokens tool_calls file_writes test_runs
```

Validation table:

| Input | Result |
|---|---|
| unknown key | reject, no mutation |
| string/boolean/table | reject, no mutation |
| NaN / +/-infinity | reject, no mutation |
| amount < 0 | reject, no mutation |
| fractional discrete axis | reject, no mutation |
| zero | accepted, omitted from charge event |
| non-negative finite continuous amount | accepted |

`budget.init` validates configured limits by the same numeric law. `from_usage`
does not silently drop malformed external usage.

## 5. Derived Evidence Fingerprint

For every evidence record, derive a stable current tuple:

```text
stored intention_hash
stored cast_tick
stored success
stored referent
stored referent_hash
current freshness zone
current freshness reason
current effective_truth_status
current referent hash or explicit missing marker
```

The tuple is ordered by evidence append order and hashed. Reads never mutate
evidence or foundation.

Tick-window fallback includes the zone/reason, not numeric age. A stable warm
record therefore keeps one fingerprint until its rent boundary is crossed.

## 6. Acceptance Matrix

| ID | Grown condition | Required result |
|---|---|---|
| I01 | append caller fragment, mutate caller | CHAOS and trace unchanged |
| I02 | crystallize caller delta/loss, mutate caller/current | historical crystallization unchanged |
| I03 | die with caller residue, mutate caller/corpse result | Packet corpse unchanged |
| I04 | append trace, mutate returned event | stored trace unchanged |
| I05 | Packet at `▽`, call CHOOSE writer | rejected, no trace/boundary change |
| I06 | route to glyph without tick, invoke writer | rejected |
| I07 | begin current tick, invoke matching writer | accepted |
| I08 | reuse source event from older visit | rejected |
| I09 | invalid cost variants | rejected atomically |
| I10 | valid costs | previous economics preserved |
| I10b | mutate returned budget/loss record | stored economic ledgers unchanged |
| I11 | cast real file evidence, stamp, mutate file | fingerprint changes and validation debt appears |
| I12 | recast and stamp unchanged file | debt disappears and does not recur |
| I13 | normal tree/legacy lives | no unexpected route/economic/terminal regression |

## 7. Explicit Deferral

`relation_debt` and `upper_observation_debt` still need `{object_id -> version}`
coverage. This table does not invent their L2 lifecycle. The defect remains named
and is handled by the following L1/L2 crystall and witness phase.
