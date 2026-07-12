# Loss Visibility Between Encode And Logic Notes

Status:

```text
chaos
new pressure
source: DeepSeek pressure probe through proc-17
```

## Trigger

DeepSeek was asked through proc-17 where development pressure is highest.

Both `plan` and `build` runs pointed to the same gap:

```text
☵ ENCODE records aggregate loss
☶ LOGIC validates remaining form
but ☶ cannot inspect what ☵ actually lost
```

Current loss is visible as numbers:

```text
input_count
output_count
omitted_count
truncated
encoding_type
loss_percentage
loss_level
```

This is useful, but not enough.

It says:

```text
loss happened
```

It does not yet say:

```text
what was lost
why it was lost
whether later logic needed it
```

## Core Pressure

If `☵` drops or compresses material, `☶` must be able to see that wound.

Otherwise the body can validate a clean-looking field that is already damaged.

Bad shape:

```text
raw chaos: a b c
☵ output: a b
☶ validates: a b is valid
lost c: invisible
```

Better shape:

```text
raw chaos: a b c
☵ output: a b
☵ loss_log: c omitted because max_items
☶ validates: a b valid, but loss verdict visible
```

The first goal is not recovery.

The first goal is visibility.

## Non-Goal

Do not build loss recovery yet.

Do not re-ask the substrate for missing material.

Do not route on loss verdict yet.

The next useful machine is smaller:

```text
☵ writes addressable loss_log
☶ runs one deterministic spell over loss
trace records verdict
```

## Why This Matters

`☵` is the first operation that creates machine-usable structure.

That creation has cost.

If cost is only summarized, later organs can pretend the field is complete.

proc-17 should not pretend.

It should be able to say:

```text
this field is valid under current loss
this field is structurally damaged
this field crossed tolerance
```

## Smallest Experiment

Add one visible field:

```text
loss_log
```

Add one spell:

```text
loss_threshold
```

The spell should not mutate the route.

It should only return runtime-confirmed verdict:

```text
acceptable | unacceptable
```

Evidence of success:

```text
same input + same limits -> same loss verdict
truncated encode -> loss_log has records
loss_threshold accepts below tolerance
loss_threshold rejects above tolerance
verdict is recorded in trace/runtime validation
```
