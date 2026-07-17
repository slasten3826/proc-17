# Tree Authority Transition Yellowprint v0

Status:

```text
table
source: docs/00_chaos/tree_authority_transition_notes.md
failure law: docs/00_chaos/body_event_and_physics_failure_boundary_notes.md
reviews: docs/00_chaos/fable_tree_authority_review_2026-07-16.md
crystall: docs/02_crystall/blueprints/tree_authority_transition.v0.md
Gate A confirmed: 2026-07-17
Gate B confirmed: 2026-07-17
Gate A evidence: docs/00_chaos/tree_authority_opt_in_results_2026-07-17.md
Gate B evidence: docs/00_chaos/tree_legacy_shadow_flip_results_2026-07-17.md
```

## 1. Scope

This table defines the controlled transfer from legacy mandatory rails to
full-tree route authority for one living Packet.

It supersedes only the authority/promotion parts of:

```text
operator_tree_physics_yellowprint.v0.md sections 10, 11 and A1.8
tension_runner_yellowprint.v0.md route/error assumptions
```

It does not replace canonical topology, Packet mortality, camera physics,
operator contracts or lineage.

## 2. Authority Matrix

| Mode | Live authority | Observer | Mandatory rails | Intended use |
|---|---|---|---|---|
| `legacy` | legacy | none | active | explicit historical control |
| `shadow` | legacy | tree | active live-only | current baseline and pre-promotion comparison |
| `tree` before instrumentation flip | tree | optional legacy report | absent | opt-in correctness experiment |
| `tree` after instrumentation flip | tree | legacy shadow | absent | promotion corpus and future default |

Tree authority is not equivalent to making `tree_router` predictions true.
It means only tree derivation may commit the next route.

## 3. One Derivation Table

| Order | Stage | Owner | State mutation | Cost |
|---:|---|---|---|---|
| 1 | read current Packet state | pressure readers | none | none |
| 2 | append immutable pressure snapshot | body trace | trace only | none |
| 3 | enumerate canonical neighbors | tree router | none | none |
| 4 | apply same-life lifecycle law | tree router | none | none |
| 5 | apply registry/capability/safety | registry/body | none | none |
| 6 | apply readiness | organ contracts | none | none |
| 7 | apply affordability | budget/loss readers | none | none |
| 8 | score surviving candidates | pressure policy | none | none |
| 9 | select winner or no viable outcome | tree router | none | none |
| 10 | append derivation evidence | body trace | trace only | none |
| 11 | commit selected route | Packet core | position + route trace | route itself has no semantic loss |

Candidate filtering and tie resolution happen inside one derivation. Rejected
candidates do not trigger another tick or recursive router call.

## 4. Candidate Outcome Matrix

| Outcome | Commit | Tick | Budget | Loss | Next action |
|---|---:|---:|---:|---:|---|
| excluded: lifecycle/safety | no | no | zero | zero | consider remaining candidates |
| excluded: missing capability | no | no | zero | zero | consider remaining candidates |
| excluded: not ready | no | no | zero | zero | consider remaining candidates |
| excluded: unaffordable | no | no | zero | zero | consider remaining candidates or mortality |
| selected | yes | later | zero at selection | zero | begin receiving organ attempt |
| no viable edge | no | no | zero | zero | typed stalled terminal law |

Rejected candidates modify only append-only derivation evidence. They do not
change pressure for the same derivation.

## 5. Execution Outcome Matrix

| Outcome | Meaning | Executed edge credit | Cost | Packet result |
|---|---|---:|---|---|
| `applied` | organ completed its declared effect | yes | actual tick/effect cost | camera, mortality, next derivation |
| `effect_failure` | coherent body observed typed external failure | no | attempted cost paid once | failure event, camera, v0 internal death |
| `invariant_failure` | trusted Lua/body law broke | invalid run | no invented accounting | loud harness failure; no honest corpse |

Validation verdict `rejected` is an applied LOGIC effect, not
`effect_failure`. The organ successfully proved rejection.

## 6. Evidence Levels

| Level | Required witness |
|---|---|
| candidate | derivation record names canonical edge and exclusions/totals |
| committed | route event references derivation and selected readiness witness |
| executed | receiving organ completed an `applied` outcome |
| failed | committed organ produced typed `effect_failure`; no executed credit |
| invalid run | invariant failure escaped body physics; not lineage evidence |

`failed` is a Packet evidence level. `invariant_failure` is not.

## 7. Route Evidence Contract

Minimum derivation record:

```lua
{
  kind = "route_derivation",
  current_operator = glyph,
  pressure_snapshot_ref = string,
  candidates = table,
  selected_to = glyph | nil,
  outcome = "selected" | "no_viable_edge",
  no_viable_cause = string | nil,
  policy = string,
  threshold = number,
  event_truth_status = "runtime_confirmed",
  trace_event_id = string,
}
```

Minimum committed route payload:

```lua
{
  kind = "tree_route_decision",
  from = glyph,
  to = glyph,
  reason = string,
  derivation_ref = string,
  pressure_snapshot_ref = string,
  selected_candidate = {
    readiness = table,
    affordable = boolean,
    total = number,
  },
  policy = string,
}
```

The route may reference the full candidate audit through `derivation_ref`
instead of duplicating it.

## 8. Entry Table

