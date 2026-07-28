# QA RUN V1 Authority E5 Manifest

manifest status: implemented, production-routed fault-free slice
date: 2026-07-28
authority: exact RUN v1 request, split-phase supervisor and launcher finality join
execution protocol: production RUN v1
body QA authority: absent

## 1. Manifested Authority

Production RUN no longer crosses the historical one-frame v0 machine. Its
single executable path is:

```text
qa_provider_witness
  -> qa_provider.normalize_request_v1
  -> launcher RUN_REQUEST_V1
  -> top-level supervisor
  -> namespace controller
  -> candidate STARTED + private READY/RELEASE
  -> candidate Lua
  -> private controller report
  -> top-level RESULT_V1 or ERROR_V1
  -> launcher reap/EOF phase machine
  -> qa_provider.normalize_result_v1 / normalize_error_v1
```

The candidate is the only STARTED writer. The namespace controller is the only
cause and measurement writer. The top-level supervisor is the only terminal
frame writer. The launcher adds only facts it owns: supervisor reap and result
EOF. Lua receives no process token, fd, raw stream, allocator page or private
report.

## 2. Fault-Free Physics

Candidate bytes load only after STARTED has been published and the private
READY/RELEASE handshake has armed supervision. A successful terminal result
requires exact identity and source-stage joins, one immutable first cause,
independent stdout and stderr EOF, stable allocator telemetry, exact wait4
metrics, complete bounded scratch observation, candidate and process-tree
finality, namespace-controller reap, namespace cleanup, top-supervisor reap and
result-pipe EOF.

The launcher accepts only these public sequences:

```text
ERROR before STARTED
STARTED then RESULT
STARTED then ERROR
```

Malformed, partial, trailing, duplicate, reordered, cross-identity, v0 or
terminal-plus-abnormal-supervisor sequences are trusted invariant failures.
Missing terminal evidence becomes typed infrastructure error, never candidate
rejection.

## 3. Descriptor And Child Ownership

Standard fd slots are reserved before controller authority descriptors are
allocated, so candidate stdout/stderr replacement cannot overwrite a private
status or report channel. Candidate stdin closure is idempotent because the
security fact is the final closed state, not which actor performed the close.

Every launcher collector return owns top-supervisor reap. Every private report
collector failure owns namespace-controller kill/reap, with the caller cleanup
path as a second attempt. No successful Lua return can precede child finality
and result EOF.

## 4. Old Authority Audit

The launcher production RUN encoder emits only wire kind 5. Supervisor `run`
parses only kind 5 and emits only kinds 6 plus 7/8. The Lua native boundary
returns only v1 result/error tables. The runtime provider calls only v1 request
and result/error normalizers. A full v0-shaped request is rejected by the
native boundary before source execution.

Old wire kinds and v0 process normalizers remain as directly tested
archaeology. They have no production caller. The historical one-frame
collector remains only for environment probe, which is not RUN authority.

## 5. Runtime Evidence

```text
clean source root       expected_exit / exit 0 / all finality true
Lua-error source root   unexpected_exit / exit 70 / all finality true
full v0 request         rejected before RUN

native RUN integration                  green
launcher v1 phase-machine corpus        green
fault-free namespace execution corpus   green
native QA gate                          16 green / 0 red / 4 skip
full ordinary suite                     all tests ok
mortality battery                       8/8
QA control matrix                       40 green / 44 red / 0 skip
```

The four skipped native gates and 44 expected-red body gates remain red by
design. E5 changes no mortality, routing, loss, lineage or repository physics
outside the named execution boundary.

## 6. Non-Claims

E5 does not claim hostile-candidate completion, trusted-fault classification,
cleanup ambiguity classification, repeated residue freedom, causal scratch
exhaustion, source disposition, Packet-owned QA evidence/verdict, arbitrary
commands or software acceptance. The environment probe still uses its older
single-frame probe engine; this is not RUN v0 coexistence.

## 7. Next Authorized Slice

Historical forecast, superseded by the implemented E6 boundary: C7 migrates
the private provider witness and gives source disposition a named writer and
reader, but does not connect body-owned execution orchestration. The resulting
boundary is manifested in `qa_provider_witness_e6.v0.md`. QN17-QN20 remain E7
through E10 and may not be made green by weakening this manifest.
