# proc-17 Self-Ingestion Results

```text
layer: CHAOS
date: 2026-07-27
subject: proc-17 reading its manifested architecture through its public CLI
raw semantic artifact: proc17_self_audit_raw_2026-07-27.json
```

## Corpus

The external harness assembled one architecture corpus without test source,
fixtures, sandbox data, binaries or git history.

```text
README
v0 release-closure decision
packet_body_physics.v0 crystall
operator_tree_physics.v0 crystall
all 16 current MANIFEST files
inventory of 96 production Lua modules
bytes: 208451 for the final plan request
local estimated tokens: 52113
```

The complete CRYSTALL layer plus MANIFEST was not sent because it exceeds one
DeepSeek context when rendered as one task. The MANIFEST layer was used as the
complete current architecture projection; two foundational crystall contracts
were included without summarization.

## Plan Lives

The first public plan life consumed 47376 prompt tokens and returned one item:

```text
audit the supplied architecture corpus and return a structured JSON proposal
```

The second plan life explicitly required item values to contain the audit
itself. It consumed 47453 prompt tokens and still returned five future actions
describing how to perform the audit.

Both Packets died `complete`. This is evidence that machine CLI plan mode is a
`work_sequence` producer, not an analytical document-output mode. The semantic
substrate followed that receiver shape more strongly than the request to place
finished analysis inside item values.

## Build Lives

The accepted plan was then passed to public build mode in an isolated empty
repository without naming a documentation layer or output file.

The first build generated 4418 completion tokens but died `effect_failure`:

```text
provider code: parent_missing
provider stage: open_parent
file_writes: 0
repository remained empty
```

The substrate selected a nested path. The body correctly refused because CLI
v0 grants no `mkdir`, but the CLI receiver contract had failed to state that
constraint. The adapter was narrowed to require one root-level basename and a
regression control was added.

The repeated build completed:

```text
artifact: proc17_self_audit.json
bytes: 12849
sha256: 3a7709fd60dc86f16e0d7fa214007eb0f3ad68ff3af4f053fe7c16d0adfa75ca
prompt tokens: 47478
completion tokens: 3413
steps: 6
substrate calls: 1
file writes: 1
tool calls: 2
death: complete
```

The body independently read the artifact back and manifested the same byte
count and digest.

## Epistemic Boundary

The raw artifact is a substrate-authored semantic proposal. It contains useful
self-description and audit claims, but its internal objects label every claim
`runtime_confirmed`. Those labels have no body authority. The enclosing
repository manifest correctly records:

```text
content_truth_status = semantic_proposal
event_truth_status = runtime_confirmed
```

Thus the runtime-confirmed fact is that proc-17 created and verified these exact
bytes. The truth of the audit's individual claims remains unresolved pressure.

## Immediate Observations

The artifact correctly identifies several existing boundaries from the corpus:

```text
the LLM is semantic current, not body authority
capability-safe repository mutation is intentionally narrow
bequest and compost writers still lack general readers
pressure calibration and broad tree evidence remain incomplete
lineage persistence and general repository work remain deferred
```

It also demonstrates stale-document susceptibility:

```text
it repeats pre-CLI release steps as remaining work although CLI is implemented
it treats partial 22-edge evidence as a contradiction with one complete build
it calls the deliberately narrow first-hand chapter incomplete because it is narrow
it questions the 107-suite count without receiving test source
```

No statement in the raw artifact is promoted by this note. The result is kept
as self-observation evidence and pressure for later document-precedence and
analytical-output design.
