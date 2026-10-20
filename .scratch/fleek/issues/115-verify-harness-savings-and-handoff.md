# 115: Verify harness savings before resuming feature work

**What to build:** Luna resumes existing feature tickets only after harness changes have reproducible savings and unchanged required correctness evidence.

**Blocked by:** 114; 116; 117.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Repeat ticket 106's same-input, same-budget probes after all harness slices. Report cold and warm phase timings, medians for bounded repetitions, total full-gate elapsed time and absolute/relative savings; do not promise an unmeasured speedup.
- [x] Run the pinned native build/tests, full unfiltered mutation suite, Flay and Reek, plus tracker/link/diff validation and required standards/spec review. Require zero findings and no surviving non-equivalent mutants; record justified exclusions. Existing baseline failures require explicit residual bug tickets and block this handoff, not silent acceptance.
- [x] Verify scheduler failure propagation, capped concurrency, dirty/untracked input preservation, cache invalidation/corruption/overlap and worker isolation through the earlier runnable regression contracts. Compare task and mutation inventories with baseline.
- [x] Record exact commands, tool identities, limitations, ADR links and verdicts in Answer/map. Resolve only when tickets 106–114 and any newly discovered harness blockers are resolved; then point Luna back to the existing feature frontier.
- [x] Keep all existing feature IDs, parent claims, acceptance criteria and dependency edges. README completion remains last, including future residual tickets.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.

## Answer

All harness tickets 106–114 and review blockers 116–117 are resolved. Pinned environment: Spinel 2026.09.12 at `112bae85c1a25fc5399009a849f805bfe691426b` (tag object `00ce35bb96e489620358ffbc48791001a73778a5`), Flay 2.14.4, Reek 6.6.0, macOS arm64, 8 logical CPUs. Ticket 106 baseline input was `bebf4e8a98e1d854e9de5d97c24dbe258bb6ccd7`; final measured HEAD was `b02416cab212bf3a8fe8b579380c682830864c20`, clean, same `JOBS=4` and full `make check` command.

Full gate timings: baseline 452.93s (56 workers); final cache-disabled 402.49s (61 workers; 49 contracts compiled); final warm-cache 377.99s (61 workers; 49 binaries restored). The cold-to-cold observed difference is 50.44s, 11.1%; warm versus the original baseline is 74.94s, 16.5%. These are single full-gate comparisons, not a speedup guarantee. Five worker tasks were added for the scheduler, precompile-budget, staging, cache, and focused group-order regression contracts; no prior task was removed. Mutation labels are unchanged from baseline, and the unfiltered current suite caught all 273 labels.

After all harness slices, three `make mutation JOBS=1 FLEEK_MUTATIONS='<label>'` repetitions per label and cache phase all caught the intended mutant. Median cold/warm precompile and total times:

| Label | Precompile median | Total mutation median | Ticket 106 total median |
| --- | ---: | ---: | ---: |
| Flay group ordering, cold | 3.97s | 18.82s | 40.97s |
| Flay group ordering, warm | 3.41s | 18.34s | 40.97s |
| Flay generated descriptor support, cold | 3.91s | 18.80s | 12.01s |
| Flay generated descriptor support, warm | 3.36s | 11.85s | 12.01s |

The focused contracts avoid repeated unrelated execution: group-ordering contract execution fell from about 32.3s to 0.28s; generated-descriptor support fell from 10.28s to 1.13s. Full mutation totals remain host-variable; the descriptor cold total does not show a reduction against its old median.

The final pinned cache-disabled `make check JOBS=4` passed all 61 workers and 273 mutations in 402.49s. The full check includes build, native contracts, mutation suite, pinned reference, Flay, and Reek. Separate `make flay reek` reported score 0 and warnings 0. Pinned `make ticket-check` passed 126 documents and `git diff --check` passed. No tests or findings were excluded.

Regression coverage verified in the runnable suite: scheduler out-of-order failure attribution and slot reuse (`check_runner_scheduler_contract.rb`); concurrency/precompile fan-out bounds, selected-contract cap, distinct temp roots, and `-O 1` (`check_runner_precompile_budget_contract.rb`); staged dirty/untracked and hidden/config inputs, excluded generated outputs, and worker source isolation (`check_runner_staging_contract.rb`); cache key invalidation, corruption, failed-build handling, concurrent publishers, and temporary-path uniqueness (`mutation_contract_cache_contract.rb`). The five added workers explain 56-to-61 task growth; mutation inventory stayed at 273 caught labels.

Standards/spec review covered the baseline-to-harness diff. Ticket 108's missing deterministic runner-budget proof was added under ticket 116 (ADR 0181); the mutable global cache counter was removed under ticket 117 (ADR 0182). No remaining documented-standard or spec findings block handoff. Review-only judgement calls about duplicated probe setup and cache parameter grouping remain non-blocking; existing project checks report no findings. Other harness decisions and evidence are in ADRs 0172–0182.

All existing feature IDs, parent claims, acceptance criteria, and dependencies were preserved; README tickets 103–105 remain last. The feature frontier resumes at [ticket 48: Compose method parameters with nested blocks](48-composed-parameters-and-blocks.md), still subject to its existing blockers. See [ADR 0183](../../../docs/adr/0183-harness-savings-and-correctness-handoff.md).
