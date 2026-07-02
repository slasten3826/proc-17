# Packet Will Routing Notes

Current runner route:

```text
▽ -> ☴ -> ☵ -> ☳ -> ☲ -> △
```

This route is manual.

It is useful as smoke rail, but it is not packet will.

## Core Thought

The packet should not move through a fixed pipeline.

The packet should move by pressure.

After an operator runs, packet density changes.

That density should throw the packet toward the next operator with the most
relevant pressure.

This pressure-routing is the first technical shape of will.

Not human free will.

Packet will:

```text
state changes
pressure appears
eye reads pressure
next operator is selected
```

## Two Eyes

`☴` is the upper eye.

It looks toward chaos, raw meaning, semantic uncertainty, unresolved shape.

`☱` is the lower eye.

It looks toward runtime, body state, budgets, validation, continuation,
manifest readiness.

They should speak a compatible pressure language, but they look in opposite
directions.

## Upper Tree Routing

Upper operators should not move blindly into each other.

After upper pressure changes, `☴` should observe.

Rough rule:

```text
▽ -> ☴
☰ -> ☴
☷ -> ☴
☵ -> ☴ when semantic/chaos pressure remains
☳ -> ☴ when choice changed semantic pressure
```

So this is not preferred:

```text
▽ -> ☰
```

Preferred shape:

```text
▽ -> ☴ -> ☰
```

And later:

```text
▽ -> ☴ -> ☰ -> ☴ -> ☵ -> ☴ -> ☳
```

`☴` prevents upper-tree drift by forcing the packet to look again after each
semantic transformation.

## Lower Tree Routing

Lower operators should not move blindly into each other either.

They should pass through `☱` because lower pressure is runtime pressure.

Not preferred:

```text
☲ -> ☶ -> ☲ -> ☶ -> ☲
```

Preferred shape:

```text
☲ -> ☱ -> ☶ -> ☱ -> ☲
```

But the route should not repeat uselessly.

If `☶` did not change, then:

```text
☲ -> ☱ -> ☶ -> ☱ -> ☲
```

may be wasteful after the first validation.

`☱` should see that logic pressure did not change and avoid sending the packet
back into the same validator without new evidence.

## Bridge Operators

`☵` and `☳` are bridge operators.

They connect to both eyes.

For now, the important upper rule is:

```text
☵ -> ☴
☳ -> ☴
```

because encoding and choosing mutate semantic shape.

Later, the lower compatibility must be designed:

```text
☵ -> ☱
☳ -> ☱
```

That is postponed.

## Routing Policy v0 Pressure

New working rule:

```text
after ☵ -> tick ☴
after ☳ -> tick ☴
```

`☵` and `☳` should not directly route themselves into lower-tree operators.

They mutate semantic shape.

So after each `☵` or `☳`, the upper eye must look.

Then `☴` may route the packet toward:

```text
☵
☳
☱
```

Meaning:

```text
☴ -> ☵ when more encoding pressure remains
☴ -> ☳ when choice pressure is visible
☴ -> ☱ when semantic shape is stable enough to check runtime pressure
```

Lower side working rule:

```text
after ☲ -> tick ☱
after ☶ -> tick ☱
```

`☲` and `☶` should not directly bounce between each other.

They mutate runtime/continuation/validation pressure.

So after each `☲` or `☶`, the lower eye must look.

Then `☱` may route the packet toward:

```text
☲
☶
☴
△
```

Meaning:

```text
☱ -> ☲ when continuation pressure remains
☱ -> ☶ when validation pressure remains
☱ -> ☴ when runtime pressure exposes new semantic uncertainty
☱ -> △ when the packet is ready to manifest or cannot continue
```

Budget/loss reaching zero may be one reason for `☱ -> △`, but this still needs
clarification. It may be too early to make it the only rule.

For now, the important implementation direction is:

```text
☵ and ☳ tick only into ☴
☲ and ☶ tick only into ☱
☴ decides among ☵/☳/☱
☱ decides among ☲/☶/☴/△
```

There may be a deeper future layer:

```text
☵ <-> ☲
☳ <-> ☶
```

Encoding/cycle and choice/logic may mirror each other across the tree.

Do not implement this now.

Keep it as future pressure.

## Loss And Budget Are Different

`loss` belongs to the packet.

`budget` belongs to the substrate/runtime.

They are not the same pressure.

Loss:

```text
packet physical limit
semantic/body degradation
when loss is exhausted, packet dies
```

Budget:

```text
runtime/resource limit
tokens
time
money
compute
tool calls
wall-clock pressure
```

In ideal conditions, budget would not matter.

In real substrate conditions, budget matters because substrates cost time,
tokens, power, money, latency, and attention.

But budget does not directly create packet loss.

And packet loss does not directly spend substrate budget.

They may correlate in real implementations, but they are not the same axis.

## Lower Triangle Cycle

The lower triangle must remember `△`.

Example:

```text
☱ -> ☲ -> ☱ -> △
```

This can happen when runtime sees that continuation has reached a manifest
trigger.

Manifest trigger examples:

```text
target count reached
target size reached
target time reached
validation passed
shape is stable
budget cannot pay another turn
loss is near death
```

`☲` is cheap because it does not decide.

It only says:

```text
continue again
or stop condition visible
```

Example:

```text
procedural generation
cellular automaton
world generation
bounded simulation
```

If runtime sends a function into cycle "until trigger", cycle can keep saying:

```text
again
again
again
```

The function itself may stay simple.

Complexity does not have to grow geometrically.

The token budget of an LLM substrate may grow, but that is substrate budget,
not packet loss.

So:

```text
loss death = packet physics
budget exhaustion = runtime economics
```

Both may send the packet toward `△`, but for different reasons.

## Cycle Role

`☲` should not decide the whole route.

`☲` should say whether continuation pressure remains.

Example:

```text
work needed: 5
work done: 1
☲ says: again
```

But `☲` should not decide which organ runs next.

The next operator belongs to routing pressure.

## Future Shape

Future runner should look more like:

```text
operator runs
packet changes
☴ or ☱ reads pressure
router chooses next operator
repeat until packet dies or manifests
```

The smoke runner is still valid as a test rail.

But the real body must become pressure-routed.
