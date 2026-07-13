# Mortality Test Battery Notes

Status:

```text
chaos
test pressure
```

## Goal

Test the new packet mortality layer.

This battery does not test whether proc-17 gives a good answer.

It tests whether the packet:

```text
pays for motion
dies when budget is exhausted
dies when identity loss is exhausted
does not confuse host tick limit with packet death
leaves residue
keeps budget and loss separate
```

## Local Battery

Runs without network.

Use fake substrates.

Cases:

```text
small_steps_loop
substrate_call_limit
token_limit_with_usage
host_guard_not_death
choose_identity_loss
cycle_does_not_create_loss
budget_residue_shape
identity_residue_shape
```

This should be stable enough to run often.

## DeepSeek Battery

Runs with network/API budget.

Use only when intentionally testing live substrate economics.

Cases:

```text
deepseek_plan_low_step_budget
deepseek_build_token_visibility
same_task_low_vs_high_budget
```

The DeepSeek battery should record:

```text
packet_id
stop_reason
death cause
trace
steps spent
substrate calls spent
prompt/completion/total tokens if provider returns usage
estimated tokens if usage is missing
residue
```

Do not put DeepSeek battery into `tests/run.lua`.

It spends external budget.
