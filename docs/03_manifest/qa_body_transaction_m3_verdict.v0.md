# QA Body Transaction M3 Verdict Manifest v0

Status:

```text
layer: manifest
date: 2026-07-30
slice: M3 deterministic current-candidate verdict and shadow readers
manual actor-valid verdict tick: implemented
automatic QA routing: not authorized
terminal QA projection: not implemented
lineage software acceptance: forbidden to Packet and corpse
QA control matrix: 82 green / 2 red / 0 skip
```

## 1. Manifested Verdict

One living build Packet with an exact current seal, aligned artifact view,
verified QA birth contract and one complete current `qa.check.v0` can now enter:

```lua
runtime = {
  qa_verdict = {
    action = "assemble_current_candidate_verdict",
    qa_contract_id = "qa-contract:<sha256>",
  },
}
```

`runtime/qa_verdict.lua` derives one exact
`qa.candidate_verdict.v0` without calling a provider, substrate or semantic
classifier. An accepted check produces an accepted verdict; a rejected check
produces a rejected verdict. Both paths have the same event shape and tick
depth. Missing check evidence is not-ready, while
`qa.execution_failure.v0` remains infrastructure and cannot become a candidate
verdict.

The verdict binds:

```text
Packet / lineage / generation / process / context / stage / repository
current candidate seal event and aligned artifact view
current QA contract / profile / environment
one exact request event and one exact check event
the check runtime cost as detached evidence
```

Every field participates in `qa-verdict:<sha256>` except the digest field
itself.

## 2. Sole Writer And Actor

`runtime.body.record_qa_candidate_verdict` is the sole body writer. It appends
through the dedicated Packet QA gate, under actor `☱`, with
`truth_status=runtime_confirmed` and zero event cost. Generic trace append,
actor-invalid direct commit, stale prepared values and contradictory current
evidence are rejected.

Preparation is pure. Commit re-derives all sources in the same actor tick and
is idempotent only for the exact same verdict. Detached return mutation cannot
change stored evidence.

## 3. Ordinary Runtime Tick

`tension_runner.execute_qa_verdict_tick` is the narrow manual/grown corpus
entrance. Within one committed `☱` tick:

```text
derive and append verdict
-> run ordinary runtime reconciliation
-> record lower observation and tension
-> charge one body step
-> capture one ordinary runtime frame
-> apply existing mortality
```

The verdict is visible to the camera in the same tick. It does not replace or
duplicate reconciliation. It charges no tool call, QA execution, test run or
identity loss, and it never reruns the candidate. One actor tick cannot be
settled twice.

No default readiness, pressure contribution, route weight or automatic
transition was added.

## 4. Named Shadow Readers

`runtime/completion_scope.lua` and `runtime/work_layer.lua` are the named
readers of current verdict evidence:

```text
seal only                    -> sealed / checking
check without verdict       -> qa_check_observed / ◈ crystallizing
execution failure           -> qa_infrastructure_incomplete / ⊞ checking
accepted current verdict    -> qa_accepted / ▲ candidate acceptance boundary
rejected current verdict    -> qa_rejected / ▲ generation recovery boundary
```

These readers are pure projections. They write no Packet event and move no
route. `▲` means the Packet-local terminal boundary is ready; it does not mean
`software_accepted`. Only a future verified lineage ledger view may make that
claim.

## 5. Runtime Evidence

Observed on 2026-07-30:

```text
lua tests/run.lua                         113 suites, all tests ok
lua tests/smoke_mortality_battery.lua      8/8
lua tests/test_qa_verdict_tick.lua          7 green / 0 red
lua tests/test_qa_check_verdict.lua        22 green / 2 expected red
lua tests/red_qa_hand.lua                  82 green / 2 red / 0 skip
luac -p changed Lua sources                passed
git diff --check                           passed
```

`tests/test_qa_check_verdict.lua` and the aggregate red battery still exit
nonzero by design while the two M4 controls remain red. The exact remaining
controls are:

```text
QV19 terminal QA evidence survives beyond the 32-event trace tail
QV20 descendant receives ancestor QA only as historical inherited evidence
```

All thirteen M3-owned controls changed to green. The total matrix moved from
M2.5 `69/15` to M3 `82/2`; no control was skipped.

## 6. Remaining Boundary

The next bounded slice is M4:

```text
△ writes one exact qa.terminal_projection.v1
corpse freezes a bounded QA envelope outside trace_tail
carrier transports that envelope as inherited history only
descendant current QA readers remain empty
QV19 and QV20 become green
```

M3 does not authorize automatic QA routing, automatic rejected-generation
recovery, semantic diagnosis, multiple QA checks, persistent lineage, CLI
software acceptance or release promotion.
