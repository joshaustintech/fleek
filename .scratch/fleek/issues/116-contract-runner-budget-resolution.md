# 116: Contract runner mutation-budget resolution

**What to build:** A deterministic process-boundary regression proves CheckRunner forwards its resolved CPU-bounded JOBS budget to mutation contract precompile.

**Status:** open
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [ ] Exercise the real CheckRunner boundary for unset JOBS, explicit JOBS, and an over-CPU request; assert the precompiler receives the resolved positive budget.
- [ ] Keep deterministic fake compiler fan-out, selected-contract cap, distinct temporary roots, and `-O 1` assertions; avoid relying on timing.
- [ ] Prove the regression fails if runner resolution/forwarding is broken, then passes with the implementation; run the full check gates and record exclusions.
- [ ] Record the test seam and evidence in an ADR. Ticket 115 remains blocked until this ticket resolves.

## Execution boundary

Preserve the existing runner budget semantics. Use the pinned Spinel compiler and deterministic process probes; no wall-clock assertions. Do not change analyzer concurrency, mapped contract selection, or user-facing CLI behavior.
