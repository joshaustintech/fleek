# ADR 0028: Support class-method unless branches

## Status

Accepted.

## Context

Rails controller and model methods use block and modifier `unless`. Ticket 19's class-method AST collector accepted `if`/`else` but rejected Prism `UnlessNode`, leaving these methods partial. The pinned Rails corpus includes `unless` branches in controllers and models. A fixture using matched block branches produces a similar `:defn` group with mass and score 62 in Flay 2.14.4.

## Decision

Add Prism `UnlessNode` to the bounded class-method AST grammar. Preserve it as a distinct tree node so `if` and `unless` structures cannot compare equal by accident. Continue to reject any unsupported child node and report partial coverage.

## Consequences

The CLI contract compares identical `unless` fixtures against Flay for group kind, mass, score, and ordered source lines. A mutation removes `UnlessNode` support and must make that contract fail. This extends only method-body syntax; class-level DSL calls and other unsupported Rails forms still keep the 25-file manifest incomplete.
