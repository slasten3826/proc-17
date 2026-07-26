# Second QA Hand Threat Model

Status:

```text
layer: CHAOS
date: 2026-07-23
roadmap: 8.5.1 of 8.5.7
subject: first execution of a sealed software candidate
machinist decision: QA is the second body-owned hand
decision truth status: document_decision
TABLE authority: granted as the next step
CRYSTALL authority: forbidden until TABLE closes the contracts
implementation authority: none
QA execution authority: absent
router/pressure authority: unchanged
CLI/TUI authority: deferred
progression note 2026-07-23:
  TABLE gate closed by docs/00_chaos/qa_table_cross_audit_2026-07-23.md
  CRYSTALL gate closed by docs/00_chaos/qa_crystall_cross_audit_2026-07-23.md
  retain the original authority lines above as the step-8.5.1 historical state
  candidate execution remains absent; only hostile-red step 8.5.4 is next
```

Primary sources:

```text
docs/00_chaos/first_repository_hand_threat_model_2026-07-19.md
docs/00_chaos/candidate_seal_finality_and_post_seal_alignment_notes_2026-07-22.md
docs/02_crystall/blueprints/candidate_seal_transaction.v0.md
docs/02_crystall/blueprints/completion_scope.v0.md
docs/02_crystall/blueprints/work_layer_projection.v0.md
docs/02_crystall/blueprints/stage_transition_generation_recovery.v0.md
core/sandbox.lua
logic/spells.lua
```

This document grants no command execution. It names the safety boundary and
the missing proof required before the body may execute software that it just
created.

## 0. Decision And Current Boundary

The first repository hand can perform one exact create-no-replace effect,
independently read the result, complete the work item and seal the candidate.
The body can now prove:

```text
these exact files were built
their final bytes matched the authorized actions
the declared artifact set was complete
source-write authority was terminally closed
this exact candidate seal exists and remains final
```

It cannot yet prove:

```text
the software parses
the software starts
the required tests pass
the components work together
the sealed candidate satisfies an executable QA contract
```

Therefore the next hand is QA:

```text
sealed candidate -> isolated execution -> exact check evidence -> final verdict
```

Roadmap note: `docs/03_manifest/current_state.md` still names CLI/TUI as the
next target. That roadmap paragraph predates steps 8.1-8.4 and this machinist
decision. Its runtime claims remain evidence, but its `next` marker is
superseded by this chapter and must be amended when the new roadmap returns to
MANIFEST.

The phrase `read-only QA hand` describes only its relationship to the sealed
source. It does not describe its danger. The hand executes potentially hostile
code and therefore receives process, CPU, memory, temporary-storage and
toolchain effects. It is a larger host-security boundary than the first file
write.

## 1. Safety Position

The default state remains:

```text
everything is denied
```

The current `core/sandbox.lua` correctly denies every command. That denial
stays authoritative until this chapter earns one narrower exception.

The candidate exception is not `run_command`. It is one structured act:

```text
given one exact current candidate seal
and one exact aligned body projection
and one host-authorized QA contract
and one exact required check from that contract
and one private one-use QA lease

start one trusted sandbox supervisor
construct one isolated execution environment
expose the sealed source as read-only
expose one bounded disposable scratch area as writable
invoke one named toolchain profile without a shell
enforce process, time, memory, storage, output and network bounds
reap the entire process tree
revalidate the sealed source boundary
emit one strictly validated bounded provider report
append one immutable body-owned QA check record
```

Anything broader returns to TABLE. Missing OS primitives do not authorize
`io.popen`, `os.execute`, a shell wrapper, an unsandboxed child or a weaker
provider under the same protocol name.

## 2. Non-Goals And Claim Ceiling

QA v0 does not prove that software is universally correct, secure, maintainable
or free of technical debt. It proves only that one exact sealed candidate
produced exact outcomes under one exact declared QA contract and environment.

The second hand does not:

```text
patch or rewrite the sealed source
run a command proposed directly by the substrate
grant a general shell
grant network access
install or download dependencies
reuse the host user's HOME, environment, credentials or agent sockets
execute in the proc-17 Lua process
load candidate native code into the proc-17 process
accept candidate-authored prose as a verdict
let a self-authored test suite define its own sufficiency after the fact
resume QA against an ancestor root after Packet death
write software_accepted from a living Packet
turn sandbox corruption into an ordinary failed test
```

