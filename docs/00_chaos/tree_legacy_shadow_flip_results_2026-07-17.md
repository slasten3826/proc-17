# Tree Live / Legacy Shadow Results - 2026-07-17

Status:

```text
chaos / runtime evidence
transition step: 3 of 5
Gate B: confirmed
default authority: legacy through shadow mode
opt-in authority: tree with legacy read-only observer
```

## What Changed

Inside explicit `router_mode=tree`, the order is now:

```text
derive tree decision
derive legacy prediction against the same post-tick Packet
record legacy prediction as append-only observation
commit only the tree decision
```

The observer is enabled by default only inside explicit tree lives and may be
disabled for ablation with `legacy_shadow=false`. Default proc-17 lives still
use `router_mode=shadow`, where legacy moves and tree observes.

## Confirmed Life

```text
walk:             ▽ ☴ ☰ ☵ ☲ ☶ ☱ △
tree derivations: 7
legacy records:   7
ticks:            7
steps:            7
substrate calls:  1
identity loss:    0.500
terminal:         manifested / complete
```

Observer comparison:

```text
▽  tree=☴  legacy=☴    agreement    runner_entry
☴  tree=☰  legacy=☵    divergence   missing_calm
☰  tree=☵  legacy=nil  unavailable  unsupported_route_source
☵  tree=☲  legacy=☴    divergence   mandatory_eye_tick
☲  tree=☶  legacy=☱    divergence   mandatory_eye_tick
☶  tree=☱  legacy=☱    agreement    mandatory_eye_tick
☱  tree=△  legacy=☲    divergence   remaining_work
```

The CONNECT absence is typed instrumentation absence. It neither stalls nor
kills the Packet and does not trigger fallback.

## Ablation

Enabling and disabling the legacy observer produced identical:

```text
entry and internal route sequence
ticks and executed operators
budget spent and remaining
substrate calls
identity loss
Packet revisions
validations and evidence
manifest type, stop reason, death cause and terminal kind
```

The only trace-length delta was seven legacy observation events. Committed
route events contain no nested observer payload.

## Evidence Ledger

Live tree derivations now feed edge statistics directly:

```text
candidate audit -> candidate/exclusion counts
selected target -> selection count
committed route -> authority + derivation refs
executed target -> arrival count
typed effect failure -> failure count + failure ref
```

Legacy observations feed separate observer counters only. This preserves the
difference between a route the body considered, a route it committed, and a
historical policy prediction that had no authority.

## Boundary

Gate B proves instrumentation isolation, not routing quality. Five divergences
are useful corpus data, not tree failures by themselves. The default remains
`shadow`. Step 4 must build the promotion corpus, including honest rejected
validation and real DISSOLVE pressure, before any default flip is considered.
