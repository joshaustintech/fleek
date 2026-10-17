# ADR 0073: Support thirteen-component qualified module class paths

## Status

Accepted.

## Context

Flay 2.14.4 reports class-method module groups under relative qualified module paths with thirteen constant components. Fleek stopped at twelve. Candidate identity and module path buffers need fourteen constant slots: thirteen module names plus the class name.

## Decision

Expand both fixed buffers to fourteen names and support direct classes with supported methods under relative qualified module paths through thirteen constant components. Keep fourteen-component paths incomplete.

## Consequences

Thirteen-component groups report complete coverage and match Flay's node mass, score, locations, and ordering. Fourteen-component paths remain explicitly partial.

## Evidence

`test/fixtures/duplication_qualified_namespace_thirteen_components.rb` matches Flay 2.14.4 at similar `:module` mass/score 78 and lines 1/12. `test/fixtures/duplication_qualified_namespace_fourteen_components.rb` matches Flay at mass/score 80 and lines 1/12 while Fleek reports incomplete. Public CLI contracts compare both; mutations lower the supported boundary and accept the unsupported boundary.
