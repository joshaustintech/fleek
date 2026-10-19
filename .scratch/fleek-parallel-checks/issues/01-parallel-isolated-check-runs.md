# 01: Parallel isolated check runs

**What to build:** Fleek tests, mutations, and analyzer checks run concurrently without shared-source, binary, or temporary-output races.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [x] `make test`, `make mutation`, and `make check` use a CPU-bounded worker pool by default; `JOBS` can lower the limit.
- [x] Each test and mutation worker has an isolated project copy and temporary-output namespace.
- [x] Mutation cases are partitioned exactly once across workers, and each mutant is caught.
- [x] `make check` shares one worker pool across tests, mutation shards, and read-only checks.
- [x] Concurrent runs leave source and generated root binary untouched by worker mutations.
- [x] Flay and Reek checks remain clean; Spinel pin/version gate remains enforced.

## Comments

## Answer

`make test`, `make mutation`, and `make check` now share a CPU-bounded worker pool. Tests and mutation shards run from private project copies with isolated `/tmp` namespaces; deterministic mutation partitioning caught all 93 configured mutants. The pinned compiler identity gate remains in place. `JOBS=2 make check SPINEL=/private/tmp/fleek-spinel-2026.09.12/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-2026.09.12` passed previously; an additional rerun was interrupted after making no visible progress. The full Fleek gate also passed with default eight-worker scheduling, including 14 contracts, all mutations, Flay, and Reek. The Spinel upstream `make check` reached 3,575 passes but was interrupted during its much larger suite; it is not reported as passing.
