# 114: Narrow the next costly independent mutation contract

**What to build:** The next ranked independent slow mutation label avoids unrelated public comparisons while preserving the same behavioral fault detection.

**Blocked by:** 113.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Remeasure the second eligible ranked label from ticket 106 after ticket 113. Limit this slice to one independent behavior; do not reopen already optimized mappings or expand analyzed syntax.
- [x] Keep the broad regression contract enabled. Reuse the smallest appropriate existing focused contract before introducing a new one; preserve all assertions relevant to this label and its specific expected failure.
- [x] Prove baseline passes, exact mutant fails at the intended assertion and filtered selection runs only the requested mapping. Record comparable cold/warm phase timings and repeated execution avoided.
- [x] If no independently useful narrowing remains, record measured evidence and retain the mapping. Stop after this label; additional measured defects become separate tickets that block ticket 115.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.

## Answer

Ticket 106 ranked `Flay generated descriptor support` second among eligible independent labels after ticket 113. Its mapping ran the broad `test/duplication_generated_descriptor_contract.rb`; reuse `test/duplication_method_range_contract.rb`, the smallest existing public contract that exercises this descriptor support. The broad generated-descriptor contract remains enabled in ordinary checks and still backs the generated-descriptor mass mutation.

The focused range contract passes on baseline. The exact support mutant is caught at `range-expression methods were not analyzed`; filtered precompile selected only `test/duplication_method_range_contract.rb`. Since the shared mapping now catches the separate range-mass mutant at its more specific `range-expression kind, mass, or locations differed from Flay` assertion, update that expected failure. The precompile-budget contract sample now uses generated-descriptor mass instead of range candidates to keep ten distinct mapped contracts.

Comparable direct contract execution: broad generated-descriptor contract 10.28s, focused range contract 1.13s, saving about 9.15s per occurrence (about 89%). Focused cache-disabled, cache-miss, and warm invocations reported 3.869s, 3.947s, and 3.404s precompile time respectively; these complete mutation wall times were noisy, so only the direct contract comparison is used as the narrowing measure. Final `make check JOBS=4` passed 61 workers and caught all 273 labels, with 49 shared binaries restored, zero compiled, and 3.689s precompile elapsed. `make flay reek`, `make ticket-check` (124 documents), and `git diff --check` passed. Pinned Spinel 2026.09.12; Flay 2.14.4; Reek 6.6.0.

See [ADR 0180](../../../docs/adr/0180-focus-generated-descriptor-support-contract.md). Ticket 115 remains the next correctness handoff.
