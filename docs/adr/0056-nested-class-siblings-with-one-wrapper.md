# ADR 0056: Support nested class siblings with one wrapper

## Status

Accepted.

## Context

Flay 2.14.4 reports outer class groups when sibling classes each contain one nested class with a matching method. Fleek supported direct one-method siblings but marked this bounded three-class shape incomplete.

## Decision

Collect sibling classes whose bodies contain either one supported method or one simple nested class containing one supported method, while keeping total class-path depth at three. Preserve complete path identity and source order, share the scope group, and compute the mass from the full paths. Unsupported bodies remain incomplete.

## Consequences

This covers one additional wrapper shape without broadening method syntax or the maximum class depth. Sibling classes with multiple methods, additional wrappers, or other body entries remain incomplete.

## Evidence

`test/fixtures/duplication_nested_wrapped_class_siblings.rb` matches Flay 2.14.4 at similar `:class` mass/score 106 and outer locations 1/25. Its public paired contract and `Flay nested wrapped class siblings` mutation protect collection and mass. Ticket 21 remains open for broader candidate parity.
