# 63: Match Attribute nested class attribute declarations

**What to build:** Explicit reek:Attribute matches Reek 6.6.0 for nested class attribute declarations, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

A nested class with literal attr_accessor/attr_writer plus a read-only attr_reader control; compare finding locations and inherited visibility setting.

## Starting evidence

Existing Attribute alias/visibility/default-object contracts; one-simple-class scope restriction.

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

- RED: the new nested public contract failed with `nested Attribute status differs from Reek`; Reek reported `attr_accessor` and `attr_writer` in `Profile::Credentials`, while the selected Fleek check returned incomplete coverage.
- GREEN: nested `attr_accessor :secret` and `attr_writer :token` match Reek at lines 5 and 6 with qualified contexts; `attr_reader :label` stays clean. The enclosing `private` does not leak into the child class. Configured exclusion of `Profile::Credentials#secret` removes only that finding. Coverage, status, and stderr are asserted through explicit CLI selection.
- Pinned identity: Spinel 2026.09.12, commit `112bae85c1a25fc5399009a849f805bfe691426b`; Reek 6.6.0.
- Focused contract: `SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel make build/fleek`; then `SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/default_object_scope_contract.rb` — pass.
- Focused mutations: `FLEEK_MUTATIONS='Attribute nested class scope acceptance,Attribute nested class visibility isolation' SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/mutation_contract.rb` — both caught.
- Full Fleek gate: `BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel JOBS=4 make check` — 72 workers passed; all 4 mutation workers passed; Flay score 175 (no new duplication); Reek 0 warnings.
- Tracker gate: `BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel make ticket-check` — 133 valid documents.
- Pinned Spinel gate: `PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:/opt/homebrew/opt/make/libexec/gnubin:/opt/homebrew/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle /opt/homebrew/bin/gmake -C /private/tmp/fleek-spinel-pinned-rebuild check` — 3,596 pass, 0 fail, 0 errors; `spin-e2e: ALL GREEN`.
- `git diff --check` — pass. Pinned reference is Reek 6.6.0; Spinel is 2026.09.12 at `112bae85c1a25fc5399009a849f805bfe691426b`.
- Limits: deeper and wrapped class scopes remain incomplete and are tracked in [issue 124](124-attribute-deeper-and-wrapped-class-scopes.md).
