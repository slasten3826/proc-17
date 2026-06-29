# Cognitive Battery Codex Results

Status: first live-run observations.

Source logs:

- `logs/cognitive_battery/2026-06-29/codex/`
- `logs/cognitive_battery/2026-06-29/README.md`

This document records what the technical/codex battery exposed. It is not a final evaluation of proc-17. It is raw interpretation material for the next table/crystall pass.

## Run Summary

- Tests: `c01-c34`
- Completed: `34 / 34`
- Stderr after final reruns: empty
- Substrate: DeepSeek through proc-17 CLI
- Dominant substrate drift: `substrate` is often interpreted as electronics/biology substrate instead of proc-17 substrate.

## Main Observation

proc-17 currently records hallucination pressure better than it prevents hallucination.

`☶` keeps the boundary: substrate output remains `semantic_proposal` and is not promoted to `runtime_confirmed`.

But `☴/☵` do not yet give the substrate enough project-specific field pressure, so DeepSeek can still answer from its nearest pretrained association instead of proc-17 context.

## Format Tests

Tests: `c01-c06`.

Observed:

- `c01-c02` passed simple formatting pressure: one word, three lines.
- `c03-c06` mostly obeyed surface format, but drifted into unrelated "substrate current / semiconductor substrate" content.
- `c05` exposed an inline-structure problem: the prompt asked for section headers as separate lines ending with `:`, but the substrate returned `Section: text` inline.

Pressure:

- `☵` can handle explicit separate-line sections, but inline section structure still remains ambiguous.
- Inline structure should not be trusted as full structure without additional parsing or ambiguity marking.

## Proc-17 Context Tests

Tests: `c07-c09`.

Observed:

- Without repo/runtime context, the substrate fabricated proc-17 abilities.
- `c07` invented bytecode injection, AST regeneration, parallel shadows, exact timing, and dead-code percentages.
- `c08` described a general coding agent or the current assistant surface instead of proc-17.
- `c09` answered as if proc-17 were a programming language/runtime design.

Pressure:

- Substrate needs project field before answering proc-17 questions.
- Terms such as `body`, `substrate`, `organ`, `runtime`, and `memory` need proc-17-local grounding before substrate call.

## Runtime Context Tests

Tests: `c10-c12` with `--repo-list logic`.

Observed:

- With runtime-confirmed repo paths, behavior improved sharply.
- `c10` selected `logic/choose.lua`, `logic/cycle.lua`, `logic/encode.lua`.
- `c11` correctly marked real files and one missing file: `logic/decode.lua`.
- `c12` selected `logic/repo_selection.lua` as best file for improving `☵`, which is debatable; expected pressure points more directly toward `logic/encode.lua`.

Pressure:

- `☵` produces a much cleaner field when it receives runtime-confirmed repo listing.
- `☳` can collapse clean repo fields, but its semantic ranking may still select an arguable item.

## Anti-Hallucination Tests

Tests: `c13-c15`, `c20-c25`, `c29`.

Observed:

- `c13` correctly said there was no context for the next needed function.
- `c15` correctly returned `нужен контекст`.
- `c23-c24` correctly detected instruction conflict.
- `c25` failed: when forbidden to say `неизвестно`, the substrate confidently answered from electronics-domain prior.
- `c29` failed by interpreting "organ" biologically and proposing biological-substrate verification.

Pressure:

- Refusal/uncertainty is a necessary valid output form.
- If the prompt forbids uncertainty, the substrate may fill the gap with high-confidence drift.
- `☶` should eventually detect forced-certainty pressure as dangerous when runtime context is missing.

## Encode/Choose Tests

Tests: `c16-c19`, `c26-c28`, `c31`.

Observed:

- `c16` correctly treated `A: one two three` as ambiguous instead of fully trusted structure.
- `c17-c18` drifted back into substrate-current semantics instead of proc-17 `☵/☳`.
- `c19/c28` showed that the substrate can produce text containing headers, evidence, and alternatives.
- Producing evidence/alternatives text does not mean `☵` has reliably extracted roles.
- `c26-c27` answered choice/loss prompts, but with weak or invented alternatives.

Pressure:

- `☵` needs role extraction: `claim`, `evidence`, `alternative`, `action`, `constraint`, `unknown`.
- `☳` should stay simple: it collapses a field; it should not become the semantic judge.
- A dirty `☵` field makes `☳` faithfully collapse dirty material.

## Philosophical/Concept Tests

Tests: `c30-c34`.

Observed:

- `c30` gave generic software-process documentation advice.
- `c31` understood `semantic_proposal` only at phrase level, not as proc-17 boundary mechanics.
- `c32` answered in generic body/soul metaphysics.
- `c33` rejected the "memory as fast re-decoding" framing using standard storage-memory assumptions.
- `c34` answered coherently, but in human existential terms rather than packet/procesis mortality terms.

Pressure:

- Deep conceptual tests need procesis/proc-17 field injection.
- Otherwise the substrate answers from common human-language priors.

## Operator Notes

`☵ ENCODE`:

- Current strength: distinguishes repo path fields from semantic line fields.
- Current weakness: does not yet parse inline structure or semantic roles deeply enough.
- Needed pressure: structured role extraction and ambiguity preservation.

`☳ CHOOSE`:

- Current strength: collapses field visibly and records killed alternatives.
- Current weakness: cannot know whether the encoded field is semantically correct.
- Current decision: do not make `☳` smart too early; improve `☵` field quality first.

`☶ LOGIC`:

- Current strength: keeps substrate output as `semantic_proposal`.
- Current weakness: does not yet reject or flag specific semantic drift in the output.
- Needed pressure: detect missing runtime context, forced-certainty prompts, and project-term drift.

`△ MANIFEST`:

- Current weakness: CLI manifest still reports internal completion (`substrate loop complete`) rather than clean task answer.
- Needed pressure: separate internal trace completion from external answer surface.

## Working Conclusion

The battery supports this working direction:

1. Improve `☵` before making `☳` smarter.
2. Add project-field grounding before substrate calls.
3. Treat uncertainty/refusal as a valid output shape.
4. Preserve `☳` as simple collapse with visible loss.
5. Later, teach `☶` to recognize semantic drift patterns without pretending to prove truth.
