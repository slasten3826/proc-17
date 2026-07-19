# Capability-Safe Repository Hands Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-07-19
chaos: docs/00_chaos/capability_safe_repository_hands_notes_2026-07-19.md
table: docs/01_table/yellowprints/capability_safe_repository_hands_yellowprint.v0.md
implementation authority: one absent regular text file in one granted repository
router authority change: forbidden
arbitrary shell: forbidden
overwrite/delete/mkdir/rename/patch: forbidden
```

## 0. Crystallized Claim

The first hand is one closed causal chain:

```text
exact current repository.create_text_file.v0 field unit
  -> pure intent
  -> exact host grant resolution
  -> immutable authorized action
  -> exact RUNTIME review when no real choice exists
  -> LOGIC effect attempt
  -> Linux no-follow atomic no-replace create
  -> separate exact-target read-back
  -> accepted or rejected LOGIC validation
  -> exact RUNTIME work completion
  -> body.progress derives done
```

The implementation is accepted only when all of these statements are true:

```text
semantic material cannot name, mint, widen or retain authority
the Packet never contains an open directory handle or absolute repository path
one action can affect only one absent regular file below one live repository root
the final target is never partially visible and is never overwritten
the writer receipt is not used as verification
completion is an immutable trace fact with exact work/action/evidence refs
expected world failure, rejected evidence and body invariant failure stay distinct
hand-disabled lives remain behaviorally identical to the current body
```

HAND is not an eleventh ProcessLang operator. It is a trusted effect provider
invoked by `☶ LOGIC` for one exact qualified action.

## 1. Scope And Deferrals

Implemented operation:

```text
repository.create_text_file.v0
precondition: final target absent
parent policy: every parent already exists and is a real directory
content: bounded valid UTF-8 text without NUL
publication: atomic no-replace
verification: separate bounded read of the exact final target
```

Not implemented by this crystall:

```text
overwrite, append, patch, delete, rename or mkdir
multi-file transaction or scheduler
arbitrary command, compiler or test runner
general repository read/search capability
binary content
spaces, non-ASCII or leading-dot path components
crash recovery or persistent action journal
safe already-applied replay
out-of-band truth rent after completion
CLI/TUI grant management
default Tree promotion
```

An `artifact_set` containing several required repository files remains several
required work items. V0 reports `multi_item_scheduling_deferred`; it must not
choose the first item or suppress the others through `☳`.

## 2. Platform Decision

The production provider is Linux-only v0:

```text
provider id: linux.openat2.renameat2.v0
Lua ABI: 5.4
native boundary: in-process Lua C module
runtime shell: none
weak fallback: none
```

The C module is selected because plain Lua 5.4 cannot retain opaque directory
descriptors or express race-safe path traversal. A helper built from lexical
checks, `realpath`, `io.open`, `os.execute`, or `io.popen` is not a compatible
provider.

Required kernel primitives and semantics:

```text
openat2(2)
RESOLVE_BENEATH
RESOLVE_NO_SYMLINKS
RESOLVE_NO_MAGICLINKS
RESOLVE_NO_XDEV
renameat2(2) with RENAME_NOREPLACE
O_CLOEXEC, O_DIRECTORY and O_NOFOLLOW where applicable
fstat(2), fsync(2), unlinkat(2), getrandom(2)
```

There is no fallback from `openat2` to `realpath + open`, and no fallback from
`RENAME_NOREPLACE` to check-then-rename. `ENOSYS`, unavailable resolve flags or
an unsupported filesystem make the capability unavailable or produce a typed
world failure; they do not weaken containment.

Observed development host at crystallization time:

```text
Linux 6.18 x86_64
GCC 14 available
/usr/include/linux/openat2.h available
Lua 5.4 runtime and shared library available
Lua 5.4 development headers/pkg-config metadata absent
```

This is environment evidence, not provider proof. Step 7 must satisfy the build
gate by supplying Lua 5.4 headers through the host toolchain. The repository
does not vendor an improvised Lua ABI header and does not silently compile a
weaker provider.

## 3. Exact File Surface

New Lua modules:

```text
runtime/repository_capability.lua
  private session registry, grant mint/revoke/resolve/projection

runtime/repository_intent.lua
  pure exact field-unit inspection and path/content normalization

runtime/repository_action.lua
  intent/grant intersection, action identity and dispatch rematerialization

