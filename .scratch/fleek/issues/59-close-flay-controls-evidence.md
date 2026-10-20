# 59: Close Flay control inventory with evidence

**What to build:** Every built-in Flay analysis control and source-selection rule has a pinned comparison or an explicit unresolved gap.

**Part of:** Ticket 23.

**Blocked by:** 53; 54; 55; 56; 57; 58; 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Produce a row per pinned option/path control: semantic role, supported syntax, differential contract, status normalization and remaining issue. Close ticket 23 only when every analysis gap and its descendant is resolved. Do not treat rejection of fuzzy/legacy as parity or presentation-only scope as a reason to drop timeout effects.

## Starting evidence

Existing ticket 23 acceptance checklist and pinned Flay 2.14.4 option inventory.

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

Inventory source: `PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle bundle exec flay --help` using the locked Flay 2.14.4 bundle. The inventory separates analysis/source controls from output modes and timeout; output differences retain Fleek's documented status normalization and report v1.

| Control | Semantic role and accepted syntax | Pinned differential evidence / Fleek result | Normalized outcome and residual |
| --- | --- | --- | --- |
| `-h`, `--help` | Help only; exits without source analysis | Pinned help lists both aliases; Fleek's explicit help contract is covered in the CLI workflow contracts. | Not an analysis result; no finding status applies. |
| `--mass MASS` | Analysis threshold; decimal integer, default 16 | Tickets 10, 54, and 58 compare threshold boundaries, validation, and repeated valid values against Flay; last valid occurrence wins. | Findings produce Fleek status 2; clean 0; invalid values fail before findings with status 1. Complete for the bounded supported candidates. |
| `--only NODE` | Analysis/report filter; repeated node values are accepted | ADR 0107 and tickets 54/58 compare node selection, full-total score retention, repeated last-value precedence, parser and combined routing. | Filtered findings status 2; clean 0; invalid or check-inapplicable use status 1 before analysis. Complete for supported node kinds. |
| `--liberal` | Analysis pruning mode | Existing contracts compare liberal pruning with Flay; ticket 58 adds bare `--fuzzy` + `--liberal` and combined Flay/Reek source-routing cases. | Findings status 2; incomplete supported-source coverage overrides findings with status 1. Complete for the bounded candidate model. |
| `--fuzzy [DIFF]` | Analysis grouping; optional unsigned integer, default distance 1 | Tickets 53, 54, and 58 compare default/explicit distances, malformed values, bounds, repeat behavior, and fuzzy+liberal routing against Flay. | Findings status 2; unsupported syntax/incomplete coverage status 1. Complete for bounded method candidates and supported distances; other candidate kinds remain outside this bounded parity claim. |
| `--legacy` | Parser selection | Ticket 55 compares shared syntax and records line-leading boolean-operator parser mismatches as incomplete; ticket 58 verifies legacy plus `--only` in explicit and combined selection. | Complete cases retain 0/2; parser mismatch status 1. Bounded shared-syntax parity only. |
| `.flayignore` and file/directory arguments | Source selection and path expansion | Tickets 56–57 compare ignore patterns, recursive `*.rb` selection, overlapping/duplicate inputs, ordering, and requested-path errors against Flay. Fleek explicitly targets `.rb`; Flay's `.erb` extension is out of scope under spec 03. | Failed requested inputs remain visible and make coverage incomplete (status 1); valid complete sources retain 0/2. Complete for the recorded bounded path rules; `.erb` remains excluded by the product scope. |
| `--summary` | Presentation: per-file score output | Ticket 58 probes unchanged Flay score; Fleek keeps report v1. | No analysis-status change. Unsupported Flay-specific presentation mode; ticket 121. |
| `--diff` | Presentation: N-way Ruby diff | Ticket 58 probes unchanged score; diff rendering was unavailable because `ruby2ruby` is absent. | No analysis-status change established; Fleek keeps report v1. Unsupported; ticket 121. |
| `-#` | Presentation: suppress numbering | Ticket 58 probes unchanged score; Fleek keeps report v1. | No analysis-status change. Unsupported Flay-specific presentation mode; ticket 121. |
| `--verbose` | Presentation: file progress | Ticket 58 probes unchanged score; Fleek keeps report v1. | No analysis-status change. Unsupported Flay-specific presentation mode; ticket 121. |
| `--timeout TIME` | Analysis/runtime budget; default 10 | Ticket 58 probes zero, positive, and negative values; negative warns, skips the source, and returns score zero in Flay. Full timeout semantics and native interruption/coverage behavior are not implemented. | Unresolved analysis gap; ticket 120. Parent cannot close. |

Fleek intentionally uses long option names where Flay's short aliases collide with Reek (`-f`, `-s`, `-t`, and `-v`); see `docs/research/combined-cli-conflicts.md`. The controls above are not evidence that all Flay syntax/candidate kinds are supported. Ticket 23 remains open until tickets 120 and 121 and its other parity criteria are complete.

Documentation-only gate: `PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild make ticket-check` passed (130 valid ticket documents); `git diff --check` passed. The pinned `bundle exec flay --help` command above confirmed the option names, defaults, aliases, and known extensions. No implementation or parity claim was added beyond linked contracts and pinned probes. Residual gaps: [ticket 120](120-flay-timeout-control.md) and [ticket 121](121-flay-presentation-controls.md). Parent [ticket 23](23-flay-analysis-control-parity.md) remains open.
