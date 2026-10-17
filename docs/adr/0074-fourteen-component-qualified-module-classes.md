# ADR 0074: Support fourteen-component qualified module class paths

## Status

Accepted.

## Context

Flay 2.14.4 reports class-method module groups under relative qualified module paths with fourteen constant components. Fleek stopped at thirteen. Candidate identity and module path buffers need fifteen constant slots: fourteen module names plus the class name.

## Decision

Expand both fixed buffers to fifteen names and support direct classes with supported methods under relative qualified module paths through fourteen constant components. Keep fifteen-component paths incomplete.

## Consequences

Fourteen-component groups report complete coverage and match Flay's node mass, score, locations, and ordering. Fifteen-component paths remain explicitly partial.

## Evidence

`test/fixtures/duplication_qualified_namespace_fourteen_components.rb` matches Flay 2.14.4 at similar `:module` mass/score 80 and lines 1/12. `test/fixtures/duplication_qualified_namespace_fifteen_components.rb` matches Flay at mass/score 82 and lines 1/12 while Fleek reports incomplete. Public CLI contracts compare both; mutations lower the supported boundary and accept the unsupported boundary.
