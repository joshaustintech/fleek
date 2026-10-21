# 128: Preserve per-file results after Flay timeout

**What to build:** A timeout in one Flay source does not discard complete results from other selected sources.

**Part of:** Ticket 23 — Flay analysis-control parity.

**Blocked by:** 120 (resolved); 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use two independently selected sources: one that exceeds Flay 2.14.4's parser timeout and one with a known duplication finding that completes within budget. Compare Flay and Fleek findings, coverage, streams, and normalized outcomes. The pinned reference reports the slow source skipped while retaining the fast source's result. Fleek must not discard that completed result or report it as failed.

## Acceptance criteria

- [x] A reproducible slow-source fixture proves pinned Flay's per-file timeout and preserves the fast source's expected finding.
- [x] Fleek retains completed findings and reports accurate per-source coverage when another source times out.
- [x] Add a public contract and non-equivalent mutation; run full native, project, analyzer, mutation, tracker, and standards/spec gates.
- [x] Record the chosen native/process boundary and exact commands in an ADR and `## Answer`.

## Answer

For explicit positive timeouts over multiple sources, Fleek probes each selected source in an isolated worker, marks expired sources failed, then analyzes completed sources together so cross-file findings remain available. Combined checks continue Reek against its original inputs. Single-source timeouts and untimed runs retain existing behavior. See [ADR 0236](../../../docs/adr/0236-continue-flay-analysis-after-per-file-timeout.md).

Verified with pinned Spinel `2026.09.12` (`112bae85c1a2`):

- `gmake -C "$SPINEL_ROOT" check` with GNU Make 4.4.1 first in `PATH`: 3,596 tests passed; allocation, inference, and `spin-e2e` passed.
- `make check JOBS=8`: 77 workers passed; all mutations caught; Flay score 1008; Reek 0 warnings.
- `make ticket-check`: passed.
- `git diff --check`: passed.
