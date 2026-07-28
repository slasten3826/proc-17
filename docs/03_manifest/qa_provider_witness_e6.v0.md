# QA Provider Witness E6 Manifest

manifest status: implemented, private provider witness v1
date: 2026-07-28
authority: post-disposition projection of production RUN v1 evidence
body QA authority: absent
expected-red delta: zero

## 1. Manifested Boundary

E6 completes C7 without creating the QA hand. The executable chain is:

```text
sealed source lease
-> exact pre-inventory
-> production RUN v1 process observation/error
-> exact post-inventory
-> untagged private pending join
-> terminal source disposition
-> detached provider witness report/error v1
```

No final witness object exists while the source lease is live. Failure to write
terminal disposition is loud and yields no report or error object. Trusted
inventory contradiction attempts quarantine first and becomes loud only after
the finality attempt.

## 2. Report V1

`qa.provider_witness_report.v1` contains the exact process reason,
termination, immutable first cause, complete finality, bounded stream/resource/
scratch measurements and cost. It also binds exact pre/post inventory ids and
the terminal `consumed` source disposition.

The report has no duplicate cleanup boolean. Candidate cleanup, reap, EOF,
scratch and namespace facts remain in the authoritative finality record.

```text
expected_exit       -> accepted provider witness
other contained RUN -> rejected provider witness
```

This accepted/rejected word is private provider classification. It is not a
Packet check, verdict, manifest or software acceptance.

## 3. Error V1

`qa.provider_witness_error.v1` preserves candidate start, cleanup, launcher
reap and result EOF as exact tri-states. `unknown` is never coerced to false or
complete. A pre-candidate source mismatch is positively `not_started`, closes
the source as `consumed` and carries no fabricated process cost. Started or
ambiguous process failure without definitive candidate finality quarantines
the source. Postflight drift also quarantines while preserving available
measured cost.

Old provider process v0 records are rejected by the executable witness join.
Historical v0 normalizers remain separately tested archaeology and have no C7
input authority.

## 4. Zero-Mass Proof

The witness transaction snapshots and compares Packet status, operator, tick,
trace, revisions, tension, runtime budget, field, death and manifest. It also
compares the detached public root projection before and after execution.

The returned report is detached: mutating its source disposition or economics
changes neither Packet state nor repository authority. Step D receives no
lineage budget handle, imports no lineage writer and therefore cannot charge or
rewrite lineage economics.

The body request verifier rejects both report v1 and a forged report-v0 alias.

## 5. Runtime Evidence

```text
clean and Lua-error production witnesses        green
preflight mismatch starts zero native RUNs      green
postflight drift quarantines                    green
unknown process tri-states survive exactly      green
legacy process witness fails loudly             green
trusted malformed inventory finalizes then loud green
returned mutation/body/root/budget ablation     green
full ordinary suite                             all tests ok
mortality battery                               8/8
QA control matrix                               40 green / 44 red / 0 skip
native QA matrix                                16 green / 4 expected red
```

## 6. Non-Claims

E6 does not implement `runtime.qa_execution`, a Packet request writer, an
execution receipt, check evidence, a verdict, QA economics, software
acceptance, hostile-candidate completion, trusted-fault injection or repeated
residue proof. It does not make QN17-QN20 green.

## 7. Next Boundary

The next campaign begins at E7/C8 and QN17. It must prove hostile candidates
remain contained under production identity without weakening the finality and
source-disposition laws manifested here. Body-owned QA authority remains a
later, separately promoted transaction after the hostile native campaign.
