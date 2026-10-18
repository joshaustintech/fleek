# ADR 0089: Support nine-level nested class candidates

## Status

Accepted. Supersedes [ADR 0084](0084-eight-level-nested-class-candidates.md).

## Context

Flay 2.14.4 reports matching `:class` groups for nine-level nested class chains. Fleek supported eight classes and marked this reference-supported chain incomplete. Ten-level chains exceed the verified traversal boundary.

## Decision

Extend single nested-class chain traversal through nine classes. Keep ten-level chains incomplete and preserve existing sibling and wrapper limits.

## Consequences

Nine-level class groups retain outer-scope location, full scope identity, and Flay mass. Ten-level chains retain the verified class candidate but remain partial; see [ADR 0090](0090-preserve-ten-level-nested-class-candidate.md). Direct-sibling and wrapper forms keep their existing limits.

## Evidence

`test/fixtures/duplication_nine_level_nested_class_boundary.rb` matches Flay 2.14.4 at similar `:class` mass/score 66 and lines 1/26. `test/fixtures/duplication_ten_level_nested_class_boundary.rb` matches Flay at mass/score 68 and lines 1/28 while Fleek preserves the candidate and reports incomplete coverage. Public contracts compare both outputs; mutation checks detect reduced six- through nine-level support and accidental completion at ten levels.
