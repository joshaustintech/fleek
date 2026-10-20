# 50: Compose exception flow with interpolated values

**What to build:** A method containing begin/rescue/ensure and an interpolated regexp/string preserves Flay identity and parent-dependent mass.

**Part of:** Ticket 43 / 22.

**Blocked by:** 42; 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use one exception/regexp pair and one exception/string pair. Compare identical and changed interpolation values, plus one still-unsupported default beside a supported finding. Do not add new syntax.

## Starting evidence

Existing exception-flow, string and regexp contracts; ADRs 0138, 0139, 0168, 0170.

## Acceptance criteria

- [x] Listed behavior cases have reproducible inputs, pinned expected results and matching public behavior. Inventory-only work records evidence and concrete child links; completion gates remain open until every required residual gap resolves.
- [x] Semantic findings, coverage, streams and normalized outcome are asserted where applicable; evidence-only inventories distinguish verified rows from unresolved work.
- [x] Relevant regression/mutation or evidence checks pass; Answer records exact commands and remaining issue links.
- [x] Stop after this behavior is proven; parent acceptance is not reduced by this child.

## Answer

Added native method-mass correction for begin/rescue/ensure compositions, including bound rescue references. The public contract covers identical and changed interpolated regexp pairs (Flay mass 36), identical and changed interpolated-string pairs (mass 32), a plain rescue/ensure pair (mass 28), and an unsupported default beside a supported pair. Before the correction, the regexp and string cases were six mass points below Flay. The unsupported case retains the similar mass-36 finding, reports `scope=partial` and incomplete coverage, exits 1, and places the partial-results diagnostic on stderr only. See [ADR 0188](../../../docs/adr/0188-match-composed-exception-wrapper-mass.md).

Verified with pinned Spinel 2026.09.12, Flay 2.14.4, and Reek 6.6.0. Focused CLI contract: `/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/duplication_composed_exception_contract.rb`. Focused mutations: `FLEEK_MUTATIONS='Flay composed exception wrapper mass,Flay composed exception binding mass' make mutation`; both mutations were caught. Full cold gate: `FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true JOBS=4 make check` passed with 65 workers and four mutation workers. `make flay` reported score 0; `make reek` reported 0 warnings; `make ticket-check` reported 127 valid tickets. `git diff --check` passed. Spec and standards reviews found no remaining issues.

Tickets 42 and 115 are resolved. Tickets 51–52 and parent Tickets 22/43 remain open; this child does not reduce their acceptance scope.

## Execution and stop condition

Claim this child before implementation; parent claims remain unchanged. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Start with the listed public CLI cases and existing helpers. Record expected versus actual behavior before editing. Implement only this behavior through the existing native path; no new framework, reference-tool fallback or unrelated syntax expansion.

Keep one focused regression and relevant non-equivalent mutations for changed behavior. Use `FLEEK_MUTATIONS` with exact registered labels for focused runs; full mutation coverage remains mandatory before a code commit. Run repository-required build/tests, Flay, Reek, mutation and standards/spec review gates before landing code. Docs/evidence-only work gets tracker/link/diff checks; do not invent implementation proof. Record commands, tool identities, RED/GREEN evidence where code changed, gate results and limitations in `## Answer`.

If cases already pass, add only missing meaningful evidence and finish; do not refactor for activity. If a second independent defect appears, publish a separate minimal child with expected pinned behavior and blockers. This child may finish its stated behavior while those gaps remain open, but the parent completion gate must wait for every residual child. Never turn incomplete coverage into clean output, skip a selected source or weaken a reference expectation to pass.
