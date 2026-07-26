# QA Contract And Profile Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-07-23
source table:
  docs/01_table/yellowprints/qa_contract_profile_yellowprint.v0.md
gate record:
  docs/00_chaos/qa_table_cross_audit_2026-07-23.md
crystall audit:
  docs/00_chaos/qa_crystall_cross_audit_2026-07-23.md
implementation authority: schema modules, exact environment probe contract and
  immutable Packet-birth binding after the hostile-red gate is installed
QA process execution authority: forbidden until steps 8.5.4 and 8.5.5
router/pressure promotion: forbidden
```

Companion crystall:

```text
docs/02_crystall/blueprints/qa_execution_capability.v0.md
docs/02_crystall/blueprints/qa_native_supervisor.v0.md
docs/02_crystall/blueprints/qa_check_verdict.v0.md
docs/02_crystall/blueprints/candidate_seal_transaction.v0.md
```

## 0. Crystallized Claim

One build stage may ask exactly one executable QA question only when that
question was fixed before candidate execution and survives every recovery birth
of that same stage without changing meaning.

```text
qa.contract.v0
  names one required sealed Lua entrypoint
  names one exact profile and measured environment
  fixes every resource ceiling
  carries no command, path to an executable or private authority
```

The public profile describes authority. It does not grant authority. The public
environment record describes one admitted host closure. It does not contain the
handle that can enter that closure.

## 1. Exact Implementation Surface

New modules:

```text
core/qa_schema.lua               closed schemas, normalization and identities
runtime/qa_environment.lua       private environment registry and projection
runtime/qa_contract.lua          birth binder and pure eligibility reader
tests/test_qa_contract.lua
tests/test_qa_environment.lua
```

Later integration under the companion crystall:

```text
core/packet.lua                  immutable birth projection only
runtime/network_ingress.lua      same-stage contract transport only
runtime/corpse.lua               frozen contract coordinates
runtime/qa_request.lua           named consumer of the required check
```

This slice does not add:

```text
an executable provider call
a command-shaped API
a QA body event
a QA verdict
router pressure
source write authority
```

## 2. Closed Constants

`core/qa_schema.lua` owns these exact public constants:

```lua
qa_schema.contract_protocol = "qa.contract.v0"
qa_schema.profile_protocol = "qa.profile.v0"
qa_schema.environment_protocol = "qa.environment.v0"
qa_schema.resource_limits_protocol = "qa.resource_limits.v0"

