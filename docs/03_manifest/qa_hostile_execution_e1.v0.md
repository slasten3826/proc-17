# QA Hostile Execution E1 Manifest

manifest status: implemented, unpromoted foundation slice
date: 2026-07-28
authority: native/Lua private schema only
execution delta: none
body QA authority: absent

## 1. Implemented Surface

`E1` adds the closed vocabulary required by the future hostile QA supervisor:

```text
native RUN v1 kinds 5-8
RUN request/STARTED/result/error fixed payload layouts
bounded v1 codec validation
qa.environment.v1 schema with fixed 64 MiB runtime heap policy
strict Lua request/result/error v1 normalizers
v0/v1 non-coercion tests
```

The current production provider, launcher and supervisor still emit and accept
the historical RUN v0 path. No production execution authority moved.

## 2. Implementation Corrections

Two writer/reader defects were found before production integration:

1. STARTED carries a private process token and therefore remains entirely in
   the C launcher phase machine. Lua receives no raw STARTED record or token.
2. Supervisor ERROR wire frames cannot attest to later launcher reap/EOF
   observations. The launcher adds those facts only after observing them.

Both corrections are recorded in
`docs/00_chaos/qa_started_native_visibility_amendment_2026-07-28.md` and were
applied back to TABLE and CRYSTALL.

## 3. Runtime Evidence

```text
lua tests/run.lua                         all tests ok
lua tests/smoke_mortality_battery.lua    8/8
lua tests/test_qa_native_supervisor.lua  16 green / 0 red / 4 skip
lua tests/test_qa_provider_witness.lua   3 green / 0 red
lua tests/red_qa_hand.lua                expected exit 1
QA control matrix                        40 green / 44 red / 0 skip
make -C native qa-wire-test              green
make -C native qa-static-closure-test    green
luac -p changed Lua files                green
git diff --check                         green
```

The exact QA color delta is zero, as required before E7.

## 4. Non-Claims

`E1` does not claim:

```text
production RUN v1 execution
STARTED emission or phase-machine finality
dual-stream/resource/scratch observation
hostile candidate containment
trusted fault classification
cleanup residue freedom
body-owned QA evidence or verdict
software acceptance
```

## 5. Next Authorized Slice

`E2` rotates the measured environment/build identity and migrates QN01-QN16
without changing their colors. Old environment ids become historical and
unavailable; there is no v0 fallback.
