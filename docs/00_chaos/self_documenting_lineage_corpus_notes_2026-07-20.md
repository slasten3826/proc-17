# Self-Documenting Lineage Corpus Notes

Status:

```text
chaos
first architecture frame
discussion document
no code authority
no completion authority
no router change
```

Date:

```text
2026-07-20
```

Primary context:

```text
docs/00_chaos/nested_layer_glyphs_notes.md
docs/01_table/yellowprints/nested_layer_glyphs_yellowprint.v0.md
docs/00_chaos/nested_work_layer_runtime_integration_2026-07-20.md
docs/00_chaos/plan_build_carrier_live_software_experiment_2026-07-20.md
docs/03_manifest/current_state.md
```

## 1. Trigger

proc-17 itself was assembled through a visible four-layer documentation
process:

```text
00_chaos
  -> 01_table
  -> 02_crystall
  -> 03_manifest
```

That corpus lets a later human or machine recover:

```text
what pressure existed
which alternatives were visible
which structure was selected
which contract became authoritative
what was actually implemented and tested
```

The same property is useful for software created by proc-17. A delivered
program without its formation record may work, but another observer cannot
reliably tell why it has this shape, which requirements it satisfies, which
failures changed later generations, or which claims are supported by runtime
evidence.

The pressure is therefore:

```text
proc-17 should be able to export the same kind of layered corpus through which
proc-17 itself was built
```

This cannot be mandatory for every task. Human-oriented explanation can spend
substantial substrate tokens, and many machine callers need only the structured
result and evidence.

## 2. Documentation Is An Orthogonal Contract

Documentation must not become a third work mode beside `plan` and `build`.

The coordinates are different:

```text
work_mode             = plan | build
work_layer            = derived ⋯ | ⊞ | ◈ | ▲
documentation_profile = off | structured | full
```

`plan` and `build` change why the Packet is working. The work layer describes
the current process form. The documentation profile describes which external
record of that life must be assembled.

The CLI or TUI may present `full` as a separate "documented mode" for human
convenience. Inside the body it remains an output/process contract, not a new
router authority and not a new ProcessLang organ.

## 3. Evidence Cannot Be Switched Off

`documentation_profile = off` must not mean that the body forgets its own
physics.

These records remain mandatory in every profile:

```text
Packet trace
lineage ledger
stage and generation identity
budget and loss accounting
capability grants and effects
candidate digest and seal
QA evidence, when QA exists
death, corpse, residue and carrier evidence
final manifest evidence
```

The body needs these records to route, validate, die, inherit and audit itself.
They are runtime state or immutable runtime evidence, not optional prose.

The switch controls only the exported documentation corpus:

```text
off        -> no optional corpus export
structured -> deterministic machine-readable corpus
full       -> structured corpus plus human-readable layered projections
```

## 4. Two Different Products Of Documentation

The documentation output has two representations with different authority.

### Structured Evidence

Intended reader:

```text
another machine
future proc-17 session
auditor
deterministic renderer
```

Candidate forms:

```text
JSON
canonical Lua data
content-addressed snapshots
immutable ledgers
```

This representation contains identifiers, source references, truth statuses,
digests, contracts and measured evidence. It should be assembled mostly from
facts the body already owns and should normally require no additional
substrate call.

### Human Projection

Intended reader:

```text
operator
maintainer
reviewer
future collaborator
```

Candidate form:

```text
Markdown in the four familiar directories
```

Some Markdown can be rendered deterministically. Explanatory synthesis may use
the substrate under a bounded documentation budget. Such prose does not become
runtime truth merely because it is well written.

## 5. The Corpus Must Describe The Real Process

The body must not finish a project and then ask an LLM:

```text
write a plausible story about how this software was made
```

That would create retrospective narration, not provenance.

Instead:

```text
the Packet creates or observes a fact
  -> the fact receives source refs and a truth status
  -> a layer boundary derives an immutable snapshot
  -> generation and stage boundaries append lineage evidence
  -> △ or a bounded corpus assembler renders the selected export profile
```

The final corpus may be assembled later, but its source material must have been
captured when the corresponding process form existed.

This is the same camera law already learned by the runtime:

```text
observe the owned state at a defined boundary
store an immutable frame
do not let the frame replace the living state
```

## 6. Four Exported Layers

The exact schemas remain open. The first content map is:

### `00_chaos`

```text
original root request
declared product boundary
raw observations
unknowns and unresolved pressure
constraints inherited from ancestors
legacy behavior observations, when a read-only source exists
semantic proposals that materially affected formation
```

