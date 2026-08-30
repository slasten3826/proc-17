# proc-17 v0 Release Closure Notes

```text
STATUS RECONCILED 2026-08-23 by:
docs/00_chaos/proc17_kernel_roadmap_and_model_orchestration_notes_2026-08-23.md

The v0.1 public capability and finite release law in this document remain
active. C1-C5 were implemented after this note; C6-C9 and the v0.1.0 tag remain
open. Later QA, authority-instrument and DISSOLVE campaigns do not silently
widen the v0.1 claim. The newer roadmap resumes release closure before another
kernel expansion.
```

Status:

```text
layer: CHAOS
date: 2026-07-27
decision kind: product boundary / feature freeze
target release: v0.1.0
runtime implementation authorized by this note: no
next documentation action: one bounded CLI TABLE round
```

Primary runtime sources:

```text
docs/03_manifest/current_state.md
docs/00_chaos/proc17_capability_handoff_2026-07-19.md
docs/00_chaos/second_qa_hand_provider_witness_results_2026-07-26.md
runtime/tension_runner.lua
runtime/lineage_runner.lua
runtime/session_memory.lua
runtime/repository_capability.lua
runtime/qa_provider_witness.lua
```

## 0. Decision

proc-17 v0 development enters release closure.

The body will not acquire another organ, broader repository operation, QA
authority, persistence mechanism, router treatment, memory reader or
self-hosting mechanism before `v0.1.0` unless a reproduced release blocker
proves that the already declared v0 capability cannot be exposed honestly.

The next product boundary was already named in `current_state.md`:

```text
machine CLI over the exact existing capability
then Go TUI
operation widening remains a separate capability-first campaign
```

This note turns that direction into a finite release decision.

## 1. Why Closure Is Required

proc-17 has crossed the point where every discovered limitation can be made
into another architecture chapter. Continuing that pattern would improve the
laboratory body indefinitely while preventing the body from becoming a usable
tool.

The difficult physical core already exists:

```text
mortal Packet life
body-owned topology and routing
typed runtime truth
budget and identity loss
terminal manifestation and immutable corpse
session-scoped grave and compost
in-memory lineage and NETWORK re-entry
qualified plan and build lives
one capability-safe create-no-replace repository hand
independent read-back and exact one-artifact delivery
real DeepSeek substrate integration
```

The remaining gap for v0 is product access, not another ontology.

## 2. Honest v0 Capability

`v0.1.0` may claim exactly this:

```text
proc-17 can run one bounded plan or build task through the Packet body;
the LLM remains replaceable semantic current rather than route authority;
a plan Packet can manifest one structured plan result;
a build Packet can create one previously absent UTF-8 text file inside one
explicitly granted repository root, independently read it back, account for
the effect and manifest one exact repository result;
the run exposes its trace, budget, terminal state and identities as structured
machine data;
sessions are separate by default and may carry only their own grave memory.
```

This is a narrow coding agent for fresh software. It is not a legacy editor.

The build contract is deliberately small:

```text
one generation
one repository identity
one create_text_file action
one absent relative path
one exact content payload
no overwrite
no patch
no delete
no rename
no arbitrary read/search
no command execution
```

The limitation must be visible in CLI output and README. It must not be hidden
behind generic wording such as "edits a repository" or "builds arbitrary
software".

## 3. Frozen Experimental Surfaces

The following code and documentation remain in the repository, but are not v0
release blockers and receive no CLI authority:

```text
QN17 hostile candidate containment campaign
QN18 trusted crash/pipe fault campaign
QN19 cleanup ambiguity campaign
QN20 repeated leak campaign
Packet QA request/grant/receipt
body QA check/failure/verdict
QA-driven completion/work-layer/tree movement
self-hosting and automatic self-modification
multi-file repository work
legacy repository reconstruction
persistent or branching lineage
provider-owned substrate conversation sessions
general bequest and compost readers
full tree promotion and pressure calibration
qualified DISSOLVE promotion
generic commands, executable selection, argv, env or cwd
```

`qa.provider_witness_report.v0` stays an internal harness witness. No CLI reader
may treat it as a Packet check, verdict or software acceptance.

The expected-red QA matrix remains evidence of withheld authority. Red
`QN17-QN20`, `QE` and `QV` controls do not block v0 because the public body is
not allowed to execute or consume that deferred QA transaction.

## 4. Self-Hosting Experiment Disposition

On 2026-07-27 an external harness ran one DeepSeek plan Packet followed by one
build Packet and requested a `QN17` self-hosting patch.

Runtime-confirmed inside proc-17:

```text
plan Packet:  dead/complete, plan delivery, one substrate call
build Packet: dead/complete, repository delivery, one substrate call
one file named qn17_candidate.patch was created through the first hand
```

Observed only by the external harness:

```text
the plan repeated superseded D1-D7 work
the patch aliased QN17 to the old basic target
the patch added comments instead of hostile execution evidence
the patch changed unrelated linker flags
git apply --check rejected the malformed patch
```

The external rejection is not Packet truth. It did not enter the Packet trace,
did not create a body-owned QA check and may not be laundered into a grave
warning. The experiment therefore proves artifact delivery, not failed
self-hosting known by the body.