runtime/repository_effect.lua
  provider contract, attempt/receipt/read-back/verification chain

runtime/work_completion.lua
  exact completion validation and repository progress derivation

runtime/repository_provider.lua
  native module loader and strict provider adapter
```

New native files:

```text
native/proc17_repository_fs.c
native/Makefile
native/tests/test_proc17_repository_fs.c
```

Existing Lua modules changed by the complete treatment:

```text
core/packet.lua
runtime/body.lua
runtime/budget.lua
runtime/qualified_pressure.lua
runtime/pressure_action.lua
runtime/pressure_composition.lua
runtime/operator_registry.lua
runtime/tension_runner.lua
runtime/lineage_runner.lua
organs/runtime.lua
organs/logic.lua
tests/run.lua
```

The first implementation does not replace or route through:

```text
core/sandbox.lua
tools/fs.lua
logic/spells.lua
runtime/trace_store.lua
```

Those modules remain compatibility or internal surfaces. Their existence grants
no repository authority.

## 4. Trusted Host Context

Repository hands are opt-in through trusted runner context:

```lua
{
  repository_hands = {
    protocol_version = "repository.hands.config.v0",
    enabled = true,
    repository_id = "notes-app",
  },
  host_services = {
    repository_capabilities = opaque_registry,
  },
}
```

`repository_id` selects the host-bound task repository. It is not a path and
does not grant authority. `host_services` is passed only among runner, pressure,
registry and organ code. It is never:

```text
copied into packet_options or Packet state
serialized into trace, corpse, carrier, manifest or substrate prompt
passed to substrate.ask
merged into caller-overridable organ options
returned in a run report
```

`options.capabilities` remains the old boolean compatibility surface. It cannot
satisfy `repository.create_text_file.v0`.

The Packet gains a non-secret `session_id`, distinct from
`substrate_session_id`. The lineage runner supplies the session identity at
every birth. A grant match requires exact:

```text
session_id
lineage_id
repository_id
operation
active grant revision
```

Generation is bound into each action, but the session grant is re-resolved for
every generation. No private authority crosses corpse or carrier.

When `repository_hands.enabled` is absent or false, repository readers do not
run and create no diagnostics, trace events or route candidates. This is the
hand-disabled ablation law.

## 5. Capability Registry Contract

Module API:

```lua
local capabilities = require("runtime.repository_capability")

registry, err = capabilities.new({
  session_id = string,
  providers = {[provider_id] = provider},
  id_source = function | nil,
})

projection, err = capabilities.mint(registry, {
  lineage_id = string,
  repository_id = string,
  provider_id = "linux.openat2.renameat2.v0",
  project_base = absolute_trusted_host_path,
  repository_path = narrow_relative_repository_path,
  operations = {create_text_file = true},
  bounds = {
    max_relative_path_bytes = positive_integer,
    max_content_bytes = positive_integer,
    max_effects_per_generation = positive_integer,
  },
  policy = {file_mode = 384}, -- 0600, host-owned policy
})

match, err = capabilities.resolve(registry, {
  session_id = string,
  lineage_id = string,
  generation = positive_integer,
  repository_id = string,
  operation = "create_text_file",
})

