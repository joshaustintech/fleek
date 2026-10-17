# ADR 0066: Support classes under eight nested modules

## Status

Accepted.

## Context

Flay 2.14.4 reports module groups for direct class methods under a sole nested-module chain of eight modules. Fleek supported seven modules and reported this reference-supported shape incomplete. This class-under-module bound is independent of direct module-method traversal.

## Decision

Extend direct class collection under sole nested-module chains through eight modules. Preserve the separate direct module-method bound and mark nine-module class paths incomplete.

## Consequences

Eight-module class groups are complete with their full qualified scope, outer module location, and Flay mass. Nine-module class paths remain partial. No change is made to qualified module syntax or nested class depth.

## Evidence

`test/fixtures/duplication_eight_level_nested_module_class_boundary.rb` matches Flay 2.14.4 at similar `:module` mass/score 66 and lines 1/26. `test/fixtures/duplication_nine_level_nested_module_class_boundary.rb` matches Flay at mass/score 68 and lines 1/28 while Fleek reports incomplete coverage. Public contracts compare both boundaries; mutations lower the supported depth and relax the partial guard.
