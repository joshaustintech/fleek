# ADR 0067: Support classes under ten nested modules

## Status

Accepted.

## Context

Flay 2.14.4 reports module groups for direct class methods under a sole nested-module chain of ten modules. Fleek supported eight modules and reported this reference-supported shape incomplete. This class-under-module bound is independent of direct module-method traversal.

## Decision

Extend direct class collection under sole nested-module chains through ten modules. Preserve the separate direct module-method bound and mark eleven-module class paths incomplete.

## Consequences

Ten-module class groups are complete with their full qualified scope, outer module location, and Flay mass. Eleven-module class paths remain partial. No change is made to qualified module syntax or nested class depth.

## Evidence

`test/fixtures/duplication_ten_level_nested_module_class_boundary.rb` matches Flay 2.14.4 at similar `:module` mass/score 70 and lines 1/30. `test/fixtures/duplication_eleven_level_nested_module_class_boundary.rb` matches Flay at mass/score 72 and lines 1/32 while Fleek reports incomplete coverage. Public contracts compare both boundaries; a mutation lowering the supported cutoff is caught. The eleven-module class stays incomplete at the preceding nested-module traversal guard, so relaxing only the class-depth guard is equivalent for this fixture and is excluded.
