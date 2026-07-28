# QA E7 QN17 Hostile Candidate Campaign Notes

date: 2026-07-28
status: E7.1 implementation diagnosis
scope: C8 / QN17 candidate fixtures only
authority: document_decision over the existing hostile TABLE/CRYSTALL and E6

## 1. What Is Red

QN17 is currently red because the named Make target does not exist. That red
state proves only that the hostile campaign has not been executed. It does not
yet prove that any hostile candidate is contained.

The production boundary needed by the campaign already exists:

```text
first hand -> exact candidate seal -> source lease
-> production RUN v1 -> process observation
-> post-inventory -> source disposition
-> provider witness v1
```

E7 must exercise this boundary rather than add another execution engine.

## 2. Closed Corpus

`tests.support.qa_hostile_fixtures` owns 26 inert bounded records:

```text
17 class=candidate       E7 / QN17
 9 class=trusted_fault   later E8/E9 / QN18-QN19
```

E7 may execute only the 17 candidate rows. A class mismatch, missing id,
duplicate id, missing marker, mismatched embedded fixture id, byte-bound
failure or count other than 17 aborts before candidate materialization.

The exact fixture bytes become `tests/run.lua` unchanged. The inert marker and
fixture identity are Lua comments, so no stripping, templating or semantic
rewrite is needed. The first hand, not the harness filesystem API, writes those
bytes into a fresh identity-owned repository.

## 3. No Label Authority

The fixture `pressure` string is descriptive archaeology. It has no expected
outcome authority. A separate closed campaign matrix maps exact fixture ids to
runtime facts:

```text
clean                                              expected_exit
nonzero + Lua error + scratch-capacity failure     unexpected_exit
CPU and present wall-loop                          cpu_limit
allocator exhaustion                               memory_limit
stdout/stderr flood                                 output_limit
source/path/API/descriptor closure probes          expected_exit
```

The wall-loop fixture is CPU spin under closed stdin. The sigsys fixture proves
Lua API closure and therefore exits cleanly; QN13 separately owns real SIGSYS
evidence. Names and error strings never derive a cause.

## 4. Trusted Harness

The dedicated harness is outside `tests/run.lua`. It is the only code allowed
to combine the inert fixture reader with an execution boundary. Per candidate
row it must:

```text
read and validate inert bytes
grow one fresh identity-owned root
materialize bytes through repository.create_text_file.v0
seal the exact resulting tree
prepare one provider witness plan
assert entrypoint bytes/hash bind the original fixture
execute production RUN v1 exactly once
assert report v1 reason/outcome/cause/finality
assert seal inventory == pre inventory == post inventory
assert source disposition consumed
assert no raw bytes/path/fd/handle/process token crosses
let identity-owned cleanup remove the disposable root
```

`runtime.qa_provider_witness` already enforces Packet/public-root/runtime-budget
ablation and source finality. The E7 harness reads that boundary; it receives no
Packet writer, lineage writer or body verdict authority.

## 5. Acceptance

The Make target `qa-supervisor-hostile-fixtures-test` invokes only the dedicated
Lua campaign and succeeds only with:

```text
candidate rows declared = 17
candidate rows executed = 17
candidate rows matched  = 17
source drifts           = 0
cleanup ambiguities     = 0
```

One skipped row, alternate reason, wrong outcome, incomplete finality,
inventory mismatch, raw authority leak or cleanup failure fails the target.
It must not alias QN16 or directly `load` fixture bytes in the trusted process.

The expected QA control delta is exactly:

```text
before E7  40 green / 44 red
after E7   41 green / 43 red
```

QN18-QN20 and all body QE/QV controls remain red.

## 6. Security Boundary

This campaign intentionally executes hostile bytes, but only after they cross
the same source, seal, mount, namespace, seccomp, resource, finality and witness
boundaries used by production RUN v1. The trusted harness never grants a
command, argv, environment, path, native module or provider handle to the
candidate.

QN17 proves containment and exact classification for this named 17-row corpus.
It does not prove universal Lua safety, trusted-runtime fault handling, residue
freedom across repeated runs or body-owned QA acceptance.

## 7. Implementation Order

```text
E7.1 this diagnosis
E7.2 TABLE/CRYSTALL exact harness amendment
E7.3 closed matrix and topology falsifiers
E7.4 dedicated campaign plus Make target
E7.5 hostile execution and isolation audit
E7.6 manifest, full batteries and exact color delta
```