qa_schema.profile_id = "qa.profile.lua54_test_suite.v0"
qa_schema.provider_id = "linux.qa_supervisor.lua54.v0"
qa_schema.supervisor_abi = "proc17.qa_supervisor.v0"
qa_schema.check_kind = "lua54_test_suite.v0"
qa_schema.execution_policy = "single_required_check.v0"
```

The first hard ceiling is:

```lua
{
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

All fields are required non-negative integers. Time and byte limits must be
positive. `max_processes` is exactly one in v0. A contract may select smaller
positive limits but may not omit, broaden or reinterpret a field.
`cpu_time_ms` must be a positive multiple of 1000 because the v0 hard kernel
enforcement is `RLIMIT_CPU`; accepting finer values would make the contract more
precise than its physics.

## 3. Public Schema API

```lua
local qa_schema = require("core.qa_schema")

qa_schema.profile() -> detached_profile
qa_schema.hard_limits() -> detached_limits

qa_schema.normalize_limits(input) -> limits | nil, err
qa_schema.normalize_environment(input) -> environment | nil, err
qa_schema.normalize_contract(input) -> contract | nil, err

qa_schema.verify_profile(value) -> true | nil, err
qa_schema.verify_environment(value) -> true | nil, err
qa_schema.verify_contract(value) -> true | nil, err
qa_schema.same(left, right) -> boolean
```

Every verifier requires a plain acyclic table, exact key set, dense arrays,
closed enum and bounded UTF-8/control-free strings. Unknown keys are rejected.
Returned values are detached deep copies.

Exact generic v0 ceilings:

```text
lineage_id and stage_id            1024 UTF-8 bytes
machine_arch                       128 UTF-8 bytes
source_refs                        256 dense members
one source ref                     4096 UTF-8 bytes
```

Path ceilings remain the stricter repository path law below. These ceilings
only reject inputs; they grant no execution authority.

Canonical ids use `core.digest.record` over every normalized field except the
id being derived:

```text
qa-check-contract:<sha256>
qa-contract:<sha256>
qa-environment:<sha256>
```

The fixed profile id is a versioned protocol name. Its `policy_digest` is a
digest of every normalized profile field except `policy_digest`.

## 4. Exact Profile Record

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

No caller may supply or amend this record. `qa_schema.profile()` constructs it
from closed constants. The native environment must implement this exact
meaning; changing Lua libraries, package search, isolation or hard ceilings
requires a new profile id.

## 5. Exact Environment Record

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

The identity includes every field except `environment_id`. Exact meanings:

```text
provider_build_id
  sha256 of the exact loaded launcher module bytes

supervisor_build_id
  sha256 of the exact opened static supervisor executable bytes

runtime_dependency_closure_id
  digest of the static supervisor closure and its build manifest; no dynamic
  candidate runtime dependency is admitted

runtime_build_id
  digest of the embedded Lua archive identity, Lua release constants and the
  candidate-library policy

kernel_identity_id
  digest of normalized uname release/version/machine and required ABI facts

isolation_feature_set_id
  digest of the exact successfully exercised feature probe, not header presence

isolation_policy_digest
  digest of namespace, mount, seccomp, descriptor and cleanup policy
```

Host observations such as available headers or sysctls are diagnostics only.
`available` requires the future native probe to exercise the exact production
path successfully. A skipped or weakened primitive yields no environment
record under this provider id.

## 6. Private Environment Registry

`runtime/qa_environment.lua` owns a weak-key private registry:

```lua
local qa_environment = require("runtime.qa_environment")

qa_environment.new(session_id, native_adapter) -> registry | nil, err
qa_environment.probe(registry) -> detached_environment | nil, diagnostic
qa_environment.inspect(registry, environment_id) -> detached_state | nil, reason
qa_environment.resolve(registry, environment_id, profile_id)
  -> private_environment_lease | nil, reason
qa_environment.quarantine(registry, environment_id, reason)
  -> detached_state | nil, err
```

Private record:

```lua
{
  public_projection = qa_environment,
  native_adapter = private,
  supervisor_identity = private,
  runtime_identity = private,
  isolation_policy = private,
  hard_limits = private,
  state = "available" | "unavailable" | "quarantined",
  revision = positive_integer,
  quarantine_reason = string | nil,
}
```

The detached projection cannot be converted back into a lease. Resolution
requires the exact registry object, environment id, profile id and available
private record. Quarantine is sticky for that environment identity.

## 7. Exact QA Contract

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

`required_checks` is a dense array of length one. `arguments` is a dense empty
array. `expected_exit_codes` is exactly `{0}`. No equivalent shorthand is
accepted.

Entrypoint path uses the repository provider path law:

```text
relative, non-empty UTF-8
no NUL/control bytes
no empty, dot, dot-dot or leading-dot component
at most 1024 bytes, 64 components and 255 bytes per component
```

The contract contains no Packet id, generation, repository id or seal. Those
coordinates identify one execution request, not the stage-level law.

## 8. Contract Binding API

```lua
local qa_contract = require("runtime.qa_contract")

qa_contract.bind_for_birth(identity, authorized_policy, environment)
  -> detached_contract | nil, diagnostic

qa_contract.verify_birth(instance)
  -> detached_contract | nil, "not_applicable" | "absent" | err

qa_contract.inspect_candidate(instance, seal, alignment, environment)
  -> eligibility | nil, diagnostic
```

`bind_for_birth` is trusted host/lineage preparation. It validates process,
stage and environment authority, normalizes the policy and produces the final
contract before `packet.new`.

`packet.new` accepts only the already normalized detached contract in
`options.qa_contract`. It does not accept profile selectors or host policy. It
verifies exact equality with Packet coordinates and stamps:

```text
instance.qa_contract_id
instance.qa_contract
metadata.qa_contract_id
birth.payload.qa_contract_id
birth.payload.qa_contract
```

All projections are detached. The full bounded contract in birth is the
immutable meaning; a mutable lookup by id is forbidden.

Mode law:

```text
plan Packet                    qa_contract must be nil
build.only build Packet        exact host-bound contract or typed absent
software.create build Packet   exact target-stage contract from lineage
same-stage recovery            byte-equivalent contract/id
different stage               distinct stage policy and contract identity
```

There is no setter after birth.

## 9. Eligibility Record

Pure inspection returns:

```lua
{
  protocol_version = "qa.eligibility.v0",
  eligibility_id = "qa-eligibility:<sha256>",
  state = "ready" | "not_ready" | "conflict",
  packet_id = string,
  lineage_id = string,
  generation = integer,
  stage_id = string,
  repository_id = string | nil,
  candidate_seal_id = string | nil,
  artifact_alignment_id = string | nil,
  qa_contract_id = string | nil,
  check_id = string | nil,
  profile_id = string | nil,
  environment_id = string | nil,
  entrypoint_artifact_ref = string | nil,
  source_refs = string[],
  missing_requirements = string[],
  conflicting_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

`ready` requires one living build Packet, exact birth contract, exact current
seal, aligned current artifact set, exactly one matching sealed regular-file
entrypoint and exact available environment. Inspection neither mints a grant
nor loads/runs the provider.

An unavailable old environment is `not_ready`; it does not amend the stage
contract. A foreign seal/check/environment is a conflict and never a fallback.

## 10. Identity And Truth Laws

```text
policy commitment act                         runtime_confirmed
exact profile/environment mechanics           runtime_confirmed
semantic belief that one check is sufficient  preserved runtime_confirmed/mixed
future candidate outcome                      absent
universal software correctness                absent
```

Changing any check, profile, environment or limit field changes both the
relevant child identity and `qa_contract_id`. Reordering semantically unordered
source refs does not change identity after normalization.

Public ids are evidence coordinates only. No combination of ids can mint an
environment lease or execute a process.

## 11. Failure Boundary

| Condition | Result |
|---|---|
| plan mode without contract | lawful not-applicable |
| build mode without contract | typed `qa_contract_absent`; no provider |
| contract differs from birth coordinates | loud Packet invariant |
| old exact environment unavailable | typed not-ready; no silent upgrade |
| entrypoint absent | typed not-ready; no provider |
| duplicate matching entrypoint | loud artifact/seal contradiction |
| malformed/overbroad policy | binding rejection before birth |
| caller/substrate supplies command/env/argv | unrepresentable/schema rejection |
| detached record is mutated | private/stored meaning unchanged |

No condition in this crystall writes a failed QA check because no candidate
process has executed.

## 12. Permanent Controls

```text
QC01 plan birth carries no executable QA contract
QC02 build-only exact host policy binds once at birth
QC03 software.create build receives exact stage contract
QC04 same-stage recovery preserves byte-equivalent contract/id
QC05 different stage cannot reuse current contract as authority
QC06 substrate-emitted complete-looking contract has zero authority
QC07 zero/two checks and non-empty argv/env/stdin are rejected
QC08 one changed normalized field changes identity
QC09 returned mutation does not alter next projection
QC10 unavailable old environment blocks rather than upgrades recovery
QC11 seal without exact entrypoint is not ready and calls no provider
QC12 foreign seal/stage/lineage/environment cannot become ready
QC13 public environment/profile ids grant no private lease
QC14 environment requires exercised native feature proof, not headers/sysctls
QC15 accepted wording in stdout has zero policy/verdict authority
```

Seal-dependent controls use grown candidate seals.

## 13. Implementation Order

```text
1. hostile red schemas and identity controls
2. core/qa_schema.lua
3. native environment probe adapter contract, still execution-disabled
4. runtime/qa_environment.lua with detached/private controls
5. runtime/qa_contract.lua and Packet birth binding
6. same-stage recovery identity controls
7. pure candidate eligibility
8. enable only the companion private execution transaction
```

## 14. Acceptance Gate

This crystall is implemented only when:

```text
all exact-schema and detached-return controls are green
the environment probe fails closed when any required primitive is absent
Packet birth cannot gain or replace a QA contract after creation
same-stage recovery identity is stable
no test or public API can obtain a private environment handle from an id
QA-disabled ablation has zero process/trace/budget/loss delta
```

The gate does not authorize production QA by itself.

## 15. Explicit Deferrals

```text
more than one check
optional/parallel/fail-fast scheduling
other language or command profiles
contract amendment inside an active stage
environment migration inside same-stage recovery
semantic test-sufficiency authority
CLI/TUI contract authoring
```

## 16. Supersession Map

This crystall replaces the QA placeholders in:

```text
completion_scope.v0: future qa-check schema/profile
work_layer_projection.v0: future QA contract reader
stage_transition_generation_recovery.v0: unspecified same-life QA policy
```

It does not supersede candidate seal, repository authority or process-stage
identity.

## 17. Crystall Thesis

```text
Before the second hand can touch consequence, the body fixes the exact question,
the exact world in which it may be asked and the exact price ceiling. The name
of that world remains evidence; the door into it remains private.
```
