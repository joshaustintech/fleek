# ADR 0102: Preserve class groups beside unsupported sibling scopes

## Status

Accepted.

## Context

Ticket 21 requires preserving verified findings when another candidate shape is unsupported. The class collector treated a multi-child class body as one unit; an unsupported module or class sibling could hide a Flay group formed by otherwise supported sibling classes.

## Decision

When a class body has multiple direct class children, collect each supported class as its own typed scope candidate, even if another child is an unsupported scope kind or class shape. Skip only the unsupported class and mark the source partial. Also mark a parent containing both direct methods and sibling classes partial until those parent methods are collected as Flay candidates. Keep fail-closed handling for unsupported candidates and do not claim complete analysis.

## Consequences

Independent Flay class groups remain visible while status communicates omitted candidates. Scope names, node kinds, method candidates, and source locations continue through the existing dynamic-path model. Compound module candidates, unsupported sibling class candidates, and mixed parent-method/sibling-class candidates remain incomplete until separately paired with Flay.

## Evidence

`test/fixtures/duplication_class_mixed_sibling_scopes.rb` makes Flay 2.14.4 report a similar `:class` group at mass 50 and lines 2/11. Fleek reports the same group and score while returning incomplete status because the parent also contains a module. `Flay mixed sibling scope preservation` mutates the sibling traversal condition and is caught by the public duplication contract.

`test/fixtures/duplication_class_direct_and_sibling_methods.rb` makes Flay report the sibling class group at mass 50 and lines 13/22. Fleek preserves that group and reports incomplete status because parent direct methods are outside the collected sibling candidates. `Flay mixed direct and sibling methods incomplete status` mutates the status guard and is caught by the public duplication contract.

`test/fixtures/duplication_class_unsupported_sibling.rb` makes Flay report the supported sibling class group at mass 50 and lines 2/11 despite a sibling whose body includes an unsupported visibility call. Fleek preserves the group and reports incomplete status. `Flay supported siblings beside unsupported class` mutates the per-parent sibling collector and is caught by its focused public contract.
