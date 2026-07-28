# QA E6 Provider Witness V1 Precision Notes

date: 2026-07-28
status: E6.1 schema and ordering decision
scope: private Step-D provider witness only
authority: document_decision over E5 runtime evidence and C7 crystall

## 1. Boundary

E6 does not create `runtime.qa_execution`, a Packet QA request, an execution
receipt, a body outcome writer or a verdict. It migrates the test-owned
provider witness that already surrounds production RUN v1.

The authorized chain remains:

```text
sealed source lease
-> pre inventory
-> production process observation/error v1
-> post inventory
-> private pending join
-> terminal source disposition
-> detached witness report/error v1
```

No E6 output is valid body evidence.

## 2. Runtime Findings

The current witness has four C7 seams:

1. it emits `qa.provider_witness_report.v0` and
   `qa.provider_witness_error.v0` around v1 process measurements;
2. it constructs the final protocol object inside the source callback before
   `finish_qa_source`, even though it returns the object only afterwards;
3. its error adapter collapses `unknown` candidate/cleanup state into booleans;
4. its no-process error path fabricates a zero `qa.cost.v0` instead of
   preserving absent measurement.

The Packet ablation snapshot also omitted `instance.runtime.budget`; C7 must
cover that state explicitly. No lineage budget handle or writer is supplied to
Step D, so lineage economics remain unreachable rather than snapshotted through
a new authority surface.

## 3. Report V1

Exact detached report:

```lua
{
  protocol_version = "qa.provider_witness_report.v1",
  operation = "run_lua54_test_suite",
  transaction_id = string,
  witness_id = string,
  profile_id = "qa.profile.lua54_test_suite.v0",
  environment_id = string,
  outcome = "accepted" | "rejected",
  reason = contained_candidate_reason,
  termination = qa_termination,
  cause = qa_first_cause_v1,
  finality = qa_finality_v1,
  source = {
    pre_inventory_id = string,
    post_inventory_id = string,
    stable = true,
    disposition = "consumed",
  },
  stdout = qa_stream_measurement_v1,
  stderr = qa_stream_measurement_v1,
  resources = qa_resource_measurement_v1,
  scratch = qa_scratch_measurement_v1,
  cost = qa_cost_v1,
  event_truth_status = "runtime_confirmed",
}
```

`expected_exit` is accepted. Every other currently legal contained candidate
reason is rejected. `scratch_limit` remains impossible until a causal scratch
write-denial witness exists.

There is no separate `cleanup` field. Complete cleanup is already represented
by the closed finality record and terminal source disposition.

## 4. Error V1

Exact detached infrastructure error:

```lua
{
  protocol_version = "qa.provider_witness_error.v1",
  transaction_id = string,
  witness_id = string,
  profile_id = string,
  environment_id = string,
  class = "unavailable" | "world" | "ambiguous",
  code = closed_witness_error_code,
  stage = closed_error_stage,
  candidate_start_state = "not_started" | "started" | "unknown",
  source_stable = true | false | nil,
  source_disposition = "consumed" | "quarantined",
  cleanup_state = "complete" | "incomplete" | "unknown",
  launcher_reaped = "complete" | "incomplete" | "unknown",
  result_eof = "complete" | "incomplete" | "unknown",
  measured_cost = qa_cost_v1 | nil,
  event_truth_status = "runtime_confirmed",
}
```

No-process preflight failures are positively `not_started`; after their source
lease closes they have complete cleanup/reap/EOF and no measured process cost.
Process errors preserve every tri-state and optional measured cost. Postflight
source drift after a complete process observation preserves that observation's
cost/finality but returns only an ambiguous witness error with quarantined
source.

## 5. Assembly Law

The callback may return only an untagged private pending join. It contains no
final protocol version, digest id or external reader. Final report/error
construction occurs only after exact `finish_qa_source` succeeds.

```text
consumed + contained result -> report v1
consumed + clean pre-candidate/process error -> error v1
quarantined + ambiguity -> error v1
trusted contradiction -> quarantine/finality attempt, then loud
finish failure -> no final object, loud
```

## 6. E6 Gates

```text
clean and Lua-error witnesses use report v1
preflight and drift use error v1 with exact terminal disposition
v0 witness objects are not accepted as any current input
returned mutation changes no private state
Packet trace/field/revisions/runtime budget are byte-identical
public root remains sealed and byte-identical
no lineage budget writer is imported or supplied
red matrix remains 40 green / 44 red
QN17-QN20 remain deferred
```
