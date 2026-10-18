# ADR 0094: Cache immutable Flay references during mutation checks

## Status

Accepted.

## Context

Each mutation rebuilds Fleek and runs its complete mapped public contract. The duplication contract also invokes the unchanged Flay 2.14.4 reference for many fixtures on every mutant. Within one isolated mutation shard, those reference inputs, arguments, and Flay executable do not change; only `bin/fleek.rb` is mutated. Re-running the same Flay processes adds time without increasing mutation coverage.

## Decision

During mutation checks only, persist Flay exit status, stdout, and stderr in the shard's disposable `build/mutation-reference-cache`. Key entries by the complete reference invocation (single path, mass plus path, or ordered path pair), using length-prefixed argument boundaries so distinct path pairs cannot collide. A contract assertion locks this distinction. Write status last so it marks a complete entry. Reuse entries across mutants in that shard. Run Flay normally when the cache environment variable is absent. Continue rebuilding each mutated Fleek binary and running its complete public contract.

## Consequences

Mutation runs still compare every changed Fleek binary against unchanged Flay output for every contract assertion. Normal test runs always invoke the live pinned Flay reference. Shards cannot share cache state, and cleanup of each disposable workspace removes its cache.

## Evidence

A compiled full duplication contract completed with all 94 Flay reference invocations live in 17.23 seconds. With the 94 reference results warmed in the disposable cache, it completed in 0.37 seconds (97.9% less contract runtime). Both runs passed. Full pinned `make check` with 183 mutants passed in 300.10 seconds; the preceding uncached full gate passed in 418.44 seconds, a 28.3% reduction. The cached gate retained 29/29 workers, zero Flay/Reek findings, and all mutants caught.
