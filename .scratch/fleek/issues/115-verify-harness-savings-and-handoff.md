# 115: Verify harness savings before resuming feature work

**What to build:** Luna resumes existing feature tickets only after harness changes have reproducible savings and unchanged required correctness evidence.

**Blocked by:** 114; 116; 117.

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [ ] Repeat ticket 106's same-input, same-budget probes after all harness slices. Report cold and warm phase timings, medians for bounded repetitions, total full-gate elapsed time and absolute/relative savings; do not promise an unmeasured speedup.
- [ ] Run the pinned native build/tests, full unfiltered mutation suite, Flay and Reek, plus tracker/link/diff validation and required standards/spec review. Require zero findings and no surviving non-equivalent mutants; record justified exclusions. Existing baseline failures require explicit residual bug tickets and block this handoff, not silent acceptance.
- [ ] Verify scheduler failure propagation, capped concurrency, dirty/untracked input preservation, cache invalidation/corruption/overlap and worker isolation through the earlier runnable regression contracts. Compare task and mutation inventories with baseline.
- [ ] Record exact commands, tool identities, limitations, ADR links and verdicts in Answer/map. Resolve only when tickets 106–114 and any newly discovered harness blockers are resolved; then point Luna back to the existing feature frontier.
- [ ] Keep all existing feature IDs, parent claims, acceptance criteria and dependency edges. README completion remains last, including future residual tickets.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
