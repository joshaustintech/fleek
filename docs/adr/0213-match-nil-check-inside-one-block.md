# ADR 0213: Match NilCheck inside one block

## Status

Accepted for Ticket 76.

## Context

Reek 6.6.0 reports `nil?` and nil comparisons inside a method block while leaving safe navigation clean. Fleek's method-body whitelist rejected block nodes before its NilCheck visitor could inspect them.

## Decision

Allow one supported block in NilCheck method bodies and retain the existing occurrence collector. Methods with multiple blocks or unsupported AST nodes remain incomplete.

## Consequences

The public CLI contract compares exact occurrence lines and method context against Reek, checks the safe-navigation control, and exercises method-context exclusion. Focused mutations protect block acceptance and source locations.

## Evidence

Pinned Reek 6.6.0 and Fleek match NilCheck at lines 4 and 5 for `Parcel#retrieve`; `value&.save` is clean. Full gate evidence is in issue 76.
