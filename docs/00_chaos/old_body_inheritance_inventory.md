# Old Body Inheritance Inventory

Status:

```text
first pass
not final
```

Old body archive:

```text
path: /home/slasten/work/procesis-body
branch: old-body-lab
commit: 02dfdf8
remote: git@github.com:slasten3826/proc-17.git
```

New body:

```text
path: /home/slasten/work/proc-17-next
git: not initialized
role: clean-room current body
```

## Decision Classes

```text
copy_now      = safe useful artifact for new main
copy_later    = useful, but should wait until matching organ exists
rewrite_later = concept is useful, implementation/docs conflict with new body
archive_only  = keep in old-body-lab, do not publish as current main
drop          = generated/runtime trash, not repo material
```

## Top-Level Files

`README.md`

```text
decision: rewrite_later
reason: old README explains CLI-first body; new README must explain packet/router/tension_runner first.
```

`BODY_SPEC.md`

```text
decision: copy_later
reason: useful high-level body description, but minimal coding loop is old fixed-loop shape.
action: extract principles, rewrite around tension runner.
```

`PACKET_SPEC.md`

```text
decision: copy_now_with_revision
reason: packet identity/budget/residue sections are still useful.
action: merge with new loss/budget separation and packet.next.v0 fields.
```

`SUBSTRATE_SPEC.md`

```text
decision: copy_now_with_revision
reason: substrate separation is still core.
action: align with current rule: DeepSeek enters only through ☴ as semantic_proposal.
```

`.gitignore`

```text
decision: copy_now_with_revision
reason: new main needs ignore rules before GitHub update.
action: include .env, logs/, sandbox/, *.jsonl, *.log, *.tmp, __pycache__/.
```

## Core / Logic / Runtime

`core/json.lua`, `core/modes.lua`, `core/sandbox.lua`, `core/topology.lua`

```text
decision: already_rebuilt_or_present
reason: new body already has these.
action: compare only if a specific test exposes missing behavior.
```

`core/packet.lua`

```text
decision: archive_only
reason: replaced by packet.next.v0 in proc-17-next.
```

`logic/encode.lua`, `logic/choose.lua`, `logic/cycle.lua`, `logic/manifest.lua`, `logic/repo_selection.lua`

```text
decision: already_rebuilt_or_present
reason: new body already contains current variants.
action: keep new versions as source of truth.
```

`runtime/operator_hints.lua`, `runtime/system_prompt.lua`, `runtime/trace_store.lua`

```text
decision: already_present
reason: new body has these modules.
action: keep, retest after README/spec migration.
```

`runtime/pressure_snapshot.lua`

```text
decision: rewrite_later
reason: old module expects old packet shape in places; new runtime eye now lives inside tension_runner.
action: later rebuild as packet.next-compatible ☱ payload module.
```

## Old CLI

`cli/procesis-body.lua`

```text
decision: rewrite_later
reason: old CLI is useful as interface reference, but it owns too much route logic.
action: do not copy as main. Later build a new CLI around runtime/tension_runner.lua.
```

## Organs Missing In New Body

`organs/repo_listing.lua`

```text
decision: copy_later
reason: useful future ☴ capability for runtime-confirmed repo observation.
blocker: needs integration with new tension runner and sandbox root.
```

`organs/repo_context.lua`

```text
decision: copy_later
reason: useful future ☴ capability for selected file context.
blocker: needs new packet source refs and runtime truth contract.
```

## Tools / Sandbox

`tools/fs.lua`, `tools/contract.lua`, `tools/fake.lua`

```text
decision: already_present_but_review
reason: new body has tools; old workspace sandbox work may contain useful constraints.
action: keep new files for now, later compare against workspace_sandbox docs/tests.
```

`sandbox/`

```text
decision: drop_from_main
reason: generated/test projects, pycache, local runtime state.
action: keep only in old-body-lab archive.
```

## Logs

