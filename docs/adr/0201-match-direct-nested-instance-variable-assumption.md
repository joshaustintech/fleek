# ADR 0201: Match direct nested InstanceVariableAssumption scope

## Status

Accepted for Ticket 64.

## Context

Reek 6.6.0 analyzes each class independently for instance-variable reads that are not assigned in that class's `initialize`. Fleek handled one simple class, but a direct nested class was rejected as incomplete even when its methods were supported. The nested class needs its own initialized-variable set and qualified context.

## Decision

Support one direct class nested in a simple class. Run the existing instance-variable analysis separately for the outer and inner class, and emit the inner class as `Outer::Inner`. Match reads against assignments in that class's own `initialize` only.

Keep deeper nested classes and classes wrapped in modules incomplete for a separate evidence-backed slice.

## Consequences

The detector reports nested assumptions without mixing the outer and inner classes' instance-variable sets. Initialization in the nested class can clear its own finding. Deeper and wrapped scopes remain explicit incomplete coverage.

## Evidence

The public contract matches the pinned `Profile::Credentials` warning at the nested class declaration line, then verifies that assigning the same variable in nested `initialize` yields a clean result. A nested-context exclusion confirms the qualified context flows through configuration. Focused mutations detect rejecting the direct child and ignoring its initializer.