Passing QA advances only to a Packet-local terminal candidate. The later corpse
and lineage assessment own software acceptance.

## 3. Trust Boundary

### 3.1 Untrusted inputs and actors

For containment, all of the following are hostile or non-authoritative:

```text
the generated program
every source file and test file inside the sealed candidate
filenames, module names and data files in the candidate
user prompt and substrate output
LLM-proposed commands, expected results and test descriptions
candidate stdout, stderr, exit code claims and structured output
environment variables requested by the candidate
paths requested by the candidate
the candidate's child processes and process tree
provider reports before strict adapter validation
old QA records, foreign seals and foreign generations
```

A generated test may be useful evidence. It does not own the rule that says
which tests are required or what counts as sufficient QA. That rule belongs to
a prior accepted process/stage contract or explicit host policy.

### 3.2 Trusted computing base

Any production proof necessarily trusts:

```text
the running Linux kernel and selected isolation primitives
the proc-17 host process and accepted Lua body
the private QA capability registry
the exact accepted sandbox supervisor/provider binary
the host authority that selects an admitted QA environment/profile
the deterministic QA check and verdict validators
```

The candidate toolchain is not trusted to report its own containment. The
supervisor owns process creation, isolation, measurement, timeout and cleanup.

### 3.3 Explicitly out of scope

QA v0 cannot defend against:

```text
a compromised kernel or CPU
arbitrary native code execution already inside the proc-17 host process
an administrator replacing proc-17 or the admitted sandbox provider
kernel/toolchain vulnerabilities that escape the selected sandbox
physical or firmware attacks
host actors with independent equivalent authority mutating the repository
side channels not bounded by the selected Linux isolation profile
```

These exclusions are residual risks, not evidence that an unsandboxed process
is acceptable.

## 4. Protected Assets

| ID | Asset | Required protection |
|---|---|---|
| QA-AS01 | sealed candidate source | never writable by QA; exact seal remains final |
| QA-AS02 | host filesystem | no visibility except named read-only runtime/source surfaces and scratch |
| QA-AS03 | other repositories, sessions and lineages | absent from namespace and capability resolution |
| QA-AS04 | host network and local sockets | no usable network namespace, inherited socket or agent socket |
| QA-AS05 | host credentials and secrets | no inherited environment, HOME, keyring, config, tokens or secret files |
| QA-AS06 | proc-17 process and private handles | no shared address space, ptrace, inherited descriptors or serialized handles |
| QA-AS07 | process availability | bounded CPU, wall time, memory, PIDs, descriptors and output |
| QA-AS08 | disk availability | bounded scratch bytes, files/inodes and cleanup |
| QA-AS09 | audit truth | request, launch, result, check and verdict remain separate facts |
| QA-AS10 | lineage truth | no foreign seal/check/verdict can advance current generation |
| QA-AS11 | source identity | exact pre/post source evidence remains bound to the candidate seal |
| QA-AS12 | verdict authority | only deterministic body logic over complete exact check records may decide |

## 5. Authority Flow

Semantic meaning and execution authority travel through separate channels:

```text
semantic channel:
  plan/process contract -> proposed QA intent and expected software behavior

policy channel:
  accepted stage contract or explicit host policy
    -> immutable qa_contract
    -> exact required check ids and admitted profiles

candidate channel:
  immutable candidate seal + aligned current body projection

authority channel:
  trusted host configuration
    -> private QA registry
    -> exact one-use check lease
    -> sandbox supervisor

intersection:
  qa_contract + check + seal + alignment + private lease
    -> one bounded isolated execution
```

The Packet may carry public ids. It never receives namespace handles, process
handles, open descriptors, cgroup handles, mount handles, supervisor secrets or
raw host paths.

## 6. QA Contract Ownership

The required QA contract must exist before its result can be known. It cannot
be silently weakened after a check fails.

Candidate sources of a lawful contract are:

```text
an accepted prior PLAN stage bound through lineage
an explicit host-supplied build-only contract
a future versioned project policy admitted by the host
```

The build Packet or substrate may propose tests, but proposal is not authority.
The TABLE round must assign one writer and one reader for:

