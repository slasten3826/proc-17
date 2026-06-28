# Substrate Spec

The substrate is replaceable LLM current.

The body must not depend on one model provider for identity, memory, routing, or task lifecycle.

## Adapter Contract

```text
ask(messages, options) -> response
stream(messages, options) -> events
capabilities() -> capability_map
```

## Capability Map

```text
provider
model
context_window
tool_calling
json_mode
vision
streaming
latency_class
cost_class
coding_strength
reasoning_strength
known_failure_modes
```

## Rule

Substrate output is proposal, not truth.

The body validates:

```text
topology
tool permissions
file existence
test results
diff scope
user intent
packet budget
```

## Initial Substrates

```text
openai
anthropic
deepseek
grok
kimi
local
```

Implementation order is not decided yet.
