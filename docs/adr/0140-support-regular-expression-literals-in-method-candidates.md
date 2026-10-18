# ADR 0140: Support regular-expression literals in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 includes regular-expression literals in method candidates. Pattern content and option flags affect whether matching method candidates are classified as similar or identical.

## Decision

Accept Prism `PM_REGULAR_EXPRESSION_NODE` in recursive method candidates. Compare the unescaped pattern bytes and node flags for identity, and validate same-pattern, changed-pattern, and changed-flag cases through the compiled CLI against Flay. Verify interpolated regex methods remain incomplete. Protect candidate support, content identity, flag identity, and the interpolation boundary with separate deterministic mutations.

## Consequences

Static regular-expression literals match Flay's mass and grouping behavior. Interpolated regular expressions remain outside this boundary.
