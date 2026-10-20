# 117: Remove global mutation from cache temporary paths

**What to fix:** Cache temporary-path allocation must remain unique without mutating a class-level constant.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Replace the mutable `TEMPORARY_SERIAL` class constant with narrowly owned temporary-path state while preserving uniqueness for overlapping cache operations and separate cache instances in one process.
- [x] Add a focused regression for distinct temporary paths and retain publisher/restore cleanup behavior.
- [x] Run cache contract, full check, Flay, Reek, and tracker/diff gates; report any exclusions.
- [x] Record the state-ownership choice in an ADR. Ticket 115 remains blocked until this ticket resolves.

## Execution boundary

Keep cache identity, format, invalidation, and public behavior unchanged. Follow Spinel 2026.09.12 and repo Ruby maintainability guidance; avoid global mutable state or broader cache redesign.

## Answer

Removed the mutable class-level `TEMPORARY_SERIAL` array. Each cache instance now owns its serial; generated temporary names include process ID, object identity, and that serial so concurrent publishers and separate cache instances in one process retain distinct paths.

`test/mutation_contract_cache_contract.rb` checks distinct paths across repeated allocation and two cache instances. Fault injection made every path use a constant suffix; the regression failed with `cache temp paths overlapped across instances`. The revised cache contract passed, including the existing concurrent publisher, corruption, invalidation, and restore checks. Full `make check JOBS=4` passed 61 workers and caught all 273 labels, with 49 cached contracts restored and zero compiled. `make flay reek` reported score 0 and warnings 0; `make ticket-check` validated 126 documents; `git diff --check` passed. No exclusions. Pinned Spinel 2026.09.12; Flay 2.14.4; Reek 6.6.0.

See [ADR 0182](../../../docs/adr/0182-instance-owned-cache-temporary-paths.md). Ticket 115 is now clear to complete its final handoff checks.
