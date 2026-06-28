# Crystallization Cycle Yellowprint v0

This map describes how `procesis-body` should grow.

The goal is not one-shot implementation.
The goal is repeated compression:

```text
chaos -> table -> crystall -> manifest
```

Then repeat from chaos.

## Cycle

```text
1. Read chaos
2. Extract stable shapes
3. Update table maps
4. Read table
5. Extract contracts
6. Update crystall blueprints
7. Build only from crystall
8. Test manifest behavior
9. Write new chaos from what broke or appeared
```

## Layer Roles

```text
chaos
  preserves raw pressure, disagreement, origin, unresolved shapes

table
  turns chaos into maps, inventories, routes, candidate module layouts

crystall
  turns table into contracts, invariants, interfaces, test obligations

manifest
  records only what exists and how it behaves
```

## Promotion Rules

Chaos can enter table when:

```text
it recurs
it clarifies a body organ
it changes implementation order
it explains a failure mode
it creates a testable distinction
```

Table can enter crystall when:

```text
it can be phrased as a contract
it has a clear owner/module
it has observable behavior
it can be tested or manually verified
it reduces ambiguity for implementation
```

Crystall can enter manifest only when:

```text
code/docs exist
behavior is verified
known gaps are named
```

## Current Stable Shapes From Chaos Packet 001

```text
body_identity
  LLM is substrate, not agent

mortal_packet
  task lives, spends, leaves residue, ends

two_center_topology
  OBSERVE reads chaos side
  RUNTIME sustains manifest side

runtime_truth_boundary
  semantic output is not runtime truth

unsupported_form_protocol
  hallucination is unsupported semantic form
  unsupported form can become diagnostic pressure

memory_as_decoding
  memory is fast reopening of residue, not archive

lua_first_body
  Lua is first nervous system / orchestration layer

tests_required
  every crystall contract needs a test or explicit manual check

body_modes
  chaos/table/crystall/manifest are process permission modes
  code writes only in manifest mode

sandbox_policy
  default-deny host permission layer below tool facade
  tools ask sandbox before host access

repo_context_eye
  first OBSERVE-side eye
  gives substrate runtime-confirmed repo evidence before reasoning

repo_listing_eye
  next OBSERVE-side eye pressure
  gives body-owned bounded file tree before file context selection
```
