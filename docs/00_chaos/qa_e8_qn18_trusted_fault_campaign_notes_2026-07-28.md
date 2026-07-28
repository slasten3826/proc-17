# QA E8 QN18 Trusted Fault Campaign Notes

date: 2026-07-28
status: E8.1 implementation diagnosis
scope: C9 / QN18 trusted-runtime faults only
authority: document_decision over the hostile TABLE/CRYSTALL and E7 evidence

## 1. What QN18 Must Prove

QN17 proved that hostile candidate bytes remain contained. QN18 has a different
subject: failures of the trusted execution machinery itself.

The nine inert `class=trusted_fault` records must never be copied into a
candidate repository or interpreted by production code. They are instructions
to one parameterless test campaign. That campaign must demonstrate that a
trusted-runtime failure remains one of:

```text
loader rejection
trusted invariant failure
typed infrastructure error
provider source ambiguity
```

No row may become an accepted or rejected candidate outcome.

## 2. Boundary Ownership

The nine rows do not have one physical writer.

| Fixture | Physical writer / reader | Required fact |
|---|---|---|
| wrong launcher ABI | production Lua provider loader | module rejected before provider construction |
| wrong supervisor identity | production launcher identity verifier | opened binary rejected before RUN/candidate |
| malformed request frames | production supervisor request decoder | every declared variant exits without STARTED |
| malformed result frames | production launcher v1 collector, then provider source finality | trusted invariant; source quarantined before loud return |
| crash before STARTED | production launcher v1 collector | `supervisor_crashed`, not_started |
| crash after STARTED | production launcher v1 collector | `supervisor_crashed`, started |
| lost result pipe | production launcher v1 collector | `result_pipe_lost`, never candidate outcome |
| wait/reap ambiguity | production launcher v1 collector | `reap_ambiguous`, never candidate outcome |
| postflight source drift | production provider witness transaction | `source_drift`, quarantined |

The campaign joins these observations. It does not grant one layer authority
over facts owned by another layer.

## 3. Runtime Gap Found Before the Harness

The present v1 collector already preserves the distinction between a crash
before and after STARTED. It also rejects malformed result frames loudly.

It does not yet preserve two other distinctions:

```text
result descriptor read failure
waitpid/reap ownership failure
```

Both currently leave `proc17_qa_launcher_collect_v1` as a generic system
failure. `run_source_consumer` then maps every such failure to
`result_pipe_lost`, so a real reap ambiguity is mislabeled.

QN18 must repair this classifier before testing it. The repair belongs to the
production collector because these are real host observations, not injected
candidate semantics:

```text
read failure on result channel -> result_pipe_lost
wait/reap ownership failure    -> reap_ambiguous
malformed trusted bytes        -> trusted invariant, loud
```

The repair must retain the known STARTED state and must never fabricate clean
reap, EOF, cleanup or cost evidence.

## 4. Test Build Law

Fault selection must not enter the production request, result, environment,
Lua API or candidate source. The campaign therefore uses a separate native
test closure:

```text
production state-machine sources
+ test-only internal header
+ PROC17_QA_FAULT_TESTING
+ closed driver-owned enum
```

The test closure has a distinct launcher ABI/build identity and a distinct
supervisor build identity. Its selector is accepted only by the test driver,
outside every production wire frame.

The production artifacts must contain none of:

```text
fault request/result key
fault environment selector
fault Lua function
fault fixture id
fault-test symbol or build identity
```

The production loader must reject the test launcher build. The production
launcher identity verifier must reject the test supervisor build.

## 5. Production Source Versus Production Artifact

A test-only conditional in a shared C source is not production authority by
itself. The authority boundary is the compiled artifact and its accepted
identity. This is allowed only if all of the following hold:

```text
the conditional is guarded by PROC17_QA_FAULT_TESTING
the production build never defines that macro
the test-only declarations live in one internal test header
the production binary has no fault symbol/string/API
the test binary has a different identity
the production loader rejects the test binary
```

Where a fault can be grown without a conditional, prefer the real production
state machine plus a synthetic trusted child/process observation. A test hook
is justified only at an otherwise unforceable trusted boundary.

## 6. Exact Variant Coverage

The two frame rows are internally closed sub-campaigns:

```text
short
oversized
wrong_magic
wrong_version
unknown_kind
digest_mismatch
trailing
```

Malformed request variants are sent to the real production supervisor. None
may emit STARTED. Malformed result variants are sent to the real production
launcher collector after the minimum legal prefix where required. Every one
must produce a trusted invariant rather than a candidate classification.

The fixture `pressure` field has no expectation authority. Expected outcomes
come from a separate exact campaign matrix keyed by fixture id.

## 7. Source Finality

The native collector does not own a repository source lease. Therefore native
malformed-result evidence and provider quarantine evidence are two named
observations in one campaign row:

```text
native collector: malformed trusted terminal -> trusted invariant
provider witness: trusted callback contradiction -> quarantine -> loud
```

Postflight drift is grown directly through the real provider-witness
transaction: a stable pre-inventory, one production RUN and a differing
post-inventory. It must return `source_drift` with a quarantined lease and no
candidate witness.

## 8. Closed Campaign Contract

One parameterless Lua entrypoint owns the nine-row campaign. It:

```text
validates all nine inert records and their embedded ids
rejects missing, duplicate or extra trusted-fault rows
invokes one parameterless native fault driver
validates the exact native row records
grows loader rejection and provider postflight rows
audits production symbols, strings and public Lua keys
prints one exact nine-row summary
```

The native driver may print only bounded, fixed-schema result lines. It accepts
no fixture path, arbitrary fault name, candidate bytes, command, environment
selector or production source handle.

## 9. Acceptance

```text
trusted rows declared       = 9
trusted rows executed       = 9
trusted rows matched        = 9
candidate outcomes          = 0
production exclusions       = all named controls green
source quarantines          = malformed-result policy + source-drift policy
```

The authorized control delta is exactly:

```text
before E8  41 green / 43 red
after E8   42 green / 42 red
```

Only QN18 changes. QN19/QN20 and every body QE/QV control remain unchanged.

## 10. Falsifiers

```text
TF01 a candidate can name a fault mode
TF02 a production request/result accepts a fault key
TF03 a production artifact contains a test fault symbol or fixture id
TF04 the production loader accepts the fault launcher
TF05 the production launcher accepts the fault supervisor identity
TF06 one malformed request variant emits STARTED
TF07 one malformed result becomes a candidate outcome
TF08 crash-before is reported started
TF09 crash-after loses its STARTED attestation
TF10 result-pipe loss is reported as reap ambiguity or vice versa
TF11 unknown finality is coerced to complete
TF12 trusted contradiction returns before source quarantine attempt
TF13 postflight drift consumes the source as clean
TF14 one row is skipped or selected by descriptive pressure text
TF15 any control except QN18 changes color
```

## 11. Implementation Order

```text
E8.1 this diagnosis
E8.2 TABLE/CRYSTALL exact ownership, build and matrix amendment
E8.3 red production-exclusion and fault-topology controls
E8.4 collector precision plus distinct test build and nine-row campaign
E8.5 artifact/identity/source-disposition audit
E8.6 manifest, full batteries and exact 42/42 promotion
```

QN19 remains separate. QN18 proves named fault classification. QN19 will prove
the broader cleanup-ambiguity disposition lattice and must not be smuggled into
this promotion.
