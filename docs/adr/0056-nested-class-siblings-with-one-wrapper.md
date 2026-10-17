# ADR 0056: Support nested class siblings with one wrapper

## Status

Accepted.

## Context

Flay 2.14.4 reports outer class groups when sibling classes each contain one nested class with a matching method. Fleek supported direct one-method siblings but marked this bounded three-class shape incomplete.

## Decision

Collect sibling classes whose bodies contain either one supported method or one simple nested class containing supported methods, while keeping total class-path depth at three. Preserve complete path identity and source order, share the scope group, count each distinct class path once in scope mass, and retain all method candidates. Unsupported bodies remain incomplete.

## Consequences

This covers one additional wrapper shape without broadening method syntax or the maximum class depth. Direct sibling classes with multiple methods, additional wrappers, or other unsupported body entries remain incomplete.

## Evidence

`test/fixtures/duplication_nested_wrapped_class_siblings.rb` matches Flay 2.14.4 at similar `:class` mass/score 158 and outer locations 1/35, including two methods per wrapped sibling. Its public paired contract and `Flay nested wrapped class siblings` plus `Flay nested sibling path mass` mutations protect collection and path-mass deduplication. Ticket 21 remains open for broader candidate parity.
