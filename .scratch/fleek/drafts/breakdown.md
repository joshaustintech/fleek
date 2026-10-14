# Fleek: proposed specification and ticket breakdown

Draft for review, not an active issue queue. No implementation is authorized by this document. The confirmed domain terms, four ADRs, and primary-source research govern this plan.

## Specifications

1. [Native foundation](specs/01-native-foundation.md): reproducible compiler/reference environments, honest CLI usage, and a bounded native parser experiment.
2. [Smell analysis and source workflow](specs/02-smell-and-source-workflow.md): ClassVariable findings, input selection, Reek configuration, and clear text reporting.
3. [Structural duplication and combined analysis](specs/03-structural-duplication.md): default Flay semantics and one combined analysis mode with separate exclusions.
4. [Language support and project parity](specs/04-language-and-project-parity.md): Ruby 4.0 and Spinel extension behavior, shared-syntax parity, and a real Rails corpus.
5. [Native release](specs/05-native-release.md): measured cold runtime, standalone installation, and a verified downloadable artifact.

## Proposed test seams

The principal acceptance seam is the compiled native CLI process. Supply source and configuration, then observe stdout, stderr, and exit status. Compare findings and type-specific metrics to the unchanged pinned references where shared syntax permits it. Preserve deliberate CLI compatibility exceptions instead of normalizing them away.

The parser experiment uses a temporary developer-facing native probe only until ordinary analysis can demonstrate parsing through the CLI. It proves diagnostics, original locations, ownership, language boundaries, and standalone linkage; it does not claim checks ran. Callable analysis checks may isolate mutation faults when process-level checks cannot explain them, without asserting private methods or call sequences.

## Tickets

| Ticket | Specification | Blocked by | Verifiable delivery |
| --- | --- | --- | --- |
| [01 Native CLI and reference harness](tickets/01-native-cli-and-reference-harness.md) | 1 | None | Pinned native help/usage plus reproducible reference execution and quality commands. |
| [02 Native parser experiment](tickets/02-native-parser-experiment.md) | 1 | 01 | Standalone parsing probe with original diagnostics and Ruby 4.0/Spinel examples. |
| [03 First ClassVariable finding](tickets/03-first-class-variable-finding.md) | 2 | 02 | One selected real smell check through the CLI, with clean/finding/error statuses. |
| [04 ClassVariable scope and occurrence parity](tickets/04-class-variable-scope-and-occurrences.md) | 2 | 03 | Correct names, grouped lines, and nested/context ownership. |
| [05 Explicit files and directory scans](tickets/05-files-and-directory-scans.md) | 2 | 03 | Honest recursive input discovery and partial-file failure reporting. |
| [06 Named stdin analysis](tickets/06-named-stdin-analysis.md) | 2 | 05 | Piped source with required origin and equivalent locations. |
| [07 Reek configuration and suppression](tickets/07-reek-configuration-and-suppression.md) | 2 | 04, 06 | Supported YAML settings, scoped exclusions, and suppression through the CLI. |
| [08 Stable human and agent text](tickets/08-stable-human-and-agent-text.md) | 2 | 04, 06 | Deterministic finding fields, coverage, completion, and separate diagnostics. |
| [09 Structural duplication groups](tickets/09-structural-duplication-groups.md) | 3 | 07 | Genuine Flay structural groups on a declared syntax subset. |
| [10 Mass thresholds and duplication scores](tickets/10-mass-thresholds-and-scores.md) | 3 | 09 | Correct threshold boundaries, identical multiplier, and totals. |
| [11 Pruning and multi-file duplication](tickets/11-pruning-and-multifile-duplication.md) | 3 | 10 | Reference-equivalent surviving groups and deterministic locations/order. |
| [12 Combined report and separate exclusions](tickets/12-combined-report-and-exclusions.md) | 3 | 07, 08, 11 | Both analyzers run together; reports, errors, and exclusion scopes stay honest. |
| [13 Ruby 4.0 and Spinel extension findings](tickets/13-ruby4-and-spinel-extension-findings.md) | 4 | 12 | Reviewed extension behavior and shared-syntax parity through the actual checks. |
| [14 Real Rails project parity](tickets/14-real-rails-project-parity.md) | 4 | 13 | Locked real Rails corpus, identical inputs/settings, and no unexplained supported-check differences. |
| [15 Cold runtime evidence](tickets/15-cold-runtime-evidence.md) | 5 | 14 | Repeatable end-to-end measurements and an evidence-based performance target. |
| [16 Standalone archive installation](tickets/16-standalone-archive-installation.md) | 5 | 14 | Versioned arm64 archive that runs checks without Ruby or original tools. |
| [17 Downloadable release verification](tickets/17-downloadable-release-verification.md) | 5 | 15, 16 | Published downloadable asset verified by identity, installation, findings, and statuses. |

Ticket 09 follows 07 to preserve the confirmed rollout of ClassVariable before structural duplication. Ticket 08 need not gate algorithm work; it gates the combined report. Benchmark and packaging work can proceed independently after project parity. Each ticket may contain several tiny test-first commits; it is not permission for a large single commit.

## Common execution requirements

- First create a failing observable-behavior test; implement the smallest passing slice; prove detection of relevant behavioral faults with mutation checks.
- Use the pinned Spinel compiler for every one-off project helper, including reference orchestration, determinism checks, and measurements. Shell only invokes existing commands. Original tools are development references, never runtime dependencies.
- Before every commit, pass the full native build/tests, zero Flay/Reek findings, and no surviving non-equivalent mutants. Explain equivalent exclusions. Establish exact commands in ticket 01.
- Commit coherent passing slices sequentially on main and push each to origin/main. Preserve unrelated changes and never describe source inspection as runtime proof.
- If an experiment fails, record the result and remaining blocker. Do not claim completion, change compiler pins, install a new dependency without applicable authorization, or introduce mock proof.

## Publication after review

Publish each specification as its feature's local spec and tickets as separate numbered issue files in a project-wide Fleek issue queue, preserving global numbers and explicit cross-spec blocking edges. An index will link the five specifications and queue. Published work uses workflow state open and the ready-for-agent triage label; draft documents carry neither an active claim nor a completed state.

Review needed: accept the CLI/probe test seams, ticket size, blocking edges, and any requested merges or splits.
