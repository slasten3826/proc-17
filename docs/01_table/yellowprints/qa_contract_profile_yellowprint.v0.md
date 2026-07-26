# QA Contract And Profile Yellowprint v0

Status:

```text
layer: table (checked)
date: 2026-07-23
scope: immutable QA policy, required check and first admitted execution profile
runtime implementation authorized: no
QA execution authorized: no
router/pressure promotion authorized: no
crystallization authorized: yes; QA TABLE cross-audit 2026-07-23
gate record: docs/00_chaos/qa_table_cross_audit_2026-07-23.md
```

Primary chaos source:

[`../../00_chaos/second_qa_hand_threat_model_2026-07-23.md`](../../00_chaos/second_qa_hand_threat_model_2026-07-23.md)

Companion TABLE contracts:

```text
qa_execution_capability_yellowprint.v0.md
qa_check_verdict_yellowprint.v0.md
completion_scope_candidate_seal_yellowprint.v0.md
nested_work_layer_derivation_yellowprint.v0.md
stage_transition_generation_recovery_yellowprint.v0.md
candidate_seal_transaction_yellowprint.v0.md
```

## 0. Selected Decisions

```text
QC01 QA policy is immutable before the first QA result can exist
QC02 the build Packet birth owns the exact current qa_contract projection
QC03 build.only receives it only from explicit host-authorized input
QC04 software.create receives it from the accepted stage/lineage transition
QC05 plan.only carries no executable build QA contract
QC06 substrate output may propose checks but cannot commit the contract
QC07 v0 has exactly one required aggregate test-suite check
QC08 the check contract is stage-stable across recovery generations
QC09 the check binds one sealed relative Lua entrypoint, not a command
QC10 the first profile is qa.profile.lua54_test_suite.v0
QC11 the first exact environment is selected and measured by trusted host policy
QC12 profile/environment ids are public evidence and carry no authority
QC13 v0 accepts no caller argv, PATH, cwd, env, stdin, shell or network fields
QC14 success means the exact profile exits with code zero inside proven bounds
QC15 stdout/stderr are diagnostics, never success authority
QC16 source is read-only; cache/temp/build outputs belong only to scratch
QC17 contract limits may narrow but never exceed fixed profile ceilings
QC18 contract identity includes every policy field except qa_contract_id
QC19 the contract stores no private executable, descriptor or namespace handle
QC20 recovery of the same stage preserves qa_contract_id
QC21 another stage/process/lineage cannot reuse the contract as current authority
QC22 changing check/profile/environment/limits creates a new contract identity
QC23 candidate contents cannot silently add, remove or redefine required checks
QC24 v0 check sufficiency is bounded policy evidence, not universal correctness
```

## 1. Closed Claim

This table defines one public immutable policy object:

```text
For one exact build stage, this exact host-authorized contract declares the
single executable QA check that every sealed generation candidate must satisfy,
the exact admitted environment/profile and the maximum authority it may consume.
```

It does not prove:

```text
the candidate is sealed
the source view is isolated
the check was executed
the check passed or failed
the QA provider is trustworthy
the software is universally correct
the stage or root is complete
```

Those claims belong to companion contracts and later readers.

## 2. Authority Chain

| Fact | Authority owner | Evidence | First named reader |
|---|---|---|---|
| process and stage coordinates | Packet birth / lineage stage transition | exact runtime-confirmed event | QA contract binder |
| build-only QA policy | explicit trusted host input | normalized bounded contract | Packet birth writer |
| software.create QA policy | accepted prior plan/stage contract | exact transition refs | target Packet birth writer |
| required check membership | immutable qa_contract | canonical one-element set | QA request derivation |
| profile mechanics | trusted host profile registry | detached measured projection | QA capability resolver |
| exact environment identity | trusted provider/host registry | measured environment record | contract binder and execution request |
| entrypoint existence/content | sealed artifact set | candidate-seal artifact record | QA request derivation |
| check outcome | sandbox execution provider + body writer | companion check record | verdict assembler |
| final verdict | deterministic body assembler | complete exact check set | completion/work layer |

No substrate appears in an authority-owner cell. A plan may carry semantic QA
intent, but the later host/process contract decides whether that intent becomes
this bounded policy.

## 3. Contract Birth And Mode Matrix

The contract is committed no later than the target build Packet birth.

| Process contract | QA source | Packet birth behavior |
|---|---|---|
| `plan.only.v0` | none | `qa_contract_id=nil`; no QA execution |
| `build.only.v0` | exact explicit host-authorized contract | birth validates and stamps the full detached projection |
| `software.create.v0`, plan stage | semantic QA intent may be produced | no build execution authority in plan Packet |
| `software.create.v0`, build stage | exact lineage transition from accepted plan/stage policy | birth validates/stamps same stage contract |
| recovery of same build stage | source stage contract | preserve identical `qa_contract_id` |
| different successor stage | target stage contract | a distinct id is required |

