# 106: Measure reproducible harness phase costs

**What to build:** A maintainer can reproduce cold and warm harness costs and choose fixes from measured compile, staging, scheduling and contract-execution work.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Record exact commands, pinned compiler/reference identities, CPU count, JOBS, input revision and dirty-input identity. Run one clean baseline, then three repetitions of the bounded probes; do not overlap unrelated gates.
- [x] Provide one small pinned-Spinel Ruby evidence command using existing helpers. Separate worker staging, contract precompile, mutant build and contract execution; report worker idle periods without adding timing assertions to ordinary contracts.
- [x] Rank at least three falsifiable causes: waiting for oldest worker, serial default precompile and repeated unchanged compilation. Change one variable per probe; include workspace-copy and mutation-contract fan-out measurements.
- [x] Record raw statuses and existing analyzer findings separately from timing. Publish up to two highest aggregate-cost mutation labels/contracts as ranked rows, excluding mappings already narrowed by resolved tickets; if fewer qualify, record that measured result. Record full-run and focused probe evidence without claiming a fix.

## Answer

Pinned Spinel build, Flay/Reek versions, host CPU count, `JOBS`, input revision, dirty claim-file identity, full-gate statuses, analyzer findings, copy bytes/timing, and ranked mutation probes are recorded in [ADR 0172](../../../docs/adr/0172-measure-harness-costs.md). Full `make check` passed 56 workers in 452.93s. Focused probes caught both mutations in all three repetitions. The two highest measured focused totals were `Flay group ordering` (median 40.97s, broad `duplication_contract.rb`) and `Flay generated descriptor support` (median 12.01s, generated descriptor contract). Per-phase probes are reported separately and are not presented as an additive decomposition. No optimization or speedup is claimed; ticket 115 remains the post-change handoff gate.

Commands used: `make check JOBS=4`; `make mutation JOBS=1 FLEEK_MUTATIONS='Flay group ordering'` (three runs); `make mutation JOBS=1 FLEEK_MUTATIONS='Flay generated descriptor support'` (three runs); `SPINEL -E test/mutation_contract.rb` with `FLEEK_PRECOMPILE_MUTATION_CONTRACTS=1`; direct pinned `spinel -O 0` compile; direct execution of the precompiled public duplication contract; and `rsync -a --stats --exclude=/build/mutation-*` (three runs). The initial stale compiler failure was fixed by rebuilding from the exact pinned tag; no project code changed.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
