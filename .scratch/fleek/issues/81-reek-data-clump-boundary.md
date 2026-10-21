# 81: Match DataClump singleton method parameter groups

**What to build:** Explicit reek:DataClump matches Reek 6.6.0 for singleton method parameter groups, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A class with repeated parameter groups across singleton methods, plus different parameter sets; derive upstream participation rules rather than counting every definition.

## Starting evidence

Existing DataClump mixed-unsupported-method regression and direct-instance-method restriction.

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

- RED: with singleton methods and instance methods mixed, pinned Reek 6.6.0 produced two clumps while Fleek initially treated the singleton-class body as unsupported and counted only instance methods.
- GREEN: explicit `reek:DataClump` matches Reek groups exactly: `['destination', 'origin']` across 9 methods (lines 3–8, 13–15), and `['destination', 'origin', 'weight']` across 8 methods (lines 3–6, 8, 13–15). `def self.external` at line 11 is excluded per Reek. `min_clump_size: 3` keeps only the three-parameter finding.
- Commands: `make all`; `ruby test/default_argument_api_contract.rb`; focused `FLEEK_MUTATIONS='DataClump singleton parameter participation,missing DataClump finding' ruby test/mutation_contract.rb`; full `JOBS=4 make check` (72 workers, four mutation workers, 10:57); pinned Spinel `make -C /private/tmp/fleek-spinel-pinned-rebuild check`; `make ticket-check`; `git diff --check`.
- Both focused mutations were caught. Full project gates passed; Reek reported zero warnings. Pinned Spinel 2026.09.12 passed 3,596 tests, allocation/inference checks, and `spin-e2e: ALL GREEN`; `skb` abort trap was nonfatal.
- Boundary: direct `class << self` methods and instance methods participate. Direct `def self.method` follows Reek exclusion. Parent ticket 24 and downstream manifest ticket 101 remain separate.
- ADR: [0218](../../../../docs/adr/0218-match-dataclump-singleton-participation.md).
