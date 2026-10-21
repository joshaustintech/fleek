# 96: Record exact gaps on the pinned Rails manifest

**What to build:** The unchanged 25-file Rails corpus yields an actionable mismatch list per analyzer, detector and source shape.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use revision 92ce7c470bc31952d7dc51cac15e577a948e479e and the existing exact app Ruby manifest. Capture versions, settings, sources, reference outputs and Fleek results. Enumerate all 29 Reek detectors, including opt-in, separately from Flay. Do not rewrite the old partial contract to assert success. For each distinct mismatch publish one child with the smallest reproducer, native result, pinned expected result and blocker edges; deduplicate against this breakdown.

## Starting evidence

Existing RailsManifestParityContract (currently asserts Flay incomplete and only Reek ClassVariable), Rails research receipt and corpus revision pin.

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

Recorded the 29-detector census and Flay result from the exact pinned 25-file Rails manifest in [the research receipt](../../../docs/research/rails-reek-census-96.md). Tool identities: Spinel 2026.09.12, Reek 6.6.0, Flay 2.14.4. `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce make rails-manifest-parity` passed its existing partial contract; it explicitly reports Flay incomplete. Each detector was separately run against the same sorted manifest with `bundle exec reek --smell D --no-progress <files>` and `build/fleek --checks reek:D <files>`. The receipt records every detector's status, findings, coverage, and source-shape failures.

The opt-in `UnusedPrivateMethod` detector crashes on the minimal `FrameworkJob < ActiveJob::Base` fixture. Pinned Reek exits 0 without findings; Fleek exits 139. The reproduction is recorded in [issue 127](127-unused-private-method-framework-subclass-crash.md), linked from issue 102, and its fixture is `test/fixtures/unused_private_method_framework_subclass.rb`.

Evidence gates: `make ticket-check` passed; `git diff --check` passed. No implementation changed, so full native, analyzer and mutation gates were not applicable. Decision: preserve incomplete/failed coverage as explicit evidence, keep the existing partial contract unchanged, and route each residual family to issues 97–101 plus the crash child 127; [ADR 0232](../../../docs/adr/0232-record-rails-detector-residuals.md) records this boundary. Ticket 96 does not close parent 24 or gate 102.
