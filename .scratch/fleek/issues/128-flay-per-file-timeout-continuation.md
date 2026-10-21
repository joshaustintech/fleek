# 128: Preserve per-file results after Flay timeout

**What to build:** A timeout in one Flay source does not discard complete results from other selected sources.

**Part of:** Ticket 23 — Flay analysis-control parity.

**Blocked by:** 120; 115.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use two independently selected sources: one that exceeds Flay 2.14.4's parser timeout and one with a known duplication finding that completes within budget. Compare Flay and Fleek findings, coverage, streams, and normalized outcomes. The pinned reference reports the slow source skipped while retaining the fast source's result. Fleek must not discard that completed result or report it as failed.

## Acceptance criteria

- [ ] A reproducible slow-source fixture proves pinned Flay's per-file timeout and preserves the fast source's expected finding.
- [ ] Fleek retains completed findings and reports accurate per-source coverage when another source times out.
- [ ] Add a public contract and non-equivalent mutation; run full native, project, analyzer, mutation, tracker, and standards/spec gates.
- [ ] Record the chosen native/process boundary and exact commands in an ADR and `## Answer`.
