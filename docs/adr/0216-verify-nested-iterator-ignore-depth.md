# ADR 0216: Verify ignored iterator depth

## Status

Accepted for Ticket 79.

## Context

Reek 6.6.0 excludes configured iterator names from NestedIterators depth. For a three-level `each` / `map` / `each` chain with `map` ignored, effective depth is two and falls within the default threshold; without that exclusion, Reek reports the innermost iterator at line 5.

## Decision

Keep the existing depth calculation and ignore-name matching. Add public CLI parity evidence for both configured and unconfigured behavior, including exact finding line and complete clean status.

## Consequences

The existing detector behavior is pinned by the contract and existing ignored-list mutation. No implementation change is required.

## Evidence

Pinned Reek 6.6.0 and Fleek match the line 5/depth 3 finding without config; both are clean when `map` is ignored. Full gate evidence is in issue 79.
