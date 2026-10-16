# Parallel isolated check runs

Type: task  
Status: resolved  
Triage: ready-for-agent

## Goal

Run Fleek tests, mutations, and independent analyzer checks concurrently without shared-source, binary, or temporary-output races.

## Acceptance criteria

- [x] `make test`, `make mutation`, and `make check` use a CPU-bounded worker pool by default; `JOBS` can lower the limit.
- [x] Each test and mutation worker has an isolated project copy and temporary-output namespace.
- [x] Mutation cases are partitioned exactly once across workers, and each mutant is caught.
- [x] `make check` shares one worker pool across tests, mutation shards, and read-only checks.
- [x] Concurrent runs leave source and generated root binary untouched by worker mutations.
- [x] Flay and Reek checks remain clean; Spinel pin/version gate remains enforced.

## Comments

## Answer

Implemented with the pinned Spinel 2026.09.12 runner. Full `make check` passed at eight workers: 14 contracts, all 93 mutations caught, reference checks passed, Flay score 0, Reek 0 warnings. Concurrent `make test` plus a two-shard `make mutation` run also passed.
