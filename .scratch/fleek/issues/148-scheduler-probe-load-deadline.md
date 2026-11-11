# 148: Keep the scheduler probe deadline independent of gate load

**What to fix:** `test/check_runner_scheduler_contract.rb` gave the probe runner 10 seconds to start its third task. That window covered compiling `bin/check_runner.rb` and three probe children with `spinel -E`, which happens while `make -B check` starts ten workers that all compile at once. On 2026-11-11 the full gate failed three times in a row with "third task started after slow task release", at load averages around 20, while the contract passed on its own.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [x] The contract still fails if the scheduler waits for the blocked slow task before starting the third task.
- [x] The full gate no longer depends on compiling the probe within 10 seconds.

## Answer

The slow probe task blocks until the contract writes `release-slow`, so the third task can never start in a scheduler that waits for it. A longer deadline only delays reporting a genuine failure. The deadline is now 120 seconds, which covers compile time at full gate load while keeping the ordering assertion intact.
