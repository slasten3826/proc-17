# QA Body Transaction M2.5 Runner Tick Manifest v0

Status:

```text
layer: manifest
date: 2026-07-29
slice: M2.5 runner-owned QA action and economics
manual actor-valid QA tick: implemented
automatic QA routing: not authorized
QA control matrix: 69 green / 15 red / 0 skip
```

## 1. Manifested Tick

One already grown, sealed and aligned build Packet may now enter the exact
manual corpus action:

```lua
logic = {
  qa_execution = {
    action = "execute_current_candidate",
  },
}
```

`organs/logic.lua` accepts this action only at a living `☶` tick. It is
exclusive with repository effects, qualified actions and spells. Readiness
uses the pure `qa_execution.inspect`; execution reuses the M2.4 private
request, grant, source, receipt and strict body join.

The successful organ payload is:

```lua
{
  kind = "qa_execution_payload",
  mode = "qa_execution",
  outcome_kind = "check",
  request_id = string,
  evidence_id = qa_check_id,
  effect_cost = {tool_calls, test_runs, time_ms},
  truth_status = "runtime_confirmed",
}
```

This slice adds no pressure reader, route weight or automatic `☱ -> ☶`
transition. `tension_runner.execute_qa_tick` is the narrow manual/grown
entrance; it cannot execute another LOGIC action or settle one actor tick
twice.

## 2. Sole Economic Writer

The check or execution-failure event retains measured `qa.cost.v1` as
evidence. It does not debit the Packet. The runner owns both charges:

```text
ordinary accepted/rejected QA tick
  -> body_tick: steps=1
  -> qa_execution: tool_calls/test_runs/time_ms once

typed infrastructure failure
  -> body_tick: steps=1
  -> failed_external_effect: admitted incurred cost once
  -> death_cause=effect_failure
```

Successful external cost is keyed by the exact `qa_check_id`. Therefore:

```text
direct M2.4 evidence before runner settlement -> first runner tick charges it
later runner replay of the same evidence      -> no second external charge
second settlement attempt in the same tick    -> explicit refusal, no charge
```

The stored cost remains present on replay; the budget ledger, not a caller or
the private receipt registry, decides whether it has already been paid. A prior
entry counts only when both `evidence_id` and normalized cost match; a mismatch
is loud. This keeps the runner as the only economic authority.

QA execution and replay create no identity loss. A trusted malformed result is
loud and economically inert: it writes no check/failure, charges no body tick
and invents no Packet death.

## 3. Failure Boundary

`runtime/qa_evidence.lua` now emits the existing exact substrate
`effect_failure` contract for infrastructure failure. The ordinary
`tension_runner` failure path can therefore append `operator_failure`, charge
the admitted cost, capture the runtime frame and kill the Packet without a new
death type.

Contained nonzero exit, wall timeout, output limit and memory limit remain
candidate rejection and return a normal QA execution payload. Source drift,
supervisor unavailability and cleanup ambiguity remain infrastructure.

## 4. Repeated Native Campaign

`tests/run_qa_body_repeated_residue_campaign.lua` grows 32 fresh Packet lives
through the production repository provider, native QA supervisor, private body
receipt, strict body join and runner settlement. The four-case cycle is:

```text
clean exit
Lua error
output limit
allocator exhaustion
```

Every life checks exact outcome/reason, one body step, one tool call, one test
run and a process-free replay. The existing native residue observer compares
each iteration, post-cleanup state and the final state against one baseline.

Observed result:

```text
declared=32
executed=32
matched=32
fd=0 process=0 namespace=0 mount=0 root=0 source=0
memory_finality=0 lua=0 sentinel=0 body=0
```

## 5. Permanent Controls

`tests/test_qa_runner_tick.lua` fixes seven fast controls:

```text
success pays one body tick and one external projection
QA action is exclusive with every other LOGIC action
one actor tick cannot be settled twice
direct evidence is paid by its first runner settlement
later replay pays no second external projection
typed infrastructure failure pays once and dies effect_failure
trusted contradiction stays loud and economically inert
```

The expected-red matrix moved only at its owning controls:

```text
before M2.5: 67 green / 17 red / 0 skip
after M2.5:  69 green / 15 red / 0 skip
new greens: QE15, QE20
```

## 6. Remaining Boundary

```text
M3 deterministic qa_candidate_verdict and shadow completion/work-layer readers
M4 terminal QA projection, corpse retention and descendant historical transport
deferred automatic routing and release promotion
```

M2.5 does not claim that a passing check accepts software, that a rejected
check has a terminal recovery carrier, or that QA should yet run automatically.
