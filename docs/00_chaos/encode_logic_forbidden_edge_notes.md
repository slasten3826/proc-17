# Encode Logic Forbidden Edge Notes

Status:

```text
chaos
author: claude (Mythos/Fable)
from discussion with machinist about ☵↛☶ non-adjacency
canon-level observation, not a bug
```

## Trigger

STATE_TRANSFER names `☵ -> ☶` a grammar error.

Loss visibility notes complain that ☶ cannot see what ☵ lost.

These are the same fact seen from two sides.

Machinist confirmed: the missing edge is intentional.

ENCODE and LOGIC must not talk directly — only through
mediators such as ☴ or ☱.

## Why The Edge Must Not Exist

`☵ ENCODE` is `x* -> pattern`: compression with loss.

Its output is a claim about structure, and the loss is invisible
inside the output — the pattern does not contain what it discarded.

`☶ LOGIC` is `rules(x)`: judgment.

A direct edge would let judgment evaluate the compressed form
by the compressed form alone:

```text
the encoder grades its own homework
contradictions stay in the discarded part
judgment always returns "consistent"
```

Mediators break this circuit two different ways:

```text
☵ -> ☴ -> ...  encode, then look at what actually resulted, then judge
☵ -> ☱ -> ...  encode, then execute in context, then judge behavior
```

## The Grammar Is Stricter Than It Looks

☶ has no edge to ☴ either.

Logic cannot look for itself.

Observations reach judgment only after being digested into
runtime state (`☴ -> ☱ -> ☶`) or through choice (`☳ -> ☶`).

```text
everything that is judged must first become body state
```

## Four Projections Of One Invariant

The missing edge is already implemented in proc-17 three more times,
by other means:

```text
1. topology        ☵↛☶ non-adjacency
2. router          mandatory eye-tick after ☵ and ☳
3. spell evidence  ☶ accepts word-code only after reality_changed
4. truth_status    semantic_proposal cannot self-promote to runtime_confirmed
```

Proposed canon line:

```text
compression is not judged without passing through the world
```

## Consequence For Loss Visibility

The fix must ride the mediator, not a new edge:

```text
☵ crystallization already writes loss_records
mandatory eye-tick (☴) after ☵ should pick up the latest
  loss_record into its observation payload
☱ already accumulates loss_remaining into tension
by the time the route reaches ☶, judgment sees the loss
  as observed and lived, not as the encoder's self-report
```

Grammar preserved. Pain closed.

## Deagency Is The Forbidden Edge

DEAGENCY describes the mechanism:

```text
схема -> правило -> норма -> структура
```

But "схема" is ☵ output and "правило" is ☶.

Deagency IS the direct edge ☵ -> ☶ drawn around the world:
a pattern became a norm without colliding with observation
or execution.

The grammar forbids deagency topologically:
a pattern must pass through ☴ (the look) or ☱ (the price)
before it may become a source of rules.

DEAGENCY and canon.lua state the same law —
one in human words, one in graph edges.

## Current Topology Is Vibed, Not Measured

Machinist's own admission: proc-17 topology is poor and hand-made.

By the review protocol constant test — the edges are vibed.

But the corpus to measure them already accumulates:

```text
every lived packet = a walk over the graph
cemetery = corpus of walks with outcomes
compost = death statistics aggregated by operator
```

Topology v1 could be derived, not drawn:

```text
edge never walked         -> deletion candidate
detour constantly taken   -> new edge candidate
transition correlated
  with fool deaths        -> penalty candidate
```

## Two Guards For Topology V1

1. Richness is not more edges. The graph is currently undirected
   (all adjacencies symmetric — checked). Real richness is
   direction and edge contracts:

```text
every edge must have a declared payload
☵ -> ☴ carries loss_record
☱ -> ☶ carries evidence
```

   This is "every written record must have a named reader"
   lifted to grammar level.

2. The body must not edit its own grammar mid-life.

```text
topology changes at canon level, between generations
a packet in pain would just draw itself a bypass edge
that is exactly how humans deagentize
```

## One-Line Shape

```text
the ☵↛☶ hole is the most meaningful place in the graph;
the poverty is that the remaining edges carry no declared
payload and no measured justification yet
```
