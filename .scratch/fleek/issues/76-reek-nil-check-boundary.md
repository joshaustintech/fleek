# 76: Match NilCheck nil checks inside blocks

**What to build:** Explicit reek:NilCheck matches Reek 6.6.0 for nil checks inside blocks, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A nil? and nil-comparison check inside a block with a safe-navigation clean control; preserve exact occurrence lines.

## Starting evidence

Existing NilCheck fixture and simple-method-body traversal.

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

- RED: with pinned Reek 6.6.0, `bundle exec reek --checks NilCheck test/fixtures/nil_check_nested_block.rb` reports `Parcel#retrieve` at lines 4 and 5; Fleek initially marked the selected source incomplete because the method body contained a block.
- GREEN: compiled Fleek now matches those exact Reek locations and method context. `value&.save` remains clean. Explicit `NilCheck` selection and `config_nil_check_nested_exclusion.yml` method exclusion both pass the public CLI contract.
- Coverage boundary: one supported block is traversed. Multiple blocks / unsupported nodes remain incomplete. Parent ticket 24 and downstream manifest ticket 100 remain separate.
- Commands: `make all`; `ruby test/default_argument_api_contract.rb`; focused `FLEEK_MUTATIONS='missing NilCheck finding,NilCheck block scope analysis,wrong nested NilCheck lines' ruby test/mutation_contract.rb`; `make reek`; full `JOBS=4 make check` (72 workers passed, mutation workers=4); `make ticket-check`; `git diff --check`.
- Focused mutations caught missing block analysis and incorrect nested source locations. Reek reported zero warnings. The full check passed build, contracts, Flay, Reek, and mutation checks. Pinned Spinel 2026.09.12 native suite remains unchanged and passed 3,596 tests with zero failures/errors, including allocation and inference checks (`spin-e2e: ALL GREEN`).
- ADR: [0213](../../../../docs/adr/0213-match-nil-check-inside-one-block.md).
