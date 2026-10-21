# 79: Match NestedIterators ignored nested iterator names

**What to build:** Explicit reek:NestedIterators matches Reek 6.6.0 for ignored nested iterator names, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A three-level iterator chain with one configured ignored iterator, then without ignore; compare calculated nesting depth and boundary threshold.

## Starting evidence

Existing nested-iterator multiple-ignore fixtures and configured contracts.

## Acceptance criteria

- [x] Baseline clean/finding and the listed boundary cases match unchanged Reek findings, context, lines and details through the compiled CLI.
- [x] Exercise explicit selection plus one relevant threshold/allow/exclude/disable control supported by this detector; no unsupported selected source may be labeled complete.
- [x] Relevant regression/mutation or evidence checks pass; Answer records exact commands and remaining issue links.
- [x] Stop after this behavior is proven; parent acceptance is not reduced by this child.

## Execution and stop condition

Claim this child before implementation; parent claims remain unchanged. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Start with the listed public CLI cases and existing helpers. Record expected versus actual behavior before editing. Implement only this behavior through the existing native path; no new framework, reference-tool fallback or unrelated syntax expansion.

Keep one focused regression and relevant non-equivalent mutations for changed behavior. Use `FLEEK_MUTATIONS` with exact registered labels for focused runs; full mutation coverage remains mandatory before a code commit. Run repository-required build/tests, Flay, Reek, mutation and standards/spec review gates before landing code. Docs/evidence-only work gets tracker/link/diff checks; do not invent implementation proof. Record commands, tool identities, RED/GREEN evidence where code changed, gate results and limitations in `## Answer`.

If cases already pass, add only missing meaningful evidence and finish; do not refactor for activity. If a second independent defect appears, publish a separate minimal child with expected pinned behavior and blockers. This child may finish its stated behavior while those gaps remain open, but the parent completion gate must wait for every residual child. Never turn incomplete coverage into clean output, skip a selected source or weaken a reference expectation to pass.

## Answer

- RED/GREEN: the existing implementation already matches pinned Reek 6.6.0. Without config, `rows.each` → `row.map` → `item.each` reports the innermost iterator at line 5, depth 3. With `max_allowed_nesting: 2` and `ignore_iterators: [map]`, effective depth is two and result is clean/complete.
- Public CLI contract compares explicit `reek:NestedIterators` findings, exact line/context, clean status, and configured ignore behavior. Focused `ignored NestedIterators list entry` mutation is caught by the new boundary contract.
- Commands: `ruby test/default_argument_api_contract.rb`; focused `FLEEK_MUTATIONS='ignored NestedIterators list entry' ruby test/mutation_contract.rb`; full `JOBS=4 make check`; pinned Spinel `make -C /private/tmp/fleek-spinel-pinned-rebuild check`; `make ticket-check`; `git diff --check`.
- No implementation change required. Parent ticket 24 and downstream manifest ticket 100 remain separate.
- ADR: [0216](../../../../docs/adr/0216-verify-nested-iterator-ignore-depth.md).
