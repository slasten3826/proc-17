# Substrate Adapters Blueprint v0

Substrate adapters normalize external model providers into packet protocol.

## Primary Rule

Substrate output is not runtime truth.

Default truth status:

```text
semantic_proposal
```

Promotion to runtime truth must happen outside the substrate adapter.

## Current Adapters

```text
substrates/fake.lua
  deterministic fake substrate for tests

substrates/openai_compatible.lua
  generic OpenAI-compatible chat/completions adapter

substrates/deepseek.lua
  DeepSeek adapter using OpenAI-compatible layer
```

## Normalized Response

Every adapter should return:

```text
text
reasoning_text
tool_intents
usage
latency
provider_metadata
raw
```

`raw` may be retained for trace/debug.

## DeepSeek Contract

DeepSeek uses:

```text
DEEPSEEK_API_KEY
https://api.deepseek.com
model: deepseek-chat
```

Current verified behavior:

```text
CLI command reaches provider
HTTP 200 response is parsed
assistant content is normalized into text
actual provider model is stored in provider_metadata.actual_model
packet stores result as semantic_proposal
```

Test status:

```text
unit_test: substrate sample normalization
manual_check: real DeepSeek smoke via CLI
```
