# 108: Use the resolved worker budget for contract precompile

**What to build:** Plain check and mutation invocations precompile contracts with the same resolved CPU-bounded budget as their outer runner.

**Blocked by:** 107.

**Status:** open
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [ ] Pass the runner's resolved positive JOBS budget to shared-contract precompile when JOBS is unset or explicitly supplied; cap actual compilers by selected contract count. Keep existing invalid-JOBS rejection.
- [ ] A deterministic process-boundary contract covers unset JOBS, JOBS=1, an explicit budget and a request above available CPUs; observe child configuration and bounded concurrent compiler launches.
- [ ] Focused mutation selection still compiles only selected contracts and their dependencies, with distinct compiler temp roots. Do not increase generated analyzer inner concurrency or change native optimization settings.
- [ ] Compare default and explicit-budget precompile timings for the identical contract set; stop after budget propagation is proven.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
