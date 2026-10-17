# ADR 0080: Support seventeen-component qualified module class paths

## Status

Accepted. Supersedes [ADR 0076](0076-sixteen-component-qualified-module-classes.md).

## Context

Flay 2.14.4 reports class-method module groups under relative qualified module paths with seventeen constant components. Fleek previously supported sixteen; candidate identity and path buffers needed eighteen constant slots for seventeen module names plus the class name.

## Decision

Expand both fixed buffers to eighteen names and support direct classes with supported methods under relative qualified module paths through seventeen constant components. Keep eighteen-component paths incomplete.

## Consequences

Seventeen-component groups report complete coverage and match Flay's node mass, score, locations, and ordering. Eighteen-component paths remain explicitly partial.

## Evidence

`test/fixtures/duplication_qualified_namespace_seventeen_components.rb` matches Flay 2.14.4 at similar `:module` mass/score 86 and lines 1/12. `test/fixtures/duplication_qualified_namespace_eighteen_components.rb` matches Flay at mass/score 88 and lines 1/12 while Fleek reports incomplete. Public CLI contracts compare both outputs; mutations detect losing 17-component support and accepting 18 components.
