# 75: Match ManualDispatch guarded dispatch inside a branch

**What to build:** Explicit reek:ManualDispatch matches Reek 6.6.0 for guarded dispatch inside a branch, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A respond_to? guard and receiver call inside a nested if, plus an unguarded clean control; compare actual pinned contexts/locations.

## Starting evidence

Existing ManualDispatch fixture and simple-method-body restriction.

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

Fleek's existing native visitor already matched nested `respond_to?` guards; no analyzer code change was needed. Added compiled-CLI evidence for the nested guard, an unguarded clean control, and method-context exclusion.

- RED/GREEN evidence: pinned Reek 6.6.0 and `build/fleek --checks reek:ManualDispatch test/fixtures/manual_dispatch_nested_guard.rb` report `Parcel#guarded_dispatch` at line 3. `Parcel#unguarded_dispatch` stays clean. Findings, status, context, and details match.
- Configuration: explicit `reek:ManualDispatch` selection with `test/fixtures/config_manual_dispatch_exclusion.yml` excludes `Parcel#guarded_dispatch` and yields a complete clean result matching Reek.
- Contract: `ruby test/default_argument_api_contract.rb` passed with `BUNDLE_PATH=/private/tmp/fleek-bundle`.
- Reek: `make reek` passed with zero warnings.
- Full gates: pinned Spinel 2026.09.12 native suite passed for the unchanged Spinel tree (3,596 tests, zero failures/errors, allocation and inference checks, `spin-e2e: ALL GREEN`). `JOBS=4 make check` passed with 72 workers and 4 mutation workers (10m43s); it includes Flay, Reek, and full mutation checks. `make ticket-check` and `git diff --check` passed.
- ADR: [0212](../../../docs/adr/0212-record-nested-manual-dispatch-parity.md).
- Remaining boundary: other unsupported syntax continues to follow existing detector coverage rules. Parent ticket 24 and downstream ticket 100 remain separate work.
