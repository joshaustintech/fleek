# 87: Match UncommunicativeModuleName qualified namespace names

**What to build:** Explicit reek:UncommunicativeModuleName matches Reek 6.6.0 for qualified namespace names, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A qualified nested class/module name containing a short component versus descriptive components; derive upstream component/context handling and accept patterns.

## Starting evidence

Existing naming unsupported-scope fixture and module-name configured contract.

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

- RED: Reek 6.6.0 reports `Fleet::S` on line 1 by default; the existing compiled CLI marked the selected qualified path incomplete. The configured reject `^Shipment$` and accept `^S$` patterns produce only `Fleet::Shipment` on line 4.
- GREEN: the compiled CLI matches default and configured Reek findings, qualified contexts, terminal names, and lines. The descriptive `Shipment` declaration is clean by default, while the accept/reject configuration selects it. `Fleet::Packages::S` remains incomplete (`1 selected; 0 analyzed; 1 failed`).
- Mutation: `FLEEK_MUTATIONS='UncommunicativeModuleName qualified context' ruby test/mutation_contract.rb` caught the context mutant.
- Verification: pinned Spinel `2026.09.12` at `00ce35bb96e489620358ffbc48791001a73778a5`; Flay `2.14.4`; Reek `6.6.0`.
- Commands: `bundle exec reek --smell UncommunicativeModuleName test/fixtures/uncommunicative_module_name_qualified.rb`; configured Reek command with `--config test/fixtures/config_uncommunicative_module_name_qualified.yml`; focused `test/default_argument_api_contract.rb`; focused mutation command above; `JOBS=4 make check` (72 workers, 4 mutation workers; Flay pass; Reek 0 findings); `make -C /private/tmp/fleek-spinel-pinned-rebuild check` (3,596 tests, allocation/infer pass, spin-e2e ALL GREEN; existing `skb` abort trap nonfatal); `make ticket-check`; `git diff --check`.
- Decision: [ADR 0224](../../../docs/adr/0224-match-qualified-module-name-paths.md). Parent 24 and downstream Rails parity ticket 101 remain separate.
