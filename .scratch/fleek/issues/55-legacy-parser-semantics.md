# 55: Match Flay legacy parser mode on shared syntax

**What to build:** --legacy selects analysis semantics matching pinned Flay's RubyParser mode without executing analyzed source.

**Part of:** Ticket 23.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Choose one identical-input case where pinned default and legacy trees differ and one case where they agree. Compare semantic reports and Reek-only rejection. Keep native analysis; do not shell out to RubyParser as Fleek's implementation. If multiple representation gaps appear, publish one child per gap and keep the legacy completion gate open.

## Starting evidence

Pinned Flay parser option; existing Prism-to-Flay descriptor adapters and parser grammar boundary.

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

Added native `--legacy` behavior and pinned `ruby_parser` 3.22.0 for Flay's reference mode; Fleek itself never loads or invokes RubyParser. Shared syntax matches Flay 2.14.4 in findings, mass, score, locations, coverage, status and streams. Public contracts cover the line-leading `&&`, `||`, `and`, and `or` syntax accepted by default Prism but rejected by Flay legacy: Flay legacy skips each with a parse warning and zero score, while Fleek legacy reports the affected source as incomplete with zero findings. Reek-only `--legacy` requests fail before analysis. ADR 0193 records the boundary and the remaining limit: this proves the tested forms, not complete RubyParser parser parity.

RED was reproduced for line-leading `||` before the native guard was extended; the contract then passed for all four forms:

```text
PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/legacy_parser_contract.rb
PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild FLEEK_MUTATIONS='Flay mass check applicability,Flay only check applicability,Flay liberal combined routing,Flay legacy parser boundary,Flay legacy check applicability' JOBS=2 /private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E bin/check_runner.rb mutation
PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true JOBS=4 make check
make ticket-check
git diff --check
```

The focused mutations caught all five selected cases. The cache-disabled full build, contract, analyzer and mutation gate passed: 69 workers with `JOBS=4`, including four mutation workers. Reek reported zero warnings; Flay passed its repository gate with no new findings from this contract. Spec and standards reviews passed. Ticket 58 now has this prerequisite resolved; Ticket 59 retains its remaining inventory gate.
