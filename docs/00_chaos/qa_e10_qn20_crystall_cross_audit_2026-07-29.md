# QA E10 / QN20 Cross-Crystall Audit

Status:

```text
layer: CHAOS audit residue
date: 2026-07-29
chapter: 8.5.5E10.2
audited head: b74c1f5
subject:
  docs/01_table/yellowprints/qa_repeated_residue_campaign_yellowprint.v0.md
  docs/02_crystall/blueprints/qa_repeated_residue_campaign.v0.md
scope: C10/QN20 repeated private-provider residue only
cross-crystall audit: satisfied after amendments recorded here
implementation authorized: C10.1-C10.7 in exact CRYSTALL order
Packet/body QA authority: forbidden
```

## 0. Audit Question

The TABLE already established why QN20 needs one long-lived host and exact
per-iteration residue evidence. This audit asks the implementation question:

```text
Can the CRYSTALL be built against the current native, Lua and Make boundaries
without inventing production authority, hiding observer residue or silently
restarting the machine being measured?
```

The answer is yes only after six precision amendments. None changes production
candidate semantics. All six are now present in the TABLE and CRYSTALL.

## 1. Cold Baseline

Observed before implementation:

```text
git branch: main
git head: b74c1f5
lua tests/run.lua: 107 suites, all ok
lua tests/smoke_mortality_battery.lua: 8/8
lua tests/test_qa_native_supervisor.lua: 19 green / 0 red / 1 skip
QN20: explicitly deferred
lua tests/red_qa_hand.lua: expected nonzero, exact 43 green / 41 red
matching proc17 QA processes after the probes: zero
```

The production-supervisor process probe also confirmed the Linux comm value:

```text
executable: ./native/proc17_qa_supervisor
comm: proc17_qa_super
```

Unrelated CLI/self-audit worktree changes existed before this audit and were
neither reverted nor used as QN20 evidence. No runtime, body, provider or native
implementation file was changed during E10.2.

## 2. Current Boundary Map

| Proposed CRYSTALL act | Current owner | Audit result |
|---|---|---|
| build repository provider | `tests/support/repository_native_build.lua` / Make | currently called by each one-shot candidate; must move outside QN20 Lua |
| build QA provider | `qa_provider_witness.load_providers` / Make | currently called by each one-shot candidate; must move outside QN20 Lua |
| load providers | `runtime/repository_provider.lua`, `runtime/qa_provider.lua` | exact native loaders already exist |
| probe environment | `runtime/qa_provider.lua` | exact production projection already exists |
| fresh body/root/seal | `qa_provider_witness.with_candidate` | reusable construction, but current helper reloads infrastructure |
| exact source replay denial | `repository_capability.reserve_qa_source` | typed denial occurs before provider callback |
| source handle finality | `repository_capability.finish_qa_source` | provider close is called and private handle is cleared |
| candidate process finality | supervisor/controller/launcher v1 | already promoted by QN17-QN19 |
| allocator terminal evidence | private controller/report validators | stable and bounded; forced death need not report current zero |
| owned-root identity cleanup | fixture guard | current create/probe/cleanup exists; absence/sentinel phases are additive test operations |
| QN20 color | `tests/test_qa_native_supervisor.lua` | target exists and is deliberately skipped |
| exact red frontier | `tests/red_qa_hand.lua` | current owner requires 43/41 |

No requested QN20 fact requires a production Packet writer, candidate-visible
selector, new result kind or public allocator field.

## 3. Findings And Disposition

### F1 - Build Ownership Was Split

Class: contract contradiction, high.

CRYSTALL section 15 originally made `open_campaign()` execute Make, while
section 22 said the Make target owns build dependencies. The current root helper
also calls Make on first use, so merely prebuilding the target would not have
stopped an in-process build during iteration 1.

That would weaken the central claim. A 32-transaction process that recompiles or
reloads its provider before baseline is not observing one already-formed host.

Disposition:

```text
outer Make target builds provider-shell, qa-provider-shell, fixture-helper,
observer artifacts and report controls before Lua starts;
open_campaign runs no Make/compiler/build command and clears no module;
owned_temp_root.use_prebuilt_helper performs only the fixed helper self-test;
the old with_candidate path keeps an explicit compatibility build wrapper.
```

