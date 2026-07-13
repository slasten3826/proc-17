# Session Grave Scope Notes

Status:

```text
chaos
correction from operator
```

## Correction

Each session has its own grave.

Default run creates a fresh session with an empty grave.

This is stronger than a global cemetery plus a session index.

## Why

If grave is global, one task can poison another task.

That breaks the whole point of session boundary.

The body should not inherit death from an unrelated room.

## Shape

```text
session
  packet lineage
  local grave
    warnings
    bequests
    neutral
```

The grave belongs to the session, not to the whole repo.

The packet receives graves only from its current session.

## Default

```text
no explicit session -> create fresh session
fresh session -> grave = empty
empty grave -> no inherited graves enter packet
```

This keeps clean work clean.

## Consequence

The next memory layer should not search all saved packet capsules.

It should first load the current session.

Then it should use only:

```text
session.grave
```

for inherited grave pressure.

## Boundary

Session grave is not router logic.

Session grave is not LLM memory.

Session grave is storage and scope.

Router only sees graves after birth, when the runner attaches them to the packet.
