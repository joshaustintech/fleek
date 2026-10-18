# ADR 0111: Preserve Flay case-condition mass

## Status

Accepted for the supported top-level method slice.

## Context

Flay 2.14.4 builds its comparison tree through Prism's RubyParser translator, which wraps each `when` condition list in a synthetic `:array` node. Fleek's Prism AST has no corresponding node. Without an adapter, matching case branches with different condition-list lengths can be incorrectly grouped, and candidate mass differs from Flay.

## Decision

Record a synthetic array marker immediately after each `when` node in the structural fingerprint and add one mass unit for that wrapper. Keep the marker in the existing fixed-size tree and account for it in the capacity check. The marker is `INT16_MIN`; the pinned Prism 1.9.0 enum ends at `PM_SCOPE_NODE = 152`, so the marker cannot collide with a node type or its negative closing tag. Track the mass adjustment per shape node in the existing signed adjustment array.

## Consequences

Case/when structure and mass match Flay without a second per-node buffer. The compiled CLI matches a multiple-condition fixture at mass/score 34 and produces the same clean result when corresponding `when` lists have different lengths. Focused CASE, WHEN, and synthetic-mass mutations are caught. Support is currently in the top-level method candidate path; other method forms remain in ticket 22.
