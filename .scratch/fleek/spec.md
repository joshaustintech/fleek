# Fleek

**Status:** resolved
**Category:** enhancement

## Problem Statement

Ruby developers lack a useful, standalone replacement for Flay and Reek. Fleek has no application source or tests. Flay and Reek also have incompatible CLI options, configuration models, parser support, output, and exit behavior.

## Solution

Build one native CLI with every built-in Flay 2.14.4 check and Reek 6.6.0 detector. Match the pinned default check sets when selection is omitted, preserve explicit subset selection and analyzer-specific configuration, and report incomplete analysis honestly. Target Ruby 4.0 and source accepted by pinned Spinel 2026.09.12. Compare shared syntax against fixed upstream references and label extension behavior separately. Prove usefulness on a real Rails project. Release publication is separate from the full native CLI parity goal.

## User Stories

1. As a Ruby developer, I want a useful replacement for Flay and Reek, so that one native tool can report duplication and code smells.
2. As a user, I want an executable that does not need Ruby or either original tool at runtime, so that installation stays simple.
3. As a developer, I want each upstream version and its dependencies fixed, so that comparison results are reproducible.
4. As a developer, I want only selected supported checks to run, so that I know what the result covers.
5. As a CI user, I want clean, finding, and incomplete results to have distinct statuses, so that a partial scan never looks successful.
6. As an agent, I want stable text fields for checks, findings, locations, and completion, so that I can interpret reports without guessing.
7. As a developer, I want real ClassVariable findings with scopes and occurrences, so that existing Reek behavior is preserved.
8. As a developer, I want structural groups, mass, pruning, and scores, so that renamed or changed-literal duplicates remain detectable.
9. As a developer, I want duplication and smell reports kept separate, so that unlike scores are not combined.
10. As a developer, I want each analyzer's settings and exclusions to retain their own scope, so that migration does not silently hide findings.
11. As a developer, I want explicit files, recursive directories, or named stdin, so that input selection is predictable.
12. As a user, I want unsupported syntax, checks, settings, and formats reported explicitly, so that absence of a finding does not hide missing analysis.
13. As a Ruby developer, I want a clear Ruby 4.0 syntax target, so that language coverage does not drift.
14. As a Spinel developer, I want documented source extensions accepted, so that Fleek can analyze source intended for the pinned compiler.
15. As a maintainer, I want shared-syntax parity separated from extension behavior, so that compatibility claims match evidence.
16. As a Rails developer, I want findings checked on a real project, so that a toy example does not stand in for everyday usefulness.
17. As a user, I want a downloadable macOS arm64 archive, so that I can install a verified release.
18. As a maintainer, I want cold runtime measured on identical work, so that performance claims follow correctness and evidence.

## Implementation Decisions

- One combined analysis mode; distinct long options and no conflicting short aliases.
- Reference Flay 2.14.4 and Reek 6.6.0 at accepted commits; pin exact reference Ruby and dependencies before comparison.
- Pinned Spinel 2026.09.12 is the implementation compiler. Analyze original source without executing it or loading dependencies.
- With omitted selection, run all built-in checks enabled by the pinned analyzers by default; explicit `--checks` selects a subset. Support opt-in built-in detectors when enabled or selected. Report unsupported selected analysis as incomplete.
- Match analysis behavior and controls on identical shared-parseable source, including settings, exclusions, suppressions, findings, locations, ordering, and scores. Fleek retains its report format and documented exit-code normalization.
- Use distinct duplication and smell sections; preserve type-specific metrics. No combined score or machine format in first release.
- Import supported Reek YAML and `.flayignore`; preserve analyzer-specific exclusions. No new unified config.
- No arguments prints usage to stderr and exits 1; explicit help exits 0. Complete clean analysis exits 0; complete findings exit 2; errors/incomplete analysis exit 1, overriding findings.
- Partial file errors retain useful findings and identify failures. Text shows checks, locations, coverage, completion, with diagnostics on stderr.
- Recursively scan `.rb` files; skip hidden directories and directory symlinks. Explicit non-Ruby inputs fail. Stdin needs explicit selection and a source filename.
- Initial implemented checks were Reek ClassVariable and Flay StructuralDuplication; these are not the full parity boundary. Unsupported grammar remains explicit until supported.
- First platform macOS arm64. Standalone release packaging is a separate delivery goal. Set speed target from cold CLI measurements after correctness.
- Ticket order: reproducible harness, native parser experiment, ClassVariable, source/config/report workflow, structural duplication, language/project parity, runtime evidence, archive, verified release.

## Testing Decisions

- Primary seam: compiled CLI process, observing inputs, stdout, stderr, and status. For parser feasibility only, use a real temporary native probe; it reports parsing and never claims an analysis ran.
- Compare identical shared-syntax inputs/settings against unchanged pinned originals for findings, locations, groups, scores, ordering, and exit behavior. Ruby 4-only expectations are reviewed fixtures, not stock-Reek parity.
- Tests use independent reference examples, public output, real files/configuration, and mutations that prove failures are detected; never test private call order or mocks of the analyzer.
- Record actual build/parser identity, corpus revision, settings, outputs, statuses, and limitations.
- Each slice is test-first with mutation evidence. Before each commit, full project build/tests, zero Flay/Reek findings, and no surviving non-equivalent mutants must pass. Explain equivalent exclusions.
- Commit coherent passing slices sequentially on main and push each to origin/main.

## Out of Scope

ERB and upstream plugins; new lint philosophy; machine output; a combined score; Ruby language versions beyond 4.0; Linux/Intel targets; executing source; performance claims without measurements; release publication as part of the full-parity goal.

## Further Notes

Source research, not runtime proof, established parser/config/CLI conflicts. The native parser experiment, exact reference locks, and real Rails parity are gates. If an experiment fails, record the blocker and an ADR; do not change the compiler pin or report unsupported coverage as clean.

## Detailed Specifications

- [Native foundation](specs/01-native-foundation.md)
- [Smell analysis and source workflow](specs/02-smell-and-source-workflow.md)
- [Structural duplication and combined analysis](specs/03-structural-duplication.md)
- [Full analyzer parity and language support](specs/04-language-and-project-parity.md)
- [Standalone native release](specs/05-native-release.md)

## Delivery status

Tickets 01–20 are resolved. Fleek 0.2.0 is published and its downloaded macOS arm64 archive and extracted CLI are verified; see the [release receipt](../../docs/research/native-archive-0.2.0.md). The shipped analyzer remains bounded to explicitly selected Flay StructuralDuplication and Reek ClassVariable. Tickets 21–24 now track full native CLI parity; this work supersedes the bounded coverage target for implementation, while release publication remains separate. The pinned 25-file Rails corpus currently reports Flay partial coverage and combined exit 1; no full parity claim applies until ticket 24 is resolved.
