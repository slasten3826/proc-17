# QA CRYSTALL Cross-Audit

Status:

```text
layer: chaos / crystall evidence
date: 2026-07-23
chapter: 8.5 second QA hand
step: 8.5.3
audit kind: internal preimplementation cross-audit
runtime code changed: no
candidate execution authority: no
next authority granted: step 8.5.4 hostile red battery only
```

## 0. Audited Surface

TABLE authority:

```text
docs/01_table/yellowprints/qa_contract_profile_yellowprint.v0.md
docs/01_table/yellowprints/qa_execution_capability_yellowprint.v0.md
docs/01_table/yellowprints/qa_check_verdict_yellowprint.v0.md
docs/00_chaos/qa_table_cross_audit_2026-07-23.md
```

New CRYSTALL contracts:

```text
docs/02_crystall/blueprints/qa_contract_profile.v0.md
docs/02_crystall/blueprints/qa_execution_capability.v0.md
docs/02_crystall/blueprints/qa_native_supervisor.v0.md
docs/02_crystall/blueprints/qa_check_verdict.v0.md
```

Amended existing authority/readers:

```text
docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
docs/02_crystall/blueprints/candidate_seal_transaction.v0.md
docs/02_crystall/blueprints/completion_scope.v0.md
docs/02_crystall/blueprints/work_layer_projection.v0.md
docs/02_crystall/blueprints/stage_transition_generation_recovery.v0.md
```

Runtime/native surfaces inspected for implementability:

```text
core/packet.lua
runtime/body.lua
runtime/budget.lua
substrates/contract.lua
runtime/repository_capability.lua
runtime/repository_provider.lua
runtime/candidate_seal.lua
runtime/completion_scope.lua
runtime/work_layer.lua
organs/logic.lua
organs/runtime.lua
runtime/operator_registry.lua
runtime/tension_runner.lua
native/proc17_repository_fs.c
native/Makefile
```

This audit validates a design-to-code boundary. It is not evidence that Linux
containment works: no candidate process was authorized or launched.

## 1. Result

```text
TABLE decisions preserved: yes
exact public schemas: closed
private/public authority split: closed
generic command surface: absent
repository root truth duplicated: no
native memory-erasure boundary: named
native wire and build closure: named
candidate/infrastructure/invariant classes: separate
accepted/rejected phase symmetry: exact
named writer/reader for every new record: present
trace-tail-only QA retention: forbidden
runtime implementation authority: still no
hostile red-battery authority: yes
```

Step 8.5.3 is complete as a documentary crystall. Step 8.5.4 may now create
tests and inert hostile fixtures that initially fail because the hand does not
exist. Production dispatch remains forbidden.

## 2. Critical Decisions Closed At CRYSTALL

### C1. Candidate memory does not inherit proc-17

Selected:

```text
fork -> execveat exact static supervisor -> namespace init -> candidate
```

Rejected:

```text
fork proc-17 and run candidate Lua in the copied address space
```

This closes the largest non-filesystem leak: a fork-only child would retain the
substrate, prompts, private registries and host handles in memory. Namespaces
alone would not erase them.

### C2. Root truth remains owned by the first hand

The QA registry stores no host path/fd/root lifecycle. The existing private
repository registry reserves one transaction-bound read-only source lease from
the terminal sealed root. A shared internal userdata ABI lets the native
launcher duplicate the already-open exact root fd without returning it to Lua.

```text
repository registry  owns root identity, seal closure and pre/post inventory
QA registry          owns one execution grant/transaction/receipt
native supervisor    owns process/isolation/measurement facts
☶                    owns body check or execution-failure evidence
☱                    owns deterministic final verdict
```

No row can write another row's fact.

### C3. The native closure is one exact static world

The supervisor is static PIE with embedded/admitted Lua 5.4. A dynamic or
weaker fallback cannot use the same provider/environment identity. The
environment id includes actual launcher/supervisor/runtime/kernel/feature/policy
identities.

Header presence and permissive sysctls are not proof. The environment exists
only after the exact production probe exercises namespaces, mounts, pivot,
seccomp, watchdog and cleanup without SKIP.

### C4. The wire cannot grow into a command language

The public request and native frame contain only exact ids/digests, one sealed
relative entrypoint and numeric bounds. There is no executable, argv, env, cwd,
shell, mount or syscall field. The supervisor executable is selected before
candidate data is parsed and is entered by open-fd `execveat`.

### C5. Source stability reuses the existing witness

QA does not implement another tree hasher. The existing candidate-seal
inventory normalizer/comparator observes:

```text
pre inventory == immutable seal == post inventory
```

The native supervisor additionally reports the exact root device/inode/mount
identity it received. Source drift is infrastructure failure, never candidate
rejection.

### C6. Success and failure have symmetric body phases

```text
accepted process -> ☶ accepted check -> build ◈ -> ☱ accepted verdict -> ▲
rejected process -> ☶ rejected check -> build ◈ -> ☱ rejected verdict -> ▲
```

Infrastructure failure has no check/verdict and reaches existing
`effect_failure`. Malformed trusted physics remains loud.

