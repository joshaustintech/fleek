# ADR 0204: Bound IrresponsibleModule Class.new support

## Status

Accepted for Ticket 67.

## Context

Reek 6.6.0 checks a constant assigned `Class.new(Array)` for a descriptive comment. Fleek marked every `Class.new` assignment incomplete, even when its assignment and superclass were statically simple.

## Decision

For `IrresponsibleModule`, support one direct constant assignment to `Class.new` with exactly one constant superclass argument, no block, and no class/module declarations in the same source. Associate comments with the assigned constant. Keep dynamic arguments, blocks, wrapped assignments, and mixed scopes incomplete.

## Consequences

Fleek matches the pinned finding for an undocumented assignment, treats a descriptive comment as clean, and keeps configuration exclusions available through the assigned constant's context. The detector does not claim support for dynamic class construction.

## Evidence

The compiled CLI contract compares pinned Reek 6.6.0 for undocumented and documented assignments, checks a configured exclusion, and requires dynamic superclass construction to remain incomplete. Focused mutations protect all three boundaries.
