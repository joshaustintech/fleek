# ADR 0059: Collect multiple methods from classes in qualified modules

## Status

Accepted.

## Context

Flay 2.14.4 reports `:module` groups when direct classes under relative qualified module paths contain multiple matching methods. Fleek already collected one-method classes under those paths but marked multi-method class bodies incomplete.

## Decision

Collect every supported direct method from each direct class in relative qualified module declarations with two through seven constant components. Preserve method order, the outer module location, and each class name in candidate identity. Count one class path toward module-scope mass regardless of its method count. A module scope is complete only when every class body entry produces a supported candidate; otherwise retain supported candidates but mark coverage partial.

## Consequences

The existing 32-body-entry, 24-candidate, method-grammar, and qualified-path bounds continue to apply. Nested wrappers and unsupported class-body entries do not gain support from this change.

## Evidence

`test/fixtures/duplication_qualified_namespace_multi_method_class_boundary.rb` matches Flay at similar `:module` mass/score 104 and lines 1/19. `test/fixtures/duplication_qualified_namespace_multiple_multi_method_classes.rb` matches at mass/score 42 and lines 1/23. Public contracts compare both outputs, and dedicated mutations restore the single-method restriction in each collection path. Ticket 21 remains open for broader candidate and grammar parity.
