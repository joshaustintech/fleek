# ADR 0151: Support class-variable logical writes in method candidates

## Status

Accepted

## Context

Flay 2.14.4 includes class-variable `&&=` and `||=` writes in method candidate trees. Same-name writes have mass 12, renamed variables remain similar, and different logical operators do not form a method group.

## Decision

Include `PM_CLASS_VARIABLE_AND_WRITE_NODE` and `PM_CLASS_VARIABLE_OR_WRITE_NODE` in bounded method candidates. Add two mass points for each write and compare the class-variable name for identical-versus-similar classification. Treat AND and OR as distinct node kinds, matching Flay's no-group result for methods that differ only by logical operator.

## Consequences

Methods using these writes can be analyzed when their other syntax is supported. Contracts compare kind, mass, locations, and coverage with pinned Flay; mutations protect candidate support, mass, and target identity.
