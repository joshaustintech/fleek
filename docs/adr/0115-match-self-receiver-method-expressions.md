# ADR 0115: Match self-receiver method expressions

## Status

Accepted

## Context

Flay 2.14.4 reports two methods with `self.convert(value)` as a similar `:defn` group at mass 10. Fleek rejected the candidate because `PM_SELF_NODE` was not supported in method expression trees.

## Decision

Accept `PM_SELF_NODE` as a structural method-expression node. The existing tree comparison preserves the explicit receiver distinction from an implicit call, without a value-specific equality rule. A public CLI contract compares the finding, mass, locations, and complete coverage with unchanged Flay; a focused mutation removes self-node support.

## Consequences

Explicit self-receiver calls are supported in method candidates. Other receiver forms remain unsupported unless separately matched to Flay.