```text
qa_contract
required check declarations
environment/profile selection
check request
provider execution report
body qa_check record
final qa_verdict
```

At minimum, a QA contract must bind:

```text
qa_contract_id and protocol version
process_contract_id, stage_id and lineage identity
the admitted environment/profile id
an ordered exact set of required check declarations
the success condition for each check
hard resource ceilings
whether bounded output content is evidence or diagnostics only
```

The exact point at which this contract becomes immutable is a TABLE question,
but it must be no later than the first QA capability grant.

## 7. Candidate And Seal Binding

No QA request is eligible unless all of these are true at dispatch:

```text
one valid current candidate-seal event exists
candidate root authority is sealed
candidate alignment is aligned
Packet, lineage, generation, stage and repository ids agree
qa_contract belongs to the same stage/process contract
the requested check is required by that contract
no current conflicting check record exists
```

The same conditions are re-read before the final verdict. If body alignment
diverges after checks but before verdict assembly, accepted evidence remains
historical but cannot advance the candidate.

The sealed-root registry prevents proc-17 source writes. The QA sandbox must
independently prevent writes by the executed program. These are two different
authorities and neither substitutes for the other.

## 8. Execution Isolation Contract

The exact mechanism remains a TABLE decision, but a production Linux provider
must prove equivalent properties to:

```text
separate process and address space
no_new_privs before candidate code
private user, mount, PID and network views where supported by the chosen model
no usable network interface or inherited socket
read-only exact source view
bounded writable scratch and temporary directories only
minimal admitted runtime/toolchain view, read-only
sanitized fixed environment
fixed working directory
no inherited file descriptors except supervisor-owned stdio channels
no ptrace or access to host process namespace
syscall restrictions appropriate to the admitted profile
bounded CPU, wall time, memory, PIDs, descriptors, file size and scratch usage
whole-process-tree termination and reaping
strict cleanup or typed quarantine on ambiguity
```

Names such as namespace, seccomp, Landlock, cgroup, rlimit, chroot or a helper
program are not proof by themselves. The TABLE and hostile battery must name
the exact primitive, kernel assumption, fallback policy and observable failure.

If one required primitive is absent, the provider is unavailable. It may not
fall back to a broad child process.

## 9. Source And Scratch Law

The sealed source and QA scratch have opposite permissions:

```text
sealed source
  exact candidate bytes
  read-only to every QA process
  no cache, build output, coverage file or temp file may appear inside it

scratch
  empty or exactly initialized by the trusted supervisor
  writable only inside the QA namespace
  bounded by bytes and object count
  disposable after one check or exact check transaction
  never treated as delivered source
```

Writable overlays over the source are rejected for v0. They would permit the
program to alter the code it is being tested against and pass on a form that is
not the sealed candidate.

Toolchains that require in-tree writes are not automatically supported. The
first profile must support explicit out-of-tree cache/build/temp paths, or it
is outside v0.

Before launch, the provider must bind the exposed source view to the exact seal
inventory. After the process tree is reaped, it must prove at least that the QA
view did not gain write authority and that the body-visible seal remains the
same. Whether v0 performs a second full inventory or executes from a verified
private read-only snapshot is an open TABLE choice.

## 10. Toolchain And Invocation Law

The public request cannot express a command string.

It may express only a typed profile and bounded arguments already allowed by
the QA contract:

```text
profile_id
check_id
sealed relative entrypoint or target refs
fixed argument slots admitted by the profile
fixed expected outcome class
fixed resource ceilings no broader than host policy
```

Forbidden request surface:

```text
shell text
redirections, pipes or substitutions
PATH lookup
caller-selected absolute executable
caller-selected cwd, HOME, TMPDIR or environment keys
arbitrary file-descriptor mapping
arbitrary mount or network options
unbounded stdin, stdout or stderr
```

The admitted toolchain/runtime must have a stable host-owned identity. A name
such as `lua`, `python`, `node` or `make` is not enough. The TABLE round must
decide whether environment identity binds an executable, a versioned runtime
image, a provider build id or a stronger measured set.

The first QA profile should be one exact Linux-only profile. General command
execution and multi-tool project pipelines remain deferred.

## 11. Process And Resource Law

The supervisor, not the candidate, owns completion of the check transaction.

It must bound and report:

