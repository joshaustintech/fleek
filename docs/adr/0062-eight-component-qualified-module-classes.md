# ADR 0062: Support eight-component qualified module class paths

## Status

Accepted.

## Context

Flay 2.14.4 reports class-method module groups beneath relative qualified module paths with eight constant components. Fleek supported paths through seven components and marked the eighth incomplete. Supporting the new depth also exposed that Fleek could combine equal-shaped candidates from different path depths, while Flay keeps those groups separate.

## Decision

Extend qualified module path capacity to eight module components, leaving the class name as the ninth stored scope name. Keep paths with nine or more module components incomplete. Require paired scope candidates to have equal full scope depth before grouping so matching methods from distinct qualified path depths remain separate.

## Consequences

Eight-component qualified module class groups are complete and preserve their full path identity and mass. Existing supported groups at different path depths remain independent. Other qualified-path syntax and broader class-body forms remain partial.

## Evidence

`test/fixtures/duplication_qualified_namespace_eight_components.rb` matches Flay's similar `:module` group at mass/score 68 and lines 1/12. `test/fixtures/duplication_qualified_namespace_depth_boundary.rb` matches Flay's separate eight- and seven-component groups at mass/scores 68 and 66, lines 23/34 and 1/12, with complete coverage. `test/mutation_contract.rb` lowers the path limit and removes the equal-depth grouping guard; both mutants must fail the public CLI contract.

The duplication contract's output verifier uses `String#index` for variable expected fragments. Under the pinned Spinel compiler, `String#include?` returned false for a present 43-character Flay fragment while `String#index` returned its correct offset (39); this keeps the public-output assertion reliable.
