# 71: Match ControlParameter nested conditional use

**What to build:** Explicit reek:ControlParameter matches Reek 6.6.0 for nested conditional use, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A parameter controlling an if inside a loop, then the same parameter also used as data; compare exact conditional lines and suppression boundary.

## Starting evidence

Existing logical-condition/body-use contracts and direct-condition native scope.

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

Implemented ControlParameter traversal for one iterator block per method, limited to supported AST forms. `UnusedParameters` retains its existing block boundary; additional blocks and unsupported nodes still report incomplete.

- RED: pinned Reek 6.6.0 reported `[4]:ControlParameter: Parcel#choose is controlled by argument 'flag'`; Fleek initially reported incomplete for `test/fixtures/control_parameter_nested_loop.rb`.
- GREEN: `build/fleek --checks reek:ControlParameter test/fixtures/control_parameter_nested_loop.rb` reports the matching finding at line 4. `choose_with_data` remains clean. The exclusion fixture `test/fixtures/config_control_parameter_nested_exclusion.yml` yields clean, complete coverage under explicit selection. The report names the one-block scope, and `test/fixtures/control_parameter_multiple_blocks.rb` remains incomplete.
- Contract: `ruby test/default_argument_api_contract.rb` with `BUNDLE_PATH=/private/tmp/fleek-bundle` passed and compares exact Reek/Fleek findings, status, line, context, and message.
- Mutations: `FLEEK_MUTATIONS='nested ControlParameter block traversal,nested ControlParameter data use suppression' ruby test/mutation_contract.rb` caught both focused non-equivalent mutations.
- Pinned compiler/runtime: Spinel 2026.09.12 at `/private/tmp/fleek-spinel-pinned-rebuild`; native suite passed with 3,596 tests, 0 failures/errors, allocation and inference checks, and `spin-e2e: ALL GREEN`.
- Full gates: `JOBS=4 make check` passed with 72 workers and 4 mutation workers (9m20s). `make ticket-check` passed with 134 valid documents; `git diff --check` passed. The repository's Flay, Reek, and mutation gates are included in `make check`.
- ADR: [0208](../../../docs/adr/0208-match-control-parameter-inside-one-iterator-block.md).
- Remaining boundary: multi-block and unsupported AST forms remain incomplete. Parent ticket 24 and ticket 99 remain separate work.
