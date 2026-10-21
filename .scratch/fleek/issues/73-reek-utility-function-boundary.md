# 73: Match UtilityFunction public_methods_only setting

**What to build:** Explicit reek:UtilityFunction matches Reek 6.6.0 for public_methods_only setting, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

The existing unsupported public_methods_only=true case with one public stateless method and one private stateless method; compare pinned visibility behavior and false setting.

## Starting evidence

Existing utility-public-methods configuration and explicit incomplete assertion.

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

Implemented `UtilityFunction` visibility tracking for bare `public`, `private`, and `protected` calls in a single class or module method scope. Default and explicit false still inspect both visibilities; `public_methods_only: true` checks public methods only. Top-level methods and ambiguous class-body statements remain incomplete in public-only mode.

- RED/GREEN: pinned Reek 6.6.0 reports public and private stateless methods by default and with explicit false; with explicit true it reports only `Parcel#public_normalize` at line 2. The compiled Fleek CLI matches the same status, lines, method contexts, and messages for all three settings.
- Boundary: explicit `reek:UtilityFunction` selection with `public_methods_only: true` marks `test/fixtures/utility_function_top_level.rb` incomplete rather than treating its visibility as known.
- Contract: `ruby test/default_argument_api_contract.rb` passed with `BUNDLE_PATH=/private/tmp/fleek-bundle`.
- Mutations: `FLEEK_MUTATIONS='UtilityFunction public visibility filter,UtilityFunction private visibility state' ruby test/mutation_contract.rb` caught both focused mutations.
- Reek: `make reek` passed with zero warnings.
- Full gates: pinned Spinel 2026.09.12 native suite passed for the unchanged Spinel tree (3,596 tests, zero failures/errors, allocation and inference checks, `spin-e2e: ALL GREEN`). `JOBS=4 make check` passed with 72 workers and 4 mutation workers (9m57s); it includes Flay, Reek, and full mutation checks. `make ticket-check` and `git diff --check` passed.
- ADR: [0210](../../../docs/adr/0210-match-utility-function-public-method-setting.md).
- Remaining boundary: singleton methods, inherited overrides, top-level visibility, and non-bare visibility changes are outside this slice.
