# Tension Runner Notes

The fixed runner proved that organs can be wired.

The tension runner should prove that the packet can move by routing pressure.

Name:

```text
runtime/tension_runner.lua
```

Why tension:

```text
packet moves by tension
not by hardcoded pipeline
```

## Difference From Smoke Runner

Smoke runner:

```text
▽ -> ☴ -> ☵ -> ☳ -> ☲ -> △
```

Tension runner:

```text
start with ☴
run current operator
ask router.after_tick
run returned operator
repeat until △ or tick limit
```

## First Route Expected

With fake substrate:

```text
☴ -> ☵ -> ☴ -> ☳ -> ☴ -> ☱ -> ☲ -> ☱ -> ...
```

The final `...` is expected because no real work executor exists yet.

`☲` can see remaining work, but nothing marks the work done.

So v0 tension runner should stop by tick limit, not by fake completion.

This is correct.

## Important Router Detail

After `☳`, the required tick is `☴`.

But after `☳ -> ☴`, the upper eye should not blindly route back to `☳`.

A choice has already happened.

If no new encoding or choice pressure appears, `☴` may route to `☱`.

This means:

```text
☳ -> ☴ -> ☱
```

is a valid v0 shape.

## Non-goal

Do not make tension runner execute real work yet.

Do not mark work units done artificially.

Do not write files.

Do not integrate sandbox mutation.

The first test is movement, not productivity.
