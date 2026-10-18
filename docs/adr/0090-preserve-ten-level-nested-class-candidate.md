# ADR 0090: Preserve ten-level nested class candidates

## Status

Superseded by [ADR 0097](0097-dynamic-nested-scope-storage.md). Its ten-level evidence remains historical.

## Context

ADR 0089 extended complete nested-class support through nine levels. Flay 2.14.4 still reports the ten-level class group, although Fleek must mark analysis incomplete at that traversal boundary. The collector previously stopped before reaching and retaining the verified method candidate.

## Decision

At the ten-level boundary, mark the source incomplete and continue one bounded class step to collect the candidate. Permit that candidate's full ten-name scope identity, then stop before traversing an eleventh nested class.

## Consequences

Ten-level output retains Flay's mass, score, and locations while reporting incomplete coverage. Deeper chains remain fail-closed; the bound does not imply complete ten-level analysis.

## Evidence

`test/fixtures/duplication_ten_level_nested_class_boundary.rb` matches Flay 2.14.4 at similar `:class` mass/score 68 and lines 1/28. The public contract requires the same candidate plus partial scope and incomplete status. Mutations prove both the boundary marker and full scope identity are required.
