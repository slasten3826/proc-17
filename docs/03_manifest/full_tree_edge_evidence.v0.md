# Full Tree Edge Evidence v0

Status:

```text
runtime-confirmed local control corpus
date: 2026-07-16
policy: pressure.binary.v0 / vibed_control
authority: shadow only
substrate: fake
```

## Method

The control corpus merges two independently grown Packet lives:

```text
plan  mode, 8 ticks
build mode, 14 tick host ceiling; manifested after 9 ticks
```

Each transition has three distinct evidence levels:

```text
candidate  the shadow router audited the adjacent edge
committed  the authoritative router moved the Packet across it
executed   the destination organ completed its following tick
```

Only `executed` satisfies directional integration evidence. A transition left
pending at `tick_limit` is committed but not executed. Candidate or shadow
selection is not promoted into a grown witness.

## Edge Matrix

| Id | Edge | Runtime status | Directional coverage | Executed |
|---|---|---|---:|---:|
| E01 | `▽-☰` | untested | 0/1 | 0 |
| E02 | `▽-☷` | untested | 0/1 | 0 |
| E03 | `▽-☴` | observed live | 1/1 complete | 2 |
| E04 | `☰-☷` | untested | 0/2 | 0 |
| E05 | `☰-☴` | shadow selected | 0/2 | 0 |
| E06 | `☰-☵` | candidate only | 0/2 | 0 |
| E07 | `☷-☴` | candidate only | 0/2 | 0 |
| E08 | `☷-☳` | candidate only | 0/2 | 0 |
| E09 | `☴-☵` | observed live | 2/2 complete | 4 |
| E10 | `☴-☳` | observed live | 2/2 complete | 4 |
| E11 | `☴-☱` | observed live | 1/2 partial | 2 |
| E12 | `☵-☱` | shadow selected | 0/2 | 0 |
| E13 | `☵-☳` | candidate only | 0/2 | 0 |
| E14 | `☵-☲` | candidate only | 0/2 | 0 |
| E15 | `☳-☱` | shadow selected | 0/2 | 0 |
| E16 | `☳-☶` | candidate only | 0/2 | 0 |
| E17 | `☱-☶` | observed live | 2/2 complete | 2 |
| E18 | `☱-☲` | observed live | 2/2 complete | 2 |
| E19 | `☲-☶` | candidate only | 0/2 | 0 |
| E20 | `☱-△` | observed live | 1/1 complete | 1 |
| E21 | `☲-△` | candidate only | 0/1 | 0 |
| E22 | `☶-△` | candidate only | 0/1 | 0 |

Summary:

```text
complete directional coverage: 6 edges
partial directional coverage:  1 edge
no executed direction:        15 edges

observed live:    7
shadow selected:  3
candidate only:   9
not encountered:  3
```

## Eye Rail Matrix

| Rail | Cases | Eye debt | Shadow recalled eye | Shadow bypassed debt |
|---|---:|---:|---:|---:|
| `☵ -> ☴` | 2 | 2 | 0 | 2 |
| `☳ -> ☴` | 2 | 2 | 0 | 2 |
| `☲ -> ☱` | 1 | 1 | 1 | 0 |
| `☶ -> ☱` | 1 | 1 | 1 | 0 |

All four promotion records remain:

```text
insufficient_evidence
```

The lower freshness policy recreates both current lower-eye rails in this
corpus. The upper policy does not: after ENCODE and CHOOSE it sees genuine upper
eye debt but gives another target a larger total. These are unresolved bypass
proposals, not successful direct edges. Removing either upper rail now would be
an unsupported promotion.

## Next Evidence Pressure

The nearest useful witnesses are not all equal:

```text
E05, E12, E15  shadow already selects them; grow destination execution
E11             grow the reverse ☱ -> ☴ direction
E01, E02, E04  absent from this corpus; require dedicated FLOW/CONNECT/DISSOLVE lives
remaining rows  keep explicit until their organ inputs can be grown honestly
```

No DeepSeek or tree-authoritative run is part of this report. This is a control
measurement of body physics, not a claim that the complete Tree is ready.
