# 56: Match .flayignore pattern semantics

**What to build:** The same .flayignore selects the same Flay source set in Fleek and pinned Flay while Reek exclusions remain independent.

**Part of:** Ticket 23.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use a tiny real directory tree: literal file, directory suffix, basename glob, nested glob, blank/comment lines and a pattern matching no source. Compare excluded paths and score. Check missing/unreadable ignore files. Probe upstream first; do not assume gitignore rules.

## Starting evidence

Existing ignore loading/partition logic, combined exclusion contract and pinned PathExpander ignore behavior.

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

Matched Flay 2.14.4 / PathExpander 2.0.1 `.flayignore` behavior in the native path. The public contract compares Flay and Fleek scores, included/excluded paths, coverage, status and streams for slash-containing literals, slashless root-only literals, directory suffixes, root and nested basename globs, nested globs, blank and hash-prefixed literal lines, unmatched patterns, a missing file and an existing directory at `.flayignore`. Slashless wildcards cross directory separators; Spinel's matcher does not do that by default, so Fleek translates separators to a sentinel before matching. Existing unreadable paths fail instead of silently disabling exclusions. Reek exclusions remain independent. ADR 0194 records the choice and boundary.

RED/GREEN: the contract first failed for nested slashless globs while Fleek applied pathname boundaries. It also caught the inverse overmatch when basename matching was tried; the final contract proves both glob-spanning and slashless-literal root behavior. The compiled contract passes against pinned Flay.

```text
PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle BUNDLE_GEMFILE="$PWD/Gemfile" make SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild build/fleek
PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle BUNDLE_GEMFILE="$PWD/Gemfile" FLEEK_TEMP_ROOT=/tmp/fleek-test-root /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/flayignore_contract.rb
PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle BUNDLE_GEMFILE="$PWD/Gemfile" SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild FLEEK_MUTATIONS='Flay ignore scope,Flay unreadable ignore file,Flay basename ignore matching' JOBS=2 /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E bin/check_runner.rb mutation
PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle BUNDLE_GEMFILE="$PWD/Gemfile" SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild JOBS=4 FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true make check
make ticket-check
git diff --check
```

The focused contract and all three focused mutations passed. The cache-disabled full check passed with 70 workers and four mutation workers; Flay and Reek repository gates passed, with no new Flay findings from this contract and zero Reek warnings. `ticket-check` validated 128 documents; `git diff --check` passed. Spec and standards reviews passed. No separate child issue was required.
