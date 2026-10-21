# 74: Match DuplicateMethodCall nested repeated receiver calls

**What to build:** Explicit reek:DuplicateMethodCall matches Reek 6.6.0 for nested repeated receiver calls, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

The same receiver/argument call in two nested branches, then distinct arguments; compare call count, locations and configured allow_calls behavior.

## Starting evidence

Existing DuplicateMethodCall fixtures, multiple allow_calls configuration and source-form comparison.

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

Fleek's existing native visitor already matched the bounded nested-call behavior; no analyzer code change was needed. Added compiled-CLI evidence for calls in separate conditional branches, a distinct-argument control, and configured `allow_calls` suppression.

- RED/GREEN evidence: pinned Reek 6.6.0 and `build/fleek --checks reek:DuplicateMethodCall test/fixtures/duplicate_method_call_nested_branches.rb` both report `[4, 6]:DuplicateMethodCall` for `Parcel#calculate` calling `order.total(:net)` twice. The one `order.total(:gross)` call is not included.
- Configuration: explicit `reek:DuplicateMethodCall` selection with `test/fixtures/config_duplicate_method_call_nested_allow.yml` matches Reek's clean result and reports complete coverage.
- Contract: `ruby test/default_argument_api_contract.rb` passed with `BUNDLE_PATH=/private/tmp/fleek-bundle`.
- Reek: `make reek` passed with zero warnings.
- Full gates: pinned Spinel 2026.09.12 native suite passed for the unchanged Spinel tree (3,596 tests, zero failures/errors, allocation and inference checks, `spin-e2e: ALL GREEN`). `JOBS=4 make check` passed with 72 workers and 4 mutation workers (10m05s); it includes Flay, Reek, and full mutation checks. `make ticket-check` and `git diff --check` passed.
- ADR: [0211](../../../docs/adr/0211-record-nested-duplicate-method-call-parity.md).
- Remaining boundary: other unsupported syntax continues to follow the existing detector coverage rules. Parent ticket 24 and downstream ticket 99 remain separate work.
