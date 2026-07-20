# First Repository Hand Manifest Plan

Date: 2026-07-20

Status:

```text
CHAOS implementation plan for roadmap 7.10
precondition: roadmap 7.9 route/effect/reconciliation is green
scope: exact projection of one completed repository action through △
authority widening: forbidden
```

## Pressure

The body can now create one exact file, verify it independently and record
`runtime.work_completion.v0`. `body.progress` says `done=1`, but this fact has no
qualified terminal reader. The Packet may continue looking or stall after the
task is already complete.

This is a reader gap, not a missing hand. Roadmap 7.10 must let △ deliver the
result already known by the body. It must not grant MANIFEST filesystem access,
repeat provider work or trust substrate prose as completion.

## Boundary Law

```text
☶ may change and verify the external world
☱ may reconcile evidence into work_completion
△ may only validate and project Packet-owned evidence
```

MANIFEST receives no capability registry, provider handle, repository root,
absolute path, content bytes or substrate call. Its only authoritative input is
one exact current action projection plus one exact current work-completion event
already present in trace.

## Causal Route

After reconciliation, the repository phase inspector sees:

```text
phase = completed
remaining work = 0
current operator = ☱
exact work_completion event exists and is still valid
```

It may then produce one terminal witness:

```text
consumer: manifest.repository_result.v0
mode: repository_delivery
route: ☱ -> △
scope: exact action route scope + completion event ref
```

There is no fixed full trace. The required terminal suffix is only:

```text
☶ -> ☱ -> △
```

## Projection

The body-owned structured result is bounded:

```text
repository.result.v0
  result_id
  packet_id / lineage_id / generation
  status = complete
  repository_id
  artifacts[1]
    work_unit_id / work_unit_version
    action_id
    operation = create_text_file
    relative_path
    outcome = created
    target_kind = regular_file
    bytes
    sha256
    verification_ref
    completion_ref
  event_truth_status = runtime_confirmed
  content_truth_status = inherited origin status
```

`result_id` is a deterministic digest of the projection without the id. The
fact that the artifact exists with these exact bytes/digest is runtime-confirmed.
The semantic origin of those bytes remains separately typed and is not promoted.

The enclosing manifest payload is:

```text
kind = manifest_payload
mode = repository_delivery
output.type = repository
output.status = complete
output.structured = repository.result.v0
output.text = canonical JSON of structured result
assembly.rule = repository_delivery.v0
assembly.input_provenance = packet_state
terminal_cause = complete
truth_status = runtime_confirmed
```

Sources name formation, attempt, receipt, verification, validation and
completion events. Residue records completion and no remaining repository work.

## Non-Disclosure

The projection must recursively exclude:

```text
raw content / observed content
host path / project base
repository or root handle
provider object or private registry
capability lease
command / shell
temporary native residue
```

Relative path, byte length and SHA-256 are intentional public artifact metadata.

## Freshness And Honesty

Before readiness and again before projection, the reader must prove:

```text
action still matches the current field unit/version
completion event is exact, ☱-owned and runtime-confirmed
its attempt -> receipt -> verification -> validation chain remains valid
verification is accepted and matches action length/digest/path
no later conflicting effect evidence exists
body.progress has zero remaining repository work for this v0 life
```

Absent or stale completion creates no qualified delivery witness. Rejected
verification may produce an honest blocked/death path elsewhere, but it can
never produce `repository.result.v0 status=complete`.

Malformed trusted input, forged scope or impossible evidence remains a loud
harness error. It is not converted into a decorative Packet death.

## Economics

Repository delivery pays only the ordinary △ body tick:

```text
steps += 1
tool_calls += 0
file_writes += 0
identity loss += 0
```

The earlier effect charge is neither repeated nor summarized as a new charge.

## Matched Controls M0-M10

| ID | One changed fact | Required result |
|---|---|---|
| M0 | exact completed one-file life | eventual `☱ -> △`, dead/complete |
| M1 | same life before completion | no repository-delivery witness |
| M2 | accepted effect but delivery reader ablated | completion remains; no repository manifest |
| M3 | rejected read-back | no complete repository result |
| M4 | completion ref changed or stale | readiness/effect verification rejects |
| M5 | runner result/substrate text changed | structured result remains identical |
| M6 | inspect projected value recursively | no private authority or raw content |
| M7 | accepted life economics | one old effect charge; △ adds steps only |
| M8 | output artifact metadata | exact path/bytes/SHA-256 from verified chain |
| M9 | mutate returned payload | Packet trace/action/completion remain unchanged |
| M10 | hands disabled or shadow authority | old lives remain physically unchanged |

## Implementation Order

1. Add a pure `runtime/repository_result.lua` resolver/projector/verifier.
2. Expose the exact current completion event ref from `work_completion.inspect`.
3. Add `repository_delivery` action schema and terminal consumer.
4. Add the completed-phase qualified witness from ☱ to △.
5. Add MANIFEST readiness/run branches that use only Packet state.
6. Grow M0-M10 and a complete real route.
7. Register the suite and rerun all hand, mortality and native controls.
8. Record the final 7.10 manifest without erasing 7.1-7.9 archaeology.

## Falsifiers

Roadmap 7.10 fails if:

```text
△ calls the provider or receives host_services
manifest trusts mutable runner result text
receipt or verification alone is treated as completion
rejected/stale evidence becomes complete
raw file content or authority appears in output/trace/corpse
effect economics are charged twice
delivery ablation still manifests the repository result
the result exists before an executed △ tick
default Tree authority changes
```

## Acceptance

The first repository-hand chapter closes only when one grown Packet reaches:

```text
prompt -> field -> exact action -> real bounded mutation -> independent evidence
-> exact work completion -> exact repository result -> △ -> dead/complete
```

and every negative/ablation control remains honest.
