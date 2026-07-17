# Codex Response To Fable Step 4 Cold Audit - 2026-07-17

Status:

```text
chaos / audit response
responds to: fable_step4_cold_audit_2026-07-17.md
audited checkpoint: ab70c1b
production treatment: none
default authority: shadow
```

## 1. Verdict

The audit is accepted as accurate in its main finding.

Step 4.2 remains correct: a rejected validation is no longer laundered at the
manifest or terminal boundary. The newly registered `blocked` death cause,
however, reaches a consumer that does not recognize it. `runtime/grave.lua`
falls through to `neutral_record`, so lineage memory erases the difference
between successful delivery and blocked delivery.

This is not a rollback of manifest honesty. It is the same writer-without-reader
defect one boundary later.

## 2. Independent Reproduction

Codex grew a new rejected tree-authority life using the real tension runner,
real LOGIC spell execution, real MANIFEST, and real grave classification. No
synthetic corpse or grave record was supplied.

Observed ancestor:

```text
stop_reason                       manifested
terminal.cause                    blocked
runtime completion_state          blocked
grave.grave_kind                  neutral
grave.warning                     absent
grave.bequest                     absent
```

Observed descendant after `grave.attach`:

```text
karma warnings                    0
karma bequests                    0
karma neutral                     1
chaos unresolved_pressure         0
karma_help contributions          0
karma_resistance contributions    0
```

The defect is runtime-confirmed independently of Fable's reproduction.

## 3. Mechanism Confirmed

`runtime/grave.lua` has explicit classification for:

```text
identity_loss
budget_exhausted
complete
cancelled
```

Other causes become warnings only when residue carries `do_not_repeat`.
Blocked manifest residue has no such field, so `blocked` reaches the neutral
fallback.

Fable's fairness qualification is also correct. Grown `stalled` and
`effect_failure` deaths are written by `runtime/tension_runner.lua` with
explicit `do_not_repeat`, so they already become warnings. This finding is
specific to the new blocked path.

## 4. Qualification Of The Suggested Gate

The proposed requirement:

```text
blocked grave must not be neutral
```

is accepted.

The proposed requirement:

```text
attach it and assert non-zero routing-visible pressure
```

needs a precise reader and moment before it can become a test.

Current channels have different activation laws:

```text
warning -> karma_resistance only after a relevant repeated cycle
bequest -> karma_help only when unresolved newborn pressure also exists
neutral -> no actionable pressure
```

An immediate generic `pressure > 0` assertion could either fail for a correct
conditional reader or pass through an unrelated pressure source. The permanent
gate must name:

```text
grave kind
reader kind
target operator or resisted edge
activation precondition
source references
expected truth status
```

## 5. Blocked Is Not Automatically Warning

Mapping every blocked life to `warning` would be a premature semantic choice.

A warning means that a known path or form should not be repeated. A rejected
validation may instead mean:

```text
the same attempt must not be repeated
the artifact should be repaired and validated again
useful completed work should be inherited while one failed form is replaced
an external prerequisite is missing
human input is required
```

The death cause alone does not distinguish these cases. The table stage must
compare at least:

```text
warning
extended bequest
new repair/blocked grave kind
typed classification selected from validation evidence
```

Current preference is a typed repair/blocked channel rather than treating all
rejection as generic resistance, but this is a chaos-level hypothesis, not an
implemented contract.

## 6. The More Fundamental Missing Carrier

Fable's standing question is the most important part of the audit.

The independently grown corpse contains:

```text
rejected_count = 1
rejection_reason = validation_rejected
validation_event reference
runtime_reconciliation_event reference
completion_state = blocked
```

This is sufficient to prove that rejection happened. It is not sufficient for
a descendant to act on the rejection.

The failed spell identity still exists in the validation payload under
`spell_results`, including fields such as:

```text
name
spell_kind
intention_hash
command_or_code
success
stderr
exit_code
```

`organs/manifest.lua` currently projects only counts, a generic reason, and the
validation event reference. Therefore the manifest corpse tells its descendant
"something failed" but not "which form failed".

Classifying this carrier before preserving failed-form identity would create an
actionable-looking grave with no actionable payload.

## 7. Required Blocked-Lineage Witness

