# ADR 0076: Support sixteen-component qualified module class paths

## Status

Accepted.

## Context

Flay 2.14.4 reports class-method module groups under relative qualified module paths with sixteen constant components. Fleek stopped at fifteen. Candidate identity and module path buffers need seventeen constant slots: sixteen module names plus the class name.

## Decision

Expand both fixed buffers to seventeen names and support direct classes with supported methods under relative qualified module paths through sixteen constant components. Keep seventeen-component paths incomplete.

## Consequences

Sixteen-component groups report complete coverage and match Flay's node mass, score, locations, and ordering. Seventeen-component paths remain explicitly partial.

## Evidence

`test/fixtures/duplication_qualified_namespace_sixteen_components.rb` matches Flay 2.14.4 at similar `:module` mass/score 84 and lines 1/12. `test/fixtures/duplication_qualified_namespace_seventeen_components.rb` matches Flay at mass/score 86 and lines 1/12 while Fleek reports incomplete. Public CLI contracts compare both; mutations lower the supported boundary and accept the unsupported boundary.
