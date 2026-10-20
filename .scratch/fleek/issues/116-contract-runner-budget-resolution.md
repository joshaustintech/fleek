# 116: Contract runner mutation-budget resolution

**What to build:** A deterministic process-boundary regression proves CheckRunner forwards its resolved CPU-bounded JOBS budget to mutation contract precompile.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Exercise the real CheckRunner boundary for unset JOBS, explicit JOBS, and an over-CPU request; assert the precompiler receives the resolved positive budget.
- [x] Keep deterministic fake compiler fan-out, selected-contract cap, distinct temporary roots, and `-O 1` assertions; avoid relying on timing.
- [x] Prove the regression fails if runner resolution/forwarding is broken, then passes with the implementation; run the full check gates and record exclusions.
- [x] Record the test seam and evidence in an ADR. Ticket 115 remains blocked until this ticket resolves.

## Execution boundary

Preserve the existing runner budget semantics. Use the pinned Spinel compiler and deterministic process probes; no wall-clock assertions. Do not change analyzer concurrency, mapped contract selection, or user-facing CLI behavior.

## Answer

Extended `test/check_runner_precompile_budget_contract.rb` to launch the real CheckRunner mutation mode with a fake Spinel child that records the precompiler's inherited `JOBS`. The process-boundary cases cover unset `JOBS` (resolved to 8 CPUs), explicit 1, explicit 3, and over-request 100 (resolved to 8). Existing deterministic precompiler scenarios still check bounded fan-out, selected-contract count, per-compiler temp roots, dependencies, and `-O 1`.

Fault injection removed the runner's `JOBS=#{@jobs}` child assignment; the contract rejected the default case with `default runner forwarded JOBS=unset, expected 8`. Restoring the assignment made the focused contract pass. Pinned full `make check JOBS=4` passed 61 workers and caught all 273 labels; 49 shared contract binaries restored and zero compiled. `make flay reek` returned Flay score 0 and Reek 0 warnings. `make ticket-check` validated 126 documents; `git diff --check` passed. No exclusions. Pinned Spinel 2026.09.12; Flay 2.14.4; Reek 6.6.0.

See [ADR 0181](../../../docs/adr/0181-contract-runner-budget-resolution.md). Ticket 117 is the remaining harness blocker for ticket 115.