This layer must preserve uncertainty. It must not rewrite every early thought
as if the final answer had been obvious from birth.

### `01_table`

```text
requirement matrix
artifact and component inventory
interface and dependency relations
acceptance matrix
alternatives and killed alternatives
stage and generation plan
named writers, readers and authorities
```

This is not merely a prose summary. It is the structured surface from which a
different machine should be able to reconstruct the shape of the work.

### `02_crystall`

```text
selected blueprint
exact contracts and invariants
candidate file/artifact plan
capability and safety boundaries
QA contract bound independently from candidate claims
failure crystals from rejected generations
constraints transported into the next birth
```

The exported crystall must correspond to the actual structured form used by
the build generation. A decorative blueprint written after the code is not a
crystall.

### `03_manifest`

```text
what was actually materialized
candidate and repository identity
artifact inventory and digests
how the result is invoked
QA evidence and verdict
budget, token, time and loss accounting
generation history
terminal residue and known limitations
root completion verdict
```

The manifest does not claim more than the body proved.

## 7. Relationship To `plan` And `build`

The documentation layers project the actual nested work rather than adding a
second fixed pipeline.

Candidate plan life:

```text
plan ⋯ -> source material for 00_chaos
plan ⊞ -> structured material for 01_table
plan ◈ -> selected material for 02_crystall
plan ▲ -> plan stage manifest and transition evidence
```

Candidate build lineage:

```text
build ⋯ -> whole candidate formation/materialization record
build ⊞ -> QA observations and acceptance evidence
build ◈ -> failure crystal for a rejected immutable candidate
build ▲ -> final acceptance or paid generation boundary
```

This map is descriptive. It must not be compiled into:

```lua
if glyph == "⊞" then next_operator = "☶" end
```

Operators still move according to body pressure and topology. Documentation
observes which form was reached and exports the evidence of that movement.

## 8. Relationship To Immutable Build Generations

A generated candidate remains governed by the greenfield-generation law:

```text
form the candidate inside Packet-owned semantic/structured state
materialize declared absent paths under a fresh repository identity
seal the whole candidate
test it without source mutation authority
```

If QA rejects the candidate:

```text
the rejected repository remains an immutable generation corpse
build ◈ records the concrete failure crystal
the Packet dies
a typed recovery carrier transports constraints, not files
a descendant receives another fresh repository identity
the whole program is generated again
```

The documentation archive may preserve the failed generation. The active build
root may not reuse it.

Documentation is stored outside the generated candidate by default. This lets
the body append QA results and lineage history without violating candidate
immutability.

If documentation is explicitly part of the delivered repository, its files
are ordinary declared candidate artifacts. They must be present before the
candidate seal and cannot be added or repaired after QA.

## 9. Lineage Owns The Corpus

The Packet is too short-lived to own the complete project history. The corpus
belongs to the root-task lineage.

Candidate layout:

```text
sessions/<session-id>/
  lineages/<lineage-id>/
    evidence/
      lineage-ledger.json
      root-contract.json
    generations/
      0001/
        packet.json
        candidate.json
        qa.json
        corpse.json
      0002/
        ...
    documentation/
      00_chaos/
      01_table/
      02_crystall/
      03_manifest/
```

This is a shape candidate, not a filesystem contract.

The root corpus can describe the whole project while generation subrecords
preserve exactly which candidate produced which evidence. A failure crystal
must name the rejected candidate digest and generation. It cannot float as a
timeless warning detached from its source.

## 10. Named Writers And Readers

The project law remains:

```text
every written record must have a named reader
```

Candidate chain:

| Record | Writer | First named reader | External reader |
|---|---|---|---|
| layer snapshot | body-owned snapshot producer | corpus assembler | human/machine corpus reader |
| generation evidence | lineage runner and runtime | corpus assembler | auditor |
| structured corpus | deterministic assembler | Markdown renderer or external machine | future agent/session |
| human projection | deterministic renderer or bounded substrate call | export validator | human reviewer |
| final documentation status | corpus assembler | root completion policy when required | CLI/TUI |

`△` is the natural final assembler because it already owns delivery boundaries.
It may read verified snapshots and assemble an output. It may not retroactively
edit the facts, raise semantic prose to runtime truth, or make an incomplete
root complete through documentation alone.

An implementation may use a helper module behind `△`; that helper is not a new
organ and receives no independent topology authority.

## 11. Truth Status Must Survive Rendering

Different statements inside one document may have different epistemic status:

