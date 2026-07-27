# Machine CLI v0 Yellowprint

```text
layer: TABLE
source: docs/00_chaos/proc17_v0_release_closure_notes_2026-07-27.md
scope: one Packet per invocation
new body authority: none
```

## 1. Command

```text
lua proc17.lua plan  [TASK | --task-file FILE] [options]
lua proc17.lua build [TASK | --task-file FILE] --project-base ABS --repository REL [options]
lua proc17.lua help
```

If neither `TASK` nor `--task-file` is present, task bytes come from stdin.
The three sources are mutually exclusive. Empty task input is rejected.

## 2. Options

| Option | Meaning | Default |
|---|---|---|
| `--session ID` | load an existing session only | create fresh session |
| `--label TEXT` | assign/update non-identity session label | absent |
| `--model ID` | substrate model | `DEEPSEEK_MODEL` or `deepseek-chat` |
| `--max-steps N` | Packet step budget | 64 |
| `--max-calls N` | substrate-call budget | 4 |
| `--max-tokens N` | total-token budget | 65536 |
| `--max-loss N` | Packet identity-loss capacity | 10 |
| `--project-base ABS` | trusted repository parent | build required |
| `--repository REL` | repository beneath parent | build required |

Unknown, duplicate, missing-value and mode-inapplicable options reject before
Packet birth. The CLI exposes no router, truth, capability, QA or command flags.

## 3. Fixed Body Policy

```text
router_mode = tree
pressure_policy = qualified_need_v0
ablate_relation_consumer = true
legacy_shadow = false
projection_adapter = vertical_single.v0
repository operation = create_text_file only
generation = 1
```

The task bytes seed one invocation-local L1 flow domain. The CLI does not
accept caller-supplied L1 state or route decisions.

## 4. Session Transaction

```text
no --session:
  session_memory.create(nil, label)
  empty grave/compost

--session ID:
  session_memory.load(ID)
  missing or malformed session rejects

before birth:
  inherit only this session's graves

after terminal Packet:
  append Packet id
  append fresh lineage id
  classify/add grave
  save session
```

The CLI does not claim lineage continuation. `lineage_id` identifies the
single invocation. Build completion does not pass through the plan-only
`lineage_runner` completion reader.

## 5. Prompt Envelope

User task remains semantic input. The CLI appends a fixed receiver contract.

Plan requires:

```text
packet.structure.proposal.v0
receiver = calm.work_structure.v0
shape = work_sequence
items = work_item
```

Build requires:

```text
packet.structure.proposal.v0
receiver = calm.work_structure.v0
shape = artifact_set
exactly one repository.create_text_file.v0 item
value = {path, content}
```

The receiver contract is body plumbing, not user text and not runtime truth.

## 6. Build Authority

Build creates one private repository registry and one grant bound to:

```text
session_id
lineage_id
generation = 1
repository_id
project_base
repository_path
provider = linux.openat2.renameat2.v0
operation = create_text_file
```

The grant is revoked on every return path after mint. No grant, handle, root
host path or provider userdata enters CLI JSON.

## 7. Output

stdout contains exactly one JSON value.

Success/terminal envelope:

```lua
{
  protocol_version = "proc17.cli.result.v0",
  ok = boolean,
  mode = "plan" | "build",
  session_id = string,
  lineage_id = string,
  packet_id = string | nil,
  final_status = string | nil,
  stop_reason = string | nil,
  death = table | nil,
  manifest = table | nil,
  budget = table | nil,
  trace = table | nil,
  session_path = string | nil,
  error = nil | {class, stage, message},
}
```

`ok=true` means Packet death cause `complete`. It does not mean externally
accepted software.

`trace` is a strict public projection containing only event id, type, operator,
truth status, time and cost. Event payloads remain body-local because current
repository events may contain non-secret capability references that still have
no reason to cross the CLI boundary.

## 8. Exit Classes

| Exit | Class |
|---|---|
| 0 | Packet completed or help returned |
| 2 | CLI input/config/session error |
| 3 | honest non-complete Packet terminal |
| 4 | trusted runtime/invariant/provider setup failure |

Substrate effect failure that becomes honest Packet mortality returns 3.
Malformed trusted machinery returns 4 and never becomes a grave.

## 9. Controls

```text
CL01 default invocation creates a fresh isolated session
CL02 explicit session loads only that session
CL03 task source ambiguity rejects before birth
CL04 plan invokes no repository provider
CL05 build requires both repository coordinates
CL06 fake plan reaches exact JSON plan delivery
CL07 fake build reaches exact create-only repository delivery
CL08 non-complete Packet returns exit 3 with JSON
CL09 malformed trusted setup returns exit 4 and no invented grave
CL10 stdout result contains no private repository authority
CL11 unknown/router/QA/command flags reject
CL12 session is saved after a terminal Packet
CL13 positional, stdin and task-file sources each run successfully
```
