# 66: Match ModuleInitialize nested module initialize methods

**What to build:** Explicit reek:ModuleInitialize matches Reek 6.6.0 for nested module initialize methods, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A nested module defining initialize versus a normal method; preserve module context and exact definition line.

## Starting evidence

Existing ModuleInitialize/default-object contract and simple-module scope restriction.

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

- RED: `BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/default_object_scope_contract.rb` failed with `nested ModuleInitialize status differs from Reek`. Pinned Reek 6.6.0 reports `[2]:ModuleInitialize: Outer::InitializerMixin has initialize method`; Fleek marked the selected nested-module source incomplete.
- GREEN: the compiled CLI now matches that finding, qualified module context, and definition line. The same fixture's `reset` method remains clean; a configured exclusion for `Outer::InitializerMixin` is complete and clean.
- Boundary: support is exactly one direct nested module with direct instance methods, no classes, and no additional module scopes. Other module trees remain incomplete. Scope limits output now describes this boundary. See ADR 0203.
- Focused verification passed: the command above; `FLEEK_MUTATIONS='missing ModuleInitialize finding,nested ModuleInitialize scope acceptance,nested ModuleInitialize context' BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/mutation_contract.rb` — all three mutations caught; `time env BUNDLE_PATH=/private/tmp/fleek-bundle make reek` — 0 warnings.
- Pinned Spinel 2026.09.12 at `00ce35bb96e489620358ffbc48791001a73778a5`: `/opt/homebrew/bin/gmake -C /private/tmp/fleek-spinel-pinned-rebuild check` passed, 3,596 tests, zero failures/errors, `spin-e2e: ALL GREEN`. Full Fleek gate: `time env BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel JOBS=4 make check` — 72 workers passed, mutation workers=4. `SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild BUNDLE_PATH=/private/tmp/fleek-bundle make ticket-check` — 134 valid; `git diff --check` passed.
