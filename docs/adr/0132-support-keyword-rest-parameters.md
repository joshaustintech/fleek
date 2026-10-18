# ADR 0132: Support named keyword-rest parameters

## Status

Accepted

## Context

Pinned Flay 2.14.4 groups methods with named keyword-rest parameters. It adds no parameter mass and classifies differing names as similar rather than identical.

## Decision

Accept keyword-rest parameters only when the parameter has a name. Compare keyword-rest presence and names during identical-method classification; leave candidate mass unchanged. Continue rejecting block parameters and anonymous keyword-rest syntax. A compiled CLI contract compares kind, mass, locations, and coverage against Flay, and focused deterministic mutations protect candidate acceptance and identity.

## Consequences

Methods with named keyword-rest parameters can contribute Flay-compatible candidates. Anonymous keyword-rest and unsupported block forms remain incomplete. This supersedes the keyword-rest rejection boundary in ADRs 0119, 0122, 0128, 0130, and 0131.
