# 57: Match Flay path expansion and duplicate inputs

**What to build:** Explicit files and directories yield the same selected Flay sources and deterministic findings as pinned Flay. Empty and unmatched literal wildcard argv follow the accepted fail-closed exceptions in [ADR 0195](../../../docs/adr/0195-deduplicate-flay-source-paths.md), not source-parity claims.

**Part of:** Ticket 23.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use a tiny tree with overlapping arguments, duplicate paths, missing and empty inputs, hidden directory and directory symlink. Pass literal glob arguments through subprocess argv so the shell cannot expand them first; assert the documented fail-closed exceptions from ADR 0195. Document any existing intentional Fleek safety policy separately from a parity gap; do not silently weaken it.

## Starting evidence

Existing source discovery and path contracts; pinned Flay/PathExpander behavior; spec 04 source-set requirement.

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

Matched Flay 2.14.4 / PathExpander 2.0.1 source identity for explicit files and directories. The contract proves unique directory/file overlap, repeated relative spellings, distinct absolute-versus-relative identities, `.` and `../` path preservation, visible directory selection, and mixed valid/missing input coverage with findings retained. It also records hidden-directory exclusion, explicit directory-symlink rejection, and empty/literal-glob fail-closed exceptions. ADR 0195 and spec 04 exclude these unmatched argument forms from parity because Flay's fallback may scan the current directory.

RED/GREEN: overlap first produced duplicate coverage and an incomplete Flay result. The normalized-path implementation then passed pinned score/source comparisons. Reviewer probes added `.` and parent-relative cases; the final contract checks report identities, not only aggregate scores. The contract now sets and restores the repo `BUNDLE_GEMFILE` while Flay runs from its temporary tree.

```text
env -u BUNDLE_GEMFILE PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild FLEEK_TEMP_ROOT=/tmp/fleek-test-root /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/flay_paths_contract.rb
PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle BUNDLE_GEMFILE="$PWD/Gemfile" SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild FLEEK_MUTATIONS='Flay path deduplication,Flay lexical path normalization,Flay empty path safety' JOBS=3 /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E bin/check_runner.rb mutation
env -u BUNDLE_GEMFILE PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild JOBS=4 FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true make check
PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle BUNDLE_GEMFILE="$PWD/Gemfile" make ticket-check
PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle BUNDLE_GEMFILE="$PWD/Gemfile" bundle exec reek bin/fleek.rb test/flay_paths_contract.rb
PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle BUNDLE_GEMFILE="$PWD/Gemfile" bundle exec flay bin/fleek.rb test/flay_paths_contract.rb
git diff --check
```

Focused contract passed with `BUNDLE_GEMFILE` unset at launch; all three focused mutations were caught. Cache-disabled `make check` passed all 71 workers with four mutation workers. Reek reported zero warnings; Flay reported zero clones from the changed Ruby files. `ticket-check` validated 128 documents and `git diff --check` passed. Spec and standards reviews passed. No residual child is needed: spec 04 and ADR 0195 explicitly accept empty and unmatched literal-wildcard argv as terminal fail-closed safety exceptions.
