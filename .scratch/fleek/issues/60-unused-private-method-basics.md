# 60: Analyze directly unused private methods

**What to build:** Explicit reek:UnusedPrivateMethod reports an uncalled private method and stays clean for a directly called private method, matching Reek 6.6.0.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use one simple class with a private helper, then add a call from a public method. Compare context, lines, detector details, coverage and normalized status. Keep detector absent from unconfigured defaults. Replace only the unsupported-opt-in assertions superseded by these supported shapes.

## Starting evidence

Current unsupported-opt-in dispatch, existing unused-private fixture and default configuration/selection contracts.

## Acceptance criteria

- [x] Listed behavior cases have reproducible inputs, pinned expected results and matching public behavior. Inventory-only work records evidence and concrete child links; completion gates remain open until every required residual gap resolves.
- [x] Semantic findings, coverage, streams and normalized outcome are asserted where applicable; evidence-only inventories distinguish verified rows from unresolved work.
- [x] Relevant regression/mutation or evidence checks pass; Answer records exact commands and remaining issue links.
- [x] Stop after this behavior is proven; parent acceptance is not reduced by this child.

## Execution and stop condition

Claim this child before implementation; parent claims remain unchanged. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Start with the listed public CLI cases and existing helpers. Record expected versus actual behavior before editing. Implement only this behavior through the existing native path; no new framework, reference-tool fallback or unrelated syntax expansion.

Keep one focused regression and relevant non-equivalent mutations for changed behavior. Use `FLEEK_MUTATIONS` with exact registered labels for focused runs; full mutation coverage remains mandatory before a code commit. Run repository-required build/tests, Flay, Reek, mutation and standards/spec review gates before landing code. Docs/evidence-only work gets tracker/link/diff checks; do not invent implementation proof. Record commands, tool identities, RED/GREEN evidence where code changed, gate results and limitations in `## Answer`.

If cases already pass, add only missing meaningful evidence and finish; do not refactor for activity. If a second independent defect appears, publish a separate minimal child with expected pinned behavior and blockers. This child may finish its stated behavior while those gaps remain open, but the parent completion gate must wait for every residual child. Never turn incomplete coverage into clean output, skip a selected source or weaken a reference expectation to pass.

## Answer

Supported Flay/Spinel identity: Reek 6.6.0; Spinel 2026.09.12 (`112bae85c1a2`); the locked bundle. The public `DefaultArgumentApiContract` compares pinned Reek and Fleek for an uncalled private instance method (context `PrivateThing`, line 4, same finding message, status 2) and for that method directly called by a public method (clean status 0). Both assert complete one-source coverage and empty stderr. An indirect `send` call is explicitly incomplete rather than treated as unused or clean.

The detector remains absent from unconfigured defaults. Explicit selection runs without configuration; configuration enablement runs in default profiles; disabled and scoped configuration precedence remain covered. Dynamic dispatch, singleton methods, nested methods, and blocks remain outside the supported shape and produce incomplete analysis.

RED/GREEN: before implementation, the public explicit check returned incomplete and did not match pinned Reek; after implementation, the focused contract passed. `FLEEK_MUTATIONS='UnusedPrivateMethod private visibility,UnusedPrivateMethod direct call tracking,UnusedPrivateMethod dynamic call boundary' JOBS=3 ... -E bin/check_runner.rb mutation` caught all three targeted mutations.

Full gate: `PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle BUNDLE_GEMFILE="$PWD/Gemfile" SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true JOBS=4 make check` passed with 72 workers and four mutation workers; Reek reported 0 warnings. The changed Ruby files scored 0 in Flay. The repository-wide Flay score is 175, unchanged from `origin/main` at `13006ca`; its three existing findings are in `duplication_fuzzy_distance_contract.rb` and `text_report_contract.rb`. `make ticket-check` passed with 130 valid documents; `git diff --check` passed.
