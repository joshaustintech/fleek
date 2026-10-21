# ADR 0215: Isolate RepeatedConditional class scopes

## Status

Accepted for Ticket 78.

## Context

Reek 6.6.0 evaluates repeated conditions within each class. Fleek rejected a source with multiple top-level classes; aggregating condition groups across classes would also create false positives and mixed-context findings.

## Decision

For RepeatedConditional only, analyze direct top-level class bodies independently and reset condition groups for each class. Preserve source locations and class context. Other class layouts remain incomplete.

## Consequences

Public CLI contracts compare per-class clean results at threshold 3 and separate findings at threshold 1. A mutation that retains groups across classes must fail.

## Evidence

Pinned Reek 6.6.0 and Fleek both report `Crate` at lines 10 and 11 and `Parcel` at lines 3 and 4 with threshold 1; threshold 3 is clean. Full gate evidence is in issue 78.
