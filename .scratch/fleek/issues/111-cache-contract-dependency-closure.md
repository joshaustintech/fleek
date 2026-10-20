# 111: Reuse a contract with shared source dependencies

**What to build:** Focused call-descriptor mutations reuse a compiled contract safely when it includes shared pair-comparison and analysis helpers.

**Blocked by:** 110.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Extend the opt-in cache from the leaf contract to the existing call-descriptor public contract and its prepared source dependencies only; retain conservative complete prepared-bundle invalidation.
- [x] Changing the selected contract, its pair helper, the common analysis helper or temporary-path rewrite format forces a rebuild. A missing dependency fails clearly and never falls back to an older cached executable.
- [x] A cached contract executes against a second isolated worker and freshly rebuilt mutant, with no embedded first-run source, working-directory or output path leakage; original expected mutation failure remains checked.
- [x] Demonstrate miss/hit/invalidation using focused invocations and compile counts. Stop after this dependent contract; keep remaining contracts on the existing path.

## Answer

Extended opt-in caching to exactly `test/duplication_method_call_contract.rb` plus `test/duplication_method_pair_contract.rb`, alongside the existing parser leaf. Cache identity hashes every prepared file, including `analysis_runner.rb`, and the rewrite format. Missing dependency reads happen before cache lookup, so preparation fails before an older binary could be restored. Contract tests verify eligibility boundaries, selected source/helper/analysis-helper changes, rewrite-format changes, compiler/runtime/flag invalidation, corruption, failed builds, and concurrent publishers.

Pinned Spinel 2026.09.12 (`112bae85c1a25fc5399009a849f805bfe691426b`), Flay 2.14.4, Reek 6.6.0. An uncached focused baseline caught `Flay method call candidates` in 12.86s. An opted-in cold run logged a cache miss, compiled one shared binary, and caught the mutation in 19.06s; the next isolated run logged a hit, restored one binary, rebuilt the mutant, and caught the same mutation in 11.59s. The existing worker-directory and temp-root assertions passed on both invocations. The cold key calculation outweighs compilation savings; caching remains opt-in.

`make check JOBS=4` passed 60 workers, including full mutations; `make flay reek` reported Flay score 0 and Reek warnings 0; `make ticket-check` validated 124 documents; `git diff --check` passed. ADR 0177 records the boundary and tradeoff.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