```text
user requested feature X                     observed input / declared request
substrate proposed architecture Y            semantic_proposal
body selected Y from alternatives            runtime_confirmed selection event
file digest equals H                         runtime_confirmed
local token estimate is N                    estimated
ancestor failure applies to this generation  inherited/grave applicability
human explanation of why Y is elegant        semantic_proposal
```

The structured corpus must preserve those statuses per record or source ref.
Markdown may render them compactly, but it must not flatten them into one voice
of authority.

In particular:

```text
"the model says tests pass" != QA evidence
"the body executed tests and observed exit 0" = runtime evidence
```

## 12. Documentation Budget

Documentation consumption requires separate visibility and a bounded cap.

Candidate contract shape:

```lua
documentation = {
  profile = "off" | "structured" | "full",
  required = false,
  audiences = { "machine", "human" },
  token_limit = 12000,
}
```

This is a sketch, not an accepted schema.

The accounting law should be:

```text
documentation usage is tagged separately
documentation has its own cap/reserve
documentation usage still contributes to cumulative lineage economics
rebirth does not reset documentation spending
```

Separate visibility prevents prose from silently consuming the budget needed
to create and test software. Inclusion in total lineage economics prevents an
escape where expensive narration becomes "free" merely because it has another
counter.

Structured export should normally spend no substrate tokens. Full export may
pay for bounded explanation calls only from already captured snapshots.

## 13. Completion Semantics

Software completion and documentation completion are different facts:

```text
software_status       = incomplete | accepted | rejected | blocked
documentation_status  = disabled | incomplete | partial | complete | blocked
```

If documentation is optional:

```text
software accepted + documentation budget exhausted
  -> software remains accepted
  -> documentation = partial
  -> manifest reports the partial state honestly
```

If documentation is an explicit root-task deliverable:

```text
software accepted + required documentation incomplete
  -> artifact/candidate may be accepted
  -> root task is not complete
```

The process contract, not the substrate, decides whether documentation is
required.

## 14. Documentation Must Not Control Routing By Assertion

The following forms are forbidden:

```text
substrate writes "crystall complete" -> body advances
Markdown directory exists -> stage complete
caller injects layer label ▲ -> root complete
documentation renderer says QA passed -> manifest accepts candidate
```

Documentation is a projection of body evidence. It does not create the evidence
it describes.

If required documentation is missing, a named completion reader may expose a
qualified documentation need. The Tree router still chooses only among legal,
ready adjacent operators. The profile itself is not a hardcoded route.

## 15. Reentry By Another Machine

A central purpose of the corpus is that a later machine can understand what was
done without inheriting the original live context.

The machine-readable corpus should be sufficient to answer:

```text
what was requested
which contract governed the work
which generation is accepted
which generations failed and why
which candidate bytes were tested
which claims are proposals and which are runtime evidence
what remains unresolved
```

If a future proc-17 run ingests this corpus, it enters through `NETWORK@▽` as a
new Packet input. The old Packet does not resurrect. Exported truth statuses and
digests remain evidence about the prior lineage; their applicability to the new
task must be evaluated again.

Markdown alone is not an adequate machine carrier. The structured corpus is the
transport; Markdown is one projection.

## 16. Legacy Reconstruction

For legacy work:

```text
old repository = read-only observation source
documentation 00_chaos = observed behavior, constraints and uncertainty
documentation 01_table = reconstructed contracts and component relations
documentation 02_crystall = selected replacement blueprint
new repository = fresh generated candidate
documentation 03_manifest = replacement evidence and differential QA
```

The corpus must not claim that proc-17 understood every legacy behavior merely
because it read the repository. Unobserved, inferred and runtime-confirmed
properties remain distinct.

## 17. Security And Capability Boundary

Documentation is an export surface and can leak more than code.

The corpus assembler must not export by default:

```text
provider handles
capability tokens or grants usable by another process
API keys or environment secrets
raw authentication headers
unbounded stdout/stderr
absolute host paths when a bounded relative identity is sufficient
unredacted external content outside the declared task scope
```

Documentation output needs:

```text
bounded size
declared destination root
create-only or content-addressed writes
canonical encoding
digest verification
redaction policy with visible redaction records
```

A redaction event must say that content was removed. Silent rewriting would
make the corpus look complete when it is not.

## 18. Expected Failure Modes

The first table/crystall pass must explicitly guard against:

```text
post-hoc plausible history
Markdown treated as body truth
documentation profile changing candidate bytes
full profile starving build or QA budget
optional docs blocking accepted software
required docs silently ignored
failed generation evidence attributed to the accepted generation
truth statuses flattened during rendering
raw secrets copied from trace
documentation written into a sealed candidate
corpus growing without retention/compost policy
record written without a named reader
```

