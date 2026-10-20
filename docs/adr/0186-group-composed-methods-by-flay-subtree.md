# ADR 0186: Group composed methods by Flay subtree

## Status

Accepted

## Context

Ticket 43 compares composed method candidates with Flay 2.14.4. Method parameter defaults affect whether Flay selects a method (`:defn`) or matching parameterized block (`:iter`) subtree. The earlier pair handling emitted the nested group only for two class methods; larger groups could instead emit an incorrect method group or overlapping iterator groups.

## Decision

Keep method-body candidate grouping independent from optional default-value shape. When grouped candidates have differing supported optional defaults, search for matching block nodes across every member and emit each `:iter` group independently. Group matching nodes rather than consuming whole methods, so one method can contribute to multiple distinct block groups. A matching subtree may include only a subset of methods. Order iterator groups by descending mass, matching Flay. Group mass scales with the number of matching nodes, and identical groups use the same candidate-count score multiplier as method groups. Preserve method-level selection when parameter shapes match.

## Evidence

Generated public-CLI contracts compare composed top-level and class methods against unchanged Flay 2.14.4. They cover identical/default-shape selection, a three-method group, a matching block subset, and two distinct iterator groups contributed by the same methods. Contracts compare node, kind, mass, score, locations, ordering, coverage, and total score. Focused mutations target top-level and class selection and multiple-block grouping. The pinned Spinel 2026.09.12 full gate passed with 63 workers and four mutation workers; Flay score and Reek warnings are both zero.

## Consequences

Composed class-method groups can contain more than two candidates, subset matches, and multiple distinct nested groups without duplicate or missing findings. Unsupported syntax remains incomplete under the existing candidate boundary. Ticket 22 remains open until its remaining acceptance criteria are proven.
