# ADR 0068: Support six-level nested class candidates

## Status

Accepted.

## Context

Flay 2.14.4 reports matching `:class` groups for six-level nested class chains. Fleek supported five classes and marked this reference-supported shape incomplete. The existing sibling-class and wrapper bounds are separate candidate forms.

## Decision

Extend the single nested-class chain traversal through six classes. Keep seven-level chains incomplete and preserve existing sibling and wrapper limits.

## Consequences

Six-level class groups retain outer-scope location, full scope identity, and Flay mass. Seven-level chains remain partial. Direct-sibling and wrapper forms keep their existing limits.

## Evidence

`test/fixtures/duplication_six_level_nested_class_boundary.rb` matches Flay 2.14.4 at similar `:class` mass/score 60 and lines 1/20. `test/fixtures/duplication_seven_level_nested_class_boundary.rb` matches Flay at mass/score 62 and lines 1/22 while Fleek reports incomplete coverage. Mutations restore the five-class cutoff and relax the six-class cutoff; both must fail public contracts.
