# ADR 0129: Support required keyword parameters

## Status

Accepted

## Context

Pinned Flay 2.14.4 groups methods with required keyword parameters. Fleek previously rejected all keywords. Flay assigns one mass unit per required keyword in each method and classifies renamed required keyword names as similar rather than identical.

## Decision

Accept required Prism keyword parameters in top-level and class-method candidates, adding one mass unit per parameter. Compare required keyword counts and names when classifying identical method trees. Continue rejecting optional keyword parameters, post parameters, keyword-rest parameters, and block parameters. A shared compiled-CLI contract compares the result with Flay's kind, mass, total score, locations, and coverage. Focused deterministic mutations remove acceptance, mass, and name comparison.

## Consequences

Methods with required keywords can contribute Flay-compatible candidates without broadening support to keyword defaults or other parameter forms. ADR 0119's keyword rejection boundary is superseded for required keywords only.
