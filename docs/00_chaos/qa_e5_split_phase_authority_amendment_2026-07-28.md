# QA E5 Split Phase Authority Amendment

date: 2026-07-28
status: document_decision; pre-E5.1 precision repair
scope: STARTED writer state versus controller phase state
found_by: first production composition of E3 and E4

## 1. Defect

The candidate prelude is the sole writer of public `STARTED`, while the
namespace controller is the sole writer of first cause, release authority and
the private terminal report. They are different processes.

The initial E3 API used one process-local `proc17_qa_phase_state` for both:

```text
emit STARTED and mark started_emitted
authorize candidate only if started_emitted
```

That works in the unit test because one process plays both roles. After the
real `fork()`, the controller cannot observe mutation of the candidate's local
copy. Sharing the state would violate HE29 and create a second cross-process
mutable truth surface.

## 2. Decision

Split the state by actor:

```text
candidate STARTED writer state
  guards one exact public write and descriptor close
  dies in the candidate prelude

controller phase state
  observes exact private READY(1)
  records started_attested from that protocol fact
  arms the candidate wall timer
  authorizes RELEASE(2)
  owns first cause and local finality
```

The status decoder is the named reader that may promote an exact validated
`READY(1)` into controller `started_attested`. Arbitrary caller assertion may
not perform that transition.

## 3. Why READY is sufficient controller evidence

The trusted candidate prelude has one fixed order:

```text
exact public STARTED write
close public descriptor
exact private READY(1)
block for RELEASE(2)
```

It cannot send READY before the successful write and close. READY therefore
attests the completed candidate-side transition to the controller. It does not
replace the public STARTED witness: the launcher independently reads and joins
that frame using the same identity and private process token.

If one channel succeeds and the other is lost, no candidate result is legal:
the controller or launcher emits/derives infrastructure failure.

## 4. Forbidden alternatives

```text
shared mutable phase state
controller directly setting candidate-emitted fields
READY treated as the public STARTED frame
RELEASE before timer arm
launcher accepting RESULT without its own STARTED observation
```

## 5. Falsifiers

```text
one process-local object is still required to both emit and observe STARTED
controller authorization succeeds without exact READY(1)
duplicate READY is accepted
candidate writer can emit STARTED twice
controller READY observation grants RELEASE before the timer is armed
public STARTED absence can still normalize as a candidate RESULT
```

This is a precision repair to the E3/E4 join. It changes no public wire layout,
truth status, process topology, first-cause law or production authority by
itself.
