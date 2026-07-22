# Capability-Safe Repository Hands Yellowprint v0

Status:

```text
layer: table (⊞)
date: 2026-07-19
source: docs/00_chaos/capability_safe_repository_hands_notes_2026-07-19.md
scope: first exact repository mutation and verified work completion
runtime implementation authorized: no
arbitrary shell authorized: no
default router promotion authorized: no
amended 2026-07-22: cross-generation grant re-resolution is provisional only
  before first root authority consumption; repository candidate lifecycle owns
  the sticky generation claim and terminal root lock
amendment source:
  repository_candidate_lifecycle_yellowprint.v0.md
```

## 0. Selected Decisions

```text
D01 work, intent, grant, authorized action, effect, verification and completion
    remain separate records
D02 substrate output can propose an intent but cannot name or mint authority
D03 the session host owns the capability registry; one v0 grant is scoped to
    one lineage and may be provisionally re-resolved before root claim; first
    authority consumption binds the root to one generation, after which only
    that generation may resolve source-write authority
D04 one grant names one repository root below the configured project base, not
    the complete sandbox tree
D05 the first operation is create_text_file.v0 over an absent target whose
    parent directory already exists
D06 the first path/content language is deliberately narrow and bounded by the
    grant; no defaults pretend to be measured constants
D07 the real provider must guarantee no-follow traversal, no-overwrite and
    atomic final visibility; lexical check + raw io.open is rejected
D08 ☵ forms an action intent without capability data; the body authorizes it
    only by intersecting it with a live host grant
D09 one uncontested action does not invoke ☳; only an explicit
    mutually-exclusive alternative_set creates choice pressure
D10 several required artifacts are work, not alternatives; CHOOSE must not kill
    future required files
D11 the uncontested ☵ -> ☱ bridge produces an exact action review with a named
    reader; ☱ is not a ceremonial routing tick
D12 ☶ owns one v0 dispatch phase and one separate read-back phase in one tick
D13 a writer receipt cannot satisfy LOGIC evidence by itself
D14 ☱ alone may append exact work completion after accepted fresh evidence
D15 completion is an immutable ledger fact; authoritative done is derived from
    it rather than written into CALM as a second truth store
D16 a create grant includes mandatory exact-target read-back, not general
    repository read authority
D17 exact execution spends budget but creates no identity loss
D18 expected world failure, trusted-contract failure and not-ready remain
    separate outcomes
D19 hand-disabled lives must remain physically identical to the current body
D20 core/sandbox.lua, tools/fs.lua and logic/spells.lua are not accepted as the
    repository provider without replacement at this boundary
D21 this treatment adds qualified build pressure but does not promote Tree as
    the default authority
```

## 1. Product Boundary

The yellowprint defines one closed physical claim:

```text
Given one exact active field unit describing a valid create-text intent and one
live matching host capability, proc-17 can create the requested file inside the
granted repository, independently read it back, record accepted evidence, and
derive that exact work unit as done.
```

It does not claim:

```text
the generated program is semantically correct
multiple files form a transaction
commands or tests may run
the repository may be overwritten
the action survives host restart
Tree pressure is calibrated or production-promoted
```

## 2. Seven-Layer Boundary

| Layer | Question | Owner | Stored truth |
|---|---|---|---|
| work material | What exact current field unit still requires work? | Packet field + formation trace | body event with inherited content status |
| action intent | What external state does this unit request? | pure body inspection of exact unit/version | derived; trace projection only when routed |
| capability grant | What external power did the host actually grant? | trusted session capability registry | host state, never substrate or Packet authority |
| authorized action | What exact intersection of intent and grant may execute? | body action planner | immutable route/action projection |
| effect attempt/receipt | What did the writer attempt and report? | ☶ plus trusted provider | immutable body events after schema checks |
| verification | What does a separate read path observe now? | ☶ read-only verifier | immutable evidence/validation |
| work completion | Which exact work version is now proven complete? | ☱ reconciliation | immutable completion event, derived progress |

Forbidden collapses:

```text
intent == capability
path string == repository identity
grant id == grant ownership
authorized action == route glyph
writer receipt == verified effect
accepted verification == mutable CALM status
one current work item == CHOOSE collapse
```

## 3. Current And Target Chains

Current caller-owned chain:

```text
runner options.logic.spells
  -> ☶
  -> arbitrary configured spell
  -> spell result
  -> validation
```

Target v0 chain:

```text
strict substrate structure proposal
  -> ☵ exact field unit + CALM projection
  -> repository intent inspection
  -> optional ☳ only for real alternatives
  -> trusted capability resolution
  -> route-carried authorized action to ☶
  -> effect_attempt event
  -> create_text_file provider
  -> effect_receipt event
  -> separate exact-target read-back
  -> accepted/rejected repository verification
  -> ☱ reconciliation
  -> work_completion event
  -> body.progress derives done/remaining
```

No caller-supplied spell, path root, action envelope or success record enters
the target chain.

## 4. Exact Source Intent

### 4.1 Strict proposal item

The accepted substrate item is contained in the existing strict
`packet.structure.proposal.v0` envelope:

```lua
{
  key = string,
  kind = "repository.create_text_file.v0",
  value = {
    path = string,
    content = string,
  },
  source_keys = string[],
}
```

The item must not contain:

```text
capability_id
repository root
absolute path
command
shell
write mode
success claim
content digest supplied as authority
```

The body computes byte length and SHA-256 itself.

### 4.2 Intent derivation

Pure inspection of the exact formed field unit derives:

