# Post-Collapse Plan Delivery Manifest v0

Status:

```text
manifest
bounded treatment implemented and locally verified 2026-07-19
source chaos: docs/00_chaos/post_collapse_plan_delivery_notes_2026-07-19.md
source table: docs/01_table/yellowprints/post_collapse_plan_delivery_yellowprint.v0.md
source crystall: docs/02_crystall/blueprints/post_collapse_plan_delivery.v0.md
bounded producer promotion: accepted inside qualified_need_v0
default router authority promotion: blocked and not authorized
decision truth status: document_decision
```

## Result

The exact structure/choice treatment no longer ends at an unexplained
post-collapse stall in plan mode. The body now owns one complete terminal
chain:

```text
exact current plan material at ☴
  -> plan_completion_review
  -> ☱ reconciles consequences and records a complete assessment
  -> plan_delivery
  -> △ projects plan.result.v0 from Packet state
  -> manifest terminal
  -> dead/complete corpse
```

The two grown lives are:

```text
work_sequence:    ▽ -> ☴ -> ☵ -> ☴ -> ☱ -> △
alternative_set: ▽ -> ☴ -> ☵ -> ☴ -> ☳ -> ☴ -> ☱ -> △
```

No direct `☴ -> △` edge was added. The existing topology remains the law:
upper sight reaches the lower boundary through RUNTIME, and only RUNTIME may
offer the completed assessment consumed by MANIFEST.

## Packet Work Regime

Work mode is now an immutable birth fact:

```lua
packet.regime.work = {
  protocol_version = "packet.work_regime.v0",
  mode = "plan" | "build",
}
```

`metadata.work_mode` is retained only as a compatibility mirror. Conflicting
runner, packet-option and metadata declarations fail at birth. Absence defaults
to `build`. The legacy router reads the canonical regime before the mirror.

This closes the old ambiguity where plan completion could depend on a transient
runner option rather than on the Packet being judged.

## Completion Contract

`runtime/plan_completion.lua` is a pure reader/projector. It grants no mutation
right and accepts only one current exact formation in plan mode.

Complete material requires:

```text
strict packet.structure.proposal.v0 formation proof
current formed ids and exact versions
current field-native material coverage for every version
zero omitted items and edges
zero truncation
shape-correct activation/choice partition
valid hierarchy endpoints
no current rejected validation
```

Supported shapes are:

```text
work_sequence
work_hierarchy
artifact_set
alternative_set
```

One alternative is confirmation and creates no CHOOSE event. Two or more
alternatives require one exact collapse, one selected member, all other members
suppressed, and fresh post-choice coverage for both survivor and suppressed
forms.

Missing, stale, partial, ambiguous and broken material remain different typed
states. In particular, a damaged formation is `blocked`; it cannot disappear
into the weaker claim that no plan exists.

Direct inspection retains normal absence reasons such as `plan_mode_absent`.
Qualified composition does not promote those reasons into unqualified defects:
an inapplicable plan consumer is absence of pressure, not broken body physics.

## Runtime Assessment

The blocking consumer is:

```text
runtime.plan_completion.v0
```

At ☴ it joins the exact candidate to significant pending camera consequences.
The committed `plan_completion_review` action pins:

```text
candidate identity
formed ids and versions
material coverage refs
optional choice event
camera watermark and significant frame refs
relevant Packet revisions
```

☱ rederives that scope, reconciles the camera, and is the sole writer of
`plan_completion_assessment`. Repeating the same review returns
`plan_completion_already_assessed`; it cannot append a second assessment.

An assessment becomes stale when its exact material or relevant Packet
revisions change. Stale assessment is a typed diagnostic and creates no
terminal witness.

## Packet-Local Delivery

The terminal consumer is:

```text
manifest.plan_delivery.v0
```

At ☱ it joins one current complete assessment to one exact `plan_delivery`
action. △ resolves the assessment and projects every item from current field
units in frozen formation order. It does not read selected ids, text or ticks
from the runner result.

The outward payload contains:

```text
kind = manifest_payload
mode = plan_delivery
output.type/status = plan/complete
output.structured.protocol_version = plan.result.v0
assembly.rule = plan_delivery.v0
assembly.input_provenance = packet_state
terminal_cause = complete
```

Suppressed alternatives remain in residue with visible choice loss. Formation
loss remains visible even when it has zero omission. `output.text` is the
canonical JSON encoding of the structured result.

## Truth Boundary

The body confirms only its own acts:

```text
formation, observation, collapse, assessment, assembly, death
  = runtime_confirmed

the model-authored item content inside the delivered plan
  = semantic_proposal (or its inherited content status)
```

A runtime-confirmed plan manifest therefore means "the body assembled this
exact current plan completely", not "every recommendation in the plan is true
or good".

## Negative Gates

The permanent corpus rejects:

```text
build mode using plan completion
ordinary prose impersonating exact plan material
unobserved or stale formed versions
unresolved alternatives
selected-only post-choice sight
omitted/truncated structure called complete
damaged or dissolved formation members
forged candidate, action or effect scope
route commitment creating the receiving organ's effect
stale assessment reaching MANIFEST
runner text/tick/result injection changing qualified output
review or delivery ablation acquiring physical mass in shadow mode
```

Compatibility MANIFEST remains available without `plan_input`. It is not
evidence for this exact treatment.

## Evidence

```text
lua tests/run.lua                               67 suites passed
tests/test_plan_completion.lua                  passed
tests/test_plan_delivery.lua                    passed
tests/test_post_collapse_plan_life.lua          passed
tests/test_encode_choose_pair.lua               passed with terminal extension
lua tests/smoke_mortality_battery.lua           8/8 passed
lua tests/smoke_runtime_camera_treatment.lua    passed
lua tests/smoke_pressure_ablation.lua           passed
luac -p over all Lua sources                    passed
git diff --check                                passed
```

The previous live DeepSeek strict-form smoke remains valid evidence that the
substrate can produce both accepted envelopes. It was recorded before this
terminal treatment and therefore stopped after the final ☴. No new live model
call was needed to prove the Packet-local assessment and assembly physics.

## Promotion Decision

```text
plan completion/delivery inside qualified_need_v0: ACCEPTED
explicit tree treatment use:                     ACCEPTED
generic prose completion:                         BLOCKED
build completion and repository hands:            NOT IMPLEMENTED
partial or multi-formation plan delivery:          NOT IMPLEMENTED
default router authority change:                   BLOCKED / NOT REQUESTED
```

## Next Bounded Pressure

The plan branch now ends honestly. The next product-bearing boundary is the
build branch:

```text
exact selected work exists
but no repository reality has changed
-> capability-safe hand action
-> fresh LOGIC evidence
-> ☱ confirms progress
-> ☲ continues or △ delivers verified work
```

That branch must begin with chaos/table work around capability, sandbox,
work-unit state transition and evidence. This manifest does not authorize a
generic shell tool, silent file mutation, semantic "done" claims, or default
tree promotion.