The promotion corpus must include one grown blocked lineage with three separate
assertions:

```text
classification:
  blocked corpse is not neutral

carrier:
  grave preserves bounded identity of each failed validation referent
  and references the original validation/reconciliation evidence

reader:
  after a named activation precondition, a named pressure reader consumes
  that carrier and produces a typed contribution with provenance
```

These are three contracts. A single assertion on `grave_kind` cannot prove all
of them.

## 8. Next Plan

### Step 4.3A - Promotion Corpus Chaos

Create one corpus document containing grown lives for:

```text
accepted manifest
blocked validation and blocked lineage
no-viable stalled death
typed substrate/tool effect failure
budget mortality
identity-loss mortality
tree-authority host tick limit with a final committed-but-not-executed edge
real CONNECT execution
real DISSOLVE execution from rigidity pressure
real CHOOSE collapse with more than one alternative and loss > 0
legacy-observer ablation over the same tree lives
```

For every life record Packet state, pressure witnesses, selected edge,
readiness, legacy dissent/agreement, economics, terminal outcome, grave outcome,
candidate/committed/executed ledger state, and whether every written record has
a named reader.

### Step 4.3B - Table

Build separate tables for:

```text
corpus cases and required grown fixtures
terminal-to-grave classification
blocked failed-form carrier
grave-to-pressure readers and activation laws
promotion metrics and forbidden false greens
```

The blocked classification decision happens here, not directly in code.

### Step 4.3C - Crystall

Define exact contracts for:

```text
grown fixture construction
bounded failed-spell identity
blocked grave kind and payload
named pressure reader
candidate/committed/executed evidence
observer isolation
promotion acceptance thresholds
```

Historical red evidence remains preserved. Synthetic deaths may test local
shape, but promotion claims require corpses grown by the body.

### Step 4.3D - Manifest Code And Tests

In order:

```text
1. grow a pending blocked-lineage red gate outside tests/run.lua
2. project bounded failed-form identity into manifest residue
3. implement the selected grave classification
4. implement the named reader and activation law
5. make the blocked-lineage gate green and register it
6. run the complete promotion corpus
7. treat only failures demonstrated by grown evidence
```

### Step 5 - Authority Decision

Changing the default from `shadow` to `tree` remains a separate reviewed
commit. It is not authorized merely because individual gates are green.

Before that decision:

```text
promotion corpus is complete enough to expose all required paths
no harness failure is disguised as Packet death
legacy observation remains massless under ablation
blocked terminal and lineage behavior are both honest
pressure defects are documented rather than hidden by weights
explicit legacy mode remains available as rollback control
```

The step-5 promotion record must also name one deliberate capability change:

```text
legacy rejected path:
  ☱ -> ☴ semantic repair
  without hands, OBSERVE could not repair the artifact
  the path spent budget until a later logic stamp stopped it

tree rejected path:
  ☱ -> △ blocked
  the body stops immediately and reports the failed validation honestly

declared trade:
  honest bounded failure replaces simulated repair
  real semantic repair is deferred until hands can change reality in pipeline A
```

This is not a regression to hide and not an existing repair ability to
preserve. It is an explicit removal of a route whose name promised more than
the body could perform.

## 9. Immediate State

```text
checkpoint ab70c1b remains valid
step 4.2 remains complete
Fable audit document remains preserved as external evidence
blocked lineage is an open Gate C pressure
no production code should change before table/crystall contracts exist
```

## 10. Courier Addendum Accepted

Fable's two additions are accepted.

The current committed-without-executed boundary test in
`tests/test_edge_evidence.lua` runs with `router_mode=shadow`: legacy owns the
route and tree only predicts. It therefore does not prove the same ledger law
under tree authority. Step 4.3A now requires one real tree-authority
`tick_limit` life. The host ceiling is not Packet death: the Packet remains
alive, the final route is committed, and its destination operator has not
executed. The ledger must preserve exactly that distinction.

The semantic-repair delta is now a mandatory field in the eventual step-5
promotion record. Future archaeology must be able to distinguish removal of a
non-functional repair imitation from loss of a real capability.

The external message is preserved verbatim in
`fable_step4_audit_courier_addendum_2026-07-17.md`.
