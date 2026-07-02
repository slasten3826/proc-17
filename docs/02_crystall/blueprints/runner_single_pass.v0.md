# Single-Pass Runner Blueprint

Module:

```text
runtime/runner.lua
```

Public contract:

```lua
runner.single_pass(prompt, substrate, options) -> packet, result | nil, err
```

Required stages:

```text
new_packet
observe
encode
choose
cycle
manifest_assemble
```

Result shape:

```text
{
  kind = "runner_single_pass_result",
  packet_id,
  stages = {
    observe,
    encode,
    choose,
    cycle,
    manifest
  },
  final_status
}
```

Rules:

```text
missing substrate fails before observe
observe errors stop the route
encode errors stop the route
choose errors stop the route
cycle errors stop the route
manifest assembly errors stop the route
cycle decision "again" leaves packet.status = "running"
cycle decision "stop_complete" may manifest packet and die complete
other stop decisions may manifest packet and die with matching residue
```

Current implementation target:

```text
single turn only
no file writes
no sandbox mutation
no automatic second pass
```
