# ADR 0081: Support thirteen-level nested module methods

## Status

Superseded by [ADR 0086](0086-fourteen-level-nested-module-methods.md). Historical record; its thirteen-module limit was extended.

## Context

Flay 2.14.4 reports module groups for direct methods under a sole nested-module chain of thirteen modules. Fleek previously supported twelve and marked this reference-supported shape incomplete. Class-under-module traversal has an independent depth bound.

## Decision

Extend direct method collection under sole nested-module chains through thirteen modules. Keep fourteen-module chains incomplete and preserve the separate class-under-module depth bound.

## Consequences

Thirteen-module method groups are complete with full scope identity, outer module location, and Flay mass. Fourteen-module method chains remain partial. No change is made to nested class or qualified namespace syntax.

## Evidence

`test/fixtures/duplication_thirteen_level_module_boundary.rb` matches Flay 2.14.4 at similar `:module` mass/score 56 and lines 1/33. `test/fixtures/duplication_fourteen_level_module_boundary.rb` matches Flay at mass/score 58 and lines 1/35 while Fleek reports incomplete coverage. Public contracts compare both outputs; mutations detect losing 13-level support and mistakenly accepting 14 levels.
