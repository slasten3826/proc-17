# Autonomous Plan-Build False Acceptance And QA Handoff

Status:

```text
layer: CHAOS
date: 2026-07-27
purpose: exact project stop point and evidence for resuming the second QA hand
runtime implementation authorized by this note: no
current body QA authority: absent
isolated provider QA witness: present and runtime-confirmed
next documentary authority: new TABLE/CRYSTALL round before wider QA power
```

Continuation amendment 2026-07-28:

```text
8.5.5E CHAOS/TABLE/CRYSTALL completed and cross-audited;
private provider implementation E1-E10 is now authorized;
body QA authority remains the later 8.5.6 boundary.
```

## 0. Why This Record Exists

proc-17 has reached a boundary that is easy to describe incorrectly.

The project has not merely decided that QA would be useful. It has already
built and exercised most of the dangerous physical foundation of a second,
read-only hand. However, the Packet body still cannot request that hand, record
its result as body evidence, assemble a QA verdict or let that verdict govern
completion.

On 2026-07-27 an autonomous external `Plan -> Build -> Plan` experiment
produced a concrete false acceptance:

```text
Plan 1 designed the product.
Build 1 wrote a complete Python program.
Plan 2 read the complete program and returned ACCEPT.
The program then crashed on its first ordinary gameplay turn.
```

This makes the missing boundary empirical. Semantic review is not runtime QA.

## 1. Exact Current Stop Point

The second-hand roadmap has reached this state:

```text
8.5.1  QA threat model                                      complete
8.5.2  TABLE contracts and cross-audit                     complete
8.5.3  CRYSTALL schemas, authority and native ABI          complete
8.5.4  preimplementation hostile red battery               complete
8.5.5A schemas and private registries                      complete
8.5.5B shared repository userdata/source bridge            complete
8.5.5C static supervisor and environment probe             complete
8.5.5D isolated clean/rejected provider transaction        complete
8.5.5E hostile/fault/resource/leak campaign                not implemented
8.5.6  Packet check/verdict and body readers               not implemented
8.5.7  grown accepted/rejected/infrastructure lineages     not implemented
```

Implementation continuation 2026-07-28:

```text
8.5.5E E1 wire v1 and strict Lua schemas                   complete
8.5.5E E2 measured environment identity rotation           complete
8.5.5E E3 supervisor STARTED/cause/finality physics         complete, unrouted
8.5.5E E4-E10                                               not implemented
current production execution                               RUN v0
QA control matrix                                          40 green / 44 red
```

E1 deliberately produced zero authority/color delta. Its exact result is
recorded in `docs/03_manifest/qa_hostile_execution_e1.v0.md`.

E2 also produced zero execution/color delta while making environment v1 the
only active identity. See
`docs/03_manifest/qa_environment_rotation_e2.v0.md`.

E3 produced zero execution/color delta while linking the private STARTED,
first-cause and finality mechanism into the production supervisor. RUN v0 does
not route through it; C5 measurements remain the next dependency. See
`docs/03_manifest/qa_supervisor_phase_e3.v0.md`.

The latest completed implementation evidence is:

```text
docs/00_chaos/second_qa_hand_provider_witness_results_2026-07-26.md
```

Its exact ceiling must be preserved:

```text
qa.provider_witness_report.v0 exists;
it is private provider evidence;
no organ, router, pressure reader, completion reader, lineage reader or CLI
can consume it;
the Packet learns nothing from it.
```

This is deliberate split-brain prevention, not missing glue that may be added
casually.

## 2. What The QA Foundation Already Proves

The implemented provider path can:

```text
take one exact current candidate seal;
reserve one opaque one-use source lease;
stage the exact sealed repository as a detached read-only/noexec mount;
cross an execveat memory-erasure boundary;
run a fixed Lua test profile inside the static Linux supervisor;
deny network, native loading and host-path authority;
bound wall time, CPU, memory, streams and scratch;
classify clean exit and one Lua runtime failure;
revalidate the source before and after execution;
terminalize the source lease before assembling a report;
return a detached provider witness without mutating Packet physics.
```

The 2026-07-27 cold baseline confirmed:

```text
lua tests/run.lua
  -> exit 0
  -> all tests ok

lua tests/smoke_mortality_battery.lua
  -> 8/8

lua tests/test_qa_provider_witness.lua
  -> clean sealed root accepted
  -> Lua runtime error rejected
  -> source final before report
  -> 3 green / 0 red / 0 skip

lua tests/test_qa_native_supervisor.lua
  -> QN01-QN16 green
  -> QN17-QN20 explicit deferred skips
```

