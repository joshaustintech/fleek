# ADR 0100: Preserve node kinds in dynamic Flay scope paths

## Status

Accepted.

## Context

Ticket 21's class-scope collector handled nested class chains but treated a nested module inside a class as unsupported. Flay 2.14.4 reports a class group when matching sibling classes contain matching nested modules. Comparing scope names and depth alone also risks treating a nested class and nested module as equivalent.

## Decision

Store each candidate scope path as dynamically sized constant names and matching class/module node kinds. Traverse a single-child class/module chain iteratively until reaching its direct methods. Compare both node kinds and names when calculating shared path mass or deciding whether candidates are identical. Keep outer candidate kind separate so a class group remains a class group even when it contains nested modules.

## Consequences

Mixed class/module nesting uses the same depth-independent path model as existing class and module chains. Matching classes containing modules can form the Flay class group; a module path and class path with the same names cannot be mistaken for identical structure. Capacity grows with parsed depth and fails closed on overflow or allocation failure.

## Evidence

`test/fixtures/duplication_modules_inside_sibling_classes.rb` matches Flay's similar `:class` group at mass and score 52. `test/fixtures/duplication_mixed_scope_kinds.rb` matches Flay's `:defn` group at mass and score 48 and verifies no class group is emitted. `test/fixtures/duplication_namespace_classes_containing_modules.rb` matches Flay's similar `:module` group at mass and score 54. Focused mutations disable iterative class traversal, nested module collection, or node-kind/group-kind comparison; each is caught by the public duplication contract. Generated 64-level class and module cases cover dynamic path growth.
