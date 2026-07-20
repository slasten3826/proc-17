# Repository Effect And Progress Manifest v0

Status:

```text
manifest
implemented and locally verified 2026-07-20
roadmap step: 7.7 of 7.10
source chaos plan: docs/00_chaos/first_repository_hand_effect_progress_plan_2026-07-20.md
source results: docs/00_chaos/first_repository_hand_effect_progress_results_2026-07-20.md
source table: docs/01_table/yellowprints/capability_safe_repository_hands_yellowprint.v0.md
source crystall: docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
scope: one exact create/read-back effect and exact work completion
router authority change: absent
decision truth status: document_decision
runtime evidence status: runtime_confirmed by listed tests
```

## Result

Proc-17 now has one narrowly bounded, deliberately callable repository hand.
Given a host-minted exact grant and a current canonical action, ☶ can create one
previously absent UTF-8 text file, independently reread that exact target, and
record bounded verification. A later ☱ visit can derive one immutable exact
work completion from the complete trace chain.

The physical sequence is:

```text
action
  -> effect attempt
  -> private one-use lease
  -> atomic create-no-replace
  -> writer receipt
  -> exact expected+1 read-back
  -> length/SHA-256 verification
  -> LOGIC validation
  -> RUNTIME work completion
  -> derived body progress
```

## Authority

Authority remains outside Packet state. The private capability registry owns
the provider and opaque repository handle. The action carries only a detached
grant projection and exact content referent.

`begin_effect` consumes one dispatch slot before provider entry. Its opaque
lease can create only the action target and read only the same target once. The
same action cannot be dispatched twice. Revoked or quarantined grants cannot
reach the provider. Ambiguous mutation residue quarantines and closes authority
before retry.

No API admitted by this manifest can:

```text
run a command or shell
choose an absolute/root path
overwrite, append, patch, rename, delete or mkdir
read an arbitrary repository path
reuse an effect lease
store a provider handle in Packet/trace
derive authority from semantic text
```

## Truth And Completion

The writer receipt is not verification. Verification is a separate read result
containing only target kind, byte length and SHA-256. Raw intended/observed bytes
remain transient and do not enter repository trace events.

Accepted verification is still not completion. Completion requires:

```text
current exact work unit/version
ordered attempt -> receipt -> verification -> accepted LOGIC validation
same action/grant/work refs at every stage
no later conflicting effect evidence
one current ☱ actor lease
```

For repository work, `body.progress` derives `done` only from the exact
`work_completion` event. Mutable compatibility status has no authority.

## Failure Boundary

```text
external provider denial or ambiguity -> typed effect_failure with actual cost
valid observed mismatch                -> rejected verification, no completion
malformed trusted record/invariant     -> loud harness error
```

The hand reports external economics but spends no identity loss. Central runner
charging waits for route integration and is not claimed here.

## Verification

```text
repository-effect                         14/14 green
repository-progress                        9/9 green
real production-provider effect chain      1/1 green
repository Linux provider                 29 green / 0 red / 1 environment skip
staged repository-hand suites             11 green / 1 route red / 12 total
ordinary registered Lua suites            80/80 green
native full fault battery                  green
GCC -fanalyzer                             green
ASan + UBSan                               green (LeakSan disabled)
```

The remaining red route suite is an acceptance condition, not hidden failure:
this step proves mechanics without granting the body automatic authority to
choose them.

## Deliberate Limits

This manifest does not claim:

```text
automatic qualified pressure for repository work
RUNTIME action review or automatic reconcile dispatch
operator-registry propagation of host repository services
router-owned ☵/☳ -> ☶ -> ☱ execution
runner charging of effect cost
multi-file scheduling or transaction recovery
commands, tests, git, patching or overwrite
manifest delivery of repository artifacts
```

## Next Boundary

Roadmap step 7.8 is a hostile audit of the demonstrated hand. No route or
operation widening is authorized until lease, provider, trace, failure,
resource and completion attacks remain fail-closed under that audit.

Update 2026-07-20: roadmap 7.8 completed this audit. Its current record is
[`repository_hostile_audit.v0.md`](repository_hostile_audit.v0.md). This 7.7
manifest remains the pre-audit mechanism record.
