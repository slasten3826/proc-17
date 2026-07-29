# QA QN19 Cleanup Ambiguity E9 Manifest

manifest status: implemented and promoted
date: 2026-07-28
authority: closed causal topology plus named cleanup witnesses
execution path: production controller terminal, launcher collector and provider witness
body QA authority: absent

## 1. Manifested Boundary

QN19 now executes rather than skips. It distinguishes six conditions that
previously collapsed into either a trusted crash or caller-supplied words:

```text
terminal frame missing
top-supervisor reap ambiguous
stdout/stderr observation incomplete
scratch observation incomplete
namespace cleanup incomplete
postflight source drift
```

None is a candidate rejection. Every case yields zero candidate witnesses,
quarantines the exact sealed source and denies replay before another provider
call.

## 2. Exact Result

```text
cases declared             6
cases executed             6
cases matched              6
stream variants            2
candidate outcomes         0
source quarantines         6
replayed provider calls    0
production exclusions      4
post-run residue checks    7
```

Five host-process rows are grown by the parameterless native driver. The sixth
case, postflight source drift, is grown by two real repository inventories in
Lua. C does not claim a repository fact it cannot observe.

## 3. Causal Error Topology

`runtime/qa_process.lua` now owns one closed table of legal class, code, stage,
phase/start and cleanup/reap/EOF combinations. Both raw native normalization and
provider-witness source disposition read that table.

Only `supervisor_unavailable` and `source_staging_failed` with exact clean
pre-start evidence are reusable. Every other legal topology is non-reusable.
An impossible topology causes a quarantine attempt before loud failure and
cannot produce a final witness.

The pre-treatment witness was:

```text
QN19_IMPOSSIBLE_ACCEPTED|reap_ambiguous|not_started|complete|consumed
```

That tuple is now rejected as a causal-topology mismatch.

## 4. Controller Terminal V2

The private 572-byte success-only report is now the fixed
`proc17.qa.controller_terminal.v2` union:

```text
kind=result  -> exact candidate evidence
kind=error   -> one controller-owned missing observation
```

The error branch can name stdout, stderr or scratch. It carries the exact
identity, private process token, source-stage evidence and one seven-member
finality vector. Result and error storage are mutually exclusive; unused bytes
must be zero. The controller still writes at most one private terminal record.

Actual stream-drain and scratch-ambiguity paths can now write this error branch.
Absence or corruption of the private record remains a loud supervisor failure;
it is not guessed into a more specific code.

## 5. Namespace Predicate

The old literal `namespace_cleanup_complete = 1` is gone. The top supervisor
returns named observations for retained pidfd identity, complete private record,
record EOF, exact controller reap and closed controller authority descriptors.
The finalizer derives cleanup from them.

A missing namespace witness emits typed
`namespace_cleanup_incomplete`. A valid controller error plus a simultaneous
namespace ambiguity is loud rather than being collapsed into one convenient
story.

## 6. Production Separation

QN19 case ids, record prefixes and selectors occur only in test artifacts. The
production supervisor and launcher contain the real terminal/error machinery
but no campaign vocabulary, environment selector or injection API. The native
driver rejects command-line arguments.

## 7. Promotion Ledger

The only control-matrix transition was:

```text
QN19 red -> green
QA matrix 42 green / 42 red -> 43 green / 41 red
```

QN19 is mandatory in the ordinary native suite. QN20 is its only deferred
native control; all body QE/QV controls retain their prior status.

## 8. Runtime Evidence

```text
qa-supervisor-cleanup-ambiguity-test  6/6; two stream variants
ordinary native QA suite              19 green / 0 red / 1 deferred
QA red control matrix                 43 green / 41 red / 0 skip
production static closure             green
production artifact/API audit         four exclusions green
ASan/UBSan focused native driver       five exact rows green
LeakSan                                not claimed: unavailable under ptrace
GCC -fanalyzer changed boundary        green
post-run process/root audit            empty
full ordinary suite                    107 suites, all tests ok
mortality battery                      8/8
git diff --check                       green
```

## 9. Non-Claims

This manifest does not prove QN20 repeated-run residue freedom, universal host
cleanup, body-owned QA evidence/verdict, software acceptance, retry/resume or a
general command hand.

## 10. Next Boundary

E10/QN20 must repeat provider transactions under bounded load and measure
descriptor, process, mount, root and memory residue. That campaign remains
separate from Packet QA authority.
