# Machine CLI v0 Manifest

```text
layer: MANIFEST
date: 2026-07-27
status: implemented, locally verified and live-substrate verified
release status: not yet tagged
new body authority: none
```

Sources:

```text
docs/00_chaos/proc17_v0_release_closure_notes_2026-07-27.md
docs/01_table/yellowprints/machine_cli_v0_yellowprint.md
docs/02_crystall/blueprints/machine_cli.v0.md
cli/proc17.lua
proc17.lua
tests/test_cli.lua
```

## Manifested Surface

The repository now exposes one machine-first entrypoint:

```text
lua proc17.lua plan  [TASK | --task-file FILE] [options]
lua proc17.lua build [TASK | --task-file FILE] --project-base ABS --repository REL [options]
lua proc17.lua help
```

Each invocation runs one mortal Packet under the fixed qualified tree policy.
DeepSeek is the production substrate. A missing explicit session creates a
fresh session with empty grave and compost; `--session ID` loads only that
existing session. The CLI stores terminal Packet identity and grave residue
after the run.

Plan mode manifests a structured plan. Build mode may create exactly one
previously absent UTF-8 file beneath one explicitly granted repository root.
The repository grant is private, create-only, generation-bound and revoked
after the run.

stdout contains one `proc17.cli.result.v0` JSON value. Its trace is a strict
projection without event payloads. Exit classes are:

```text
0 complete Packet or help
2 invalid input/config/session
3 honest non-complete Packet terminal
4 trusted runtime/setup/invariant failure
```

`ok=true` means only that the Packet died `complete`. It is not a software QA
verdict or lineage-level acceptance.

## Runtime Evidence

Local verification on 2026-07-27:

```text
lua tests/run.lua                    107 suites passed
tests/test_cli.lua                   passed
lua tests/smoke_mortality_battery.lua 8/8 passed
lua tests/red_qa_hand.lua            40 green / 44 expected red, exit 1
luac -p CLI sources                  passed
git diff --check                     passed
./proc17.lua help                    one JSON value, exit 0
live DeepSeek plan                  complete, 1 call / 373 tokens / 5 steps
live DeepSeek build                 complete, 1 call / 408 tokens / 6 steps
live create-only replay             effect_failure, exit 3, original unchanged
```

`tests/test_cli.lua` proves positional, stdin and task-file plan delivery, fresh
and explicit sessions, fake build delivery, one real native-provider file
creation, budget death, hostile arguments, private-authority non-disclosure and
loud runner failure without invented grave history.

The first live plan exposed a renderer defect: successful Packets carried an
`error` member because Lua's `condition and nil or fallback` cannot select nil.
The result builder now adds `error` only on non-complete terminals, and CL06/
CL08 pin both sides of that contract.

The live build created only `sum.lua`, 38 bytes, with SHA-256
`f234abd894607549cc0ccedd9b39b6e56c0e2d2f90a6c422d9f94a17f0ffec56`.
Independent filesystem inspection and Lua execution confirmed the bytes and
`add(2, 3) == 5`. A second live build targeting the same path died
`effect_failure`; the file and digest remained unchanged and no second artifact
appeared.

## Remaining Release Boundary

The live probes above ran from the development worktree. They prove the public
entrypoint and production substrate/provider path, but they do not replace the
clean-checkout release reproduction required by R8.

The CLI does not add patching, overwrite, deletion, rename, arbitrary source
inspection, commands, project QA, multi-file transactions, persistent lineage
recovery or a TUI. The expected-red QA matrix remains withheld authority.

Plan invocation depends on Lua 5.4 and `curl`. Build additionally depends on
the Linux native repository provider built with `make -C native provider-shell`
and therefore on a C toolchain, `pkg-config` and Lua 5.4 development headers.

`v0.1.0` is not declared by this document. Clean-checkout release reproduction,
the release commit and tag remain separate closure work.
