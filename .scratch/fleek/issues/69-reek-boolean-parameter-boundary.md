# 69: Match BooleanParameter singleton method boolean defaults

**What to build:** Explicit reek:BooleanParameter matches Reek 6.6.0 for singleton method boolean defaults, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A def self.method flag=true method and a nonboolean-default control; compare parameter identity, definition location and detector enablement.

## Starting evidence

Existing BooleanParameter/default argument contracts and direct-instance-method restriction.

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

- The native behavior already matched Reek 6.6.0. The new compiled-CLI contract covers `def self.requeue(force = true)` against a numeric `seconds = 5` default control. Pinned Reek and Fleek both report `[2]:BooleanParameter: Parcel#self.requeue has boolean parameter 'force'`, with the same parameter identity, singleton context, and method line.
- Explicit `reek:BooleanParameter` selection is compared against Reek. With BooleanParameter disabled in configuration, Reek returns no findings and Fleek reports the explicit selected check as disabled before analysis.
- Focused evidence passed: `BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/default_argument_api_contract.rb`; `time env BUNDLE_PATH=/private/tmp/fleek-bundle make reek` — 0 warnings.
- Pinned Spinel 2026.09.12 at `00ce35bb96e489620358ffbc48791001a73778a5`: `/opt/homebrew/bin/gmake -C /private/tmp/fleek-spinel-pinned-rebuild check` passed, 3,596 tests, zero failures/errors, `spin-e2e: ALL GREEN`. Full Fleek gate: `time env BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel JOBS=4 make check` — 72 workers passed, mutation workers=4. `SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild BUNDLE_PATH=/private/tmp/fleek-bundle make ticket-check` — 134 valid; `git diff --check` passed.
- No code behavior changed; ADR 0206 records the already-supported contract and its detector-disable control.
