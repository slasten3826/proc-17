# Capability-Safe Repository Hands Notes - 2026-07-19

Status:

```text
layer:          CHAOS (⋯)
document_role: treatment pressure / audit synthesis
source:         proc17 capability handoff + Codex step-1 code audit
authority:      hypotheses and non-negotiable boundary laws
code_changed:   no
router_changed: no
next_layer:     capability/action/effect/evidence/failure TABLE
```

## Trigger

proc-17 can form exact work, collapse alternatives, validate runtime evidence,
die honestly and continue one task through a descendant. It still cannot do the
one thing that turns process physics into a coding worker:

```text
selected work does not change a repository
```

The missing layer is not a generic tool API. It is a narrow physical boundary
between body-owned intention and an external effect.

The current path is still caller-owned:

```text
harness options.logic.spells
  -> ☶ LOGIC
  -> logic/spells.lua
  -> io.popen / host filesystem
  -> spell result
```

The target path must become body-owned:

```text
exact Packet work
  -> body-owned action
  -> optional real alternative collapse
  -> host-owned capability grant
  -> bounded hand effect
  -> independent read-back evidence
  -> ☱ confirmed progress
  -> exact work unit done
```

## Audit Status And Epistemic Honesty

Step 1 read every production Lua path that opens, writes, removes or executes
external state. It did not run an ad hoc escape payload.

The following are implementation facts:

```text
core/sandbox.lua checks path spelling, not resolved filesystem identity
tools/fs.lua reads and writes with raw io.open
logic/spells.lua invokes commands through io.popen
check_command_exit_code does not call sandbox.can_run_command
☶ declares no required external capability
the runner passes route capabilities and execution capabilities inconsistently
tools/fs.lua has no production caller
trace_store and packet_memory are standalone or partially integrated
no production writer changes a calm work unit to done
tests create done work manually through body.apply_crystallized_work
```

The following are strongly derived risks and must become runtime-confirmed red
tests before treatment:

```text
a symlink below sandbox can redirect raw io.open outside the intended root
a check-then-open create_only write can race its precondition
an arbitrary command spell can mutate state while reporting reality_changed=false
a hand granted the whole sandbox could rewrite sessions, graves or Packet memory
an unconstrained trace_store path can bypass a future repository capability
```

Static derivation is enough to define pressure. It is not a substitute for the
red battery in step 5.

## The Missing Entities

The next layers need to keep six entities separate.

### 1. Work unit

A body-owned statement of required work. It has identity, version, provenance,
content truth status and a lifecycle. Current work units have `pending` and
test-only `done`; executable work needs a stricter contract.

### 2. Capability grant

A host-owned authorization to affect one concrete external resource in bounded
ways. It is not prose, a boolean name, a path supplied by the substrate or a
secret that becomes valid merely because the Packet knows it.

### 3. Action envelope

An immutable body-owned instruction derived from one exact work unit under one
exact capability reference. It describes one effect and its preconditions.

### 4. Hand

A deliberately stupid executor. It receives a validated action envelope and a
resolved grant, performs no routing or semantic interpretation, and cannot see
or mutate the Packet.

### 5. Effect receipt

A body record of what the executor attempted and observed. It proves that an
attempt occurred. By itself it does not prove that the requested reality now
exists.

### 6. Verification evidence

A fresh, independently obtained observation of the external referent after the
attempt. Only matching evidence may support progress.

Collapsing any two of these recreates the current harness shortcut.

## Boundary Law In One Line

```text
The Packet may form and select an action.
Only the host may grant power.
The hand may execute only the exact intersection of both.
```

## Authority Laws

### The substrate cannot mint power

The LLM may propose:

```text
create src/main.lua with these bytes
run this test
I need access to repository X
```

None of those statements is a capability.

```text
semantic proposal != authorization
path text != repository identity
knowing capability_id != owning the grant
```

### The Packet does not own the grant registry

The trusted runner/session should own the real capability registry. The Packet
may carry an immutable public projection and `capability_id`, but it must not
carry a mutable authority object that substrate-facing code can copy or forge.

The registry resolves an id only from trusted execution context. The same id in
substrate prose or Packet CALM creates no authority.

### Authority is narrower than mode

`work_mode = build` says that effects may be meaningful. It does not authorize
an effect. `manifest` mode in `core/modes.lua` is a documentation workflow mode,
not a repository security capability.

Plan mode must never acquire a repository mutation hand.

## Repository Isolation Laws

### One grant names one repository root

The current word `workspace` means the entire `sandbox/` tree. That tree also
contains sessions, Packet capsules, graves, smoke artifacts and historical test
data. It is too broad to be a hand boundary.

A repository capability must resolve one explicit project root, conceptually:

```text
sandbox/projects/<repository-id>/
```

The exact directory convention is not yet law. The isolation is.

The hand must have no route to:

```text
sandbox/sessions
sandbox/packets
grave or compost storage
trace storage
.git
.agents
.codex
another repository capability root
```

Git control access may become a separate later capability. It is forbidden in
the first file hand.

