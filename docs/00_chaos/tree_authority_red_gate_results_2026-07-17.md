# Tree Authority Red Gate Results - 2026-07-17

Status:

```text
chaos / runtime evidence
checkpoint: 49c2e89 plus uncommitted authority documents and gate
production code changed: no
promotion gate: RED as expected
```

## Commands

```sh
luac -p tests/pending_tree_authority_gate.lua
lua tests/pending_tree_authority_gate.lua
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
```

## Baseline

```text
pending gate syntax: ok
main Lua suites: all tests ok
mortality battery: 8/8
```

The pending gate is intentionally absent from `tests/run.lua`. The legacy
control body remains green while promotion work is incomplete.

## Promotion Gate Result

```text
green = 1
red   = 6
```

### RED: explicit_tree_authority_runs

```text
router:tree_authority_not_promoted
```

Confirms explicit tree mode is still forbidden.

### RED: normal_build_manifests_under_tree

```text
router:tree_authority_not_promoted
```

The authority blocker fires before the known missing normal-manifest witness
can be exercised.

### RED: rejected_validation_stays_inside_body

```text
router:tree_authority_not_promoted
```

Tree survival is unavailable. The same scenario under current live legacy is
independently known to abort as `☱:nothing_to_reconcile`.

### RED: typed_substrate_failure_becomes_body_terminal

```text
typed substrate failure escaped as harness failure: ☴:table: <address>
```

The address-bearing error is additional evidence that a structured external
failure is being flattened through string-oriented `stage_error` instead of
becoming body physics.

### RED: committed_route_preserves_derivation_evidence

```text
invalid event type: route_derivation
```

Packet trace has no route-derivation event yet. The test therefore fails
before reaching the already-observed loss of derivation fields in
`packet.commit_transition`.

### RED: tree_flow_entry_is_body_derived

```text
router:tree_authority_not_promoted
```

Current runner still uses direct `runner_entry`; the tree contract cannot yet
exercise the first FLOW edge.

### GREEN control: lua_invariant_failure_remains_loud

```text
injected_lua_invariant_failure escaped the body with diagnostic reason intact
```

This behavior must remain green throughout promotion. Making the other six
cases green by catching all failures would regress this control and violate
the body/physics failure boundary.

## Interpretation

The first step has produced independent falsifiers rather than one broad
claim that the router is unfinished.

The next implementation step must not merely remove
`tree_authority_not_promoted`. It must make progress in this order:

```text
structured effect-failure and terminal boundary
route-derivation event and commit evidence
Packet-local normal manifest witness/material
tree FLOW and internal authority
```

At every intermediate point:

```text
main suites remain green
mortality remains 8/8
Lua invariant control remains green
the number and reasons of promotion RED cases are recorded
```

## Treatment Addendum - 2026-07-17

This document remains the baseline and is not rewritten as if the failures
never existed. Treatment evidence is recorded in
`tree_authority_opt_in_results_2026-07-17.md`.

The gate was expanded, turned fully green, moved to
`tests/test_tree_authority.lua`, and registered in the main suite:

```text
green = 10
red   = 0
```

Gate A is confirmed. Explicit `router_mode=tree` is now allowed; default mode
remains `shadow` until the later promotion steps.