Status: corrected in TABLE sections 0/4 and CRYSTALL sections 14/15/22.

### F2 - The Observer Could Retain Itself

Class: liveness omission, high.

The original weak set covered Packet, registry, plan, report, services and root.
It excluded the per-iteration opaque root subject, native snapshots and public
snapshot projections. A campaign could therefore prove that the body was
collectible while leaking one native snapshot array per generation.

Disposition: two named weak sets and two GC boundaries.

```text
body/support set -> zero after root cleanup, before post-cleanup capture;
observer set -> zero after post-cleanup comparison and explicit release;
observer session + immutable baseline remain campaign-owned;
durable records contain detached deltas/scalars only.
```

Status: corrected in TABLE sections 8/12/15/18/19 and CRYSTALL sections 16/19.

### F3 - Capture Order Could Make the Observer Self-Blind

Class: observability ordering defect, high.

If the parent-fd set were captured first and the observer then leaked a process,
mount, namespace or root scan descriptor, that descriptor would not appear in
the same observation. A final capture could therefore create residue after the
only fd census capable of seeing it.

Disposition:

```text
process -> namespace -> mount -> root scans;
close all of their descriptors;
parent-fd scan last;
close its own scan descriptor;
memory-only projection assembly afterward.
```

Any close failure is typed observation failure. RO15 deliberately retains one
observer-owned pre-fd-scan descriptor and requires same-capture detection.

Status: corrected in TABLE R14/section 6 and CRYSTALL sections 7/12.

### F4 - Process Channels Were Called Disjoint But Overlap

Class: schema contradiction plus falsifier gap, medium.

A direct live production supervisor satisfies both `direct_live_child_count`
and `matching_supervisor_process_count`. A direct fixed-comm zombie can satisfy
both the direct-zombie and unresolved channels. Calling those channels disjoint
was false and invited a future aggregate sum resembling the old double-counted
pressure defect.

Disposition:

```text
the channels are independent and may overlap;
they are never summed;
clean means each channel is zero;
RO13 runs the exact production executable on valid blocking descriptors;
RO14 grows a fixed-comm unreadable zombie;
the observer itself never kills or reaps either fixture.
```

The protected native self-test owns teardown only after the failed observation.

Status: corrected in TABLE sections 6/19 and CRYSTALL sections 5/8/12/26.

### F5 - Sentinel Had A Writer And Reader But No Complete Timeline

Class: choreography omission, medium.

The contract required `sentinel_exact = true` but the per-iteration sequence did
not name a sentinel probe. A root-cleanup defect could also mutate the sentinel
after a transaction-only probe and remain hidden until the end.

Disposition:

```text
probe after production transaction;
probe after exact root cleanup;
probe before final snapshot after final GC;
identity-clean sentinel last;
require no-follow ENOENT before printing success.
```

Status: corrected in TABLE sections 14/15 and CRYSTALL sections 14/16/20/21.

### F6 - Provider Table Identity Was Too Shallow

Class: identity underspecification, medium.

The same `package.loaded` table can survive while one callable or environment
value is replaced. Comparing only table identity, provider id and environment id
would therefore allow in-place infrastructure drift.

Disposition: freeze and compare all of the following on every iteration:

```text
package.loaded table identities;
every production callable used by the campaign;
provider/protocol/build ids;
normalized environment value digest.
```

Status: corrected in TABLE section 4 and CRYSTALL section 15.

## 4. Confirmed Non-Defects

### Forced-Termination Allocator State

The production controller may send SIGKILL after `output_limit` or
`memory_limit` wins, before candidate `lua_close`. A nonzero private
allocation-at-death counter is therefore compatible with a reaped process.
QN20 correctly joins stable/bounded private terminal evidence with process
reap, namespace finality and zero host process/fd residue. It does not add a
false universal current-zero rule.

### Source Replay

`reserve_qa_source` returns `repository_qa_source_already_reserved` before
`with_qa_source` can enter the provider. Existing PT-T08 callback counting is a
named reader of that ordering. No second production launch counter is needed.

### Root Absence

The proposed fixture-guard operation checks the detached prior identity through
the fixed path grammar and no-follow parent-relative ENOENT. The observer's
prefix census independently catches any other matching root. A Lua `cleaned`
flag is not accepted as evidence.

### Observer Authority