```text
launch count
wall duration
CPU consumption where the selected mechanism can prove it
peak/current memory where provable
process count
open-descriptor ceiling
scratch bytes and object count
stdout and stderr observed byte counts
retained diagnostic byte counts
termination reason and signal/exit status
cleanup result
```

Output capture must drain without unbounded allocation or pipe deadlock. Raw
unbounded logs never enter trace, corpse, grave or prompt. A future check record
may retain bounded diagnostic fragments plus full-stream digests and counts;
the exact policy belongs to TABLE.

A timeout, memory limit, PID limit, denied syscall or output limit reached by a
successfully contained candidate is candidate behavior and may become typed QA
rejection. Failure to enforce, measure, terminate or clean the sandbox is not a
candidate failure; it is infrastructure ambiguity or trusted invariant failure.

## 12. Outcome Taxonomy

At least five classes must remain distinct:

| Class | Example | Body consequence |
|---|---|---|
| denied/not ready | no seal, diverged alignment, missing contract/profile | no provider call and no QA cost |
| candidate accepted check | expected result observed inside proven bounds | immutable accepted check evidence |
| candidate rejected check | assertion/exit/resource/policy result proves contract failure | immutable rejected check evidence |
| infrastructure/world failure | toolchain unavailable, sandbox could not start, cleanup ambiguous | typed failure/incomplete QA; never accepted or candidate-rejected by convenience |
| trusted invariant failure | malformed provider result, impossible measurement, identity contradiction | loud harness failure; no honest Packet death or verdict |

TABLE must decide the exact boundary for timeout, signal, OOM and denied syscall,
but the decision must follow named evidence. It cannot depend on error text.

No final verdict exists while any required check is missing, infrastructure-
incomplete or contradictory.

## 13. Evidence And Truth Law

The body requires separate immutable records:

```text
qa_check_request
  body-owned authorization request; no execution claim

qa_provider_report
  strictly validated trusted adapter result; not yet body truth

qa_check
  body-owned runtime-confirmed observation bound to exact request/seal/contract

qa_verdict
  deterministic assembly over the complete exact required check set
```

The substrate may summarize diagnostics or propose a repair. That content stays
`semantic_proposal`. It cannot change check state or verdict.

An accepted final verdict requires:

```text
the same exact current seal
current candidate alignment = aligned
one exact current qa_contract
exactly one current valid qa_check for every required check id
every required check accepted
no foreign, stale, missing or conflicting refs
one deterministic verdict identity
```

A rejected final verdict requires at least one exact candidate-rejected check
and complete disposition of the required set according to the contract. The
TABLE round must decide whether fail-fast creates an explicit skipped tail or
whether all checks always run; silence cannot masquerade as completion.

## 14. Lifecycle And Finality

The intended same-life v0 sequence remains:

```text
build files
-> independently verify work
-> complete artifact set
-> seal candidate and close source writes
-> execute bounded read-only QA
-> assemble final QA verdict
-> manifest exact accepted/rejected evidence
-> Packet dies
-> corpse and lineage decide acceptance or recovery
```

An accepted living Packet may only expose
`software_acceptance_ready, terminalized=false`. It cannot write
`software_accepted`.

A rejected living Packet must assemble one exact rejected-generation terminal
projection. The next build is a new Packet in a fresh repository. It does not
patch the old root.

If the Packet dies from budget or loss before a final verdict, the candidate is
not accepted. Existing stage law selects a fresh build generation rather than
resuming QA against the ancestor sealed root.

## 15. Deny Matrix: Authority And Identity

Evidence states in this document:

```text
EXISTING  already proved by current seal/body contracts
NEW-RED   step 8.5.4 must add the control before implementation
AUDIT     source/schema inspection is also required
OPEN      TABLE must close the exact contract first
```