Release consequence:

```text
self-hosting is deferred;
no retry is required for v0;
software acceptance remains an external user/test responsibility;
the CLI must distinguish Packet completion from external software acceptance.
```

## 5. v0 Session Law

The CLI/TUI, not an individual Packet, manages sessions.

Required v0 behavior:

```text
no session argument -> create a fresh session with a generated safe id
fresh session -> empty grave and compost
explicit existing session id -> load only that session
session memory never crosses ids
an optional human label may be assigned without becoming identity
the structured result always reports session_id and lineage_id
```

The TABLE round must settle create-versus-load syntax and collision behavior.
It may use the existing `runtime/session_memory.lua` create/load/save boundary;
it must not invent a second session store.

The generated id in the current runtime is safe but not a UUID. Exact UUID
format is not a v0 blocker unless the CLI contract chooses to strengthen the
identity schema consistently. Random-looking text must not be advertised as a
cryptographic or globally unique identity without a physical writer that can
support the claim.

## 6. Minimal Machine CLI Surface

The v0 interface is machine-first. Human TUI work begins only after the CLI
release gate closes.

The bounded CLI must expose:

```text
one run command
mode: plan | build
task input from an explicit argument, file or stdin
substrate provider/model configuration
explicit Packet and lineage budgets
fresh session by default; explicit session load when requested
build repository coordinates only in build mode
tree/treatment configuration fixed to the proven product path, not arbitrary
router-policy selection
one structured JSON result on stdout
diagnostics only on stderr
stable process exit classes
```

The CLI must not expose:

```text
private capability ids or grants
raw repository handles, paths outside the granted root or provider userdata
generic tools or commands
QA provider witness execution
router experimentation flags
fixture routes
caller-supplied truth status, completion, verdict or grave records
```

The CLI is an adapter over existing body contracts. It does not become a new
truth writer.

## 7. Release Blockers

Only the following work may block `v0.1.0`.

| ID | Blocker | Required evidence |
|---|---|---|
| R0 | Current claims and counts are stale | README/current_state match the release baseline and tests |
| R1 | CLI input contract is ambiguous | one TABLE/CRYSTALL contract for arguments, stdin and config precedence |
| R2 | Session default/resume behavior is ambiguous | fresh/load collision controls and cross-session isolation test |
| R3 | Substrate failures cannot be rendered stably | typed config/provider/network outcome and exit class tests |
| R4 | Plan mode cannot be invoked end to end | one fake and one optional live DeepSeek plan CLI life |
| R5 | Build mode cannot invoke the exact first hand | one fake and one real-provider create-only CLI life |
| R6 | Machine output can mix prose or secrets with JSON | stdout/stderr separation and schema tests |
| R7 | CLI can widen authority | hostile argument and capability non-leak tests |
| R8 | Release behavior is not reproducible | bounded end-to-end release battery on a clean checkout |
| R9 | Installation/invocation is unspecified | one documented Lua 5.4 invocation and dependency check |

A defect outside this table is assigned to post-v0 unless it falsifies one of
these blockers with a reproducible run.

## 8. Definition Of Done

`v0.1.0` is ready when all of the following hold:

```text
feature freeze remains intact
CLI TABLE and CRYSTALL contracts are implemented
ordinary Lua suite is green
mortality battery is 8/8
repository hostile and candidate-seal suites remain green
expected-red QA authority matrix changes only if explicitly authorized
fresh-session plan invocation returns one valid JSON result
fresh-root build invocation creates and reports one exact new file
explicit session reuse reads only that session memory
invalid input and unavailable substrate have stable nonzero exits
no CLI output contains private authority or raw provider state
README states the one-artifact/create-only and external-QA limitations
current_state records the release rather than an open architecture campaign
clean checkout instructions reproduce the fake-substrate release battery
release commit is tagged v0.1.0
```

Live DeepSeek success is a product integration witness, not a deterministic CI
dependency. Fake substrate and native provider controls remain the reproducible
release gate.

## 9. Change Admission During Closure

A proposed change enters v0 only if it has all four:

```text
named release blocker R0-R9
reproduced failing case
smallest correction that closes that case
regression evidence proving no authority widening
```

The following arguments are insufficient:

```text
"the architecture would be cleaner"
"the agent should eventually know this"
"the feature already has a blueprint"
"another model found an interesting omission"
"self-hosting would be more complete"
```

Those may become post-v0 pressure. They do not reopen the release body.

## 10. Ordered Closure Plan

```text
C0 write this release closure decision                         complete
C1 build one CLI TABLE round for R1-R3 and R6-R7               next
C2 crystallize the CLI adapter and release battery
C3 implement the Lua machine CLI without new body authority
C4 grow fake plan and real create-only build lives through CLI
C5 test session default/load isolation and structured exits
C6 update README and current_state to the measured baseline
C7 run the clean-checkout release battery
C8 fix only reproduced R0-R9 blockers
C9 commit, push and tag v0.1.0
```

The Go TUI starts after C9. It consumes the machine CLI/session contracts and
does not delay the first release.

## 11. Closure Thesis

```text
proc-17 v0 does not need another organ to become real.
It needs one honest door into the body, a finite claim, and a release.
```
