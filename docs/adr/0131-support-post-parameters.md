# ADR 0131: Support required post parameters

## Status

Accepted

## Context

Pinned Flay 2.14.4 groups methods with required post parameters, including methods with optional positional parameters before them. It does not add post-parameter nodes to the candidate mass. Different post names and counts remain similar candidates rather than changing the group structure.

## Decision

Accept required positional post parameters in otherwise supported method signatures. Compare post names and counts when deciding whether methods are identical; preserve Flay's mass and similar-group behavior. Continue rejecting keyword-rest and block parameters. Compiled CLI contracts compare supported fixtures with Flay for mass, kind, locations, and coverage; deterministic mutations protect candidate acceptance, identity, and mass.

## Consequences

Methods with required post parameters can participate in Flay-compatible groups without changing candidate mass. Unsupported parameter forms remain incomplete. This supersedes the post-parameter rejection boundary in ADRs 0119, 0122, 0128, and 0130.
