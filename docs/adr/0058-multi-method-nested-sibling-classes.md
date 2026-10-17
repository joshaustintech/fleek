# ADR 0058: Collect multiple methods from nested sibling classes

## Status

Accepted.

## Context

Flay 2.14.4 reports matching outer-class groups when each direct sibling class contains multiple matching methods. Restricting each sibling to one method left this bounded shape incomplete, even though method syntax and sibling path structure were already supported.

## Decision

Collect every supported direct method from each direct sibling class, preserving source order and full class-path identity, within the existing three-class depth and 24-candidate limits. Continue to support one nested class wrapper per sibling. Count each distinct class path once when calculating class-scope mass. Mark the source incomplete when a sibling contains unsupported entries or methods.

## Consequences

Nested sibling scopes can contain multiple methods without changing method grammar, class-depth limits, or candidate limits. Unsupported sibling content still prevents a complete parity claim.

## Evidence

`test/fixtures/duplication_nested_class_sibling_methods.rb` matches Flay 2.14.4 at similar `:class` mass/score 118 and outer locations 1/29. The paired public contract checks locations, mass, score, and complete status; a mutation rejects multi-method siblings and must be caught by that contract. Ticket 21 remains open for broader parity.
