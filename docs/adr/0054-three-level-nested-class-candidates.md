# ADR 0054: Support three-level nested class candidates

## Status

Accepted.

## Context

Flay 2.14.4 reports a `:class` group for matching three-level nested class chains. Fleek previously supported a single nested wrapper and marked the three-level reference case incomplete.

## Decision

Collect simple nested class chains up to three classes. Preserve all class names in scope identity, use the outer declaration location, and add one scope-mass unit per nested class. When a chain exceeds three classes, mark the source incomplete and omit that incomplete group.

## Consequences

The supported boundary is explicit and bounded. Deeper chains remain visible as incomplete coverage until separately proven.

## Evidence

`test/fixtures/duplication_deep_nested_class_boundary.rb` matched Flay 2.14.4 at similar `:class` mass/score 54 and locations 1/14. At the time, `test/fixtures/duplication_deeper_nested_class_boundary.rb` confirmed that a four-class chain stayed incomplete while Flay reported mass 56 at locations 1/16. ADR 0060 later extends the supported chain depth to four classes and records the new fifth-level incomplete boundary.
