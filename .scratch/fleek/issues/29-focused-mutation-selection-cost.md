# 29: Honor focused mutation selection before shard work

**What to fix:** A requested focused mutation run still precompiles every shared contract and executes every mutation shard.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [x] `FLEEK_MUTATIONS` restricts mutation execution and shared-contract precompilation to the named mutation labels and their public contracts.
- [x] Isolated shard assignments stay deterministic; non-selected shards do no mutant build or contract run.
- [x] A selected mutation is caught, and an unfiltered complete mutation run still catches every configured mutation.
- [x] Record focused before/after time and full-gate verdict without asserting wall-clock limits.

## Diagnosis

Pinned Spinel `2026.09.12`, source `112bae85c1a25fc5399009a849f805bfe691426b`; command `FLEEK_MUTATIONS='Flay only missing repeated value' SPINEL=/private/tmp/fleek-spinel-2026.09.12/bin/spinel make mutation JOBS=8`. Despite requesting one label, output showed all 18 shared binaries compiled and all eight mutation shards ran every mapped case; the run took over two minutes. Three ranked causes: (1) shard selection ran before label selection, so `FLEEK_MUTATIONS` was ignored in shard mode; (2) precompilation always used every contract mapping; (3) each mutant rebuild and public contract run dominates after setup. The first two predictions were confirmed: filtering labels before deterministic shard assignment left unrelated workers idle, and selected mappings reduced shared compilation from 18 binaries to 1.

The same focused command now passes in 25.02s, catches the selected mutant, compiles 1 shared binary, and reports all 8 shard workers passed. This is at least a 79% improvement over the measured baseline lower bound of 120 seconds. The unfiltered `make -B check JOBS=8` passes in 247.06s with the pinned rebuild, 21 contracts, all mutation shards, Flay score 0, and Reek warnings 0. No wall-clock threshold was added.

## Answer

The focused filter now applies before shard selection and shared-contract compilation. Selected labels retain their stable full-list shard assignment; unrelated shards pass without building a mutant. With no filter, all 18 shared contracts and every configured mutation still run. ADR 0108 records the decision.
