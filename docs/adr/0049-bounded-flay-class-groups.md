# ADR 0049: Bounded Flay class groups

## Status

Accepted.

## Context

Flay 2.14.4 can report a duplicated `:class` tree even when Fleek already recognizes the matching method candidates. The existing native adapter treated that shape as unsupported because it could not prove the whole class tree from a partial candidate set.

## Decision

Recognize a class group when two different class scopes each contain exactly one supported direct method, their complete class bodies consist of that method, and their method trees match Flay's structural candidate shape at the configured mass threshold. Add one class-node mass to each method tree, report class declaration locations and `node="class"`, and keep different class names classified as similar. Unequal scope shapes, unsupported class entries, and a possible class group alongside an independent method group remain incomplete until report grouping can preserve every finding.

## Consequences

The public CLI matches Flay 2.14.4 for the cross-class fixture at similar `:class` mass/score 50 and class declaration lines 1 and 10. The mixed class/method fixture still reports its verified method group and incomplete coverage. This slice does not claim module groups, multiple groups in one source, or general nested-scope parity; Ticket 21 remains open.

## Evidence

`test/duplication_contract.rb` compares Fleek and pinned Flay on the class group and mixed-finding boundaries. `test/mutation_contract.rb` removes class-group selection and loosens the complete-scope checks; both changes must be caught by the public contract.
