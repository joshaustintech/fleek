# Parallel isolated check runs

Type: task  
Status: resolved
Triage: ready-for-agent

## Goal

Run Fleek tests, mutations, and independent analyzer checks concurrently without shared-source, binary, or temporary-output races.

## Acceptance criteria

- [ ] `make test`, `make mutation`, and `make check` use a CPU-bounded worker pool by default; `JOBS` can lower the limit.
- [ ] Each test and mutation worker has an isolated project copy and temporary-output namespace.
- [ ] Mutation cases are partitioned exactly once across workers, and each mutant is caught.
- [ ] `make check` shares one worker pool across tests, mutation shards, and read-only checks.
- [ ] Concurrent runs leave source and generated root binary untouched by worker mutations.
- [ ] Flay and Reek checks remain clean; Spinel pin/version gate remains enforced.

## Comments

## Answer

`make test`, `make mutation`, and `make check` now share a CPU-bounded worker pool. Tests and mutation shards run from private project copies with isolated `/tmp` namespaces; deterministic mutation partitioning caught all 93 configured mutants. The pinned compiler identity gate remains in place. `JOBS=2 make check SPINEL=/private/tmp/fleek-spinel-2026.09.12/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-2026.09.12` passed previously; an additional rerun was interrupted after making no visible progress. The full Fleek gate also passed with default eight-worker scheduling, including 14 contracts, all mutations, Flay, and Reek. The Spinel upstream `make check` reached 3,575 passes but was interrupted during its much larger suite; it is not reported as passing.
