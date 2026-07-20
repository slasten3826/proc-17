# Plan To Build Carrier Live Software Experiment Notes

Status:

```text
chaos
live DeepSeek experiment
single paired sample
runtime facts separated from interpretation
do not promote to general law yet
```

Date:

```text
2026-07-20
```

Related implementation:

```text
runtime/tension_runner.lua
runtime/plan_completion.lua
runtime/repository_result.lua
runtime/repository_capability.lua
runtime/repository_provider.lua
runtime/work_completion.lua
```

Related records:

```text
docs/00_chaos/first_repository_hand_manifest_results_2026-07-20.md
docs/03_manifest/repository_delivery.v0.md
docs/03_manifest/current_state.md
```

Local experimental material, intentionally outside Git:

```text
sandbox/live_software_probe_20260720_01/
sandbox/live_software_probe_20260720_02/
```

The sandbox material is useful local evidence but is not yet a public,
reproducible smoke program. Any future promoted claim needs a named live smoke
or a deterministic paired fixture in the repository.

## 1. Trigger

The first capability-safe repository hand had completed its 7.1-7.10 campaign.
The body could grow one exact repository life:

```text
semantic proposal
  -> structured repository work
  -> capability-authorized native effect
  -> independent read-back
  -> LOGIC validation
  -> body-owned completion
  -> repository.result.v0
```

The open question was no longer whether the body could create a real file.

The question became:

```text
Does a plan life materially improve the following build life?
```

The operator prediction was:

```text
build-only sees the target and acts
plan sees constraints and failure surfaces
plan -> build should preserve both
```

## 2. Software Task

All three probes used the same bounded task class:

```text
create one Python 3 file named notes.py
use only the standard library
provide add, list, done and delete commands
accept a global --db PATH
persist notes in JSON
store integer id, text and done
never reuse deleted IDs
save atomically through a temporary file and os.replace
return controlled non-zero failures for missing IDs and malformed data
run through python3 notes.py --help
```

This task fits the first hand exactly:

```text
one absent UTF-8 text file
one granted repository root
one create-no-replace effect
no existing repository context
no patch
no command or test hand
```

## 3. Experimental Boundary

Three observations were made.

### A. Build-only

One build Packet received the task and the strict artifact proposal contract.
It had one create-only repository capability.

### B. Plan-only

One plan Packet received the same requirements but was asked for an ordered
`work_sequence`. It received no repository capability and therefore had no
physical mutation path.

### C. Plan then build

One fresh plan Packet produced `plan.result.v0`. A temporary host harness then
inserted that structured result, byte-for-byte through JSON encoding, into the
prompt of one fresh build Packet. The build Packet received a new capability
for a new empty repository.

The temporary carrier did not edit, summarize or repair the plan.

However, this was not yet automatic proc-17 lineage re-entry:

```text
the harness selected the mode transition
the harness transported plan.result.v0
the two runs shared a declared lineage_id but did not use lineage_runner
the DeepSeek adapter supplied no hidden provider conversation continuity
```

Therefore the experiment tests explicit plan transport, not finished
plan-to-build lineage mechanics.

## 4. Build-Only Result

Runtime result:

```text
wall time             10.3 seconds
substrate calls       1
prompt tokens         438
completion tokens     1402
total tokens          1840
body ticks            6
file writes           1
tool calls            2
provider time         4 ms
loss                   0.15
artifact bytes        4176
artifact sha256       1ec5000672e8e26d62b077fb0f6f6c3bea32a20fe57926c3861be00a4aa472d7
terminal              dead / complete
manifest              repository.result.v0
```

Logged tick walk:

```text
☴ -> ☵ -> ☱ -> ☶ -> ☱ -> △
```

Conceptual birth-inclusive route:

```text
▽ -> ☴ -> ☵ -> ☱ -> ☶ -> ☱ -> △
```

The generated file compiled and its ordinary commands worked, but external QA
found two requirement-level defects:

