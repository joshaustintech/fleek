# ADR 0184: Normalize optional method and block mass together

## Status

Accepted

## Context

Ticket 48 combines positional and keyword method parameters with a nested block that has optional parameters. Existing contracts proved each descriptor independently, but the composed pair exposed a one-point-per-method overcount: Flay reported mass 44 and Fleek reported mass 46. The parameterized block's wrapper adjustment was already correct when method parameters had no optional defaults.

## Decision

When calculating method candidate mass, subtract the nested block-parameter wrapper adjustment if the method signature itself has an optional positional or optional keyword parameter. Keep the shared descriptor mass rules unchanged. Apply the same correction to top-level and class-method candidates.

Treat Flay's nested-group choice for renamed/default-variant signatures as a separate residual; track it in ticket 118 rather than broadening this mass fix.

## Evidence

On pinned Spinel 2026.09.12 and Flay 2.14.4, the composed identical public CLI fixture contract now matches at mass/score 44/88 and locations 1/7. A different-arity composed fixture matches Flay's clean result. Focused mass mutations are caught by the composed contract. Ticket 118 records the separate variant mismatch: Flay emits `:iter` at mass 22 while Fleek emits `:defn` at mass 36.

## Consequences

Optional method defaults and optional block parameters now compose with Flay's mass normalization without changing block-only results. Similar composed methods still require subtree-selection parity before parent ticket 43 can close.
