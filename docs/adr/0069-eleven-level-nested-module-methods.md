# ADR 0069: Support eleven-level nested module methods

## Status

Accepted.

## Context

Flay 2.14.4 reports module groups for direct methods under a sole nested-module chain of eleven modules. Fleek supported ten modules and marked this reference-supported shape incomplete. Class-under-module traversal has an independent depth bound.

## Decision

Extend direct method collection under sole nested-module chains through eleven modules. Keep twelve-module chains incomplete and preserve the separate class-under-module depth bound.

## Consequences

Eleven-module method groups are complete with full scope identity, outer module location, and Flay mass. Twelve-module method chains remain partial. No change is made to nested class or qualified namespace syntax.

## Evidence

`test/fixtures/duplication_eleven_level_module_boundary.rb` matches Flay 2.14.4 at similar `:module` mass/score 52 and lines 1/29. `test/fixtures/duplication_twelve_level_module_boundary.rb` matches Flay at mass/score 54 and lines 1/31 while Fleek reports incomplete coverage. Public contracts compare both boundaries; mutations lower the supported depth and relax the partial guard.
