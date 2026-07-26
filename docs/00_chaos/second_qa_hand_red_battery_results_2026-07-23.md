# Second QA Hand Red Battery Results

Status:

```text
layer: CHAOS / runtime-observed test pressure
date: 2026-07-23
roadmap: 8.5.4 of 8.5.7
status: complete as an expected-red perimeter
production QA hand: absent
candidate process dispatch: forbidden and absent
router authority: unchanged
```

Sources:

```text
docs/00_chaos/second_qa_hand_threat_model_2026-07-23.md
docs/00_chaos/qa_table_cross_audit_2026-07-23.md
docs/00_chaos/qa_crystall_cross_audit_2026-07-23.md
docs/02_crystall/blueprints/qa_contract_profile.v0.md
docs/02_crystall/blueprints/qa_execution_capability.v0.md
docs/02_crystall/blueprints/qa_native_supervisor.v0.md
docs/02_crystall/blueprints/qa_check_verdict.v0.md
```

## 0. Result

Step 8.5.4 did not implement the QA hand. It made the missing hand executable
as a set of failing obligations.

The split is now:

```text
ordinary proc-17 runtime
  no QA schema modules
  no QA private registry
  no sealed-source QA lease
  no QA launcher or supervisor
  no QA body events or verdict
  no candidate process dispatch

test harness
  may read a fixed bounded hostile corpus as inert bytes
  may compile fixed native contract probes
  may grow sealed candidates through the existing fake repository provider
  may not execute a hostile candidate fixture
```

The expected-red runner is:

```text
lua tests/red_qa_hand.lua
```

It is deliberately absent from `tests/run.lua`.

## 1. Inert Hostile Corpus

The corpus lives at:

```text
native/tests/qa_fixtures/*.fixture
```

There are 26 fixed fixtures:

```text
17 candidate fixtures
  clean/nonzero/error
  CPU/wall/memory/output/scratch bounds
  source mutation and host/sibling observation
  socket/fork/exec/native-module/fd/policy escape

9 trusted-fault fixtures
  wrong launcher/supervisor identity
  malformed request/result frames
  supervisor crash before/after candidate start
  lost result pipe
  wait/reap ambiguity
  postflight source drift
```

Every file:

```text
uses the non-executable .fixture extension
starts with one exact inert-data marker
contains its manifest identity
is bounded to at most 16384 bytes
has bytes distinct from every other fixture
is opened only through a fixed manifest path
```

`tests/support/qa_hostile_fixtures.lua` exposes only bounded `io.open`/read.
It contains no `load`, `loadfile`, `dofile`, shell, process or native-loader
primitive. The scripts inside the fixture bytes are not Lua modules and are
not entered through `package.path`.

The ordinary runner executes only `tests/test_qa_fixture_guard.lua`. The guard
reads the bytes to prove their inert contract; it never evaluates them.

## 2. Closed Control Catalog

`tests/support/qa_control_catalog.lua` records every permanent control from the
four QA crystall documents:

| Surface | Controls |
|---|---:|
| contract/profile/environment | QC01-QC15: 15 |
| private execution transaction | QE01-QE20: 20 |
| body check/verdict/readers | QV01-QV24: 24 |
| native containment/build | QN01-QN20: 20 |
| inert fixture guard | QF01-QF05: 5 |
| total | 84 |

Every catalog id has a named callback. A missing callback is a load-time test
failure, not a skip.

## 3. Red Test Surfaces

New suites:

```text
tests/test_qa_contract.lua
tests/test_qa_execution.lua
tests/test_qa_native_supervisor.lua
tests/test_qa_check_verdict.lua
tests/test_qa_fixture_guard.lua
```

The tests distinguish three states:

```text
green safety fact
  the fixture is inert, the ordinary runner is isolated or an old subject
  ceiling already holds

red missing implementation
  the exact schema/module/private API/native boundary does not exist

red missing grown witness
  an API name alone cannot satisfy the control; the test remains explicitly
  red until 8.5.5 grows the exact replay/split-brain/hostile transaction
```

In particular, QE08-QE20 and the body/verdict transaction family do not become
green when a module-shaped stub appears. They require the exact public/private
surface and then retain an explicit red grown-witness gate. Native controls use
named future Make targets, so source strings alone cannot satisfy containment.

This is intentional test pressure, not a claim that the future behavioral
fixtures are already implemented.

## 4. Native Preimplementation Probes

Safe compile-only host ABI probe:

```text
native/tests/test_proc17_qa_host_contract.c
make -C native qa-host-contract-syntax
```

Observed:

```text
GREEN
```

It proves only that the current compiler headers expose the required Linux ABI
names and structures. It does not prove that namespaces, mount policy, seccomp,
static closure or cleanup work at runtime.

