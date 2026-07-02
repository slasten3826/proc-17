# Packet Routing Yellowprint v0

Source chaos:

```text
docs/00_chaos/packet_will_routing_notes.md
```

Goal:

```text
replace fixed runner rail with pressure-routed packet movement
```

This is not implemented yet.

## Axes

Packet has at least two independent pressure axes:

```text
loss
budget
```

`loss`:

```text
belongs to packet
physical/semantic/body degradation
ending means packet death
```

`budget`:

```text
belongs to runtime/substrate
tokens/time/money/compute/tool calls
ending means runtime cannot or should not pay for another turn
```

Do not merge them.

Do not make budget directly change loss.

Do not make loss directly spend budget.

## Eyes

`☴`:

```text
upper eye
reads chaos/semantic pressure
routes upper and bridge pressure
```

`☱`:

```text
lower eye
reads runtime/body pressure
routes lower and manifest pressure
```

Both eyes should speak a compatible pressure language.

They do not look at the same side of the packet.

## Tick Rules v0

Mandatory eye ticks:

```text
☵ -> ☴
☳ -> ☴
☲ -> ☱
☶ -> ☱
```

`☵` and `☳` tick only into `☴` in v0.

`☲` and `☶` tick only into `☱` in v0.

## Eye Routing v0

`☴` may route toward:

```text
☵
☳
☱
```

`☱` may route toward:

```text
☲
☶
☴
△
```

## Meaning

`☴ -> ☵`:

```text
more encoding pressure remains
```

`☴ -> ☳`:

```text
choice/collapse pressure is visible
```

`☴ -> ☱`:

```text
semantic shape is stable enough for runtime pressure
```

`☱ -> ☲`:

```text
continuation pressure remains
```

`☱ -> ☶`:

```text
validation/rule pressure remains
```

`☱ -> ☴`:

```text
runtime pressure exposed new semantic uncertainty
```

`☱ -> △`:

```text
manifest trigger reached
or packet cannot continue
```

## Manifest Triggers

Candidate trigger set:

```text
target count reached
target size reached
target time reached
validation passed
shape is stable
budget cannot pay another turn
loss is near death
```

These triggers are not equivalent.

`loss near death` is packet physics.

`budget cannot pay` is runtime economics.

## Non-goals

Do not implement deeper mirror routes yet:

```text
☵ <-> ☲
☳ <-> ☶
```

Do not add anti-loop hacks.

Loops must be controlled by real pressure:

```text
☵ is expensive in loss
☲ is cheap but does not decide
☱ decides whether another cycle is meaningful
△ is available in the lower triangle
```
