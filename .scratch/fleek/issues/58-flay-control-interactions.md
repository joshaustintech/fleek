# 58: Verify Flay control precedence and routing

**What to build:** Mass, only-node, liberal, fuzzy and parser controls retain correct semantics in explicit and combined runs.

**Part of:** Ticket 23.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use a bounded table of one baseline per control, repeated mass/only, one fuzzy+liberal case and one parser+only case. Check malformed, unknown and check-inapplicable options reject before stdout analysis. Classify summary/diff/numbering/verbose as presentation; probe timeout separately before claiming it has no analysis effect. Publish individual remaining option gaps.

## Starting evidence

Ticket 23 inventory, existing CLI contracts and ADRs 0106, 0107, 0109.

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

Pinned Spinel 2026.09.12, Flay 2.14.4, and Reek 6.6.0 confirmed repeated `--mass` uses the last valid value. The contract compares `--mass 100 --mass 16` (score 112) and reversed order (score 0), bare `--fuzzy` plus `--liberal` (score 266), and `--legacy --only class` (class score 50) against Flay. Combined Flay+Reek runs verify fuzzy/liberal (score 32) and legacy/`--only defn` (score 64), with both coverage sections complete. Existing contracts verify repeated `--only`, malformed mass/fuzzy, unknown options, and check-inapplicable controls reject before stdout findings.

Presentation probe: `--summary`, `--diff`, `-#`, and `--verbose` leave the observed score unchanged. `--diff` could not render because `ruby2ruby` is absent. These options remain unsupported in Fleek report v1. Timeout is analysis/runtime behavior: Flay accepts zero and positive values; `--timeout -1` warns, skips input, and returns score zero. Neither behavior is claimed as parity.

RED/GREEN: pinned `SPINEL -E test/duplication_control_interactions_contract.rb` failed before the fix on repeated mass and fuzzy/liberal routing, then passed after last-value mass selection and numeric-only optional fuzzy extraction. Focused mutations `Flay repeated mass precedence` and `Flay fuzzy liberal source routing` were both caught.

Full gates: `FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true JOBS=4 make check` passed 72 workers, including four mutation workers; Flay score 0 and Reek warnings 0. `make ticket-check` passed 130 documents. Pinned Spinel `gmake check` passed 3,596 tests, alloc-report, and inference; its first `spin-e2e` attempt found system Make 3.81 in PATH, then `PATH=/opt/homebrew/opt/make/libexec/gnubin:/opt/homebrew/bin:$PATH gmake -C /private/tmp/fleek-spinel-pinned-rebuild spin-check` passed `spin-e2e: ALL GREEN`.

Residual gaps: [Ticket 120](120-flay-timeout-control.md) tracks `--timeout`; [Ticket 121](121-flay-presentation-controls.md) tracks presentation options. Parent Ticket 23 remains open until both close.
