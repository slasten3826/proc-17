# Promotion Tables Materialization And Witness Audit - 2026-07-17
Status:

```text
chaos / audit response
audited stage: 4.3B promotion tables
audited documents:
  docs/01_table/yellowprints/tree_authority_promotion_corpus_yellowprint.v0.md
  docs/01_table/yellowprints/blocked_lineage_yellowprint.v0.md
  docs/01_table/yellowprints/tree_authority_promotion_record_yellowprint.v0.md
external reviewer: Fable, delivered through the machinist
independent code verification: Codex
production code change authorized: no
table amendment performed here: no
crystallization authorized: no
```

## 1. Verdict

Both reported gaps are accepted as real.

The first is a discontinuity in the blocked-lineage body chain: inherited
repair pressure is written, but the failed form it names is never materialized
inside the descendant field before DISSOLVE is expected to act on it.

The second is a sequencing defect in the promotion plan: the corpus cannot
honestly prove adaptive full-tree routing while important pressure witnesses
remain recurrent, insensitive to relevant mutations, or able to win only by a
canonical tie-break.

The tables remain useful and are not discarded. They exposed these gaps before
crystallization and code, which is exactly the purpose of the table stage.

## 2. Fable Findings, Normalized

The courier report contains two findings.

### F1 - Blocked lineage has pressure without a materialized referent

The current table chain says:

```text
grave.attach
-> grave_repair_pressure in unresolved CHAOS
-> repair/rigidity pressure toward DISSOLVE
-> DISSOLVE releases inherited failed form
```

DISSOLVE acts on Packet field objects. The descendant currently receives a
grave record and unresolved pressure, but no field object representing the
failed ancestral form. A pressure source exists without an actionable
referent.

The E02 witness already names the intended phenomenon:

```text
inherited rigid carrier form releases residue
```

FLOW is the likely materialization boundary, but the same-session user-born
descendant must be specified explicitly rather than treating only
`network_reentry` as inheritance.

### F2 - Strict promotion is blocked before witness repair

The promotion tables require all of the following:

```text
pressure varies across matched cases
the named reader consumes the same source domain
the selected target does not win only through canonical tie-break
all 38 legal directions are executed under tree authority
```

Current relation and upper-observation witnesses do not yet satisfy these laws
for all relevant directions. Building 38 fixtures before repairing those
witnesses would produce a large corpus around routes that the current scoring
cannot select for task-sensitive reasons.

Fable also notes that 38/38 closure is a campaign rather than a small gate. A
narrower authority surface would be a possible explicit design revision, not
an exception hidden inside the corpus.

## 3. Independent Verification Of F1

The current runner order is:

```text
runtime/tension_runner.lua
  FLOW runs at lines 281-290
  inherited graves attach at lines 292-298
```

Therefore FLOW cannot currently see inherited grave pressure. Attachment
happens after ingress materialization.

Current FLOW creates exactly one unit from the direct ingress carrier:

```text
organs/flow.lua
  raw prompt or network carrier
  -> one field.add_unit call
```

Current grave attachment writes:

```text
runtime.karma.bequests
chaos.unresolved_pressure[] = grave_bequest_pressure
```

It does not write a field unit or relation.

Current DISSOLVE readiness reads only active relations and requires an
externally supplied reason:

```text
organs/dissolve.lua
  field.relation_view(...)
  options.relation_id
  options.reason
```

The reported discontinuity is therefore code-confirmed:

```text
grave pressure exists
failed-form field identity does not exist
DISSOLVE has no target
```

There is already an unused part of the intended body contract that makes a
direct form treatment plausible. The older crystall says DISSOLVE weakens a
selected `relation or form`, and `runtime/field.lua` already grants ☷ the right
to set a field unit activation to `dissolved`. The organ implementation covers
relations only.

## 4. Candidate F1 Treatment, Not Yet A Decision

The strongest current candidate is:

```text
Packet birth event
-> select and attach applicable inherited graves
-> FLOW materializes direct ingress
-> FLOW also materializes each bounded inherited failed form as a
   generation-local field unit with ancestral provenance
-> repair rigidity derives from that field unit
-> DISSOLVE readiness consumes the same unit and source refs
-> DISSOLVE dissolves the form and emits recoverable residue
-> later pressure may carry the changed field toward OBSERVE or ENCODE
```

This keeps the boundaries distinct:

```text
grave selects inherited memory
FLOW gives inherited material a body in the new generation
pressure measures its rigidity
DISSOLVE releases it
```

A same-session generation-N+1 Packet may still have `birth_kind=user`. It does
not need to pretend to be `network_reentry`; the direct ingress kind and the
presence of inherited repair material are independent axes.

The table amendment must still decide explicitly:

```text
whether grave attachment is always a pre-FLOW birth phase
the exact inherited_failed_form unit schema
how rigidity is represented and read without becoming semantic truth
whether DISSOLVE v1 targets units and relations through one tagged contract
how one-release-per-descendant idempotence is recorded
```

Creating a synthetic relation only to fit the current relation-only DISSOLVE
implementation is not selected. The body contract should determine the code,
not the current implementation gap.

