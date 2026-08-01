# QA Body Transaction M4 Terminal Retention Manifest v0

Status:

```text
layer: manifest
date: 2026-08-01
slice: M4 terminal QA projection, corpse retention and historical transport
manual actor-valid terminal action: implemented
automatic QA routing: not authorized
automatic rejected-generation recovery: not authorized
lineage software acceptance: forbidden to Packet and corpse
QA control matrix: 84 green / 0 red / 0 skip
```

## 1. Manifested Terminal Projection

One living build Packet with an exact current candidate seal, QA contract,
request, check and deterministic verdict may now enter the explicit `△` action:

```lua
manifest = {
  qa_terminal = {
    action = "project_current_candidate",
    qa_contract_id = "qa-contract:<sha256>",
  },
}
```

`logic/manifest.lua` derives one closed `qa.terminal_projection.v1` solely from
current body evidence. It binds the candidate seal, aligned artifact view,
contract, environment, request, check, contained-process finality, verdict,
runtime cost and all source refs. It calls neither substrate nor QA provider.

Accepted and rejected candidates have the same projection schema and tick
depth. An accepted verdict manifests with `death_cause=complete`; a rejected
verdict manifests with `death_cause=blocked`. The latter is an honest terminal
record of the rejected generation, not permission to patch it or to create a
descendant.

The action is exclusive with plan and repository delivery. M4 adds no pressure
reader, route weight or automatic transition.

## 2. Live And Historical Readers

`runtime/qa_evidence.lua` now separates two readings of one append-only source:

```text
current(instance, seal, contract)
  verifies exact schemas, Packet coordinates and the live candidate state

historical(instance, seal, contract)
  verifies exact schemas, Packet coordinates and causal joins after finality
  without pretending that a dead Packet still has live candidate readiness
```

This is not a second evidence store. Both views are derived from body events.
The historical reader exists because live artifact-set derivation is correctly
unavailable after Packet death.

## 3. Corpse Retention Outside Trace Tail

Before truncating `trace_tail`, `runtime/corpse.lua` derives one exact
`corpse.qa_evidence.v1` envelope containing the current request, check or
execution failure, verdict and terminal projection. The corpse hash covers the
envelope. Verification cross-binds it to the birth QA contract, terminal
manifest and death cause.

Consequently the bounded trace tail is diagnostic history, not the sole owner
of terminal QA truth. A grown life with more than 32 later events retains its
exact check and verdict even though the verdict event is absent from the stored
tail. Mutation of the retained projection invalidates corpse verification.

## 4. Descendant Transport Is History Only

`runtime/carrier.lua` verifies the source corpse before building recovery data.
When that corpse contains QA evidence, the carrier adds one bounded
`carrier.qa_history.v1` projection with:

```text
event_truth_status         = runtime_confirmed
applicability_truth_status = inherited_proposal
```

The first status belongs to the ancestor's recorded event. The second belongs
to its possible relevance to a descendant. The nested history exports no
provider, grant, handle, lease, command, host path or registry authority.

A clean descendant receives the history through its carrier, but its current
QA reader remains empty and its trace contains no inherited `qa_check`. M4's
transport fixture supplies an explicit assessment only to exercise this
boundary; automatic recovery from a rejected verdict remains deferred.

## 5. Runtime Evidence

Observed on 2026-08-01:

```text
lua tests/run.lua                         114 suites, all tests ok
lua tests/test_qa_terminal_retention.lua    5 green / 0 red
lua tests/test_qa_check_verdict.lua         24 green / 0 red
lua tests/red_qa_hand.lua                   84 green / 0 red / 0 skip
lua tests/smoke_mortality_battery.lua        8/8
luac -p changed Lua sources                 passed
git diff --check                            passed
```

QV19 and QV20 are now green. The QA matrix has no expected-red controls and no
skips. The ordinary runner also owns permanent controls for accepted/rejected
symmetry, retention beyond `trace_tail`, corpse tamper rejection and
history-only descendant transport.

## 6. Remaining Boundary

M4 completes the bounded manual QA body transaction:

```text
sealed candidate
-> exact private RUN
-> body check or infrastructure failure
-> deterministic current-candidate verdict
-> exact terminal projection
-> hashed corpse retention
-> bounded inherited history
```

It does not authorize automatic QA routing, multiple checks, semantic failure
diagnosis, automatic rejected-generation recovery, lineage-level
`software_accepted`, persistent lineage, CLI release acceptance or wider
repository authority. Those are later policy and integration decisions, not
implicit consequences of the now-complete M1-M4 transaction.
