# Logic Validator Notes

Raw notes on the emerging role of LOGIC in `proc-17`.

## Trigger

After repo listing tests, the next missing shape was not another eye.

The body already had:

```text
repo_listing_eye
  sees file tree

repo_context_organ
  reads selected files
```

The gap was between them:

```text
substrate proposes selected paths
body needs to decide what can move forward
```

This is LOGIC.

## Important Distinction

LOGIC is not sandbox.

```text
LOGIC
  validates proposal shape before contact

SANDBOX
  guards host contact itself
```

For repo selection:

```text
LOGIC checks:
  path exists in runtime-confirmed repo_listing
  path is file unless directory mode is explicit
  max path count is not exceeded

SANDBOX checks:
  path is relative
  path has no parent traversal
  read/write/action is allowed by runtime policy
```

Do not collapse these.

If LOGIC becomes sandbox, it becomes too dangerous and host-facing.
If sandbox becomes LOGIC, it becomes too semantic and too smart.

## Tupid Validator

The first LOGIC validators should be intentionally stupid.

They should not:

```text
infer meaning
rank files semantically
prove roles
prove dependency claims
understand architecture
```

They should:

```text
check membership
check kind
check limits
mark accepted/rejected
preserve reasons as semantic_proposal
```

## Pattern

Expected common pattern:

```text
substrate proposes
LOGIC validates structure
RUNTIME/SANDBOX executes or rejects contact
tool_result becomes runtime_confirmed
```

This should later apply to:

```text
file selections
tool calls
file edits
test commands
patches
possibly phantom spawning
```

The current concrete instance:

```text
repo_selection_validator
```
