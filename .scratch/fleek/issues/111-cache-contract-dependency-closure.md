# 111: Reuse a contract with shared source dependencies

**What to build:** Focused call-descriptor mutations reuse a compiled contract safely when it includes shared pair-comparison and analysis helpers.

**Blocked by:** 110.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [ ] Extend the opt-in cache from the leaf contract to the existing call-descriptor public contract and its prepared source dependencies only; retain conservative complete prepared-bundle invalidation.
- [ ] Changing the selected contract, its pair helper, the common analysis helper or temporary-path rewrite format forces a rebuild. A missing dependency fails clearly and never falls back to an older cached executable.
- [ ] A cached contract executes against a second isolated worker and freshly rebuilt mutant, with no embedded first-run source, working-directory or output path leakage; original expected mutation failure remains checked.
- [ ] Demonstrate miss/hit/invalidation using focused invocations and compile counts. Stop after this dependent contract; keep remaining contracts on the existing path.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
