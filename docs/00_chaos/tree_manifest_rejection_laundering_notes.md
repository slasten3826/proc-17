# Tree Manifest Launders Rejected Validation

Status:

```text
chaos / defect report
author: claude (Mythos/Fable)
found: 2026-07-17, cold review of checkpoint 78a627e
severity: high for step 4-5 promotion; does not block step 3
class: manifest laundering / writer without reader
gate impact: passes tests/test_tree_authority.lua case
             rejected_validation_stays_inside_body
```

## Repro

```lua
local p = assert(tension_runner.run("build notes app", fake, {
    work_mode = "build",
    router_mode = "tree",
    max_ticks = 20,
    packet_options = {budget = {steps = 32, substrate_calls = 8,
                                encode_items = 8, loss = 10}},
    choose = {limits = {max_selected = 1, max_killed_sample = 8}},
    logic = {spells = {{
        kind = "check_file_exists",
        name = "probe",
        intention = "x",
        path = "sandbox/definitely_missing_runtime_probe.py",  -- fails
    }}},
}))
```

Observed:

```text
walk:                     ▽ ☴ ☰ ☵ ☲ ☶ ☱ △
validation 1:             status = rejected
terminal.cause:           complete
manifest.truth_status:    runtime_confirmed
manifest.output:          type=text, text="fake substrate response"
manifest.assembly:        no rejection field at all
```

The rejected life is indistinguishable at the terminal level from the passing
life (same walk, same cause, same truth status, same output type).

## Mechanism

1. The C1 treatment ("fresh LOGIC stamp suppresses continuation and creates
   manifest pressure") does not discriminate verdict polarity. A stamp with
   `verdict = rejected` still produces manifest pressure toward △.
2. `organs/manifest.lua:76-78` correctly computes `rejected_count` and
   `rejection_reasons` into the logic context, but the assembled payload drops
   them: nothing in `manifest.assembly`, `manifest.output`, or the terminal
   record carries the rejection.
3. The gate case `rejected_validation_stays_inside_body` asserts only that a
   real rejected validation grows and a typed terminal is reached. It does not
   assert the terminal is honest about the rejection. This is the exact twin of
   the transition brief's own warning:

```text
brief:   wrong route -> beautiful typed death -> green test
found:   rejected work -> beautiful complete manifest -> green test
```

Confident text instead of confirmed behavior, at the terminal boundary - the
defect class this body exists to kill, in its newest organ.

## The Witness Already Exists And Has No Reader

`runtime/reconciliation.lua` (completion_state) already returns:

```text
blocked   when the latest validation is rejected
```

The camera knew. At manifest time the body possessed a runtime-confirmed
witness that the work was blocked, and MANIFEST did not read it. This is the
project's signature "writer without reader" defect: the newest storage
(reconciliation completion_state) already carries the exact fact the newest
consumer (Packet-local manifest input) needed.

## Legacy Divergence Note

Under legacy authority the same life routes `☱ -> ☴`
(`validation_rejected_semantic_repair`). Under tree authority it routes
`☱ -> △ complete`. The step-3 instrumentation flip (legacy as shadow of live
tree) would have recorded exactly this divergence on the first rejected life.
This defect is therefore an argument FOR the current step, not against it.

## What This Does Not Claim

- Manifesting a failure is not wrong. An honest rejection report delivered at
  △ is a legitimate, even desirable terminal. The defect is only that the
  rejection vanishes: cause `complete`, clean `runtime_confirmed`, no marker.
- No claim about which repair is right. Candidates the table stage should
  weigh: manifest classification carrying the rejection
  (output.type / assembly verdict), a distinct terminal flavor, or manifest
  pressure gated on completion_state - the last one already has its witness.
- Not a step-3 blocker. It must be red-tested before step 4 (promotion corpus)
  because the corpus requirement "один rejected-validation путь" would
  currently be satisfied by a laundered manifest.

## Suggested Red Test (before step 4)

```text
grow a rejected validation under router_mode=tree
assert the life reaches a typed terminal (already green)
assert the terminal/manifest records the rejection:
    manifest must not present cause=complete + clean truth status
    while boundary.validations tail is rejected and
    reconciliation completion_state is blocked
```

## Step 4.1 Red Gate - 2026-07-17

The suggested integration witness now exists as
`tests/pending_tree_manifest_honesty_gate.lua`.

Measured baseline:

```text
green: 3
red:   1
```

The green cases prove that rejection, blocked runtime, legacy dissent, and
internal manifest residue all exist. The sole red case proves that the primary
outward result still says `text + complete`. Full evidence is preserved in
`tree_manifest_honesty_red_gate_results_2026-07-17.md`.

No production treatment was made in step 4.1.

## Step 4.2 Treatment - 2026-07-17

The body now projects one `blocked` outcome through primary manifest output,
summary, assembly, terminal, death, and corpse residue while preserving the
substrate text. The latest runtime reconciliation is a named MANIFEST source;
the validation record remains an independent witness.

The former pending gate is permanent and green at `4/4`. Normal accepted
manifestation remains `complete`. No route or pressure weight changed. Full
evidence is preserved in
`tree_manifest_honesty_treatment_results_2026-07-17.md`.