### Relative names do not prove containment

Containment must be checked against filesystem identity, not string prefix.

At minimum the future path law must address:

```text
absolute paths
empty and NUL-containing paths
`.` and `..` components
hidden control components
symlink root, parent and final component
nonexistent final targets
path replacement between validation and write
hard-link and cross-device policy
path and content size bounds
```

The current Lua environment has neither LuaFileSystem nor luaposix. Coreutils
`realpath`, `readlink` and `stat` exist, but check-then-open cannot eliminate a
race by itself. The TABLE/CRYSTALL stages must choose honestly between:

```text
a fixed audited helper with no-follow/open-at semantics
or an explicitly weaker local Linux v0 with a named race limitation
```

No implementation may claim a stronger boundary than its primitive provides.

## Action Identity Laws

One action must bind at least:

```text
Packet id
lineage id and generation
work unit id and exact version
capability id and grant revision
operation kind
repository-relative target
content length and digest when content exists
precondition on the target
bounded policy values
provenance and selected-choice refs when a real choice occurred
content truth status
```

The body can derive a canonical action id with the existing SHA-256
implementation. Changing any bound field must create another action, not mutate
history.

The executor receives a deep copy of the action and a resolved read-only grant
view. It never receives the Packet table.

## First V0 Candidate

The smallest useful action appears to be:

```text
create one absent regular file
inside one already existing repository root and parent directory
with exact bounded bytes
using an absent-target precondition
```

This is a candidate for TABLE, not yet a crystall contract.

The first hand should not support:

```text
overwrite
append
delete
rename
chmod
directory creation
git mutation
arbitrary command execution
subprocess tests
multiple files in one action
```

Requiring an existing parent keeps the first effect singular. Directory creation
can become a different action later.

## Operator Placement

HAND is not an eleventh ProcessLang operator and gains no topology edge.

The existing tree already contains the required adjacency, but there are two
different lives that must not be collapsed.

With real alternatives:

```text
☵ forms executable work
☳ collapses more than one executable alternative
☳ -> ☶ is a canonical edge
☶ applies the bounded spell/effect contract and records fresh evidence
☶ -> ☱ lets runtime reconcile what actually happened
☱ may confirm the exact work unit as done
```

With one uncontested action:

```text
☵ forms one executable work unit
☳ is not invoked because confirmation is not choice
☵ -> ☱ -> ☶ is a canonical path available for qualification and execution
☶ -> ☱ reconciles the effect and evidence
```

The exact pressure witnesses for the uncontested path belong to TABLE. The
non-negotiable law is already known: the body must not invent alternatives just
to force every action through CHOOSE.

This is consistent with the earlier HOD/YESOD reading:

```text
☶ HOD   desire -> exact spell -> execution -> evidence
☱ YESOD evidence -> runtime foundation/progress
```

One ambiguity remains for TABLE: whether dispatch and independent read-back are
two explicit phases inside one ☶ tick or require two different ☶ visits with a
runtime observation between them. What is not ambiguous:

```text
the hand does not validate itself
☶ cannot mark the work unit done merely because dispatch returned success
☱ cannot mark done without exact fresh evidence
```

## Truth Laws

The same action carries several different truths:

```text
the substrate proposed these bytes             semantic_proposal
the body formed action A                       runtime_confirmed event
the host resolved capability C                 runtime_confirmed grant fact
the executor attempted A                       runtime_confirmed attempt fact
the executor reported a write                  runtime_confirmed receipt fact
the read-only verifier observed digest D       runtime_confirmed evidence fact
the bytes satisfy the user's broader intention still not proven by file existence
```

Event truth and content truth must remain separate. Writing semantic bytes does
not promote their meaning into runtime truth. Runtime only confirms which bytes
exist and which declared acceptance checks passed.

## Effect And Evidence Laws

### A receipt is not evidence of success

The write path and the verification path must be named separately.

```text
writer says success
  -> effect receipt

read-only verifier opens the granted target after the effect
  -> observed bytes, type, length and digest

declared evidence predicate matches action preconditions and expected effect
  -> accepted LOGIC evidence
```

The first verifier need not understand program semantics. For `create_file.v0`,
it can prove only:

```text
one regular file exists at the granted target
its bytes and digest exactly equal the action
the observation is fresh and tied to the action id
```

Compilation, tests and semantic acceptance are later evidence contracts.

### Progress needs its own event

`body.apply_crystallized_work` is currently a compatibility/test helper. It
changes work status without a producing body event, actor lease or evidence
reference. The hand treatment must not call it to manufacture progress.

The future progress transition must bind:

```text
work unit id and prior version
action id
effect receipt ref
accepted verification ref
new status
actor and visit
```

Only then may `body.progress`, ☲ and completion observe `done`.

## Economics And Loss

An exact hand spends runtime budget. Candidate axes already exist:

```text
tool_calls
file_writes
time_ms
test_runs later
```

An attempt pays only costs that actually occurred. Sandbox denial before an
external attempt must not invent a file write. A failed write still pays any
real attempt and time cost.

