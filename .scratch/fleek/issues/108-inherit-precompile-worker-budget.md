# 108: Use the resolved worker budget for contract precompile

**What to build:** Plain check and mutation invocations precompile contracts with the same resolved CPU-bounded budget as their outer runner.

**Blocked by:** 107.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Pass the runner's resolved positive JOBS budget to shared-contract precompile when JOBS is unset or explicitly supplied; cap actual compilers by selected contract count. Keep existing invalid-JOBS rejection.
- [x] A deterministic process-boundary contract covers the resolved default, JOBS=1, an explicit budget, and the CPU-bounded over-request result; observes child configuration and bounded concurrent compiler launches. Actual runner probes also exercise JOBS unset and JOBS=100.
- [x] Focused mutation selection still compiles only selected contracts and their dependencies, with distinct compiler temp roots. Analyzer concurrency and native optimization settings are unchanged.
- [x] Compare default and explicit-budget precompile timings for the identical contract set; stop after budget propagation is proven.

## Answer

Pinned Spinel `112bae85c1a25fc5399009a849f805bfe691426b` (tag object `00ce35bb96e489620358ffbc48791001a73778a5`, 2026.09.12), Flay 2.14.4, Reek 6.6.0. The RED focused `make mutation` run with `JOBS` unset omitted forwarding and reported child `JOBS=1`; four contracts compiled in 6.48s. GREEN forwards the resolved runner budget: unset resolved to runner `JOBS=8` and the same precompile set took 4.46s; the selected four contracts cap its compiler batch at four. Explicit `JOBS=3` reached the child and took 5.50s; explicit 1 and over-CPU request 100 resolved to runner budgets 1 and 8, with the four-contract cap retained. All four focused mutation labels were caught in each runner probe.

`test/check_runner_precompile_budget_contract.rb` passes at the process boundary for resolved budgets 8, 1, 3, and 8. Its gated fake compiler verifies fan-out, ten selected contracts and their dependency, distinct `TMPDIR` values, and Spinel `-O 1`. Full `make check JOBS=4` passed 58 workers in 398.63s, including four mutation shards; `make flay reek` reported Flay score 0 and Reek 0 warnings; `make ticket-check` validated 124 documents; `git diff --check` passed. The temporary incomplete Spinel build was replaced with the exact pinned tag clone before gate runs. ADR 0174 records the decision. Timing probes are diagnostic, not assertions.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
