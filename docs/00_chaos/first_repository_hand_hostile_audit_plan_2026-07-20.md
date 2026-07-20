# First Repository Hand: Hostile Audit Plan

status: CHAOS test plan for roadmap step 7.8
date: 2026-07-20
previous: `first_repository_hand_effect_progress_results_2026-07-20.md`
authority: attack hypotheses until reproduced by tests

## 1. Purpose

Step 7.8 grants no new route, operation, path or provider authority. It attacks
the deliberately callable hand built in 7.7:

```text
action -> private lease -> create -> receipt -> read-back -> verification
       -> LOGIC validation -> RUNTIME completion -> progress
```

The audit asks whether individually strict layers can be composed into a false
or wider result. It treats repository data as hostile, provider code as trusted
but fallible, and malformed trusted-runtime records as loud harness failures.

The known autonomous route suite remains red by design. Route promotion is
step 7.9 and cannot be used to make this audit green.

## 2. Baseline

Before hostile changes:

```text
lua tests/run.lua                       green
tests/test_repository_effect.lua       14/14 green
tests/test_repository_progress.lua      9/9 green
repository staged suites               11 green / route only red
```

The first attempted native baseline command used a nonexistent convenience
target (`make -C native test-full`). That is a harness command error, not body
evidence. Step 7.8 must use the actual `native/Makefile` targets and record each
result separately.

## 3. Audit Laws

### 3.1 No authority by alias

A lease belongs to one private registry, one grant revision, one action and one
effect generation. Copying, replaying, crossing registries, changing the
request or exhausting the generation must not produce another provider call.
A denied attempt does not refund consumed authority.

### 3.2 Trusted corruption stays loud

Provider exceptions, malformed success/error records, impossible economics,
metatables and cyclic diagnostic structures are runtime corruption. They must
not become an honest Packet death, grave or retryable world event.

### 3.3 Public failure is a projection

A well-formed world failure may become `effect_failure`, but its public form is
narrower than the provider record. It may expose a bounded code, stage-derived
message, retryability, economics and explicitly safe residue facts. It may not
expose raw bytes, absolute host paths, opaque handles, arbitrary nested values
or caller-owned aliases.

### 3.4 Completion must survive rereading

`work_completion` is not true merely because an event has that type. Every
reader that converts it into `done` must revalidate its identity, current work
version, exact evidence order, accepted verification/validation and absence of
later conflicts. A stale or forged record remains inert.

### 3.5 Runtime records are closed values

Repository event writers reject unknown keys, metatables, sparse/cyclic refs
and wrong actors before append. Stored trace owns a detached immutable copy.
Input mutation after append cannot alter history.

### 3.6 One life leaves no resource debt

Every native create/read path is bounded. Repeated successful and failed lives
must return descriptors to baseline after explicit close or registry lifetime
end. Fault injection remains test-only and production loading remains exact.

## 4. Attack Matrix

| ID | Attack | Required result | Named reader/guard |
|---|---|---|---|
| H-A01 | lease from registry A used with B | loud denial; zero call in B | private lease registry identity |
| H-A02 | create/read lease replay | loud denial; provider count unchanged | one-use lease state |
| H-A03 | forged action passed to `begin_effect` | denial before slot consumption | private grant/action match |
| H-A04 | generation dispatch limit exhausted | typed denial; no provider call | private generation counter |
| H-A05 | revoke/quarantine after action or lease | no new external call | grant state plus closed handle |
| H-P01 | provider method throws | loud harness failure; Packet remains live | protected provider boundary |
| H-P02 | malformed success/error/metatable/cycle | loud rejection before trace/death | strict provider validator |
| H-P03 | impossible/NaN/negative economics | loud rejection | cost validator |
| H-P04 | create/read reports foreign root | loud identity contradiction | lease root witness |
| H-P05 | ambiguous error carries hostile residue | bounded public projection only | failure projector |
| H-T01 | hostile returned bytes/path/handle | absent from events, failure and outcome | closed public schemas |
| H-T02 | caller mutates returned records | stored trace unchanged | append deep copy |
| H-T03 | metatable/cyclic/sparse event payload | reject before append | body event schema |
| H-C01 | evidence refs missing/reordered/cross-work | no completion | exact chain reader |
| H-C02 | candidate goes stale before record | no completion | record-time revalidation |
| H-C03 | completion event is forged or later invalidated | `is_complete=false`, progress pending | completion reader |
| H-C04 | current work version changes after completion | old event no longer completes it | current version reader |
| H-R01 | repeated real effects | exact files only; descriptors reclaimed | provider close/GC boundary |
| H-R02 | every native fault stage | no partial final; bounded residue/cost | native fault corpus |
| H-R03 | loader/path poisoning after integration | trusted module still selected | exact loader root |

## 5. Test Shape

### 5.1 Lua composition battery

Create `tests/test_repository_hostile_audit.lua`. Prefer grown actions and real
trace chains over synthetic records. The suite attacks capability, provider,
trace and completion boundaries in one place so cross-layer failures remain
visible.

The suite is added to `tests/red_repository_hands.lua`, not to the ordinary full
suite yet. Step 7.9 owns promotion into the default regression corpus.

### 5.2 Real-provider repetition

Extend `tests/test_repository_effect_linux.lua` with repeated identity-owned
fixtures or grants. Assert exact file predicates and descriptor reclamation
without reading or deleting outside the fixture root. No semantic value may
enter a shell command.

### 5.3 Native corpus

Run the existing full create/read fault harness, strict warning build, GCC
analyzer and ASan/UBSan battery. Add native code only if a named 7.8 threat is
not already represented. Duplicate tests do not create stronger evidence.

## 6. Expected Defect Policy

When a hostile test fails:

1. preserve the attack and its expected result;
2. identify the first layer that accepted the invalid state;
3. patch that boundary only;
4. add no route, retry, fallback or new operation;
5. rerun the focused attack before the full corpus;
6. record the defect and treatment in the results document.

If an attack premise is invalid, mark it as rejected in this document and keep
the test as a control where useful. Do not silently weaken the assertion.

## 7. Acceptance Gate

Step 7.8 is complete only when:

```text
all H-* attacks have green evidence or an explicit bounded non-claim
no malformed trusted value becomes honest Packet mortality
no raw content, host path or handle escapes through a public result
completion remains exact when reread after later state changes
real and injected native paths return resources to their claimed boundary
the old full suite remains green
the sole staged red remains repository route authority
no router, pressure reader or autonomous hand path was added
```

Only then may step 7.9 decide which demonstrated suites become default body
authority and regression evidence.
