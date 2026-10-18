# ADR 0127: Support for loops in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 finds similar top-level methods containing `for` loops. Fleek previously rejected those methods because its supported method-candidate syntax did not include the loop and its local-variable target.

## Decision

Accept Prism `PM_FOR_NODE` and `PM_LOCAL_VARIABLE_TARGET_NODE` in method candidate trees. Compare the public Fleek report with Flay's kind, mass, score, locations, and complete coverage. Protect the candidate boundary with a focused mutation.

## Consequences

Methods containing supported `for` loops are grouped with Flay-compatible mass and locations. Loop syntax outside the supported candidate tree remains incomplete.
