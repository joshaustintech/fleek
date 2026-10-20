# 64: Match InstanceVariableAssumption nested class instance-variable use

**What to build:** Explicit reek:InstanceVariableAssumption matches Reek 6.6.0 for nested class instance-variable use, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A nested class with an uninitialized instance-variable read, then initialization in initialize; compare context, lines and clean boundary.

## Starting evidence

Existing default-object contract and direct-instance-method traversal.

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

- RED: `test/default_object_scope_contract.rb` failed with `nested InstanceVariableAssumption status differs from Reek`. Pinned Reek reports `Profile::Credentials` at line 2 for uninitialized `@name`; explicit Fleek selection marked the source incomplete.
- GREEN: direct nested class findings now match Reek's context and class declaration line. A nested `initialize` assignment removes the warning, and configured exclusion of `Profile::Credentials` leaves a complete clean result. Both run through explicit compiled-CLI selection.
- Focused contract: `BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/default_object_scope_contract.rb` — pass.
- Focused mutations: `FLEEK_MUTATIONS='InstanceVariableAssumption nested class scope acceptance,InstanceVariableAssumption nested initialization boundary' SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/mutation_contract.rb` — both caught.
- Pinned Reek identity: 6.6.0. Spinel identity: 2026.09.12, commit `112bae85c1a25fc5399009a849f805bfe691426b`.
- Full Fleek gate: `BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel JOBS=4 make check` — 72 workers passed; all 4 mutation workers passed; Flay score 175; Reek 0 warnings.
- Tracker gate: `BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel make ticket-check` — 134 valid documents.
- Focused Reek and Flay gates: `BUNDLE_PATH=/private/tmp/fleek-bundle make reek flay` — Reek 0 warnings; Flay score 175.
- Pinned Spinel gate: `PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:/opt/homebrew/opt/make/libexec/gnubin:/opt/homebrew/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle /opt/homebrew/bin/gmake -C /private/tmp/fleek-spinel-pinned-rebuild check` — 3,596 pass, 0 fail, 0 errors; `spin-e2e: ALL GREEN`.
- `git diff --check` — pass.
- Deeper nested and module-wrapped classes remain incomplete. Reek reports `Profile::Account::Credentials` at line 3 and `Profiles::Credentials` at line 2, respectively; Fleek marks both incomplete. Tracked in [issue 125](125-instance-variable-assumption-deeper-and-wrapped-scopes.md).
- Spec review: accepted behavior and residual boundary are covered.
- Standards review found hidden reads/writes of shared source and finding buffers. The helper now receives the source pointer, output buffer, and capacity explicitly; no documented-standard breach remains.
- Standards review noted the output buffer/capacity/used parameters form a possible data clump. Kept this bounded helper interface; no second abstraction is needed for two call sites.
