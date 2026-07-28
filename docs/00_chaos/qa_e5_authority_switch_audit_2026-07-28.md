# QA E5 Authority Switch Audit

date: 2026-07-28
status: implemented and verified; E5 complete
scope: fault-free RUN v1 authority switch
authority: document_decision over runtime-confirmed code inspection
depends_on:
- `docs/02_crystall/blueprints/qa_hostile_execution_campaign.v0.md`
- `docs/03_manifest/qa_supervisor_phase_e3.v0.md`
- `docs/03_manifest/qa_measurement_e4.v0.md`

## 1. What owns production before E5

Production RUN authority is still the historical v0 chain:

```text
runtime/qa_provider.lua
  -> qa_process.normalize_request(v0)
  -> proc17_qa_launcher.run_lua54_test_suite
  -> RUN_REQUEST kind 3
  -> supervisor run_execution_protocol
  -> run_namespace_probe
  -> one RUN_RESULT kind 4
  -> launcher collect_probe_result(one opaque frame)
  -> qa_process.normalize_result(v0)
```

This path combines stdout and stderr, owns a second historical watchdog,
returns only exit-shaped outcomes and does not route E3/E4 phase, stream,
allocator, controller, scratch or report physics.

## 2. What already exists but has no production authority

The production supervisor binary links the following tested organs:

```text
proc17_qa_phase       STARTED ownership, release gate, first cause, finality
proc17_qa_status      READY / RELEASE / HEAP_DENIED private conversation
proc17_qa_stream      independent bounded stdout and stderr witnesses
proc17_qa_allocator   shared reservation telemetry surviving abrupt death
proc17_qa_controller  wall/CPU clocks, wait4 metrics, epoch arbitration
proc17_qa_scratch     bounded post-reap scratch observation
proc17_qa_report      private controller report and public RESULT finalization
```

They are linked and unit-tested, but `run_execution_protocol()` does not call
them as one life. Therefore E4 is real mechanism without routed authority, as
its manifest claims.

## 3. Exact E5 replacement chain

```text
launcher
  -> exact RUN_REQUEST_V1 kind 5
  -> top-level supervisor
      -> namespace controller
          -> candidate prelude emits public STARTED kind 6 and closes its fd
          -> private READY; controller arms timer; private RELEASE
          -> candidate Lua runs with shared allocator telemetry
          -> controller joins streams/status/wait4/scratch into private report
      -> top-level reaps controller and establishes namespace cleanup
      -> exact RESULT kind 7, or typed ERROR kind 8
  -> launcher validates frame sequence plus supervisor reap and result EOF
  -> one detached Lua v1 result or error table
  -> qa_process.normalize_result_v1 / normalize_error_v1
```

The candidate writes STARTED. The namespace controller writes only the private
report. The top-level supervisor writes only the terminal public frame. The
launcher contributes only its own supervisor-reap and result-EOF facts.

## 4. Authority-switch law

RUN v0 and RUN v1 may coexist only as codec-testable history. They may not both
be accepted or emitted by the production RUN route.

The switch is complete only when all of the following are true:

1. the launcher emits only kind 5 for a production RUN;
2. the supervisor production RUN parser rejects kind 3;
3. the supervisor emits STARTED followed by exactly one kind 7 or 8;
4. the launcher state machine rejects kind 4 and every illegal v1 sequence;
5. the native Lua boundary returns only v1 tables;
6. the provider accepts only `qa.native_run_request.v1` and normalizes only v1;
7. a source/symbol audit shows that old RUN helpers are unreachable from the
   production RUN entrypoint.

Removing old code is not itself the proof. Removing its authority is.

## 5. Fault-free E5 boundary

E5 proves two ordinary candidate lives through the real production route:

```text
clean test suite -> expected_exit -> RESULT v1
Lua load/runtime failure -> unexpected_exit -> RESULT v1
```

Both must include STARTED, exact identity/token joins, all eight finality facts,
independent stream EOFs, stable allocator telemetry, exact candidate wait4
metrics, complete scratch observation, controller reap, namespace cleanup,
supervisor reap and result EOF.

Hostile cause campaigns remain E7-E10. E5 must not fake those outcomes in
order to claim the fault-free switch.

## 6. Implementation boundary

The current `run_namespace_probe()` remains the environment-probe engine until
the probe contract is deliberately migrated. E5 replaces only production RUN.
Probe reuse is not RUN v0 coexistence because it neither accepts a RUN request
nor emits a RUN result.

The E5 sequence is:

```text
E5.1 assemble a directly tested fault-free namespace controller
E5.2 route STARTED and terminal publication through the top-level supervisor
E5.3 replace the launcher one-frame collector with the v1 phase machine
E5.4 rotate provider/runtime production authority to v1
E5.5 grow clean and Lua-error end-to-end lives
E5.6 run batteries and record the switch manifest
```

## 7. Stop conditions

Do not switch authority if any of these remains true:

```text
candidate bytes can run before STARTED close plus RELEASE
controller can publish a public terminal result
top-level can invent candidate cause or measurement
launcher can return before supervisor reap plus result EOF
infrastructure ambiguity can become a candidate RESULT
v0 production request/result remains accepted as fallback
```

No fallback is safer than a quiet fallback to the old king.

