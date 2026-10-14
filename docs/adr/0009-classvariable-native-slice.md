# ADR 0009: First native ClassVariable slice

## Status

Accepted for ticket 03.

## Decision

Implement `reek:ClassVariable` in the native Prism adapter for one simple, top-level class with a simple constant name and no superclass. Support class-variable reads, plain writes, and targets when exactly one occurrence exists. Reject modules, nested classes/modules, inheritance, complex class names, repeated occurrences, and compound writes until their scope and grouping behavior are implemented.

The CLI requires explicit check selection and returns 0 for a clean result, 2 for findings, and 1 for invalid or unsupported input. Reports include the selected check and completion state. Preserve Reek 6.6.0's finding name, class context, message, location, help URL, and finding exit status for the supported case.

## Rationale

Prism's AST distinguishes class-variable syntax from comments and strings and supplies source locations. This enables a useful bounded replacement without scanning source text or executing analyzed code. The native adapter explicitly destroys the Prism AST before freeing parser and option storage.

## Consequences

The first supported scope is intentionally narrow. Unsupported contexts fail clearly; they do not become clean success. This slice does not claim full Reek configuration, suppression, nested-scope, or grouping parity. Expand support only with reference comparisons and explicit behavior decisions.
