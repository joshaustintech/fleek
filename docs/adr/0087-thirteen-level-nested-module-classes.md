# ADR 0087: Support classes under thirteen nested modules

## Status

Superseded by [ADR 0088](0088-fourteen-level-nested-module-classes.md). Historical record; its thirteen-module limit was extended.

## Context

Flay 2.14.4 reports module groups for direct class methods under a sole nested-module chain of thirteen modules. Fleek supported twelve and marked this reference-supported shape incomplete. The direct module-method limit is independent.

## Decision

Extend direct class collection under sole nested-module chains through thirteen modules. Keep fourteen-module class chains incomplete.

## Consequences

Thirteen-module class groups are complete with full scope identity, outer module location, and Flay mass. Fourteen-module class chains remain partial. Qualified module syntax and nested class depth are unchanged.

## Evidence

`test/fixtures/duplication_thirteen_level_nested_module_class_boundary.rb` matches Flay 2.14.4 at similar `:module` mass/score 76 and lines 1/36. `test/fixtures/duplication_fourteen_level_nested_module_class_boundary.rb` matches Flay at mass/score 78 and lines 1/38 while Fleek reports incomplete coverage. Public contracts compare both outputs; mutations detect losing twelve- and thirteen-level support and mistakenly accepting fourteen levels.
