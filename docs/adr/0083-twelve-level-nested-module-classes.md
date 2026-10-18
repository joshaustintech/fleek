# ADR 0083: Support classes under twelve nested modules

## Status

Superseded by [ADR 0087](0087-thirteen-level-nested-module-classes.md). Historical record; its twelve-module limit was extended.

## Context

Flay 2.14.4 reports module groups for direct class methods under a sole nested-module chain of twelve modules. Fleek supported eleven and marked this reference-supported shape incomplete. The direct module-method bound remains independent.

## Decision

Extend direct class collection under sole nested-module chains through twelve modules. Keep thirteen-module class chains incomplete.

## Consequences

Twelve-module class groups are complete with full scope identity, outer module location, and Flay mass. Thirteen-module class chains remain partial. Qualified module syntax and nested class depth are unchanged.

## Evidence

`test/fixtures/duplication_twelve_level_nested_module_class_boundary.rb` matches Flay 2.14.4 at similar `:module` mass/score 74 and lines 1/34. `test/fixtures/duplication_thirteen_level_nested_module_class_boundary.rb` matches Flay at mass/score 76 and lines 1/36 while Fleek reports incomplete coverage. The public contract compares both outputs; mutations prove the contract catches losing twelve-level support and mistakenly accepting thirteen levels.
