# QA E8 QN18 Campaign Audit

date: 2026-07-28
status: runtime-confirmed E8 audit
scope: C9 / QN18 trusted-runtime faults only

## 1. Cold Result

The production and fault-test closures were deleted, rebuilt from source and
then exercised by the parameterless QN18 campaign:

```text
declared=9
executed=9
matched=9
candidate_outcomes=0
source_quarantines=2
production_exclusions=6
```

The seven native rows also matched their exact closed protocol:

```text
wrong supervisor identity  rejected before candidate execution
malformed requests         7/7 rejected before STARTED
malformed results          7/7 loud trusted invariants after STARTED
crash before STARTED       supervisor_crashed / not_started
crash after STARTED        supervisor_crashed / started
lost result channel        result_pipe_lost / reap complete / EOF unknown
lost reap ownership        reap_ambiguous / reap unknown / EOF complete
```

Loader rejection and postflight source drift were grown through their real Lua
owners, not forged as native-driver records.

## 2. Classifier Audit

The production v1 collector now keeps result-channel failure, reap-ownership
failure, dirty child exit and malformed trusted bytes as four different facts.
It copies the already observed STARTED state and does not turn an unobserved
reap or EOF into a clean boolean.

The generic launcher path no longer relabels every collector system failure as
`result_pipe_lost`. A contradiction outside the typed collector outcomes is
loud trusted failure. No trusted-runtime row can become an accepted or rejected
candidate result.

## 3. Source Finality Audit

The native malformed-result sub-campaign proves the collector boundary. A
separate provider-witness probe proves the policy boundary: a trusted callback
contradiction quarantines its source before the contradiction is raised. A
real postflight inventory drift independently returns `source_drift` with
terminal `quarantined` disposition and no candidate witness.

Both probes deny replay. The campaign therefore has two source-quarantine
witnesses without pretending that the native collector owns repository leases.

## 4. Production Exclusion Audit

The test closure has a different launcher ABI, supervisor identity and artifact
name. The production loader rejects the test launcher, and the production
identity verifier rejects the test supervisor.

Compiled-artifact and public-API inspection confirms:

```text
fault launcher and production launcher digests differ
fault supervisor and production supervisor digests differ
production launcher exports no proc17_qa_fault_test_* symbol
production artifacts contain no fault-test ABI, identity or fixture id
production Lua exports no fault API or selector
production request/result/environment schemas contain no fault field
```

The first campaign draft attempted to inspect production strings through an
unbounded external `strings` stream and tripped its own 64 KiB output ceiling.
The repair scans the already bounded artifact bytes directly. The ceiling was
not weakened, and no test identity was accepted as production.

## 5. Native Audit

```text
cold fault target                         green, exact 9/9 join
static production supervisor closure      green, self-test passed
GCC -fanalyzer on collector               green
ASan + UBSan native seven-row driver       green
LeakSan                                    not claimed; ptrace environment rejects it
post-run QA processes                      none
post-run QN18/repository temporary roots   none
```

The sanitizer driver emitted the same seven exact records as the normal test
build. This is evidence about the named driver and collector paths, not a
universal leak-freedom claim.

## 6. Promotion Consequence

The only authorized control transition is:

```text
QN18 red -> green
QA matrix 41 green / 43 red -> 42 green / 42 red
ordinary native QA suite 17 green / 3 deferred
                         -> 18 green / 2 deferred
```

QN19 cleanup/source-disposition ambiguity and QN20 repeated residue remain
deferred. Every body QE/QV control remains red.

## 7. Non-Claims

E8 does not create a Packet QA request, check evidence, verdict, candidate
acceptance, retry policy or software acceptance. It does not prove arbitrary
language containment, 32-generation residue freedom or all possible host
failures. It proves the exact nine trusted-fault rows and the production
exclusion boundary required to test them safely.
