# 57: Match Flay path expansion and duplicate inputs

**What to build:** Explicit files, directories and glob inputs yield the same selected Flay sources and deterministic findings as pinned Flay.

**Part of:** Ticket 23.

**Blocked by:** 56; 115 — Verify harness savings before resuming feature work.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use a tiny tree with overlapping arguments, duplicate paths, missing input, hidden directory and directory symlink. Pass literal glob arguments through subprocess argv so the shell cannot expand them first. Document any existing intentional Fleek safety policy separately from a parity gap; do not silently weaken it.

## Starting evidence

Existing source discovery and path contracts; pinned Flay/PathExpander behavior; spec 04 source-set requirement.

## Acceptance criteria

- [ ] Listed behavior cases have reproducible inputs, pinned expected results and matching public behavior. Inventory-only work records evidence and concrete child links; completion gates remain open until every required residual gap resolves.
- [ ] Semantic findings, coverage, streams and normalized outcome are asserted where applicable; evidence-only inventories distinguish verified rows from unresolved work.
- [ ] Relevant regression/mutation or evidence checks pass; Answer records exact commands and remaining issue links.
- [ ] Stop after this behavior is proven; parent acceptance is not reduced by this child.

## Execution and stop condition

Claim this child before implementation; parent claims remain unchanged. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Start with the listed public CLI cases and existing helpers. Record expected versus actual behavior before editing. Implement only this behavior through the existing native path; no new framework, reference-tool fallback or unrelated syntax expansion.

Keep one focused regression and relevant non-equivalent mutations for changed behavior. Use `FLEEK_MUTATIONS` with exact registered labels for focused runs; full mutation coverage remains mandatory before a code commit. Run repository-required build/tests, Flay, Reek, mutation and standards/spec review gates before landing code. Docs/evidence-only work gets tracker/link/diff checks; do not invent implementation proof. Record commands, tool identities, RED/GREEN evidence where code changed, gate results and limitations in `## Answer`.

If cases already pass, add only missing meaningful evidence and finish; do not refactor for activity. If a second independent defect appears, publish a separate minimal child with expected pinned behavior and blockers. This child may finish its stated behavior while those gaps remain open, but the parent completion gate must wait for every residual child. Never turn incomplete coverage into clean output, skip a selected source or weaken a reference expectation to pass.
