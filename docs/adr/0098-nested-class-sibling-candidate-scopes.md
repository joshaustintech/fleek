# ADR 0098: Preserve Flay's nested sibling class candidate scope

## Status

Accepted.

## Context

Flay 2.14.4 reports a class group when a single top-level class contains sibling classes that each wrap equivalent methods in another class. Fleek previously flattened those methods under their shared parent, so it retained the method group but missed the class group. Treating all wrapped siblings as independent groups also duplicates findings when multiple top-level classes already form a larger matching subtree.

## Decision

For a source with one top-level class, when all of its direct child classes form sole nested-class chains ending in supported direct methods, collect each child chain as its own class-scope candidate. Walk each chain iteratively and store its complete class-name path dynamically. For multiple top-level classes and all other sibling shapes, retain the existing aggregate candidate rules so outer matching subtrees remain the reported groups.

## Consequences

Fleek reports the `:class` group at each matching wrapped sibling declaration and retains arbitrary chain depth without per-level branches. The candidate strategy depends on the source-level sibling shape; additional compound forms remain subject to public parity tests against unchanged Flay.

## Evidence

`test/fixtures/duplication_nested_class_sibling_wrappers.rb` matches Flay 2.14.4 at similar `:class` mass 52, score 52, and declaration lines 2 and 13. The existing nested sibling and wrapped sibling contracts continue to match Flay's outer group. A targeted mutation disabling the wrapped sibling scope path is caught by the public CLI contract.
