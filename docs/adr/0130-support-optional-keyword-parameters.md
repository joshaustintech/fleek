# ADR 0130: Support optional keyword parameters

## Status

Accepted

## Context

Pinned Flay 2.14.4 groups methods with optional keyword defaults, counts each supported default as two mass units per method, and compares keyword names and defaults when classifying identical methods. It leaves methods with different optional keyword counts ungrouped.

## Decision

Accept optional keyword parameters only when their defaults are supported literals. Add two mass units for each, compare names and literal defaults for identity, and include optional keywords in Flay's optional-parameter-count grouping rule. Reject unsupported defaults and continue rejecting post, keyword-rest, and block parameters. Compare candidate and clean cases with Flay through the compiled CLI; focused deterministic mutations protect acceptance, identity, mass, and count behavior.

## Consequences

Top-level and class-method candidates can now match Flay for supported optional keyword syntax. Optional keywords with unsupported defaults remain outside the parity boundary. ADR 0129's optional-keyword rejection boundary is superseded.
