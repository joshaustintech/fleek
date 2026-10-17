# ADR 0072: Support twelve-component qualified module class paths

## Status

Superseded by [ADR 0073](0073-thirteen-component-qualified-module-classes.md).

## Context

Historical context: Flay 2.14.4 reports class-method module groups under relative qualified module paths with twelve constant components. Fleek stopped at eleven. Candidate identities therefore need thirteen constant slots: twelve module names plus the class name. The module path collector needs the same capacity.

## Decision

Expand both fixed buffers to thirteen names and support direct classes with supported methods under relative qualified module paths through twelve constant components. Keep thirteen-component paths incomplete.

## Consequences

Twelve-component groups report complete coverage and match Flay's node mass, score, locations, and ordering. Thirteen-component paths remain explicitly partial.

## Evidence

`test/fixtures/duplication_qualified_namespace_twelve_components.rb` matches Flay 2.14.4 at similar `:module` mass/score 76 and lines 1/12. `test/fixtures/duplication_qualified_namespace_thirteen_components.rb` matches Flay at mass/score 78 and lines 1/12 while Fleek reports incomplete. Public CLI contracts compare both; mutations lower the supported boundary and accept the unsupported boundary.