The contract is stage-level, not generation-level. It contains lineage and
stage identity but not Packet id, repository id, generation or candidate seal.
Those current-life coordinates enter the later check request.

No API may add a QA contract to an already-born Packet. A Packet born without
one cannot gain QA authority by receiving an LLM response or by reaching a
sealed state.

Environment change does not silently amend an active stage contract:

```text
same stage recovery + original environment still available
  -> preserve exact qa_contract_id and environment_id

same stage recovery + original environment unavailable
  -> preserve exact qa_contract_id; QA is typed not_ready

new environment/profile policy
  -> new environment_id and qa_contract_id only through an explicit new
     stage/lineage policy revision; never through recovery convenience
```

Stage/lineage policy revision is deferred in v0. This means an environment
upgrade may honestly block an old stage rather than rewrite its historical law.

## 4. Target QA Contract

```lua
{
  protocol_version = "qa.contract.v0",
  qa_contract_id = "qa-contract:<sha256>",

  lineage_id = string,
  process_contract_id = "build.only.v0" | "software.create.v0",
  context = "software_task.v0",
  stage_id = string,

  execution_policy = "single_required_check.v0",
  required_checks = {
    {
      check_id = "qa-check-contract:<sha256>",
      ordinal = 1,
      required = true,
      kind = "lua54_test_suite.v0",
      profile_id = "qa.profile.lua54_test_suite.v0",
      environment_id = "qa-environment:<sha256>",
      entrypoint = {
        relative_path = string,
        expected_kind = "regular_file",
      },
      invocation = {
        stdin = "closed",
        arguments = {},
        expected_exit_codes = {0},
      },
      resource_limits = qa_resource_limits,
      output_policy = {
        authority = "exit_status_only",
        retain_raw_output = false,
      },
    },
  },

  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "mixed",
}
```

`required_checks` has exactly one dense member in v0. The member is still an
array so a later protocol can add ordered multi-check policy without changing
the meaning of the v0 object.

The contract's `content_truth_status` may be `mixed` when the prior plan
proposed semantic test intent. The act that committed this exact bounded policy
is nevertheless runtime-confirmed.

Implementation precision amendment, 2026-07-23:

```text
lineage_id and stage_id            at most 1024 UTF-8 bytes
source_refs                        dense, at most 256 members
one source ref                     at most 4096 UTF-8 bytes
all bounded strings                control-free and valid UTF-8
```

These are rejection ceilings, not additional authority. Lowering one requires
a protocol amendment because it changes which exact historical contracts can
be admitted; raising one requires a bounds review.

## 5. Required Check Identity

The required check identity hashes every normalized check field except
`check_id`.

Required path law:

```text
relative UTF-8 path
no empty, dot, dot-dot or leading-dot component
no control/NUL bytes
bounded by repository provider path ceilings
must resolve to one regular-file artifact in the eventual exact seal
```

The contract binds the expected relative entrypoint path before candidate
materialization. The execution request later binds that path to the exact
sealed artifact's:

```text
work_unit_id
work_unit_version
bytes
sha256
completion_ref
verification_ref
candidate_seal_id
```

If the sealed candidate does not contain exactly that artifact, QA is not ready.
The provider is not called and no substitute path is selected.

## 6. First Admitted Profile

The v0 public profile family is:

```lua
{
  protocol_version = "qa.profile.v0",
  profile_id = "qa.profile.lua54_test_suite.v0",
  provider_id = "linux.qa_supervisor.lua54.v0",
  language_runtime = "lua-5.4",
  invocation_kind = "sealed_lua_test_entrypoint",

  source_cwd = true,
  stdin = "closed",
  caller_arguments = "forbidden",
  caller_environment = "forbidden",
  shell = "forbidden",
  network = "forbidden",
  child_processes = "forbidden",
  native_modules = "forbidden",
  source_writes = "forbidden",
  scratch_writes = "bounded",

  lua_policy = {
    ignore_host_environment = true,
    package_path = "./?.lua;./?/init.lua",
    package_cpath = "",
  },

  hard_limits = qa_resource_limits,
  policy_digest = "sha256:<hex>",
  event_truth_status = "runtime_confirmed",
}
```

The profile is a detached public description. Its id cannot launch anything.
Private provider registration and an exact one-use lease are still required.

`source_cwd=true` means the candidate observes the sealed source root as its
current directory. That directory is read-only. `HOME`, `TMPDIR` and writable
cache locations point into bounded scratch.

The Lua policy may remove or wrap unsafe library entry points as defense in
depth, but OS containment remains mandatory. Hiding `os.execute` is not proof
that filesystem, network or process authority is absent.

