# Cycle Netzach Progress Notes

Raw expansion for `☲ CYCLE` after rereading the Netzach section from
`slop.raw.txt`.

## Source Pressure

Netzach is not intelligence.

Netzach is not planning.

Netzach is the pressure of:

```text
again
more
continue
not finished
```

After `☳ CHOOSE` cuts alternatives, `☲ CYCLE` appears as the refusal to stop
while a payable unfinished form remains.

## Correction

The first `☲` implementation treated continuation as:

```text
accepted_count > 0
new_input_count > 0
budget remains
no repeated fingerprint
```

That was useful for the first repo-context loop, but it is not the deeper
shape.

The deeper shape is progress:

```text
needed = N
done = M

if M < N:
  again

if M == N:
  stop_complete
```

`☲` should not discover `needed`.

`☲` should not verify `done`.

`☲` should not choose which remaining part comes next.

Those pressures belong elsewhere:

```text
☱ RUNTIME counts progress
☶ LOGIC validates the count
☳ CHOOSE selects a branch when there are alternatives
☲ CYCLE only decides continuation from counted pressure
```

## Loss

`☲` should spend almost no semantic loss.

It does not transform meaning.

It does not compress.

It does not kill alternatives.

It only preserves the same unfinished form across another turn.

Therefore:

```text
semantic_loss ~= 0
runtime_cost > 0
```

Every cycle still costs time, budget, trace space, and substrate opportunity.

So the cycle is cheap in meaning, but never free in runtime.

## Desired Contract

Input pressure:

```text
progress:
  goal
  needed_count
  done_count
  remaining_count
  logic_status
```

Decision:

```text
if unsafe:
  stop_unsafe

if needs_user_input:
  needs_user_input

if budget cannot pay:
  stop_budget

if repeated state or max turns:
  stop_repetition

if progress logic is rejected:
  stop_invalid

if remaining_count > 0:
  again

if remaining_count == 0:
  stop_complete
```

The old `accepted_count/new_input_count` route remains valid as a legacy
first-loop shape.

## Boundary

If `☲` starts adding new tasks, changing goals, interpreting user intent, or
choosing the next organ, it is no longer `☲`.

It has become a hidden agent.

The correct `☲` is a valve:

```text
payable unfinished pressure -> again
finished or blocked pressure -> stop
```