The second hand therefore does not need a new sandbox design. It needs the
remaining hostile campaign and a lawful body transaction around an already
measured provider boundary.

## 3. What Is Still Missing

The body currently lacks the causal chain:

```text
eligible exact candidate
  -> Packet-owned QA request
  -> private one-use execution grant
  -> provider transaction
  -> private execution receipt or typed infrastructure failure
  -> body-owned qa_check / qa_execution_failure event
  -> deterministic qa_verdict assembly
  -> completion/work-layer/manifest/corpse readers
  -> tree route or lineage consequence
```

Consequently, all of the following remain forbidden or impossible:

```text
Packet-triggered QA execution
body-owned QA check evidence
body-owned accepted/rejected verdict
software_accepted derived from runtime QA
qa_rejected terminal projection
QA-driven recovery generation
CLI acceptance guarded by QA
```

The current CLI can run one Plan Packet or one Build Packet. It cannot run a
native software lifecycle and it cannot distinguish plausible source text from
a functioning product.

## 4. Autonomous Experiment

### 4.1 Question

The experiment asked:

```text
If Plan receives the original task plus the complete current artifact after
every Build, will repeated semantic self-review converge to a genuinely working
program without external QA guidance?
```

No defect hints, patch instructions or external review findings were returned
to the loop.

### 4.2 Orchestration

The external harness used one CLI session/grave and a fresh empty repository
root for Build:

```text
Plan 1: original task, no artifact
Build 1: original task + Plan 1 result, fresh repository root
Plan 2: original task + complete Build 1 artifact
stop only when Plan emits ACCEPT
```

This was an external orchestration experiment. The calls shared session memory,
but each CLI invocation still created its own CLI Packet/lineage. Therefore it
does not claim that the body-native lineage runner already owns this loop.

The task required a complete playable terminal ASCII roguelike in one Python
program, including world generation, combat, progression, loot, economy,
balance, victory and defeat, using only the standard library.

### 4.3 Plan And Build Result

Plan 1 emitted eight work items:

```text
design game specification
implement engine core
implement world generation
implement player and combat
implement inventory and loot
implement progression and win/loss
implement UI and input loop
integration test and polish
```

The first Build request encountered one retryable substrate transport failure:

```text
death_cause: effect_failure
failure.code: transport_failed
substrate_calls: 1
tokens: 0
```

The exact unchanged retry succeeded and wrote:

```text
artifact: sandbox/proc17_ascii_roguelike_plan_build_loop_20260727/roguelike.py
size: 19,736 bytes
lines: 527
sha256: 78aee108923557973098a0ce72605dd6ca3f0a85241d1aaa352b897a7ca0ff7d
```

Plan 2 read the complete source and returned:

```text
ACCEPT: The artifact is a complete, playable ASCII roguelike game using only
standard Python libraries. It includes map generation, FOV, combat, items,
leveling, win/loss conditions, and runs as a standalone program. No further
Build phase is required.
```

The semantic loop therefore terminated after:

```text
Plan 1 -> Build 1 -> Plan 2 ACCEPT
```

### 4.4 Economics

Successful Packet-local substrate usage was:

```text
Plan 1      547 prompt + 233 completion =   780 tokens
Build 1     598 prompt + 5670 completion = 6268 tokens
Plan 2     5654 prompt + 143 completion = 5797 tokens
                                               -----
total successful substrate usage             12845 tokens
```

Plan 2 cost almost as much as Build 1 because the complete 527-line artifact
entered its prompt. High review cost did not imply physical validation.

## 5. External QA Result

The external observer ran only after Plan had stopped the loop. Its findings
were not fed back to Plan or Build.

### 5.1 Syntax

```text
python3 -m py_compile roguelike.py
  -> exit 0
```

### 5.2 Startup

The program started in an 80x40 PTY, initialized curses and rendered a map,
player, monsters, item, status and instructions.

This proves only startup and first render.

### 5.3 First Ordinary Gameplay Tick

One right-arrow input produced:

```text
exit: 1

Traceback:
  File "roguelike.py", line 482, in main
    if entity.ai and entity != player:
AttributeError: 'Entity' object has no attribute 'ai'
```

The source creates optional components ad hoc but the main loop reads them as
total fields. The same class of defect is visible for `entity.item` in pickup
handling. The requested economy also has no implementation in the artifact.

Therefore:

```text
Plan claim: complete and playable
runtime fact: crashes on first ordinary gameplay action
requirement fact: requested economy absent
```

Plan 2 produced a false green.

## 6. Epistemic Disposition

The experiment separates three claims:

