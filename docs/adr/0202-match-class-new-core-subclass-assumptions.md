# ADR 0202: Match Class.new core subclass assumptions

## Status

Accepted for Ticket 65.

## Context

Reek 6.6.0 reports a constant assigned `Class.new(Array)`, while Fleek marked every `Class.new` assignment incomplete. This left a simple, statically known core-class inheritance case outside the detector's supported boundary.

## Decision

Support one direct constant assignment whose value is `Class.new` with exactly one constant argument and no block, when the source has no class or module declarations. Emit the assigned constant and assignment line when the superclass is `Array`, `Hash`, or `String`. Treat other constant arguments as clean, matching Reek's bounded detector behavior.

Keep block, dynamic, multi-argument, wrapped, or otherwise unsupported `Class.new` forms incomplete. Preserve `IrresponsibleModule`'s existing unsupported treatment of these assignments.

## Consequences

The detector can report the known inheritance case and complete the custom-superclass clean control without claiming support for dynamic class construction or mixed declarations.

## Evidence

The compiled CLI contract compares pinned Reek for `Class.new(Array)`, a custom superclass, and an exclusion. Mutations prove both detection and the clean boundary.
