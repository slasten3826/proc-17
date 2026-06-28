# ENCODE Operator Notes

Raw notes for `☵ ENCODE`.

This is not a table or crystal yet.
It records the current pressure after reading the old `packet-slop` Eva.00
encode work.

## First Correction

`☵ ENCODE` is not JSON encoding.

It is not serialization.

It is not merely compression.

Those are only low-level manifestations.

The operator invariant is closer to:

```text
raw pressure becomes transferable form
```

or:

```text
unformed material becomes a loss-bearing field that another operator can use
```

## First Invariant

`☵ ENCODE` turns observed material into a formed field.

Before ENCODE:

```text
raw observation
substrate text
repo listing
repo context
trace fragments
unsupported shape
```

After ENCODE:

```text
bounded field
items
kind
source truth
value
hierarchy
encoding basis
loss
```

The body must change when pressure passes through `☵`.

If no package-visible form, hierarchy, or loss appears, no real ENCODE
happened.

## Difference From OBSERVE

`☴ OBSERVE` sees.

`☵ ENCODE` makes what was seen portable.

OBSERVE can say:

```text
there are files
there is text
there is trace
there is an unsupported form
```

ENCODE should say:

```text
these are candidate items
this is their source
this is their shape
this is what was compressed away
this is what can be chosen from
```

Short form:

```text
☴ sees material
☵ forms material into a field
```

## Difference From CHOOSE

`☵ ENCODE` and `☳ CHOOSE` are adjacent but not the same.

`☵ ENCODE`:

```text
creates the possibility field
compresses raw material into items
records source and loss
preserves hierarchy
```

`☳ CHOOSE`:

```text
receives the possibility field
selects continuing branch
kills alternatives as active paths
records attention collapse
```

Short form:

```text
☵ makes the field
☳ collapses the field
```

Current `proc-17` already has a temporary leak:

```text
cli/procesis-body.lua builds candidate fields directly
```

That is useful scaffolding, but topologically wrong as final shape.

The field-building pressure belongs to `☵ ENCODE`.

## Difference From LOGIC

`☶ LOGIC` validates a formed proposal against a boundary.

`☵ ENCODE` does not validate truth.

It preserves source truth while changing shape.

Example:

```text
substrate line
  source_truth_status = semantic_proposal

encoded field item
  source_truth_status = semantic_proposal
  encoding_event_truth_status = runtime_confirmed
```

The encoding event can be runtime-confirmed.

The encoded content may remain semantic.

This boundary must hold, otherwise ENCODE becomes hidden belief.

## Packet-Slop Trace

The old Eva.00 encode core showed a stronger shape than a one-shot function.

There, ENCODE behaved as a long-lived process between:

```text
CHAOS / raw
CALM / form
```

It did not simply read raw and produce calm once.

It lived across ticks.

On each tick it could:

```text
hold hidden CONNECT
pull CHAOS
OBSERVE(raw)
CHOOSE(raw)
convert raw_mass into calm_mass
OBSERVE(calm)
CHOOSE(calm)
try RUNTIME gate
spend PU
possibly die before producing form
```

This is important.

It means mature ENCODE is not a pure mapper.

It is a form-building process that may fail.

## Hidden CONNECT

The strangest useful thing from `packet-slop`:

```text
ENCODE contains hidden CONNECT
```

This does not mean ENCODE replaces CONNECT.

It means any real encoding must maintain a relation between raw source and
emerging form.

Without that relation:

```text
raw source drifts away
calm form becomes arbitrary
encoding becomes hallucinated shape
```

So mature ENCODE has an internal tick:

```text
connect source to forming field
```

For `proc-17` v0 this may be much simpler:

```text
encoded item carries source reference / source truth / source kind
```

But the invariant is the same.

The formed item must remember what pressure it came from.

## Loss

ENCODE always loses.

Loss is not an error.

It is the price of transfer.

Possible ENCODE loss shapes:

```text
raw lines collapsed into one item
large repo listing reduced into bounded field
trace tail compressed into summary pressure
unsupported form preserved only as missing-shape residue
source detail omitted by limit
ordering introduced where raw material had no order
kind assigned where raw material was mixed
```

ENCODE loss differs from CHOOSE loss.

`☵` loss:

```text
loss from making form portable
```

`☳` loss:

```text
loss from making one branch continue
```

## Hierarchy

ENCODE creates hierarchy.

This is not optional.

Even a flat list has hidden hierarchy:

```text
field
  item
    id
    kind
    value
    source truth
```

Without hierarchy the body cannot pass material between operators.

But hierarchy is also dangerous:

```text
hierarchy can look more true than its source
```

Therefore every encoded item must keep source truth visible.

## V0 Shape For Proc-17

The first practical ENCODE in `proc-17` should probably be small and pure:

```text
logic/encode.lua
```

Possible function:

```text
encode(input) -> encoded_field_payload | nil, error
```

Possible input:

```text
observations
substrate_result
repo_listing
repo_context
trace_tail
limits
pressure
```

Possible output:

```text
kind = encoded_field_payload
field
encoding_basis
source_mix
hierarchy
loss
limits
truth_status = runtime_confirmed
```

This would move candidate-field construction out of the CLI and into an
operator-owned module.

## Current Route And Better Route

Current route:

```text
☴ observe repo listing / substrate response
cli builds candidate field
☳ choose from candidate field
☶ validate selected paths or semantic result
```

Better route:

```text
☴ observe repo listing / substrate response
☵ encode observations into candidate field
☳ choose from encoded field
☶ validate selected form
☱ read runtime pressure
```

This makes `☵` visible in the packet trace.

It also makes CHOOSE less magical because CHOOSE receives a formed field rather
than raw CLI ad hoc state.

## Mature Route

Longer-term ENCODE may become a process, not just a pure module.

Possible mature shape:

```text
encode_process
  source
  forming_field
  hidden_connect_state
  raw_observe_count
  raw_choose_count
  calm_observe_count
  calm_choose_count
  pu_spent
  coherence
  ready_for_runtime
  death_residue
```

That is not v0.

But the v0 module should not contradict it.

## Open Questions

```text
what minimum encoded field shape does CHOOSE need?
should ENCODE emit one field per observation source or one merged field?
how much source reference is enough for hidden CONNECT v0?
does ENCODE spend packet budget directly?
should ENCODE run before every CHOOSE by default?
can ENCODE encode unsupported forms into gap residue?
how should ENCODE distinguish source loss from hierarchy loss?
what makes an encoded field too lossy to pass to CHOOSE?
```

No table yet.
No crystal yet.
No code yet.
