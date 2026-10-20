# 49: Compose collections inside branches and loops

**What to build:** An array/hash call nested in if/case and a loop matches Flay without losing wrapper mass or children.

**Part of:** Ticket 43 / 22.

**Blocked by:** 42; 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use two bounded compositions, one case-with-multiple-conditions and one loop-with-array/hash call. Include an identity-only variant and different child topology that must not group.

## Starting evidence

Collection and control-flow descriptors; existing collection/control-flow contracts; ADRs 0166, 0167, 0170.

## Acceptance criteria

- [x] Listed behavior cases have reproducible inputs, pinned expected results and matching public behavior. Inventory-only work records evidence and concrete child links; completion gates remain open until every required residual gap resolves.
- [x] Semantic findings, coverage, streams and normalized outcome are asserted where applicable; evidence-only inventories distinguish verified rows from unresolved work.
- [x] Relevant regression/mutation or evidence checks pass; Answer records exact commands and remaining issue links.
- [x] Stop after this behavior is proven; parent acceptance is not reduced by this child.

## Answer

No analyzer change was needed: all bounded compositions already matched. Added `test/duplication_composed_collection_contract.rb` and fixed fixtures for a multi-condition case/array call (similar `:defn`, mass/score 38), a loop with array and hash calls (similar, 30), an identical conditional collection pair (mass 26, score 52), and a different-child-topology pair (clean at threshold 3). Contracts check pinned Flay 2.14.4 and Fleek classifications, locations, scores, coverage, statuses, and empty stderr.

Verified with pinned Spinel 2026.09.12: focused contract command `/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/duplication_composed_collection_contract.rb`; focused mutations `Flay method CASE candidates`, `Flay method array expression`, `Flay method hash expression`, `Flay method while loop candidates`, and `Flay structural equality` were all caught. `FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true JOBS=4 make check` passed with 64 workers and four mutation workers. `make flay` reported score 0, `make reek` reported 0 warnings, and `make ticket-check` validated 127 tickets. Spec and standards reviews found no blockers.

Ticket 49 proves only these bounded compositions. Tickets 50–52 and parent Tickets 22/43 remain open for their remaining criteria. See [ADR 0187](../../../docs/adr/0187-preserve-composed-collection-control-parity.md).

## Execution and stop condition

Claim this child before implementation; parent claims remain unchanged. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Start with the listed public CLI cases and existing helpers. Record expected versus actual behavior before editing. Implement only this behavior through the existing native path; no new framework, reference-tool fallback or unrelated syntax expansion.

Keep one focused regression and relevant non-equivalent mutations for changed behavior. Use `FLEEK_MUTATIONS` with exact registered labels for focused runs; full mutation coverage remains mandatory before a code commit. Run repository-required build/tests, Flay, Reek, mutation and standards/spec review gates before landing code. Docs/evidence-only work gets tracker/link/diff checks; do not invent implementation proof. Record commands, tool identities, RED/GREEN evidence where code changed, gate results and limitations in `## Answer`.

If cases already pass, add only missing meaningful evidence and finish; do not refactor for activity. If a second independent defect appears, publish a separate minimal child with expected pinned behavior and blockers. This child may finish its stated behavior while those gaps remain open, but the parent completion gate must wait for every residual child. Never turn incomplete coverage into clean output, skip a selected source or weaken a reference expectation to pass.
