# ADR 0122: Support splat arguments in method candidates

## Status

Accepted

## Context

Method calls with positional splat arguments, such as `normalize(*items)`, were rejected as unsupported even though Flay 2.14.4 analyzes this common call shape.

## Decision

Treat Prism `PM_SPLAT_NODE` as a supported method candidate node. The public contract compares renamed-parameter splat calls against Flay for group kind, mass, score, ordered locations, and complete coverage. A focused mutation removes splat-node support.

## Consequences

Splat arguments are supported within otherwise supported methods. Rest, post, keyword, keyword-rest, and block method parameters remain unsupported.
