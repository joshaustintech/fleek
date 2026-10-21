# 65: Match SubclassedFromCoreClass Class.new inheritance

**What to build:** Explicit reek:SubclassedFromCoreClass matches Reek 6.6.0 for Class.new inheritance, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A constant assigned Class.new(Array), plus Class.new of a non-core class as clean control; reference fixture already demonstrates unsupported behavior.

## Starting evidence

Existing Class.new assignment fixture and default-object unsupported-shape contract.

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

- Baseline RED: pinned Reek 6.6.0 reports `[1]:SubclassedFromCoreClass: RecordSet inherits from core class 'Array'`; Fleek reported the selected source failed/incomplete. Added the public CLI contract first and confirmed `Class.new(Array) status differs from Reek`.
- GREEN: `Class.new(Array)` now matches Reek findings, source line, and status. The custom constant superclass remains clean and complete; exclusion remains clean and complete. A dynamic `Class.new(resolve_superclass)` selected source stays failed/incomplete while pinned Reek is clean.
- Design: `fleek_core_subclass` keeps the Array/Hash/String policy in one place for ordinary class declarations and direct `Class.new` assignments. Other `Class.new` shapes stay unsupported. See ADR 0202.
- Focused commands passed:
  - `BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/default_object_scope_contract.rb`
  - `FLEEK_MUTATIONS='missing SubclassedFromCoreClass finding,unsupported Class.new assignment,missing Class.new SubclassedFromCoreClass finding,false-positive Class.new SubclassedFromCoreClass finding' BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/mutation_contract.rb` — all four mutations caught.
  - `time env BUNDLE_PATH=/private/tmp/fleek-bundle make reek` — 0 warnings.
- Full gates passed with Spinel 2026.09.12 at `00ce35bb96e489620358ffbc48791001a73778a5`: `time env BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel JOBS=4 make check` — 72 workers passed, mutation workers=4; and `/opt/homebrew/bin/gmake -C /private/tmp/fleek-spinel-pinned-rebuild check` — 3,596 tests passed, zero failures/errors, `spin-e2e: ALL GREEN`. `SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild BUNDLE_PATH=/private/tmp/fleek-bundle make ticket-check` — 134 valid; `git diff --check` passed.
- Reviews: spec review requested an unsupported selected-input contract; added the dynamic-superclass case. Standards review found duplicated core-superclass policy; centralized it and updated its mutation selector. No open gap remains for this ticket.
