# 113: Narrow the highest-cost remaining mutation contract

**What to build:** The first ranked slow mutation label uses the smallest public CLI comparison that detects its intended behavioral fault.

**Blocked by:** 112.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [ ] Use the first eligible ranked label from ticket 106, remeasured after caching. Bound this ticket to one label and its behavior, not an entire descriptor family.
- [ ] Retain the broad public contract in the normal full test suite. Move or reuse only the narrow assertion needed for this mutation and preserve findings, mass/score, locations/order, coverage and normalized outcome relevant to that fault.
- [ ] Show unchanged implementation passes and the exact mutant fails at its intended assertion/message; an unrelated earlier assertion must not supply the kill. Change only this mapping and necessary focused evidence.
- [ ] Record compile/setup versus execution cost, run frequency and before/after focused timings. If measurement shows no avoidable repeated work, record that evidence and leave the mapping unchanged rather than creating a redundant contract.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
