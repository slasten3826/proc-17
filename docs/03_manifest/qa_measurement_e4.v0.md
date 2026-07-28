# QA Measurement E4 Manifest

production-routing note 2026-07-28: section 3 is historical after E5; the E4
measurement laws remain active under `qa_run_v1_authority_e5.v0.md`.

manifest status: implemented, production-linked, unrouted measurement slice
date: 2026-07-28
authority: namespace-controller measurements plus top-level finality join
execution protocol: production RUN v0
body QA authority: absent

## 1. Implemented Surface

`E4` completes the C5 measurement machinery required by the already linked E3
phase state:

```text
stdout/stderr       independent bounded drains, prefix SHA-256 and exact EOF
private status      READY/RELEASE/zero-or-one HEAP_DENIED seqpacket protocol
runtime allocator   shared single-writer reservation/peak/denial telemetry
candidate clocks    absolute monotonic wall timer, RLIMIT_CPU and exact wait4
cause arbitration   one complete poll epoch, no descriptor-order tie-break
scratch             pinned baseline plus bounded no-follow final inventory
controller report   fixed private 572-byte local evidence record
finality join       top-level adds only namespace-clean after controller reap
```

All modules are compiled into the exact static production supervisor:

```text
native/proc17_qa_stream.c
native/proc17_qa_status.c
native/proc17_qa_allocator.c
native/proc17_qa_controller.c
native/proc17_qa_scratch.c
native/proc17_qa_report.c
```

The existing bounded Lua allocator was moved to the shared allocator module;
there are not two heap calculators.

## 2. Exact Physics

### Streams

Each stream counts all observed bytes, hashes at most its declared prefix and
drains bounded slices until EOF. Crossing is recorded once. stdout bytes cannot
enter stderr state and raw bytes never enter the native adapter.

### Allocator and private status

The candidate blocks before loading candidate bytes until exact private
RELEASE. The allocator page survives abrupt candidate death and distinguishes
policy denial from host allocation failure. Reservation and peak are published
before host allocation, so an intervening kill cannot erase authorized mass.
Only the namespace controller writes first cause.

### Clocks and arbitration

The wall timer is armed before RELEASE. Candidate resource metrics come from
`wait4(candidate_pid)`, never from the namespace controller. Every successful
`poll` return is one epoch: one distinct cause may win, two different causes
are ambiguity, and later cleanup cannot rewrite a chosen cause.

### Scratch

The controller pins the exact empty `home`/`tmp` baseline before release. After
candidate reap it walks only the pinned scratch root without following links or
crossing mounts. Candidate entries, logical regular bytes and final filesystem
capacity are bounded. Depth is fixed at 64 by the policy digest. This final
observation cannot claim `scratch_limit` because no trusted causal write-denial
hook exists in v0.

### Two-stage finality

The private controller report contains the first seven public finality facts,
status EOF, stable allocator evidence, all measurements and the immutable
cause. It is bound to the exact identity join and private process token. The
top-level supervisor can assemble RESULT only after successful controller reap
and namespace cleanup; it writes the eighth fact and does not re-derive cause.

Missing EOF, unstable or contradictory allocator state, baseline corruption,
malformed private bytes, abnormal controller exit, token/identity mismatch or
one missing finality fact suppresses candidate RESULT. An in-budget host
allocator failure follows this infrastructure path rather than being blamed on
candidate code.

## 3. Production Boundary

E4 is production-linked but deliberately unrouted. The live launcher still
sends one `RUN v0` request and the supervisor's current RUN branch still uses
the historical execution path. No public STARTED/RESULT v1 sequence, process
token, fd, raw output, allocator page or fault selector reaches Lua.

The supervisor and policy changes rotate their build/policy digests. Future
feature names are not declared exercised merely because their symbols are
linked.

## 4. Runtime Evidence

```text
make -C native qa-stream-test              green
make -C native qa-allocator-test           green
make -C native qa-controller-test          green
make -C native qa-scratch-test             green
make -C native qa-report-test              green
ASan/UBSan E4 focused runs                 green (leak scan disabled under ptrace)
GCC -fanalyzer E4 focused runs             green
lua tests/test_qa_native_supervisor.lua    16 green / 0 red / 4 skip
lua tests/red_qa_hand.lua                  expected exit 1
QA control matrix                          40 green / 44 red / 0 skip
lua tests/run.lua                          all tests ok
lua tests/smoke_mortality_battery.lua     8/8
```

The QA color delta remains exactly zero.

## 5. Non-Claims

E4 does not claim production RUN v1 routing, launcher multi-frame handling,
hostile candidate completion, trusted-fault classification, cleanup residue
freedom, source disposition, QA evidence/verdict writers or software
acceptance. It also does not claim causal scratch exhaustion.

## 6. Next Authorized Slice

`E5` is the explicit authority switch for the fault-free RUN v1 path. It must
replace, not silently coexist with, RUN v0 routing; validate STARTED then one
terminal frame plus supervisor reap/EOF; expose no private coordinate; and keep
all candidate/infrastructure distinctions proved by E4. QN17-QN20 remain later
campaigns and must not be folded into that first switch.