| Mode | First edge after FLOW |
|---|---|
| legacy/shadow | current `runner_entry` override remains for control compatibility |
| tree | derive from Packet state across legal `▽` neighbors `☰`, `☷`, `☴` |
| explicit test override | allowed only when marked as non-physical harness control |

Tree birth must pass the same candidate and evidence contract as internal
movement.

## 9. No-Viable Terminal Matrix

| Tree cause | Terminal class | Required residue detail |
|---|---|---|
| `missing_capability` | `stalled` | missing capabilities and candidate refs |
| `below_threshold` | `stalled` | totals, threshold and surviving readiness |
| `stalled` | `stalled` | all readiness/exclusion reasons |
| `unsafe` | existing unsafe death class | safety witness and denied edge |
| unaffordable with exhausted economics | budget/loss mortality | exhausted ledger refs |

No free wait exists in v0. `stall_kind` preserves the exact tree cause.

## 10. Effect Failure Matrix

| Source | Typed body failure | Physics failure instead when |
|---|---|---|
| substrate | timeout, disconnect, malformed external response | adapter throws or violates internal return contract |
| tool/spell | process start/exit/protocol failure | trusted runner corrupts Packet or throws unexpectedly |
| sandbox | explicit deny | sandbox permits forbidden mutation or breaks invariant |
| storage/session | declared compatibility or I/O failure | current-version record contradicts trusted schema |

First authority version terminates a coherent effect failure as
`effect_failure` after charging actual attempted cost. Retry/cycle behavior is
deferred until it has named pressure and bounded economics.

## 11. Manifest Witness Table

| Witness | Source | Status |
|---|---|---|
| no remaining work | Packet CALM/progress | existing |
| budget/loss near terminal | Packet economics | existing |
| fresh logic stamp and unchanged evidence fingerprint | Packet runtime/evidence | required before tree authority |
| reconciliation completion state | runtime camera/reconciliation | future |
| explicit usable partial-output policy | Packet output policy | future |

The logic-stamp witness means no new evidence can appear in the current
handless life. It permits honest partial manifestation; it does not claim the
artifact was repaired.

Manifest input must migrate from `options.result` to bounded Packet records.
Compatibility fallback may exist during opt-in mode but must be visible in
the manifest evidence.

## 12. Failure Boundary Table

| Signal shape | Classification | Owner |
|---|---|---|
| readiness witness with `ready=false` | candidate exclusion | tree derivation |
| typed `{kind="effect_failure"}` from organ/adapter | body event | runner/body |
| untyped error/exception from trusted body code | invariant failure | harness/test process |

No blanket `pcall` converts all errors into Packet death.

## 13. Promotion Gates

### Gate A: opt-in tree authority

```text
tree mode no longer answers tree_authority_not_promoted
tree entry uses a derivation
every committed tree route carries evidence
no unready candidate is committed
no_viable_edge is terminal and typed
normal build can reach △
typed effect failure creates an honest terminal
invariant failure still escapes loudly
mortality/finality suites remain green
```

### Gate B: instrumentation flip

```text
legacy prediction is append-only
legacy prediction cannot change live route/economics/revisions
tree live evidence feeds edge statistics
```

### Gate C: default flip

```text
at least one manifested build tree-life
at least one stalled tree-life
all mortality cases green under tree where applicable
zero expected-world harness aborts in the promotion corpus
known calibration defects documented with live traces
explicit legacy control remains runnable
```

## 14. Red Test Inventory

| Test | State at table creation | Gate A requirement |
|---|---|---|
| tree mode accepts authority | red: promotion forbidden | Packet/result returned |
| passing build manifests | red | terminal △ manifest |
| rejected validation survives harness | red | typed terminal, not nil/string |
| substrate effect failure | red | typed effect terminal |
| route evidence survives commit | red | derivation refs in Packet trace |
| FLOW entry is derived | red | no normal `runner_entry` |
| injected invariant explodes | green control | must remain loud |

Historical state at table creation: the battery was red and unregistered.
Current state: Gate A is green and the permanent `tests/test_tree_authority.lua`
suite is registered in `tests/run.lua`.

## 14.1 Gate A Treatment Record

```text
initial independent gate: 1 green / 6 red
final expanded gate:      10 green / 0 red
manifested tree walk:     ▽ ☴ ☰ ☵ ☲ ☶ ☱ △
manifest input:           Packet trace
default authority:        unchanged shadow/legacy control
```

The table remains valid. Treatment changed witnesses and writer-reader links;
it did not add pressure weights or promote tree mode to the default.

## 14.2 Gate B Treatment Record

```text
independent red baseline:        3 green / 3 red
permanent instrumentation gate: 7 green / 0 red
tree derivations:                7
legacy observer records:         7
observer ablation:               identical body physics and terminal
typed legacy absence:            1 at CONNECT
default authority:               unchanged shadow/legacy control
```

In explicit tree lives, legacy now predicts after the tree derivation and has
no commit path. Tree candidate audits feed edge statistics directly. Legacy
records feed only observer comparison counters and cannot become candidate,
rail, commit, or execution evidence.

Gate B is confirmed. Gate C remains closed pending the promotion corpus and
honest treatment of rejected-validation manifestation.

## 15. Open Calibration, Not Contract

```text
pressure weights
relation_debt strength
upper-eye freshness semantics
canonical tie behavior
rail recall rate
edge coverage target beyond minimum correctness lives
```

These may make tree lives poor. They do not permit legacy to remain the final
authority.
