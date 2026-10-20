# ADR 0200: Match direct nested Attribute scope

## Status

Accepted for Ticket 63.

## Context

Reek 6.6.0 analyzes writable attribute declarations within each class context. Fleek handled one simple scope but marked a direct nested class incomplete, even though Reek reports its writable declarations. The nested class has its own public visibility state; an enclosing class's `private` marker does not carry into it.

## Decision

Support one direct class nested in a simple class. Analyze each class body independently, stop outer traversal at the child class, reset attribute visibility to public for that child, and build its qualified `Outer::Inner#attribute` context. Preserve `attr_reader` as clean and apply configured context exclusions to the fully qualified name.

Keep deeper or wrapped class contexts incomplete for a separate evidence-backed slice.

## Consequences

This matches the pinned nested writable-attribute warnings without merging parent and child visibility or attributing child findings to the outer class. Other nested scope shapes remain explicit incomplete coverage.

## Evidence

The public contract compares literal `attr_accessor` and `attr_writer` findings plus a read-only `attr_reader` control against Reek 6.6.0 when the outer class is private. A configured exclusion verifies the nested `Profile::Credentials#secret` context. Focused mutations detect rejection of the child class and inherited private visibility.
