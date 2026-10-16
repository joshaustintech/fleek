# Parallel isolated check runs

Type: task  
Status: open
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

Implementation was rolled back at the user's request. Reopened for an agent to implement and verify this slice again.
