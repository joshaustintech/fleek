# 54: Match explicit fuzzy distance and validation

**What to build:** Explicit --fuzzy DIFF changes analysis exactly as pinned Flay and fails malformed requests before analysis.

**Part of:** Ticket 23.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Compare distance 1 versus 2 on one distinguishing pair; probe zero/negative, noninteger, missing optional value, repeated options and Reek-only selection. Derive valid ranges and repetition from pinned Flay; retain documented Fleek diagnostics/status normalization.

## Starting evidence

Pinned Flay option parser and distance logic; shared CLI option validation and check routing.

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

Implemented Flay 2.14.4 explicit fuzzy distances for bounded method candidates. Bare `--fuzzy` defaults to one when followed by no token or another option; use source paths before a bare flag. Attached and separate integer values work, repeated values use the last occurrence, and zero/negative values disable fuzzy findings. Malformed values fail before analysis. Reek-only selection rejects the option; combined analysis removes both option and value from Reek inputs. ADR 0192 records parser ordering and the distance cap within ADR 0191's candidate size bound.

The compiled public CLI contract compares distance one and two against Flay on a pair with two extra statements. It also covers attached/separate values, repeated-option precedence, zero, negative values in top-level and class methods, omitted distance, malformed attached and bare values, Reek-only rejection, findings, score/mass, status, and streams. RED was confirmed before implementation (`Fleek distance one outcome changed`); focused GREEN passed:

```text
/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/duplication_fuzzy_distance_contract.rb
/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/duplication_fuzzy_contract.rb
/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel -E test/cli_contract.rb
```

Focused mutation checks caught `Flay fuzzy explicit distance parsing`, `Flay fuzzy multiple statement matching`, and `Flay liberal combined routing`. Full gate passed with Spinel 2026.09.12, Flay 2.14.4, Reek 6.6.0; cache disabled; `68 workers passed with JOBS=4; mutation workers=4`. `make ticket-check` reports 128 valid tickets; `git diff --check` passes. Spec and standards reviews pass. Ticket 58 now has this prerequisite resolved; Ticket 59 retains its full inventory gate.
