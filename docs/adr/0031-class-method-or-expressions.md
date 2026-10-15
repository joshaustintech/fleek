# ADR 0031: Support boolean OR expressions in class methods

## Status

Accepted.

## Context

One method in the pinned Rails corpus uses a boolean `or` expression. The bounded class-method collector rejected Prism `OrNode`, so the source was partial even when the expression was structurally supported by Flay's method grouping.

## Decision

Support Prism `OrNode` in class-method ASTs. Preserve its operator node in structural equality and mass, and visit both operands using the existing bounded child traversal.

## Consequences

A paired fixture matches Flay 2.14.4 as a similar `:defn` group at mass/score 34 and ordered lines 2/12. A focused mutation proves that removing OR-node support breaks the contract. Class-level Rails declarations and other unsupported method forms still leave the full corpus incomplete.
