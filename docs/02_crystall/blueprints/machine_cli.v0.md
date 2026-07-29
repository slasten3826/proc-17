# Machine CLI v0 Blueprint

```text
source table: docs/01_table/yellowprints/machine_cli_v0_yellowprint.md
implementation: cli/proc17.lua + proc17.lua
authority: adapter only
```

## 1. Modules

```text
cli/proc17.lua
  parse(argv)
  execute(config, deps)
  main(argv, io_context, deps) -> exit_code

proc17.lua
  package path bootstrap
  os.exit(require("cli.proc17").main(arg))
```

Tests inject substrate and repository provider through `deps`; production has
no public flag for dependency injection.

## 2. Execution Order

```text
parse exact argv
read exactly one task source
create or load session
create invocation lineage id
derive task-seeded flow domain
inherit session graves
if build:
  load exact repository provider
  create registry
  mint exact create-only grant
run tension_runner once
revoke grant if minted
if runner returned terminal Packet:
  append packet + lineage + grave
  save session
render detached CLI result
```

No session/grave write occurs for CLI parse errors or loud runner failures.

## 3. Fixed Runner Options

```lua
{
  router_mode = "tree",
  pressure_policy = "qualified_need_v0",
  ablate_relation_consumer = true,
  work_mode = config.mode,
  legacy_shadow = false,
  packet_options = {
    session_id = session.session_id,
    lineage_id = invocation_lineage_id,
    generation = 1,
    work_mode = config.mode,
    budget = normalized_budget,
  },
  packet_life = {
    protocol_version = "vertical_packet_life.v0",
    flow_domain = task_domain,
    projection_adapter = "vertical_single.v0",
  },
  inherited_graves = prepared_session_graves,
  substrate_options = {
    model = config.model,
    temperature = 0,
  },
}
```

Build additionally receives exact `repository_hands` and
`host_services.repository_capabilities`.

The build receiver prompt requires a root-level basename without `/`. This is a
capability declaration, not a filename preference: CLI v0 grants no `mkdir` and
cannot establish nested-parent existence before Packet birth.

## 4. Cleanup Law

After successful mint, every branch calls `repository_capability.revoke`.

```text
runner success + revoke failure -> exit 4
runner loud failure + revoke success -> exit 4
runner loud failure + revoke failure -> exit 4 with cleanup message
terminal Packet + session save failure -> exit 4; Packet remains terminal
```

The CLI does not retry effects or substrate calls.

## 5. Rendering Law

Rendering deep-copies only public Packet records. Trace rendering is an
allowlisted event projection without payloads. It never renders registry,
grant projection, provider object, repository host identity, L1 mutable state
or raw substrate response.

JSON encode failure is a trusted adapter failure and returns exit 4 through a
minimal fallback JSON object.

## 6. Release Gate

```text
luac -p proc17.lua cli/proc17.lua
lua tests/test_cli.lua
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
local fake plan smoke
positional, stdin and task-file source controls
local fake-provider build smoke
optional live DeepSeek plan smoke
optional live DeepSeek build in a fresh empty root
```

No `QN`, `QE` or `QV` control changes status through this implementation.
