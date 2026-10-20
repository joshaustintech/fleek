# 53: Match Flay fuzzy detection at default distance

**What to build:** Explicit --fuzzy without a value matches unchanged Flay's default distance-one findings on supported method candidates.

**Part of:** Ticket 23.

**Blocked by:** None (can start immediately).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use one pair with one copied statement difference, one exact duplicate and one unrelated pair. Compare group kind, fuzzy locations, mass and score. Keep non-fuzzy invocation unchanged. Validate via Flay itself before fixing expected output.

## Starting evidence

Pinned Flay option parser and fuzzy grouping implementation; current CLI rejects --fuzzy.

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

Implemented `--fuzzy` at Flay's default distance one for supported top-level and class method candidates. Native matching removes one direct body statement and applies Flay 2.14.4's candidate-size and integer average-mass limits. Reports identify the fuzzy occurrence. Invocation without `--fuzzy` remains unchanged; Reek-only use is rejected before analysis. ADR 0191 records this boundary and supersedes the earlier fuzzy exclusions in ADRs 0016 and 0017.

The pinned public CLI contract compares top-level and class fuzzy groups, exact and unrelated controls, non-fuzzy invocation, and the Flay size-cap boundary. The below-cap reference reports mass/score 40; the separate mass-eligible above-cap pair reports zero in both Flay and Fleek. It asserts finding kind, locations, fuzzy locations, mass, score, coverage, status, streams, and exit outcome.

Focused GREEN: `/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/duplication_fuzzy_contract.rb` passed with the pinned Spinel and bundle environment. Focused mutations `Flay fuzzy option recognition`, `Flay fuzzy candidate collection`, `Flay fuzzy location attribution`, and `Flay fuzzy candidate bounds` were all caught. The existing `Flay liberal combined routing` mutation target was updated for fuzzy-option stripping and its focused mutation passed.

Full gate: `PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true JOBS=4 make check` passed with Spinel 2026.09.12, Flay 2.14.4, and Reek 6.6.0; check runner reported 67 workers passed, including four mutation workers. The reference Flay scan scored 0 and the Reek scan reported 0 warnings. Spec and standards reviews pass. Explicit `--fuzzy N` and non-method Flay candidates remain outside this bounded child and are tracked by Tickets 54 and 59.