effect_lease, err = capabilities.begin_effect(registry, action)
projection, err = capabilities.revoke(registry, grant_id)
projection, err = capabilities.project(registry, grant_id)
```

Registry state is held behind module closures/private weak-key state. Returned
values are deep copies. The threat boundary is semantic/caller data, not
arbitrary hostile Lua code with `debug` access in the same process.

Private grant:

```lua
{
  protocol_version = "repository.capability_grant.v0",
  grant_id = string,
  revision = positive_integer,
  state = "active" | "revoked",
  session_id = string,
  lineage_id = string,
  repository_id = string,
  provider_id = "linux.openat2.renameat2.v0",
  provider = opaque_provider_object,
  repository_handle = opaque_native_userdata,
  project_base_identity = identity,
  root_identity = {
    host_path = string,
    device = integer,
    inode = integer,
    fingerprint = string,
  },
  operations = {create_text_file = true},
  bounds = table,
  policy = {file_mode = integer},
  policy_digest = string,
  effect_counts = {[generation] = integer},
}
```

Public projection is exactly the TABLE schema and contains neither
`provider`, `repository_handle`, `host_path`, nor `project_base_identity`.
It includes the non-authoritative administrative state `active|revoked`, so a
revocation receipt is observable without exposing private authority.

`mint` calls the provider to open and identify the project base and repository.
It rejects:

```text
the complete sandbox as repository root
internal sessions/packets/graves/compost/trace roots
an empty repository path
symlinked base/root components
cross-device repository traversal
unsupported provider semantics
zero, negative, fractional or missing bounds
unknown operation or policy keys
```

No implicit grant is created. Several exact active matches return
`ambiguous_capability`; the body does not choose one.

A caller may carry a `semantic_grant_id` claim for diagnostics. Resolution
ignores its value completely: only private registry state can create a match.
Knowing or forging a grant name therefore changes no authority decision.

`begin_effect` re-resolves the action, atomically checks and consumes one
`max_effects_per_generation` dispatch slot, and returns an opaque transaction
lease containing the private provider handle. The lease permits exactly one
create call and one read-back of the same action target; it cannot widen the
path or be reused. It runs after the attempt event and immediately before
provider invocation. A consumed dispatch slot is never refunded, including
when the provider fails before opening a temporary file. The count is private
authority state; its named reader is the next `begin_effect` check.

## 6. Native Provider API

`runtime/repository_provider.lua` loads the C module with an explicit search:

```text
module absent and hands disabled -> no effect
module absent when provider requested -> capability unavailable
module present but ABI/init fails -> loud harness failure
```

It exports the normalized provider object:

```lua
provider = {
  provider_id = "linux.openat2.renameat2.v0",
  contract_id = "repository.provider.create_readback.v0",
  available = function() -> boolean, diagnostic,
  open_repository = function(input) -> opaque_handle, identity | nil, error,
  revalidate = function(handle) -> identity | nil, error,
  create_text_file = function(handle, request) -> result | nil, error,
  read_text_file = function(handle, request) -> result | nil, error,
  close = function(handle) -> true | nil, error,
}
```

The native module exports only opaque userdata and bounded records:

```lua
native.open_repository(absolute_project_base, relative_repository_path)
native.revalidate(repository_handle)
native.create_text_file(repository_handle, relative_path, content, file_mode)
native.read_text_file(repository_handle, relative_path, max_bytes)
native.close(repository_handle)
```

File descriptors are never exposed as Lua integers. Userdata owns them and has
an idempotent `__gc` close path. Native functions independently validate the
narrow relative path grammar even when Lua has already validated it.

Native success result:

```lua
{
  protocol_version = "repository.provider_result.v0",
  operation = "create_text_file" | "read_text_file" | "revalidate",
  outcome = "created" | "observed" | "valid",
  target_kind = "regular_file" | "missing" | "other" | nil,
  bytes = integer | nil,
  content = string | nil, -- read_text_file only
  root = {device=integer, inode=integer},
  mutation_primitive_entered = boolean,
  published = boolean,
  cost = {
    tool_calls = 0 | 1,
    file_writes = 0 | 1,
    time_ms = non_negative_finite_number,
  },
}
```

Native error result:

```lua
{
  protocol_version = "repository.provider_error.v0",
  class = "world" | "ambiguous" | "contract",
  code = string,
  stage = string,
  errno = integer | nil,
  mutation_primitive_entered = boolean,
  published = false | true | "unknown",
  cost = table,
}
```

Unknown keys, impossible cost, impossible stage/outcome combinations and
provider identity mismatch are trusted-contract failures and stay loud.

## 7. Root Identity And Revalidation

At grant mint, native code performs:

```text
1. open absolute project base with openat2 and NO_SYMLINKS/NO_MAGICLINKS
2. fstat and retain base descriptor plus absolute base path and identity
3. open repository path relative to base with BENEATH/NO_SYMLINKS/
   NO_MAGICLINKS/NO_XDEV
