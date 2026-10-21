# ADR 0217: Analyze FeatureEnvy inside one block

## Status

Accepted for Ticket 80.

## Context

Reek 6.6.0 counts receiver calls and self references inside a method block. Fleek's simple method-body whitelist rejected blocks before its receiver collector ran.

## Decision

Allow the existing FeatureEnvy visitor to inspect method bodies with one supported block, reusing the bounded single-block shape check. Keep multiple-block methods incomplete.

## Consequences

Public CLI contracts compare receiver counts, exact lines/context, configured method exclusion, a self-call control, and the multiple-block incomplete boundary. A mutation restoring the old body restriction must fail.

## Evidence

Pinned Reek 6.6.0 and Fleek report `Parcel#price` at lines 5, 6, and 7 for receiver `item`; self-heavy `update` remains clean. Full gate evidence is in issue 80.
