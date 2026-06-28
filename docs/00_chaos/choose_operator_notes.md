# CHOOSE Operator Notes

Raw notes for `☳ CHOOSE`.

This is not a crystal yet.
It is pressure collected after `☱ RUNTIME` became stable enough to expose the
missing upper-side pair.

## First Invariant

`☳ CHOOSE` is not ordinary decision text.

It is irreversible narrowing of possibility.

```text
before ☳
  possibility field is wider

after ☳
  one branch continues as body
  other branches become loss / residue
```

The package must change when it passes through `☳`.

If no package mutation happens, no real choice happened.

## Difference From LOGIC

`☶ LOGIC` and `☳ CHOOSE` are similar, but opposite in sign.

`☶ LOGIC`:

```text
receives an already formed proposal
passes it through a rule boundary
accepts or rejects what is already there
```

`☳ CHOOSE`:

```text
receives a possibility field
collapses it before complete rule enumeration
makes one branch continue
kills the rest as active possibility
```

Short form:

```text
☶ rejects invalid forms
☳ kills alternatives
```

Or:

```text
☶ preserves boundary by refusing
☳ creates loss by choosing
```

## Package Mutation

Candidate package fields after `☳`:

```text
selected
killed_alternatives
not_chosen_count
choice_pressure
choice_basis
loss
```

`selected`:

```text
what became the continuing branch
runtime_confirmed as a narrowing event
```

`killed_alternatives`:

```text
what was possible but no longer continues in this pass
bounded list or count, not infinite archive
```

`choice_pressure`:

```text
why choice was required at all
budget pressure
attention pressure
operator pressure
task pressure
```

`choice_basis`:

```text
how the choice was made
can include semantic_proposal if substrate supplied reasons
```

`loss`:

```text
cost of destroyed potentiality
not only token/budget cost
attention collapse residue
```

## Truth Boundary

The fact of body choice can be runtime-confirmed.

The explanation of why can remain semantic.

```text
body chose these candidates
  truth_status = runtime_confirmed

substrate says these are important because X
  truth_status = semantic_proposal
```

This boundary matters because `☳` must not become hidden LLM planning.

## First Concrete Shape

Current body route:

```text
☴ repo_listing_eye
substrate proposes paths
☶ repo_selection_validator
☴ repo_context_eye
```

This works, but it means the substrate is currently doing the choice.

Future body-owned route:

```text
☴ observe listing
☵ encode listing into candidate field
☳ choose focus
☶ validate focus
☴ observe selected context
```

In that route:

```text
☴ sees 100 files
☵ makes a bounded candidate field
☳ chooses 4 files as focus
☳ records 96 not chosen as loss/count
☶ validates the chosen 4
☴ reads accepted files
```

## Important Boundary

`☳` is not planner.

It is not final decision.

It is not LOGIC.

It is closer to attention collapse:

```text
selected branch lives
unselected branches die as active paths
residue remains
```

## Open Questions

```text
how to represent killed alternatives without archiving too much?
is not_chosen_count enough for v0?
should loss be numeric, symbolic, or both?
does CHOOSE spend budget directly or only records loss?
what minimum input shape does CHOOSE require from ENCODE?
can CHOOSE operate without ENCODE in v0?
```

No code yet.
No table yet.
No crystal yet.
