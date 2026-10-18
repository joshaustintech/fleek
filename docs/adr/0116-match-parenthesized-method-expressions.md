# ADR 0116: Match parenthesized method expressions

## Status

Accepted

## Context

Flay 2.14.4 reports two methods with parenthesized calls as a similar `:defn` group at mass 8. Prism retains an explicit parentheses wrapper, while Flay's RubyParser tree does not. Fleek rejected the candidate because that wrapper was not normalized.

## Decision

Treat `PM_PARENTHESES_NODE` like a statement-list wrapper while collecting method candidates: visit its children without adding a tree marker. A compiled CLI contract compares method candidates with and without explicit self receivers against unchanged Flay output and checks mass, locations, and complete coverage. A focused mutation restores the previous behavior.

## Consequences

Parenthesized expressions normalize to their contained candidate tree. This handles grouping parentheses only; other wrapper and expression nodes remain separately bounded.
