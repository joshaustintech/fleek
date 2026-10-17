# ADR 0084: Support eight-level nested class candidates

## Status

Accepted. Supersedes [ADR 0079](0079-seven-level-nested-class-candidates.md).

## Context

Flay 2.14.4 reports matching `:class` groups for eight-level nested class chains. Fleek supported seven classes and marked this reference-supported chain incomplete. Existing sibling-class and wrapper bounds are independent candidate forms.

## Decision

Extend single nested-class chain traversal through eight classes. Use one named depth limit for traversal and scope identity, so the two fail-closed checks stay aligned. Keep nine-level chains incomplete and preserve existing sibling and wrapper limits.

## Consequences

Eight-level class groups retain outer-scope location, full scope identity, and Flay mass. Nine-level chains remain partial. Direct-sibling and wrapper forms keep their existing limits.

## Evidence

`test/fixtures/duplication_eight_level_nested_class_boundary.rb` matches Flay 2.14.4 at similar `:class` mass/score 64 and lines 1/24. `test/fixtures/duplication_nine_level_nested_class_boundary.rb` matches Flay at mass/score 66 and lines 1/26 while Fleek reports incomplete coverage. Public contracts compare both outputs; mutations detect reduced six-, seven-, and eight-level support and accidental acceptance of nine levels.
