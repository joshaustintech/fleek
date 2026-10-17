# ADR 0063: Support nine-component qualified module class paths

## Status

Superseded by [ADR 0070](0070-ten-component-qualified-module-classes.md).

## Context

Historical context: Flay 2.14.4 reports class-method module groups under relative qualified module paths with nine constant components. Fleek supported paths through eight components. The constant-path collector used a fixed-size reverse buffer as well as a caller-provided destination, so both storage limits needed to cover the new depth.

## Decision

Allow nine module components plus the class name in stored candidate scope identity. Collect constant names into the caller-provided buffer and reverse them in place, avoiding a second fixed-size scratch array. Set the destination capacity to ten entries. Keep paths with ten or more module components incomplete.

## Consequences

Nine-component qualified module class groups are complete, and their full scope identity, locations, mass, score, and ordering remain compared through the public CLI. Ten-component qualified module paths remain an explicit partial boundary.

## Evidence

`test/fixtures/duplication_qualified_namespace_nine_components.rb` matches Flay 2.14.4 at similar `:module` mass/score 70 and lines 1/12. The public contract verifies the finding and complete coverage. `test/fixtures/duplication_qualified_namespace_ten_components.rb` confirms Flay still reports a similar `:module` group at mass/score 72 and lines 1/12 while Fleek reports incomplete coverage. Mutations lower the nine-component limit and allow the ten-component boundary; both must be caught by public CLI contracts.