| ID | Attempted widening | Required result | Evidence |
|---|---|---|---|
| QA-A01 | QA absent/disabled | no provider load, process, trace, route or budget delta | NEW-RED |
| QA-A02 | unsealed candidate | no QA capability or provider call | EXISTING reader + NEW-RED |
| QA-A03 | diverged current alignment | no QA dispatch or acceptance | EXISTING SF/CS/WL + NEW-RED |
| QA-A04 | substrate names profile/check/grant id | zero authority | NEW-RED |
| QA-A05 | foreign Packet, lineage, generation, stage or repository | no capability match | NEW-RED |
| QA-A06 | foreign or stale candidate seal | no capability match/check advancement | NEW-RED |
| QA-A07 | caller mutates public QA projection | revalidation restores/rejects | NEW-RED |
| QA-A08 | one-use check lease is replayed | no second launch | NEW-RED |
| QA-A09 | check not required by current contract | no launch and no verdict contribution | NEW-RED |
| QA-A10 | contract changes after first grant/result | reject as a different contract; no laundering | OPEN + NEW-RED |
| QA-A11 | private supervisor/process handle enters trace/corpse/carrier | impossible projection | AUDIT + NEW-RED |
| QA-A12 | QA output asks for another capability | ignored as data | NEW-RED |

## 16. Deny Matrix: Invocation And Host Isolation

| ID | Threat | Required result | Evidence |
|---|---|---|---|
| QA-I01 | shell metacharacters or command string | unrepresentable/rejected before launch | NEW-RED + AUDIT |
| QA-I02 | PATH/cwd/module lookup substitutes supervisor or toolchain | exact trusted identity only | NEW-RED + AUDIT |
| QA-I03 | candidate reads host HOME/config/keys/tokens | absent from namespace/environment | NEW-RED |
| QA-I04 | candidate reads proc-17 stores, `.git`, `.agents`, `.codex` | absent from namespace | NEW-RED |
| QA-I05 | candidate opens network/socket/agent connection | denied with no inherited endpoint | NEW-RED |
| QA-I06 | candidate ptraces/signals host processes | isolated/denied | NEW-RED |
| QA-I07 | inherited descriptor leaks repository or control authority | only exact stdio channels survive | NEW-RED + AUDIT |
| QA-I08 | candidate loads malicious native module into proc-17 | separate process; never host-process loading | NEW-RED + AUDIT |
| QA-I09 | required isolation primitive unavailable | provider unavailable, no fallback | NEW-RED |
| QA-I10 | malformed/wrong-ABI sandbox provider | loud harness failure | NEW-RED |
| QA-I11 | legacy `logic/spells.lua` command path is reused | forbidden structurally | AUDIT |
| QA-I12 | generic `sandbox.can_run_command` is widened | forbidden; QA uses separate typed capability | AUDIT |

## 17. Deny Matrix: Source, Scratch And Process Tree

| ID | Threat | Required result | Evidence |
|---|---|---|---|
| QA-S01 | candidate writes/renames/deletes source | denied; seal and bytes unchanged | NEW-RED |
| QA-S02 | toolchain writes cache beside source | redirected to bounded scratch or profile unavailable | NEW-RED |
| QA-S03 | writable overlay lets candidate rewrite tested form | treatment rejected | AUDIT |
| QA-S04 | source symlink/magic-link escape | exact seal inventory and isolated view only | NEW-RED |
| QA-S05 | candidate accesses another scratch/session | namespace denial | NEW-RED |
| QA-S06 | scratch fills disk or inode table | hard bound, typed result, cleanup | NEW-RED |
| QA-S07 | fork bomb or daemon survives parent | PID bound plus whole-tree kill/reap | NEW-RED |
| QA-S08 | infinite loop | wall/CPU bound and whole-tree termination | NEW-RED |
| QA-S09 | memory bomb | memory bound; host remains available | NEW-RED |
| QA-S10 | stdout/stderr flood | bounded drain/digest/retention without deadlock | NEW-RED |
| QA-S11 | candidate closes/rebinds stdio | supervisor still obtains typed termination evidence | NEW-RED |
| QA-S12 | cleanup is ambiguous | quarantine scratch/check authority; no verdict | NEW-RED |

## 18. Deny Matrix: Evidence And False Green

