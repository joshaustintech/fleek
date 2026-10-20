# 113: Narrow the highest-cost remaining mutation contract

**What to build:** The first ranked slow mutation label uses the smallest public CLI comparison that detects its intended behavioral fault.

**Blocked by:** 112.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Use the first eligible ranked label from ticket 106, remeasured after caching. Bound this ticket to one label and its behavior, not an entire descriptor family.
- [x] Retain the broad public contract in the normal full test suite. Move or reuse only the narrow assertion needed for this mutation and preserve findings, mass/score, locations/order, coverage and normalized outcome relevant to that fault.
- [x] Show unchanged implementation passes and the exact mutant fails at its intended assertion/message; an unrelated earlier assertion must not supply the kill. Change only this mapping and necessary focused evidence.
- [x] Record compile/setup versus execution cost, run frequency and before/after focused timings. If measurement shows no avoidable repeated work, record that evidence and leave the mapping unchanged rather than creating a redundant contract.

## Answer

Ticket 106 ranked `Flay group ordering` first at a 40.97s focused median with the broad `test/duplication_contract.rb`. After contract caching, the same broad mapping took 42.63s on the first cold selected-set run and 35.64s warm; warm precompile was 3.347s and the full broad public contract occupied the remaining ~32.3s. This label runs once per complete mutation suite, so its broad execution was avoidable repeated work.

Added `test/duplication_group_order_contract.rb` for only the mixed method/class report. It checks the CLI finding status, both group kinds, exact locations, masses and scores, total/per-file score, coverage, normalized findings status, clean stderr, pinned Flay report, and the method-group-before-class-group order. The broad duplication contract remains in normal tests; its moved scenario now runs through this focused contract. The unchanged CLI passes. The intended mutation is caught at the exact `Flay group ordering differed` assertion after all other report fields pass.

Pinned Spinel 2026.09.12 (`112bae85c1a25fc5399009a849f805bfe691426b`), Flay 2.14.4, Reek 6.6.0. With `JOBS=1`, focused narrow cold was 18.98s total / 4.145s precompile; warm was 18.25s / 3.360s. A direct warm execution of the compiled narrow public contract took 0.28s. The warm end-to-end focused run fell from 35.64s to 18.25s (49%); precompile remained essentially unchanged, so the gain came from running the relevant comparison instead of the entire broad contract. The label executes once per complete mutation run.

Full `make check JOBS=4` passed 61 workers and caught the same 273 mutation labels. Flay score 0, Reek warnings 0, all 124 ticket documents valid. The changed complete source bundle caused 49 cache misses, compiled in 27.329s. ADR 0179 records the mapping and evidence.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
