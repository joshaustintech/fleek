# ADR 0068: Support six-level nested class candidates

## Status

Superseded by [ADR 0079](0079-seven-level-nested-class-candidates.md).

## Context

Flay 2.14.4 reports matching `:class` groups for six-level nested class chains. Fleek supported five classes and marked this reference-supported shape incomplete. The existing sibling-class and wrapper bounds are separate candidate forms.

## Decision

Extend the single nested-class chain traversal through six classes. Keep seven-level chains incomplete and preserve existing sibling and wrapper limits.

## Consequences

Historical decision: six-level class groups are complete; seven-level chains were partial at the time. ADR 0079 extends direct nested-class chains through seven and keeps eight-level chains partial. Direct-sibling and wrapper forms retain their independent limits.

## Evidence

Historical evidence is retained in [ADR 0079](0079-seven-level-nested-class-candidates.md), which records current seven/eight-level contracts and mutation checks.
