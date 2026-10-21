# ADR 0212: Record nested ManualDispatch parity

## Status

Accepted for Ticket 75.

## Context

Reek 6.6.0 flags `respond_to?` inside a method even when nested inside a conditional. Fleek's existing visitor already traverses those branches, but the compiled-CLI contract covered only a direct call.

## Decision

Keep the existing native behavior and add evidence for a nested `respond_to?` guard, an unguarded clean control, and a method-context exclusion through the explicit detector CLI.

## Consequences

The contract preserves Reek's finding location at the guard line and keeps the unrelated unguarded method clean. No new parsing behavior or detector-specific configuration was added.

## Evidence

Pinned Reek 6.6.0 and Fleek match the finding for `Parcel#guarded_dispatch` at line 3. Excluding that method yields complete clean coverage. Full gate evidence is in issue 75.