## 7. Exact Environment Record

The host profile registry publishes a detached environment record:

```lua
{
  protocol_version = "qa.environment.v0",
  environment_id = "qa-environment:<sha256>",
  profile_id = "qa.profile.lua54_test_suite.v0",
  provider_id = "linux.qa_supervisor.lua54.v0",
  provider_build_id = "sha256:<hex>",
  supervisor_abi = "proc17.qa_supervisor.v0",
  supervisor_build_id = "sha256:<hex>",
  runtime_dependency_closure_id = "sha256:<hex>",
  runtime_name = "Lua 5.4",
  runtime_build_id = "sha256:<hex>",
  platform = "linux",
  machine_arch = string,
  kernel_identity_id = "sha256:<hex>",
  isolation_feature_set_id = "sha256:<hex>",
  isolation_policy_digest = "sha256:<hex>",
  hard_limits_digest = "sha256:<hex>",
  event_truth_status = "runtime_confirmed",
}
```

The environment record contains no executable path, handle or loader option.
The provider loader owns those privately and fails closed if the exact build or
ABI is unavailable.

Changing provider/supervisor/runtime closure, machine/kernel identity,
isolation features/policy or hard limits creates a different `environment_id`.
Historical QA remains valid as history but cannot be presented as execution
under the new environment.

## 8. Resource Limits

The v0 profile hard ceilings are:

```lua
qa_resource_limits = {
  protocol_version = "qa.resource_limits.v0",
  wall_time_ms = 30000,
  cpu_time_ms = 20000,
  address_space_bytes = 268435456,
  max_processes = 1,
  max_open_files = 64,
  max_file_bytes = 16777216,
  scratch_bytes = 67108864,
  scratch_entries = 4096,
  stdout_bytes = 1048576,
  stderr_bytes = 1048576,
}
```

A host contract may choose smaller positive values. It may not exceed any
field, omit a field or replace the fixed profile protocol.

The exact numbers are v0 safety ceilings, not performance recommendations.
Changing a hard ceiling requires a new profile/policy identity and hostile
evidence.

`max_processes=1` means the admitted Lua entrypoint cannot create child
processes. Multi-process software testing requires a future profile and threat
model.

## 9. Fixed Environment Projection

Candidate code receives only a fixed profile environment equivalent to:

```text
HOME=/qa/scratch/home
TMPDIR=/qa/scratch/tmp
LANG=C
LC_ALL=C
TZ=UTC
```

No host environment is inherited. In particular:

```text
PATH
SSH_AUTH_SOCK
GPG_AGENT_INFO
AWS_*
GITHUB_*
OPENAI_*
ANTHROPIC_*
DEEPSEEK_*
XDG_*
DBUS_*
DISPLAY
WAYLAND_DISPLAY
```

are absent unless a future versioned profile names an exact non-secret value.

The request cannot add, remove or override environment entries.

## 10. Canonical Contract Derivation

Conceptual host/body boundary:

```lua
qa_contract.bind_for_birth(process_stage, host_policy, environment_projection)
  -> detached_contract | nil, diagnostic
```

Canonical order:

```text
1. verify target process/stage/lineage coordinates
2. select the one permitted source according to the mode matrix
3. validate exact host-authorized profile and environment projection
4. normalize the single required check and relative entrypoint
5. clamp/reject limits against the profile; never silently broaden
6. canonicalize dense arrays and source refs
7. derive check_id from the normalized check
8. digest every contract field except qa_contract_id
9. stamp the detached contract into Packet birth authority
```

Silent clamping is forbidden because the contract id must describe the limits
that will actually govern execution. An overbroad request is rejected and must
be resubmitted as a different exact policy.

## 11. Packet Birth Binding

Build Packet birth gains public fields:

```lua
qa_contract_id = "qa-contract:<sha256>"
qa_contract = detached_qa_contract
```

The Packet's current immutable coordinates must equal the contract:

```text
lineage_id
process_contract_id
context
stage_id
```

The full contract is bounded and carries no private authority, so storing it in
the birth event does not leak a capability. Keeping only an id with a mutable
host lookup would make the contract's meaning changeable after birth.

Recovery birth verifies the same stage-level contract id. A different id means
a different stage policy and requires an explicit lineage stage-policy event;
v0 recovery has no such transition.

## 12. Eligibility Projection

Pure reader:

```lua
qa_contract.inspect_candidate(instance, seal, alignment, environment)
  -> ready | not_ready | conflict
```

`ready` requires:

```text
living build Packet
exact birth-bound qa_contract
exact current candidate seal
candidate alignment = aligned
sealed artifacts contain exactly one matching entrypoint
current host environment_id equals the contract environment_id
no current check/verdict for a foreign contract or seal is treated as current
```

