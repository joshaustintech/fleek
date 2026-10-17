# ADR 0077: Support twelve-level nested module methods

## Status

Accepted. Supersedes [ADR 0069](0069-eleven-level-nested-module-methods.md).

## Context

Flay 2.14.4 reports module groups for direct methods under a sole nested-module chain of twelve modules. Fleek previously supported eleven and marked this reference-supported shape incomplete. Class-under-module traversal has an independent depth bound.

## Decision

Extend direct method collection under sole nested-module chains through twelve modules. Keep thirteen-module chains incomplete and preserve the separate class-under-module depth bound.

## Consequences

Twelve-module method groups are complete with full scope identity, outer module location, and Flay mass. Thirteen-module method chains remain partial. No change is made to nested class or qualified namespace syntax.

## Evidence

`test/fixtures/duplication_twelve_level_module_boundary.rb` matches Flay 2.14.4 at similar `:module` mass/score 54 and lines 1/31. `test/fixtures/duplication_thirteen_level_module_boundary.rb` matches Flay at mass/score 56 and lines 1/33 while Fleek reports incomplete coverage. The public contract compares both outputs; mutation checks prove that the contract catches losing 12-level support and mistakenly accepting 13 levels.
