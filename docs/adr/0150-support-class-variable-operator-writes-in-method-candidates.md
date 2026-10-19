# ADR 0150: Support class-variable operator writes in method candidates

## Status

Accepted

## Context

Flay 2.14.4 includes class-variable operator writes in method candidate trees. Two identical methods containing `@@count += 1` have mass 24; renaming the class variable keeps a similar group, and changing `+=` to `-=` also keeps a similar group. Fleek previously marked these methods unsupported.

## Decision

Include `PM_CLASS_VARIABLE_OPERATOR_WRITE_NODE` in the bounded method candidate tree. Add the same two mass points Flay assigns to other operator writes. Compare both the class-variable name and operator token when distinguishing identical from similar candidates.

## Consequences

Methods with class-variable operator writes can be analyzed when all other candidate syntax is supported. Focused public contracts compare kind, mass, locations, and coverage with pinned Flay; mutation cases protect candidate support, mass, and identity.
