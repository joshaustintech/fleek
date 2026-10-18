# ADR 0138: Support begin, rescue, and retry in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 includes `begin`, `rescue`, and `retry` nodes in method candidates. A repeated method pair with the same rescue body has mass 16; Fleek currently marks the shared syntax incomplete.

## Decision

Accept Prism `PM_BEGIN_NODE`, `PM_RESCUE_NODE`, and `PM_RETRY_NODE` in the recursive method candidate collector. Compare the rescue/retry fixture through the compiled CLI against Flay and protect each node type with its own deterministic mutation.

## Consequences

`retry` contributes one mass point per node; begin and rescue contribute no adjustment. Methods using this supported exception-flow shape retain Flay's candidate tree, mass, score, and locations. Rescue clauses with other syntax remain subject to the existing recursive support boundary.
