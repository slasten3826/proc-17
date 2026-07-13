# Grave Generation Bug Notes

Status:

```text
chaos
from Mythos/Fable generation experiment
bug found by integration run
```

## Bug

Karma warning route did not fire in the real generation experiment.

The unit test used a synthetic grave:

```text
last_operator = ☲
```

But real budget deaths in the loop land on:

```text
last_operator = ☱
```

The live walk:

```text
▽☴☵☴☳☴☱☲☱☲☱☲☱☲☱
```

Budget is charged after each tick, so exhaustion is observed at the runtime eye.

The router matched only `☲`, so real graves were attached but never applied.

## Lesson

Death fixtures must be grown by death.

Do not test grave learning only with hand-written graves.

The integration test must:

```text
run ancestor until real death
classify ancestor as grave
feed grave to descendant
verify descendant route changes
```

## Fix

Repeated cycle warning should match:

```text
last_operator == ☲
or
last_operator == ☱
```

`☲` means the dead pattern was recorded at cycle.

`☱` means the same dead pattern was observed at runtime after cycle.

Both describe the same two-pole loop:

```text
☱☲
```
