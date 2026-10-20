# 48: Compose method parameters with nested blocks

**What to build:** A required/optional/rest/keyword method signature containing a parameterized block preserves Flay grouping and mass.

**Part of:** Ticket 43 / 22.

**Blocked by:** 42; 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use two generated method pairs: one identical, one renamed parameter/default variant. Add one different-arity no-group control. Reuse supported forms only; forwarding/default grammar expansion is separate.

## Starting evidence

Parameter descriptors and existing method/block parameter contracts; ADRs 0146, 0169, 0170.

## Acceptance criteria

- [x] The identical composed case and different-arity no-group control have reproducible fixture inputs and matching pinned public results. The renamed/default variant is a separate subtree-selection defect tracked by ticket 118.
- [x] The focused contract asserts finding/mass/score/locations, coverage, empty stderr streams, and the no-group result.
- [x] Relevant regression and mutation checks pass; Answer records exact commands and the residual issue link.
- [x] The optional-method/block mass behavior is proven; parent 43 remains open until ticket 118 and other residuals resolve.

## Execution and stop condition

Claim this child before implementation; parent claims remain unchanged. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Start with the listed public CLI cases and existing helpers. Record expected versus actual behavior before editing. Implement only this behavior through the existing native path; no new framework, reference-tool fallback or unrelated syntax expansion.

Keep one focused regression and relevant non-equivalent mutations for changed behavior. Use `FLEEK_MUTATIONS` with exact registered labels for focused runs; full mutation coverage remains mandatory before a code commit. Run repository-required build/tests, Flay, Reek, mutation and standards/spec review gates before landing code. Docs/evidence-only work gets tracker/link/diff checks; do not invent implementation proof. Record commands, tool identities, RED/GREEN evidence where code changed, gate results and limitations in `## Answer`.

If cases already pass, add only missing meaningful evidence and finish; do not refactor for activity. If a second independent defect appears, publish a separate minimal child with expected pinned behavior and blockers. This child may finish its stated behavior while those gaps remain open, but the parent completion gate must wait for every residual child. Never turn incomplete coverage into clean output, skip a selected source or weaken a reference expectation to pass.

## Answer

The identical composed case was RED before implementation: pinned Flay 2.14.4 reported mass/score 44/88 at lines 1/7, while Fleek reported 46/92 with complete coverage. The native mass path now removes the nested block-parameter wrapper point when the method signature also contains optional positional or optional keyword parameters. The compiled public CLI contract passes at 44/88 and lines 1/7 for the identical fixture; the different-arity fixture matches Flay's no-group result. The contract checks findings, coverage and empty stderr streams. Focused mutations for the new mass correction and existing method-case mass behavior are caught.

Pinned Spinel 2026.09.12 was built from `/private/tmp/fleek-spinel-pinned-rebuild` (source commit `112bae85c1a25fc5399009a849f805bfe691426b`, tag object `00ce35bb96e489620358ffbc48791001a73778a5`); Flay 2.14.4 and Reek 6.6.0 were used. ADR 0184 records the mass decision. The renamed/default variant was not covered by this ticket's focused contract: it exposed separate Flay subtree-selection behavior, now recorded with pinned evidence in [ticket 118](118-composed-block-subtree-selection.md). Ticket 48 closes its mass behavior, while parent ticket 43 stays open until 118 and other residuals resolve.

Commands: `make all`; `spinel -E test/duplication_composed_parameter_block_contract.rb`; `FLEEK_MUTATIONS='Flay composed parameter block mass,Flay method case condition mass' FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true spinel -E bin/check_runner.rb mutation`; `PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true JOBS=4 make check`; `make ticket-check`; `git diff --check`.

Remaining link: [ticket 118](118-composed-block-subtree-selection.md).
