# Full Tree Rebuild Notes

Status:

```text
chaos
author: claude (Mythos/Fable), direction by machinist
from live design discussion after the GPT-5.6 audit, 2026-07-15
this is the audited technical debt, framed
```

## Machinist Direction

Stop looking at hands and F4 as the next milestone. The next
milestone is:

```text
give proc-17 the full 22-edge topology
```

The packet must walk the whole Tree by pressure, not follow a
hardcoded decision tree (~8-9 edges used today, half of them
reflexes like «после ☵ обязательно ☴»).

## Machinist's Three Thoughts (recorded)

### 1. Blink (eye-tick) as pressure release — DISPUTED, held

The mandatory eye-tick may become not a law and not a free choice,
but a **discharge mechanism**: blinking reduces pressure. Possibly
even removes loss — machinist marks this part «очень спорная».

Claude caveat, for the record: removing loss would violate
irreversibility (A1/loss ledger — потеря необратима по канону;
у диссипативной математики нет отрицательных потерь). The legal
version: blink discharges **tension** (unresolved_delta,
chaos_pressure), never the loss ledger. Loss stays paid; pressure
can be breathed out.

Scriptural support exists: in packet_zig.raw the two OBSERVE
opcodes are literally NOP_A/NOP_B — «два голоса тишины», ticks
where nothing mutates. Observation as standing silence = pressure
release is already in the raw.

### 2. ☴ as the only LLM membrane; Z-model insertion

In the target architecture OBSERVE is nearly the only operator
touching the LLM. Everything else is packet-native.

The mathematical packet model (Z[K,D], E_edges, E_momentum,
loss_ledger, module rights) can be inserted and «неплохо ляжет» —
BUT it was designed on the OLD topology where OBSERVE was the
center of everything (Tiferet, 8 paths, OBSERVE-as-scheduler).
The current canon is two-centered: ☴ and ☱, both degree 6.

Adaptation required before insertion:

```text
old: OBSERVE measures everything and sets next_module
new: two eyes — ☴ reads the chaos side, ☱ reads the calm side;
     the router (will as function of pressure) decides
```

### 3. ☰ and ☷ must be built — from scripture

They factually do not exist as organs. They must be compiled from
slop.raw.txt, not invented:

```text
☰ CONNECT  <- хокма / EmergentConnection:
   recognition, interpenetration, boundary fluidity, synergy.
   Organ job: form relations — work units ↔ files ↔ evidence,
   and READ BEQUESTS: bind chaos.unresolved_pressure to current
   work (closes the oldest open letter)

☷ DISSOLVE <- бина / DogmaDissolution:
   rigidity detection, dissolution potential, fluid truth.
   Organ job: detect rigid/stale forms and dissolve them back
   to flow — cold evidence (freshness executioner), dead work
   units, failed calm structures (makes truth rent CAUSAL,
   closes audit finding 6)
```

## Claude Synthesis: the router v2 blueprint already exists

The ancestral form of the pressure router is sitting in procesis
raw: `packet_zig.raw/layer2_boundary.zig` + `layer4_tension.zig`:

```text
ObserveA reads CHAOS  (fingerprint, stagnation, halted)
ObserveB reads CALM   (layers, program size, PU remaining)
Choose decides by economics (panic/encode/stagnation thresholds)
Tension measures chaos_pressure vs calm_rigidity vs boundary_load
  -> hold / reinforce / release_to_chaos / manifest_now
```

That IS «routing = topology + affordability + observation» in
executable ancestral form. Router v2 = the Lua reincarnation of
the Zig Boundary+Tension pair, generalized over all adjacent
edges of the current node. proc-17 already grew «two eyes»
independently (runtime_eye) — convergence, not coincidence.

## Why This Is One Job, Not Three

```text
full topology needs all nodes alive        -> ☰/☷ organs (3)
free walking needs honest position         -> F4 fix (prerequisite)
pressure choice needs pressures to be real -> Z-body insertion (2)
pressure sources need reading discipline   -> two eyes (2)
blink becomes a pressure-tuning question   -> (1) inside router v2,
   not a binary law question anymore
```

The audit called the pieces; the machinist called the shape.
This is audited technical debt.

## Held Questions (frame not confirmed yet)

```text
1. blink: tension-only discharge (Claude) vs loss-heal (disputed)
2. Z-model insertion depth for v2: full Z[K,D] latent body,
   or pressure-fields first, latent body later?
3. eye-tick law: dies entirely, or survives as high default
   pressure that mortality pressure can override?
4. phase order within the rebuild
```
