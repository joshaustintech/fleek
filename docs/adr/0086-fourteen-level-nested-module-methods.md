# ADR 0086: Support methods under fourteen nested modules

## Status

Accepted. Supersedes [ADR 0081](0081-thirteen-level-nested-module-methods.md).

## Context

Flay 2.14.4 reports module groups for direct methods under a sole nested-module chain of fourteen modules. Fleek supported thirteen and marked this reference-supported shape incomplete. Candidate scope storage has spare capacity for this bounded extension.

## Decision

Extend direct nested-module method traversal through fourteen modules. Keep fifteen-module chains incomplete.

## Consequences

Fourteen-module groups report complete coverage and match Flay's node mass, score, outer location, and ordering. Fifteen-module chains remain explicitly partial.

## Evidence

`test/fixtures/duplication_fourteen_level_module_boundary.rb` matches Flay 2.14.4 at similar `:module` mass/score 58 and lines 1/35. `test/fixtures/duplication_fifteen_level_module_boundary.rb` matches Flay at mass/score 60 and lines 1/37 while Fleek reports incomplete coverage. Public CLI contracts compare both outputs; mutations detect losing 11-, 12-, 13-, and 14-level support and accepting fifteen levels.
