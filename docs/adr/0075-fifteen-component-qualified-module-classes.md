# ADR 0075: Support fifteen-component qualified module class paths

## Status

Accepted.

## Context

Flay 2.14.4 reports class-method module groups under relative qualified module paths with fifteen constant components. Fleek stopped at fourteen. Candidate identity and module path buffers need sixteen constant slots: fifteen module names plus the class name.

## Decision

Expand both fixed buffers to sixteen names and support direct classes with supported methods under relative qualified module paths through fifteen constant components. Keep sixteen-component paths incomplete.

## Consequences

Fifteen-component groups report complete coverage and match Flay's node mass, score, locations, and ordering. Sixteen-component paths remain explicitly partial.

## Evidence

`test/fixtures/duplication_qualified_namespace_fifteen_components.rb` matches Flay 2.14.4 at similar `:module` mass/score 82 and lines 1/12. `test/fixtures/duplication_qualified_namespace_sixteen_components.rb` matches Flay at mass/score 84 and lines 1/12 while Fleek reports incomplete. Public CLI contracts compare both; mutations lower the supported boundary and accept the unsupported boundary.
