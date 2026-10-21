# ADR 0211: Record nested DuplicateMethodCall parity

## Status

Accepted for Ticket 74.

## Context

Reek 6.6.0 groups repeated method calls by their source form within a method, including calls in separate conditional branches. Fleek's existing call visitor already traversed those branches, but the contract lacked a nested-branch case.

## Decision

Keep the existing native behavior and add explicit compiled-CLI evidence for identical receiver and argument calls in both branches, a distinct argument control, and configured `allow_calls` suppression.

## Consequences

The fixture protects the expected lines and method context while ensuring distinct arguments do not join the repeated group. The allow-list case verifies the public configuration path without changing analyzer logic.

## Evidence

Pinned Reek 6.6.0 and Fleek match the finding at lines 4 and 6 for `order.total(:net)`; the single `order.total(:gross)` call stays clean. With `allow_calls: ["order.total"]`, both tools report clean results. Full gate evidence is recorded in issue 74.
