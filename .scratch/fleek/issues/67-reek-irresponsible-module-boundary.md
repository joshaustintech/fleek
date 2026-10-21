# 67: Match IrresponsibleModule Class.new comments

**What to build:** Explicit reek:IrresponsibleModule matches Reek 6.6.0 for Class.new comments, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A constant assigned Class.new without documentation, then with a descriptive comment; derive comment association from pinned Reek.

## Starting evidence

Existing Class.new assignment/default-object unsupported-shape contract.

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

- RED: pinned Reek 6.6.0 reports `[1]:IrresponsibleModule: RecordSet has no descriptive comment` for `RecordSet = Class.new(Array)`; Fleek previously marked that selected source incomplete. The compiled CLI contract first failed with `undocumented Class.new status differs from Reek`.
- GREEN: Fleek now matches the finding and line for an undocumented direct assignment. A descriptive comment is clean and complete. A configured exclusion for `RecordSet` stays complete and clean. A dynamic superclass assignment remains unsupported/incomplete.
- Boundary: support one direct constant assignment to `Class.new` with exactly one constant superclass argument, no block, and no class/module declarations in the source. Comment association uses the assigned constant. Other forms stay incomplete. See ADR 0204.
- Focused verification passed: `BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/default_object_scope_contract.rb`; `FLEEK_MUTATIONS='missing IrresponsibleModule finding,unsupported Class.new assignment,missing undocumented Class.new finding,false-positive described Class.new' BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/mutation_contract.rb` — all four mutations caught; `time env BUNDLE_PATH=/private/tmp/fleek-bundle make reek` — 0 warnings.
- Pinned Spinel 2026.09.12 at `00ce35bb96e489620358ffbc48791001a73778a5`: `/opt/homebrew/bin/gmake -C /private/tmp/fleek-spinel-pinned-rebuild check` passed, 3,596 tests, zero failures/errors, `spin-e2e: ALL GREEN`. Full Fleek gate: `time env BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel JOBS=4 make check` — 72 workers passed, mutation workers=4. `SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild BUNDLE_PATH=/private/tmp/fleek-bundle make ticket-check` — 134 valid; `git diff --check` passed.