The projection creates no QA grant and calls no provider.

## 13. Truth And Semantics

```text
host policy commitment act                         runtime_confirmed
profile/environment mechanical identity            runtime_confirmed
required check membership                          runtime_confirmed policy fact
semantic claim that the check is sufficient        runtime_confirmed or mixed content
future check execution                              absent in this table
future software correctness                        not claimed
```

A passing check proves contract satisfaction only. Documentation and UI must
not render it as universal correctness.

## 14. Conflict And Failure Law

| Condition | Outcome |
|---|---|
| no contract for plan mode | lawful not-applicable |
| no contract for build mode | typed `qa_contract_absent`; no execution |
| contract disagrees with birth | loud body invariant failure |
| profile/environment unavailable | typed not-ready; no QA grant |
| profile/environment id changed | current environment mismatch; no replay |
| entrypoint absent from seal | typed not-ready; no provider call |
| two matching sealed entrypoints | loud artifact/seal contradiction |
| contract has zero or several checks | schema rejection |
| non-empty argv/env/stdin request | schema rejection |
| limits exceed profile | policy rejection, never silent clamp |
| LLM emits a complete-looking contract | proposal only; no birth authority |

No condition in this table becomes a failed candidate check because no
candidate process has run yet.

## 15. Named Readers

| Written/projected record | Named reader | When |
|---|---|---|
| qa_contract in birth | eligibility reader | before any QA grant |
| required check | check-request derivation | after exact seal/alignment |
| profile/environment projection | private capability resolver | at grant and dispatch |
| contract/check ids | qa_check validator | provider report ingestion |
| full required set | final verdict assembler | after check evidence |
| semantic policy description | documentation corpus | after terminalization |

No record is introduced without a reader.

## 16. Permanent Controls

| ID | Control | Expected result |
|---|---|---|
| QC-T01 | build-only birth without host contract | no QA contract and no execution authority |
| QC-T02 | software.create build birth from accepted stage | exact inherited contract stamped |
| QC-T03 | plan-only birth | QA contract not applicable |
| QC-T04 | recovery birth for same stage | identical qa_contract_id |
| QC-T05 | caller changes one contract field after birth | birth/current divergence is loud |
| QC-T06 | substrate returns complete contract | zero authority delta |
| QC-T07 | zero or two required checks | schema rejection |
| QC-T08 | missing/foreign entrypoint in exact seal | not ready, no provider call |
| QC-T09 | caller adds argv/env/shell/path | unrepresentable or schema rejection |
| QC-T10 | requested limit exceeds hard profile | rejection, no silent clamp |
| QC-T11 | environment build/policy changes | old stage remains bound/unavailable; any explicitly new stage contract gets new identities |
| QC-T12 | returned contract/profile mutation | next read unchanged |
| QC-T13 | same normalized policy order | same ids |
| QC-T14 | foreign stage/lineage uses contract | no eligibility |
| QC-T15 | aligned versus diverged candidate | only aligned is ready |
| QC-T16 | stdout text claims success | no contract or verdict authority |

Controls use a real grown candidate seal where seal membership matters.

## 17. Cross-Contract Consequences

The companion execution table must consume only:

```text
exact birth-bound qa_contract
its one required check
exact matching seal artifact
exact current environment/profile
private one-use authority
```

The companion evidence table must preserve:

```text
qa_contract_id
check_id
profile_id
environment_id
candidate_seal_id
exact resource envelope
```

Completion/work-layer readers may not infer any of these fields from an exit
code or substrate summary.

## 18. Explicit Deferrals

```text
more than one required check
optional checks
fail-fast and parallel check scheduling
arbitrary argv or environment parameters
shell/make/package-manager profiles
Python, Node, compiled-language and service profiles
networked or multi-process tests
external legacy differential QA
dependency download/install
QA contract amendment inside a live stage
semantic test sufficiency classifier
CLI/TUI contract authoring
```

## 19. Closed Chaos Questions

```text
Q1  writer: host-authorized build birth or accepted lineage stage transition
Q2  immutability point: target build Packet birth
Q3  first profile: exact Linux Lua 5.4 sealed test-suite profile
Q6  scratch/cache authority: fixed profile, bounded, never source
Q7  request surface: profile/check/entrypoint refs only; no command API
Q10 scheduling: exactly one required aggregate check in v0
Q14 contract-side economics: exact limits; actual cost belongs to check evidence
```

Other chaos questions are owned by the execution and evidence companion tables.

## 20. Table Thesis

```text
The candidate may contain tests, but it does not own the law that makes them
sufficient. That law is fixed before execution, carried by birth and narrowed
to one exact profile whose public name grants no power by itself.
```
