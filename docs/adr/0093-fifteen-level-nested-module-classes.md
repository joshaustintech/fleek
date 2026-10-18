# ADR 0093: Support classes under fifteen nested modules

## Status

Superseded by [ADR 0097](0097-dynamic-nested-scope-storage.md). Its fifteen-module evidence remains historical.

## Context

Flay 2.14.4 reports a complete `:module` group for direct class methods beneath a sole nested-module chain of fifteen levels. Fleek already preserves the candidate at that boundary but marks the selected source incomplete. The traversal frontier admits only one direct class at this depth; nested modules and method-only chains at the same frontier remain unsupported.

## Decision

Treat the direct class candidate at the existing fifteen-level frontier as complete. Keep the frontier shape restriction and the fourteen-level nested module method limit unchanged.

## Consequences

Fifteen-level nested-module class groups match Flay's kind, mass, score, outer declaration locations, and ordering with complete coverage. Deeper nested-module class paths and fifteen-level method chains remain incomplete.

## Evidence

`test/fixtures/duplication_fifteen_level_nested_module_class_boundary.rb` matches Flay 2.14.4 at similar `:module` mass/score 80 and lines 1/40. The public CLI contract now requires complete coverage. A focused mutation restores the incomplete marker at the frontier, and the contract catches it. The focused full duplication contract passes.