Opaque session/subject/snapshot userdata carries copied read-only identity only.
The API accepts no pid, fd, mount selector, command or arbitrary root path. It
cannot execute, wait, kill, reap, unmount, close foreign authority or clean
detected residue.

## 5. Cross-Crystall Questions

| ID | Question | Verdict |
|---|---|---|
| X1 | Can the observer avoid exporting live host authority? | yes, opaque copied records only |
| X2 | Can one capture see residue created by its own earlier scans? | yes after F3, fd scan is last |
| X3 | Are exact supervisor and unreadable-zombie paths both falsified? | yes after F4, RO13/RO14 |
| X4 | Does memory finality distinguish allocation-at-death from live retention? | yes, private terminal evidence is joined with reap/host absence |
| X5 | Can body objects collect while the root subject remains needed? | yes, first weak boundary precedes post-cleanup capture |
| X6 | Can observer objects collect before the next iteration? | yes after F2, second weak boundary |
| X7 | Can replay denial happen without a second provider launch? | yes, typed reserve boundary + PT-T08 |
| X8 | Is exact root absence independent of Lua state? | yes, fixture guard + observer prefix census |
| X9 | Is one provider genuinely continuous across all 32 rows? | yes after F1/F6, prebuilt one-load exact surface |
| X10 | Can test instrumentation enter production artifacts? | excluded by placement, dependency identity and compiled scans |
| X11 | Does QN20 write Packet/body truth? | no |
| X12 | Does every new record have a first reader? | yes, section 6 below |

## 6. Writer And Reader Closure

| Fact | Writer | First reader | Closure |
|---|---|---|---|
| fixed schedule | TABLE | campaign enumerator | closed |
| provider surface identity | prebaseline loader/probe | per-iteration continuity guard | closed after F6 |
| production outcome/finality | controller/launcher | existing process normalizer | closed |
| allocator/process memory finality | private validators + reap owner | campaign comparator | closed |
| source disposition/replay denial | repository registry | report/replay assertions | closed |
| post-transaction host snapshot | read-only observer | iteration comparator | closed |
| post-cleanup host snapshot | read-only observer | iteration comparator | closed |
| body/support weak liveness | Lua GC + body weak set | pre-post-cleanup guard | closed |
| observer weak liveness | Lua GC + observer weak set | pre-next-iteration guard | closed after F2 |
| sentinel projection | fixture guard | transaction/cleanup/final guards | closed after F5 |
| body/public-root digest | pure Lua derivation | iteration comparator | closed |
| iteration record | campaign assembler | summary assembler | closed |
| summary | summary assembler | QN20 ordinary/red matrix | closed |

## 7. Exact Implementation Boundary

Authorized in order:

```text
C10.1 test-only native observer and closed Lua userdata API
C10.2 native observer falsifiers RO01-RO15
C10.3 fixture absence/sentinel/prebuilt phase helpers
C10.4 one-load campaign context and fresh candidate constructor
C10.5 fixed 32-transaction campaign
C10.6 QN20/matrix/production-exclusion wiring
C10.7 focused, full, sanitizer, analyzer and diff verification
```

Expected implementation writes are limited to:

```text
native/tests/* QN20 observer/falsifier sources
native/tests/proc17_fixture_guard.c additive test operations
native/Makefile test targets and generated-artifact cleanup
tests/support/* campaign/root support
tests/run_qa_repeated_residue_campaign.lua
tests/test_qa_repeated_residue_observer.lua
tests/test_qa_native_supervisor.lua QN20 promotion
tests/red_qa_hand.lua exact 44/40 frontier
```

Not authorized:

```text
production provider, launcher or supervisor semantic changes;
runtime/core/organs Packet QA authority;
public allocator-current telemetry;
candidate-visible residue selectors;
observer cleanup or repair authority;
changes to QN01-QN19 outcomes.
```

## 8. Decision

All current writer, reader, lifecycle, build and exclusion boundaries have an
implementation path after the amendments above. No unresolved authority or
observability conflict remains.

Decision:

```text
cross-crystall audit: satisfied
CRYSTALL consistent with TABLE: yes
C10/QN20 implementation: authorized
first authorized slice: C10.1 red-first test-only native observer
Packet/body QA authority: forbidden
```

This audit does not claim QN20 is green. It authorizes the experiment that can
make or falsify that claim.
