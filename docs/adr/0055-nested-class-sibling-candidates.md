# ADR 0055: Collect one-method nested class siblings

## Status

Accepted.

## Context

Flay 2.14.4 reports a class group for paired outer classes containing multiple corresponding direct nested classes, each with one matching method. Fleek previously marked these outer class scopes incomplete.

## Decision

Collect direct nested class siblings when each child has exactly one supported method and the chain stays within the three-class limit. Keep candidates in source order, preserve each full class path, and assign the shared outer location. Compute scope mass by counting each class path while subtracting shared prefixes once. Any unsupported sibling keeps the outer scope incomplete.

## Consequences

The supported sibling shape matches Flay's outer `:class` group while retaining per-child identity for similar-versus-identical comparison. Multi-method child classes and deeper chains remain incomplete.

## Evidence

`test/fixtures/duplication_nested_class_siblings.rb` matches Flay 2.14.4 at similar `:class` mass/score 104 and outer locations 1/23. The public contract and sibling-mass mutation protect the result. Ticket 21 remains open for broader candidate parity.
