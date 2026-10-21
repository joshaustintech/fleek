# 94: Verify default, subset and combined outcomes

**What to build:** Default runs, explicit subsets and combined Flay/Reek requests report exactly the selected checks and truthful complete/findings/incomplete outcomes.

**Part of:** Ticket 24.

**Blocked by:** 59; 61; 90; 91; 92; 93; 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use a small matrix: clean default, finding default, explicit opt-in, config-enabled opt-in, disabled detector, separate analyzer exclusions, and one supported finding beside an unresolved selected source. Compare normalized statuses 0/2/1, per-check source accounting, deterministic finding order and preserved partial findings. Reuse existing selection contracts.

## Starting evidence

CheckProfiles, combined/default invocation contracts and ADR 0048; all detector child receipts are required before global completion claims.

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

Pinned Spinel 2026.09.12, Flay 2.14.4, and Reek 6.6.0. The requested matrix was already covered by public contracts: clean/finding defaults and explicit subsets in `test/default_invocation_contract.rb`; explicit opt-in in `test/default_argument_api_contract.rb`; config-enabled opt-in and disabled checks in `test/default_configuration_contract.rb` and `test/default_invocation_contract.rb`; independent analyzer exclusions, per-check source accounting, preserved Reek findings beside incomplete Flay input, and combined status/order in `test/combined_contract.rb`. Complete clean, complete findings, and incomplete outcomes are asserted as 0, 2, and 1 respectively. No implementation changes were needed.

`$SPINEL -E test/default_invocation_contract.rb`, `$SPINEL -E test/default_configuration_contract.rb`, `$SPINEL -E test/default_argument_api_contract.rb`, and `$SPINEL -E test/combined_contract.rb` all passed with the pinned environment. The full `make check JOBS=4` immediately before this ticket passed 72 workers and all configured mutations; the pinned Spinel native suite passed 3,596 tests and `spin-e2e: ALL GREEN`. Flay score was 0, Reek had 0 warnings, `make ticket-check` validated 135 documents, and `git diff --check` passed. No remaining gap was found in the listed matrix. ADR 0231 records the outcome and independent-coverage decision.
