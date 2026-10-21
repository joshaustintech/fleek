# 93: Validate Reek configuration before analysis

**What to build:** Malformed configuration cannot silently disable selected analysis or produce a clean report.

**Part of:** Ticket 24.

**Blocked by:** 90 (resolved); 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use one supported detector with malformed YAML, unknown detector/setting, wrong scalar/list type and invalid threshold. Probe pinned Reek's accepted/rejected behavior, preserve deliberate Fleek diagnostic normalization and add a regression for each actual change. Unsupported valid upstream YAML features become individually scoped follow-ups.

## Starting evidence

Current bounded Reek YAML reader and malformed-configuration public contracts.

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

Pinned Spinel 2026.09.12 (source commit `112bae85c1a25fc5399009a849f805bfe691426b`; tag object `00ce35bb96e489620358ffbc48791001a73778a`), Flay 2.14.4, and Reek 6.6.0. Before editing, `spinel -E test/configuration_contract.rb` passed; inspection showed the bounded invalid cases were already rejected by Fleek. Added public CLI contracts and fixtures for malformed YAML, unknown detector, unknown setting, wrong scalar type, wrong list type, and non-integer threshold. For every case, both Fleek and the pinned Reek CLI exit unsuccessfully with no findings output; Fleek's existing normalized diagnostic is asserted. No production behavior change was needed.

With the pinned compiler and bundle exported as in `docs/agents/spinel.md`, `$SPINEL -E test/configuration_contract.rb` passed. `JOBS=4 make check` passed all 72 workers, including four mutation shards and the full mutation set. `make -C /private/tmp/fleek-spinel-pinned-rebuild check` passed 3,596 native tests and `spin-e2e: ALL GREEN`. `bundle exec flay bin` reported score 0; `bundle exec reek bin test/*.rb` reported 0 warnings; `make ticket-check` validated 135 documents; `git diff --check` passed. No remaining gap was found within these bounded invalid cases. This does not claim support for all valid Reek YAML syntax; no additional valid-syntax gap was investigated. ADR 0230 records the validation boundary and choice to keep config checking native.
