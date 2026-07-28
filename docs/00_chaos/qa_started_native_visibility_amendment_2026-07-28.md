# QA STARTED Native Visibility Amendment

status: implementation-boundary correction
date: 2026-07-28
scope: Step 8.5.5E / E1
truth status: document_decision

## Finding

The hostile-execution TABLE and CRYSTALL placed the STARTED frame in two
incompatible domains:

```text
STARTED carries a private candidate-process token;
the token must never cross the native adapter into Lua;
qa_process.normalize_started_v1(raw, request) was nevertheless specified.
```

Passing the raw STARTED record to Lua would violate the stronger authority
boundary. Removing the token from that record would create a second, weaker
STARTED schema and make the Lua layer appear to validate a join that only the
native launcher can actually prove.

## Decision

STARTED is a C-private wire phase, not a Lua/provider record.

```text
supervisor emits STARTED with private process token
-> native launcher validates nonce, identity, phase, source and token join
-> native launcher validates the matching terminal frame
-> native launcher returns one sanitized terminal v1 table to Lua
-> qa_process normalizes that terminal table only
```

The sanitized result may state that start attestation was validated. It may
not contain the process token, pid, pidfd, descriptor, mount identity, raw
frame or frame digest. Infrastructure errors carry only the closed tri-state
start fact derived by the launcher phase machine.

## API Correction

The E1 Lua surface is therefore:

```lua
qa_process.normalize_request_v1(value)
qa_process.normalize_result_v1(raw, request)
qa_process.normalize_error_v1(raw, request)
```

There is no `normalize_started_v1` Lua API. Matching STARTED to terminal is a
native launcher invariant and is tested in the native codec/phase-machine
campaign.

## Falsifiers

```text
candidate_process_token appears in any Lua table
raw STARTED frame crosses the native module ABI
Lua can manufacture or weaken the STARTED/terminal join
terminal result normalizes without native start_attested=true
error claims started/not_started inconsistently with the native phase state
```

Any falsifier stops E1 and returns the design to TABLE.

## Second E1 Finding: Launcher Facts Cannot Be Supervisor Wire Facts

The first wire layout pass exposed a second ownership mismatch. The conceptual
`qa.native_run_error.v1` record contains `launcher_reaped` and `result_eof`,
but an ERROR frame is emitted before the launcher can observe either fact.
The supervisor therefore has no right to write those fields.

Decision:

```text
supervisor ERROR wire payload owns start/namespace-cleanup/cost/source facts;
launcher owns supervisor reap and result-pipe EOF;
the sanitized Lua error is assembled only after both ownership domains join.
```

The native ERROR frame reserves no alias for launcher facts. A test that places
reap/EOF truth into supervisor-owned bytes must fail codec validation.

## Third E2 Finding: Future Features Cannot Rotate Present Identity

The original C3 feature list names mechanisms implemented only by E3-E5. E2
cannot publish those names as exercised runtime facts before their writers
exist.

Decision:

```text
E2 rotates environment protocol/id for the already measured fixed heap law,
wire/build changes and exact current probe evidence;
E3-E5 rotate build/policy/feature identity again as each physical feature
becomes exercised;
no future feature bit is predeclared runtime_confirmed.
```

Environment identity is intentionally allowed to rotate more than once during
the campaign. Historical ids remain unavailable for new contracts each time.