`logs/cognitive_battery/`

```text
decision: archive_only
reason: valuable research data, but too bulky/noisy for current clean main.
action: keep old-body-lab; maybe later extract summarized docs only.
```

`logs/mode_probe/`, `logs/atm_emulator/`, `logs/tictactoe_ai/`, `logs/notes_app_multifile/`, `logs/workspace_write_smoke/`, `logs/self_gap_organogenesis/`

```text
decision: archive_only
reason: useful history/test evidence, not current repo runtime surface.
action: do not copy into new main.
```

## Old Chaos Docs: Copy Now With Revision

These should be brought into new main, but rewritten against `proc-17-next`.
They contain invariants that are still alive, not final old wording.

```text
docs/00_chaos/body_kernel.md
docs/00_chaos/cognitive_wrapper_packet_notes.md
docs/00_chaos/packet_lifecycle_notes.md
docs/00_chaos/packet_chaos_calm_architecture_notes.md
docs/00_chaos/encode_code_only_boundary.md
docs/00_chaos/two_eyes_runtime_notes.md
docs/00_chaos/unsupported_form_protocol.md
docs/00_chaos/organogenesis_notes.md
docs/00_chaos/pressure_topology_notes.md
docs/00_chaos/substrate_and_language_choice.md
docs/00_chaos/operator_runtime_hints_notes.md
docs/00_chaos/plan_build_hints_modes.md
docs/00_chaos/plan_build_mode_request.md
docs/00_chaos/procesis_word_and_organ_routing.md
docs/00_chaos/encode_operator_notes.md
docs/00_chaos/choose_operator_notes.md
docs/00_chaos/logic_validator_notes.md
docs/00_chaos/manifest_operator_notes.md
docs/00_chaos/encode_quality_before_choose_notes.md
docs/00_chaos/encode_choose_shape_notes.md
docs/00_chaos/body_modes_notes.md
docs/00_chaos/proc17_myth_notes.md
docs/00_chaos/completed_form_myth_notes.md
```

Reason:

```text
they explain invariants still alive in proc-17-next:
wrapper owns process control, substrate is semantic current, packet is mortal,
semantic output is not runtime truth, ☵ owns field formation, ☳ stays stupid,
plan/build are process modes, and the router must be body-owned.
```

Risk:

```text
some wording assumes old body topology, old CLI route, or old hint wording.
Copying verbatim would reintroduce stale fixed-route pressure.
```

Rewrite rules:

```text
replace old fixed route with tension_runner/router language
keep coding-body boundary, not general philosophical text interpreter
keep "procesis word" as canonical orientation, not runtime evidence
keep plan/build split, but map it to current work_mode contract
keep packet loss/budget separation from the new packet architecture
rewrite myth notes as proc-17 origin/meaning notes, not as current engineering spec
```

## Old Chaos Docs: Do Not Migrate Now

These are useful as old pressure, but should not be copied into the new main.
If the pressure returns, create a fresh proc-17-next document from current
architecture instead of migrating old text.

```text
docs/00_chaos/connect_operator_notes.md
docs/00_chaos/dissolve_operator_notes.md
docs/00_chaos/cycle_operator_notes.md
docs/00_chaos/machine_cli_notes.md
docs/00_chaos/glyph_first_interface_notes.md
docs/00_chaos/sandbox_policy_notes.md
docs/00_chaos/eva_inheritance_notes.md
```

Reason:

```text
the concepts are useful, but the current new body is not ready to expose them
as main architecture. CONNECT/DISSOLVE/CYCLE/CLI/TUI/sandbox should be born
again from packet/tension pressure, not inherited from the old CLI-first body.
```

## Old Chaos Docs: Archive Only

These should stay in `old-body-lab` as evidence/history unless a later task
explicitly extracts a small invariant from them.

