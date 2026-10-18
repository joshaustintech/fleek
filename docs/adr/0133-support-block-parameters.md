# ADR 0133: Support named block parameters

## Status

Accepted

## Context

Pinned Flay 2.14.4 groups methods with named block parameters. It adds no parameter mass and classifies differing names as similar rather than identical.

## Decision

Accept block parameters only when the parameter has a name. Compare block-parameter presence and names during identical-method classification; leave candidate mass unchanged. Continue rejecting anonymous block parameters. Compiled CLI contracts compare named and anonymous cases with Flay for kind, mass, locations, and coverage; deterministic mutations protect support, identity, and rejection.

## Consequences

Methods with named block parameters can contribute Flay-compatible candidates. Anonymous block parameters remain incomplete. This supersedes the block-parameter rejection boundary in ADRs 0119, 0122, 0128, 0130, 0131, and 0132.
