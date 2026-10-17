# ADR 0070: Support ten-component qualified module class paths

## Status

Superseded by [ADR 0071](0071-eleven-component-qualified-module-classes.md).

## Context

Historical context: Flay 2.14.4 reports class-method module groups under relative qualified module paths with ten constant components. Fleek stopped at nine, leaving a reference-supported group incomplete. Existing candidate identity and constant-path buffers already hold eleven names, enough for ten module components plus the class.

## Decision

Support direct classes with supported methods under relative qualified module paths through ten constant components. Keep eleven-component paths incomplete.

## Consequences

Ten-component groups report complete coverage and match Flay's node mass, score, locations, and ordering. Eleven-component paths remain explicitly partial.

## Evidence

`test/fixtures/duplication_qualified_namespace_ten_components.rb` matches Flay 2.14.4 at similar `:module` mass/score 72 and lines 1/12. `test/fixtures/duplication_qualified_namespace_eleven_components.rb` matches Flay at mass/score 74 and lines 1/12 while Fleek reports incomplete. Public CLI contracts compare both; mutations lower the supported boundary and accept the unsupported boundary.