4. fstat repository, require directory and capture device/inode
5. retain base identity, repository relative path and root identity in userdata
```

Lua computes:

```text
root_fingerprint = "repository-root:" .. sha256(canonical {
  provider_id,
  project_base device/inode,
  repository relative identity,
  repository device/inode,
})
```

Before every mutation and read-back, the native function itself reopens the
named base and repository and compares both identities with the handle. It then
uses that freshly opened repository descriptor for the operation. A Lua
preflight revalidation improves classification but is not the security gate.

If another process replaces a path after re-open, descriptor-relative traversal
still cannot escape the authorized directory. If replacement changes the named
root before read-back, verification cannot complete against the stale grant.

## 8. Path And Content Contract

`runtime/repository_intent.lua` owns one canonical parser used by intent and
action validation:

```lua
intent, diagnostic = repository_intent.derive(instance, {
  max_items = instance.regime.encoding.bounds.max_output_units,
})
```

Accepted current field unit:

```text
kind == structured_item
carrier.kind == repository.create_text_file.v0
carrier.value has exactly path and content
activation == live or selected
generation == current Packet generation
one exact structure_formation event names unit id/version
```

Relative path grammar:

```text
non-empty valid UTF-8 string
no NUL or ASCII control byte
not absolute; no leading/trailing slash
components separated only by `/`
no empty, `.` or `..` component
first byte of each component is ASCII letter or digit
remaining bytes are ASCII letter, digit, `.`, `_` or `-`
components `.git`, `.agents` and `.codex` forbidden
byte length within live grant bound before authorization
```

Content grammar:

```text
Lua string
valid UTF-8 according to Lua 5.4 utf8 library
no NUL
exact bytes retained; no newline or Unicode normalization
```

Intent inspection has no capability authority, so it does not apply a
grant-specific byte limit. It records exact path/content lengths. The action
authorizer applies `max_relative_path_bytes` and `max_content_bytes` while
intersecting the intent with the resolved live grant. Oversized material creates
no authorized action and no provider call.

The pure intent has protocol `repository.action_intent.v0` and the exact TABLE
fields. IDs use `core.digest.record` over the canonical record without its ID:

```text
intent_id = "repository-intent:" .. digest.record(identity_projection)
```

The content selector is fixed:

```text
carrier.value.content
```

The intent stores a unit/version referent, byte length and SHA-256, not an
independent content copy.

Malformed semantic material produces a diagnostic and no action. A malformed
current field object or contradictory formation event is a loud body invariant.

## 9. Authorized Action

`runtime/repository_action.lua` exports:

```lua
action, diagnostic = repository_action.authorize(instance, intent, registry, {
  session_id = instance.session_id,
  lineage_id = instance.lineage_id,
  generation = instance.generation,
  repository_id = trusted_repository_id,
  work_mode = "build",
})

request, projection = repository_action.materialize(instance, action, registry)
ok, err = repository_action.validate(instance, action)
```

Authorization is forbidden in plan mode. It resolves exactly one grant and
intersects intent, operation, bounds, repository identity and current Packet
identity. The resulting `repository.action.v0` is exactly the TABLE envelope.

Identity:

```text
action_id = "repository-action:" .. digest.record(action_without_action_id)
```

The identity binds:

```text
Packet/session/lineage/generation
work unit id/version/formation event
intent id/path/content length/content digest
grant id/revision/repository/provider/root fingerprint/policy digest
absent-target precondition
required tool/write budget
scope and provenance refs
```

Before dispatch, `materialize` performs all checks again, resolves the current
field unit and public grant projection, deep-copies content into an ephemeral
request and recomputes byte length and SHA-256. It returns no provider handle.
After the attempt event, `begin_effect` supplies the private transaction lease
to `repository_effect`; only that trusted module combines lease and request.
Any mismatch before route is not-ready. Any internal action contradiction after
a committed route is loud. Revocation, root replacement or external
affordability change after route is a typed world failure with no write.

`runtime/repository_effect.lua` exports one trusted transaction boundary:

```lua
outcome, err = repository_effect.execute(instance, action, registry)
```

It requires the current `☶` actor lease, owns attempt through read-back events,
and returns accepted/rejected verification plus actual cost. Expected provider
failure returns a typed `effect_failure`; malformed trusted data returns a loud
string error. `organs/logic.lua` is the only production caller and appends the
final LOGIC validation over this outcome.

## 10. Action Review And Pressure Modes

`runtime/pressure_action.lua` keeps protocol `pressure.action_plan.v0` and gains
three non-mergeable exact modes:

| Mode | Target | Option root | Expected effect |
|---|---|---|---|
| `repository_action_review` | `☱` | `runtime` | `runtime_eye_payload` mode `repository_action_review` |
| `repository_effect` | `☶` | `logic` | `logic_validation_payload` mode `repository_effect` |
| `repository_reconcile` | `☱` | `runtime` | `runtime_eye_payload` mode `repository_reconcile` |

Each mode carries:

```lua
repository_input = {
  action = repository_action_projection,
  action_id = string,
  work_unit_id = string,
  work_unit_version = integer,
  formation_event_ref = string,
  grant_id = string,
  grant_revision = integer,
  evidence_refs = string[], -- empty only before effect
}
```

For these modes, `pressure_action.registry_context` owns only the exact
`options.runtime.repository_*` or `options.logic.repository_effect` subtree. It
rejects a caller value at that subtree but preserves unrelated compatibility
options. `options.logic.spells` may coexist in caller configuration, but LOGIC
ignores it while an action-owned repository effect is executing.

`scope_refs` contains the exact unit/version coverage ref plus the action ID.
`preconditions.object_versions` contains exactly that field unit. Action-plan
validation re-hashes the repository action and forbids capability handles,
absolute paths and raw content inside route evidence.

Qualified readers added to `runtime/qualified_pressure.lua`:

```text
repository_review_need
  source: one uncontested current authorized action without current review
  target: ☱

