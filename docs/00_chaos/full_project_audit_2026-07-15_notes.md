# Full Project Audit - 2026-07-15

Status: chaos / repository-wide observation

Author: Codex

Scope:

- Git history and authorship layers;
- chaos, table, crystall, and manifest documentation;
- executable Lua body and its tests;
- local unit, mortality, syntax, and targeted reproduction runs;
- the transition from the first laboratory body to the current packet-first body;
- the later Fable/Claude changes and the direction they introduced or reinforced.

This document is an observation layer, not a frozen specification. It preserves
what the repository currently is, where the implementation disagrees with its
claims, and what direction is visible through those disagreements.

## Audit Result In One Sentence

proc-17 has a working process-physics engine with pressure routing, epistemic
typing, mortality, lineage, and memory decay; it does not yet have the hands and
closed evidence loop required to be a complete coding agent.

The hardest conceptual architecture is already present. The project now stands
at the transition from ontology to work.

## Authorship And Development Layers

The repository is not the product of one uninterrupted implementation pass.
The history has five visible layers.

### 1. First laboratory body

Commits `cb67e59..c9f9141`, June 28-30.

The user and Codex built the first usable laboratory: CLI routes, sandbox ideas,
operator organs, plan/build behavior, hints, cognitive batteries, and the ATM
and tic-tac-toe coding tests. This layer proved that procesis could shape model
behavior and produce useful artifacts, but accumulated a fixed-route body around
the experiments.

### 2. Packet-first clean-room rebuild

Commits `eaaf66d..0c4f3ac`, July 2-12.

The user and Codex started again from the packet. This produced the current core,
the two eyes, pressure routing, tension runner, packet-native ENCODE and CHOOSE,
trace, budget/loss separation, and early memory. This is the architectural root
of the current repository.

### 3. Mortality, grave, and compost

Commits `7673b19..333a749`, July 13.

Fable supplied external review pressure and integration experiments. The user
and Codex implemented internal mortality, `physis`, grave classification,
warning karma, the generation experiment, session-scoped graves, and compost.
Fable was a strong temporary observer, not the project owner or permanent design
channel.

### 4. Death finality transition

Commit `d0b67c4` is a mixed Codex and Claude/Fable layer. It closes important
posthumous packet mutations and preserves corpse trace behavior, but does not yet
make every packet-related module respect finality.

### 5. Direct Fable/Claude implementation layer

Commits `5761df2..c413b8a` add truth rent, the assembly map, a live coding battery,
and the LOGIC stamp. These changes strengthen the existing direction: facts must
pay to remain true, and the lower triangle must not revisit unchanged evidence
forever.

Fable did not replace the original design. It stress-tested it, found real
defects, and sometimes closed laws more readily than it closed worker behavior.

## Reconstructed Intent

The current project can be summarized as:

```text
procesis = law / soul / source orientation
proc-17 = executable body
packet = mortal task life
LLM = replaceable semantic current inside ☴
router = will as a function of packet pressure
tools = runtime contact with the world
trace = packet life ledger
grave = inherited individual death residue
compost = death of individual memory into bodily pattern
```

The central hypothesis is pressure-driven routing from packet state.

The LLM does not choose the route. The developer does not prescribe one full
route. The body reads the packet and selects the next permitted operator. Model
output can change packet pressure, but remains a semantic proposal until runtime
contact confirms it.

The coding agent is the first concrete and testable manifestation of this body,
not the full meaning of procesis. Human-language cognition is not the primary
target of ENCODE. The intended encoder is code-first and packet-native: it forms
work, dependencies, evidence obligations, and visible loss.

The later body is also not intended to have one rigid universal schema. In the
longer design, ▽, ☰, and ☷ form the task-specific skeleton from which a packet
body emerges. That layer is deliberately postponed until the lower mechanics
are reliable.

Plan/build modes and the nested glyph levels remain important:

```text
plan  ⋯ / ⊞ / ◈    form and test structure without changing reality
build ◈ / ▲        act, validate, repeat, and manifest
```

A machine-oriented CLI and human-oriented TUI are planned as separate surfaces.
Neither should own the body physics.

## What Is Already Solid

The following are implemented and supported by tests or live reproductions:

- packet areas, lifecycle, trace, truth statuses, budget, loss, and residue;
- topology validation and mandatory eye ticks;
- a pressure router and multi-tick tension runner;
- ENCODE structures with source references and explicit loss;
- CHOOSE with selected and killed alternatives;
- internal death from budget exhaustion and identity loss;
- grave warnings, bequests, inherited karma, and a control-line generation test;
- session-scoped graves and compost of old graves into aggregate patterns;
- truth freshness observation and a LOGIC stamp;
- fake and OpenAI-compatible substrate contracts;
- unit and mortality batteries.

Audit verification:

```text
lua tests/run.lua                      30 suites passed
lua tests/smoke_mortality_battery.lua  8/8 cases passed
luac -p over all Lua files             passed
```

The grave experiment is the strongest behavioral result currently in the
repository: a descendant with inherited warning avoids a repeated no-progress
loop, while an orphan control line repeats the same budget death.

## Findings

### 1. The body has no hands

`organs/choose.lua` records a selection. `runtime/body.lua` computes progress by
reading work-unit status. No integrated component executes the selected work and
changes its state to `done` through runtime evidence.

The intended loop therefore stops between choice and reality:

```text
☵ form work -> ☳ select work -> [missing hands] -> ☶ validate changed reality
```

### 2. The 5/5 coding battery is useful but not body end-to-end