## 19. Candidate Experiments

### Profile Ablation

Run the same deterministic/fake-substrate life with:

```text
off
structured
full with narration disabled
```

Expected:

```text
same body route
same candidate bytes and digest
same QA verdict
same loss
same work/substrate calls
only export records differ
```

Full prose calls are tested separately because they legitimately consume
documentation tokens. They still must not alter the accepted candidate.

### Provenance Test

```text
every table/crystall/manifest claim resolves to a snapshot or evidence ref
unknown ref -> export rejected or visibly partial
tampered snapshot -> digest failure
```

### Budget Test

```text
documentation token cap reached
optional docs -> partial documentation, software result preserved
required docs -> root incomplete with exact missing requirement
all usage remains visible in lineage total
```

### Generation Test

```text
generation 1 fails QA
generation 2 succeeds
corpus preserves both candidate identities
failure crystal names generation 1
final manifest names generation 2
no rejected source file is presented as accepted output
```

### Security Test

```text
trace contains a synthetic secret/provider handle
structured and full exports omit or redact it
redaction is recorded
export cannot write outside its declared documentation root
```

### Reentry Test

```text
fresh machine/session ingests only structured corpus
reconstructs root contract, accepted generation and unresolved residue
does not inherit live capabilities or Packet identity
```

## 20. Likely Table Split

This chaos document probably needs three table documents:

### Table A: Documentation Profiles And Economics

```text
off / structured / full
required versus optional
audiences
token and runtime accounting
completion interaction
ablation expectations
```

### Table B: Layer Snapshot And Truth Schema

```text
00_chaos / 01_table / 02_crystall / 03_manifest contents
snapshot timing
source refs
truth statuses
named writers and readers
generation attribution
```

### Table C: Corpus Assembly, Storage And Reentry

```text
lineage ownership
filesystem layout
△ assembly boundary
machine and human representations
redaction/capability boundary
retention and compost
NETWORK@▽ reentry
```

## 21. Open Questions

### Q1. Is `structured` always emitted or explicitly requested?

The body already keeps mandatory evidence. The open question is whether a
portable structured corpus should be a cheap default or an explicit export.

### Q2. Which snapshots are physical records and which are derived on demand?

Persisting every projection may duplicate truth. Deriving everything only at
the end may lose historical form. The camera pattern suggests immutable
boundary snapshots plus derived rendering, but exact boundaries need a table.

### Q3. Does full documentation use the same substrate session?

Same-substrate continuity may improve explanation and cache locality, but it
must not be the only carrier of meaning. A cold substrate must be able to write
the same class of documentation from the structured corpus.

### Q4. Who validates human prose?

A deterministic export validator can check refs, required sections, statuses,
size and forbidden data. It cannot prove that every semantic explanation is
good. The prose must remain typed accordingly.

### Q5. When does documentation become a candidate artifact?

Only when the root contract requests documentation inside the delivered
repository. Otherwise it remains lineage-side export and may be assembled after
candidate QA without modifying the candidate.

### Q6. How does corpus compost work?

Long lineages can produce large documentation histories. Individual failed
generations may eventually be compacted, but accepted evidence, failure counts,
truth distinctions and reproducibility requirements constrain what may decay.

## 22. Proposed Order

```text
1. discuss and amend this chaos frame
2. build the three table documents
3. crystallize structured evidence and snapshot boundaries first
4. implement observation/export in shadow with no substrate narration
5. prove profile ablation and candidate-byte equivalence
6. implement lineage-owned structured corpus
7. add bounded human Markdown rendering
8. add documentation token accounting and required/optional completion law
9. add security/redaction battery
10. only then expose the documentation profile in CLI/TUI
```

The first implementation should not begin with prose generation. It should
prove that another machine can recover the real process from structured facts.

## 23. Current Thesis

proc-17 should not merely return code and should not merely narrate confidence.
It should be capable of delivering:

```text
the generated form
the evidence that selected it
the history of rejected forms
the contracts under which it was tested
the bounded explanation of how the form came to exist
```

The four-layer corpus is not decorative documentation attached after the work.
It is an external, readable projection of the same process that actually built
the software.

This is why the symmetry with proc-17's own development matters:

```text
proc-17 was made legible through ⋯ -> ⊞ -> ◈ -> ▲
proc-17 can make its products legible through ⋯ -> ⊞ -> ◈ -> ▲
```

The body remains authoritative. Documentation makes that authority inspectable
without pretending that prose created the underlying truth.