### C7. QA detail and current budget use different schemas

Full QA evidence preserves wall/CPU/scratch/output measurements. Existing body
economics receives only its admitted axes:

```text
tool_calls
test_runs
time_ms
```

There is no unreviewed `qa_executions` budget-axis amendment. The detailed
field remains evidence and may inform later budget work.

### C8. QA evidence survives terminal truncation

Check, execution failure and verdict records are frozen in a dedicated corpse
QA envelope outside `trace_tail`. Accepted/rejected terminal lives additionally
carry one exact `qa.terminal_projection.v0` through △. Private leases/handles
and raw output do not cross.

## 3. Exact Causal Chain

| Phase | Record/state | Writer | First named reader |
|---|---|---|---|
| stage policy | `qa.contract.v0` | trusted birth/lineage binder | Packet birth and request reader |
| host world | private environment + public projection | environment registry | contract/grant resolver |
| eligibility | `qa.eligibility.v0` | pure reader | request preparation/readiness |
| request | `qa.check_request.v0` body event | ☶ | QA grant mint/begin |
| source authority | private sealed-source lease | repository registry | trusted QA transaction |
| execution authority | private grant/transaction | QA registry | strict provider adapter |
| process fact | native report/error | supervisor + adapter | private receipt writer |
| private commit | `qa.execution_receipt.v0` | QA registry | ☶ evidence writer/idempotence |
| body observation | `qa.check.v0` | ☶ | ☱ verdict assembler |
| testing-world failure | `qa.execution_failure.v0` | ☶ | operator registry/runner |
| body verdict | `qa.candidate_verdict.v0` | ☱ | completion/work-layer/△ |
| terminal projection | `qa.terminal_projection.v0` | △ | corpse/lineage/corpus |
| frozen evidence | `corpse.qa_evidence.v0` | corpse capturer | lineage/corpus/history |

Every written record has a named reader. No substrate is an authority writer.

## 4. Identity Join

The body/private join agrees on:

```text
session through private registry
Packet id
lineage id
generation
process contract id
semantic context
stage id
repository/root authority id
candidate seal id and event ref
artifact alignment id
QA contract/check/profile/environment ids
request id and body request event ref
private receipt id/result digest
```

The native wire deliberately carries less:

```text
private transaction nonce
request/profile/environment digests
root device/inode/mount identity
entrypoint
exact limits
```

Lineage prose and public host paths are unnecessary to process containment and
therefore do not cross that boundary.

## 5. Private/Public Audit

| Value | Public body evidence? | Carries authority? |
|---|---:|---:|
| qa contract/profile/environment projection | yes | no |
| request/check/verdict/failure | yes | no private host authority |
| grant id / receipt id | audit id only | no |
| private environment lease | no | yes, one exact environment |
| private QA grant/transaction | no | yes, one execution |
| sealed-source lease | no | yes, read-only exact root handoff |
| repository userdata/fd/path | no | yes, registry/native only |
| supervisor fd/build manifest | no | trusted launcher only |
| raw stdout/stderr/scratch content | no | no retained surface |

No detached id can be resolved without the exact private registry object and
state.

## 6. Native Trust Boundary

Selected mandatory mechanics:

```text
static PIE supervisor
open+hash+execveat exact supervisor fd
async-signal-safe fork child before exec
fresh user/mount/PID/network/IPC/UTS namespaces
private mount propagation and pivoted empty root
read-only noexec source + bounded noexec scratch tmpfs
all capabilities dropped + no_new_privs + closed seccomp allowlist
RLIMIT CPU/AS/NOFILE/FSIZE/CORE/NPROC
parent monotonic watchdog and complete wait/reap
bounded stream hashing with no raw retention
exact cleanup or ambiguous infrastructure error
```

The initial x86_64 syscall allowlist is a falsifiable hypothesis, not an excuse
to broaden at runtime. If the admitted Lua profile needs another syscall, the
change must be recorded as a policy/environment amendment with a hostile test.

## 7. Refinements Relative To TABLE

CRYSTALL made these representation choices without changing TABLE meaning:

```text
R1 qa_contract core validation lives in core/qa_schema.lua; private environment
   authority lives in runtime/qa_environment.lua

R2 request is appended before private grant begin; a later pre-begin
   unavailability leaves one honest pending request and no process cost

R3 cpu_time_ms is restricted to positive whole seconds because v0 uses
   RLIMIT_CPU; finer declared precision would be false

R4 source inventory remains in the existing repository provider; the native
   supervisor proves root identity/process mechanics rather than duplicating
   candidate-seal hashing

R5 qa.cost.v0 retains detailed measurements while budget projection uses the
   already admitted tool_calls/test_runs/time_ms axes

R6 full QA evidence is frozen in corpse even when death happens before △ or
   before final verdict
```

These are narrowing/ownership refinements. None adds public authority or a new
outcome class.

## 8. Cross-Reader Consistency

