# 92: Verify Reek comment suppression scope

**What to build:** Detector comment suppression applies to the same method/class and source lines as pinned Reek without hiding adjacent findings.

**Part of:** Ticket 24.

**Blocked by:** 90 (resolved); 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use ClassVariable and one direct method detector: class-wide suppression, method-local suppression, setting-bearing suppression and adjacent unsuppressed method. Retain exact upstream semantics; record unsupported directive forms as individual follow-up tickets.

## Starting evidence

Existing ClassVariable suppression contract and native suppression parsing; spec 04 suppression requirement.

## Acceptance criteria

- [x] Listed behavior cases have reproducible inputs, pinned expected results and matching public behavior. Inventory-only work records evidence and concrete child links; completion gates remain open until every required residual gap resolves.
- [x] Semantic findings, coverage, streams and normalized outcome are asserted where applicable; evidence-only inventories distinguish verified rows from unresolved work.
- [x] Relevant regression/mutation or evidence checks pass; Answer records exact commands and remaining issue links.
- [x] Stop after this behavior is proven; parent acceptance is not reduced by this child.

## Execution and stop condition

Claim this child before implementation; parent claims remain unchanged. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Start with the listed public CLI cases and existing helpers. Record expected versus actual behavior before editing. Implement only this behavior through the existing native path; no new framework, reference-tool fallback or unrelated syntax expansion.

Keep one focused regression and relevant non-equivalent mutations for changed behavior. Use `FLEEK_MUTATIONS` with exact registered labels for focused runs; full mutation coverage remains mandatory before a code commit. Run repository-required build/tests, Flay, Reek, mutation and standards/spec review gates before landing code. Docs/evidence-only work gets tracker/link/diff checks; do not invent implementation proof. Record commands, tool identities, RED/GREEN evidence where code changed, gate results and limitations in `## Answer`.

If cases already pass, add only missing meaningful evidence and finish; do not refactor for activity. If a second independent defect appears, publish a separate minimal child with expected pinned behavior and blockers. This child may finish its stated behavior while those gaps remain open, but the parent completion gate must wait for every residual child. Never turn incomplete coverage into clean output, skip a selected source or weaken a reference expectation to pass.

## Answer

Pinned Spinel 2026.09.12 (`112bae85c1a25fc5399009a849f805bfe691426b`; tag object `00ce35bb96e489620358ffbc48791001a73778a5`), Flay 2.14.4, and Reek 6.6.0. Before editing, `spinel -E test/default_argument_api_contract.rb` failed on class-wide LongParameterList suppression status. Added fixtures for a suppressed class and adjacent methods with bare, setting-bearing, and repeated directives. Fleek's public report is compared with the pinned Reek report, including status, coverage, streams, and findings; repeated same-detector directives use the last configuration as Reek does.

`test/default_invocation_contract.rb` initially exposed a top-level method with no class/module scope; the suppression helper now handles that null scope. `test/default_invocation_contract.rb` and `test/default_argument_api_contract.rb` pass under the pinned compiler. The full `make check JOBS=4` passed 72 workers, including four mutation shards; the `LongParameterList comment suppression` mutation was caught. `make -C /private/tmp/fleek-spinel-pinned-rebuild check` passed, including 3,596 native tests and `spin-e2e: ALL GREEN`. `make ticket-check` validated 135 documents. `bundle exec flay bin` reported score 0; `bundle exec reek bin test/*.rb` reported 0 warnings; `git diff --check` passed.

The broader `bundle exec flay bin test/*.rb` reports score 1,008, identical to clean base commit `1a9a263d767cce95b4ecfbd96a3e3b25baeb9a3c`; these pre-existing test-corpus similarities are not introduced by this ticket. No unresolved gap remains within the listed cases. ADR 0229 records the scope and precedence decision.