## 5. Independent Verification Of F2

The exact defect is more precise than "every witness is literally constant."

### Relation debt

`runtime/pressure.lua:139-176` emits one `relation_debt` contribution toward ☰
when two or more live addressable units are not covered by the latest raw
relation epoch.

OBSERVE appends a new semantic field unit. Until CONNECT creates a fresh
relation epoch covering that unit, relation debt returns. In the common
post-OBSERVE state, this gives ☰ one recurrent positive contribution.

ENCODE, CHOOSE, RUNTIME, and rigidity may each receive one binary contribution
in the same state. With equal totals, canonical order selects ☰ first. The
signal is conditional in source code but can behave as a route-dominating
constant over the relevant living states.

### Upper-observation debt

The camera treatment correctly prevents OBSERVE from becoming stale merely
because it produced its own sensor output. The current reader covers unit IDs
from `scope_refs` and `sensor_output_refs`.

However, ID coverage alone does not prove that later changes to the represented
form were observed. ENCODE remap, CHOOSE activation changes, DISSOLVE changes,
and other versioned mutations may leave the same old ID marked as covered or
may fall outside the reader's selected unit domain. For relevant reverse
directions, upper-observation debt can therefore remain absent when the field
has materially changed.

This means the two failures have different shapes:

```text
relation_debt              recurrent positive vote in common upper states
upper_observation_debt     insufficiently sensitive to relevant field changes
```

Both are degenerate for promotion purposes even though neither must be a
literal constant over every possible Packet state.

## 6. Directions At Risk

The Fable report names E05, E09, E10, and E11. Code inspection confirms the
general risk and expands the diagnostic surface:

| Direction family | Current risk |
|---|---|
| `☴ -> ☰` | Recurrent relation debt can select ☰ without proving task-specific relation need |
| `☴ -> ☵` | Encoding debt can tie relation debt and lose canonical tie-break |
| `☴ -> ☳` | Choice pressure can tie relation debt and lose canonical tie-break |
| `☴ -> ☱` | Runtime reconciliation can tie relation debt and lose canonical tie-break |
| `☴ -> ☷` | Rigidity can tie relation debt and lose canonical tie-break; E07 must also be diagnosed |
| `☰/☵/☳/☱ -> ☴` | Upper observation may not detect the relevant versioned semantic mutation |

Readiness exclusions or specially shaped fixtures may force some of these
routes. Such a route does not satisfy the existing promotion requirement if
its claimed adaptive witness is constant, absent, or defeated except by
excluding every competitor.

## 7. Required Diagnostic Before Corpus Construction

Witness repair becomes an explicit pre-corpus stage. It is not weight tuning.

For each selected witness, grow matched Packet states that differ in exactly
one relevant body fact:

```text
relation need absent / relation need introduced
observed form unchanged / observed form version changed
one alternative / multiple alternatives
no runtime consequence / unreconciled significant consequence
no rigidity / inherited or runtime-confirmed rigid form
```

Record:

```text
contribution absent/present
source refs
reader readiness over the same domain
candidate totals before tie-break
selected target and reason
negative-control route
```

The required result is not "every signal has a larger weight." It is:

```text
the witness appears only when its named body fact exists
the witness disappears or changes when that fact is removed
the destination organ can consume the same referent
the intended route does not depend solely on canonical order
```

Only after this stage should the 38-direction corpus be grown.

## 8. Authority-Surface Decision

The current recommendation is to retain the strict 38/38 gate.

The project is explicitly attempting to give the full 22-edge Tree authority.
The fact that evidence collection is large does not make a smaller surface
equivalent. If a legal direction remains impossible after correct witness and
organ contracts exist, the authority surface or topology may be revised only
through a separate chaos -> table -> crystall decision.

There is no `accepted_exception` inside the current promotion record.

## 9. Proposed Next Sequence

```text
1. external audit of this diagnosis
2. amend blocked_lineage yellowprint with birth/materialization law
3. amend promotion tables with an explicit witness-repair precondition
4. observe amended tables
5. crystallize materialization and witness contracts
6. implement one falsifiable treatment at a time
7. grow the promotion corpus only after witness gates are green
8. consider Step 5 default authority change only after all hard gates pass
```

Until step 2 is complete, P03/P10 do not have an executable body chain.
Until step 3 is complete, building the full corpus would measure current
tie-break artifacts rather than full-tree pressure physics.

## 10. Questions For External Audit

```text
Q1. Is pre-FLOW grave attachment the correct birth boundary, or should another
    body stage materialize inherited repair pressure?

Q2. Should inherited failed form be a direct field unit dissolved by ☷, or is
    there a body-level reason to require a relation/form pair?

Q3. Does versioned upper-observation coverage capture the missing witness, or
    is a separate semantic-change ledger required?

Q4. Is E07 (☴ -> ☷) blocked by the same relation-debt tie identified for the
    other exits from OBSERVE?

Q5. Which matched controls minimally prove relation_debt and
    upper_observation_debt are task-sensitive before weights are discussed?
```
