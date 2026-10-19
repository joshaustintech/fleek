# ADR 0153: Support constant keyword defaults in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 analyzes optional keyword parameters whose defaults are constant reads. Two methods with different constant defaults form a similar group at mass and score 10, with locations at lines 1 and 5. Treating these defaults as unsupported loses a candidate that Flay reports.

## Decision

Accept constant-read defaults for optional keyword parameters. Compare constant names when deciding whether method candidates are identical or similar, using the parser's constant identity helper. Preserve the existing two mass units per optional keyword parameter.

## Consequences

Constant-default keyword methods can be analyzed when their remaining syntax is supported. Paired CLI contracts and focused mutations protect acceptance and name-sensitive classification against Flay 2.14.4.
