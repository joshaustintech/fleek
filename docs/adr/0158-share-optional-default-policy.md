# ADR 0158: Share optional parameter default policy

## Status

Accepted

## Context

Flay 2.14.4 accepts bare receiverless method calls as defaults for both optional positional and optional keyword parameters. Fleek already modeled the positional form, but duplicated a narrower literal/constant allowlist for keyword defaults. This caused supported shared syntax to be reported incomplete.

## Decision

Use the same default-support predicate for positional and keyword optional parameters. Keep the existing two-unit parameter mass and compare default values with the existing identity rules.

## Consequences

The two parameter forms cannot drift on supported defaults. A compiled CLI contract and focused mutation cover keyword bare-call acceptance; the shared predicate remains the single place to extend when Flay evidence supports more default expressions.