```text
docs/00_chaos/processlang_lua_source_notes.md
docs/00_chaos/slop_operator_direction_candidate.md
docs/00_chaos/operator_readiness_notes.md
docs/00_chaos/runtime_manifestation_notes.md
docs/00_chaos/live_deepseek_default_organs_notes.md
docs/00_chaos/ignition_tests_notes.md
docs/00_chaos/deepseek_next_pressure_notes.md
docs/00_chaos/reflection_model_tests_notes.md
docs/00_chaos/procesis_word_live_smoke_results.md
docs/00_chaos/tictactoe_ai_speed_test_results.md
docs/00_chaos/cognitive_test_battery_codex_candidate.md
docs/00_chaos/cognitive_test_battery_user_candidate.md
docs/00_chaos/cognitive_battery_codex_results.md
docs/00_chaos/cognitive_battery_user_results.md
docs/00_chaos/cognitive_battery_hints_results.md
docs/00_chaos/plan_build_mode_probe_battery.md
```

Reason:

```text
they are valuable research residue, not current source of truth.
The cognitive batteries are useful benchmarks, but proc-17-next is now scoped
as coding-body first. Historical live results should inform future tests, not
become main architecture docs.
```

Special note:

```text
slop_operator_direction_candidate is explicitly controversial and non-verbatim.
Do not migrate it as canon. If operator scripture snippets are tested again,
use a separate verbatim extraction created by the user, then compare it against
the compressed candidate as an experiment.
```

## Old Table / Crystall Docs: Do Not Migrate

Do not migrate old table/crystall documents into the new main.

```text
docs/01_table/yellowprints/repo_listing_eye_yellowprint.v0.md
docs/02_crystall/blueprints/repo_listing_eye.v0.md
docs/01_table/yellowprints/repo_context_eye_yellowprint.v0.md
docs/02_crystall/blueprints/repo_context_eye.v0.md
docs/01_table/yellowprints/repo_selection_validator_yellowprint.v0.md
docs/02_crystall/blueprints/repo_selection_validator.v0.md
docs/01_table/yellowprints/sandbox_policy_yellowprint.v0.md
docs/02_crystall/blueprints/sandbox_policy.v0.md
docs/01_table/yellowprints/workspace_sandbox_yellowprint.v0.md
docs/02_crystall/blueprints/workspace_sandbox.v0.md
docs/02_crystall/blueprints/tool_facade.v0.md
docs/02_crystall/blueprints/trace_store.v0.md
docs/01_table/yellowprints/body_yellowprint.v0.md
docs/02_crystall/blueprints/body_blueprint.v0.md
docs/01_table/yellowprints/packet_protocol_yellowprint.v0.md
docs/02_crystall/blueprints/packet_protocol.v0.md
docs/01_table/yellowprints/cycle_decision_yellowprint.v0.md
docs/02_crystall/blueprints/cycle_decision.v0.md
docs/01_table/yellowprints/machine_cli_yellowprint.v0.md
docs/02_crystall/blueprints/machine_cli.v0.md
```

Reason:

```text
old table/crystall documents encode the old fixed route and old packet protocol.
New table/crystall must be generated from proc-17-next chaos and current code.
```

## Old Historical Patterns: Archive Only

This older coarse rule is kept as a fallback for any old lab file not named
above.

```text
docs/00_chaos/*_results.md
docs/00_chaos/*_test_plan.md
docs/00_chaos/*_test_results.md
```

Reason:

```text
historical evidence, not current architecture. If a result file contains a
still-useful invariant, extract the invariant into a new proc-17-next note
instead of copying the old result file.
```

## Immediate Next Step

Before replacing GitHub main:

```text
1. switch /home/slasten/work/procesis-body back to main
2. clean old worktree contents
3. copy proc-17-next contents into procesis-body
4. add .gitignore
5. write new README
6. copy/rewrite PACKET_SPEC and SUBSTRATE_SPEC
7. run lua tests/run.lua
8. review status before commit
```

Do not push until user explicitly asks.