Expected-red wire probe:

```text
native/tests/test_proc17_qa_wire.c
make -C native qa-wire-contract-syntax
```

Observed:

```text
RED: no rule can produce native/proc17_qa_wire.h
process exit: 2
```

The test already fixes the documented frame constants:

```text
magic bytes       8
protocol version  0
nonce bytes       32
digest bytes      32
envelope bytes    80
maximum frame     4096
resource fields   10
```

It does not assign undocumented numeric message-kind values and therefore does
not invent policy beyond the crystall.

## 5. Observed Red Baseline

Command:

```text
lua tests/red_qa_hand.lua
```

Observed suite result:

```text
qa-hand red baseline: green=1 red=4 total=5
process exit: 1
```

Observed controls after QF05 was added:

| Suite | Green | Red | Skip |
|---|---:|---:|---:|
| qa-fixture-guard | 5 | 0 | 0 |
| qa-contract | 1 | 14 | 0 |
| qa-execution | 0 | 20 | 0 |
| qa-native-supervisor | 1 | 19 | 0 |
| qa-check-verdict | 0 | 24 | 0 |
| total | 7 | 77 | 0 |

The two non-guard greens are truthful existing facts:

```text
QC01 plan Packet carries no executable QA contract
QN01 the hostile corpus is present, closed and inert
```

The nonzero process exit is expected. No red is converted into a skip.

## 6. What The Red Means

The dominant red causes are concrete:

```text
core/qa_schema.lua absent
runtime/qa_environment.lua absent
runtime/qa_contract.lua absent
runtime/qa_request.lua absent
runtime/qa_capability.lua absent
runtime/qa_execution.lua absent
runtime/qa_evidence.lua absent
runtime/qa_verdict.lua absent
runtime/qa_provider.lua absent
repository sealed-source lease API absent
Packet dedicated QA event gate absent
shared native repository-handle ABI absent
wire/launcher/supervisor/policy implementation absent
static closure/environment/hostile Make targets absent
```

This is the intended state before 8.5.5. A red control may become green only
when its named boundary exists and its assertion reaches that boundary.

## 7. Harness Authority Audit

The new test harness authority is fixed and bounded:

```text
read known repository files
read the 26 manifest-owned .fixture files as bytes
grow fake-provider repository candidates entirely in memory
invoke constant make targets for compiler/build probes
```

No prompt, substrate output, repository content or fixture byte is interpolated
into a command. `tests/test_qa_native_supervisor.lua` can invoke only constant
native Make targets. The expected-red runner never passes fixture bytes to Lua,
a shell, a process or the existing first hand.

The dangerous fixtures may first execute in 8.5.5C/D, after the exact static
supervisor and environment probe exist, and only through that isolated provider.

## 8. Ordinary Regression

Command:

```text
lua tests/run.lua
```

Observed:

```text
101 suites
all tests ok
process exit: 0
```

Mortality:

```text
lua tests/smoke_mortality_battery.lua
8/8 ok
```

Also green:

```text
Lua syntax for every new test/support module
native host-contract syntax probe
git diff --check
```

No Packet route, budget, loss, mortality, repository authority or candidate
seal behavior changed. The only ordinary-suite addition is the massless inert
fixture guard.

## 9. No Second Contact Yet

Step 8.5.4 has not run untrusted code.

Specifically absent:

```text
fork/execveat QA launcher
static supervisor
new namespace or mount
fresh candidate Lua state
seccomp policy
sealed-source QA lease
QA process budget charge
QA check/failure/verdict body event
```

Therefore the green host ABI compile probe must not be cited as containment
evidence. It only proves that implementation can now fail against named host
contracts instead of discovering missing declarations after authority exists.

## 10. Next Gate

Step 8.5.5 remains ordered as crystallized:

```text
8.5.5A core schemas and private registries
8.5.5B shared repository userdata ABI with first-hand regressions
8.5.5C static supervisor and exact environment probe
8.5.5D one isolated clean/rejected process transaction
8.5.5E resource/policy/fault/leak controls
```

The first implementation slice may target only 8.5.5A. Candidate fixture
execution remains forbidden until the earlier native gates are green.

## 11. Chapter Position

```text
8.5.1 Chaos threat model                                    complete
8.5.2 TABLE contracts and cross-audit                       complete
8.5.3 CRYSTALL schemas/authority/native ABI                 complete
8.5.4 hostile red battery                                   complete
8.5.5 minimal isolated Linux QA hand                        next
8.5.6 completion/work-layer/manifest readers                blocked by hand
8.5.7 grown accepted/rejected/infrastructure lives           blocked by readers
```