| Claim | Status |
|---|---|
| proc-17 can externally alternate Plan and Build calls | runtime-confirmed |
| Build can materialize a substantial standalone artifact | runtime-confirmed |
| the artifact is complete and playable | semantic proposal, falsified by runtime |
| a gameplay action crashes | runtime-confirmed by external PTY execution |
| semantic Plan review is sufficient for software acceptance | falsified |
| body-owned QA is required before software acceptance | document decision supported by the experiment |

The word `ACCEPT` in Plan output must never be upgraded to
`runtime_confirmed`. At most it means:

```text
semantic_review_proposal
```

Only a body-owned QA verdict bound to the exact candidate seal may unlock
`software_accepted`.

## 7. Architectural Consequence

The needed lifecycle is now evidenced, not speculative:

```text
Plan
  -> Build fresh generation
  -> exact candidate seal
  -> QA execution through the second hand
  -> deterministic verdict

accepted
  -> honest terminal projection
  -> software acceptance

rejected
  -> honest rejected-generation terminal projection
  -> corpse/carrier
  -> fresh Plan/Build generation

infrastructure failure
  -> typed body failure or suspension
  -> never candidate rejection and never acceptance
```

Build must not patch a sealed or rejected generation. Recovery means a new
Packet and a fresh repository identity. QA evidence belongs to the dead
generation and crosses the boundary only through bounded terminal evidence.

## 8. Ordered Resume Plan

The next session should not redesign the QA hand and should not connect the
provider witness directly to the router.

### Step 1: 8.5.5E CHAOS/TABLE/CRYSTALL

Close the deferred physical campaigns:

```text
QN17 hostile candidate containment
QN18 trusted crash and pipe-fault classification
QN19 cleanup ambiguity classification
QN20 repeated transaction leak/residue freedom
```

The current green/skip matrix is evidence. A skip may change only through its
named campaign.

### Step 2: 8.5.6 CHAOS

Specify the body transaction from exact candidate eligibility to terminal
private receipt and one body outcome. Preserve the existing rule:

```text
candidate rejection and body/infrastructure failure are different physics;
Lua/native invariant failure remains a loud harness failure.
```

### Step 3: 8.5.6 TABLE/CRYSTALL

Name every writer, reader, identity join, transition and falsifier for:

```text
QA request/grant/receipt
qa_check and qa_execution_failure
qa_verdict assembly
completion/work-layer/manifest/corpse projection
tree readiness from body evidence
```

No implementation authority exists until this round closes.

### Step 4: 8.5.6 Implementation

Implement in bounded slices with the full ordinary, mortality, hostile and
expected-red matrices after every slice. Do not promote routing merely because
the provider can execute a fixture.

### Step 5: 8.5.7 Grown Lives

Grow, do not synthesize:

```text
accepted candidate -> software accepted
rejected candidate -> honest rejected terminal projection -> fresh generation
infrastructure failure -> no false candidate verdict
stale/foreign seal -> no execution
receipt/body split-brain -> loud invariant failure
```

### Step 6: Repeat This Exact Experiment

Run the same roguelike task without external defect hints. The acceptance test
is no longer whether Plan says `ACCEPT`. It is:

```text
the exact sealed artifact receives an accepted body QA verdict;
the first-render-only false green is rejected;
the lineage produces a fresh generation;
the accepted generation survives the declared gameplay smoke contract.
```

## 9. Do Not Regress

The next implementation must preserve:

```text
candidate seal finality
fresh root per rejected recovery generation
private one-use source authority
no command string or host path in Packet data
provider witness is not body truth by itself
source stability before and after execution
receipt/body split-brain detection
candidate rejection != infrastructure failure
observer/instrumentation has zero Packet mass
Lua/native invariant failures remain loud
```

It must not:

```text
feed external QA prose into Plan as if it were body evidence;
let Plan self-accept software;
let the substrate manufacture qa_check or qa_verdict;
turn the provider witness directly into router pressure;
patch a sealed generation;
call the existing fixed Lua profile a universal software QA system.
```

## 10. Handoff In One Paragraph

proc-17 can already plan, build one substantial artifact, seal exact repository
state and execute a fixed Lua QA profile inside a hardened read-only Linux
boundary. The provider can distinguish a clean fixture from a runtime error,
but the Packet body has no lawful reader for that fact. A real autonomous
Plan-Build experiment then produced a program that rendered successfully,
crashed on its first ordinary action and was nevertheless accepted by the next
Plan Packet. The next work is therefore not broader coding power or a smarter
prompt. It is to finish the hostile provider campaign, then carry the existing
private witness through an exact body-owned check/verdict/completion chain and
prove it with grown accepted, rejected and infrastructure-failure lives.
