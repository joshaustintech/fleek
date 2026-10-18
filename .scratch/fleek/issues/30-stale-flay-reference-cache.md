# 30: Invalidate copied Flay reference caches

**What to fix:** Mutation workers can reuse Flay output cached for older fixture contents when copied ignored build artifacts survive between runs.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Reproduction

- Pinned Spinel: `2026.09.12`, source `112bae85c1a25fc5399009a849f805bfe691426b`.
- Edit a Flay fixture at the same path so its expected mass changes, then run `SPINEL=/path/to/pinned-spinel/bin/spinel SPINEL_ROOT=/path/to/pinned-spinel make -B check JOBS=8`.
- The mutation harness copies ignored `build/mutation-reference-cache` data into each worker and enables that cache only for mutation contracts. Its key identifies invocation paths but not fixture bytes, so a fixture edit at the same path can make a worker compare the new expected result with old Flay output. Ordinary contracts do not enable the cache.

## Diagnosis

Three ranked causes: (1) stale shard cache copied from the prior source tree; prediction: clear it in each worker before mutation setup and the gate passes; (2) incorrect expected mass; disproved because live `bundle exec flay --mass 3` and compiled Fleek both report the updated mass 34; (3) mutants changing the reference result; disproved because only Fleek source is mutated while Flay remains unchanged.

## Acceptance criteria

- [x] Mutation worker initialization clears any copied Flay reference cache.
- [x] Repeated full mutation gates pass after fixture contents change without manual cache cleanup.
- [x] Ordinary contracts invoke live references; mutation runs reuse only per-run immutable results.
- [x] Full native build, contracts, all mutations, Flay, and Reek gates pass.

## Decision

Keep cache entries keyed by the full invocation within one mutation run, where source files are immutable. Clear copied ignored cache data at worker setup so it cannot cross source revisions. Bounded digest filenames store and verify the full invocation key before accepting hits. See ADR 0094. Full pinned `make -B check JOBS=8` passed all 33 workers, mutations, Flay, and Reek in 282.07s.
