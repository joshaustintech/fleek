# ADR 0079: Support seven-level nested class candidates

## Status

Accepted. Supersedes [ADR 0068](0068-six-level-nested-class-candidates.md).

## Context

Flay 2.14.4 reports matching `:class` groups for seven-level nested class chains. Fleek previously supported six classes and marked this reference-supported chain incomplete. Existing sibling-class and wrapper bounds are independent candidate forms.

## Decision

Extend single nested-class chain traversal through seven classes. Keep eight-level chains incomplete and preserve existing sibling and wrapper limits.

## Consequences

Seven-level class groups retain outer-scope location, full scope identity, and Flay mass. Eight-level chains remain partial. Direct-sibling and wrapper forms keep their existing limits.

## Evidence

`test/fixtures/duplication_seven_level_nested_class_boundary.rb` matches Flay 2.14.4 at similar `:class` mass/score 62 and lines 1/22. `test/fixtures/duplication_eight_level_nested_class_boundary.rb` matches Flay at mass/score 64 and lines 1/24 while Fleek reports incomplete coverage. Public contracts compare both outputs; mutations detect reduced seven-level support and accidental acceptance of eight levels, while retaining the six-level cutoff check.