## 8. Error ownership precision

The top-level supervisor may emit a typed ERROR only when its own evidence
fixes candidate start state:

```text
failure before namespace/candidate birth -> not_started ERROR
complete private report plus top-level failure -> started ERROR
controller failure without a private report -> no guessed terminal frame
```

In the third case the launcher owns the missing-frame derivation because it is
the actor that actually observed zero or one public STARTED frames plus
supervisor reap and result EOF. A new controller error ledger would duplicate
that observation and is not introduced for E5. Unknown remains unknown.

## 9. E5.3 launcher phase machine implementation

Implementation status 2026-07-28: complete, production-unrouted.

`native/proc17_qa_launcher_v1.c` now owns a transaction-local stream machine:

```text
arbitrary read fragmentation
  -> exact frame boundary from the closed envelope
  -> strict RUN v1 decode
  -> identity + source-stage join
  -> zero/one STARTED + zero/one terminal
  -> supervisor reap + result EOF
  -> terminal frame or launcher-derived infrastructure error
```

The machine rejects duplicate, out-of-order, v0, malformed, partial and
trailing frames as trusted invariants. A complete terminal frame accompanied
by a non-clean supervisor exit is also contradictory and loud. When reap and
EOF are complete but no terminal exists, the launcher derives either
`supervisor_crashed` or `terminal_frame_missing` from its own observations; it
does not invent namespace cleanup.

The STARTED process token and source-stage join live only in private C state,
are explicitly erased when collection ends and are absent from the terminal
structure. Synthetic sequence tests and a real namespace-supervisor life use
the same collector. The module is linked into the launcher binary but no Lua
or provider production route calls it before E5.4.

## 10. E5.4 production authority switch

Implementation status 2026-07-28: complete.

The only production RUN chain is now:

```text
qa_provider_witness -> qa.native_run_request.v1
qa_provider -> normalize_request_v1
native launcher -> RUN_REQUEST_V1 kind 5
supervisor "run" -> run_execution_protocol_v1
namespace controller -> STARTED kind 6 + private report
top-level supervisor -> RESULT kind 7 or ERROR kind 8
launcher v1 collector -> reap + EOF join
qa_provider -> normalize_result_v1 / normalize_error_v1
```

The native boundary rejects a complete request carrying
`qa.native_run_request.v0`. The supervisor `run` mode has no v0 branch. The old
wire kinds and `qa_process` v0 normalizers remain only as codec-testable
history; no production provider, launcher consumer or supervisor entrypoint
calls them. The one-frame collector remains named and reachable only from the
environment probe, which is outside RUN authority.

## 11. E5.5 grown production lives

Two real source roots cross the full chain without a fake adapter:

```text
clean_silent         -> STARTED -> expected_exit   -> RESULT v1, exit 0
runtime_error_silent -> STARTED -> unexpected_exit -> RESULT v1, exit 70
```

Both results carry the exact request identity, one first cause, independent
stdout/stderr measurements, wait4/resource measurements, complete scratch
inventory and all eight finality facts. The private candidate process token is
absent at the Lua boundary. The same outcomes also pass through sealed-root
inventory, provider witness normalization and source revalidation in
`test_qa_provider_witness.lua`.

The production integration exposed two descriptor-history defects that direct
controller tests could not see:

1. candidate stdin closure required `close(0)` to perform a transition even
   when the launcher had already closed it; the law is now idempotent final
   state, not actor credit;
2. closed standard descriptors allowed a private status socket to receive fd
   2 and then be overwritten by candidate stderr `dup2`; the controller now
   reserves 0/1/2 before allocating any authority descriptor.

The private report collector was also tightened so every failure branch owns
controller termination/reap. This strengthens ownership but does not claim the
future trusted-fault corpus.

## 12. E5.6 absence and battery audit

Source inspection confirms:

```text
production launcher RUN encoder        kind 5 only
production supervisor RUN parser       kind 5 only
production terminal parser             kinds 7/8 only
runtime provider normalizers            v1 only
v0 wire kinds                           generic codec history only
v0 qa_process normalizers               direct codec tests only
one-frame launcher collector             probe path only
```

Runtime evidence:

```text
make -C native qa-run-basic-internal-test   green
make -C native qa-launcher-v1-test          green
make -C native qa-execution-test            green
lua tests/test_qa_native_supervisor.lua     16 green / 0 red / 4 skip
lua tests/test_qa_provider_witness.lua      3 green / 0 red
lua tests/run.lua                           all tests ok
lua tests/smoke_mortality_battery.lua       8/8
lua tests/red_qa_hand.lua                   expected exit 1
QA control matrix                          40 green / 44 red / 0 skip
git diff --check                           clean
```

The QA color delta outside the authorized E5 gates is zero.

## 13. Residual boundary

E5 proves a fault-free production execution organ. It does not prove QN17
hostile candidate causes, QN18 trusted-fault injection, QN19 ambiguity/source
disposition or QN20 repeated residue freedom. It also does not create
Packet-owned QA evidence, verdict, execution orchestration or software
acceptance. Those missing readers remain visible in the expected-red corpus.

The next authorized slice is E6/C7: migrate the provider witness into the body
execution transaction and give sealed-source disposition a named owner without
letting infrastructure failure become a candidate verdict.
