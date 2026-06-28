# Sandbox Policy Notes

Raw idea: `proc-17` needs a sandbox/policy layer before it becomes a real coding
body.

This should inherit the old planGOD safety instinct:

```text
default: nothing is allowed
permission must be explicit
safety first
```

The current fs tool already has local guards:

```text
absolute paths denied
parent traversal denied
write_file checks mode path policy
```

But this is not enough.

The rule should not live only inside individual tools.
The body needs a central permission layer below tool facade and above host.

## Desired Shape

```text
packet -> tool facade -> sandbox policy -> host
```

The substrate never calls host directly.

The tool facade never mutates host without policy approval.

## Default Deny

Start from:

```text
read: denied
write: denied
shell: denied
network: denied
git: denied
delete: denied
```

Then allow only specific capabilities.

## Permission Inputs

Policy decision should depend on:

```text
packet mode
tool action
path
operation kind
budget
user approval state
workspace root
```

Later it can also depend on:

```text
risk class
file ownership
git state
diff size
test state
```

## First Practical Policy

For now:

```text
relative paths only
no ..
no absolute paths
read workspace files allowed
write allowed only by body mode path policy
shell denied
network only through substrate adapters
delete denied
```

This is enough for first safe body movement.

## Why It Matters

Without sandbox, LLM pressure can become host mutation too easily.

With sandbox, even if substrate emits a bad action:

```text
semantic proposal -> tool call -> policy denial -> trace residue
```

The denial becomes runtime truth.

