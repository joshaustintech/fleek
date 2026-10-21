# Count TooManyConstants per nested module

Accepted for Ticket 82.

## Context

Reek 6.6.0 counts direct constant assignments in each namespace independently. The existing Fleek counter handled one class or module and rejected nested namespaces, so explicit `TooManyConstants` checks could not report the nested module's finding or preserve a clean outer scope.

## Decision

Support a source containing one top-level module with exactly one direct nested module for `TooManyConstants`. Count constant writes separately in each module, stop traversal at nested scopes and methods, and report the nested module with its qualified constant path. Keep other nested or compound scope shapes incomplete. Apply the configured `max_constants` threshold to each module independently.

## Consequences

The detector now matches pinned Reek for the supported nested namespace boundary while retaining an explicit scope limit for other shapes. The contract covers an outer module at the default threshold, a nested module one above it, and a configured threshold that makes both clean.
