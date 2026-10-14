# Language support and real-project parity

Publication: draft for review.

## Problem Statement

A native parser can accept source while the analyzers misinterpret it. Stock Reek cannot certify all Ruby 4 syntax, and a few toy examples cannot demonstrate a useful replacement on real Ruby development work.

## Solution

Prove Ruby 4.0 and pinned Spinel input behavior through implemented checks. Separate unchanged-reference parity on shared syntax from reviewed extension behavior, then demonstrate the supported selected checks on an immutable small real Rails project.

## User Stories

1. As a Ruby developer, I want explicit Ruby 4.0 input support, so that language coverage is clear and reproducible.
2. As a Spinel developer, I want documented pinned-compiler source extensions supported, so that native Ruby projects can be analyzed too.
3. As a developer, I want original locations preserved for transformed syntax, so that reports point at my source rather than generated code.
4. As an agent, I want unchanged-reference comparisons labeled accurately, so that extension tests are not mistaken for stock-Reek parity.
5. As a maintainer, I want reviewed expected findings for reference-rejected syntax, so that new syntax has an explicit behavior contract.
6. As a maintainer, I want modified references validated separately if used, so that a parser swap does not silently redefine detector semantics.
7. As a developer, I want unsupported syntax identified explicitly, so that a clean result cannot hide skipped constructs.
8. As a developer, I want analysis not to execute requires or FFI declarations, so that source inspection remains independent of application behavior.
9. As a Rails developer, I want a real-project parity receipt, so that the replacement demonstrates everyday usefulness.
10. As a maintainer, I want immutable source, settings, and reference environments, so that parity results can be reproduced.
11. As an agent, I want capability limits and deliberate differences documented, so that I can select checks without misleading expectations.
12. As a maintainer, I want discovered failures turned into minimal regression cases, so that fixes remain narrow and testable.

## Implementation Decisions

- Ruby syntax target is explicitly 4.0, not an unspecified latest grammar. Spinel input targets source accepted by compiler 2026.09.12 including documented syntax extensions; implementation compiler remains pinned.
- Analyze original source without executing it or loading its dependencies. Treat native source strings as source content according to the Ruby check semantics, not as a promise to analyze another embedded language.
- Unchanged pinned originals define shared-syntax comparisons. Review extension expectations separately and label them as extension behavior.
- Any secondary modified reference must first demonstrate agreement with its unchanged counterpart on common grammar and have its own locked identity.
- Select and lock one small actual Rails project and relevant settings. Compare both selected supported checks over identical source and settings, including clean/finding/incomplete cases.
- Maintain an explicit capability statement for syntax, checks, settings, path discovery, and CLI differences. Do not infer full replacement coverage from selected-check parity.

## Testing Decisions

- Use the native CLI seam, actual parser, and actual selected checks. Parsing-only success is insufficient.
- Include Ruby 4.0 and documented Spinel extension examples with expected findings, negative cases, source locations, scope, comments, suppression, and duplication shape where applicable.
- Verify non-execution by analyzing source whose execution/loading would produce an observable effect and proving the effect does not occur.
- Compare shared-syntax examples against originals; keep extension fixtures and their provenance distinguishable in evidence.
- Record corpus revision, input manifest, exact settings, tool versions, outputs, statuses, and every deliberate comparison exception.
- Mutate extension location handling and check traversal where relevant. Regressions found in the real corpus receive minimal behavior tests and the ordinary gates.

## Out of Scope

Ruby versions beyond 4.0, arbitrary Spinel releases, execution of analyzed code, unsupported syntax silently ignored, exhaustive analysis of every Rails ecosystem plugin, and full upstream check coverage.

## Further Notes

Corpus selection and exact parser/extension cases are evidence-driven work, not facts already proved. A real-project failure keeps release blocked until corrected or until an explicitly documented supported scope genuinely satisfies the agreed useful-release bar.