```text
1. deleting the highest ID allowed that ID to be reused
2. malformed but syntactically valid field types caused a Python traceback
```

The body still terminated `complete` because its exact completion predicate
proved the selected artifact and its bytes, not the software requirements.

This was an honest repository completion and an incomplete software-task
completion.

## 5. Plan-Only Result

The isolated plan probe produced 12 ordered work items.

Runtime result:

```text
wall time             9.1 seconds
substrate calls       1
prompt tokens         436
completion tokens     967
total tokens          1403
body ticks            5
file writes           0
tool calls            0
loss                   0.25
terminal              dead / complete
manifest              plan.result.v0
```

Logged tick walk:

```text
☴ -> ☵ -> ☴ -> ☱ -> △
```

The plan explicitly required:

```text
a database object containing next_id and notes
increment-only next_id
no ID reuse after delete
field-type validation for id, text and done
malformed-data error paths
an explicit QA case for deleted-ID reuse
```

Those are exactly the surfaces missed by the build-only artifact.

The plan file caused no repository effect. The build-only artifact hash remained
unchanged after the plan life.

## 6. Paired Plan-To-Build Result

The paired run created two mortal Packets.

### Plan Packet

```text
walk                  ☴ -> ☵ -> ☴ -> ☱ -> △
ticks                 5
prompt tokens         410
completion tokens     926
total tokens          1336
substrate calls       1
file writes           0
tool calls            0
loss                   0.25
terminal              dead / complete
manifest              plan.result.v0
```

### Build Packet With Plan Carrier

```text
walk                  ☴ -> ☵ -> ☱ -> ☶ -> ☱ -> △
ticks                 6
prompt tokens         1446
completion tokens     1706
total tokens          3152
substrate calls       1
file writes           1
tool calls            2
provider time         4 ms
loss                   0.15
terminal              dead / complete
manifest              repository.result.v0
artifact bytes        5014
artifact sha256       ecea2c66a37a8f22a0775b413b9782e3ba8710899eec8d24136224efea04ae0e
```

### Combined Cost

```text
wall time             21.2 seconds
substrate calls       2
prompt tokens         1856
completion tokens     2632
total tokens          4488
body ticks            11
file writes           1
tool calls            2
```

Compared with build-only:

```text
tokens                1840 -> 4488
wall time             10.3 s -> 21.2 s
artifact bytes        4176 -> 5014
known QA defects      2 -> 0 in the executed battery
```

The additional build prompt cost came mainly from transporting the complete
plan result. The deterministic body work still added negligible latency next
to the two substrate calls.

## 7. External QA Result

The paired artifact was tested outside proc-17 because the body does not yet
own a test-runner hand.

Result:

```text
QA summary: green=9 red=0
```

Cases:

```text
GREEN Python compilation
GREEN --help exposes add/list/done/delete
GREEN initial IDs are monotonic
GREEN deleted IDs are never reused
GREEN list preserves done/deleted/live state
GREEN missing ID is a controlled non-zero failure
GREEN malformed JSON is a controlled non-zero failure
GREEN malformed field types are a controlled non-zero failure
GREEN the database persists the next_id counter
```

No repair prompt or manual code edit was required after generation.

This does not mean testing was unnecessary. It means the tested artifact passed
on its first QA run.

## 8. Residual Engineering Risk

The external battery did not prove:

```text
inter-process concurrency safety
crash behavior at every point of atomic replacement
cleanup of a temporary file after every exceptional save path
portability across non-POSIX environments
long-running database growth behavior
```

Direct review found two non-blocking robustness pressures:

```text
save_db does not explicitly unlink its temporary file after every caught error
there is no inter-process lock, and the plan itself names this limitation
```

These did not violate the bounded single-user task used in the experiment, but
they prevent a claim of production completeness.

## 9. What Is Runtime-Confirmed

The following claims are supported by body trace, provider evidence or the
external executable QA:

