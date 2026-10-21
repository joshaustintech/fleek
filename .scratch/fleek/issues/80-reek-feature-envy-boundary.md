# 80: Match FeatureEnvy receiver calls inside blocks

**What to build:** Explicit reek:FeatureEnvy matches Reek 6.6.0 for receiver calls inside blocks, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Repeated external-receiver calls inside a block versus equivalent self/instance-state use; compare receiver count and reported context.

## Starting evidence

Existing FeatureEnvy fixture and simple-method receiver counting.

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

- RED: pinned Reek 6.6.0 reports `FeatureEnvy` inside `Parcel#price` at lines 5, 6, and 7 for receiver `item`; Fleek initially returned incomplete because method bodies with a block were outside its whitelist.
- GREEN: compiled Fleek matches the finding lines, context, receiver, and message through explicit `reek:FeatureEnvy`. Self-heavy `update` remains clean. Configured exclusion for `Parcel#price` matches Reek. Methods with multiple blocks remain incomplete.
- Commands: `make all`; `ruby test/default_argument_api_contract.rb`; focused `FLEEK_MUTATIONS='FeatureEnvy block scope analysis,missing FeatureEnvy finding' ruby test/mutation_contract.rb`; full `JOBS=4 make check` (72 workers, four mutation workers, 11:09); pinned Spinel `make -C /private/tmp/fleek-spinel-pinned-rebuild check`; `make ticket-check`; `git diff --check`.
- Both focused mutations were caught. Full project gates passed; Reek reported zero warnings. Pinned Spinel 2026.09.12 passed 3,596 tests, allocation/inference checks, and `spin-e2e: ALL GREEN`; `skb` abort trap was nonfatal.
- Boundary: one supported block traversed; multiple blocks remain incomplete. Parent ticket 24 and downstream manifest ticket 100 remain separate.
- ADR: [0217](../../../../docs/adr/0217-analyze-feature-envy-inside-one-block.md).
