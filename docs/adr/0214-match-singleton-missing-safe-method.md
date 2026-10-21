# ADR 0214: Match singleton MissingSafeMethod scopes

## Status

Accepted for Ticket 77.

## Context

Reek 6.6.0 reports a bang method declared inside `class << self` when its matching non-bang singleton method is absent. It scopes companions to the singleton-class body; an instance method with the same name does not count. Fleek previously scanned only direct class methods and returned a complete clean report.

## Decision

Scan method declarations inside direct singleton-class bodies for MissingSafeMethod only. Find companions within that same singleton body. Keep other detectors' traversal unchanged.

## Consequences

The public CLI contract checks exact Reek finding parity, a singleton companion clean control, an instance-method scope boundary, and configured exclusion. Unsupported singleton-class bodies remain incomplete.

## Evidence

Pinned Reek 6.6.0 reports `Parcel#deliver!` at line 7; Fleek matches. The singleton scope mutation is caught. Full gate evidence is in issue 77.
