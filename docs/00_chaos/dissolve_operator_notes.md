# DISSOLVE Operator Notes

Raw notes for `☷ DISSOLVE`.

This is not a table or crystal yet.
It records the current understanding after comparing `proc-17` with older
packet bodies.

## First Correction

`☷ DISSOLVE` is not simple deletion.

Deletion is too crude.

The stronger invariant:

```text
DISSOLVE removes false form as active truth while preserving useful residue
```

or:

```text
DISSOLVE weakens stale pressure so the body can continue without carrying false body
```

## First Invariant

Before DISSOLVE:

```text
false claim may still look formed
stale route may still have pressure
unsupported form may pretend to be fact
noise may be mixed with useful signal
```

After DISSOLVE:

```text
false factual status is removed
stale relation is weakened
noise pressure is reduced
residue may remain if shape is diagnostically useful
```

If nothing is weakened, removed, or re-statused, no real DISSOLVE happened.

## Difference From LOGIC

`☶ LOGIC` validates or rejects at a boundary.

`☷ DISSOLVE` changes the status and pressure of what failed.

Example:

```text
substrate says:
  packet.promote_gap exists

LOGIC:
  method does not exist

DISSOLVE:
  remove factual status
  keep missing-shape residue:
    substrate wants gap-promotion route
```

Short form:

```text
☶ says no
☷ removes the false body of the claim
```

## Difference From CHOOSE

`☳ CHOOSE` kills alternatives because one branch continues.

`☷ DISSOLVE` weakens or removes a formed pressure because it cannot keep its
current status.

CHOOSE loss:

```text
unchosen possibilities no longer continue
```

DISSOLVE loss:

```text
false/stale/noisy form no longer holds its old shape
```

They can meet, but they are not the same.

## Difference From ENCODE

`☵ ENCODE` is not directly adjacent to `☷` in current topology.

So DISSOLVE should not be hidden inside ENCODE.

The better reading:

```text
☷ prepares by subtraction
☵ later encodes what remains or what residue was produced
```

Routes can be indirect:

```text
☷ -> ☴ -> ☵
☷ -> ☰ -> ☵
☷ -> ☳ -> ☵
```

This matters because ENCODE should not secretly own every cleanup operation.

## Packet-Slop Trace

In older packet work, DISSOLVE appeared in several forms.

In L1 chaos:

```text
each tick mutates the substrate
instruction/state does not survive execution unchanged
trace is rewritten, not archived
stable ready-made memory inside chaos is forbidden
```

In neural L2-like stands:

```text
activation decays
weak routes lose pressure
noise is reduced before stable form can appear
```

In Eva encode core, a DISSOLVE-like effect appeared as raw cleanup:

```text
raw_mass is reduced when noisy or excessive
raw_noise is damped
weak calm candidates lose mass
```

These should not be copied literally into `proc-17`.

But they clarify the invariant:

```text
DISSOLVE is active weakening and status removal, not trash collection
```

## Proc-17 Form

`proc-17` current medium is not a neural field.

Its dissolvable material is:

```text
semantic proposal
unsupported form
invalid path
unsupported reason
stale trace pressure
repeated but unconfirmed claim
dead branch after choice
```

First package-visible DISSOLVE may look like:

```text
dissolved = {
  target,
  old_status,
  new_status,
  dissolve_reason,
  residue,
  pressure_after
}
```

Possible new statuses:

```text
false_as_fact
unsupported_residue
stale
decayed
rejected
```

This does not require a separate CLI organ immediately.

It may first appear in LOGIC/unsupported-form handling as explicit status
removal.

## Unsupported Form Route

Important route:

```text
☴ OBSERVE
  captures emitted form

☶ LOGIC
  checks against runtime truth

☷ DISSOLVE
  removes factual status

☵ ENCODE
  later preserves missing-shape residue if useful

☳ CHOOSE
  reject / defer / promote
```

The key is not to throw away everything.

False fact can die.

Shape pressure can remain.

## What DISSOLVE Must Not Become

DISSOLVE must not become:

```text
delete all inconvenient evidence
silence substrate drift without residue
hide validation failures
rewrite history
pretend rejection never happened
```

DISSOLVE should make the trace clearer, not cleaner-looking.

## Open Questions

```text
does DISSOLVE need its own module in proc-17 v0?
or should first DISSOLVE live inside unsupported-form status handling?
what is the smallest useful dissolved payload?
how long should unsupported residue live?
when does residue decay completely?
can DISSOLVE weaken a CONNECT relation without deleting it?
how does DISSOLVE interact with CHOOSE killed alternatives?
```

No table yet.
No crystal yet.
No code yet.
