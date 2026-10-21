# ADR 0210: Match UtilityFunction public_methods_only

## Status

Accepted for Ticket 73.

## Context

Reek 6.6.0 normally checks public and private stateless instance methods for `UtilityFunction`. With `public_methods_only: true`, it checks only public methods. Fleek previously marked the true setting incomplete.

## Decision

Track bare `public`, `private`, and `protected` visibility changes in the bounded class or module method scope. Apply the public-only filter when configured; preserve the default and explicit false behavior. Top-level methods and other class-body statements remain incomplete under this setting because their visibility is outside the bounded case.

## Consequences

The compiled CLI contract compares default visibility, explicit true, and explicit false settings against Reek for one public and one private stateless method. Mutations protect the visibility transition and the filter.

## Evidence

Pinned Reek 6.6.0 reports both methods by default and with explicit false, and only the public method with explicit true. The full check evidence is recorded in issue 73.
