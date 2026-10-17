# ADR 0052: Bound nested class candidate paths

## Status

Accepted.

## Context

Flay 2.14.4 finds a `:class` group when a class contains one nested class whose direct methods match another such scope. Treating every non-method class-body entry as unsupported loses this candidate.

## Decision

Collect a class group through exactly one direct nested class, preserve both class names in scope identity, and use the outer declaration location. Add one scope-mass unit for the nested class. Mark deeper nested-class chains incomplete until separate reference evidence establishes a useful supported depth.

## Consequences

The supported `Outer::Inner` candidate remains bounded and retains normal method-body checks. No nested class body with another nested class is treated as complete.

## Evidence

`test/fixtures/duplication_nested_class_group.rb` matches Flay 2.14.4 at similar `:class` mass/score 52 and outer declaration lines 1/12. A three-level fixture proves deeper chains remain incomplete while Flay reports mass 54. The public duplication contract and a scope-mass mutation protect the behavior. Full Ticket 21 parity remains open.
