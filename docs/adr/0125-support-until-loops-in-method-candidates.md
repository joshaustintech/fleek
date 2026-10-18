# ADR 0125: Support until loops in method candidates

## Status

Accepted

## Context

Flay 2.14.4 finds similar method candidates containing `until` loops. Fleek rejected those methods even though its candidate representation can preserve the loop's AST shape and mass.

## Decision

Accept Prism `PM_UNTIL_NODE` in method candidate trees. Compare generated loop methods against pinned Flay and protect support with a focused mutation.

## Consequences

Methods containing supported `until` loop bodies are analyzed with Flay-compatible grouping and mass. Other loop forms remain outside this slice.
