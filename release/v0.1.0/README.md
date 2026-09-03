# proc-17 v0.1.0

This directory is the short public entry point for the first shareable
proc-17 kernel snapshot.

The repository root remains the laboratory. It contains the full research
archive, experimental operators, audits and future architecture. The release
surface is intentionally smaller: it describes the bounded body that can be
shared and reproduced without presenting laboratory hypotheses as product
capabilities.

## What This Release Is

proc-17 is a mortal process-physics kernel with one narrow machine interface.
An LLM supplies semantic proposals; the body owns packet state, routing,
runtime truth, cost, death, inheritance and manifestation.

The v0.1 release candidate can run one isolated Packet in either mode:

```text
plan  -> produce one bounded structured plan
build -> create exactly one previously absent UTF-8 file at repository root
```

The build hand is create-only and capability-bounded. It does not patch,
overwrite, delete, rename, inspect an arbitrary project tree, run project
tests, or perform a multi-file transaction.

## Run

From the repository root:

```sh
lua proc17.lua help
lua proc17.lua plan "design a tiny Lua program"

mkdir -p /tmp/proc17-demo/fresh-project
lua proc17.lua build "create hello.lua" \
  --project-base /tmp/proc17-demo \
  --repository fresh-project
```

Plan mode requires Lua 5.4, `curl` and `DEEPSEEK_API_KEY`. Build mode also
requires the native create-only provider:

```sh
make -C native provider-shell
```

The CLI emits one JSON result. Exit status `0` means that the Packet completed;
it does not mean that produced software is universally correct or QA-accepted.

## Verify

The deterministic release battery is described in [MANIFEST.md](MANIFEST.md).
The main commands are:

```sh
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
```

The expected-red QA hand remains an internal containment matrix and is not a
release acceptance claim.

## Scope Boundary

This release does not include a general coding agent, automatic PLAN -> BUILD
orchestration, persistent lineage recovery, arbitrary repository hands,
multi-file software, a TUI, general semantic garbage collection, or
cross-model NETWORK anchor compilation.

Those belong to the laboratory roadmap and must acquire their own TABLE,
CRYSTALL and MANIFEST evidence before entering a later release.

## Repository Map

```text
proc17.lua       machine entrypoint
cli/             JSON CLI adapter
core/            Packet and body primitives
runtime/         routing, lineage, economics and authority boundaries
organs/          ten registered operator organs
logic/           bounded semantic and manifestation logic
native/          capability-bounded repository/QA support
tests/           deterministic and hostile verification
docs/00_chaos/  laboratory research and unresolved hypotheses
docs/01_table/  structured contracts in development
docs/02_crystall/ executable contracts in development
docs/03_manifest/ measured body evidence
```

The exact release-candidate scope and measured baseline are in
[MANIFEST.md](MANIFEST.md).
