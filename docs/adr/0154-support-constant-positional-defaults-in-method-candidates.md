# ADR 0154: Support constant positional defaults in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 analyzes optional positional parameters with constant-read defaults. Two methods with different constant defaults form a similar group at mass and score 10, at lines 1 and 5. ADR 0035's literal-only restriction omitted this shared-syntax candidate.

## Decision

Accept constant-read defaults for positional optional parameters. Compare their constant names when classifying candidates as identical or similar. Keep the existing optional-parameter mass and count rules.

## Consequences

The supported positional-default boundary now includes literal and constant reads. A dedicated compiled-CLI contract compares kind, mass, score, locations, ordering, and coverage with pinned Flay. Focused mutations protect constant-default acceptance and name-sensitive identity. ADR 0035 is superseded only for its literal-only default restriction.
