# ADR 0137: Support break and redo in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 includes `break` and `redo` nodes in method candidates inside blocks. Fleek currently marks these shared-parseable forms incomplete.

## Decision

Accept Prism `PM_BREAK_NODE` and `PM_REDO_NODE` in the existing recursive method candidate collector. Compare separate block fixtures through the compiled CLI against Flay and protect each node kind with a deterministic mutation.

## Consequences

The block fixtures match Flay's candidate mass, score, kind, and locations. The current fixtures establish masses 20 for `break value if value` and 18 for `redo if value`. Other unsupported control-transfer nodes remain outside this boundary.