```lua
{
  protocol_version = "repository.action_intent.v0",
  intent_id = string,
  operation = "create_text_file",
  source_unit_id = string,
  source_unit_version = integer,
  source_formation_event_ref = string,
  relative_path = string,
  content_ref = {
    unit_id = string,
    unit_version = integer,
    selector = "carrier.value.content",
  },
  content_bytes = integer,
  content_sha256 = string,
  scope_refs = string[],
  provenance_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

`intent_id` is SHA-256 over the normalized record excluding `intent_id`. The raw
content need not be duplicated in route history; its exact field referent,
length and digest are bound.

### 4.3 Intent qualification

| Source state | Intent result |
|---|---|
| exact active/live unit, valid kind/value/path/content | one current intent |
| exact selected unit after real choice | one current intent |
| suppressed or dissolved unit | no intent |
| unit version changed | old intent stale; derive a new identity |
| unsupported kind | typed unsupported diagnostic, no repository pressure |
| malformed value/path/content | typed malformed semantic proposal, no action |
| inspection truncated | incomplete diagnostic, no action |

Malformed semantic material is not a tool failure because no authorized effect
exists yet.

## 5. Choice And Work Cardinality

| Formed structure | Item count | ☳ law | Execution meaning |
|---|---:|---|---|
| `artifact_set` | 1 | no CHOOSE | one uncontested action |
| `artifact_set` | >1 | no CHOOSE from cardinality alone | all artifacts remain required work |
| `work_sequence` / hierarchy | any | no CHOOSE unless a separate alternative contract exists | order/dependencies remain work structure |
| `alternative_set` + `mutually_exclusive` | 1 | confirmation, no collapse/loss | one uncontested action |
| `alternative_set` + `mutually_exclusive` | >1 | exact ☳ collapse | one selected, others genuinely suppressed |

The first treatment executes one item only. Multi-item scheduling is deferred,
but it must not be approximated by killing unexecuted required work.

## 6. Host Capability Registry

### 6.1 Authority location

The session host owns an opaque registry. Substrate calls and Packet field data
never receive the registry table or provider handle.

One v0 grant is scoped to:

```text
one session
one task lineage
one repository identity
one provider identity
one operation set
explicit bounds
```

The grant survives Packet death within that lineage, but no authority crosses
inside corpse or carrier. A descendant may resolve the host grant only while
the root remains unclaimed. Once any generation consumes root authority, the
sticky root claim denies descendant reuse and a later generation requires a
fresh repository/root under the lifecycle amendment.

### 6.2 Private grant record

Conceptual trusted record:

```lua
{
  protocol_version = "repository.capability_grant.v0",
  grant_id = string,
  revision = integer,
  state = "active" | "revoked",
  session_id = string,
  lineage_id = string,
  repository_id = string,
  provider_id = string,
  project_base_identity = table,
  root_identity = {
    host_path = string,
    device = integer,
    inode = integer,
    fingerprint = string,
  },
  operations = {
    create_text_file = true,
  },
  bounds = {
    max_relative_path_bytes = integer,
    max_content_bytes = integer,
    max_effects_per_generation = integer,
  },
  policy_digest = string,
}
```

All numeric bounds are explicit positive integers supplied by trusted host
configuration. This table defines no universal magic numbers.

### 6.3 Public projection

Packet route/evidence may record only:

```lua
{
  protocol_version = "repository.capability_projection.v0",
  grant_id = string,
  revision = integer,
  state = "active" | "revoked",
  session_id = string,
  lineage_id = string,
  repository_id = string,
  provider_id = string,
  root_fingerprint = string,
  operations = string[],
  bounds = table,
  policy_digest = string,
  event_truth_status = "runtime_confirmed",
}
```

The projection contains no provider object and need not expose the absolute host
path. Mutating a returned projection cannot mutate the private grant.

### 6.4 Resolution table

| Context | Result |
|---|---|
| active exact session/lineage grant, operation allowed | capability match |
| no grant | candidate excluded as `missing_capability` |
| revoked grant before route | candidate excluded as `revoked_capability` |
| wrong session or lineage | no match |
| wrong repository or operation | no match |
| several matching grants | `ambiguous_capability`, no canonical choice |
| grant revision changes after route commit | typed pre-effect world failure; no write |
| root identity changes before execution | typed capability invalidation; no write |
| provider cannot enforce grant contract | capability unavailable |

Knowing `grant_id` never changes these results.

## 7. Repository Root And Path Contract

### 7.1 Root acceptance

The host may mint a grant only when:

```text
configured project base exists and is a real directory
repository root exists below that base
base and root are opened without following a symlink at their named component
root identity is captured by device/inode/fingerprint
root is not sandbox itself
root is not sessions, packets, grave, compost, trace or another internal store
provider can retain or re-open the exact root identity safely
```

### 7.2 Relative path grammar for v0

One path is accepted only when:

```text
it is non-empty UTF-8 text with no NUL/control byte
it is not absolute and has no leading/trailing slash
it has no empty, `.` or `..` component
every component begins with ASCII letter or digit
remaining component bytes are ASCII letters, digits, `.`, `_` or `-`
no component is `.git`, `.agents` or `.codex`
its byte length is within the grant bound
all parent components already exist as real directories
no root, parent or final component is a symlink
all traversed parents remain beneath root and obey a no-cross-device policy
the final target is absent
```

This intentionally rejects spaces, leading-dot files and non-ASCII paths in v0.
Those can be widened later without weakening the first proof.

### 7.3 Content grammar for v0

```text
Lua string
valid UTF-8
contains no NUL
exact bytes, with no newline or encoding normalization
byte length <= grant.max_content_bytes
SHA-256 computed by the body before authorization and again before dispatch
```

### 7.4 Provider atomicity

The real provider must implement semantics equivalent to:

```text
open trusted root identity
walk existing parents relative to directory handles with semantics equivalent
to RESOLVE_BENEATH + RESOLVE_NO_SYMLINKS + RESOLVE_NO_MAGICLINKS
reject mount/device escape with semantics equivalent to RESOLVE_NO_XDEV
require the final parent to be owned by the process effective UID and deny
group/other write permission
create/write a private temporary sibling
flush/close according to provider contract
publish final name atomically with no-replace
never expose a partial final file
return no success if final target pre-existed
```

An implementation based on lexical check, `realpath` followed by raw `io.open`,
or check-then-open does not satisfy this table. CRYSTALL must name a primitive
that actually implements the semantics.

Implementation observation (2026-07-19, step 7.5): the parent ownership/mode
row is required by the named-temporary design. Random naming prevents advance
guessing but does not stop a differently privileged writer that can alter the
directory after the name appears. The remaining same-UID adversary is an
explicit v0 trust-boundary exclusion, not an atomicity claim.

## 8. Authorized Action Envelope

The body intersects one exact intent with one resolved grant:

```lua
{
  protocol_version = "repository.action.v0",
  action_id = string,
  intent_id = string,
  packet_id = string,
  session_id = string,
  lineage_id = string,
  generation = integer,
  work_unit = {
    id = string,
    version = integer,
    formation_event_ref = string,
  },
  capability = {
    grant_id = string,
    revision = integer,
    repository_id = string,
    provider_id = string,
    root_fingerprint = string,
    policy_digest = string,
  },
  operation = "create_text_file",
  target = {
    relative_path = string,
    precondition = "absent",
  },
  content = {
    ref = table,
    bytes = integer,
    sha256 = string,
  },
  required_budget = {
    tool_calls = 2,
    file_writes = 1,
  },
  scope_refs = string[],
  provenance_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

`action_id` is SHA-256 over the canonical normalized record excluding
`action_id`. The action stores a content referent and digest, not a second
authoritative mutable copy of Packet material.

Before dispatch, the body resolves the exact field referent, deep-copies the
bytes into an ephemeral provider request, recomputes length/digest and rejects
any mismatch.

### 8.1 Action same-ref gate

```text
intent unit id/version
== authorized action work id/version
== route pressure scope
== ☶ readiness scope
== effect attempt scope
== receipt action id/scope
== verification action id/scope
== ☱ completion work id/version
```

Capability projection refs and formation/provenance refs may extend provenance.
They cannot replace the exact work referent.

### 8.2 Uncontested action review

The topology does not permit `☵ -> ☶`, and a single action must not be laundered
through ☳. The lawful bridge is one exact ☱ review:

```lua
{
  protocol_version = "runtime.repository_action_review.v0",
  review_id = string,
  action_id = string,
  packet_id = string,
  lineage_id = string,
  generation = integer,
  work_unit_id = string,
  work_unit_version = integer,
  capability_grant_id = string,
  capability_revision = integer,
  verdict = "actionable" | "not_actionable",
  reason = string,
  scope_refs = string[],
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

This review is produced only for the `repository_action_review` mode carried by
the committed `☵ -> ☱` edge. It does not execute or complete work. Its first
named reader is the `repository_effect` pressure producer, which requires the
same current action/work/grant identities before proposing `☱ -> ☶`.

The alternative path needs no bridge because `☳ -> ☶` is directly adjacent. It
still re-resolves and validates the same authorized action before execution.

## 9. Derived Action Phases

No mutable action state machine is authoritative. Phase is derived from current
Packet state and immutable events.

| Derived phase | Required facts | Next lawful consumer |
|---|---|---|
| `intent_available` | exact active intent, no authorized action in current derivation | capability resolver/action planner |
| `authorization_missing` | intent exists, no matching live grant | readiness exclusion/report |
| `authorized` | current action id, no attempt | ☶ readiness/dispatch |
| `reviewed` | exact actionable ☱ review, no attempt | repository-effect pressure/☶ |
| `attempted` | exact effect-attempt event, no valid receipt | effect provider/reconciliation |
| `effect_reported` | valid receipt, no verification | read-only verifier |
| `verification_rejected` | exact rejected verification | LOGIC/repair/terminal policy |
| `verified` | exact accepted current verification | ☱ reconciliation |
| `completed` | exact work-completion event | progress/cycle/manifest |
| `stale` | unit/grant/action referent changed | no execution; derive new intent/action if lawful |

A reader derives these phases from trace, field and host capability resolution.
No second mutable `action.status` table is introduced.

## 10. Operator And Route Matrix

HAND is an effect provider under ☶, not an operator.

| Current body state | Qualified need | Lawful target/path | Effect |
|---|---|---|---|
| ☵ formed one uncontested exact action | action qualification review | `☵ -> ☱` | ☱ records exact action review; no choice |
| ☵ formed real mutually-exclusive alternatives | alternative collapse | `☵ -> ☳` | one selected, others suppressed with real loss |
| ☳ completed exact collapse | selected repository effect | `☳ -> ☶` | authorized action arrives at LOGIC |
| ☱ has one reviewed pending action | repository effect | `☱ -> ☶` | authorized action arrives at LOGIC |
| ☶ created and verified target | runtime reconciliation | `☶ -> ☱` | exact verification becomes completion candidate |
| ☱ appended completion, work remains | continuation | `☱ -> ☲` or another qualified lawful edge | CYCLE observes remaining work |
| ☱ appended completion, no work remains | terminal delivery need | lawful lower path to △ | MANIFEST consumes verified result |

Upper observation or another higher-class need may lawfully intervene. The table
does not hardcode one full trace. It defines the witnesses that must eventually
make the work chain possible.

### 10.1 Qualified pressure additions

Required new body-derived modes:

```text
repository_action_review -> ☱
repository_effect       -> ☶
repository_reconcile    -> ☱
```

The exact `pressure.action_plan` revision belongs to CRYSTALL. Every mode must
carry the authorized action id and same-ref scope. Caller `options.logic.spells`
cannot satisfy these modes.

## 11. Readiness, Capability And Affordability

### 11.1 ☶ readiness

☶ is ready for `repository_effect` only when:

```text
work mode is build
authorized action validates canonically
current field unit id/version/content digest still match
current activation is live or selected, never suppressed/dissolved
grant re-resolves for current session/lineage/generation
grant revision/root/provider/policy still match the action
operation and bounds permit the request
provider declares the exact create/read-back contract
budget can reserve the bounded external attempt
no current accepted completion already covers the work version
```

### 11.2 Affordability reservation

The first normal life reserves enough for:

```text
one create provider call
one independent read-back provider call
one file-write attempt
the normal body tick (charged by runner separately)
```

The action records a bounded requirement. Actual charges come from actual
attempt/verification outcomes and may be lower after a pre-effect denial.

### 11.3 Change after route commit

| Change | Classification |
|---|---|
| internal action/work identity changes impossibly | invariant failure |
| host revokes grant | typed capability effect failure, no provider write |
| repository root identity changes | typed capability invalidation, no provider write |
| budget was concurrently consumed by lawful body event | typed unaffordable effect failure, no write |
| provider disappears | typed external availability failure |

Expected external volatility must not become `committed_operator_not_ready`
harness failure. Internal Packet contradiction remains loud.

## 12. Provider Request And Effect Attempt

### 12.1 Ephemeral provider request

After revalidation, ☶ materializes:

```lua
{
  protocol_version = "repository.create_text_file.request.v0",
  action_id = string,
  grant_id = string,
  grant_revision = integer,
  root_handle = opaque_trusted_value,
  root_fingerprint = string,
  relative_path = string,
  content = string,
  content_bytes = integer,
  content_sha256 = string,
  precondition = "absent",
}
```

The opaque root handle comes from the private registry and is never stored in
Packet/trace or shown to substrate.

### 12.2 Attempt event

Before entering the external writer, ☶ appends an immutable attempt event:

```lua
{
  protocol_version = "repository.effect_attempt.v0",
  attempt_id = string,
  action_id = string,
  grant_id = string,
  grant_revision = integer,
  operation = "create_text_file",
  target_ref = string,
  work_unit_id = string,
  work_unit_version = integer,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

The attempt event does not claim that a write occurred. It allows bounded
reconciliation if the external call returns ambiguously.

## 13. Effect Receipt Contract

A successful provider response is normalized and validated before trace append:

```lua
{
  protocol_version = "repository.effect_receipt.v0",
  receipt_id = string,
  attempt_id = string,
  action_id = string,
  grant_id = string,
  grant_revision = integer,
  provider_id = string,
  operation = "create_text_file",
  outcome = "created",
  target = {
    relative_path = string,
    kind = "regular_file",
  },
  provider_observation = {
    bytes = integer,
    sha256 = string,
  },
  cost = {
    tool_calls = integer,
    file_writes = integer,
    time_ms = number,
  },
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

The receipt means:

```text
the body accepted a well-formed provider report for this exact attempt
```

It does not mean:

```text
the final target currently exists
the writer-reported digest is independently true
the work unit is done
```

Unknown keys, mismatched identities, impossible costs, unsupported outcome or a
digest inconsistent with the request are trusted-contract failures and remain
loud. A well-formed external denial is a typed effect failure instead.

## 14. Independent Verification Contract

The verifier is a separate read-only provider path. The write grant authorizes
it to read only the exact target named by the same action.

Implementation observation (2026-07-20, step 7.6): the lower provider primitive
is now real and independently tested. It freshly revalidates the root,
classifies the final object without following it, reads a regular file under a
hard caller bound, checks pre/post metadata and reopens the named target before
success. Missing and non-regular results contain no bytes. This observation
does not satisfy the action-owned verifier described below: deriving the path
and `expected_bytes + 1` bound from the same action, hashing ephemeral bytes
and writing bounded evidence remain step 7.7.

```lua
{
  protocol_version = "repository.verification.v0",
  verification_id = string,
  action_id = string,
  attempt_id = string,
  receipt_ref = string,
  grant_id = string,
  grant_revision = integer,
  provider_id = string,
  target = {
    relative_path = string,
    kind = "regular_file" | "missing" | "other",
  },
  observed = {
    bytes = integer | nil,
    sha256 = string | nil,
  },
  expected = {
    bytes = integer,
    sha256 = string,
  },
  verdict = "accepted" | "rejected",
  reason = string,
  cost = {
    tool_calls = integer,
    time_ms = number,
  },
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

Acceptance requires all of:

```text
exact action/attempt/receipt/grant identities
same relative target
regular final file
observed byte length == action byte length
observed SHA-256 == action SHA-256
current root identity still equals the grant
read occurred after the effect receipt in the same ☶ visit
```

The resulting `logic_validation_payload` references both receipt and
verification. A well-formed mismatch is `status=rejected`, not success. A
malformed trusted verification response is a loud invariant failure.

## 15. Runtime Work Completion

### 15.1 Completion record

On the next lawful ☱ visit, RUNTIME may append:

```lua
{
  protocol_version = "runtime.work_completion.v0",
  completion_id = string,
  work_unit_id = string,
  work_unit_version = integer,
  formation_event_ref = string,
  action_id = string,
  attempt_ref = string,
  receipt_ref = string,
  verification_ref = string,
  validation_ref = string,
  completed_status = "done",
  completed_by = "☱",
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

### 15.2 Completion gate

RUNTIME accepts completion only when:

```text
all refs resolve in immutable trace/body evidence
all ids point to the same action and exact work version
verification verdict is accepted
LOGIC validation is accepted
the verification belongs to the latest effect for this work version
the field unit remains live/selected at that exact version
no later rejected verification or conflicting effect exists
the current ☱ visit has a valid actor lease
```

### 15.3 Derived progress

Authoritative progress becomes:

```text
needed  = current executable work identities
done    = identities with one valid exact completion event
pending = needed - done
```

`calm.work_units[].status` remains a compatibility projection for old fixtures.
For `repository.create_text_file.v0`, it cannot create authoritative `done`.

Named readers:

```text
body.progress
☲ CYCLE
plan/build completion assessment
△ MANIFEST
lineage completion/corpse projection
```

## 16. Truth Matrix

| Claim | Event truth | Content truth | What it proves |
|---|---|---|---|
| substrate proposed path/content | semantic proposal event | `semantic_proposal` | proposal exists |
| ☵ formed exact unit | runtime-confirmed act | inherited proposal status | body preserved exact material |
| host grant resolved | runtime-confirmed resolution | non-semantic authority fact | capability was live for this derivation |
| action authorized | runtime-confirmed act | inherited proposal status | exact intersection was formed |
| attempt appended | runtime-confirmed act | inherited | external call was about to begin |
| receipt appended | runtime-confirmed act | provider claim remains unverified | well-formed report was received |
| verifier observed digest | runtime-confirmed observation | bytes still inherit original semantic status | exact referent existed at read-back |
| LOGIC accepted | runtime-confirmed validation | no semantic promotion | declared file predicate passed |
| RUNTIME completed work | runtime-confirmed completion | no semantic promotion | exact declared work predicate was satisfied |

File existence never proves that the code is good. Later compile/test actions add
new predicates rather than rewriting this truth.

## 17. Economics And Identity Loss

| Event | `tool_calls` | `file_writes` | `time_ms` | identity loss |
|---|---:|---:|---:|---:|
| capability/path denial before provider | 0 | 0 | measured internal time may remain body tick only | 0 |
| writer provider started | 1 | provider reports whether mutation primitive was attempted | measured | 0 |
| independent verifier started | +1 | 0 | measured | 0 |
| successful exact create + read-back | 2 total | 1 | sum actual | 0 |
| rejected read-back | actual calls | actual write attempts | actual | 0 |
| malformed trusted response | run invalid | run invalid | diagnostic only | no Packet economics certified |

The normal body tick remains charged separately by `tension_runner`.

`file_writes` counts entry into the provider's mutation primitive, not a success
claim. The provider failure/receipt contract must return actual bounded costs.

## 18. Failure Classification Matrix

| Condition | Class | Packet/body result |
|---|---|---|
| no current executable intent | not ready | no candidate/effect |
| malformed semantic action value | unsupported semantic material | no action; may create observation/dissolve pressure later |
| no matching grant before route | not ready / missing capability | candidate excluded |
| several matching grants | ambiguous capability | no canonical action |
| plan mode | not ready | mutation candidate forbidden |
| stale unit/action before route | not ready | derive current state again |
| grant revoked after route | typed effect failure | no provider call/write; real cost only |
| root identity changed | typed capability failure | no write |
| target already exists | typed effect failure `target_exists` | no overwrite, no done |
| missing/non-directory parent | typed effect failure | no final target |
| permission denied / disk full | typed effect failure | actual costs preserved |
| writer call returns ambiguously after attempt | typed unknown effect | no false receipt/done; bounded reconciliation only |
| well-formed receipt, target missing/different on read-back | rejected verification | Packet-world evidence, no done |
| receipt identity/cost/schema malformed | invariant failure | loud harness failure, no honest corpse |
| verifier schema/identity malformed | invariant failure | loud harness failure |
| provider escapes root or overwrites target | security/body invariant failure | loud; provider treatment rejected |
| completion refs cross action/work identities | invariant failure | loud, no progress |
| Lua exception | invariant failure | loud, no grave/lineage inheritance |

## 19. Retry And Replay Table

| Observed state | Prior exact attempt in current valid trace | Result |
|---|---:|---|
| target absent | any | execute create once |
| target exists with different digest | any | conflict/effect failure |
| target exists with expected digest | no | conflict; matching bytes do not prove our action |
| target exists with expected digest | yes, but no receipt | bounded `ambiguous_effect` reconciliation candidate; never automatic success in v0 |
| same action id, changed envelope | any | invariant failure |
| same completed action requested again | exact completion exists | no new effect; already completed |

Crash recovery is not implemented, so the ambiguous branch records residue or
blocks. A later persistent action journal may promote a safe `already_applied`
outcome. V0 does not guess.

## 20. Reader And Writer Matrix

| Record | Writer | First named reader | Discharge/effect reader |
|---|---|---|---|
| strict structure item | substrate proposal captured by ☴ | ☵ structure formation | repository intent inspection |
| repository intent | pure derived inspection | pressure/action planner | capability resolver |
| private grant | trusted session host | capability resolver | provider request materializer |
| capability projection | capability resolver/route evidence | registry readiness and audit | receipt/verification validators |
| authorized action | body action planner | route candidate/☶ readiness | provider materializer |
| uncontested action review | ☱ | repository-effect pressure producer | ☶ readiness |
| effect attempt | ☶ body event | provider result reconciler | receipt/ambiguity reader |
| effect receipt | ☶ after schema validation | read-only verifier | ☶ validation and ☱ completion gate |
| repository verification | ☶ read-only path | LOGIC validation | ☱ completion gate |
| LOGIC validation | ☶ | ☱ reconciliation | completion/manifest honesty |
| work completion | ☱ | body.progress | ☲/△/lineage completion |

Every persisted record has a named reader. Derived intent/action plans live for
one derivation and enter history only through immutable route/effect projections.

## 21. Capability Matched Controls G0-G12

| ID | One changed variable | Required result |
|---|---|---|
| G0 | no grant | no executable ☶ candidate; no external call |
| G1 | substrate text names a plausible grant id | identical to G0 |
| G2 | one exact active lineage grant | one authorized action |
| G3 | same grant, wrong session | no match |
| G4 | same grant, wrong lineage | no match, including descendant of another lineage |
| G5a | same lineage, next generation, root still unclaimed | grant may resolve provisionally; root remains unclaimed |
| G5b | same lineage, next generation after first authority consumption | denied before provider call; owner claim remains |
| G6 | grant revoked before derivation | candidate excluded |
| G7 | grant revoked after route commitment | typed effect failure, zero provider writes |
| G8 | two matching grants | typed ambiguity, no canonical selection |
| G9 | create operation removed only | intent remains, executable action disappears |
| G10 | mutate returned public projection | private grant and future resolution unchanged |
| G11 | repo-A grant with repo-B intent/root substitution | denied before effect |
| G12 | plan mode with otherwise valid grant/action | no mutation candidate |

## 22. Path And Provider Controls P0-P17

| ID | One path/provider condition | Required result |
|---|---|---|
| P0 | valid bounded `src/main.lua`, absent target, real parents | create succeeds |
| P1 | absolute path | rejected before authorization |
| P2 | `..` component | rejected before authorization |
| P3 | `.` or empty component | rejected before authorization |
| P4 | leading-dot/control component | rejected before authorization |
| P5 | invalid UTF-8/NUL/control byte | rejected before authorization |
| P6 | path exceeds grant bound | rejected before authorization |
| P7 | content invalid UTF-8/NUL | rejected before authorization |
| P8 | content exceeds grant bound | rejected before authorization |
| P9 | repository root is symlink | grant cannot be minted |
| P10 | existing parent component is symlink | provider denies, no outside mutation |
| P11 | final target is symlink | provider denies, target unchanged |
| P12 | parent missing/not directory | typed effect failure, no final target |
| P13 | final target already exists | typed conflict, no overwrite |
| P14 | provider root inode/fingerprint changed | capability invalidated, no write |
| P15 | parent resolves through bind mount/cross-device escape | provider denies, no outside mutation |
| P16 | provider attempts partial final visibility | test rejects provider contract |
| P17 | provider receives no command/shell field | arbitrary command cannot be expressed |

P9-P16 must use real filesystem objects grown inside one unique test-owned root
where the host permits that fixture. An unsupported mount fixture is an explicit
environmental skip, never a false green.
Tests clean only identities they created.

## 23. Action And Choice Controls A0-A12

| ID | One changed variable | Required result |
|---|---|---|
| A0 | exact single artifact item | one intent; no ☳ pressure/loss |
| A1 | two required artifact items | two required work items; no mutual suppression |
| A2 | two explicit mutually-exclusive items | real ☳ collapse; one selected |
| A3 | same source unit/version/content | same intent id |
| A4 | change path only | new intent/action id |
| A5 | change content only | new digest and intent/action id |
| A6 | change grant revision only | same intent, new authorized action id |
| A7 | change Packet generation only | same intent material, new action id |
| A8 | suppress/dissolve source unit | action disappears |
| A9 | mutate caller copy of intent/action | stored field/route action unchanged |
| A10 | stale source version before dispatch | no provider call |
| A11 | caller supplies `options.logic.spells` only | cannot satisfy repository action mode |
| A12 | route scope differs from action work ref | invariant/qualified-action rejection |

## 24. Effect, Verification And Progress Controls E0-E15

| ID | Grown condition | Required result |
|---|---|---|
| E0 | valid action/provider | attempt -> receipt -> verification accepted |
| E1 | commit route only, do not execute ☶ | no attempt/receipt/file/completion |
| E2 | append attempt, provider denies | typed failure, no receipt/done; actual cost only |
| E3 | writer receipt claims success, verifier sees missing | rejected verification, no done |
| E4 | writer receipt digest differs from action | loud trusted-contract failure |
| E5 | verifier response identity malformed | loud failure, no Packet death/grave |
| E6 | verification accepted but ☱ not visited | no completion/done yet |
| E7 | ☱ sees exact accepted chain | one completion event, progress done=1 |
| E8 | same ☱ state repeated | no duplicate completion |
| E9 | accepted evidence for action A offered to work B | rejected loudly/no B completion |
| E10 | source field version changes after evidence | old evidence cannot complete new version |
| E11 | later rejected effect for same current work version | no false current completion |
| E12 | mutate returned receipt/verification/completion | stored history unchanged |
| E13 | successful effect | budget charges actual tool/write/time, loss unchanged |
| E14 | pre-effect capability denial | no tool/write charge beyond normal tick |
| E15 | all work completed from exact ledger | ☲/△ readers see remaining=0 |

## 25. Route And Ablation Controls R0-R10

| ID | Grown life | Required route/effect property |
|---|---|---|
| R0 | one artifact, hand policy disabled | current legacy/shadow life unchanged |
| R1 | one artifact, qualified hand enabled, no grant | typed capability exclusion/stall; no write |
| R2 | one artifact, exact grant | eventual `☵ -> ☱ -> ☶ -> ☱` subpath; no ☳ |
| R3 | real alternative set, exact grant | eventual `☵ -> ☴ -> ☳ -> ☶ -> ☱` subpath; field-native coverage precedes real choice |
| R4 | remove only action-review witness | single-action ☱ proposal disappears |
| R4b | commit review edge but mismatch/remove review effect | repository-effect proposal disappears |
| R5 | remove only repository-effect witness | ☶ proposal/effect disappears |
| R6 | remove only reconciliation witness | file/evidence may exist; completion does not |
| R7 | receipt only, verifier disabled | no accepted validation/completion |
| R8 | exact accepted chain | one file, one completion, verified manifest input |
| R9 | same normal non-hand corpus before/after modules | routes, budgets, loss, revisions and terminal equal |
| R10 | tree remains shadow/default setting unchanged | no hidden authority promotion |

Route assertions allow lawful OBSERVE or other higher-class interventions. They
assert the required causal subpath, not one hardcoded full life.

## 26. False-Green Matrix

| False green | Rejecting control |
|---|---|
| LLM names a capability and gains power | G0-G2 |
| whole sandbox treated as one repository | G11 + P9/P14 |
| lexical path check called containment | P9-P15 |
| check-then-open called atomic | P13/P16 |
| one work item forced through CHOOSE | A0/R2 |
| required artifacts killed as alternatives | A1/A2 |
| caller spell called body-owned action | A11 |
| committed route called an effect | E1 |
| writer success called verification | E3/R7 |
| accepted verification immediately called done | E6 |
| CALM status manually creates exact completion | E7/E9 exact-ledger assertion |
| stale action/evidence finishes changed work | A10/E10 |
| denied call counted as write | E14 |
| malformed provider response becomes honest death | E4/E5 |
| new modules silently alter old lives | R0/R9 |
| hand work used to promote Tree authority | R10 |

## 27. Existing Helper Disposition

| Existing helper | v0 disposition | Reason |
|---|---|---|
| `core/sandbox.lua` | retain for legacy/docs; not repository authority | lexical path checks only |
| `tools/fs.lua` | do not connect | raw `io.open`, shell `find/mkdir`, no capability/action/evidence |
| `tools/contract.lua` | do not extend in place as authority | action-name allowlist without exact schemas |
| `logic/spells.lua` | retain compatibility tests; repository mode cannot use arbitrary spell input | caller-owned commands and weak path/hash boundary |
| `core/digest.lua` | reuse | tested SHA-256 and canonical record hashing |
| `substrates.contract.effect_failure` | reuse behavior, crystallize body-owned placement/alias | typed failure shape already enforced |
| `runtime/operator_registry.lua` | extend through exact capability resolver | current boolean capability check is insufficient |
| `runtime/pressure_action.lua` | extend/revise exact mode | already provides route-carried same-ref actions |
| `runtime/body.lua` work helper | compatibility only | manual status mutation has no exact evidence event |
| `runtime/trace_store.lua` | unreachable non-goal, fence before product exposure | arbitrary standalone output path |

## 28. Implementation Sequence Predicted By TABLE

This is not permission to implement before CRYSTALL. It fixes dependency order:

```text
1. crystallize exact intent, grant projection, action, attempt, receipt,
   verification and completion schemas
2. crystallize trusted provider semantics and invocation boundary
3. grow G/P/A/E/R red tests with a unique test root and fake/real providers
4. implement host capability registry and pure intent/action resolution
5. implement the real no-follow atomic create provider
6. integrate repository mode into qualified pressure and ☶
7. integrate ☱ completion ledger and derived body.progress
8. run focused controls after each boundary
9. run full Lua, mortality, camera, lineage and hand-disabled ablations
10. grow one real repository life and only then manifest treatment
```

## 29. Explicit Deferrals

```text
overwrite, patch, append, delete, rename and mkdir
arbitrary commands and test runner
multi-file scheduling and transactions
git capabilities
general repository read/search tools
binary file content
spaces, Unicode and leading-dot paths
persistent action journal and crash recovery
safe already-applied replay promotion
out-of-band filesystem watcher/truth-rent after completion
provider conversation continuity
CLI/TUI capability management
numeric pressure calibration
default Tree promotion
fencing every standalone internal writer
```

## 30. Table Acceptance

This table may feed CRYSTALL only if all statements remain explicit:

```text
authority comes from a host registry, never semantic text
one grant means one lineage and one repository root
intent and authorized action have different identities
the first operation cannot overwrite or invoke shell
filesystem containment depends on no-follow/atomic provider semantics, not text
single work and required artifact sets are not fake choices
receipt, verification and completion are three different facts
☱ completion is immutable and body.progress derives from it
failure classes preserve the body/world boundary
every new stored record has a named reader
matched controls can falsify each claimed property
legacy lives and router authority remain unchanged while the hand is opt-in
```

## 31. Roadmap 7.7 Implementation Observation

Status: runtime evidence recorded 2026-07-20 in
`docs/00_chaos/first_repository_hand_effect_progress_results_2026-07-20.md`.

The TABLE chain through effect and exact progress is now material:

```text
action -> attempt -> one-use lease -> create receipt -> independent read-back
       -> verification -> LOGIC validation -> ☱ completion -> body.progress
```

Measured controls:

```text
repository-effect:       14/14 green
repository-progress:      9/9 green
real Linux effect chain:  1/1 green
staged hand suites:       11 green / 1 red
normal body suites:       80/80 green
```

The remaining red suite is route integration, which this implementation was
required not to authorize. The direct LOGIC branch and ☱-owned completion
mechanism exist; qualified pressure, operator-registry host-service propagation,
automatic RUNTIME reconciliation and runner cost charging remain later work.

One layering correction is now part of the table: the native provider owns the
hard read/allocation bound, while LOGIC owns expected length/digest comparison
and raw-byte non-disclosure. A well-formed mismatch is rejected evidence; an
unknown or malformed provider record remains loud.

## 32. Roadmap 7.8 Hostile Audit Observation

Status: runtime evidence recorded 2026-07-20 in
`docs/00_chaos/first_repository_hand_hostile_audit_results_2026-07-20.md`.

The composition boundary now has the following additional guards:

| Boundary | Hostile condition | Required guard |
|---|---|---|
| action -> lease | caller mutates action projection | revalidate against current Packet before spending dispatch |
| lease -> request | caller adds or omits a field | exact plain request schema; no silent strip |
| grant -> old lease | revoke/quarantine changes revision | issuance revision plus active-state check on every lease operation |
| provider -> failure | cyclic/metatable/arbitrary residue | exact bounded relative-residue projection or loud failure |
| body -> trace | generic writer names completion | repository body event requires dedicated writer |
| trace -> progress | completion becomes stale/conflicted | reread and revalidate full chain on every `is_complete` |

Measured controls:

```text
hostile Lua composition:       16/16 green
repeated real Linux lives:      2/2 green
staged hand suites:            12 green / 1 route red
ordinary body suites:          80/80 green
native repeated transactions: 128 with zero fd delta
```

One false-green rule is now explicit: a revoked-lease test must use the current
revoked revision, otherwise it proves only stale-request rejection. State
transition and revision mismatch are separate guards and require separate
evidence.

No pressure, router, operation or route claim changed in 7.8.

## 33. Roadmap 7.9 Route Promotion Observation

Status: runtime evidence recorded 2026-07-20 in
`docs/00_chaos/first_repository_hand_route_promotion_results_2026-07-20.md`.

The previously separate mechanics now form one opt-in Tree life:

| Phase | Named reader | Target | Stored fact |
|---|---|---|---|
| exact singular action | repository phase inspector | ☱ | `repository_action_review` |
| selected/reviewed affordable action | repository phase inspector | ☶ | attempt, receipt, verification, validation |
| accepted current effect chain | repository phase inspector | ☱ | `work_completion` |
| successful/rejected effect cost | tension runner | budget | one central `repository_effect` charge |

Observed routes:

```text
one item:     ▽ -> ☴ -> ☵ -> ☱ -> ☶ -> ☱
alternatives: ▽ -> ☴ -> ☵ -> ☴ -> ☳ -> ☶ -> ☱
```

The extra upper observation in the alternative route is evidence, not a rail:
ENCODE changed field versions and CHOOSE required current versioned coverage.
The singular action creates no fake choice and no choice loss.

The private registry is transported separately from route-carried options.
Review, effect and reconciliation share exact action/work/grant scope refs.
Disabled, unauthorized and unaffordable hands create no provider call. Matched
review/effect/reconcile ablations remove only their respective causal phase.

Measured controls:

```text
repository route controls              11/11 green
staged repository battery              13/13 green
ordinary registered Lua corpus         90 suites green
mortality                                8/8 green
native hostile/analyzer/sanitizer       green
```

This table now authorizes only repository result manifestation in 7.10. It does
not authorize a wider operation, a fixed route or default Tree promotion.

## 34. Roadmap 7.10 Repository Result Projection Table

Status: contract selected 2026-07-20 from
`docs/00_chaos/first_repository_hand_manifest_plan_2026-07-20.md`.

### 34.1 Terminal Reader Chain

| Existing fact | Named reader | Derived fact | Consumer |
|---|---|---|---|
| current `runtime.work_completion.v0` | repository result resolver | exact completed artifact projection | △ readiness/run |
| accepted verification event | repository result resolver | observed bytes/SHA-256/path | `repository.result.v0` |
| action + completion event ref | qualified pressure | `repository_delivery_need` | Tree router |
| committed repository delivery plan | MANIFEST | `manifest_payload` | Packet terminal/freeze |

No new mutable completion ledger is introduced. The result is derived again
from field and trace at readiness, execution and qualified-effect verification.

### 34.2 Projection Matrix

| Output field | Source | Truth |
|---|---|---|
| Packet/lineage/generation | Packet identity | runtime-confirmed |
| repository id | public action projection | runtime-confirmed authorization fact |
| relative path/operation | current exact action | runtime-confirmed action binding |
| target kind/bytes/SHA-256 | accepted independent verification | runtime-confirmed observation |
| action/work/completion refs | immutable trace/action chain | runtime-confirmed provenance |
| content origin status | action | preserved, never promoted |
| result id | deterministic digest of projection | runtime-confirmed assembly |

The projection carries no raw bytes, absolute/root path, private grant object,
provider object, handle, lease, command or shell field.

### 34.3 Route And Failure Table

| State at ☱ | Delivery pressure | Result |
|---|---|---|
| exact current completion, remaining=0 | qualified terminal witness to △ | one repository manifest |
| completion absent | none | continue/stall/death by existing physics |
| verification rejected | none | never complete repository output |
| completion stale/conflicted | none | old completion is inert |
| committed plan becomes malformed/stale | readiness/effect mismatch | loud harness failure |
| delivery reader ablated | none | completion remains internal |

### 34.4 Economics And Authority

| Stage | Steps | Tool calls | File writes | Loss | Authority |
|---|---:|---:|---:|---:|---|
| prior ☶ effect | ordinary tick | actual 2 | actual 1 | 0 | one-use hand |
| ☱ completion | ordinary tick | 0 | 0 | 0 | Packet trace only |
| △ delivery | ordinary tick | 0 | 0 | 0 | Packet trace only |

△ receives no host services. The default router remains shadow. The only live
delivery route is opt-in Tree authority over the already demonstrated hand.

### 34.5 Acceptance Controls

M0-M10 from the CHAOS plan become a dedicated registered suite. Acceptance
requires exact `☱ -> △`, deterministic output under runner-text substitution,
delivery ablation, rejected/stale evidence denial, recursive non-disclosure and
no second effect charge.

## 35. Roadmap 7.10 Implementation Observation

Status: runtime evidence recorded 2026-07-20 in
`docs/00_chaos/first_repository_hand_manifest_results_2026-07-20.md`.

The predicted terminal chain is material:

```text
single:       ▽ -> ☴ -> ☵ -> ☱ -> ☶ -> ☱ -> △ -> dead/complete
alternatives: ▽ -> ☴ -> ☵ -> ☴ -> ☳ -> ☶ -> ☱ -> △ -> dead/complete
```

The terminal reader reconstructs completion at readiness, execution and effect
verification. `repository.result.v0` is deterministic under changed runner
text, detached from the runner payload and recursively free of raw content and
host authority.

Observed controls:

```text
M0-M10 repository manifestation       11/11 green
repository hand battery               14/14 green
registered corpus                     91 suites green
production C-provider end-to-end       1/1 green
mortality                               8/8 green
native analyzer/sanitizer               green
```

Delivery ablation leaves exact completion internal. Rejected read-back and
stale completion cannot become a complete repository result. △ adds one step,
zero tools, zero writes and zero identity loss.

The first repository-hand TABLE campaign is complete for its selected v0
surface. Future operation widening requires a new table, not an amendment that
silently changes `create_text_file`.
