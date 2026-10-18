# ADR 0139: Support ensure in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 includes ensure bodies in method candidates. Structurally matching methods with begin/ensure form a similar group at mass 10; Fleek currently marks this shared syntax incomplete.

## Decision

Accept Prism `PM_ENSURE_NODE` in the existing recursive method candidate collector. Compare an ensure fixture through the compiled CLI against Flay and protect ensure-node support with a deterministic mutation.

## Consequences

Ensure contributes one fewer mass point than Prism's default node count. A focused mass mutation protects that adjustment; nested values remain governed by the recursive supported-expression boundary.
