# ADR 0247: Bound Rails Flay empty method bodies

## Status

Accepted

## Context

The pinned Rails controllers include direct class methods with no body. Flay 2.14.4 emits no duplication group for those empty definitions, but Fleek currently rejects them as unsupported, making otherwise supported files incomplete.

## Decision

Treat a direct class method with a valid supported parameter list and no body as a supported zero-candidate method. Do not synthesize a duplication group or score for it. Preserve existing support requirements for nonempty bodies and fail closed on all other unsupported shapes.

## Consequences

Issue 133 owns the public CLI fixture, pinned Rails assertions, and mutation boundary. This decision does not broaden method parameters, class scopes, or nonempty method bodies. Rails-wide parity remains open in issue 97 until all remaining manifest shapes resolve.
