# ADR 0244: Bound Rails Flay callback declarations

## Status

Accepted

## Context

The pinned 25-file Rails Flay contract retains the reference score-48 group at `UsersController:51,58`, but every selected source remains partial. The controller contains direct `before_action` declarations alongside methods. Flay's method candidates come from method definitions; these direct declaration calls do not add method candidates. Silently treating arbitrary class-body syntax as supported could hide nested methods or alter class grouping.

## Decision

Track direct callback declarations as a bounded Flay candidate-collection case. Accept only the reference-verified call forms with positional symbols, arrays, and keyword-hash options. Continue marking callback blocks, unknown declaration shapes, and unrelated unsupported class-body forms incomplete. Preserve already collected method candidates and compare findings, mass, score, ordering, and coverage against Flay 2.14.4.

## Consequences

Issue 130 owns the focused implementation and mutation proof. Rails-wide Flay parity remains open in issue 97 until every residual source gap has a verified implementation or explicit unresolved child. The existing partial result remains the truthful baseline until the callback case is implemented.

