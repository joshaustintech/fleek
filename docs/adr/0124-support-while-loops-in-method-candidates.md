# ADR 0124: Support while loops in method candidates

## Status

Accepted

## Context

Flay 2.14.4 finds similar method candidates containing `while` loops. Fleek rejected those methods despite already preserving the loop's AST shape and mass.

## Decision

Accept Prism `PM_WHILE_NODE` in method candidate trees. Compare generated loop methods against pinned Flay and protect support with a focused mutation.

## Consequences

Methods containing supported `while` loop bodies are analyzed with Flay-compatible grouping and mass. Other loop forms remain outside this slice.
