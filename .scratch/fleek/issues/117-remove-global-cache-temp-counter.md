# 117: Remove global mutation from cache temporary paths

**What to fix:** Cache temporary-path allocation must remain unique without mutating a class-level constant.

**Status:** open
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [ ] Replace the mutable `TEMPORARY_SERIAL` class constant with narrowly owned temporary-path state while preserving uniqueness for overlapping cache operations and separate cache instances in one process.
- [ ] Add a focused regression for distinct temporary paths and retain publisher/restore cleanup behavior.
- [ ] Run cache contract, full check, Flay, Reek, and tracker/diff gates; report any exclusions.
- [ ] Record the state-ownership choice in an ADR. Ticket 115 remains blocked until this ticket resolves.

## Execution boundary

Keep cache identity, format, invalidation, and public behavior unchanged. Follow Spinel 2026.09.12 and repo Ruby maintainability guidance; avoid global mutable state or broader cache redesign.
