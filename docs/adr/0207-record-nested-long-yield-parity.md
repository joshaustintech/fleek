# ADR 0207: Record nested LongYieldList parity

## Status

Accepted for Ticket 70.

## Context

Reek 6.6.0 reports oversized yields inside nested iterator blocks. Fleek's existing yield visitor already traverses nested blocks, but the contract covered only one block level.

## Decision

Keep the existing native behavior and add compiled-CLI evidence for yields two iterator blocks deep. Protect the default `max_params` boundary and the same case with configured `max_params: 4`.

## Consequences

The tests ensure traversal preserves the yield's source line and enclosing method context without introducing a separate nested-block counting rule.

## Evidence

Pinned Reek and Fleek match for three yielded values at the default threshold, four above it, and five above the configured threshold of four. The configured run leaves the four-value yield clean.
