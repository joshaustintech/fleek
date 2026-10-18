# ADR 0140: Support regular-expression literals in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 includes regular-expression literals in method candidates. Pattern content and option flags affect whether matching method candidates are classified as similar or identical.

## Decision

Accept Prism `PM_REGULAR_EXPRESSION_NODE` in recursive method candidates. Compare the unescaped pattern bytes and node flags for identity, and validate same-pattern, changed-pattern, and changed-flag cases through the compiled CLI against Flay. Interpolated regular expressions were outside this slice; ADR 0141 extends the decision to support them.

## Consequences

Static regular-expression literals match Flay's mass and grouping behavior. Interpolated regular-expression support is specified in ADR 0141.
