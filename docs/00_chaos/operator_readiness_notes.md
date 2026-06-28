# Operator Readiness Notes

Raw current view of which ProcessLang operators have first working organs in
`proc-17`.

This is not a final capability map.
It is a checkpoint after the first eyes and first LOGIC validator.

## Current Working Operators

```text
▽ FLOW
☴ OBSERVE
☶ LOGIC
```

They are not complete operator realizations.
They are first working organs.

## ▽ FLOW

Current working shape:

```text
packet lifecycle
birth
trace events
operator_enter
mode_enter
budget_spend
manifest
death
residue
```

Meaning:

```text
the task now has mortal packet life
the body can record what happened
the body can end a packet instead of pretending continuation forever
```

Limits:

```text
no child packet execution yet
no automatic continuation loop
budget is simple
residue is still minimal
```

## ☴ OBSERVE

Current working organs:

```text
repo_listing_eye
repo_context_organ
```

Current working shape:

```text
repo_listing_eye
  sees bounded runtime-confirmed file tree
  emits repo_listing observation
  passes listing into substrate_call

repo_context_organ
  reads explicit files through fs/sandbox
  emits repo_context observation
  passes file contents into substrate_call
```

Meaning:

```text
the body can now see repository shape
the body can read selected file contents
the substrate no longer has to invent repo context from nothing
```

Limits:

```text
repo listing v0 uses internal find through io.popen
repo context still needs explicit selected files
no automatic file ranking
no directory summaries
no runtime-side memory eye yet
```

## ☶ LOGIC

Current working module:

```text
repo_selection_validator
```

Current working shape:

```text
accept repo_listing_payload
accept substrate selection text
extract candidate paths
accept listed files
reject absent paths
reject directories by default
preserve reasons as semantic_proposal
```

Meaning:

```text
the body can validate proposal shape before runtime contact
the body can distinguish valid path membership from semantic reasons
the body can prevent absent paths from reaching repo_context_organ
```

Limits:

```text
LOGIC does not validate file role
LOGIC does not validate dependency claims
LOGIC does not rank paths semantically
LOGIC does not replace sandbox
```

## Current Manual Loop

The pieces work separately:

```text
repo_listing_eye
  -> DeepSeek selection proposal
  -> repo_selection_validator
  -> repo_context_organ
```

But the full loop is still manual.

We currently run:

```text
1. CLI with --repo-list
2. read DeepSeek substrate_result
3. manually call logic/repo_selection.lua
4. manually inspect accepted/rejected paths
```

Next body growth should make this an internal packet route.

## Important Boundary

```text
LOGIC validates proposal before contact.
SANDBOX guards contact itself.
```

Do not collapse them.

For repo selection:

```text
LOGIC:
  path exists in runtime-confirmed listing
  path is file unless directories are explicitly allowed
  max_paths is not exceeded

SANDBOX:
  path is relative
  path has no parent traversal
  read/write/action is allowed
```

## Current Shape In One Line

```text
FLOW gives packet life;
OBSERVE gives repo sight;
LOGIC gives first dumb validation;
the loop between them is not automated yet.
```
