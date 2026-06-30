# Plan Build Mode Probe Run 2026-06-30

Status: captured, not interpreted.

This directory stores the first live plan/build probe run through proc-17 body.

## Run Shape

- substrate: DeepSeek through `cli/procesis-body.lua`
- probes: 30
- modes: `plan`, `build`
- total DeepSeek calls: 60
- output format: JSONL stdout plus JSONL trace files
- stderr: empty after final run

Files per probe:

```text
plan/<id>.trace.jsonl
plan/<id>.stdout.jsonl
plan/<id>.stderr.txt

build/<id>.trace.jsonl
build/<id>.stdout.jsonl
build/<id>.stderr.txt
```

## Mode Verification

Plan mode:

```text
hint_pressure.enabled = false
hint_pressure.reason = work_mode_plan
hint_pressure.hint_count = 0
```

Build mode:

```text
hint_pressure.enabled = true
hint_pressure.reason = work_mode_build
hint_pressure.hint_count = 32
```

## Probe Source

```text
docs/00_chaos/plan_build_mode_probe_battery.md
```

## Probe IDs

Mode probes:

```text
p01 p02 p03 p04 p05
p06 p07 p08 p09 p10
p11 p12 p13 p14 p15
p16 p17 p18 p19 p20
```

Will probes:

```text
w01 w02 w03 w04 w05
```

Regime conflict probes:

```text
r01 r02 r03 r04 r05
```

## Read Rule

Analyze by comparing the same probe across:

```text
plan/<id>.stdout.jsonl
build/<id>.stdout.jsonl
```

Do not judge only by answer beauty.

Check:

```text
does plan preserve uncertainty?
does build manifest honestly?
does build fabricate?
does plan stall unnecessarily?
does either mode expose residue?
does either mode change operator pressure?
```
