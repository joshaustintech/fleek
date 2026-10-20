# 107: Refill check slots when any worker finishes

**What to build:** Independent check tasks start as soon as any worker slot becomes free instead of waiting behind the oldest running task.

**Blocked by:** 106.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Use the existing process runner; reap a completed child and associate its status/output with its actual task. Preserve the configured concurrency cap, complete task inventory and isolated worker roots.
- [x] A deterministic gated-child contract starts a slow first child and a finishing second child, then proves a third starts before the first is released. Avoid sleep-based correctness assertions.
- [x] Cover a failing out-of-order child and teardown: failure remains attributed to that task, every started child is waited for, and cleanup does not remove another active worker's resources.
- [x] Compare the same bounded scheduling probe before/after; stop after slot reuse works. Leave compile batching and mutation shard assignment unchanged.

## Answer

The scheduler now waits for any child with `Process.waitpid2(-1)`, then matches returned PID to its worker before reading output and cleaning its private roots. `test/check_runner_scheduler_contract.rb` deterministically gates the first child, checks that task three starts before release, repeats with task two failing, verifies statuses and completion markers, and confirms live worker files survive until completion plus all worker roots disappear at teardown. Before fix, third did not start until the 10-second guard released the first task. After fix, both cases pass in 8.47s. Concurrency cap, complete task list, mutation shard assignment, and contract precompile batching remain unchanged.

Pinned Spinel 2026.09.12; Flay 2.14.4; Reek 6.6.0. `make test JOBS=4` passed 50 workers in 66.15s; `make mutation JOBS=4` passed four shards and caught all mapped labels across 48 shared contracts in 331.54s; `make flay reek` passed with zero findings; full `make check JOBS=4` passed 57 workers in 389.48s with zero Flay/Reek findings. `make ticket-check` and `git diff --check` pass. The RED contract failed with `third task started after slow task release`; GREEN passes. ADR 0173 records the wait-any decision.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