proc-17 manifests five useful code artifacts. The external battery harness then
extracts the code, writes files, and executes validation. The evidence is real,
but the body did not perform those mutations itself.

The precise claim is: proc-17 can route a live substrate to deliver code that an
external harness validates 5/5. It is not yet an autonomous repository worker.

### 3. The LOGIC stamp closes a loop without proving progress

The stamp prevents repeated validation of unchanged evidence. That fixes a real
lower-triangle loop. When no new evidence appears, however, the current route can
manifest because the court was already visited, not because selected work was
performed.

This is a law-closure mechanism, not a replacement for hands.

### 4. Packet event traces can be topologically false

`runtime/tension_runner.lua` advances a local `current` operator but does not
update `instance.operator`. Core packet events therefore continue to claim that
they originated from ▽.

Live reproduction:

```text
packet.operator=▽
event_trace=▽☴☵☴☳☴☱☶☱△▽
valid=false
bad=△▽ index=10
```

The route walk is useful, but the packet's own event ledger is not yet the
canonical route trace it appears to be.

### 5. Death finality is incomplete

Core packet mutations are guarded, and corpse trace writes were deliberately
handled. Other modules still mutate state after death. A dead packet can be
charged budget, receive additional loss, or be changed through foundation,
memory, and grave helpers.

Live reproduction included:

```text
dead=dead
budget_mutated=true
loss=0.2
```

Finality currently depends partly on runner discipline rather than entirely on
packet physics.

### 6. Truth rent is observed but does not govern movement

`runtime/freshness.lua` and foundation snapshots can mark evidence stale. The
router still reads the raw evidence array and counts stale records as evidence.

A live stale-evidence reproduction still routed to `☲ remaining_work` at tick
100. Freshness is therefore visible but not yet causal in routing or validation.

### 7. The sandbox boundary must be rebuilt before hands

`logic/spells.lua` can call `io.popen` with configured command arguments, while
`core/sandbox.lua` currently denies every public shell command. This is two
different security models living side by side.

Filesystem permission checks are lexical. Once write tools are connected, a
symlink can make a lexically safe path resolve outside the intended root.

Hands should receive explicit capabilities, not generic shell access hidden
behind a string policy.

### 8. Memory exists as libraries, not one integrated lifecycle

Session memory, packet memory, grave, and compost can write records. Their readers
are incomplete:

- bequests enter `chaos.unresolved_pressure`, but ENCODE ignores that pressure;
- compost patterns are stored, but neither router nor foundation consumes them;
- runner birth does not own one complete session attach/read/bury/compost flow.

The repeated design lesson is: every written record must have a named reader and
a defined read moment.

### 9. The entry documentation was stale

Before this audit, the root README still described a clean-room rebuild and said
the old body existed as a local donor tree. `current_state.md` stopped near the
first tension-runner implementation and described the router as standalone.

This made a cold reader reconstruct the live architecture from Git history and
dozens of chaos documents. The README and current-state manifest were rewritten
as part of this audit. The laboratory body is now described correctly as the
`old-body-lab` Git branch.

## Additional Architectural Gaps

- ☰ CONNECT and ☷ DISSOLVE have no live organs.
- Pressure routing is real but currently uses simple explicit predicates; it is
  not yet the richer density-driven movement anticipated by the ontology.
- Plan mode often loops until budget death or inherited warning because work has
  no execution path to completion.
- `runtime/pressure_snapshot.lua`, `runtime/trace_store.lua`,
  `runtime/packet_memory.lua`, `runtime/session_memory.lua`, `tools/fs.lua`,
  `logic/repo_selection.lua`, and `logic/trace_validator.lua` are standalone or
  only partially integrated into the main runner.
- Constants and thresholds are mostly designed values, not measured substrate
  profiles.

## Assessment Of The Fable Layer

Fable's strongest contribution was not prose. It repeatedly used cold runs and
integration experiments to find mismatches that unit fixtures hid:

- budget and loss were recorded but initially not lethal;
- real loop deaths landed on ☱ while the synthetic karma fixture expected ☲;
- packet death was written but not enforced as final;
- truth needed rent rather than permanent confirmation;
- the live lower triangle needed a closure stamp.

The caution is equally specific. The later work occasionally treats closure of
a runtime law as completion of worker behavior. The LOGIC stamp is correct, but
it does not perform selected work. The 5/5 coding battery is valuable, but its
external harness is still supplying the hands.

Fable therefore strengthened the original direction rather than redirecting it.
The project remains the work of the user, Codex, and proc-17's own experimental
pressure, with Fable as a high-value temporary observer and contributor.

## Recommended Direction

The next milestone should not be another broad organ or user interface. It should
be one honest, body-owned work cycle:

```text
☵ forms executable work
☳ selects work
hands mutate the sandbox
☶ obtains new runtime evidence
☱ sees progress
the selected work unit becomes done
☲ continues or stops
△ assembles a verified result
```

Before connecting hands, close four physical invariants:

1. make `packet.operator` and the event trace describe actual movement;
2. enforce death finality in every mutating module;
3. make freshness affect routing and validation decisions;
4. make the sandbox capability-based and resistant to path resolution escape.

Then integrate session birth, inheritance, burial, and compost around the runner.
Only after this loop is observable should the machine CLI and Go TUI become the
main effort.

## Final Observation

The repository is neither a finished product nor merely an executable metaphor.
It is a working process-physics engine whose central laws already produce
measurable behavior. The remaining gap is concrete: the body can perceive,
structure, choose, judge, repeat, die, inherit, and manifest, but it cannot yet
touch a repository and learn from that touch under its own authority.

That boundary is where proc-17 stops proving its ontology and starts doing work.