```text
plan mode can produce an exact Packet-local plan.result.v0
plan mode can remain physically inert without repository authority
build mode can consume a transported plan as semantic input
the following build life can create and independently verify one real file
the paired artifact passed the named 9-case QA battery without repair
the plan named the two requirement surfaces missed by the build-only artifact
the paired run cost 4488 tokens and approximately 21.2 seconds end to end
```

## 10. What Is Not Yet Proven

The experiment does not prove:

```text
plan always improves build
the improvement generalizes beyond one task and one DeepSeek model
the exact same build prompt without the plan would always reproduce the defects
plan content is runtime truth
proc-17 can yet perform the plan-to-build transition by itself
proc-17 can test or repair the generated program by itself
the resulting artifact needs no testing
```

This is an N=1 paired observation with a strong mechanism and a useful control,
not a calibrated production claim.

## 11. Main Observation

The strongest current interpretation is:

```text
PLAN preserved constraints and anticipated failure surfaces.
BUILD converted the transported plan into a materially better first artifact.
```

The result supports the earlier behavioral distinction:

```text
plan understands and bounds
build selects and acts
```

The modes are not merely two prompt flavors in this experiment. They produced
different Packet structures, different routes, different material authority
and different contributions to the final artifact.

## 12. New Completion Pressure

The experiment exposed a scope problem that must be named before automatic
mode transition.

The plan Packet died `complete`, but only this stage was complete:

```text
planning complete
software task incomplete
```

The following build Packet then died `complete` under another predicate:

```text
repository artifact complete
software QA still external
```

Therefore a future automatic chain needs to distinguish at least:

```text
Packet-life completion
stage completion
root task completion
```

Without this distinction, a terminal plan manifest can be mistaken for the end
of the user's software task, or a byte-verified artifact can be mistaken for a
requirement-verified product.

## 13. Carrier Truth Boundary

The transported plan has:

```text
body assembly truth        runtime_confirmed
plan content truth         semantic_proposal
applicability to build     inherited proposal / unresolved until build
```

Automatic re-entry must preserve these statuses.

It must not promote the plan content to runtime truth merely because the plan
survived MANIFEST. The build Packet may use it as a selected orientation or
contract candidate, but runtime truth still comes only from effects and
evidence owned by the body.

## 14. Next Architectural Pressure

The desired autonomous form is:

```text
plan Packet
  -> △ plan.result.v0
  -> corpse / stage result
  -> typed plan-to-build carrier
  -> NETWORK@▽
  -> fresh build Packet
  -> repository effect
  -> QA evidence
  -> repair generation when required
```

The open ownership question is:

```text
Does lineage_runner own the mode transition,
or does the future machine CLI request the next typed stage?
```

Whichever actor requests continuation must not:

```text
rewrite the plan
fabricate task completion
smuggle repository authority through the carrier
reset lineage economics
turn semantic plan content into runtime evidence
```

## 15. Falsifiers For The Next Experiment

A broader paired battery should compare:

```text
build-only
plan then build with exact carrier
plan then build with plan ablated
plan then build with one critical plan item removed
```

Across several one-file tasks, record:

```text
first-pass QA pass count
repair generations required
total tokens
wall time
artifact defects by requirement
whether build actually reflects plan-specific constraints
```

The plan-to-build hypothesis weakens if:

```text
QA quality does not improve over build-only
build ignores transported plan constraints
token/time cost grows without reducing repair generations
plan transport introduces false authority or stale requirements
```

## 16. Current Conclusion

The first paired observation is positive:

```text
build-only              fast, cheap, two detected requirement defects
plan -> build           twice as slow, 2.44x tokens, zero defects in 9-case QA
```

The result is strong enough to justify a table-stage contract for typed
plan-to-build continuation.

It is not strong enough to remove QA, declare plan universally beneficial, or
claim that automatic lineage re-entry already exists.