| Exact current evidence | Completion state | Work glyph | Terminal permission |
|---|---|---|---|
| seal only | `sealed` | `⊞` | none |
| accepted check only | `qa_acceptance_observed` | `◈` | verdict only |
| rejected check only | `qa_rejection_observed` | `◈` | verdict only |
| execution failure | `qa_infrastructure_incomplete` | `⊞` before effect death | no verdict/△ QA boundary |
| accepted final verdict | `qa_accepted` | `▲` | accepted Packet terminal projection |
| rejected final verdict | `qa_rejected` | `▲` | rejected-generation terminal projection |
| post-seal alignment divergence | sealed + conflict | `⊞` | fresh-generation plan, no QA |

Packet/corpse cannot emit `software_accepted`. Final lineage acceptance still
requires △, corpse and lineage assessment.

## 9. Failure Separation

| Evidence | Class | Packet consequence |
|---|---|---|
| no eligibility/environment before dispatch | not-ready | no process/death/cost |
| contained non-success/limit/policy | candidate rejection | rejected check then verdict |
| provider cannot prove world/supervision/cleanup | infrastructure | failure event then effect_failure death |
| trusted schema/identity contradiction | invariant | harness loud, no honest Packet outcome |

Matched timeout law:

```text
candidate wall timer + complete kill/reap/postflight -> rejected wall_timeout
outer/supervision timeout + ambiguous cleanup       -> infrastructure failure
```

## 10. Host Feasibility Observation

Observed on the development host during this crystall:

```text
Linux 6.18.36_1 x86_64
GCC 14.2.1
Lua 5.4.8
glibc 2.41
/proc/sys/user/max_user_namespaces = 2147483647
required Linux syscall/header declarations present
/usr/lib/liblua5.4.a present
```

This supports attempting the implementation. It proves neither static linking
nor unprivileged namespace/mount/seccomp behavior. The exact native probe is the
only future authority for `qa.environment.v0`.

## 11. False-Green Gates

The following must never pass:

```text
fork-only child retaining proc-17 memory
dynamic/unknown supervisor under the v0 environment id
header/sysctl presence treated as isolation proof
candidate-selected executable/argv/env/cwd
public root path/fd or copied repository lifecycle in QA registry
exit zero without request/receipt/pre=seal=post/cleanup
accepted check without final verdict
infrastructure failure rendered as rejected candidate
body outcome without private receipt
receipt/body split repaired by rerunning
ancestor QA used as descendant current evidence
raw output retained or fed to substrate
```

## 12. False-Red Gates

These remain ordinary candidate rejection when containment is complete:

```text
nonzero exit
Lua error/crash
proved wall/CPU/memory/output/scratch bound
proved seccomp policy violation
```

An unavailable historical environment may block same-stage recovery without
rewriting the old contract or old QA history.

## 13. Implementation Dependency Order

```text
8.5.4A schema/id/event-right red tests
8.5.4B private grant/source/replay/split-brain red tests
8.5.4C binary wire/build/environment-probe red tests
8.5.4D inert hostile candidate and trusted-fault red corpus

8.5.5A core schemas and private registries
8.5.5B shared repository userdata ABI with first-hand regressions
8.5.5C static supervisor and exact environment probe
8.5.5D one isolated clean/rejected process transaction
8.5.5E resource/policy/fault/leak controls

8.5.6A body check/failure/verdict writers
8.5.6B completion/work-layer/manifest/corpse readers
8.5.6C tree readiness only after observer evidence

8.5.7 grown accepted/rejected/infrastructure lives and lineage consequences
```

The dangerous candidate fixtures enter only at 8.5.5C/D and only through the
isolated provider. Step 8.5.4 stores them as inert bytes and tests the absent
provider/contract boundaries.

## 14. Residual Risks And Explicit Non-Claims

```text
same-authority host mutation fully between pre/post observations remains outside
kernel and trusted supervisor remain TCB
initial seccomp allowlist may be falsified by the exact profile corpus
static toolchain availability is not yet proven
candidate-authored tests may be semantically weak
passing proves contract satisfaction, not universal correctness
raw diagnostics are intentionally unavailable for semantic repair v0
no persistence/restart/retry of QA private transactions
```

These are named limits, not reasons to weaken the first implementation.

## 15. Decision

```text
Step 8.5.3 is complete.

The four QA crystall documents and five amendments are internally consistent
and precise enough to write a hostile red battery without inventing policy.

Authorized next:
  step 8.5.4 tests, inert fixtures, native wire/build probes and expected-red
  assertions

Still forbidden:
  candidate process dispatch
  generic command execution
  router/pressure promotion
  software acceptance from Packet-local evidence
```

## 16. Chapter Position

```text
8.5.1 Chaos threat model                                    complete
8.5.2 TABLE contracts and cross-audit                       complete
8.5.3 CRYSTALL schemas/authority/native ABI                 complete
8.5.4 hostile red battery                                   next
8.5.5 minimal isolated Linux QA hand                        blocked by red gate
8.5.6 completion/work-layer/manifest readers                blocked by hand
8.5.7 grown accepted/rejected/infrastructure lives           blocked by readers
```
