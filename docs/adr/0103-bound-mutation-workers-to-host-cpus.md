# ADR 0103: Bound mutation workers to host CPUs

## Status

Accepted.

## Context

Each mutation rebuilds the native CLI, then runs its mapped public contract. Mutation work is CPU-heavy, so worker count can change the gate duration. The runner already caps `JOBS` to online logical CPUs.

## Decision

Keep mutation concurrency bounded by the host CPU count. Do not oversubscribe or lower the configured mutant set to chase shorter wall time.

## Consequences

All configured mutations and their complete mapped public contracts remain enabled. On the current eight-logical-CPU host, a mutation run requested with `JOBS=16` was capped to eight workers and took 171.04 seconds. `JOBS=4` took 240.94 seconds for the same passing mutation suite. A forced full gate at `JOBS=8` took 235.52 seconds and passed. Re-measure if the host or compiler changes; timing is evidence, not a contract threshold.

## Evidence

The deterministic runs used pinned Spinel 2026.09.12, the same checkout, and identical mutation set. See `.scratch/fleek/issues/27-duplicate-mutation-contract-compilation.md` and ADR 0099 for the earlier shared-contract compilation optimization.
