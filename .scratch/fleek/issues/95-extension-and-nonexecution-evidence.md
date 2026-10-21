# 95: Separate extension evidence and prove non-execution

**What to build:** Ruby 4/Spinel reference-rejected syntax is labeled separately, and source analysis never runs requires, FFI declarations or application code.

**Part of:** Ticket 24.

**Blocked by:** 52; 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Reuse existing extension fixtures; add a sentinel side effect for requires/application statements and inert FFI declarations. Assert no sentinel effect. Record reference acceptance/rejection before any semantic parity comparison; retain original locations. Do not widen grammar in this verification slice.

## Starting evidence

Existing language-extension/non-execution contracts; spec 04 extension and inert-analysis boundaries.

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

Pinned Spinel 2026.09.12, Flay 2.14.4, and Reek 6.6.0. The existing `test/language_extensions_contract.rb` now records the pinned reference outcome first: Reek accepts the Spinel-shaped source and reports `NativeDependency` at original line 6; it rejects the Ruby 4-only `&&` fixture with its parser diagnostic before Fleek's separately labeled finding at line 3 is checked. Flay reference groups, scores, and original method lines remain separately asserted. `spinel_ffi.rb` now requires `side_effect.rb`, which would write a sentinel, and retains its module-body write plus inert `ffi_func` declaration. The contract checks both sentinels before and after Reek and Fleek analysis. `test/native_parser_contract.rb` also passes its non-execution assertion. No analyzer implementation changed.

`$SPINEL -E test/language_extensions_contract.rb` and `$SPINEL -E test/native_parser_contract.rb` passed. Full `make check JOBS=4` passed 72 workers and all configured mutations. `make -C /private/tmp/fleek-spinel-pinned-rebuild check` passed 3,596 native tests and `spin-e2e: ALL GREEN`. `bundle exec flay bin` scored 0; `bundle exec reek bin test/*.rb` reported 0 warnings. The broad test corpus Flay score remains 1,008, the known preexisting similarity baseline recorded in ticket 92. `make ticket-check` validated 135 documents and `git diff --check` passed. No behavior gap remains within this ticket. ADR 0019 already records the decision to keep Ruby 4 extension findings separate from shared-syntax parity and to treat analyzed files as inert; its evidence was updated with the stronger require sentinel and reference-first ordering.
