# ADR 0209: Match UnusedParameters block-local uses

## Status

Accepted for Ticket 72.

## Context

Reek 6.6.0's `UnusedParameters` analysis counts local reads inside an iterator block when their name matches a method parameter. This includes a same-name block parameter, even though Ruby's block parameter shadows the method parameter. Fleek previously stopped its local-use traversal at blocks and marked the method body incomplete.

## Decision

For `UnusedParameters`, traverse local reads and writes through one iterator block per method, matching Reek's name-based behavior. Keep `ControlParameter` separate and leave methods with multiple blocks or unsupported syntax incomplete.

## Consequences

The contract protects a same-name block parameter read, a different block parameter with a captured method parameter, and a genuinely unused method parameter. An explicit method exclusion exercises configuration through the public CLI.

## Evidence

Pinned Reek 6.6.0 and Fleek match on the exact finding at line 14 for `Parcel#unused`; `Parcel#shadowed` and `Parcel#captured` stay clean. Focused mutations prove block traversal and local-read recognition are required. Full gate evidence is in issue 72.
