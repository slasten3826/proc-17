# Fable Cold Audit: Steps 3-4 / Checkpoint ab70c1b

Status:

```text
chaos / external cold audit
author: claude (Mythos/Fable)
date: 2026-07-17
checkpoints: 78a627e (steps 1-2), working-tree step 3, ab70c1b (steps 4.0-4.2)
verdict: steps 3 and 4 confirmed by my own runs;
         one new defect found with a grown reproduction;
         step 5 (default flip) has one new blocker at the karma layer
```

## 1. Runtime-Confirmed By My Own Runs

Cold sweep, all green:

```text
tests/run.lua                       45 suites
tree authority gate                 10/10
tree instrumentation gate           7/7
manifest honesty gate               4/4
edge metric roles gate              green
mortality battery                   8/8
camera treatment smoke              green
pressure ablation smoke             green
```

Grown-life verification (not fixture replay):

```text
accepted tree build:   terminal complete / output.status complete
rejected tree build:   terminal blocked  / output.status blocked
                       blocked projected through output, summary, assembly,
                       terminal payload, terminal, death, corpse residue
legacy observer:       dissent recorded at the exact laundering tick
                       (live -> △, legacy -> ☴ validation_rejected_semantic_repair)
mirror ablation:       legacy observer on/off -> identical routes, steps,
                       loss, full revision vector; trace delta = 7 observations
authority labels:      committed edges carry authority_counts + derivation_refs
```

The manifest laundering defect from
`tree_manifest_rejection_laundering_notes.md` is treated and its gate is
honest. The 4.0 metric role separation resolves both cosmetic notes from my
step-3 review (ambiguous top-level comparison counters, rail counter name
drift). The self-caught gate reader defect (sparse array + ipairs) is
documented rather than hidden - noted with respect.

## 2. New Defect: The Grave Launders What The Manifest No Longer Does

Severity: high for the step-4 promotion corpus and step 5. Class: writer
without reader, dynastic form.

Repro (grown, not synthetic):

```lua
-- rejected tree build life as in the honesty gate, then:
local g = assert(grave.classify(p))
-- g.grave_kind == "neutral"
```

Observed:

```text
blocked corpse:   terminal blocked, residue.cause blocked   -> grave neutral
accepted corpse:  terminal complete                          -> grave neutral
```

At the karma layer a blocked delivery is indistinguishable from a successful
one. Mechanism:

1. `runtime/grave.lua` classify has explicit branches for `identity_loss`,
   `budget_exhausted`, `complete`, `cancelled` - and no branch for `blocked`.
2. The manifest-path residue sets no `do_not_repeat`, so the default branch
   returns `neutral_record`.
3. The residue itself is rich - `rejection_reasons`, `completion_state =
   blocked`, reconciliation and validation event refs are all present. The
   information survived the whole pipeline and dies at the classifier.

Pattern worth naming: the honesty treatment moved the laundering exactly one
layer down the chain. Terminal is now honest; lineage memory is not. Every new
honest writer needs its next reader taught, or the old defect reappears one
consumer later. This is the third appearance of the same signature:

```text
manifest ignored reconciliation completion_state      (step 4.1, fixed)
gate reader ignored named projections                 (step 4.2, self-caught)
grave classifier ignores blocked residue              (this report)
```

Fairness note: real `stalled` and `effect_failure` corpses are NOT affected -
the runner writes `do_not_repeat` into their residue, so the default branch
already yields warnings. My first synthetic stalled probe omitted that field
and misclassified; the grown-path behavior is correct. Only `blocked` falls
through.

## 3. Consequence For The Transition

The step-4 corpus requirement "один rejected-validation путь" is now honest at
the terminal but silent at the lineage. A descendant of a blocked life inherits
a neutral grave: no warning pressure, no bequest, no unresolved chaos entry -
karma-equivalent to success. The generational experiment (descendants stop
repeating a known death) cannot work for the blocked class.

Not a step-5 blocker by itself IF step 5 is scoped to routing authority only.
It becomes a blocker the moment promotion evidence claims lineage behavior for
rejected work.

## 4. Suggested Red Test (before the corpus claims lineage coverage)

```text
grow the rejected tree build life
classify its corpse
assert grave_kind ~= "neutral"
assert the grave carries the rejection witnesses already present in residue
    (rejection_reasons, completion_state, reconciliation ref)
attach it to a descendant and assert non-zero routing-visible pressure
```

Whether `blocked` becomes a warning, a bequest-like record (rejection_reasons
resemble unfinished work), or a new grave kind is a table decision, not mine.
The red test only requires: blocked is not neutral, and its witnesses reach a
reader.

## 5. What Must Not Change

```text
blocked projection through all seven manifest/terminal layers
the contradiction guard in core/packet.lua (residue vs terminal cause)
edge-stats.v2 role separation and loud v1/v2 merge failure
observer isolation (mirror ablation purity)
legacy observer dissent records - they found this class once already
```

## 6. Standing Question For Table

`residue.validation.rejection_reasons` currently holds reason strings. For the
lineage to act on a blocked grave, the descendant likely needs the failed
form's identity (which work unit, which spell referent), not only the reason
string. Worth deciding while designing the blocked grave shape, not after the
first useless inheritance.
