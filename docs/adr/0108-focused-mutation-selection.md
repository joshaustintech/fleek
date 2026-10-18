# ADR 0108: Apply focused mutation filters before shard work

## Status

Accepted.

## Context

Ticket 29 found that `FLEEK_MUTATIONS` did not actually narrow `make mutation JOBS=8`: shard selection returned before label selection, and the shared-contract precompiler always compiled every contract. A one-label request therefore performed the full mutation setup and all shard work.

## Decision

Filter mutation labels before shard assignment. Keep the stable full-list label index for assigning selected mutations to shards, so focused runs use the same deterministic shard as full runs and unrelated workers skip the mutant. Precompile only the unique public contracts mapped by the selected labels; compile all mapped contracts when no filter is set.

## Consequences

Focused mutation runs become a useful tight loop without changing which public contract proves the selected mutation. The focused one-label run fell from over 120 seconds to 25.02 seconds and compiled one shared contract instead of 18. The unfiltered run retains all mutation labels, shared contracts, and isolated worker boundaries. Ticket 29 records the full-gate proof.
