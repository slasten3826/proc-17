# proc-17

proc-17 is the first executable body of procesis.

It is not a chatbot and the LLM is not its controller. A replaceable substrate
supplies semantic current; the body owns packet state, routing, runtime truth,
cost, death, inheritance, and manifestation.

```text
procesis   law / soul / source orientation
proc-17    executable body
packet     one mortal generation of a task
lineage    task ancestry across terminal packet lives
LLM        replaceable semantic current inside OBSERVE
router     next movement derived from packet pressure
trace      packet life ledger
grave      inherited residue of individual deaths
compost    old graves dissolved into session patterns
```

## Current Runtime

The repository currently contains:

- a packet core with CHAOS, CALM, BOUNDARY, trace, budget, loss, and residue;
- a task-shaped potential/relation field with revision-based two-eye freshness;
- a continuous runtime camera with immutable per-tick frames and explicit ☱ reconciliation;
- all ten ProcessLang operators behind one rights-declaring registry;
- CONNECT and DISSOLVE organs available for direct execution and shadow routing;
- full-tree route authority with legacy retained only as read-only instrumentation;
- fake and OpenAI-compatible substrates, including a DeepSeek adapter;
- internal mortality through budget exhaustion and identity loss;
- grave inheritance, warning karma, bequests, and session compost;
- truth freshness, spell evidence, and a LOGIC stamp for lower-triangle closure;
- a 22-edge evidence ledger that separates candidate, committed, and executed,
  with observer- and authority-typed promotion channels;
- exact plan completion through ☱ and Packet-local `plan.result.v0` delivery
  through terminal △ under the explicit qualified treatment;
- a bounded in-memory lineage runner with cumulative economics, immutable
  corpses, deterministic recovery carriers, and NETWORK@▽ rebirth;
- one capability-safe create-only repository hand with independent native
  read-back and exact one-artifact delivery;
- a JSON machine CLI for one explicit plan or build Packet per invocation;
- 141 Lua test suites plus mortality, expected-red QA, and live-substrate smoke
  programs.

The fixed single-pass runner remains as a smoke rail. The tension runner is the
active experiment: movement is chosen from packet pressure rather than a fixed
pipeline or an LLM-selected tool route.

## Current Boundary

proc-17 is a working process-physics engine with one narrow coding path, but it
is not yet a general coding agent.

- Build mode can create exactly one previously absent UTF-8 file inside one
  explicitly granted repository root. It cannot patch, overwrite, delete,
  rename, inspect arbitrary source trees, run project tests, or coordinate a
  multi-file transaction.
- The first runner-managed lineage is in memory only. Disk recovery, branching,
  provider-owned substrate sessions, and automatic resume are not implemented.
  Bequests and compost patterns still need general named readers beyond direct
  newborn grave attachment.
- The default legacy router cannot select CONNECT or DISSOLVE. Explicit tree
  authority has executed CONNECT; DISSOLVE still needs a live rigidity witness.
- The binary full-tree pressure policy is uncalibrated. Explicit
  `router_mode=tree` can now own a complete build life while legacy records
  read-only comparison evidence. Observer ablation is green; the promotion
  corpus is still incomplete and the default remains `shadow`.
- A rejected validation is delivered through △ as an explicit `blocked`
  output, terminal, death, and residue while preserving the substrate text.
  Retry and repair policy remains intentionally separate.
- The command sandbox must become capability-based before arbitrary hands are
  connected.
- The machine CLI is intentionally narrow. The Go TUI is not implemented.

## Machine CLI

The CLI uses DeepSeek by default and emits exactly one JSON object on stdout.
Plan mode requires Lua 5.4, `curl`, and `DEEPSEEK_API_KEY`. Build mode also
requires Linux, a C compiler, `pkg-config`, Lua 5.4 development headers, and the
native create-only provider. The QA supervisor builds its pinned Lua 5.4.8
static runtime from committed source; a system `liblua5.4.a` is not required.

```sh
make -C native provider-shell
```

Set `DEEPSEEK_API_KEY` before a real run.

```sh
export DEEPSEEK_API_KEY=...

# A fresh isolated session is created when --session is omitted.
lua proc17.lua plan "design a tiny Lua program"

# Build can create one new file below the granted repository root.
mkdir -p /tmp/proc17-demo/fresh-project
lua proc17.lua build "create hello.lua" \
  --project-base /tmp/proc17-demo \
  --repository fresh-project

# Resume only an explicitly named existing session.
lua proc17.lua plan "continue the design" --session SESSION_ID

lua proc17.lua help
```

Task input can also come from `--task-file FILE` or stdin. Useful limits are
`--max-steps`, `--max-calls`, `--max-tokens`, and `--max-loss`. Exit status `0`
means the Packet completed, `2` means input/configuration failure, `3` is an
honest non-complete Packet death, and `4` is a trusted runtime/setup failure.
`ok=true` is Packet completion, not a claim that the produced software is
universally correct or QA-accepted.

## Verification

Requires Lua 5.4.

The full QA battery additionally requires a Linux C toolchain, `make`, `tar`,
`sha256sum`, `ar`, and `ranlib`. It performs no dependency download.

```sh
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
lua tests/red_qa_hand.lua  # expected exit 1: 40 green / 44 intentionally red
```

Live DeepSeek smoke programs require the corresponding API configuration.

## Documentation

- [`docs/00_chaos`](docs/00_chaos) records discovery, pressure, experiments, and unresolved questions.
- [`docs/01_table/yellowprints`](docs/01_table/yellowprints) contains first structured forms.
- [`docs/02_crystall/blueprints`](docs/02_crystall/blueprints) contains executable contracts.
- [`docs/03_manifest/current_state.md`](docs/03_manifest/current_state.md) is the current implementation map.
- [`docs/03_manifest/lineage_in_memory_slice.v0.md`](docs/03_manifest/lineage_in_memory_slice.v0.md) records the first task ancestry across mortal Packet lives.
- [`docs/03_manifest/lineage_completion_continuation_separation.v0.md`](docs/03_manifest/lineage_completion_continuation_separation.v0.md) separates task truth from lineage affordability and recovery policy.
- [`docs/03_manifest/proc17_assembly_map.md`](docs/03_manifest/proc17_assembly_map.md) records the July 15 assembly pass.
- [`docs/00_chaos/full_project_audit_2026-07-15_notes.md`](docs/00_chaos/full_project_audit_2026-07-15_notes.md) is the full repository audit.
- [`docs/00_chaos/proc17_capability_handoff_2026-07-19.md`](docs/00_chaos/proc17_capability_handoff_2026-07-19.md) is the dated machine handoff: proven abilities, open boundaries, and the next product-bearing pressure.

The previous laboratory body remains available in Git history on the
`old-body-lab` branch.

## Shareable Release Candidate

The short public release surface is [release/v0.1.0](release/v0.1.0). This
repository remains the laboratory; the release directory defines the narrow
capability claim and the checks required before the `v0.1.0` tag is published.
