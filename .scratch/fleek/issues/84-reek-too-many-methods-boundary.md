# 84: Match TooManyMethods nested class method counts

**What to build:** Explicit reek:TooManyMethods matches Reek 6.6.0 for nested class method counts, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Outer/inner classes with direct methods at threshold and threshold+1; ensure definitions are attributed to the correct class, preserving mixed-unsupported findings.

## Starting evidence

Existing TooManyMethods nested-definition and data/size scope regressions.

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

- RED: pinned Reek 6.6.0 reports `[18]:TooManyMethods: Fleet::Shipment has at least 16 methods`; Fleet's 15 direct methods stay clean. Fleek initially marked the nested-class input incomplete without a finding.
- GREEN: explicit `reek:TooManyMethods` matches the nested finding's qualified context, line, and count. `max_methods: 16` leaves both scopes clean. A separate top-level method makes the source incomplete while Fleek preserves the matching nested class finding; a deeper nested class remains incomplete with no falsely complete analysis.
- Commands: `make all`; `ruby test/default_argument_api_contract.rb`; focused `FLEEK_MUTATIONS='TooManyMethods nested class isolation' ruby test/mutation_contract.rb`; full `JOBS=4 make check` (72 workers, four mutation workers; Reek 0 warnings); `make -C /private/tmp/fleek-spinel-pinned-rebuild check`; `make ticket-check`; `git diff --check`.
- The focused mutation was caught by the nested default threshold status mismatch. Full project checks passed. Pinned Spinel 2026.09.12 passed 3,596 tests, allocation/inference checks, and `spin-e2e: ALL GREEN`; its `skb` abort trap was nonfatal.
- ADR: [0221](../../../docs/adr/0221-count-too-many-methods-per-nested-class.md). Parent ticket 24 and downstream Rails parity ticket 101 remain separate.
