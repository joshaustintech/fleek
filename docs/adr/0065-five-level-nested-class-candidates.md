# ADR 0065: Support five-level nested class candidates

## Status

Accepted.

## Context

Flay 2.14.4 reports matching `:class` groups for five-level nested class chains. Fleek previously marked this shape incomplete at a four-class traversal limit.

## Decision

Extend the bounded nested-class traversal through five classes, including the nested-wrapper recursion path. Keep six-level chains incomplete.

## Consequences

Five-level nested class groups are complete and retain outer-scope location, full scope identity, and Flay mass. The fixed bound remains finite; supported method grammar and sibling/wrapper collection rules remain unchanged for existing shapes.

## Evidence

`test/fixtures/duplication_five_level_nested_class_boundary.rb` matches Flay 2.14.4 at similar `:class` mass/score 58 and lines 1/18. `test/fixtures/duplication_six_level_nested_class_boundary.rb` matches Flay at mass/score 60 and lines 1/20 while Fleek reports incomplete status. Mutations restore the six-level cutoff or lower the wrapper recursion bound; both must fail public contracts.
