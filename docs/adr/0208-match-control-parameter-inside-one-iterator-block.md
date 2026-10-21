# ADR 0208: Match ControlParameter inside one iterator block

## Status

Accepted for Ticket 71.

## Context

Reek 6.6.0 reports a method parameter used as a condition inside an iterator block. Fleek's method-body support rejected blocks, and its ControlParameter walkers did not enter block bodies.

## Decision

Enable one iterator block per method body for `ControlParameter` only. Traverse its conditional branches to collect source lines and distinguish condition use from later data use. Keep `UnusedParameters` on its existing block-rejecting path. Other unsupported AST nodes and multiple blocks remain incomplete.

## Consequences

The contract compares pinned Reek and Fleek CLI results, including a condition-only finding, suppression when the parameter is also passed as data, and a configured method exclusion. Focused mutations prove both block traversal and data-use suppression are required.

## Evidence

Pinned Reek 6.6.0 and Fleek match for `Parcel#choose` at line 4; `Parcel#choose_with_data` stays clean. The explicit `reek:ControlParameter` run with the exclusion config is clean and complete. Full suite evidence is recorded in issue 71.
