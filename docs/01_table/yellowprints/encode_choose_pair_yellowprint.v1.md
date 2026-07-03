# Encode Choose Pair Yellowprint v1

Status:

```text
table
pair contract
no code yet
```

Source chaos:

```text
docs/00_chaos/encode_as_chesed_packet_structure_notes.md
docs/00_chaos/slop_raw_as_packet_body_notes.md
docs/00_chaos/packet_skeleton_and_first_operations_notes.md
```

## Direction

Implementation moves bottom-up.

Do not start with fixed `▽☰☷` skeleton.

Use the lower body that already works:

```text
☴ observe
☲ cycle
☶ logic
☱ runtime
△ manifest
```

Now build the first operation pair:

```text
☵ encode -> ☳ choose
```

The pair must be designed together.

## Pair Law

```text
☵ creates a possibility space
☳ collapses that possibility space
```

If `☳` looks stupid, first inspect `☵`.

Bad choice usually means bad field.

## ☵ Responsibility

`☵` is not a parser.

`☵` is packet structure formation.

Input:

```text
packet.chaos
latest substrate semantic proposal from ☴
existing packet.calm
existing packet.boundary residue
task mode / work mode
```

Output:

```text
packet.calm.current.field
packet.calm.current.structure
packet.calm.current.encoding
packet.calm.work_units
packet.boundary.loss_records
```

Required encoding metadata:

```text
encoding_type
loss_percentage
loss_level
creates_hierarchy
creates_sequence
reversible
hierarchy_lens_visible
source_refs
```

Allowed encoding types from slop CHESED:

```text
hierarchy
sequence
category
teaching
language
```

## ☳ Responsibility

`☳` is collapse.

It should be dumb.

Input:

```text
packet.calm.current.field
packet.calm.current.structure
packet.calm.work_units
optional semantic ranking
```

Output:

```text
chosen
killed_alternatives
not_chosen_count
collapse_type
choice_loss
packet.boundary.choices
packet.trace
```

Must not:

```text
invent missing structure
rewrite packet.calm
decide continuation
validate repo truth
manifest output
```

## Field Shape

The field must carry both material and structure.

```text
field.items      = things that can be chosen, worked, or validated
field.structure  = how those things relate
field.encoding   = why the field has this shape and what was lost
```

Minimum item shape:

```text
id
kind
label
content
source_refs
potential
status
```

Minimum structure shape:

```text
kind
entry
nodes
edges
levels
steps
categories
unknowns
```

Not every structure uses every key.

Unused keys should be empty, not invented.

## Encoding Types

### hierarchy

Use when semantic material contains containment, priority, abstraction levels,
dependencies, parent-child shape, module trees, or implementation layers.

Expected structure:

```text
kind = hierarchy
root
nodes
edges(parent -> child)
levels
```

Choice unit:

```text
subtree or node
```

Risk:

```text
order illusion
```

Required:

```text
hierarchy_lens_visible = true
```

### sequence

Use when semantic material contains steps, before/after, lifecycle, execution
order, todo order, or migration path.

Expected structure:

```text
kind = sequence
entry
exit
steps
edges(previous -> next)
```

Choice unit:

```text
next step or blocked step
```

Risk:

```text
simultaneous process becomes artificial order
```

### category

Use when semantic material separates kinds, buckets, classes, allowed/denied
groups, or comparable options.

Expected structure:

```text
kind = category
categories
members
classification_basis
unknown_or_mixed
```

Choice unit:

```text
category or member
```

Risk:

```text
boundary ambiguity hidden
```

### teaching

Use when semantic material is doctrine-like: explanations, rules, lessons,
warnings, or conceptual transfer.

Expected structure:

```text
kind = teaching
claims
rules
examples
warnings
residue
```

Choice unit:

```text
claim, rule, or warning
```

Risk:

```text
live process becomes dead doctrine
```

In coding-agent work this should not be the default.

### language

Use only when stronger structure cannot honestly be formed.

Expected structure:

```text
kind = language
utterances
claims
possible_actions
unknowns
residue
```

Choice unit:

```text
claim or possible_action
```

Risk:

```text
highest semantic loss
```

## Loss

Initial CHESED loss table:

```text
hierarchy = 0.30
sequence  = 0.25
category  = 0.40
teaching  = 0.60
language  = 0.50
```

These numbers are provisional.

Invariant:

```text
encoding loss must be visible
choice loss must be visible
total packet loss must not be hidden
```

## Pair Flow

Expected local route:

```text
☴ -> ☵ -> ☴ -> ☳ -> ☴
```

`☴` after `☵` checks the encoded field.

`☴` after `☳` checks the collapse result.

Then router may send packet toward:

```text
☱ runtime
☵ re-encode
☳ choose again
△ manifest
```

## Failure Modes

Bad `☵`:

```text
field is just text lines
encoding_type missing
loss hidden
structure missing
items have no source refs
everything becomes language
```

Bad `☳`:

```text
chooses without killed alternatives
rewrites field
claims validation truth
decides continuation
manifests output
```

Expected diagnosis:

```text
if choice is bad, inspect field first
if field is bad, fix ☵ before tuning ☳
```

## Tests To Design Later

```text
encode hierarchy from module tree
encode sequence from implementation plan
encode category from alternatives
encode language only when no stronger structure exists
choose records killed alternatives from each structure type
choose preserves field and work_units
observe can inspect field.structure after encode
observe can inspect boundary.choices after choose
```

