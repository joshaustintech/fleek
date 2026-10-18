# ADR 0134: Support yield expressions in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 includes `yield` expressions in method candidates. Bare yield and yield with a local-variable argument produce identical groups with different method masses.

## Decision

Accept Prism yield nodes in supported method candidate trees. Let the existing recursive collector account for supported yield arguments, preserving node shape and mass. Compare bare and argument-bearing yield fixtures with Flay through the compiled CLI; a deterministic mutation removes yield-node support and must fail the public contract.

## Consequences

Methods with bare yield or supported yield arguments can match Flay without adding special mass adjustments. Other unsupported control-flow and expression nodes remain outside this boundary.