The first exact file hand should create no identity loss by itself. ENCODE paid
for representation and CHOOSE paid for killed alternatives. A hand that writes
different bytes from the sealed action is not lossy execution; it is a failed
effect or broken implementation.

## Failure Boundary

The existing three-way law applies unchanged.

### Not ready

Examples:

```text
no selected executable work
missing or revoked capability
stale work unit version
unsupported operation kind
unaffordable action
```

The candidate must be excluded before route commitment and before an effect.

### Typed effect failure

Examples:

```text
target already exists under an absent-target precondition
permission denied after a valid grant
disk full
external target changes before effect
read-back does not match the expected digest
```

This is Packet-world evidence. Actual costs remain paid. It must never create a
false `done` transition.

### Loud body or harness failure

Examples:

```text
malformed trusted action passes validation
executor returns an impossible receipt shape
action id changes after commitment
hand writes outside its resolved capability root
trace or progress is mutated without the owning actor/event
Lua invariant failure
```

These invalidate the run. They must not be turned into an honest Packet death,
grave or inherited lesson.

## Retry And Replay Pressure

Every effect must be replay-aware because a process can stop after the write but
before the receipt is committed.

The action id gives the body something stable to reconcile. TABLE must decide:

```text
absent target                       -> execute create
existing target with expected digest -> recover as already_applied or conflict
existing target with other digest    -> conflict
same action id with changed envelope  -> invariant failure
```

Blind retry is forbidden. So is treating every existing file as success.

## Existing Writers Are Different Authority Domains

The audit found other host writers:

```text
session_memory
packet_memory
trace_store
OpenAI-compatible request temp files
```

They are not repository hands. They need their own trusted storage/transport
boundaries and must never become alternate ways for a Packet action to mutate a
project.

`trace_store.write_jsonl(path, ...)` currently accepts an arbitrary path. It is
not integrated into the live body, so it does not block the first hand, but it
must be fenced before any product surface exposes it.

## Red-Battery Seeds

The later security battery must grow real cases, not synthetic success records.

```text
absolute path denied
parent traversal denied
dot/control component denied
root symlink denied
parent symlink denied
final symlink denied
repo-A capability cannot touch repo B
repository hand cannot touch sessions/packets/graves/trace
missing, revoked and stale capability denied before effect
plan mode cannot dispatch a mutation
unsupported operation and arbitrary command denied
stale work unit/action precondition denied
content length or digest mismatch denied
oversized path/content denied
pre-existing different target is conflict
malformed effect receipt fails the harness loudly
write receipt without read-back cannot mark done
read-back mismatch cannot mark done
accepted evidence for action A cannot finish work B
replay cannot duplicate or silently overwrite an effect
```

Tests must use a unique temporary repository root and clean only resources they
created. Fixed names under the user's general `sandbox/` are not acceptable.

## Falsifiers

Reject the treatment if any statement below remains true:

```text
the LLM can create authority by naming a capability
the Packet can forge or mutate the host grant registry
the hand can reach outside one granted repository root
the hand can mutate memory, graves, traces or another repository
the committed action path/content can change before execution
the executor receives the Packet table
one uncontested action is laundered into a fake ☳ choice
arbitrary shell is required for create_file.v0
an effect receipt alone marks work done
LOGIC trusts writer output without fresh read-back
☱ marks a different or stale work unit done
a denied action is counted as a successful write
a malformed trusted effect becomes Packet mortality
plan mode changes repository reality
normal hand-disabled lives change route, budget, loss or terminal outcome
```

## Open Questions For TABLE

1. Does a repository grant live for one Packet, one lineage or one session, and
   how is revocation projected into each descendant?
2. Which trusted primitive provides the first no-follow create operation in the
   current Lua environment?
3. Are dispatch and read-back two phases of one ☶ visit or two visits?
4. What exact evidence predicate authorizes the first `done` transition?
5. Which actor/API owns that transition, and how is the work-unit version
   advanced?
6. Is an existing file with the exact expected digest `already_applied`, or an
   absent-precondition conflict requiring explicit reconciliation?
7. Does the verifier use the same repository grant with a read operation, or a
   separately projected read-only grant?
8. Which capability facts are safe to expose to substrate context without
   confusing description with authority?
9. Which standalone internal writers must be fenced in the same sprint, and
   which remain unreachable non-goals?

## Non-Goals Of The First Hand

```text
arbitrary command execution
automatic dependency installation
git commit or push
multi-file transactions
overwrite/patch/delete
test runner
crash recovery and persistent lineage
semantic proof that generated code is good
CLI or TUI
default Tree-authority promotion
```

These are later capabilities, not hidden options on the first one.

## Next Layer

The TABLE document must turn this pressure into explicit rows for:

```text
capability identity and lifetime
repository root and path resolution
action schema and preconditions
executor input and effect receipt
read-only verification evidence
progress transition
budget charges
not-ready/effect-failure/invariant-failure outcomes
replay cases
red-test acceptance matrix
```

Only after those rows agree may CRYSTALL name modules and APIs.
