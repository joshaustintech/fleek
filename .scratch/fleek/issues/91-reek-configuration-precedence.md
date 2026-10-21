# 91: Verify Reek discovery and directory precedence

**What to build:** Discovered and explicit Reek configuration resolve the same effective detector settings on the same paths as pinned Reek.

**Part of:** Ticket 24.

**Blocked by:** 90 (resolved); 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use one detector and a parent/child directory with conflicting enabled/threshold values. Compare explicit config versus discovered config, most-specific path override and no-config fallback. Reuse current precedence checks; add only missing cases and publish separate gaps for other configuration syntax.

## Starting evidence

Existing default-configuration and configuration contracts; effective per-path detector settings.

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

Pinned tools: Spinel 2026.09.12, Flay 2.14.4, Reek 6.6.0. The reproducible inputs are `test/fixtures/reek_settings_scope/.reek.yml`, `parent.rb`, and `child/input.rb`. The config sets `LongParameterList.max_params: 3` for the parent and `4` for the more-specific child.

- Explicit configuration: Reek and Fleek both report `Parcel#update has 4 parameters` at line 2 in `parent.rb` (exit 2); both report no finding for `child/input.rb` (exit 0).
- Discovered configuration: running from the fixture root without a config argument produces the same parent and child results for both tools.
- No-config fallback: running from the repository root against the absolute child fixture path lets Reek and Fleek use the default limit of three; both report the four-parameter method at line 2 (exit 2).
- Fleek reports the expected source coverage (`1 analyzed; 0 failed; 0 excluded`) and normalized `findings` or `complete` status in all cases. Reek warning lines, method context, parameter count and process outcomes match.

Commands used the public CLIs: `bundle exec reek --smell LongParameterList [--config .reek.yml] <path>` and `build/fleek --checks reek:LongParameterList [--reek-config .reek.yml] <path>` from the fixture root; the same commands without config arguments and with the absolute child path from the repository root verified fallback. `make ticket-check` passed 135 documents with pinned Spinel identity validation; `git diff --check` passed. These cases already passed, so this ticket adds only fixtures and evidence, with no analyzer or mutation claim. Remaining independent configuration work: issues 92, 93, and 126. Parent issue 24 remains open. Decision: [ADR 0228](../../../docs/adr/0228-verify-reek-directory-precedence.md).
