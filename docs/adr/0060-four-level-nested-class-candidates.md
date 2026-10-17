# ADR 0060: Support four-level nested class candidates

## Status

Accepted.

## Context

Flay 2.14.4 reports matching `:class` groups for four-level nested class chains. Fleek supported three levels and marked the four-level reference case incomplete.

## Decision

Collect supported methods through four nested class declarations, preserving all class names in scope identity, using the outer class location, and counting each nested class once in scope mass. Keep deeper chains incomplete and omit their incomplete group.

## Consequences

The new limit extends the existing bounded traversal by one class level. Method grammar, candidate limits, sibling handling, and unsupported subtree behavior remain unchanged.

## Evidence

`test/fixtures/duplication_deeper_nested_class_boundary.rb` now matches Flay at similar `:class` mass/score 56 and lines 1/16. `test/fixtures/duplication_five_level_nested_class_boundary.rb` confirms the next level remains incomplete while Flay reports mass 58 at lines 1/18. A mutation removes the four-class guard and must be caught by the five-level boundary contract. Ticket 21 remains open for broader parity.
