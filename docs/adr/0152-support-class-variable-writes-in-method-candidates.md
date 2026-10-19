# ADR 0152: Support class-variable writes in method candidates

## Status

Accepted

## Context

Flay 2.14.4 includes plain class-variable assignments in method candidates. Methods assigning the same variables match at mass 12, and renaming only those variables preserves a similar group.

## Decision

Include `PM_CLASS_VARIABLE_WRITE_NODE` in bounded method candidates without a mass adjustment. Compare the assigned variable name for identical-versus-similar classification.

## Consequences

Methods with plain class-variable assignments can be analyzed when all other syntax is supported. Contracts compare kind, mass, locations, and coverage with pinned Flay; focused mutations protect support, ordinary mass, and target identity.
