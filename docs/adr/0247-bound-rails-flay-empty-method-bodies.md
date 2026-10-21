# ADR 0247: Bound Rails Flay empty method bodies

## Status

Accepted

## Context

The pinned Rails controllers include direct class methods with no body. Flay 2.14.4 emits no method-level duplication group for an empty definition, but includes empty methods in class-level candidate trees. Fleek currently rejects those definitions, making otherwise supported files incomplete. Omitting empty definitions from class candidates would also miss Flay's class-level groups.

## Decision

Treat a direct class method with a valid supported parameter list and no body as a candidate with an empty body tree. It contributes no method-level body group, while class-level groups retain its method identity and Flay mass. Preserve existing support requirements for nonempty bodies and fail closed on all other unsupported shapes.

## Consequences

Issue 133 implements the public CLI fixtures and pinned Rails assertion. Empty-only classes remain clean; paired classes with distinct empty method names match Flay's similar `:class` group at mass/score 56. The focused acceptance and mass mutations protect the boundary. This decision does not broaden method parameters, class scopes, or nonempty method bodies. Rails-wide parity remains open in issue 97 until all remaining manifest shapes resolve.
