# ADR 0101: Test dynamic namespace depth at representative boundaries

## Status

Accepted.

## Context

`test/duplication_contract.rb` ran paired Fleek and Flay CLI invocations for each qualified namespace length from 8 through 21. Those fixtures differed only by depth and repeated the same mass/location contract. A timed baseline took 42.20 seconds. One Flay process took 0.33 seconds and one Fleek process took 0.06 seconds.

## Decision

Keep one qualified-namespace path at the former 21-component boundary, plus generated 64-level class and module chains. Remove the intermediate 8–20 component fixtures and assertions. Keep separate fixtures for distinct scope shapes, grouping, mixed class/module identity, incomplete analysis, mass, score, and ordering.

## Consequences

The public contract checks a representative path beyond the former capacity boundary and still checks deep class and module traversal against Flay. It no longer reruns the same expectation at every intermediate length. The contract took 29.41 seconds after removing the redundant pairs, a 30.3% reduction. The final forced full gate passed with 29 workers, 185 caught mutation cases, Flay score 0, and Reek warnings 0 in 233.11 seconds. No wall-clock threshold is asserted. `.scratch/fleek/issues/28-qualified-namespace-reference-test-cost.md` records the timed fix and gate.

## References

The mutation-to-public-contract mapping follows the same principle recorded in [ADR 0099](0099-share-mutation-contract-binaries.md): select the complete relevant contract for each mutant while preserving deterministic public behavior checks. PIT's coverage-guided selection is guidance for relevance, not a Fleek runtime dependency.
