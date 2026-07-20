# First Repository Hand: Hostile Audit Results

status: roadmap step 7.8 complete
date: 2026-07-20
plan: `first_repository_hand_hostile_audit_plan_2026-07-20.md`
previous: `first_repository_hand_effect_progress_results_2026-07-20.md`
next: roadmap step 7.9, measured suite and route promotion

## 1. Result

The 7.7 hand survived a composition-level hostile audit after five boundary
defects were reproduced and repaired. The audit added no route, operation,
fallback or repository authority.

Final focused evidence:

```text
repository-hostile-audit:                16/16 green
repository-effect:                       14/14 green
repository-progress:                      9/9 green
real Linux effect/resource lives:         2/2 green
native create/read/fault battery:        green
128 repeated native transactions:        zero descriptor delta each
```

## 2. Defects Grown By The Audit

### 2.1 Action projection could mint a lease

Initial control H-A03 mutated only `action.target.relative_path` while retaining
the old action id. `begin_effect` checked the private grant projection and
bounds, but did not revalidate the action against current Packet state. The
mutated action received a lease and consumed the real action's dispatch slot.

Treatment:

```text
begin_effect(registry, action, instance)
  -> repository_action.validate(instance, action)
  -> private exact grant check
  -> dispatch consumption
```

The denial now occurs before authority is spent.

### 2.2 Exact request ignored unknown fields

The create lease compared every expected value but did not reject additional
keys. A request carrying `command` reached the fake provider, although the
provider projection stripped that field. Silent stripping was weaker than the
closed-schema contract.

Treatment: the lease now requires one plain, complete, exact-key request record
before marking create as called.

### 2.3 Provider residue validation was shallow

A cyclic table under `provider_error.residue` passed the top-level error schema
and became a typed public `effect_failure`. It could therefore enter routed
trace and corpse residue as trusted world evidence.

Treatment: effect failure accepts only an optional plain
`repository.provider_residue.v0` record with:

```text
kind=reserved_temp
relative_name=.proc17-tmp-<32 hex>
class=ambiguous
```

Unknown, cyclic, metatable or malformed residue remains a loud trusted-runtime
failure. A valid relative residue remains detached and contains no host path.

### 2.4 Completion had a writer and reader bypass

The generic Packet event writer could append `work_completion`, and
`work_completion.is_complete` trusted a small subset of its payload. Three
controls exposed one root defect:

```text
a synthetic generic event reported done
a later conflicting attempt did not revoke the old conclusion
a changed current work version left the old completion readable as true
```

Treatment:

```text
generic append_event rejects repository body event types
runtime.body validates and uses append_repository_event
is_complete revalidates the complete candidate and evidence chain on every read
```

The reader now checks current version, formation, ordered evidence, grant and
provider identity, accepted verification/validation, exact source refs,
completion digest and absence of later conflicts.

This is intentionally a trusted-Lua boundary. Arbitrary hostile Lua with debug
or direct memory access remains outside the v0 threat model.

### 2.5 First revocation control was false green

The first H-A05 passed because an old request revision happened to differ from
the newly revoked grant revision. The control was strengthened by replacing the
request revision with the new revoked/quarantined revision. Both variants then
reached the fake provider.

Root cause: the lease retained the mutable grant object but not the revision at
issuance.

Treatment: every lease stores its issuance revision. Every lease operation now
requires:

```text
same private registry
grant state active
grant revision unchanged from lease issuance
repository handle still present
```

Revocation and quarantine therefore deny old leases by state, not by accidental
request mismatch.

## 3. Controls That Were Already Sound

The first hostile pass was green for:

```text
cross-registry lease substitution
create and read lease replay
generation effect exhaustion
provider exceptions as loud failures
NaN provider economics rejection
foreign read root rejection
detached bounded valid residue
metatable/cyclic repository event input rejection
```

The existing loader, root, path, no-replace, expected+1 read, fault injection,
hard-limit and production-hook controls also remained green. P15 cross-device
mount coverage remains the same explicit environmental skip; no claim was
promoted from it.

## 4. Resource Evidence

The real Linux composition test now grows 16 independent Packets and grants
inside one identity-owned fixture. Every life creates and rereads one exact
file, then explicitly revokes the grant and closes its provider handle.

The native harness performs 128 additional successful transactions and asserts
for every one:

```text
open_fd_delta == 0
temp_entries == 0
partial_final_observed == 0
```

All pre-publish, post-publish, cleanup, read instability and replacement fault
stages remain green.

## 5. Full Verification

```text
lua tests/run.lua:                         80/80 suites green
staged repository-hand suites:            12 green / 1 route red / 13 total
repository_route internal controls:        5 green / 5 red (expected frontier)
strict C builds (-Wall -Wextra -Werror):   green
GCC -fanalyzer production provider:        green
GCC -fanalyzer full native test build:     green
ASan + UBSan full native battery:          green
LeakSanitizer:                             not claimed; disabled at ptrace boundary
git diff --check:                          green
```

The staged process still exits non-zero solely because autonomous repository
routing is intentionally absent. No 7.8 treatment changed pressure, router,
operator readiness or route tests.

## 6. What 7.8 Does Not Authorize

```text
automatic RUNTIME review
automatic LOGIC effect dispatch
automatic RUNTIME completion reconciliation
runner charging of effect economics
route or suite promotion
multi-file scheduling
overwrite, patch, delete, rename, mkdir, shell, commands, tests or git
```

## 7. Next Gate

Roadmap 7.9 may now promote only the hostile-demonstrated mechanism into the
normal regression surface and connect qualified repository routing in measured
increments. The known five red route controls are the next evidence frontier;
they must not be turned green by bypassing action review, LOGIC evidence or
RUNTIME rereading.
