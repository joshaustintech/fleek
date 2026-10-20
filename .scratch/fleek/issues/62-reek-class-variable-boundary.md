# 62: Match ClassVariable nested namespace contexts

**What to build:** Explicit reek:ClassVariable matches Reek 6.6.0 for nested namespace contexts, with truthful coverage and normalized status.

**Part of:** Ticket 24.

**Blocked by:** 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

One class inside two nested modules, with read/write occurrences; compare context and line aggregation against a supported one-level baseline.

## Starting evidence

Existing ClassVariable scope/namespace contracts; native simple-scope restriction.

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

- RED: the existing two-module fixture returned incomplete coverage; the new public contract failed with `nested namespace ClassVariable status differs from Reek`.
- GREEN: one- and two-level namespace fixtures match pinned Reek 6.6.0 finding context, message, and grouped lines (`3, 6` and `4, 6, 9`). Configured exclusion of `ApplicationCable::Internal::Connection` removes the nested finding. Three-level and wrapped class declarations remain incomplete.
- Pinned identity: Spinel 2026.09.12, commit `112bae85c1a25fc5399009a849f805bfe691426b`; Reek 6.6.0.
- Verification commands:

  ```sh
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild make build/fleek
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/class_variable_contract.rb
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/configuration_contract.rb
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/class_variable_scope_contract.rb
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle BUNDLE_GEMFILE="$PWD/Gemfile" SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild FLEEK_MUTATIONS='ClassVariable namespace context traversal,ClassVariable nested namespace class support,ClassVariable nested namespace boundary' JOBS=2 /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E bin/check_runner.rb mutation
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild JOBS=4 make check
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle make flay reek
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild make ticket-check
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:/opt/homebrew/opt/make/libexec/gnubin:/opt/homebrew/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle /opt/homebrew/bin/gmake -C /private/tmp/fleek-spinel-pinned-rebuild check
  git diff --cached --check
  ```

- Full gate: `make check` completed with 72 workers and all four mutation workers passed. Flay score is 175, unchanged from the prior baseline; Reek reports 0 warnings. Pinned Spinel `make check` completed with 3,596 passing tests, 0 failures, 0 errors; `spin-e2e: ALL GREEN`.
- Limits: direct two-module class declarations only. Deeper and wrapped namespace residuals are tracked in [issue 123](123-class-variable-deeper-and-wrapped-namespaces.md).
