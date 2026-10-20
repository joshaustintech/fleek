# ADR 0182: Give cache temporary paths instance-owned state

## Status

Accepted

## Context

The mutation contract cache incremented a mutable class-level `TEMPORARY_SERIAL` array for temporary filenames. This violated `docs/agents/ruby-maintainability.md`'s rule against global mutation and spread unrelated cache instances' path allocation through shared state.

## Decision

Keep the serial on each `MutationContractCache` instance. Include process ID, instance `object_id`, and the instance serial in each temporary filename. This preserves distinct names across processes, instances in the same process, and repeated allocations by one instance without global mutable state.

## Evidence

The cache contract now checks three temporary names from repeated calls across two instances. Replacing the suffix with a constant made this assertion fail; the instance-owned implementation passes. The full cache contract retains publisher, checksum corruption, dependency invalidation, and restore coverage. Full `make check JOBS=4` passed 61 workers and caught 273 mutations; Flay score 0, Reek warnings 0, and all 126 ticket documents valid. Pinned Spinel 2026.09.12; Flay 2.14.4; Reek 6.6.0.

## Consequences

Temporary-path allocation no longer mutates class-level state. Cache keys, cache format, and executable publication behavior are unchanged.