| ID | False-green path | Required result | Evidence |
|---|---|---|---|
| QA-E01 | process prints `passed` | no authority without exact check result contract | NEW-RED |
| QA-E02 | exit zero with missing required checks | no final verdict | NEW-RED |
| QA-E03 | rejected check omitted from final set | verdict identity/required-set mismatch | NEW-RED |
| QA-E04 | accepted and rejected records for same check | loud contradiction or explicit supersession law | OPEN + NEW-RED |
| QA-E05 | old generation's accepted check reused | no advancement | NEW-RED |
| QA-E06 | check for another seal reused | no advancement | NEW-RED |
| QA-E07 | malformed provider success/error report | loud harness failure | NEW-RED |
| QA-E08 | timeout/kill is reported as normal exit zero | loud impossible evidence | NEW-RED |
| QA-E09 | retained output is truncated but presented as complete | explicit counts/truncation; cannot satisfy exact-output check | NEW-RED |
| QA-E10 | caller mutates returned check/verdict | stored body evidence unchanged | NEW-RED |
| QA-E11 | LLM says failure is harmless | semantic proposal, zero verdict delta | NEW-RED |
| QA-E12 | QA observer changes route/budget/loss while disabled | exact ablation equality | NEW-RED |
| QA-E13 | sandbox infrastructure failure becomes `qa_rejected` | typed incomplete/infrastructure result, never candidate verdict | NEW-RED |
| QA-E14 | candidate rejection becomes harness crash | exact rejected check evidence, body remains coherent | NEW-RED |

## 19. Economics And Retry Law

QA is not free merely because it cannot write source.

The body must account for bounded observed execution cost separately from
identity loss:

```text
one check dispatch consumes tool-call/QA execution budget
wall/CPU/resource observations are runtime-confirmed only where measured
scratch writes are QA economics, not repository source-write authority
cycle/retry consumes lineage and Packet economics
QA execution itself creates no identity loss merely by running
semantic interpretation of logs may consume substrate tokens separately
```

Exact replay of a completed request returns the same body evidence without a
second process. A changed request, contract, seal, profile or resource envelope
is a new identity and requires fresh authority.

No provider-internal retry of a candidate process is authorized. Retry belongs
to body/lineage policy and must read prior check evidence and remaining budget.

## 20. Test-Harness Safety

The hostile battery will itself execute malicious fixtures. Its harness must
not become the unsafe QA hand.

| ID | Harness threat | Required result |
|---|---|---|
| QA-T01 | malicious fixture escapes because test uses ordinary `lua`/shell | fixture runs only through candidate sandbox provider |
| QA-T02 | fixture path is host-selected by untrusted text | constant/test-owned identity only |
| QA-T03 | cleanup follows substituted scratch/root | identity-owned bounded cleanup; refuse ambiguity |
| QA-T04 | network/namespace test is silently skipped | explicit SKIP and containment claim withheld |
| QA-T05 | production provider exposes fault hooks | symbol/API audit rejects |
| QA-T06 | failed test leaves processes, mounts, cgroups or scratch | leak scan and identity-owned cleanup |
| QA-T07 | sanitizer/fault build becomes production provider | fail-closed loader identity and artifact audit |
| QA-T08 | test requires broad sudo/root without naming it | explicit environmental prerequisite; no green claim |

The first contact must occur only inside a disposable harness-owned root with
sentinels inside the test fixture but outside every granted QA view.

## 21. Discovered Pre-Execution Blockers

Step 8.5.1 identifies these blockers before TABLE:

| Blocker | Why QA execution is forbidden until resolved |
|---|---|
| QB1 QA contract provenance | current runtime has no immutable owner for required checks |
| QB2 sandbox primitive set | `sandbox.v0` denies commands but provides no isolated execution exception |
| QB3 legacy command path | `logic/spells.lua` uses `io.popen` and cannot become the QA provider |
| QB4 trusted supervisor/toolchain identity | a command/profile name can be substituted by host/task lookup |
| QB5 source-view construction | sealed registry state alone does not create an OS read-only namespace |
| QB6 scratch and cache policy | common toolchains write caches/build products and need bounded out-of-tree paths |
| QB7 process/resource enforcement | timeout alone does not contain memory, PIDs, output, descendants or disk |
| QB8 result taxonomy | candidate failure, infrastructure failure and invariant failure need distinct writers |
| QB9 check/verdict schemas | completion/work-layer readers exist, but their QA records do not |
| QB10 exact environment identity | executable name/version alone may not bind dynamic runtime/dependencies |
| QB11 pre/post source evidence | QA must not judge a source view that drifted from the exact seal |
| QB12 hostile harness | malicious fixtures need isolation before they can test isolation |

These are expected pressures, not regressions in the first hand or candidate
seal.

## 22. TABLE Questions

The next layer must answer without implementation invention:

