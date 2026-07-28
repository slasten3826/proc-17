# QA Environment Rotation E2 Manifest

manifest status: implemented, unpromoted identity slice
date: 2026-07-28
authority: measured environment identity
execution protocol: production RUN v0
body QA authority: absent

## 1. Implemented Surface

`E2` makes `qa.environment.v1` the only active environment schema:

```text
native probe protocol                      qa.native_probe.v1
active environment protocol                qa.environment.v1
fixed measured runtime heap ceiling        67108864 bytes
historical environment parser              qa.environment.v0, archaeology only
historical environment registry admission  denied
```

The native supervisor uses the same policy constant for the bounded Lua
allocator and the measured probe field. The provider verifies that field before
constructing the environment identity.

## 2. Identity Rotation

Changing the policy/header and measured probe rebuilt:

```text
supervisor binary and build digest
launcher binary and expected supervisor digest
provider module digest
runtime dependency/policy identity
environment identity
```

No historical environment id is silently upgraded. A v0 record may be parsed
for archaeology through `normalize_environment_v0`, but the active registry
accepts only v1.

Future E3-E5 feature names were deliberately not inserted into the current
feature digest. Each feature rotates identity only after its physical witness
exists and is exercised.

## 3. Runtime Evidence

```text
lua tests/run.lua                         all tests ok
lua tests/smoke_mortality_battery.lua    8/8
lua tests/test_qa_native_supervisor.lua  16 green / 0 red / 4 skip
lua tests/test_qa_provider_witness.lua   3 green / 0 red
lua tests/red_qa_hand.lua                expected exit 1
QA control matrix                        40 green / 44 red / 0 skip
native launcher ABI/probe tests          green
strict compiler warnings                 green
```

The exact QA color delta remains zero.

## 4. Non-Claims

`E2` does not claim STARTED emission, RUN v1 production execution, dual-stream
observation, finality, hostile-candidate coverage, cleanup residue freedom or
body-owned QA verdicts.

## 5. Next Authorized Slice

`E3` implements the pre-chunk STARTED attestation, first-cause ledger and
terminal finality state. It is the first concurrent process-physics slice and
must begin from this committed checkpoint.
