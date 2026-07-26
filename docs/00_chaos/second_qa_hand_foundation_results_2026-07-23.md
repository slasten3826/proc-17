# Second QA Hand Foundation Results

Status:

```text
layer: CHAOS / runtime-observed implementation evidence
date: 2026-07-23
roadmap: 8.5.5A of 8.5.5E
status: complete
candidate process dispatch: forbidden and absent
native QA provider: absent
router authority: unchanged
```

Sources:

```text
docs/00_chaos/second_qa_hand_red_battery_results_2026-07-23.md
docs/01_table/yellowprints/qa_contract_profile_yellowprint.v0.md
docs/01_table/yellowprints/qa_execution_capability_yellowprint.v0.md
docs/02_crystall/blueprints/qa_contract_profile.v0.md
docs/02_crystall/blueprints/qa_execution_capability.v0.md
```

## 0. Result

Step 8.5.5A made the QA question exact without making it executable.

The body can now represent and verify:

```text
one closed Lua 5.4 QA profile
one exact hard-limit vector
one measured environment identity
one required sealed entrypoint check
one immutable build-stage QA contract
one pure candidate eligibility projection
one command-free QA check request
```

It still cannot:

```text
obtain a sealed-source lease
mint a successful QA execution grant
load a QA provider
launch a candidate process
write a QA check, failure or verdict
change tree readiness or routing
```

This split is intentional. Public meaning exists before private consequence.

## 1. Implemented Surfaces

New modules:

```text
core/qa_schema.lua
runtime/qa_environment.lua
runtime/qa_contract.lua
runtime/qa_request.lua
runtime/qa_capability.lua
```

`core/qa_schema.lua` owns exact normalization and identities for:

```text
qa.profile.v0
qa.resource_limits.v0
qa.environment.v0
qa.contract.v0
qa-check-contract identities
```

Unknown keys, metatables, cycles, sparse arrays, broadened resource limits,
non-empty argv, inherited stdin and command-shaped additions are rejected.
All returned records are detached.

The implementation precision ceilings omitted from the first prose pass are
now written back into TABLE and CRYSTALL: 1024-byte stage/lineage identities,
128-byte machine architecture, at most 256 source refs and 4096 bytes per ref.
They are rejection bounds, not new authority.

## 2. Private Environment Boundary

`runtime/qa_environment.lua` uses a weak-key private registry.

The public environment projection contains exact measured identities only. The
native adapter and future entrance authority remain reachable only through the
exact registry object. Copying the environment record or lease fields grants
nothing.

Observed laws:

```text
successful fake probe is normalized once
public projection cannot resolve itself
wrong profile cannot resolve
quarantine is sticky for the environment identity
probe diagnostics cannot become availability
no candidate run occurs during probe/resolve/inspect
```

The current fake adapter is test evidence only. Production availability remains
red until 8.5.5C exercises the real supervisor path.

## 3. Packet, Death And Recovery

`packet.new` now accepts only an already normalized full contract in
`options.qa_contract`.

Mode and projection laws:

```text
plan + QA contract                  rejected
build + no QA contract              typed absence remains lawful
build + id without full contract    rejected
coordinate mismatch                rejected at birth
mutable post-birth divergence       detected by verify_birth
```

Independent detached projections are stamped into:

```text
instance.qa_contract_id
instance.qa_contract
metadata.qa_contract_id
birth.payload.qa_contract_id
birth.payload.qa_contract
```

`corpse.v0` freezes the full contract and id. A recovery carrier transports the
same process/context/stage contract, and `network_ingress` births the next
generation with that exact contract. The carrier contains no environment
adapter, lease, provider, host path or descriptor.

Grown witness:

```text
generation 1: sealed build Packet with exact QA contract
death: budget_exhausted
corpse: contract hash and coordinates verify
carrier: bounded recovery projection verifies
generation 2: same stage_id and qa_contract_id
local Packet state: fresh
private QA authority: absent
```

## 4. Eligibility And Request

`runtime/qa_contract.inspect_candidate` is a pure reader. `ready` requires:

```text
living build Packet
exact immutable birth contract
repository identity
current exact candidate seal
aligned current artifact set
one exact sealed entrypoint artifact
matching measured environment record
```

Missing entrypoint is `not_ready`; a foreign seal/environment is `conflict`.
Neither path calls an adapter.

`runtime/qa_request.prepare` then projects one exact
`qa.check_request.v0`. It carries the sealed entrypoint's work-unit, byte,
digest, completion and verification evidence. It has no field for:

```text
command
executable
argv
caller environment
cwd
mount
namespace
syscall policy
retry
```

Preparation changes no trace, budget, loss or Packet revision.

## 5. Deliberately Closed Grant Boundary

`runtime/qa_capability.lua` now owns the private-registry shape and rejects
public projections. Successful mint remains deliberately impossible because
the sealed-source bridge does not exist yet.

Current sequence:

```text
request schema may verify
exact body qa_check_request event is still absent
mint rejects before private authority
source bridge absence remains typed
begin finds no grant
provider is never loaded or called
```

This is not a fake green grant. The successful transaction starts only in
8.5.5B after the repository registry can issue one opaque read-only lease.

## 6. Permanent Green Witness

New ordinary suite:

```text
tests/test_qa_foundation.lua
```

It covers closed schemas, detached profile/environment state, private registry
denial, immutable Packet birth, ready eligibility, command-free massless
request preparation, no-event grant denial, corpse freezing and exact
same-stage recovery.

Observed ordinary regression:

```text
lua tests/run.lua
101 suites
all tests ok
process exit: 0

lua tests/smoke_mortality_battery.lua
8/8 ok
process exit: 0
```

Also green:

```text
luac -p for every new/changed Lua implementation module
git diff --check
```

## 7. Red Battery Delta

Command:

```text
lua tests/red_qa_hand.lua
```

Expected process exit remains `1`.

Before 8.5.5A:

| Suite | Green | Red |
|---|---:|---:|
| fixture | 5 | 0 |
| contract | 1 | 14 |
| execution | 0 | 20 |
| native | 1 | 19 |
| verdict | 0 | 24 |
| total | 7 | 77 |

After 8.5.5A:

| Suite | Green | Red |
|---|---:|---:|
| fixture | 5 | 0 |
| contract | 14 | 1 |
| execution | 3 | 17 |
| native | 1 | 19 |
| verdict | 0 | 24 |
| total | 23 | 61 |

Newly green execution controls are only:

```text
QE02 public request has no command-shaped surface
QE03 public ids grant zero private authority
QE05 exact body request event is required before grant begin
```

`QC15` remains red because verdict authority does not exist. Source lease,
execution, supervisor, body evidence and verdict controls remain red. No red
was converted into a skip.

## 8. Next Gate

```text
8.5.5A schemas/private registries          complete
8.5.5B shared repository userdata ABI     next
8.5.5C supervisor/environment probe        blocked by B
8.5.5D isolated transaction                blocked by C
8.5.5E hostile/fault/resource/leak corpus  blocked by D
8.5.6 body check/verdict readers           blocked by execution hand
```

8.5.5B may expose one private read-only source bridge to trusted QA internals.
It may not expose a path, descriptor or userdata to Packet, substrate, carrier
or detached Lua values, and it may not launch a process.

## 9. Thesis

```text
The second hand now knows the exact question and the exact sealed thing the
question concerns. It still has no door into the room. The next step builds
that door as a private one-use object before any candidate is allowed through.
```
