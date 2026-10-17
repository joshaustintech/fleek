# ADR 0051: Collect class groups under qualified module paths

## Status

Accepted.

## Context

Flay 2.14.4 reports module groups for a direct class under relative qualified module declarations such as `module Current::Versioned`. Fleek's namespace collector accepted only a single constant-read node or an explicit nested-module chain, so it marked these shared-grammar candidates incomplete.

## Decision

Flatten simple relative constant paths into their ordered constant names and collect direct simple classes beneath qualified module paths containing two through nine components. Carry the full module and class names into candidate identity, retain the module declaration line, and account for the qualified path in the module group's mass. Keep empty paths clean. Mark absolute or otherwise unsupported paths, paths with ten or more components, and unsupported qualified module bodies incomplete. ADRs 0062 and 0063 record the supported depth extensions and require candidate groups with different full path depths to stay separate.

## Consequences

Qualified module class groups retain the existing bounded class-method AST support and fail closed when the class or its methods are unsupported. A source may retain verified groups at multiple supported path depths while reporting incomplete coverage for a separate unsupported candidate. No general qualified namespace, sibling-class, or nested-class parity claim follows from this slice.

## Evidence

`test/duplication_contract.rb` compares a two-component qualified module group with Flay 2.14.4 at similar `:module` mass/score 56 and lines 1/12. The depth fixture compares seven- and eight-component paths: Flay reports separate groups with mass 66 and 68, and Fleek preserves both groups and complete coverage. Separate eight- and nine-component fixtures verify groups at mass/scores 68 and 70, at lines 1/12. Mutations lower the supported depth and remove full-path-depth grouping; both regressions are caught by the public CLI contract. The full Ticket 21 parity boundary remains open.
