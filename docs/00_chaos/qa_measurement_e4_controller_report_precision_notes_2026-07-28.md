# QA Measurement E4 Controller Report Precision Notes

status: document_decision
date: 2026-07-28
scope: E4.5 private controller report and top-level finality join
parents:
- `qa_measurement_e4_topology_audit_2026-07-28.md`
- `qa_measurement_e4_status_amendment_cross_audit_2026-07-28.md`
- `qa_hostile_execution_campaign.v0.md`

## 1. Missing shape

The accepted topology names a fixed private controller report but does not
define its bytes. Implementing that phrase directly would hide a new protocol
inside C and leave the top-level supervisor unable to prove exactly what it
validated.

This note closes that gap. The report is private evidence, not a fifth public
QA wire kind and not a second mutable ledger.

## 2. Exact private record

The report is exactly 572 bytes and fits one atomic pipe write:

```text
0..7      magic = "P17QACR\0"
8..9      version = 1
10..11    record_bytes = 572
12..15    zero
16..143   transaction/witness/profile/environment identity join
144..175  private candidate process token
176..177  reason
178..179  termination kind
180..183  exit code
184..187  signal
188..189  first-cause kind (must equal reason)
190..191  zero
192..199  first-cause monotonic sequence
200..207  first-cause observed value
208..214  first seven finality booleans
215       private status EOF observed
216       allocator telemetry observation stable
217       HEAP_DENIED packet count (0 or 1)
218       system-allocation-failed sticky flag
219       status-notification-failed sticky flag
220..223  zero
224..231  allocator current reservation bytes after reap
232..295  stdout measurement v1
296..359  stderr measurement v1
360..447  resource measurement v1
448..487  scratch measurement v1
488..571  source-stage summary v1
```

All multi-byte integers use the existing QA wire network byte order. The
private process token binds this report to the exact STARTED/READY/RELEASE
conversation without exposing the token to Lua.

## 3. Two-stage finality

The namespace controller may build the record only when:

```text
STARTED was emitted and closed before RELEASE;
candidate release was authorized;
first cause is immutable and complete;
source-staged through scratch-observed finality members are all true;
namespace-clean finality is still false;
private status EOF is observed;
allocator telemetry is stable after candidate reap;
HEAP_DENIED packet count and allocator denial flag agree;
allocator current/peak/ceiling and sticky failure flags agree;
all measurement records are exact and internally consistent.
```

The top-level supervisor accepts the record only after exact successful reap of
the namespace controller, exact identity/token match and completed namespace
cleanup. It then copies the seven local finality facts, writes the eighth fact
it owns, and assembles the existing 512-byte public RESULT payload. It does not
re-derive or rewrite the first cause.

## 4. Suppression law

Malformed, partial, mismatched or contradictory private evidence produces no
candidate result. In particular:

```text
missing status EOF;
unstable allocator observation;
notification/page disagreement;
two HEAP_DENIED records;
missing local finality;
controller abnormal exit;
identity or token mismatch;
measurement/reason contradiction
```

all suppress public RESULT and become infrastructure ambiguity in the later E5
authority path.

An observed in-budget host allocator failure also suppresses candidate RESULT.
E4.5 chooses the infrastructure branch permitted by the earlier allocator
amendment; it never hides that host fact inside `unexpected_exit`.

## 5. Authority

E4.5 only builds and tests this join. The module is production-linked but RUN
v0 remains routed. Public STARTED/RESULT/ERROR sequencing remains E5.
