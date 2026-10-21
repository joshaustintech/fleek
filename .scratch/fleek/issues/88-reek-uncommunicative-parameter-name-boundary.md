# 88: Match UncommunicativeParameterName block parameter names

**What to build:** Verify pinned Reek 6.6.0 and compiled Fleek behavior for block parameter names, including configured name patterns and truthful coverage.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A block with a one-letter parameter and a descriptive-name control, both under default and configured accept/reject patterns; verify whether pinned Reek reports block parameters and compare exact CLI status and context.

## Starting evidence

Existing uncommunicative naming scopes and parameter configuration contracts.

## Acceptance criteria

- [x] Baseline clean/finding and the listed boundary cases match unchanged Reek findings, context, lines and details through the compiled CLI.
- [x] Exercise explicit selection plus configured accept/reject patterns; no unsupported selected source may be labeled complete.
- [x] Relevant regression/evidence checks pass; Answer records exact commands and remaining issue links.
- [x] Stop after this behavior is proven; parent acceptance is not reduced by this child.

## Execution and stop condition

Claim this child before implementation; parent claims remain unchanged. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Start with the listed public CLI cases and existing helpers. Record expected versus actual behavior before editing. Implement only this behavior through the existing native path; no new framework, reference-tool fallback or unrelated syntax expansion.

Keep one focused regression and relevant non-equivalent mutations for changed behavior. Use `FLEEK_MUTATIONS` with exact registered labels for focused runs; full mutation coverage remains mandatory before a code commit. Run repository-required build/tests, Flay, Reek, mutation and standards/spec review gates before landing code. Docs/evidence-only work gets tracker/link/diff checks; do not invent implementation proof. Record commands, tool identities, RED/GREEN evidence where code changed, gate results and limitations in `## Answer`.

If cases already pass, add only missing meaningful evidence and finish; do not refactor for activity. If a second independent defect appears, publish a separate minimal child with expected pinned behavior and blockers. This child may finish its stated behavior while those gaps remain open, but the parent completion gate must wait for every residual child. Never turn incomplete coverage into clean output, skip a selected source or weaken a reference expectation to pass.

## Answer

- Upstream evidence: Reek 6.6.0's `UncommunicativeParameterName#sniff` inspects `expression.parameters`; for a block with `|x|` and `|item|`, pinned Reek reports no findings. The same clean result holds with reject `^item$` and accept `^x$` configured.
- CLI evidence: explicit compiled selection reports both block cases clean, analyzes the selected source, and reports complete coverage. Default and configured output/status match pinned Reek. Existing method-parameter contracts still prove the detector's intended method-argument behavior.
- Decision: no block-parameter analysis is added because it would diverge from Reek 6.6.0. See [ADR 0225](../../../docs/adr/0225-preserve-reek-block-parameter-boundary.md).
- Commands: `bundle exec reek --smell UncommunicativeParameterName test/fixtures/uncommunicative_parameter_name_block.rb`; configured Reek command with `--config test/fixtures/config_uncommunicative_parameter_name_block.yml`; focused `test/default_argument_api_contract.rb`; `JOBS=4 make check` (72 workers and 4 mutation workers); `make -C /private/tmp/fleek-spinel-pinned-rebuild check` (3,596 tests, allocation/infer pass, spin-e2e ALL GREEN; existing `skb` abort trap nonfatal); `make ticket-check`; `git diff --check`.
