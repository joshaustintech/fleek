# 72: Match UnusedParameters block-local shadowing

**What to build:** Explicit reek:UnusedParameters matches Reek 6.6.0 for block-local shadowing, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A method parameter shadowed by a block parameter versus a method parameter captured by the block; derive name-use rules from pinned Reek.

## Starting evidence

Existing UnusedParameters fixture and supported parameter/body traversal.

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

Implemented `UnusedParameters` local-use traversal through one iterator block. It counts reads and writes inside the block by name, matching Reek 6.6.0 even when a same-name block parameter shadows the method parameter. Methods with multiple blocks or unsupported syntax remain incomplete; `ControlParameter` behavior remains detector-specific.

- RED: Reek 6.6.0 reports only `Parcel#unused` at line 14 for `test/fixtures/unused_parameters_block_shadowing.rb`; `Parcel#shadowed` and `Parcel#captured` are clean. Fleek initially marked the selected source incomplete.
- GREEN: compiled CLI explicit selection matches Reek's status, line, method context, name, message, and finding. Explicit selection with `test/fixtures/config_unused_parameters_block_exclusion.yml` excludes the unused method and matches Reek's clean result.
- Boundary: `test/fixtures/control_parameter_multiple_blocks.rb` stays incomplete when selected for `UnusedParameters`; the output states the one-block scope.
- Focused contract: `ruby test/default_argument_api_contract.rb` passed with `BUNDLE_PATH=/private/tmp/fleek-bundle`.
- Focused mutations: `FLEEK_MUTATIONS='UnusedParameters block body traversal,UnusedParameters block captures' ruby test/mutation_contract.rb` caught both mutations.
- Reek: `make reek` passed with zero warnings.
- Full gates: pinned Spinel 2026.09.12 native suite previously passed for this unchanged Spinel tree (3,596 tests, 0 failures/errors, allocation and inference checks, `spin-e2e: ALL GREEN`). `JOBS=4 make check` passed with 72 workers and 4 mutation workers (9m36s); it includes Flay, Reek, and full mutation checks. `make ticket-check` and `git diff --check` passed.
- ADR: [0209](../../../docs/adr/0209-match-unused-parameters-block-local-uses.md).
- Remaining boundary: multiple block bodies and unsupported method syntax remain incomplete. Parent ticket 24 and downstream ticket 99 remain separate work.
