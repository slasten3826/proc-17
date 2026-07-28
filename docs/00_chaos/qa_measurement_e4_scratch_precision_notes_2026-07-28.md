# QA Measurement E4 Scratch Precision Notes

status: document_decision
date: 2026-07-28
scope: E4.4 scratch observer only
parents:
- `qa_measurement_e4_topology_audit_2026-07-28.md`
- `qa_hostile_execution_campaign_yellowprint.v0.md`
- `qa_hostile_execution_campaign.v0.md`

## 1. The missing bound

TABLE and CRYSTALL require the final scratch walker to reject depth overflow,
but neither document names the maximum depth. Leaving that value to the C
implementation would make a hidden implementation constant part of execution
physics.

Decision:

```text
PROC17_QA_SCRATCH_MAX_DEPTH = 64
```

The value is part of the isolation policy digest. It bounds observer work and
descriptor/stack use. It is not a candidate result field, a scratch-capacity
metric, or a terminal cause.

Depth zero is `/qa/scratch`. Direct children have depth one. The trusted
baseline directories `home` and `tmp` are excluded from `stored_entries`, but
their descendants are measured at their actual depth.

## 2. Baseline and final truth

Before RELEASE, the namespace controller pins `/qa/scratch` and records the
device, inode and mode of the root plus the exact empty `home` and `tmp`
directories. No other initial entry is allowed.

After exact candidate reap, the same controller walks from the pinned root
descriptor. It never follows links or crosses mounts. Replacement, mutation or
disappearance of a baseline object; a symlink or special object; excessive
depth/count/bytes; or an observation failure yields infrastructure ambiguity.

The final record reports candidate-created entries and logical regular-file
bytes. The trusted root, `home` and `tmp` are not candidate entries. Final
filesystem capacity flags come from `fstatvfs` on the pinned root and remain
post-terminal observations, not causal evidence for `scratch_limit`.

## 3. Wire projection

E4.4 provides a fixed 40-byte private projection for E4.5. Multi-byte integers
use the existing QA wire network byte order:

```text
0..7    stored_regular_bytes u64
8..15   stored_entries u64
16..23  limit_bytes u64
24..31  limit_entries u64
32      byte_capacity_exhausted 0|1
33      entry_capacity_exhausted 0|1
34      inventory_complete = 1
35..39  zero
```

The protocol tag remains owned by the enclosing controller report. Reserved
bytes, booleans and bounds are checked on decode.

## 4. Non-claim

E4.4 observes what survived. It does not observe the write that failed when a
tmpfs filled. Therefore it cannot emit `scratch_limit`; that remains reserved
for a future trusted causal write-denial hook.
