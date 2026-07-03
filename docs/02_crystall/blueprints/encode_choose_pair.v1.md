# Encode Choose Pair Blueprint v1

Status:

```text
crystall
no code yet
```

Source table:

```text
docs/01_table/yellowprints/encode_choose_pair_yellowprint.v1.md
```

## Purpose

Define the executable contract for the `☵☳` pair.

`☵` and `☳` must be implemented as one design unit.

`☵` produces a structured possibility field.

`☳` collapses that field and records dead alternatives.

## Modules

Expected existing targets:

```text
logic/encode.lua
organs/encode.lua
logic/choose.lua
organs/choose.lua
```

The first implementation should prefer changing logic modules before changing
router behavior.

## ENCODE Public Contract

Required function remains:

```lua
encode.encode(input, options) -> encoded
```

`organs/encode.lua` still calls logic encode and writes through packet APIs.

Required output shape:

```lua
{
  kind = "encoded_field",
  field = {
    kind = "field",
    items = {},
    structure = {},
    encoding = {},
  },
  work_units = {},
  loss = {},
}
```

## Field Item Contract

Every `field.items[n]` must have:

```lua
{
  id = string,
  kind = string,
  label = string,
  content = string | table,
  source_refs = table,
  potential = number,
  status = "pending",
}
```

Rules:

```text
id must be stable inside the field
source_refs must not be empty when source material exists
potential defaults to equal weight if no stronger pressure exists
status starts as pending
```

## Field Structure Contract

`field.structure` must have:

```lua
{
  kind = "hierarchy" | "sequence" | "category" | "teaching" | "language",
  entry = string | nil,
  root = string | nil,
  exit = string | nil,
  nodes = table,
  edges = table,
  levels = table,
  steps = table,
  categories = table,
  unknowns = table,
}
```

Unused keys are empty tables or nil.

Do not invent structure to fill keys.

## Encoding Metadata Contract

`field.encoding` must have:

```lua
{
  encoding_type = string,
  loss_percentage = number,
  loss_level = string,
  creates_hierarchy = boolean,
  creates_sequence = boolean,
  reversible = boolean,
  hierarchy_lens_visible = boolean,
  source_refs = table,
}
```

Initial loss table:

```lua
{
  hierarchy = 0.30,
  sequence = 0.25,
  category = 0.40,
  teaching = 0.60,
  language = 0.50,
}
```

Loss levels:

```text
minimal: < 0.15
moderate: < 0.45
severe: < 0.75
total: >= 0.75
```

## Encoding Selection

Selection should be deterministic from visible input shape.

Priority order:

```text
1. explicit repo paths / file tree / module tree -> hierarchy
2. numbered steps / ordered plan / lifecycle -> sequence
3. alternatives / buckets / classes / allowed-denied -> category
4. rules / explanations / doctrine-like transfer -> teaching
5. fallback prose -> language
```

This priority is a v1 heuristic.

It must be visible in code and tests.

## CHOOSE Public Contract

Required function remains:

```lua
choose.choose(field, options) -> choice
```

Required output shape:

```lua
{
  kind = "choice_result",
  chosen = table,
  killed_alternatives = table,
  not_chosen_count = number,
  collapse_type = string,
  choice_loss = table,
}
```

`organs/choose.lua` records this through packet/body APIs.

## CHOOSE Input Rules

`☳` reads:

```text
field.items
field.structure
field.encoding
optional semantic_ranking
```

`☳` must not require LLM routing.

If semantic ranking exists, it may influence item potential.

If semantic ranking is absent, use field order/potential.

## Collapse Rules

Collapse unit depends on structure:

```text
hierarchy -> node or subtree
sequence  -> next actionable step
category  -> category or member
teaching  -> rule, claim, or warning
language  -> possible_action first, claim second, utterance last
```

Every collapse must record:

```text
before_count
after_count = 1 when real choice happens
killed_alternatives
not_chosen_count
```

If there is only one item:

```text
collapse_type = confirmation
killed_alternatives = {}
not_chosen_count = 0
```

Confirmation is not a real choice.

## Boundary Rules

`☳` must not:

```text
mutate field.items
mutate field.structure
mutate work_units
validate repo truth
decide continuation
call manifest
call substrate
```

`☳` may:

```text
write packet.boundary.choices
write packet.trace choice event
write packet.tension.last_choice_pressure
```

## Pair Invariants

```text
☵ owns structure formation
☳ owns collapse
☵ records encoding loss
☳ records choice loss
☵ may be complex
☳ should stay simple
bad choice usually means bad field
```

## Observe Hooks

After `☵`, `☴` should be able to inspect:

```text
field.structure.kind
field.encoding.loss_percentage
field.items count
field.source_refs
```

After `☳`, `☴` should be able to inspect:

```text
chosen
killed_alternatives count
collapse_type
choice_loss
```

No code change is required in observe until implementation begins, but this is
the expected visibility contract.

## Required Tests Later

Unit tests:

```text
encode selects hierarchy for module/file tree input
encode selects sequence for ordered plan input
encode selects category for alternatives input
encode falls back to language for unstructured prose
encode always includes encoding metadata and visible loss
choose records killed alternatives for multi-item field
choose returns confirmation for single-item field
choose does not mutate field/work_units
```

Smoke tests:

```text
tension runner route includes ☴☵☴☳☴
after ☵ observe sees structure
after ☳ observe sees collapse residue
```

