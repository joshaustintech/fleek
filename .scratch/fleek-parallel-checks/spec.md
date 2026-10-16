# Parallel and isolated check runs

**Status:** open  
**Category:** enhancement  
**Triage:** ready-for-agent

## Problem

Fleek's project checks run serially. Their test contracts write fixed paths under `/tmp`, and mutation checks edit `bin/fleek.rb` and rebuild `build/fleek`; running these commands concurrently can corrupt evidence or the checkout.

## Decision

Run independent test contracts, mutation shards, and read-only analyzer checks concurrently, bounded by available logical CPUs and an optional lower `JOBS` value. Keep Spinel verification and the initial Fleek build as shared prerequisites. Give each worker a private project copy and temporary-output namespace. Split mutation labels across workers so each mutant is applied, built, and checked inside exactly one private copy.

The normal `make test`, `make mutation`, and `make check` commands use this runner. Failures are collected and reported after remaining workers finish; every worker copy is removed on completion.

## Acceptance

- Concurrent `make test` invocations finish with stable contract results.
- `make mutation` reports each configured mutant exactly once, all caught.
- Concurrent test and mutation runs do not change tracked source or interfere with each other's output or binaries.
- `make check` schedules test contracts, mutation shards, and reference/analyzer checks through one bounded worker pool.
- A caller can lower concurrency with `JOBS`; it cannot exceed available logical CPUs.
- Existing analyzer outputs, mutation failure assertions, and build prerequisites remain unchanged.
