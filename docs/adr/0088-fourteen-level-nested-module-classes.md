# ADR 0088: Support classes under fourteen nested modules

## Status

Accepted. Supersedes [ADR 0087](0087-thirteen-level-nested-module-classes.md).

## Context

Flay 2.14.4 reports module groups for direct class methods under a sole nested-module chain of fourteen modules. Fleek supported thirteen and marked this reference-supported shape incomplete. The direct module-method depth limit remains fourteen modules.

## Decision

Permit a direct class at the outer module-method traversal frontier and extend direct class collection under sole nested-module chains through fourteen modules. Keep fifteen-module class chains incomplete; nested module methods at that same frontier remain incomplete.

## Consequences

Fourteen-module class groups are complete with full scope identity, outer module location, and Flay mass. Fifteen-module class groups retain their verified candidate but report incomplete coverage; fifteen-module method chains remain partial. Qualified module syntax and nested class depth are unchanged.

## Evidence

`test/fixtures/duplication_fourteen_level_nested_module_class_boundary.rb` matches Flay 2.14.4 at similar `:module` mass/score 78 and lines 1/38. `test/fixtures/duplication_fifteen_level_nested_module_class_boundary.rb` matches Flay at mass/score 80 and lines 1/40; Fleek preserves that candidate but reports incomplete coverage. Public contracts compare both outputs; mutations detect losing eleven- through fourteen-level complete status and mistakenly marking fifteen levels complete. The class-specific partial marker runs beyond the shared nested-module-method frontier.