```text
Q1  Who writes qa_contract for plan-only, build-only and software.create lives?
Q2  At what exact event does qa_contract become immutable?
Q3  What is the first admitted Linux QA profile and how is its identity bound?
Q4  Which exact isolation primitives are mandatory and what is the no-fallback law?
Q5  How is the exact sealed source view constructed and revalidated?
Q6  What scratch paths, byte/object bounds and cache redirects exist?
Q7  What structured fields can a check request express without becoming a command API?
Q8  Which measurements distinguish accepted, rejected, infrastructure and invariant outcomes?
Q9  Are timeout, signal, OOM, syscall denial and output limit candidate rejection or incomplete QA?
Q10 Does v0 run all checks or fail fast with explicit typed skipped records?
Q11 What bounded stdout/stderr material, digests and counts enter qa_check?
Q12 How are check request/report/body event identities composed and made idempotent?
Q13 How does final verdict bind required checks, seal, alignment, contract and environment?
Q14 What exact economics are charged to Packet and lineage?
Q15 Which private handles and lifecycle states exist, and who reads each one?
Q16 Which hostile controls require native/fault/environmental fixtures?
```

## 23. Candidate Minimal v0 Slice

The smallest useful implementation target appears to be:

```text
Linux only
one fail-closed trusted sandbox supervisor/provider
one host-admitted toolchain/environment profile
one exact sealed candidate source view, read-only
one bounded scratch view
no network
no shell and no generic command API
one process-tree transaction per required check
one exact structured check request family
bounded output digests/counts and optional diagnostic tails
one immutable qa_check body event
one deterministic final qa_verdict assembler
completion/work-layer readers in shadow or explicitly gated mode
```

The exact first profile is intentionally not chosen in CHAOS. TABLE must select
one profile whose cache, dependency, process and filesystem behavior can be
tested without weakening the laws above.

## 24. Acceptance Gate For Second Contact

No production QA process is authorized until:

```text
QB1-QB12 each has an explicit treatment or bounded rejected claim
the public request cannot represent shell, arbitrary executable, cwd or env
the provider has one exact fail-closed trust root and ABI
the sealed source is demonstrably read-only to candidate processes
host files, secrets, network, sockets and proc-17 handles are absent
scratch, CPU, wall, memory, PID, descriptor and output bounds are enforced
the entire process tree is reaped under success, rejection, timeout and panic
provider/infrastructure corruption remains loud or typed incomplete
candidate test failure becomes exact rejected evidence, not runtime corruption
every required check has one named writer and final-verdict reader
accepted verdict requires exact current seal and aligned body evidence
QA disabled produces zero behavior and host-effect delta
the hostile harness proves containment without broad cleanup authority
```

Only then may one sealed disposable candidate be executed. A successful run
returns to the four-layer process for canonization; it does not automatically
promote QA or software acceptance authority.

## 25. Chapter Position

```text
8.5.1 Chaos threat model for the second QA hand                complete by this note
8.5.2 TABLE contracts: QA contract/check/verdict/capability    next
8.5.3 CRYSTALL exact schemas and authority boundaries          blocked by 8.5.2
8.5.4 preimplementation hostile red battery                    blocked by 8.5.3
8.5.5 minimal isolated QA hand                                 blocked by 8.5.4
8.5.6 completion/work-layer/manifest readers                  blocked by 8.5.5
8.5.7 grown accepted/rejected/infrastructure-error lives       blocked by 8.5.6
```

CLI/TUI remains outside this chapter. The body must first learn to judge one
sealed candidate without granting that candidate the host.

### Step 8.5.4 Runtime Amendment

Date: 2026-07-23.

The preimplementation hostile red battery is now complete. Runtime-observed
results, the inert fixture contract and the exact next gate are recorded in:

```text
docs/00_chaos/second_qa_hand_red_battery_results_2026-07-23.md
```

This amendment changes the roadmap state of 8.5.4 from blocked/next to complete.
It grants no candidate process authority; 8.5.5 remains the first implementation
boundary.

## 26. Thesis

```text
The first hand lets the body write one exact thing.
The second hand lets it expose that thing to consequence.

Read-only source is not harmless execution.
QA becomes truth only when the candidate is contained, the check is owned,
the evidence is exact and no failure class is allowed to impersonate another.
```
