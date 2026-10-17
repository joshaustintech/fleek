# ADR 0057: Collect methods from nested sibling wrappers

## Status

Accepted.

## Context

Flay 2.14.4 groups matching outer classes when sibling classes each contain a single nested class with multiple matching direct methods. Counting each method candidate's class path independently overstates class-scope mass.

## Decision

Collect all supported direct methods from the one nested class wrapper under each sibling, within the existing three-class path limit. Preserve method order and full path identity. Compute scope mass once per distinct class path, independent of the number of methods on that path. Mark the source incomplete if any wrapper contains unsupported syntax.

## Consequences

This supports multiple methods inside a bounded wrapper without allowing multiple direct methods on sibling classes or deeper wrappers. The mass algorithm deduplicates identical paths before subtracting shared prefixes.

## Evidence

`test/fixtures/duplication_nested_wrapped_class_siblings.rb` matches Flay 2.14.4 at similar `:class` mass/score 158 and outer locations 1/35. Its paired contract and path-mass mutation verify the result. Ticket 21 remains open for broader parity.
