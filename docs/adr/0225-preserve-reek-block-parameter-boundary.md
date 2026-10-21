# Preserve Reek block parameter behavior

Accepted for Ticket 88.

## Context

Reek 6.6.0's `UncommunicativeParameterName` detector checks the parameters of each detected expression. Its public CLI reports no findings for short or descriptive block parameters, including when accept/reject patterns are configured. Fleek already reports the selected block-only source clean and complete.

## Decision

Keep block parameters outside Fleek's `UncommunicativeParameterName` findings to match Reek 6.6.0. Add public CLI regression coverage for default and configured cases. Continue analyzing method parameters as before.

## Consequences

The detector's documented boundary remains simple method parameters. Ticket 88 records verified no-op behavior rather than adding unsupported block-parameter findings.
