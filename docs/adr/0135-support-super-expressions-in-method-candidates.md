# ADR 0135: Support super expressions in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 includes both bare `super` and argument-bearing `super(value)` expressions in method candidates. Their Prism nodes differ, and both forms affect Flay's candidate identity and mass.

## Decision

Accept `PM_FORWARDING_SUPER_NODE` and `PM_SUPER_NODE` in the existing recursive method candidate collector. Compare bare and argument-bearing super fixtures through the compiled CLI against Flay, and protect each node form with a deterministic mutation.

## Consequences

Bare super matches at mass 6 and argument-bearing super at mass 8. The existing collector preserves argument structure and mass; unsupported values remain subject to the current expression boundary.
