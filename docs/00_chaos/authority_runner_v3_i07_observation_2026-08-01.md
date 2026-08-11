# Authority Runner v3 I07 Observation

```text
layer: CHAOS
date: 2026-08-01
status: runtime_observation
source blueprint:
  docs/02_crystall/blueprints/authority_epoch_edge_credit.v0.md
slice: I07 opt-in runner integration
source baseline commit: 1d3433a
implementation commit: pending
default authority instrument: edge_stats_v2
canonical promotion decision: forbidden
```

## 0. Result

The detached v3 authority instrument now runs inside ordinary
`tension_runner` lives behind an explicit opt-in:

```text
omitted authority_instrument -> edge_stats_v2
authority_instrument=v3      -> authority epoch + edge credit + edge-stats.v3
authority_instrument=off     -> test override required; no edge ledger
```

Exactly one instrument writes during one life. The runner closes every v3
selection through the real Packet route and one terminal route phase:

```text
selection -> committed -> executed
selection -> committed -> failed
selection -> committed -> pending_at_host_ceiling
```

No route phase is inferred after the life. A successful destination tick is
the only writer of arrival credit. Typed effect failure and host ceiling do
not create executed or credited evidence.

## 1. Grown Runtime Evidence

The I07 integration battery grows the required cases through the ordinary
runner rather than constructing route records by hand:

```text
EC02 ineligible fixture route:
  physically executed = 1
  ineligible executed = 1
  eligible executed = 0

EC05 host ceiling:
  committed = 1
  pending = 1
  executed = 0
  Packet remains alive

EC06 typed substrate failure:
  failed = 1
  executed = 0
  credit decision = absent
  Packet death = effect_failure

EC11 harness then Tree:
  authority_taint = 1
  following Tree selection reads authority_tainted
  taint remains monotonic
```

Fresh `legacy`, `shadow` and `tree` v3 lives all resolve an authority epoch.
The ordinary legacy and shadow probes close with a valid ledger and zero
instrument errors. A qualified Tree entry produces real eligible and credited
evidence.

## 2. Boundary Falsifications Found by the First Live Run

### 2.1 Runner-only options leaked into the body option surface

The first implementation normalized omitted measurement options directly into
the shared runner `options` table. That table is also passed to organs and the
router. The existing LP10 observer-neutral control detected Packet trace and
corpse differences.

Treatment:

```text
runner-only measurement keys stay runner-local
body_options removes them before every organ/router boundary
omitted v2 receives the previous body option surface literally
```

LP10 returned green. This is stronger than assuming unknown options are inert:
the measurement configuration is now structurally unable to enter body policy.

### 2.2 The blueprint named a Packet field that does not exist

The blueprint pseudocode hashed `instance.prompt`. Packet truth stores the raw
task in:

```text
instance.chaos.raw_prompt
```

The first v3 life failed loudly before FLOW rather than inventing a prompt.
The life identity now hashes the canonical CHAOS carrier.

### 2.3 Valid epoch diagnostics were accidentally passed as epoch error

Lua's `condition and nil or value` idiom cannot select `nil`. The initial code
therefore passed diagnostics beside a valid epoch and hit
`epoch_record_error_conflict`.

Treatment: explicit branch assignment. This remains a harness error class;
Packet physics never receives a beautiful death for a broken Lua world.

### 2.4 Packet trace values may contain aliases

Committed Tree evidence can contain the same candidate through both
`selected_candidate` and `candidates`. Packet trace preserves that relation;
the immutable evidence ledger rejects aliases and cycles.

The capture boundary now creates an alias-free detached value snapshot. It
does not alter Packet trace or collapse fields. A cycle or non-plain value
still invalidates instrumentation instead of entering the evidence corpus.

### 2.5 Tree audits a direction outside the authority surface

At `☴`, the router audits `☴->▽` and excludes it because a living Packet cannot
return to FLOW. The 38-direction authority surface intentionally contains only
`▽->☴`, not its reverse.

The v3 derivation projection now counts only directions admitted by the
authority surface while retaining the complete original derivation event in
Packet trace. An excluded birth reversal therefore remains body audit evidence
without becoming a fictional physical edge.

### 2.6 Eligibility had a named reader but an incomplete writer

`edge_credit` verifies one exact chain:

```text
Tree decision
selected candidate
route_derivation payload
committed route
```

The live router carried eligibility in the first, second and fourth records,
but `route_derivation` omitted `selected_candidate`. Every real Tree selection
was consequently unclassified even though synthetic fixtures were green.

The router now records the already selected candidate in the derivation event.
No route, pressure, readiness or choice changes; the existing fact merely gains
the writer required by its verifier.

## 3. Masslessness Evidence

Matched lives prove:

```text
default v2 vs previous runner controls -> unchanged legacy behavior
valid v3 epoch vs invalid v3 epoch     -> same observer-neutral body projection
v3 vs v2 result surface               -> no concurrent writer
off                                    -> no v2, v3 or credit ledger
expected epoch identity lie            -> loud harness failure
```

An invalid epoch creates an invalid measurement ledger and unclassified credit
records while the same Packet route, budget, loss, revisions and terminal state
remain unchanged. An explicit expected-id mismatch is not recoverable
instrument absence; it is a failed harness assertion.

## 4. Verification

```text
new runner-v3 integration suite: green
legacy/shadow/tree v3 probes: green
eligibility carry regression: green
observer-neutral life projection: green
Tree authority and instrumentation gates: green
full suite: 123/123 green
mortality battery: 8/8 green
luac: green
git diff --check: green
```

The full suite includes the ordinary and hostile native QA/repository
campaigns. No QA, repository, budget, loss, route or finality authority was
changed by I07.

## 5. Current Boundary

I07 is complete. The instrument is live but not canonical:

```text
default remains edge_stats_v2
v3 requires explicit opt-in
I08 full masslessness campaign remains
I09 canonical cutover remains forbidden
I10 current evidence manifest remains
```

This is the first point where the DISSOLVE hypotheses can be tested with the
instrument on ordinary runner-grown lives. A real route through `☷`, its loss
record and its P10 control can now be observed without changing the evidence
contract after seeing the result.
