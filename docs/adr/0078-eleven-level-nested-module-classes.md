# ADR 0078: Support classes under eleven nested modules

## Status

Accepted. Supersedes [ADR 0067](0067-ten-level-nested-module-classes.md).

## Context

Flay 2.14.4 reports module groups for direct class methods under a sole nested-module chain of eleven modules. Fleek previously supported ten and marked this reference-supported shape incomplete. The direct module-method bound is independent.

## Decision

Extend direct class collection under sole nested-module chains through eleven modules. Keep twelve-module class chains incomplete and preserve the separate direct module-method depth bound.

## Consequences

Eleven-module class groups are complete with full scope identity, outer module location, and Flay mass. Twelve-module class chains remain partial. No change is made to qualified module syntax or nested class depth.

## Evidence

`test/fixtures/duplication_eleven_level_nested_module_class_boundary.rb` matches Flay 2.14.4 at similar `:module` mass/score 72 and lines 1/32. `test/fixtures/duplication_twelve_level_nested_module_class_boundary.rb` matches Flay at mass/score 74 and lines 1/34 while Fleek reports incomplete coverage. The public contract compares both outputs; mutations prove the contract catches losing 11-level support and mistakenly accepting 12 levels.
