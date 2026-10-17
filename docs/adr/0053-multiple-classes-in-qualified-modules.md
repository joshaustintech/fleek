# ADR 0053: Collect multiple classes in qualified modules

## Status

Accepted.

## Context

Flay 2.14.4 reports a single module group when relative qualified module bodies contain multiple corresponding direct classes. The existing qualified-path slice accepts only one class, so it loses this group.

## Decision

For qualified module paths of two through seven constants, collect direct simple classes with exactly one supported method each as one module candidate, in source order. Set scope overhead to the qualified path's constant count, plus one unit per direct class and one outer-module unit. If any direct entry or class body is unsupported, preserve other verified candidates and mark source coverage incomplete; do not emit the incomplete module group.

## Consequences

This preserves Flay's outer `:module` candidate and location while keeping class order and path identity bounded. Multi-method classes inside qualified modules remain incomplete until separately proven.

## Evidence

`test/fixtures/duplication_qualified_namespace_multiple_classes.rb` matches Flay 2.14.4 at similar `:module` mass/score 106 and locations 1/21. `test/fixtures/duplication_qualified_namespace_multi_method_class_boundary.rb` confirms a two-method class stays incomplete; its boundary mutation must be caught. Public contract mutations remove collection and alter mass; both must be caught. Ticket 21 remains open for broader candidate parity.
