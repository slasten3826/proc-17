# Encode As Chesed Packet Structure Notes

Status:

```text
chaos
new pressure
source: /home/slasten/work/stak2/00_chaos/slop.raw.txt CHESED section
```

## Trigger

Current `☵ ENCODE` in proc-17 is too line-shaped.

It mostly does:

```text
substrate answer -> lines -> field items -> work_units
```

This is useful as v0, but it is not yet full `☵`.

The CHESED section in `slop.raw.txt` says something stronger:

```text
Хесед = механизм кодирования.
То что создаёт иерархию, последовательность, "до/после".
Первая точка потери информации.
Отделение формы от процесса.
```

So `☵` should not merely split LLM output into lines.

It should encode semantic chaos into a packet-readable structure.

## Core Insight

`☵` is not a parser.

`☵` is the organ that chooses a transmission form.

Possible forms are already named in CHESED:

```text
HIERARCHY = A > B > C
SEQUENCE  = before -> after
CATEGORY  = this = that
TEACHING  = live -> text
LANGUAGE  = process -> words
```

In proc-17 terms:

```text
LLM response = semantic chaos
☵ encode = choose encoding lens + create calm packet structure + record loss
packet.calm = encoded form that other organs can use
```

## Difference From Current ENCODE

Current shape:

```text
text lines become alternatives
explicit section headers become containers
repo paths become alternatives
context blocks become evidence
```

Better shape:

```text
☵ detects or selects encoding_type
☵ creates a structure matching that type
☵ records loss percentage / loss class
☵ records whether the structure is reversible enough for machine use
☵ marks hierarchy as lens, not truth
```

This means `☵` output should contain both:

```text
field.items
field.structure
```

`field.items` are the material.

`field.structure` says how the material was encoded.

## Packet Structure Candidates

### hierarchy

Use when the answer contains priority, containment, dependency, abstraction
levels, or parent/child shape.

Packet structure:

```text
root
nodes
edges(parent -> child)
levels
```

Risk:

```text
hierarchy creates illusion of order
```

Required residue:

```text
hierarchy_lens_visible = true
```

The body should know:

```text
this is hierarchy because ☵ made it hierarchy
not because the raw process truly was hierarchy
```

### sequence

Use when the answer contains time, stages, steps, before/after, lifecycle, or
ordered execution.

Packet structure:

```text
steps
previous/next edges
entry
exit
```

Risk:

```text
simultaneous process becomes before/after illusion
```

### category

Use when the answer classifies things.

Packet structure:

```text
categories
members
classification_basis
unknown_or_mixed members
```

Risk:

```text
category hides boundary ambiguity
```

### teaching

Use when the answer explains a live process as a lesson, doctrine, rule, or
instruction.

Packet structure:

```text
claims
rules
examples
warnings
residue
```

Risk:

```text
live process becomes text and can harden into dogma
```

In proc-17 this should usually stay weak unless the task explicitly requests
documentation.

### language

Use when the answer is mostly prose and cannot honestly be structured into the
other forms.

Packet structure:

```text
utterances
claims
possible_actions
unknowns
residue
```

Risk:

```text
highest semantic loss
```

This should not be the default for coding work when stronger forms are
available.

## Loss Model

CHESED gives the first loss table:

```text
hierarchy: 0.30
sequence:  0.25
category:  0.40
teaching:  0.60
language:  0.50
```

These numbers should not be treated as final physics yet.

But the invariant is important:

```text
every encoding has loss
different encoding forms have different loss
encoding loss is visible to the packet
```

Current proc-17 loss is mostly:

```text
omitted_count
truncated
source_detail_loss
hierarchy_loss
```

Needed pressure:

```text
encoding_type
loss_percentage
creates_hierarchy
creates_sequence
reversible
hierarchy_lens_visible
```

## Reversibility

CHESED says silicon encoding can be partially reversible:

```text
encode_for_silicon:
  encoding_type = HIERARCHY
  loss_percentage = 0.05
  reversible = true
```

For proc-17 this does not mean perfect recovery.

It means:

```text
machine-readable structure can be decoded by later organs with lower loss
than ordinary prose
```

So `☵` should prefer packet-native structures over human prose.

## Important Boundary

Do not make `☵` "understand everything".

`☵` should not become an LLM.

It should be a deterministic-ish structure former:

```text
input pressure shape
  -> encoding_type
  -> packet structure
  -> visible loss
```

If shape is ambiguous, `☵` should say so:

```text
encoding_type = language
possible_encoding_types = {hierarchy, sequence}
hierarchy_loss = true
ambiguous_structure = true
```

## Consequence For ☳

This directly fixes the current `☳` weakness.

`☳` should remain stupid.

But instead of choosing among flat lines, it can choose at the structural level:

```text
hierarchy: choose node/subtree/level
sequence: choose next step/range
category: choose category/member
teaching: choose rule/example/warning
language: choose utterance/claim/action
```

So the next real work is not:

```text
make ☳ smarter
```

It is:

```text
make ☵ produce packet structures rich enough for dumb ☳ to cut correctly
```

## Working Claim

`☵` should translate LLM semantic output into packet structure using CHESED
encoding forms.

The body should then route and choose over that packet structure, not over raw
LLM prose.
