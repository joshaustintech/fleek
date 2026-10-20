# 114: Narrow the next costly independent mutation contract

**What to build:** The next ranked independent slow mutation label avoids unrelated public comparisons while preserving the same behavioral fault detection.

**Blocked by:** 113.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [ ] Remeasure the second eligible ranked label from ticket 106 after ticket 113. Limit this slice to one independent behavior; do not reopen already optimized mappings or expand analyzed syntax.
- [ ] Keep the broad regression contract enabled. Reuse the smallest appropriate existing focused contract before introducing a new one; preserve all assertions relevant to this label and its specific expected failure.
- [ ] Prove baseline passes, exact mutant fails at the intended assertion and filtered selection runs only the requested mapping. Record comparable cold/warm phase timings and repeated execution avoided.
- [ ] If no independently useful narrowing remains, record measured evidence and retain the mapping. Stop after this label; additional measured defects become separate tickets that block ticket 115.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
