# 89: Match UncommunicativeVariableName block-local names

**What to build:** Explicit reek:UncommunicativeVariableName matches Reek 6.6.0 for block parameters and block-local assignments in direct methods, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

The existing unsupported block-argument case plus one block-local assignment; compare one-letter, descriptive and configured accepted names without leaking names across scopes.

## Starting evidence

Existing block-argument incomplete assertion and variable naming configuration contract.

## Acceptance criteria

- [x] Baseline clean/finding and the listed boundary cases match unchanged Reek findings, context, lines and details through the compiled CLI.
- [x] Exercise explicit selection plus configured accept/reject patterns; unsupported block parameter forms remain incomplete.
- [x] Relevant regression/mutation or evidence checks pass; Answer records exact commands and remaining issue links.
- [x] Stop after this behavior is proven; parent acceptance is not reduced by this child.

## Execution and stop condition

Claim this child before implementation; parent claims remain unchanged. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Start with the listed public CLI cases and existing helpers. Record expected versus actual behavior before editing. Implement only this behavior through the existing native path; no new framework, reference-tool fallback or unrelated syntax expansion.

Keep one focused regression and relevant non-equivalent mutations for changed behavior. Use `FLEEK_MUTATIONS` with exact registered labels for focused runs; full mutation coverage remains mandatory before a code commit. Run repository-required build/tests, Flay, Reek, mutation and standards/spec review gates before landing code. Docs/evidence-only work gets tracker/link/diff checks; do not invent implementation proof. Record commands, tool identities, RED/GREEN evidence where code changed, gate results and limitations in `## Answer`.

If cases already pass, add only missing meaningful evidence and finish; do not refactor for activity. If a second independent defect appears, publish a separate minimal child with expected pinned behavior and blockers. This child may finish its stated behavior while those gaps remain open, but the parent completion gate must wait for every residual child. Never turn incomplete coverage into clean output, skip a selected source or weaken a reference expectation to pass.

## Answer

- RED: before implementation, explicit selection marked block parameter/local cases incomplete and retained only the supported assignment finding. Pinned Reek 6.6.0 reports block parameter `x` on line 3 and local `n2` on line 4 in `Worker#perform`; it reports `z` on line 12 and `q2` on line 13 in `Worker#archive`.
- GREEN: the compiled CLI now matches Reek's findings, lines, names, and separate method contexts. With reject `^item$` and accept `^x$`, it reports only `item` on line 6. The existing `uncommunicative_variable_name_partial.rb` case is now complete and preserves its method-local `x` finding. Optional, rest, keyword, destructured, semicolon-declared block locals, and class-level block parameter scopes remain incomplete.
- Mutation: `FLEEK_MUTATIONS='UncommunicativeVariableName block parameters' ruby test/mutation_contract.rb` caught removal of block parameter analysis.
- Verification: pinned Spinel `2026.09.12` at `00ce35bb96e489620358ffbc48791001a73778a5`; Flay `2.14.4`; Reek `6.6.0`.
- Commands: `bundle exec reek --smell UncommunicativeVariableName test/fixtures/uncommunicative_variable_name_blocks.rb`; configured Reek command with `--config test/fixtures/config_uncommunicative_variable_name_blocks.yml`; focused `test/default_argument_api_contract.rb`; focused mutation command above; `JOBS=4 make check` (72 workers, 4 mutation workers; Flay pass; Reek 0 findings); `make -C /private/tmp/fleek-spinel-pinned-rebuild check` (3,596 tests, allocation/infer pass, spin-e2e ALL GREEN; existing `skb` abort trap nonfatal); `make ticket-check`; `git diff --check`.
- Decision: [ADR 0226](../../../docs/adr/0226-match-uncommunicative-block-variable-names.md). Parent ticket 24 and downstream Rails parity ticket 101 remain separate.
