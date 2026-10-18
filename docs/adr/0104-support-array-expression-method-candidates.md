# ADR 0104: Support array expressions in method candidates

## Status

Accepted.

## Context

Ticket 22 compares method and expression candidates against Flay 2.14.4. The bounded class-method AST walker rejected `ArrayNode`, which made an otherwise supported method partial and omitted a Flay class group.

## Decision

Treat array literals as supported class-method AST nodes and traverse their children with the existing structural fingerprint. Keep the current node and tree-size limits; unsupported descendants still mark the candidate partial.

## Consequences

The compiled CLI now matches Flay's similar class group at mass/score 40 and source lines 1/7 for a paired array-expression fixture. A named mutation removes array-node acceptance and must make the public contract fail. This adds one expression form without broadening unrelated method syntax.
