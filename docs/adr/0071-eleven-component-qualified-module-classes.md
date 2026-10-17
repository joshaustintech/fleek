# ADR 0071: Support eleven-component qualified module class paths

## Status

Superseded by [ADR 0072](0072-twelve-component-qualified-module-classes.md).

## Context

Historical context: Flay 2.14.4 reports class-method module groups under relative qualified module paths with eleven constant components. Fleek stopped at ten, although the existing 12-name candidate and collector buffers hold eleven module names plus the class.

## Decision

Support direct classes with supported methods under relative qualified module paths through eleven constant components. Keep twelve-component paths incomplete.

## Consequences

Eleven-component groups report complete coverage and match Flay's node mass, score, locations, and ordering. Twelve-component paths remain explicitly partial.

## Evidence

`test/fixtures/duplication_qualified_namespace_eleven_components.rb` matches Flay 2.14.4 at similar `:module` mass/score 74 and lines 1/12. `test/fixtures/duplication_qualified_namespace_twelve_components.rb` matches Flay at mass/score 76 and lines 1/12 while Fleek reports incomplete. Public CLI contracts compare both; mutations lower the supported boundary and accept the unsupported boundary.
