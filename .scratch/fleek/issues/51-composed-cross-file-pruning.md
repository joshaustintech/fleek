# 51: Verify composed groups across scopes and files

**What to build:** The same composed method candidates keep original paths, lines, order and pruning semantics in top-level and class scopes across two files.

**Part of:** Ticket 43 / 22.

**Blocked by:** 48; 49; 50; 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Move one already-verified composition into two files and sibling classes. Compare default/liberal pruning, multiple groups, permuted input order and one unsupported sibling retaining supported groups. Reuse existing group-ordering assertions.

## Starting evidence

Existing cross-file, liberal, group-ordering and unsupported-sibling contracts; ADRs 0102, 0109, 0120.

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

The RED probes showed two pruning mismatches. Flay 2.14.4 selected an identical `:ensure` group (mass 32, score 64) for the top-level regexp pair across files, while Fleek emitted an enclosing `:defn`. For classes, Flay emitted a similar `:defn` (mass/score 32) plus an identical `:defn` (mass 6, score 12), while Fleek emitted a `:class` group. A same-file regexp pair plus an unrelated second input must retain its original identical `:defn` group (mass 36, score 72); candidate file provenance now limits cross-file pruning to pairs whose methods actually come from different sources.

Passed the focused public contract for default/liberal modes, both input orders, exact normalized Flay finding records and Fleek groups, same-file pruning where the paired methods span a comment containing the former boundary marker plus an unrelated second input, class multi-group ordering, and a supported cross-file result beside an unsupported sibling. The unsupported case retains score 44, reports `2 selected; 0 analyzed; 2 failed; 0 excluded`, and keeps its warning on stderr. Focused mutations caught changes to cross-file subtree selection, class pruning, the existing mass boundary, and original class method locations.

Commands and evidence (pinned Spinel 2026.09.12, Flay 2.14.4, Reek 6.6.0):

- `PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/duplication_composed_cross_file_contract.rb` — pass.
- `PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild FLEEK_MUTATIONS='Flay class method original locations,Flay mass boundary,Flay composed cross-file subtree selection,Flay composed cross-file class pruning' FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E bin/check_runner.rb mutation` — all four caught.
- `PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true JOBS=4 make check` — pass, 66 workers and four mutation workers; Flay score 0; Reek 0 warnings.
- `PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:/private/tmp/fleek-spinel-pinned-rebuild/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild make ticket-check` — 127 valid issue documents; `git diff --check` — pass.

ADR 0189 records how candidate source provenance limits cross-file pruning to pairs from separate files. Parent Tickets 22/43 remain open; Ticket 52 remains open.
