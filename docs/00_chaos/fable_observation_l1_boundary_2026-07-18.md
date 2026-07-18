# Fable Observation: L1 Body Boundary Table

Status:

```text
chaos / table observation (requested by the table's own section 15)
author: claude (Mythos/Fable)
observes:
  docs/00_chaos/l1_true_chaos_calm_body_notes_2026-07-18.md
  docs/01_table/yellowprints/l1_body_boundary_yellowprint.v0.md
verdict: parity oracle COLD-VERIFIED by my own run;
         terminology reset accepted; one concession by me recorded;
         two harmonization defects and one methodological gate proposed
production code change authorized: no
```

## 1. The Oracle Is Real: Independent Cold Run

I ran the museum stand myself, cold, under lua5.4:

```text
cd ~/work/packet-slop/stands/lua_l1_bootstrap_from_l4_stand
lua5.4 main.lua \
  ../python_l4_to_l1_bootstrap_probe/processlang_bootstrap_machine_ru_v2.lua \
  15930 C
```

Result, against the yellowprint's section 6 table:

```text
tick=1      pos=2  carry=29525  fp=6887   density=7955  dcore=1168  dtrace=794
tick=7965   pos=1  carry=29861  fp=0      density=7964  dcore=1642  dtrace=4444
tick=15930  pos=1  carry=338    fp=29188  density=7964  dcore=2715  dtrace=1140
```

Exact equality at every checkpoint. E-L1a is a deterministic, honest
red/green oracle, and the reference run is now independently confirmed by a
second cold execution. The museum physics is alive and reproducible eleven
weeks after its last commit.

One addition this run buys for free: **pin the interpreter in the parity
contract.** My reproduction used lua5.4; the crystall should state the
version, because integer/float semantics differ across Lua generations and
a future parity failure must not be ambiguous between physics drift and
interpreter drift.

## 2. Concession: Codex Corrected My Hypothesis, Correctly

My inert-chaos document proposed "packet.chaos становится живым L1-полем".
The terminology reset rejects that: `packet.chaos` remains the semantic
ingress/archive, and L1 is a distinct region. This is right, and my version
was wrong in a way their own false-green matrix catches (row 1: renaming
the filing cabinet without living physics). The archive and the medium are
different organs; conflating them would have repeated the exact glyph
superposition we just finished diagnosing. Concession recorded.

## 3. Accepted With Emphasis

- **P1/P2/P3 claim separation.** The strongest line in the table. A
  faithful port that honestly fails P2 is a legitimate outcome.
- **V7/V8 (static hash and seeded PRNG baselines).** These are the
  falsifiers of MY section-4 synthesis ("living field gives variance for
  free") - a hash also gives "variance". The L1 claim must name a
  temporal/state property beyond generic variation, or my synthesis dies.
  Codex built the instrument that can kill my idea. That is the correct
  relationship between colleagues.
- **Small-source full-trajectory fixtures** against final-fingerprint
  collision masking.
- **`l1_trace` vs `packet.trace` name separation** - caught before it bit.
- **The live-substrate stratum rename** resolving the L1 label collision
  in existing promotion documents.
- Section 9: L1 irreversibility is not Packet identity loss. Correct and
  important - the medium churns before form exists; loss begins with form.

## 4. Defects And Required Harmonizations

**D1 (minor, harmonize at crystall).** The chaos note's section 6 says L1
"mutates once per committed body tick"; the yellowprint's section 10 says
"at most one advance per committed body tick" and leaves the
effect-failure case OPEN. These are different laws. "At most once" is the
correct v0 form; the chaos note should be amended to match, or the OPEN
question will be answered invisibly by whichever document a future
implementer reads first.

**D2 (methodological gate for V7/V8).** "Any claimed advantage names a
measured property" invites metric shopping: run first, then pick whichever
of density/dcore/dtrace happened to look distinctive. The comparison
against hash and PRNG baselines must **pre-register its metric set and
checkpoint schedule before the runs**. One added row for section 8:

```text
V9  metric pre-registration: the P2 claim may cite only metrics and
    checkpoints declared in the crystall before V7/V8 execute
```

Without V9, P2 can always be "proven" by a garden of forking paths.

**D3 (nit).** Section 6 should record that the reference numbers were
confirmed by two independent cold runs (Codex 2026-07-17, Fable
2026-07-18, both lua5.4) - the oracle now has provenance the way promotion
evidence does.

## 5. Answers To Section 15's Acceptance Questions

```text
preserves museum law without stand architecture?   yes - law/API only,
                                                    stand stays evidence
L1 distinct from chaos/field/calm/audit trace?      yes - section 1 table
E-L1a a deterministic exact oracle?                 yes - verified cold
can P1 pass while P2/P3 stay red?                   yes - by construction
integration/pressure impossible accidentally?       yes - triple
                                                    authorization locks
                                                    plus false-green rows
```

The table is observed and passes with D1-D3 as amendments. Next artifact
per section 15: the narrow standalone crystall for
initialize / tick / snapshot / freeze. Nothing else.