repository_effect_need
  source: current actionable review, or exact selected alternative action,
          with no attempt/completion
  target: ☶

repository_reconcile_need
  source: accepted exact verification + accepted validation, no completion
  target: ☱
```

No grant means no executable witness. A typed diagnostic may appear in explicit
hand instrumentation, but does not contribute pressure.

The uncontested path is:

```text
☵ -> ☱ -> ☶ -> ☱
```

The first `☱` records a real review and is not an empty topology bridge. A real
mutually-exclusive set may use:

```text
☵ -> ☳ -> ☶ -> ☱
```

One item never pays choice loss.

## 11. RUNTIME Action Review

`organs/runtime.lua` gains `repository_action_review` mode. In one normal
RUNTIME tick it:

```text
validates current action and exact unit/version
re-resolves the host grant without exposing it
checks count-axis affordability
appends one repository_action_review event
performs the ordinary camera/reconciliation/tension/observation work
returns runtime_eye_payload mode=repository_action_review
```

Review ID:

```text
repository-action-review:<digest of action id, work identity, grant revision,
current review tick and source refs>
```

The schema permits `actionable` or `not_actionable`, but the qualified v0 path
appends a review only when the verdict is `actionable`. Expected host volatility
after route is represented as typed effect failure rather than a fabricated
`not_actionable` review. Internal identity contradiction stays loud.

`runtime.repository_action_review.v0` is stored only in trace. Its named reader
is `repository_effect_need`.

## 12. LOGIC Effect Transaction

`organs/logic.lua` gains an explicit branch:

```lua
logic.run(instance, options, host_services)
```

When `options.repository_effect` is present, it cannot read or execute
`options.logic.spells`. Repository mode performs:

```text
1. validate committed qualified action and same-ref scope
2. re-resolve grant and rematerialize exact content
3. check budget.can_pay({tool_calls=2, file_writes=1})
4. append repository_effect_attempt event
5. consume one private grant dispatch slot and obtain an opaque effect lease
6. invoke create provider
7. validate and append repository_effect_receipt event
8. invoke separate exact-target read provider
9. compute read-back bytes/SHA-256 in Lua
10. append repository_verification event
11. append logic validation referencing receipt and verification
12. return logic_validation_payload mode=repository_effect with actual cost
```

The external effect begins only after the immutable attempt event exists.

The writer receipt uses the TABLE schema. The native writer reports bytes and
publication; the Lua adapter attaches the request digest as the writer's claim.
This remains unverified content. Only the separate read-back computes evidence.

Successful payload:

```lua
{
  kind = "logic_validation_payload",
  mode = "repository_effect",
  status = "accepted" | "rejected",
  reason = string,
  action_id = string,
  attempt_ref = string,
  receipt_ref = string,
  verification_ref = string,
  evidence_count = 1,
  effect_cost = {tool_calls=2, file_writes=1, time_ms=number},
  effect_scope_refs = string[],
  truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

`status=rejected` is an applied LOGIC result, not an effect failure. It means a
real writer receipt exists but independent evidence did not satisfy the exact
predicate. A provider denial or ambiguous read is a typed effect failure. A
malformed provider record or impossible identity is a loud harness failure.

The trusted transaction returns a detached projection for LOGIC to validate:

```lua
{
  protocol_version = "repository.effect_result.v0",
  status = "accepted" | "rejected",
  reason = string,
  action_id = string,
  attempt_ref = string,
  receipt_ref = string,
  verification_ref = string,
  receipt = table,
  verification = table,
  cost = {tool_calls=2, file_writes=1, time_ms=number},
  effect_scope_refs = string[],
  truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

The returned tables are deep copies. Mutating them cannot mutate the trace.
There is no success projection for a typed provider failure or a malformed
trusted record.

## 13. Native Create Algorithm

For `src/main.lua`, native code splits only the already validated path into:

```text
parent = src
basename = main.lua
```

The exact algorithm is:

```text
1. re-open and compare project base and repository root identities
2. open parent relative to fresh root fd using openat2:
   O_RDONLY|O_DIRECTORY|O_CLOEXEC and all four resolve restrictions
3. generate 128 random bits once with getrandom
4. form private sibling name `.proc17-tmp-<random-hex>`
5. open temp with openat O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC
   and host-owned file_mode; a name collision returns typed
   `temp_name_collision` rather than introducing an unmeasured retry loop
6. count file_writes=1 once the mutation primitive is entered
7. write the complete Lua string with a short-write/EINTR loop
8. fsync temp and close it successfully
9. publish with renameat2(parent,tmp,parent,basename,RENAME_NOREPLACE)
10. fsync parent directory
11. close parent/root descriptors and return `created`
```

The reserved temporary prefix cannot be requested by v0 path grammar. No final
target existence check is used as authority; `RENAME_NOREPLACE` is the atomic
precondition.

Failure law:

```text
before rename success:
  best-effort unlink temp; final target remains absent/unchanged

rename returns EEXIST:
  typed target_exists; existing target remains byte-identical

after rename success but before durable parent fsync result:
  ambiguous_effect; never fabricate receipt or completion

temp cleanup failure:
  typed/ambiguous provider failure with actual write cost; no success claim
```

The production API has no fault-injection option. Native C tests compile a
separate test target with an internal syscall table to prove pre-publish cleanup,
no-replace and post-publish ambiguity. Test hooks are not exported by the Lua
module.

## 14. Independent Read-Back

Native read-back:

```text
1. re-open and compare base/root identities
2. open exact target relative to root using openat2 and all resolve restrictions
3. return `target_kind=missing` for an exact ENOENT observation
4. classify a present non-regular target as `target_kind=other`
5. for a regular file, read at most expected_bytes + 1
6. return the bounded observation and measured cost
```

Lua computes SHA-256 using `core/digest.lua`. Verification is accepted only if:

```text
root identity still matches
target is one regular file at the exact action path
observed length equals action content length
observed SHA-256 equals action content SHA-256
attempt and receipt are earlier events in the same ☶ visit
all action/grant/work identities agree
```

The `repository.verification.v0` event stores observed length/digest, not the
full file content. Its event truth is `runtime_confirmed`; semantic content
status remains inherited from the work material.

Read-back authority is implicit and mandatory inside the exact create grant. It
cannot be reused to read another path or exposed as a general read tool.

## 15. Trace Events And Actor Rights

`core/packet.lua` adds event types and rights:

| Event type | Actor | First named reader |
|---|---|---|
| `repository_action_review` | `☱` | repository effect pressure |
| `repository_effect_attempt` | `☶` | receipt/ambiguity reconciler |
| `repository_effect_receipt` | `☶` | verifier and completion gate |
| `repository_verification` | `☶` | LOGIC validation and completion gate |
| `work_completion` | `☱` | body.progress, CYCLE, MANIFEST, lineage completion |

`runtime/body.lua` exposes actor-guarded writers:

```lua
body.record_repository_action_review(instance, payload)
body.record_repository_effect_attempt(instance, payload)
body.record_repository_effect_receipt(instance, payload)
body.record_repository_verification(instance, payload)
body.record_work_completion(instance, payload)
```

All writers validate exact schemas, require a current actor lease, deep-copy on
store and return, and reject unknown keys. Trace is the canonical ledger. No
parallel mutable `action.status` or `work_completion_by_id` truth store is added.

Derived record identities use `core.digest.record` over the normalized payload
without its own ID:

```text
target_ref      = repository-target:<root fingerprint, path, absent precondition>
attempt_id      = repository-attempt:<action id, current ☶ tick ref, target ref>
receipt_id      = repository-receipt:<attempt event ref, normalized writer result>
verification_id = repository-verification:<receipt event ref, observed, expected>
completion_id   = work-completion:<work/action/attempt/receipt/verification/
                  validation refs>
```

Repository verification increments `revisions.evidence` exactly once; work
completion increments `revisions.history` exactly once. Those revisions are
observation triggers only, not the completion authority.

## 16. Work Completion

`runtime/work_completion.lua` exports:

```lua
candidate, err = work_completion.derive(instance, repository_input)
record, err = work_completion.record(instance, candidate)
complete, evidence_or_err = work_completion.is_complete(instance, unit_id, version)
progress, err = work_completion.repository_progress(instance)
```

`repository_reconcile` mode on the next `☱` tick validates the complete chain:

```text
current live/selected exact unit/version
current action identity
attempt -> receipt -> verification ordering
accepted verification
accepted LOGIC validation over the same refs
no later conflicting/rejected effect for that work version
no existing exact completion
```

It then appends exactly one `runtime.work_completion.v0` event. Repeating the
same reconciliation is a no-op readiness exclusion, not a duplicate event.

`body.progress` changes only for field units whose carrier kind is
`repository.create_text_file.v0`:

```text
done = exact current work_completion exists
pending = no exact current work_completion
```

For those units, `calm.work_units[].status` has no authority. Other legacy work
units keep the compatibility behavior until their own completion contracts are
migrated.

Completion proves the exact declared file predicate. It does not prove program
quality, compilation or tests.

## 17. Economics

`runtime/budget.lua` adds a pure check:

```lua
budget.can_pay(instance, cost) -> true | false, missing_axes | error
```

Absent budget axes retain current unlimited semantics. Count-axis preflight for
the normal action is:

```lua
{tool_calls = 2, file_writes = 1}
```

Actual charging remains centralized in `tension_runner`:

```text
normal body tick -> steps=1
successful/rejected repository LOGIC payload -> payload.effect_cost
typed effect failure -> failure.cost through existing failure path
```

`apply_operator_physics` gains a `☶ repository_effect` branch that validates
`effect_cost` with `budget.validate_cost` and charges it once. No organ mutates
budget directly.

Cost rules:

```text
route-time missing/revoked grant: 0 tool_calls, 0 file_writes
native writer entered but root race detected before temp open: 1 tool_call, 0 writes
temp creation entered: 1 tool_call, 1 file_write even if publication fails
read-back entered: +1 tool_call
time_ms: measured actual provider duration
identity loss: always 0 for exact hand execution
```

Time and money can exhaust after a real effect because their exact cost is not
known before execution. The body never rewrites the resulting economics to fit
the preflight estimate.

## 18. Failure Boundary

### 18.1 Not-ready or excluded before route

```text
hands disabled or plan mode
no current exact intent
malformed semantic proposal
no matching grant
ambiguous grants
stale/suppressed/dissolved work
already completed exact work
insufficient known count-axis budget
provider absent before authorization
```

These create no external effect and no Packet death merely by existing.

### 18.2 Typed effect failure after committed route

Mapped through `substrates.contract.effect_failure`:

```text
source=sandbox:
  grant_revoked, root_changed, provider_unavailable, path_containment_denied

source=tool:
  target_exists, parent_missing, parent_not_directory, permission_denied,
  no_space, io_failure, ambiguous_effect, readback_unavailable
```

Actual provider costs are retained. The existing runner records
`operator_failure`, captures a camera frame, and kills the Packet with
`death_cause=effect_failure` and honest residue.

### 18.3 Rejected evidence

```text
writer returned a valid created receipt
read-back found missing/other/length mismatch/digest mismatch
```

LOGIC records `status=rejected`; no completion exists. This is Packet-world
evidence, not a harness exception.

### 18.4 Loud body/invariant failure

```text
malformed trusted provider result
unknown provider keys/cost/outcome
action, route, attempt, receipt or verification identity contradiction
event actor/lease violation
impossible effect cost
Lua/C exception or native ABI mismatch
provider reports escape/overwrite contract violation
```

These return a harness error. They do not become a beautiful Packet death,
grave, carrier or inherited lesson.

## 19. Runner And Lineage Wiring

`runtime/tension_runner.lua`:

```text
preserves host_services by reference in trusted execution context
never deep-copies or serializes opaque registry/provider state
passes only public action projections through pressure_action.registry_context
passes host_services separately to LOGIC/RUNTIME descriptors
verifies committed action readiness/effect with exact same-ref checks
charges actual repository effect economics once
```

`runtime/operator_registry.lua`:

```text
does not model repository authority as `capabilities[name] == true`
delegates exact repository readiness to the action/grant resolver
passes host_services as a separate trusted argument
retains current not_ready/effect_failure/invariant trichotomy
```

`runtime/lineage_runner.lua`:

```text
owns session_id insertion at every Packet birth
passes the same session registry to every generation
does not put grants in corpse/carrier/session-memory projections
does not reset grant effect counts at Packet rebirth
closes provider handles when the outer session/lineage run is released
```

V0 is in-memory. Host restart loses private grants; resume is already deferred.

## 20. Red Test Surface For Step 5

New Lua suites, initially run directly and not registered in `tests/run.lua`
until the corresponding implementation is green:

```text
tests/test_repository_capability.lua
  G0-G12, private/public aliasing, generation re-resolution

tests/test_repository_intent.lua
  P1-P8, A0-A10, strict field/formation identity

tests/test_repository_action.lua
  action hash, same-ref gate, plan/build, ambiguous grant, no fake choice

tests/test_repository_effect.lua
  malformed fake provider results, receipt/verification separation, E0-E14

tests/test_repository_provider_linux.lua
  P0, P9-P15, target no-overwrite, independent read-back

tests/test_repository_progress.lua
  E6-E15, exact completion, duplicate and cross-work rejection

tests/test_repository_route.lua
  R0-R10, exact ☵->☱->☶->☱ chain and hand-disabled ablation
```

Native tests:

```text
native/tests/test_proc17_repository_fs.c
  short writes/EINTR
  failure before rename leaves no final file
  rename no-replace preserves existing bytes
  failure after rename is ambiguous, never clean success
  descriptor cleanup and idempotent close
```

Real filesystem fixtures are grown under one unique test-owned directory. They
must include real symlink parents/finals. Cross-device/bind-mount coverage may
be an explicit environmental skip with a reason; it may not pass without the
fixture.

The red runner records which controls fail because modules are absent and which
fail because old helpers are unsafe. It must not execute arbitrary user-derived
commands or write outside its unique fixture root.

## 21. Implementation Order After This Crystall

Roadmap step 5:

```text
grow red pure-contract, malformed-provider and real-filesystem controls
capture baseline without weakening or registering false-green skips
```

Roadmap step 6:

```text
implement session_id propagation
implement repository_capability, repository_intent and repository_action
implement pressure mode schemas with fake provider only
keep all external writes disabled
```

Roadmap step 7:

```text
satisfy native build gate
implement Linux descriptor provider and C tests
turn P0/P9-P16 green
```

Roadmap step 8:

```text
integrate RUNTIME review, LOGIC transaction, trace rights, economics,
repository reconciliation and body.progress
turn action/effect/progress/route suites green
```

Roadmap step 9:

```text
grow one strict DeepSeek/fake-substrate task that creates one real file in one
granted test repository and reaches exact work_completion without caller spell
or caller path authority
```

Roadmap step 10:

```text
crystallize and implement the first build completion/manifest projection
record treatment, security limits, measured route/economics and deferrals
```

## 22. Acceptance Gate

This crystall is internally complete when:

```text
the provider primitive is named and has no weak fallback
authority location and trusted context propagation are exact
intent/action/grant/effect/verification/completion identities are distinct
all new trace writers and first readers are named
one-item and real-choice routes are topologically lawful
budget and identity-loss effects are explicit
expected, rejected and invariant failures cannot alias
the red battery maps every TABLE control to a concrete test surface
the current missing Lua development headers are recorded as a build gate,
not hidden as an implementation detail
```

No source implementation is authorized to widen this crystall. A required
primitive that cannot be implemented or falsified returns the work to TABLE or
CHAOS; it does not produce a weaker provider under the same protocol name.
