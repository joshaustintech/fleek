# 61: Honor private-method visibility and opt-in configuration

**What to build:** UnusedPrivateMethod honors pinned visibility changes and configuration enablement while default selection stays correct.

**Part of:** Ticket 24.

**Blocked by:** 60; 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Compare private section versus private :helper, a method becoming public, calls from another private method, explicit selection, config-enabled defaults and explicit disable. Use one tiny class per distinguishing behavior. Queue any inherited/dynamic-call gap as its own child rather than guessing call-graph semantics.

## Starting evidence

Existing Reek configuration precedence and disabled-opt-in contracts; pinned UnusedPrivateMethod implementation.

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

- RED: the new `private :hidden` fixture returned `UnusedPrivateMethod findings differ from Reek` through the public contract. Pinned Reek 6.6.0 reports the method when the detector is enabled.
- GREEN: the public contract now matches Reek for named private visibility, visibility reopened with `public`, and a call from one private method to another. It checks findings, coverage, stderr, and normalized statuses. Existing contracts verify explicit selection, configured default enablement, default opt-in exclusion, and explicit disablement.
- Pinned identity: Spinel 2026.09.12, commit `112bae85c1a25fc5399009a849f805bfe691426b`; Reek 6.6.0.
- Verification commands:

  ```sh
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild make build/fleek
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/default_argument_api_contract.rb
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/default_invocation_contract.rb
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/default_configuration_contract.rb
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle BUNDLE_GEMFILE="$PWD/Gemfile" SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild FLEEK_MUTATIONS='UnusedPrivateMethod private visibility,UnusedPrivateMethod named visibility,UnusedPrivateMethod public visibility,UnusedPrivateMethod direct call tracking,UnusedPrivateMethod dynamic call boundary' JOBS=3 /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E bin/check_runner.rb mutation
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle BUNDLE_GEMFILE="$PWD/Gemfile" SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild JOBS=4 make check
  PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild make ticket-check
  git diff --cached --check
  ```

  Full check completed with 72 passing workers, including four mutation workers; ticket check validated 130 documents.
- Full gate: build and contracts pass; full mutation inventory passes. Repository Flay score remains 175, unchanged from `origin/main`; Reek reports 0 warnings. Standards and spec reviews found no issues.
- Limits: inherited and reflection-based call parity is tracked in [issue 122](122-unused-private-method-call-graph-residuals.md), under ADR 0197. Multi-symbol visibility changes and symbol directives before method definitions remain outside this bounded behavior.
