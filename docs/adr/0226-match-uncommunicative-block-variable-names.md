# Match uncommunicative block variable names

Accepted for Ticket 89.

## Context

Reek 6.6.0 includes required block parameters and local assignments inside a method's blocks in `UncommunicativeVariableName` analysis. Fleek marked block parameter nodes unsupported, so selected files could be incomplete and omit Reek findings.

## Decision

Analyze simple required parameters and local assignments inside blocks within a direct method body. Keep each finding in the enclosing method context and use the block parameter group's source line. Optional, rest, keyword, destructured, and semicolon-declared block locals stay incomplete. Class-level block parameters remain incomplete because this slice only analyzes direct method bodies.

## Consequences

Contracts cover one-letter and numbered names, descriptive controls, configured accept/reject patterns, separate method contexts, and preservation of findings beside supported block arguments. The detector scope limit now states the supported block parameter boundary.
