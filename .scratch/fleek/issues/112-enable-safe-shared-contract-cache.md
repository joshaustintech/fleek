# 112: Enable safe reuse for all mapped mutation contracts

**What to build:** Ordinary check and mutation invocations reuse validated unchanged contracts across runs, with an explicit cold mode for independent verification.

**Blocked by:** 111.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [ ] Extend the proven cache path to all currently mapped contracts and their prepared dependency bundle. Reuse compilation only: rebuild and run every selected mutant, preserve all expected-failure checks and retain full mutation coverage.
- [ ] Provide one documented cache-disable setting for a true cold run. Keep standalone ordinary test contracts uncached in this slice. Cache storage survives runner cleanup but is excluded from disposable worker copies.
- [ ] Prove simultaneous independent invocations can share immutable cache entries while retaining distinct source/build/compiler-temp/contract-output roots. Cleanup or interruption of one invocation cannot break the other.
- [ ] Compare cold and warm complete mutation runs: same selected-label inventory, caught outcomes, statuses and reference expectations. Report compiles avoided and precompile time; do not count reused verdicts as execution.
- [ ] Record cache identity, invalidation, recovery and explicit cleanup policy in the existing harness ADR/docs. Stop after default mutation-cache integration; leave production compilation untouched.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
