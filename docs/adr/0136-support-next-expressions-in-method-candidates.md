# ADR 0136: Support next expressions in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 includes `next` expressions inside method blocks when comparing structural candidates. A method pair with identical block contents has mass 24, while Fleek currently marks that syntax incomplete.

## Decision

Accept Prism `PM_NEXT_NODE` in the existing recursive method candidate collector. Verify the block fixture through the compiled CLI against Flay and use a deterministic mutation that removes next-node support.

## Consequences

`next` contributes one mass point per node, while its supported value is analyzed recursively. The fixture and mass mutation lock Flay's candidate shape and score. Other unsupported control-transfer nodes remain outside this boundary.
